USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_helptable]    Script Date: 2025-06-20 오전 10:27:34 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*******************************************************************************************************     
    
	1. Procedure	: sp_helptable     
	2. Process Func	: 특정 테이블 또는 현재 DB 컨텍스트에 있는 모든 테이블의 레이아웃을 반환합니다.
	3. Create Date	: 2023-01-19
	4. Create User	: JS
	5. Execute Test	:           
	6. return value	:
		0 = There is no error.
	7. History Info	:     
		Date		Author				Description    
		----------- ------------------- -------------------------------------------    
    
*******************************************************************************************************/ 
ALTER   PROCEDURE [dbo].[sp_helptable]
    @nvcTableName sysname = NULL, --// 테이블 이름.
    @nvcSchemaName sysname = NULL, --// 테이블 소유주 이름.
    @inyPrintFormat tinyint = 3 --// Print 포맷. 1=Media Wiki, 2=HTML, 3=RedCloth
--WITH ENCRYPTION
AS
 
SET NOCOUNT ON;
SET XACT_ABORT ON;
 
DECLARE @intReturnValue int
    , @i int
    , @intTableObjectID int
    , @intTableCount int;
 
DECLARE @tblTableLists table (
    seq int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    tableObjectID int NOT NULL,
    tableName sysname NOT NULL,
    schemaName sysname NOT NULL
);
 
DECLARE @tblTableInfo table (
    seq int IDENTITY(1, 1) NOT NULL PRIMARY KEY,
    col1 nvarchar(max) NOT NULL DEFAULT(N''),
    col2 nvarchar(max) NOT NULL DEFAULT(N''),
    col3 nvarchar(max) NOT NULL DEFAULT(N''),
    col4 nvarchar(max) NOT NULL DEFAULT(N''),
    col5 nvarchar(max) NOT NULL DEFAULT(N''),
    col6 nvarchar(max) NOT NULL DEFAULT(N'')
);
 
INSERT @tblTableLists (tableObjectID, tableName, schemaName)
SELECT T.[object_id], T.[name], S.[name]
FROM sys.tables T
INNER JOIN sys.schemas S
    ON T.[schema_id] = S.[schema_id]
WHERE T.[name] LIKE ISNULL(@nvcTableName, T.[name]) AND S.[name] = ISNULL(@nvcSchemaName, S.[name])
ORDER BY T.[name];
 
SELECT @i = 1, @intTableCount = @@ROWCOUNT;
 
IF @intTableCount = 0
BEGIN
    PRINT N'테이블이 존재하지 않습니다.'
    RETURN 0;
END
 
WHILE @i <= @intTableCount
BEGIN
    SELECT @intTableObjectID = tableObjectID
        , @nvcTableName = tableName
        , @nvcSchemaName = schemaName
    FROM @tblTableLists
    WHERE seq = @i;
 
    INSERT @tblTableInfo (col1, col2, col5, col6)
    SELECT N'Table Name', @nvcSchemaName + N'.' + @nvcTableName
        , N'Description'
        , ISNULL(CAST([value] AS nvarchar(max)), N'')
    FROM sys.extended_properties
    WHERE major_id = @intTableObjectID AND minor_id = 0;
 
    IF @@ROWCOUNT = 0
        INSERT @tblTableInfo (col1, col2, col5, col6)
        VALUES (N'Table Name', @nvcSchemaName + N'.' + @nvcTableName, N'Description', N'');
 
    INSERT @tblTableInfo (col1, col2, col3, col4, col5, col6)
    VALUES (N'KEY', N'COLUMN NAME', N'DATA TYPE', N'NULL OPTION', N'REMARK', N'DESCRIPTION');
 
    WITH CTE_PK ([object_id], column_id)
    AS (
        SELECT IXC.[object_id], IXC.column_id
        FROM sys.key_constraints PK
        INNER JOIN sys.index_columns IXC
            ON PK.parent_object_id = IXC.[object_id] AND PK.unique_index_id = IXC.index_id
        WHERE PK.parent_object_id = @intTableObjectID AND PK.[type] = 'PK'
    )
    INSERT @tblTableInfo (col1, col2, col3, col4, col5, col6)
    SELECT
        -- PK, FK
        REPLACE(
            CASE
                WHEN PK.[object_id] IS NOT NULL THEN N'PK'
                ELSE N''
            END +
            CASE
                WHEN FK.parent_object_id IS NOT NULL THEN N'FK'
                ELSE N''
            END
            , N'PKFK'
            , N'PK, FK'
        )
 
        -- 컬럼 이름
        , COL.[name]
 
        -- 데이터 타입
        , CASE TP.[name]
            WHEN N'char' THEN N'char(' + CAST(COL.max_length AS nvarchar(10)) + N')'
            WHEN N'varchar' THEN N'varchar(' + CASE COL.max_length WHEN -1 THEN N'max' ELSE CAST(COL.max_length AS nvarchar(4)) END + N')'
            WHEN N'nchar' THEN N'nchar(' + CAST(COL.max_length / 2 AS nvarchar(10)) + N')'
            WHEN N'nvarchar' THEN N'nvarchar(' + CASE COL.max_length WHEN -1 THEN N'max' ELSE CAST(COL.max_length / 2 AS nvarchar(4)) END + N')'
            WHEN N'numeric' THEN N'decimal(' + CAST(COL.precision AS nvarchar(10)) + N',' + CAST(COL.scale AS nvarchar(10)) + N')'
            WHEN N'decimal' THEN N'decimal(' + CAST(COL.precision AS nvarchar(10)) + N',' + CAST(COL.scale AS nvarchar(10)) + N')'
            WHEN N'binary' THEN N'binary(' + CAST(COL.max_length AS nvarchar(10)) + N')'
            WHEN N'varbinary' THEN N'varbinary(' + CASE COL.max_length WHEN -1 THEN N'max' ELSE CAST(COL.max_length AS nvarchar(4)) END + N')'
            WHEN N'datetime2' THEN N'datetime2(' + CAST(COL.scale AS nvarchar(10)) + N')'
            WHEN N'time' THEN N'time(' + CAST(COL.scale AS nvarchar(10)) + N')'
            WHEN N'datetimeoffset' THEN N'datetimeoffset(' + CAST(COL.scale AS nvarchar(10)) + N')'
            ELSE TP.[name]
        END
 
        -- NULL 허용 여부
        , CASE COL.is_nullable WHEN 0 THEN N'NOT NULL' ELSE N'NULL' END
 
        -- Default 값 / Identity 여부 / Computed Column 정의
        , ISNULL(DF.definition, N'') +
            CASE
                WHEN ID.[object_id] IS NOT NULL THEN N'IDENTITY'
                ELSE N''
            END +
            ISNULL(
                CASE
                    WHEN CP.[object_id] IS NOT NULL THEN CP.definition
                    ELSE N''
                END
                , N''
            )
        , ISNULL(CAST(EP.[value] AS nvarchar(max)), N'')
    FROM sys.columns COL
    INNER JOIN sys.types TP
        ON COL.user_type_id = TP.user_type_id
    LEFT OUTER JOIN sys.foreign_key_columns FK
        ON COL.[object_id] = FK.parent_object_id AND COL.column_id = FK.parent_column_id
    LEFT OUTER JOIN CTE_PK PK ON COL.[object_id] = PK.[object_id] AND COL.column_id = PK.column_id
    LEFT OUTER JOIN sys.default_constraints DF
        ON COL.[object_id] = DF.parent_object_id AND COL.column_id = DF.parent_column_id
    LEFT OUTER JOIN sys.identity_columns ID
        ON COL.[object_id] = ID.[object_id] AND COL.column_id = ID.column_id
    LEFT OUTER JOIN sys.computed_columns CP
        ON COL.[object_id] = CP.[object_id] AND COL.column_id = CP.column_id
    LEFT OUTER JOIN sys.extended_properties EP
        ON COL.[object_id] = EP.major_id AND COL.column_id = EP.minor_id AND EP.class = 1
    WHERE COL.[object_id] = @intTableObjectID
    ORDER BY COL.column_id;
 
    IF @i < @intTableCount
        INSERT @tblTableInfo DEFAULT VALUES;
 
    SET @i += 1;
END
 
SELECT col1, col2, col3, col4, col5, col6 FROM @tblTableInfo ORDER BY seq;
 
IF @intTableCount > 1
BEGIN
    IF @inyPrintFormat = 1 PRINT N'== Tables ==';
    IF @inyPrintFormat = 3 PRINT N'h2. 테이블 명세';
END
 
DECLARE
    @j int,
    @nvcCol1 nvarchar(max),
    @nvcCol2 nvarchar(max),
    @nvcCol3 nvarchar(max),
    @nvcCol4 nvarchar(max),
    @nvcCol5 nvarchar(max),
    @nvcCol6 nvarchar(max);
 
DECLARE @tblTableInfoCopy table (
    seq int IDENTITY(1, 1) NOT NULL,
    col1 nvarchar(max) NOT NULL DEFAULT(N''),
    col2 nvarchar(max) NOT NULL DEFAULT(N''),
    col3 nvarchar(max) NOT NULL DEFAULT(N''),
    col4 nvarchar(max) NOT NULL DEFAULT(N''),
    col5 nvarchar(max) NOT NULL DEFAULT(N''),
    col6 nvarchar(max) NOT NULL DEFAULT(N'')
);
 
INSERT @tblTableInfoCopy (col1, col2, col3, col4, col5, col6)
SELECT CASE col1 WHEN N'' THEN ' ' ELSE col1 END
    , col2, col3, col4
    , CASE col5 WHEN N'' THEN ' ' ELSE col5 END
    , CASE col6 WHEN N'' THEN ' ' ELSE col6 END
FROM @tblTableInfo
ORDER BY seq;
 
SELECT @i = 1, @j = @@ROWCOUNT;
 
IF @inyPrintFormat = 1
BEGIN
    WHILE @i <= @j
    BEGIN
        SELECT @nvcCol1 = col1, @nvcCol2 = col2, @nvcCol3 = col3, @nvcCol4 = col4, @nvcCol5 = col5, @nvcCol6 = col6
        FROM @tblTableInfoCopy
        WHERE seq = @i;
 
        IF @nvcCol1 = N'Table Name'
            PRINT N'
=== ' + @nvcCol2 + N' ===
{|border="0" cellpadding="2" cellspacing="1" style="background-color:#000000"
|+align="left"|' + @nvcCol6
 
        ELSE IF @nvcCol1 = N'KEY'
            PRINT N'|-
!width="70" style="background-color:#777777;color:#FFFFFF"|' + @nvcCol1 + N'||width="180" style="background-color:#777777;color:#FFFFFF"|' + @nvcCol2  + N'||width="100" style="background-color:#777777;color:#FFFFFF"|' + @nvcCol3 + N'||width="150" style="background-color:#777777;color:#FFFFFF"|' + @nvcCol4 + N'||width="100" style="background-color:#777777;color:#FFFFFF"|' + @nvcCol5 + N'||width="400" style="background-color:#777777;color:#FFFFFF"|' + @nvcCol6
 
        ELSE IF @nvcCol2 > N''
            PRINT N'|-
|align="center" style="background-color:#FFFFFF"|' + @nvcCol1 + N'||style="background-color:#FFFFFF"|' + @nvcCol2  + N'||style="background-color:#FFFFFF"|' + @nvcCol3 + N'||align="center" style="background-color:#FFFFFF"|' + @nvcCol4 + N'||align="center" style="background-color:#FFFFFF"|' + @nvcCol5 + N'||style="background-color:#FFFFFF"|' + @nvcCol6
 
        ELSE
            PRINT N'|}<br><br>'
 
        SET @i += 1;
    END
 
    PRINT N'|}<br><br>'
END
 
ELSE IF @inyPrintFormat = 2
BEGIN
    PRINT N'
<html>
<head>
  <title>' + DB_NAME() + N' - 테이블 명세</title>
  <style>
  <!--
    .caption1 {font-family: Arial, Gulim; font-size: 11pt; background-color:#FFFFFF; font-weight:bold}
    .caption2 {font-family: Arial, Gulim; font-size: 10pt; background-color:#FFFFFF;}
    td {font-family: Courier New, Gulim; font-size: 9pt; background-color:#FFFFFF}
    th {font-family: Gulim; font-size: 10pt; background-color:#777777; color:#FFFFFF}
  -->
  </style>
</head>
<body>';
    WHILE @i <= @j
    BEGIN
        SELECT @nvcCol1 = col1, @nvcCol2 = col2, @nvcCol3 = col3, @nvcCol4 = col4, @nvcCol5 = col5, @nvcCol6 = col6
        FROM @tblTableInfoCopy
        WHERE seq = @i;
 
        IF @nvcCol1 = N'Table Name'
            PRINT N'
<table border="0" cellpadding="2" cellspacing="1" style="background-color:#000000">
  <caption align="left" class="caption1">' + @nvcCol2 + N'</caption>
  <caption align="left" class="caption2">' + @nvcCol6 + N'</caption>';
 
        ELSE IF @nvcCol1 = N'KEY'
            PRINT N'  <tr>
    <th width="70">KEY</th><th width="180">COLUMN NAME</th><th width="100">DATA TYPE</th><th width="150">NULL OPTION</th><th width="100">REMARK</th><th width="400">DESCRIPTION
    </th>
  </tr>';
 
        ELSE IF @nvcCol2 > N''
            PRINT N'  <tr>
    <td align="center">' + @nvcCol1 + N'</td>
    <td>' + @nvcCol2 + N'</td>
    <td align="center">' + @nvcCol3 + N'</td>
    <td align="center">' + @nvcCol4 + N'</td>
    <td align="center">' + @nvcCol5 + N'</td>
    <td>' + @nvcCol6 + N'</td>
  </tr>'
 
        ELSE
            PRINT N'</table></br></br>
';
        SET @i += 1;
    END
 
    PRINT N'
</table>
</body></html>';
END
 
ELSE IF @inyPrintFormat = 3
BEGIN
    WHILE @i <= @j
    BEGIN
        SELECT @nvcCol1 = col1, @nvcCol2 = col2, @nvcCol3 = col3, @nvcCol4 = col4, @nvcCol5 = col5, @nvcCol6 = col6
        FROM @tblTableInfoCopy
        WHERE seq = @i;
 
        IF @nvcCol1 = N'Table Name'
            PRINT N'
h3. ' + @nvcCol2 + N'
 
' + @nvcCol6;
 
        ELSE IF @nvcCol1 = N'KEY'
            PRINT N'|_. ' + @nvcCol1 + N'|_. ' + @nvcCol2 + N'|_. ' + @nvcCol3 + N'|_. ' + @nvcCol4 + N'|_. ' + @nvcCol5 + N'|_. ' + @nvcCol6 + N'|';
 
        ELSE IF @nvcCol2 > N''
            PRINT N'|' + @nvcCol1 + N'|' + @nvcCol2  + N'|' + @nvcCol3 + N'|' + @nvcCol4 + N'|' + @nvcCol5 + N'|' + @nvcCol6 + N'|';
 
        ELSE
            PRINT N''
 
        SET @i += 1;
    END
 
    PRINT N'';
END
 
IF @intTableCount = 1
BEGIN
    DECLARE @nvcColumns nvarchar(max);
 
    SET @nvcColumns = N'';
 
    SELECT @nvcColumns = @nvcColumns + CASE @nvcColumns WHEN N'' THEN N'' ELSE N', ' END + [name]
    FROM sys.columns
    WHERE [object_id] = @intTableObjectID;
 
    SELECT @nvcColumns AS allColumns;
 
    SELECT [name] AS [Check Constraint Name], definition
    FROM sys.check_constraints
    WHERE parent_object_id = OBJECT_ID(@nvcSchemaName + N'.' + @nvcTableName, N'U');
 
    EXEC ('SELECT TOP (10) * FROM ' + @nvcSchemaName + N'.' + @nvcTableName + N';');
END
 
RETURN 0;
