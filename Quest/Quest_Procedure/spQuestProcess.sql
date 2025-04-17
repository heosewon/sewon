/*
    퀘스트 진행 - 계정, 캐릭터 (서버에서 1분에 한번씩 호출)
*/
CREATE   PROCEDURE [dbo].[spQuestProcess]
    @Result          INT OUTPUT,
    @AccountUniqueID INT,
    @HeroUniqueID    BIGINT,
    @JsonQuest       VARCHAR(8000)
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET @Result = -1;

    DECLARE @CurrentTime DATETIMEOFFSET = SYSDATETIMEOFFSET();

    BEGIN TRY

        BEGIN TRAN spQuestProcess;

        DECLARE @TQuestProcess TABLE (InitialQuestID INT, PerformingCount INT, IsAccountShared BIT)
        INSERT  @TQuestProcess
        SELECT 
            InitialQuestID, PerformingCount, IsAccountShared
        FROM 
            OPENJSON (@JsonQuest)
            WITH
            (
                InitialQuestID  INT '$.iqi', 
                PerformingCount INT '$.pfc',
                IsAccountShared BIT '$.ias'
            );

        DECLARE @ResultCount INT = @@ROWCOUNT;

        UPDATE
            A
        SET 
            A.PerformingCount = B.PerformingCount,
            A.UpdateTime = @CurrentTime
        FROM 
            dbo.TQuestAccount A
            JOIN @TQuestProcess B ON A.InitialQuestID = B.InitialQuestID
        WHERE
            AccountUniqueID = @AccountUniqueID
            AND IsAccountShared = 1;
           
        SET @ResultCount -= @@ROWCOUNT;

        UPDATE 
            A
        SET 
            A.PerformingCount = B.PerformingCount,
            A.UpdateTime = @CurrentTime
        FROM 
            dbo.TQuest A 
            JOIN @TQuestProcess B ON A.InitialQuestID = B.InitialQuestID
        WHERE
            HeroUniqueID = @HeroUniqueID
            AND IsAccountShared = 0;

        SET @ResultCount -= @@ROWCOUNT;

        IF @ResultCount <> 0
            THROW 50046, N'퀘스트 업데이트 실패', 1;

        SET @Result = 0;
        
        COMMIT TRAN;

    END TRY

    BEGIN CATCH
        SET @Result = ERROR_NUMBER();

        ROLLBACK TRAN;
        INSERT dbo.TProcedureError DEFAULT VALUES;
        THROW;

    END CATCH
