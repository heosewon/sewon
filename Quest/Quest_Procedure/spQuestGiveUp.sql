/*
    퀘스트 포기 - 캐릭터
*/
CREATE   PROCEDURE [dbo].[spQuestGiveUp]
    @Result          INT OUTPUT,
    @HeroUniqueID    BIGINT,
    @InitailQuestID  INT
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET @Result = -1;

    BEGIN TRY

        BEGIN TRAN spQuestGiveUp;

        DELETE dbo.TQuest WHERE HeroUniqueID = @HeroUniqueID AND InitialQuestID = @InitailQuestID;

        SET @Result = 0;
        
        COMMIT TRAN;

    END TRY

    BEGIN CATCH
        SET @Result = ERROR_NUMBER();

        ROLLBACK TRAN;
        INSERT dbo.TProcedureError DEFAULT VALUES;
        THROW;

    END CATCH
