/*
    퀘스트 의뢰 갱신 또는 초기화 할 때

        1. 시간 지나서 초기화
            클라에서 의뢰 퀘스트 화면 들어갈 때

        2. 의뢰 갱신 버튼 눌렀을 때.
        
        QuestType
         6 : 개인
         8 : 길드
*/
CREATE   PROCEDURE [dbo].[spQuestRequestReset]
    @Result                INT OUTPUT,
    @AccountUniqueID       INT,
    @HeroUniqueID          BIGINT,
    @CurrencyID            INT,           -- 소모할 재화ID
    @JsonQuest             VARCHAR(8000), -- 갱신할 때 이전이랑 같으면 비워져서 옴.
    @PrevGold              BIGINT,        -- 서버가 알고 있는 값.
    @Gold                  BIGINT,        -- 차감 값.
    @PrevFreeDia           INT,           -- 서버가 알고 있는 값.
    @FreeDia               INT,           -- 차감 값.
    @QuestType             INT,
    @QuestGroupID          INT,
    @QuestResetCount       INT,
    @IsReset               BIT            -- 1 : 재화 소모 갱신
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET @Result = -1;

    DECLARE @CurrentTime    DATETIMEOFFSET = SYSDATETIMEOFFSET();

    --아직 길드가 없어서 캐릭터만
    DECLARE @OwnerType      INT    = CASE @QuestType WHEN 6 THEN             3 END;
    DECLARE @OwnerUniqueID  BIGINT = CASE @QuestType WHEN 6 THEN @HeroUniqueID END;

    BEGIN TRY

        BEGIN TRAN spQuestRequestReset;

        IF @IsReset = 1
        BEGIN 
            IF @CurrencyID = 5
            BEGIN
               -- 재화 차감
                UPDATE 
                    dbo.THero 
                SET 
                    Gold += @Gold 
                WHERE 
                    HeroUniqueID = @HeroUniqueID 
                    AND Gold = @PrevGold;

                IF @@ROWCOUNT = 0
                    THROW 50049, N'골드 처리 실패.', 1;
            END
            ELSE IF @CurrencyID = 3
            BEGIN
                EXEC dbo.innerCurrencyProcess
                    @AccountUniqueID   = @AccountUniqueID,
                    @PrevPaidDiamond   = 0,
                    @AddPaidDiamond    = 0,
                    @PrevFreeDiamond   = @PrevFreeDia,
                    @AddFreeDiamond    = @FreeDia,
                    @PrevMileage       = 0,
                    @AddMileage        = 0,
                    @GroupSeq          = 0,
                    @ReasonWhy         = 0,
                    @SourceType        = 0,
                    @SourceID          = 0,
                    @ProcedureUniqueID = 0;
            END

            UPDATE
                dbo.TQuestRequestGroup
            SET
                QuestResetCount      = @QuestResetCount,
                QuestResetUpdateTime = @CurrentTime
            WHERE
                OwnerType         = @OwnerType
                AND OwnerUniqueID = @OwnerUniqueID
                AND QuestGroupID  = @QuestGroupID;

            IF @@ROWCOUNT = 0
                THROW 50050, N'의뢰 퀘스트 목록 업데이트 실패.', 1;

        END
        ELSE
        BEGIN
            UPDATE
                dbo.TQuestRequestGroup
            SET
                QuestResetCount   = @QuestResetCount,
                QuestLastInitTime = @CurrentTime
            WHERE
                OwnerType         = @OwnerType
                AND OwnerUniqueID = @OwnerUniqueID
                AND QuestGroupID  = @QuestGroupID;

            IF @@ROWCOUNT = 0
            BEGIN
                INSERT dbo.TQuestRequestGroup(OwnerType, OwnerUniqueID, QuestGroupID, QuestResetCount, QuestResetUpdateTime, QuestLastInitTime)
                SELECT 
                    @OwnerType,
                    @OwnerUniqueID,
                    @QuestGroupID, 
                    0, 
                    @CurrentTime, 
                    @CurrentTime;
            END
        END

        IF @JsonQuest IS NOT NULL AND @JsonQuest NOT IN ('', '[]')
        BEGIN
            DECLARE @TQuestReset TABLE (QuestID INT, IsNew BIT)
            INSERT  @TQuestReset
            SELECT
                QuestID, IsNew
            FROM 
                OPENJSON (@JsonQuest)
                WITH
                (
                    QuestID      INT '$.qi',
                    IsNew        BIT '$.is'
                );

            DECLARE @ResultCount INT = @@ROWCOUNT;

            DELETE
                A
            FROM
                dbo.TQuestRequest A
                JOIN @TQuestReset B ON A.QuestID = B.QuestID AND B.IsNew = 0
            WHERE
                A.OwnerType         = @OwnerType
                AND A.OwnerUniqueID = @OwnerUniqueID
                AND A.QuestGroupID  = @QuestGroupID;

            SET @ResultCount -= @@ROWCOUNT;

            INSERT dbo.TQuestRequest (OwnerType, OwnerUniqueID, QuestGroupID, QuestID)
            SELECT 
                @OwnerType, 
                @OwnerUniqueID,
                @QuestGroupID, 
                QuestID
            FROM 
                @TQuestReset 
            WHERE 
                IsNew = 1
            ;

            SET @ResultCount -= @@ROWCOUNT;

            IF @ResultCount <> 0
                THROW 50051, N'의뢰 퀘스트 목록 업데이트 실패', 1;

            DELETE 
                A 
            FROM 
                dbo.TQuest A 
                JOIN @TQuestReset B ON A.InitialQuestID = B.QuestID AND B.IsNew = 0
            WHERE
                A.HeroUniqueID = @HeroUniqueID 
                AND QuestType = 6; 
        END
        ELSE
        BEGIN
            DELETE dbo.TQuest WHERE HeroUniqueID = @HeroUniqueID AND QuestType = 6;
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
