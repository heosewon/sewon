USE [master]
GO
/****** Object:  StoredProcedure [dbo].[sp_viewmodule]    Script Date: 2025-06-20 오전 10:28:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/*******************************************************************************************************     
    
	1. Procedure	: sp_viewmodule     
	2. Process Func	: SP, UDF의 소스코드를 조회합니다.
	3. Create Date	: 2021-03-25
	4. Create User	: JS
	5. Execute Test	:           
	6. return value	:
		0 = There is no error.
	7. History Info	:     
		Date		Author				Description    
		----------- ------------------- -------------------------------------------    
    
*******************************************************************************************************/ 
ALTER   PROCEDURE [dbo].[sp_viewmodule]
    @nvcObjectName nvarchar(128)    --// 개체 이름
--WITH ENCRYPTION
AS
 
SET NOCOUNT ON;
 
DECLARE @intReturnValue int
    , @nvcDefinition nvarchar(max)
    , @nvcDefinitionBuffer nvarchar(max)
    , @m int;
 
/**_# Rollback and return if inside an uncommittable transaction.*/
IF XACT_STATE() = -1
BEGIN
    SET @intReturnValue = 1;
    ROLLBACK TRANSACTION;
    GOTO ErrorHandler;
END

SELECT @nvcDefinition = definition FROM sys.sql_modules WHERE [object_id] = OBJECT_ID(@nvcObjectName);
 
IF @@ROWCOUNT = 0
BEGIN
    PRINT N'개체를 찾을 수 없습니다.';
    RETURN -1
END
 
EXEC dbo.sp_print @nvcString = @nvcDefinition;
 
RETURN 0;
 
ErrorHandler:
RETURN @intReturnValue;
