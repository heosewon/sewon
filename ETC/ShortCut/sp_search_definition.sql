USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_search_definition]    Script Date: 2025-06-20 오전 10:28:40 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/******************************************************************************  
    name        :   [sp_search_definition]  
    description :   get object definition  
    timing      :   
    excute ex)  :   EXEC [dbo].[sp_search_definition] @Name='GuildMember'  
    
    Ver         Date        Author          Description  
    ---------   ----------  --------------- ------------------------------------      
******************************************************************************/  
ALTER PROCEDURE [dbo].[sp_search_definition]  
    @Name SYSNAME = NULL  
, @OwnerName SYSNAME = NULL  
AS  
BEGIN  
    -- ??????  
    SET NOCOUNT ON  
    SET XACT_ABORT ON  
    SET LOCK_TIMEOUT 3000   
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  
      
    ------------------------------------------------------------------------  
    -- declare.  
    ------------------------------------------------------------------------  
 DECLARE @ObjectId INT  
 DECLARE @ObjectType CHAR(2)  
  
 BEGIN TRY  
    
  IF @Name IS NULL  
  BEGIN  
   RETURN 0  
  END  
  
  PRINT 'db : '+DB_NAME()  
  PRINT 'search : '+@Name  
    
  SELECT ROW_NUMBER() OVER (ORDER BY name) [#]  
  , [name]  
  , CONCAT(  
    'USE [',DB_NAME(),']',CHAR(10),'GO',CHAR(10)  
   , CASE IsAnsiNullsOn WHEN 0 THEN 'SET ANSI_NULLS IFF' WHEN 1 THEN 'SET ANSI_NULLS ON' ELSE '' END , CHAR(10) , 'GO' , CHAR(10)  
   , CASE IsQuotedIdentOn WHEN 0 THEN 'SET QUOTED_IDENTIFIER OFF' WHEN 1 THEN 'SET QUOTED_IDENTIFIER ON' ELSE '' END , CHAR(10) , 'GO' , CHAR(10)  
   --, 'IF OBJECT_ID(''' , [name] , ''') IS NULL',CHAR(10),CHAR(9),'EXEC (''CREATE PROCEDURE ' , [name], ' AS SELECT 1'')', CHAR(10) , 'GO' , CHAR(10)  
   , 'IF OBJECT_ID(''' , [name] , ''') IS NOT NULL',CHAR(10),CHAR(9),'DROP PROCEDURE ' , [name], ';', CHAR(10) , 'GO' , CHAR(10)  
   , [definition] , CHAR(10) , 'GO' , CHAR(10)  
   ) [definition]  
  , create_date CreateDate  
  , modify_date ModifyDate  
  , IsAnsiNullsOn  
  , IsQuotedIdentOn  
  FROM (  
    SELECT A.name  
    , A.create_date  
    , A.modify_date  
    , OBJECTPROPERTY(A.[object_id],'ExecIsAnsiNullsOn') IsAnsiNullsOn  
    , OBJECTPROPERTY(A.[object_id],'ExecIsQuotedIdentOn') IsQuotedIdentOn  
    , B.[definition]  
    FROM sys.procedures A  
     INNER JOIN sys.sql_modules B ON A.[object_id] = B.[object_id]  
    WHERE [type] = 'P' AND B.[definition] LIKE '%'+@Name+'%'  
    UNION ALL  
    SELECT A.name  
    , A.create_date  
    , A.modify_date  
    , OBJECTPROPERTY(A.[object_id],'ExecIsAnsiNullsOn') IsAnsiNullsOn  
    , OBJECTPROPERTY(A.[object_id],'ExecIsQuotedIdentOn') IsQuotedIdentOn  
    , B.[definition]  
    FROM sys.objects A  
     INNER JOIN sys.sql_modules B ON A.[object_id] = B.[object_id]  
    WHERE [type] IN ('FN','IF','TF') AND B.[definition] LIKE '%'+@Name+'%'  
   ) A  
  
 END TRY  
 BEGIN CATCH  
    
  THROW;  
  
 END CATCH  
END  

