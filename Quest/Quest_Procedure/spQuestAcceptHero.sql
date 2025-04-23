/*
    퀘스트 수락 할 때  - 캐릭터 

    QuestType
        1 : 메인
        2 : 서브
        3 : 가이드
        6 : 개인의뢰

    2025.02.13      허세원     최초생성.
*/
CREATE   PROCEDURE [dbo].[spQuestAcceptHero]
    @Result          INT OUTPUT,
    @HeroUniqueID    BIGINT,
    @InitialQuestID  INT,
    @QuestID         INT,
    @QuestType       TINYINT,
    @ExpireTick      BIGINT,
    @QuestGroupID    INT        -- 의뢰 일 때 
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET @Result = -1;

    DECLARE @CurrentTime DATETIMEOFFSET = SYSDATETIMEOFFSET();

    BEGIN TRY

        BEGIN TRAN spQuestAcceptHero;

        IF @QuestType IN (1, 2, 3)
        BEGIN
            UPDATE
                dbo.TQuest
            SET
                QuestID         = @QuestID,
                IsComplete      = 0,
                PerformingCount = 0,
                ExpireTick      = @ExpireTick,
                UpdateTime      = @CurrentTime,
                CreateTime      = @CurrentTime
            WHERE
                HeroUniqueID = @HeroUniqueID
                AND InitialQuestID = @InitialQuestID
                AND IsComplete = 1;

            IF @@ROWCOUNT = 0
            BEGIN
                INSERT dbo.TQuest (HeroUniqueID, InitialQuestID, QuestID, QuestType, ExpireTick)
                VALUES (@HeroUniqueID, @InitialQuestID, @InitialQuestID, @QuestType, @ExpireTick);
            END
        END
        ELSE IF @QuestType = 6
        BEGIN
            UPDATE
                dbo.TQuest
            SET
                IsComplete      = 0,
                PerformingCount = 0,
                ExpireTick      = @ExpireTick,
                UpdateTime      = @CurrentTime,
                CreateTime      = @CurrentTime
            WHERE
                HeroUniqueID = @HeroUniqueID
                AND InitialQuestID = @InitialQuestID;

            IF @@ROWCOUNT = 0
            BEGIN
                INSERT dbo.TQuest (HeroUniqueID, InitialQuestID, QuestID, QuestType, ExpireTick)
                VALUES (@HeroUniqueID, @InitialQuestID, @InitialQuestID, @QuestType, @ExpireTick);
            END
        END
            
        SET @Result = 0;
        
        COMMIT TRAN;

    END TRY

    BEGIN CATCH
        SET @Result = ERROR_NUMBER();

        ROLLBACK TRAN;
        INSERT dbo.TProcedureError DEFAULT VALUES;
        THROW;

    END CATCH
