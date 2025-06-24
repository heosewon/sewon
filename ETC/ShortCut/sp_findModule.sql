USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_findModule]    Script Date: 2025-06-20 오전 10:28:49 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*******************************************************************************************************     
    
	1. Procedure	: sp_findModule     
	2. Process Func	: 특정 문자열을 포함한 SQL Module을 찾습니다.
	3. Create Date	: 2021-03-25
	4. Create User	: JS
	5. Execute Test	:           
	6. return value	:
		0 = There is no error.
	7. History Info	:     
		Date		Author				Description    
		----------- ------------------- -------------------------------------------    
    
*******************************************************************************************************/ 
ALTER   PROCEDURE [dbo].[sp_findModule]
    @nvcString nvarchar(4000)
--WITH ENCRYPTION
AS
 
SET NOCOUNT ON;
 
DECLARE
    @intReturnValue int,
    @nvcStmt nvarchar(4000);
 
SET @nvcStmt = N'SELECT OBJECT_NAME= OBJECT_NAME(A.object_id), SCRIPT = A.definition, B.create_date, B.modify_date, A.object_id, B.type
FROM sys.sql_modules AS A
	LEFT OUTER JOIN sys.objects AS B
		ON B.object_id = A.object_id
WHERE definition LIKE N''%'' + @nvcString + ''%'' ORDER BY OBJECT_NAME(A.object_id)';
 
EXEC sp_executesql @nvcStmt, N'@nvcString nvarchar(4000)', @nvcString = @nvcString;
 
RETURN 0;
 
ErrorHandler:
RETURN @intReturnValue;
