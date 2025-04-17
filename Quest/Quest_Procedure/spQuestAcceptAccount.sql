/*
    퀘스트 수락 - 계정 (업적, 이벤트)
    QuestType
         9 : 업적
        10 : 이벤트
*/
CREATE   PROCEDURE [dbo].[spQuestAcceptAccount]
    @Result          INT OUTPUT,
    @AccountUniqueID INT,
    @JsonQuest       VARCHAR(8000),
    @QuestType       TINYINT,
    @ExpireTick      BIGINT
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET @Result = -1;

    DECLARE @CurrentTime DATETIMEOFFSET = SYSDATETIMEOFFSET();

    BEGIN TRY

        BEGIN TRAN spQuestAcceptAccount;

        DECLARE @TQuestAccount TABLE (InitialQuestID INT, QuestID INT)
        INSERT  @TQuestAccount
        SELECT
            InitialQuestID, QuestID
        FROM 
            OPENJSON (@JsonQuest)
            WITH
            (
                InitialQuestID INT '$.iqi',
                QuestID        INT '$.qi'
            );
            
        IF @QuestType = 9
        BEGIN
            MERGE dbo.TQuestAccount T
            USING @TQuestAccount S ON T.AccountUniqueID = @AccountUniqueID AND T.InitialQuestID = S.InitialQuestID
            WHEN MATCHED THEN
                UPDATE SET
                    T.IsComplete      = 0,
                    T.PerformingCount = 0,
                    T.ExpireTick      = @ExpireTick,
                    T.UpdateTime      = @CurrentTime,
                    T.CreateTime      = @CurrentTime
            WHEN NOT MATCHED THEN
                INSERT (AccountUniqueID, InitialQuestID, QuestID, QuestType, ExpireTick)
                VALUES (@AccountUniqueID, S.InitialQuestID, S.QuestID, @QuestType, @ExpireTick)
            ;
        END
        ELSE IF @QuestType = 10
        BEGIN
            INSERT dbo.TQuestAccount (AccountUniqueID, InitialQuestID, QuestID, QuestType, ExpireTick)
            SELECT @AccountUniqueID, InitialQuestID, QuestID, @QuestType, @ExpireTick FROM @TQuestAccount;
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
