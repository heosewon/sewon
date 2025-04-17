/*
    퀘스트 수락 - 지령 (캐릭터, 길드) 길드는 아직 없음.
*/
CREATE   PROCEDURE [dbo].[spQuestAcceptMission]
    @Result          INT OUTPUT,
    @HeroUniqueID    BIGINT,
    @InitialQuestID  INT,
    @QuestType       TINYINT,
    @ItemUniqueID    BIGINT,
    @PrevStackCount  INT,            -- 지령서 변경전 값
    @ExpireTick      BIGINT
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET @Result = -1;

    DECLARE @CurrentTime DATETIMEOFFSET = SYSDATETIMEOFFSET();

    BEGIN TRY

        BEGIN TRAN spQuestAcceptMission;

        IF @PrevStackCount = 1
        BEGIN
            DELETE 
            FROM 
                dbo.TItem
            WHERE
                ItemUniqueID = @ItemUniqueID
                AND StackCount = @PrevStackCount;
        END
        ELSE
        BEGIN
            UPDATE
                dbo.TItem
            SET
                StackCount -= 1
            WHERE
                ItemUniqueID = @ItemUniqueID
                AND StackCount = @PrevStackCount;
        END

        IF @@ROWCOUNT = 0
            THROW 50026, N'아이템 소모 실패.', 1;

        IF @QuestType = 5
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
