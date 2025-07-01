USE [Game]
GO
/******************************************************************************
    캐릭터 선택창 진입 할 때

    2025.06.24      허세원     계정별 푸쉬 추가.
        @LastPostSupplyTimeFromUserDB   User.spAccountPostSupplyCheckList.LastPostSupplyTime 으로 Update
        @IsReceived                     수령여부는 서버에서 보내줌
            0 : 푸쉬 안받음, 1 : 푸쉬 받음
******************************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[spHeroSelectSimpleHeros_Imp] 
    @HeroSlotCount       INT OUTPUT,
    @WarehouseSlotCount  INT OUTPUT, -- IN 창고 기본슬롯 , OUT 현재 창고슬롯
    @AccountUniqueID     INT,

    @LastPostSupplyTimeFromUserDB DATETIME,
    @IsReceived                   BIT
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY

        BEGIN TRAN;

        SET @WarehouseSlotCount = 0;

        SET @HeroSlotCount =  3;

        SELECT
            @WarehouseSlotCount = [WarehouseExpansionCount],
            @HeroSlotCount      = HeroSlot
        FROM
            TAccountShareData
        WHERE
            AccountUniqueID = @AccountUniqueID;

        IF @@ROWCOUNT = 0
            INSERT TAccountShareData ( [AccountUniqueID], [HeroSlot])  VALUES (@AccountUniqueID, 3);

        -- Result Tables
        DECLARE @DeletedUIDTable TABLE (HeroUniqueID BIGINT)

        -- Poco 예외처리 - 항상 row 있게 하려고.
        INSERT INTO @DeletedUIDTable(HeroUniqueID) VALUES (0)


        -- Hero Delete 상태로 바꾸기
        UPDATE
            THero
        SET
            HeroStatus = 3
        OUTPUT
            inserted.HeroUniqueID INTO @DeletedUIDTable
        WHERE
            AccountUniqueID = @AccountUniqueID
            AND HeroStatus = 2                      -- 삭제 대기 캐릭터인지 조건 추가. 2020.09.15. 안미향
            AND DeleteDate <> '1900-01-01'
            AND DeleteDate < GETDATE() --2 <= DATEDIFF(MINUTE, DeleteDate, GETDATE())

        UPDATE  
            dbo.TAccountShareData
        SET
            LastPostSupplyTime = @LastPostSupplyTimeFromUserDB
        WHERE
            AccountUniqueID         = @AccountUniqueID
            AND LastPostSupplyTime <= @LastPostSupplyTimeFromUserDB
            AND @IsReceived         = 1
        ;

        COMMIT;

        SELECT
            A.HeroUniqueID,
            A.HeroName,
            A.HeroLevel,
            A.HeroClass,
            A.HeroStatus,
            CAST(A.CreateTime as datetime) CreateTime,
            CAST(A.LogoutTime as datetime) LogoutTime,
            A.DeleteDate,
            ISNULL(C.GuildName, '') GuildName,
            ROUND(A.PosX, 2) PosX,
            ROUND(A.PosY, 2) PosY,
            0 ChaoticPoint,
            A.CheckFlag,
            A.ZoneID,
            A.HeroPower,
            A.[SaviorLevel]
        FROM
            THero AS A
            LEFT JOIN TGuildMember  AS B ON A.HeroUniqueID = B.HeroUniqueID
            LEFT JOIN TGuild        AS C ON B.GuildUniqueID = C.GuildUniqueID AND C.IsDeleted = 0
            
         WHERE
            A.AccountUniqueID = @AccountUniqueID and HeroStatus in (1,2)
    
         -- result 2
         -- AccountDB 동기화 하기위해 보내줌
         SELECT HeroUniqueID FROM @DeletedUIDTable

         

    END TRY
    BEGIN CATCH

        IF @@TRANCOUNT <> 0
            ROLLBACK;

        INSERT [TProcedureError] DEFAULT VALUES;
        THROW;

    END CATCH
GO
GRANT EXECUTE ON [dbo].[spHeroSelectSimpleHeros_Imp] TO ROLE_GAMESERVER;
GO
/*
    22.08.18    신현철     아이템 생성 단일화
    22.08.23    신현철     아이템 옵션 추가 --  '{"ItemOption1":31252304,"ItemOption2":31251408,"ItemOption3":31257401,"SpecializedOption1":41252302,"SpecializedOption2":41259304,"ExpireTick":0}'
    2025.06.24      허세원     계정별 푸쉬 추가.
        @@LastPushUpdateTime DATETIME OUTPUT 추가 
            이미 선언되어있는 @LastPostSupplyTime과 이름이 겹쳐서 여기만 다름 종속되어있는 프로시저들은 @LastPostSupplyTime
*/
CREATE OR ALTER PROCEDURE [dbo].[innerPostSupply_Imp]
    @AccountUniqueID    INT,
    @LastPushUpdateTime DATETIME OUTPUT
AS
    SET NOCOUNT, XACT_ABORT ON;
    
    DECLARE @CurrentDatetime     DATETIMEOFFSET = SYSDATETIMEOFFSET()
    DECLARE @LastPostSupplyTime  DATETIMEOFFSET;

    SELECT @LastPostSupplyTime = [LastPostSupplyTime] FROM [TAccountShareData] WITH (UPDLOCK) WHERE [AccountUniqueID] = @AccountUniqueID;
    IF @LastPostSupplyTime IS NULL
        SET @LastPostSupplyTime = '1601-01-01';

    DECLARE @PostReward TABLE (
        RewardType                INT,
        RewardTemplateID       BIGINT,
        RewardAmount              INT,
        TitleID                   INT,
        ExpireTick             BIGINT,
        ItemOption      VARCHAR(1000),
        [PostSupplyUniqueID]   BIGINT
    );

    INSERT @PostReward (RewardType, RewardTemplateID, RewardAmount, TitleID, ExpireTick, ItemOption, [PostSupplyUniqueID])
    SELECT
        RewardType,
        RewardTemplateID,
        RewardAmount,
        TitleID,
        [dbo].[fnCreateTick](DATEADD(DAY, 7, SYSDATETIMEOFFSET())),
        ItemOption,
        [PostSupplyUniqueID]
    FROM
        TPostSupply
    WHERE
        @LastPostSupplyTime < StartDatetime 
        AND
        @CurrentDatetime BETWEEN StartDatetime AND EndDatetime
        AND
        DeletePFSeq IS NULL
    ;

    IF @@ROWCOUNT = 0
        RETURN;

    BEGIN TRY

        BEGIN TRAN;

        DECLARE @JsonPostRewardList VARCHAR(MAX);
        SET @JsonPostRewardList =
        (
            SELECT
                @AccountUniqueID [AID],
                0                [HID],
                0                [PT],
                TitleID          [TI],
                ExpireTick       [ET],
                (
                    SELECT
                        RewardType                                      [rt],
                        RewardTemplateID                                [rv],
                        RewardAmount                                    [rc],
                        -- RewardReceiveBind                               [rb], -- 우편 꺼낼 때 귀속여부
                        JSON_VALUE(ItemOption, '$.ItemOption1')         [o1],
                        JSON_VALUE(ItemOption, '$.ItemOption2')         [o2],
                        JSON_VALUE(ItemOption, '$.ItemOption3')         [o3],
                        JSON_VALUE(ItemOption, '$.SpecializedOption1') [so1],
                        JSON_VALUE(ItemOption, '$.SpecializedOption2') [so2],
                        JSON_VALUE(ItemOption, '$.ExpireTick')          [rm],
                        JSON_VALUE(ItemOption, '$.ao1')                 [ao1],
                        JSON_VALUE(ItemOption, '$.ao2')                 [ao2],
                        JSON_VALUE(ItemOption, '$.ao3')                 [ao3],

                        -- * 전체우편 지급은 HeroBind 를 사용할 수 없음.
                        -- JSON_VALUE(ItemOption, '$.ib')                [ib]
                        --                                             [huid]
                        1002                                            [rw],
                        56                                              [st],
                        [PostSupplyUniqueID]                            [si]
                    FOR
                        JSON PATH
                ) [R]
            FROM
                @PostReward
            FOR JSON PATH
        );

        EXEC [innerJsonPostRewardListProcess]
            @JsonPostRewardList = @JsonPostRewardList,
            @JsonPostResult     = NULL;


        
        UPDATE [TAccountShareData] SET [LastPostSupplyTime] = @CurrentDatetime  WHERE [AccountUniqueID] = @AccountUniqueID;
        SET @LastPushUpdateTime = @CurrentDatetime;

        COMMIT;

    END TRY
    BEGIN CATCH

        ROLLBACK;
        INSERT [TProcedureError] DEFAULT VALUES;

        -- THROW; -- 게임은 진행되게
    
    END CATCH
GO
/******************************************************************************
    name        : (SP)[spHeroSelectDetail]
    description : 캐릭터 정보 얻기

    2025.06.24      허세원     계정별 푸쉬 추가.
        @LastPostSupplyTime DATETIME OUTPUT 추가
******************************************************************************/
CREATE OR ALTER PROCEDURE [dbo].[spHeroSelectDetail_Imp]
    @AccountUniqueID    INT,
    @HeroUniqueID       BIGINT,
    @ServerTick         BIGINT, -- 서버시간  -- 0시

    @IsBellatraReward   TINYINT OUTPUT,  -- 0이 보상 안 받음 1이 보상 받음

    @LastPostSupplyTime DATETIME OUTPUT  -- 마지막 푸쉬 받은 시간.
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET @IsBellatraReward = 0;

    BEGIN TRY

        BEGIN TRAN

        DECLARE @CurrentTime        DATETIMEOFFSET = SYSDATETIMEOFFSET();
        DECLARE @LastWednesday5Hour DATETIMEOFFSET = [dbo].[fnLastDayOfTheWeekHour] (@CurrentTime, 3, 5);
        DECLARE @IsFirstLogin       TINYINT = [dbo].[fnIsFirstLogin] ( @AccountUniqueID, @HeroUniqueID, @LastWednesday5Hour );

        SELECT
            HeroName,
            HeroLevel,
            HeroExp,
            HeroClass,
            HeroStatus,
			[MaxHeroPower],
            [Str],
            [Dex],
            [Int],
            [Vit],
            [Wis],
            StatPoint,

            HP,
            MP,

            ZoneID,
            ROUND(PosX, 2) PosX,
            ROUND(PosY, 2) PosY,

            InventorySlotCount,

            CAST(CreateTime AS DATETIME) CreateTime,
            CAST(LogoutTime AS DATETIME) LogoutTime,
            DeleteDate,
            HeroLevel, -- 킹덤 RealLevel 언젠간 삭제하자

            H.Alarm,

            CASE WHEN DATEDIFF(DAY, B.LastPostSendDate, GETDATE()) > 0 THEN  0  ELSE B.PostCount END  PostCount,
            [LastPostSendDate],
            [MinPostUniqueID],
            H.[TitleID],
			C.AccumulationAccountPlaytime,
            H.AccumulationHeroPlaytime,
            1 - @IsFirstLogin as [HeroPowerRankTop3Popup], -- 0 일때 팝업해야함. 1 일때 띄었었음.
            H.HeroEquipWingID,
            H.[ExchangeRegistExpansionCount],
            IIF(H.[PartyRaidGiveHelpTime] IS NULL, DATEADD(DAY, -1, GETDATE()), [PartyRaidGiveHelpTime]) [PartyRaidGiveHelpTime],
            H.[GroupPresetID],
            H.[JewelPocketExpansionCount],
            H.[RevivalPenaltyCount],
            H.[RevivalRestrictTick],
            H.[SaviorLevel],
            H.[SaviorExp]
        FROM
            [THero]                    H  WITH(NOLOCK)
            JOIN [TPostCount]          B  WITH(NOLOCK) ON H.HeroUniqueID    = B.HeroUniqueID
            JOIN [TAccountShareData]   C  WITH(NOLOCK) ON H.AccountUniqueID = C.AccountUniqueID
        WHERE
            H.HeroUniqueID = @HeroUniqueID;

        DECLARE @PlaytimeLogUniqueID BIGINT;
        EXEC [innerPlaytimeLog]
            @PlaytimeLogUniqueID = @PlaytimeLogUniqueID OUTPUT,
            @AccountUniqueID     = @AccountUniqueID,
            @HeroUniqueID        = @HeroUniqueID,
            @IsLogin             = 1,
            @UpdateTime          = @CurrentTime
        ;

        UPDATE [THero] SET [PlaytimeLogUniqueID] = @PlaytimeLogUniqueID WHERE [HeroUniqueID] = @HeroUniqueID;

        IF @@ROWCOUNT <> 1
            THROW 50032, N'플레이 타임 정보 저장 실패', 1;

        IF EXISTS
            (
                SELECT
                    1
                FROM
                    [TBellatraResult]
                WHERE
                    [BellatraOpenTick] BETWEEN @ServerTick AND @ServerTick + 86400000 - 1
                    AND [HeroUniqueID] IN (SELECT [HeroUniqueID] FROM [THero] WHERE [AccountUniqueID] = @AccountUniqueID)
                    AND IsRewardOnce = 1
            )
        BEGIN
            SET @IsBellatraReward = 1;
        END

        COMMIT;

    END TRY
    BEGIN CATCH

        ROLLBACK;
        INSERT [TProcedureError] DEFAULT VALUES;
        THROW;

    END CATCH;

    BEGIN TRY

        EXEC [innerPostSupply_Imp]
            @AccountUniqueID    = @AccountUniqueID,
            @LastPushUpdateTime = @LastPostSupplyTime OUTPUT;

    END TRY
    BEGIN CATCH

        INSERT [TProcedureError] DEFAULT VALUES;

    END CATCH
GO
GRANT EXECUTE ON dbo.spHeroSelectDetail_Imp TO ROLE_GAMESERVER;
GO

/*
    캐릭터 접속중일 때 60초 마다 한번씩 호출 들어옴
    접속기준 +60초

    22.09.02    신현철     캐릭터 상태에 상관없이 업데이트, 계정 플레이시간이 낮아도 rowcount 나오도록
    2025.06.24      허세원     계정별 푸쉬 추가.
        @LastPostSupplyTime DATETIME OUTPUT 추가

*/
CREATE OR ALTER PROCEDURE [dbo].[spHeroUpdateInfoOnTime_Imp]
	@Result				         INT OUTPUT       ,
	-- Base
	@AccountUniqueID             INT              ,
	@HeroUniqueID                BIGINT           ,
	-- UpdateHeroInfo
	@HuntingExp                  BIGINT           ,
	@Hp                          INT              ,
	@Mp                          INT              ,
	@PosX                        FLOAT            ,
	@PosY                        FLOAT            ,
	@ZoneID                      INT              ,
	-- Consume Item
	@ConsumeItemJson             VARCHAR(MAX)     ,
    @JsonBuffUpdate              VARCHAR(MAX)     , -- 부여 버프
    @JsonBuffDelete              VARCHAR(MAX)     , -- 버프 삭제
    @JsonDungeonInfoHeroUpdate   VARCHAR(MAX)     , -- 던전 시간 
    @ServerTime                  DATETIME         , -- 서버 시간 
    @AccumulationAccountPlaytime BIGINT           , -- 계정 누적 플레이 타임
    @AccumulationHeroPlaytime    BIGINT           , -- 캐릭터 누적 플레이 타임
    @HeroPower                   INT              , -- 캐릭터 전투력
    @AccumulationExp             BIGINT           , -- 1분간 누적 경험치
    @HuntingSaviorExp            BIGINT           , -- 구원자 경험치

    @LastPostSupplyTime          DATETIME OUTPUT    -- 마지막 푸쉬 받은 시간.
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET @Result = -1;
    DECLARE @Count INT = 0;

    BEGIN TRY

        -- 소모품(포션) 수량 변경을 위한 테이블
        DECLARE @ConsumeItemTable TABLE
        (
            uniqueId bigint,
            cnt      int
        )
        
        IF isnull(@ConsumeItemJson, '') <> ''
        BEGIN
            
            INSERT @ConsumeItemTable
            SELECT
                id,
                cnt
            FROM
                OPENJSON ( @ConsumeItemJson )
                WITH
                (
                    id BIGINT '$.uid',
                    cnt INT '$.cnt'
                )

            SET @Count = @@ROWCOUNT;

        END

    END TRY
    BEGIN CATCH

        SET @Result = CASE WHEN ERROR_NUMBER() >= 50000 THEN ERROR_NUMBER() ELSE -2 END;
        INSERT TProcedureError DEFAULT VALUES;
        IF @Result = -2
            THROW;
        ELSE
            RETURN;
    END CATCH;

    BEGIN TRY
        BEGIN TRAN
            
            UPDATE
                TAccountShareData
            SET
                AccumulationAccountPlaytime = CASE WHEN AccumulationAccountPlaytime < @AccumulationAccountPlaytime THEN @AccumulationAccountPlaytime ELSE AccumulationAccountPlaytime END
            WHERE
                AccountUniqueID = @AccountUniqueID

            IF @@ROWCOUNT <> 1
                THROW 50022, N'계정 정보 저장 실패', 1;

            DECLARE @HeroClass INT;
            DECLARE @PlaytimeLogUniqueID BIGINT;

            UPDATE
                THero
            SET
                LogoutTime    = SYSDATETIMEOFFSET(),
                HeroExp       += @HuntingExp,
                HP            = @Hp,
                MP            = @Mp,
                PosX          = @PosX,            --5
                PosY          = @PosY,
                ZoneID        = @ZoneID,
                AccumulationHeroPlaytime = CASE WHEN AccumulationHeroPlaytime < @AccumulationHeroPlaytime THEN @AccumulationHeroPlaytime ELSE AccumulationHeroPlaytime END,
                HeroPower = @HeroPower,
                @HeroClass = HeroClass,
                @PlaytimeLogUniqueID = [PlaytimeLogUniqueID],
                [CheckFlag] = [CheckFlag] & ~(POWER(2, 5) | POWER(2, 7)),
                [SaviorExp]   += @HuntingSaviorExp
            WHERE
                HeroUniqueID = @HeroUniqueID;

            IF @@ROWCOUNT <> 1
                THROW 50023, N'캐릭터 정보 저장 실패', 1;

            UPDATE
                TItem
            SET
                StackCount = j.cnt
            FROM
                TItem AS i
                JOIN @ConsumeItemTable j ON i.ItemUniqueID = j.uniqueId and OwnerType = 2 AND i.OwnerUniqueID = @HeroUniqueID;

            IF @Count <> @@ROWCOUNT
                THROW 50024, N'아이템 소비 실패', 1;


            EXEC [innerJsonBuffUpdateProcess] @AccountUniqueID, @HeroUniqueID,  @JsonBuffUpdate;

            EXEC [innerJsonBuffDeleteProcess] @AccountUniqueID, @HeroUniqueID,  @JsonBuffDelete;

            EXEC [innerJsonDungeonInfoHeroUpdateProcess] @HeroUniqueID, @JsonDungeonInfoHeroUpdate, @ServerTime;

            DECLARE @CurrentTime   DATETIMEOFFSET = SYSDATETIMEOFFSET();

            /* 랭킹을 위한 누적 경험치 저장 */
            IF @AccumulationExp > 0
            BEGIN
                
                DECLARE @StandardTime  DATETIMEOFFSET = [dbo].[fnLastDayOfTheWeekHour] (@CurrentTime, 3, 5);
                SET @StandardTime = DATEADD(DAY, 7, @StandardTime); -- 기준을 다음 집계일자로
                
                UPDATE
                    [dbo].[TRankHeroExp]
                SET
                    [HeroExp] += @AccumulationExp
                WHERE
                    [Time] = @StandardTime
                    AND
                    [HeroUniqueID] = @HeroUniqueID;

                IF @@ROWCOUNT = 0
                BEGIN

                    INSERT [dbo].[TRankHeroExp] ([Time], [HeroUniqueID], [HeroExp] )
                    VALUES (@StandardTime, @HeroUniqueID, @AccumulationExp);

                END
            END

            EXEC [innerPlaytimeLog]
                @PlaytimeLogUniqueID = @PlaytimeLogUniqueID OUTPUT,
                @AccountUniqueID     = @AccountUniqueID,
                @HeroUniqueID        = @HeroUniqueID,
                @IsLogin             = 0,
                @UpdateTime          = @CurrentTime
            ;

            
        COMMIT;
        SET @Result = 0;

    END TRY
    BEGIN CATCH

        ROLLBACK;
        SET @Result = CASE WHEN ERROR_NUMBER() >= 50000 THEN ERROR_NUMBER() ELSE -2 END;
        INSERT TProcedureError DEFAULT VALUES;
        IF @Result = -2
            THROW;
        ELSE
            RETURN;

    END CATCH

    BEGIN TRY

        EXEC [innerPostSupply_Imp]
            @AccountUniqueID    = @AccountUniqueID,
            @LastPushUpdateTime = @LastPostSupplyTime OUTPUT;

    END TRY
    BEGIN CATCH


    END CATCH
GO
GRANT EXECUTE ON [dbo].[spHeroUpdateInfoOnTime_Imp] TO ROLE_GAMESERVER;
