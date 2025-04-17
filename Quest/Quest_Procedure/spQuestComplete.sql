/*
    퀘스트 완료 - 계정, 캐릭터
*/
CREATE PROCEDURE [dbo].[spQuestComplete]
    @Result          INT OUTPUT,
    @IsAccountShared BIT,            -- 0 : 계정 공유 X , 1: 계정 공유
    @AccountUniqueID INT,
    @HeroUniqueID    BIGINT,
    @QuestType       TINYINT,
    @JsonQuest       VARCHAR (8000), -- '[{"iqi" : 10000, "qi" : 10001}]'     iqi : 최초 퀘스트, qi : 완료 퀘스트
    @Gold            BIGINT,         -- 획득 값
    @Exp             BIGINT,         -- 획득 경험치
    @Position        INT,
    @JsonItem        VARCHAR (MAX)   -- 획득 아이템'[{"uid" : 11234, "tid" : 10002 , "sc" : 10,  "flag" : 1,  "psc" : 0]'
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET @Result = -1;

    DECLARE @CurrentTime DATETIMEOFFSET = SYSDATETIMEOFFSET();

    DECLARE @OwnerType     TINYINT = IIF(@IsAccountShared = 1, 2, 3);
    DECLARE @OwnerUniqueID BIGINT  = IIF(@IsAccountShared = 1, @AccountUniqueID, @HeroUniqueID);

    BEGIN TRY

        BEGIN TRAN spQuestComplete;

        DECLARE @TQuestComplete TABLE (InitialQuestID INT, QuestID INT)
        INSERT  @TQuestComplete
        SELECT 
            InitialQuestID, QuestID
        FROM 
            OPENJSON (@JsonQuest)
            WITH
            (
                InitialQuestID  INT    '$.iqi', 
                QuestID         INT    '$.qi'
            );

        IF @IsAccountShared = 1
        BEGIN
            UPDATE
                A
            SET 
                IsComplete = 1,
                UpdateTime = @CurrentTime
            FROM 
                dbo.TQuestAccount A 
                JOIN @TQuestComplete B ON A.InitialQuestID = B.InitialQuestID
            WHERE
                AccountUniqueID = @AccountUniqueID
                AND IsComplete = 0;
        END
        ELSE
        BEGIN
            UPDATE 
                A
            SET 
                IsComplete = 1,
                UpdateTime = @CurrentTime
            FROM 
                dbo.TQuest A 
                JOIN @TQuestComplete B ON A.InitialQuestID = B.InitialQuestID
            WHERE
                HeroUniqueID = @HeroUniqueID
                AND IsComplete = 0;
        END

        IF @@ROWCOUNT = 0
            THROW 50047, N'퀘스트 완료 실패', 1;

        /* QuestType (1: 메인, 2: 서브, 3: 가이드) 같은 퀘스트를 2번 클리어 못하게 방지 */ 
        IF EXISTS 
        (
            SELECT 1
            FROM 
                dbo.TQuestComplete A
                JOIN @TQuestComplete B ON A.QuestID = B.InitialQuestID
            WHERE
                A.OwnerType = @OwnerType
                AND A.OwnerUniqueID = @OwnerUniqueID
                AND A.QuestType IN (1, 2, 3)
        )
        BEGIN
            ;THROW 50050, N'퀘스트 중복.', 1;
        END

        INSERT dbo.TQuestComplete (OwnerType, OwnerUniqueID, QuestID, QuestType, CompleteHeroUniqueID)
        SELECT 
            IIF(@IsAccountShared = 1, 2, 3),
            IIF(@IsAccountShared = 1, @AccountUniqueID, @HeroUniqueID),
            QuestID,
            @QuestType,
            @HeroUniqueID
        FROM 
            @TQuestComplete
        ;

        -- 아이템 지급
        IF @JsonItem IS NOT NULL AND @JsonItem NOT IN ('', '[]')
        BEGIN

            EXEC [dbo].[innerJsonItem]
                @AccountUniqueID    = @AccountUniqueID,
                @HeroUniqueID       = @HeroUniqueID,
                @Position           = @Position,
                @JsonItem           = @JsonItem,
                @NeedInsertSelect   = 1;

        END

        UPDATE
            [dbo].[TCurrency]
        SET
            [CurrencyValue] += @Gold
        WHERE
            [OwnerType] = 3 AND [OwnerUniqueID] = @HeroUniqueID
            AND [CurrencyID] = 5;

        UPDATE dbo.THero SET HeroExp += @Exp WHERE HeroUniqueID = @HeroUniqueID;

        SET @Result = 0;
        
        COMMIT TRAN;

    END TRY

    BEGIN CATCH
        SET @Result = ERROR_NUMBER();

        ROLLBACK TRAN;
        INSERT dbo.TProcedureError DEFAULT VALUES;
        THROW;

    END CATCH
