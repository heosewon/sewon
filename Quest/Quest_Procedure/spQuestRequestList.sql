/*
    의뢰 퀘스트 리스트 - 캐릭터, 길드 
        길드 아직 없음.
*/
CREATE   PROCEDURE [dbo].[spQuestRequestList]
    @HeroUniqueID    BIGINT
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        SELECT 
            QuestGroupID, 
            QuestResetCount, 
            CAST(QuestResetUpdateTime AS DATETIME) QuestResetUpdateTime
        FROM
            dbo.TQuestRequestGroup
        WHERE
            OwnerType = 3
            AND OwnerUniqueID = @HeroUniqueID
        UNION ALL
        SELECT 0, 0, '1900-01-01 00:00:00';

        SELECT 
            QuestGroupID, 
            QuestID 
        FROM 
            dbo.TQuestRequest
        WHERE
            OwnerType = 3
            AND OwnerUniqueID = @HeroUniqueID
        UNION ALL
        SELECT 0, 0;


    END TRY

    BEGIN CATCH

        INSERT dbo.TProcedureError DEFAULT VALUES;
        THROW;

    END CATCH
