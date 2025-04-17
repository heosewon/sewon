/*
    퀘스트 리스트 - 계정, 캐릭터 (캐릭터 접속시)
*/
CREATE   PROCEDURE [dbo].[spQuestList]
    @AccountUniqueID INT,
    @HeroUniqueID    BIGINT
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        SELECT
            InitialQuestID, QuestID, QuestType, IsComplete, PerformingCount, ExpireTick, 
            CAST(UpdateTime AS DATETIME) UpdateTime, CAST(CreateTime AS DATETIME) CreateTime
        FROM
            dbo.TQuest
        WHERE
            HeroUniqueID = @HeroUniqueID
        UNION ALL
        SELECT
            InitialQuestID, QuestID, QuestType, IsComplete, PerformingCount, ExpireTick, 
            CAST(UpdateTime AS DATETIME) UpdateTime, CAST(CreateTime AS DATETIME) CreateTime
        FROM
            dbo.TQuestAccount
        WHERE
            AccountUniqueID = @AccountUniqueID
        UNION ALL
        SELECT 0, 0, 0, 0, 0, 0, '1900-01-01 00:00:00', '1900-01-01 00:00:00';

    END TRY

    BEGIN CATCH

        INSERT dbo.TProcedureError DEFAULT VALUES;
        THROW;

    END CATCH
