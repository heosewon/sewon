USE [User]
GO
DROP TABLE IF EXISTS dbo.TAccountPostSupplyCheck
CREATE TABLE dbo.TAccountPostSupplyCheck
(
    AccountUniqueID    INT             NOT NULL,
    ServerID           INT             NOT NULL,
    LastPostSupplyTime DATETIMEOFFSET  NOT NULL,
    [ServerGroupID]    AS              ([dbo].[fnServerGroupID]([ServerID])) PERSISTED NOT NULL, -- 계산된 열로..
    CONSTRAINT PK_TAccountPostSupplyCheck PRIMARY KEY (AccountUniqueID)
);
GO
/*
    푸쉬 우편 계정 단위 체크 리스트

    2025.06.24      허세원     최초생성.
*/
CREATE OR ALTER PROCEDURE dbo.spAccountPostSupplyCheckList
    @AccountUniqueID     INT
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

    BEGIN TRY
        
        SELECT
            ServerID,
            CAST(LastPostSupplyTime AS DATETIME) LastPostSupplyTime,
            ServerGroupID
        FROM 
            dbo.TAccountPostSupplyCheck
        WHERE
            AccountUniqueID = @AccountUniqueID
        UNION ALL
        SELECT 0, '1900-01-01 00:00:00', 0
        ;

    END TRY

    BEGIN CATCH
        
        INSERT dbo.TProcedureError DEFAULT VALUES;
        THROW;

    END CATCH
GO
GRANT EXECUTE ON dbo.spAccountPostSupplyCheckList TO ROLE_GAMESERVER;
GO
/*
    푸쉬 우편 계정 단위 체크
        * 어느 서버든 푸쉬 지급되는 순간 무조건 Update
          
    @LastPostSupplyTime GameServer에 DATETIME으로 OUTPUT을 주기 때문에 Type DATETIME
    
    2025.06.24      허세원     최초생성.
*/
CREATE OR ALTER PROCEDURE dbo.spAccountPostSupplyCheck
    @Result              INT OUTPUT,
    @AccountUniqueID     INT,
    @ServerID            INT,
    @LastPostSupplyTime  DATETIME
AS
    SET NOCOUNT, XACT_ABORT ON;
    SET @Result = -1;
    DECLARE @LastPostSupplyTimeOffset DATETIMEOFFSET = TODATETIMEOFFSET(@LastPostSupplyTime, dbo.fnCreateTimeZone());

    BEGIN TRY
        BEGIN TRAN spAccountPostSupplyCheck;
        
        UPDATE 
            dbo.TAccountPostSupplyCheck
        SET
            ServerID           = @ServerID,
            LastPostSupplyTime = @LastPostSupplyTimeOffset
        WHERE
            AccountUniqueID = @AccountUniqueID
            AND LastPostSupplyTime <= @LastPostSupplyTimeOffset
        ;

        IF @@ROWCOUNT = 0
        BEGIN 
            INSERT dbo.TAccountPostSupplyCheck (AccountUniqueID, ServerID, LastPostSupplyTime)
            VALUES (@AccountUniqueID, @ServerID, @LastPostSupplyTimeOffset);
        END


        SET @Result = 0;
        COMMIT TRAN;
    END TRY

    BEGIN CATCH
        ROLLBACK TRAN;

        SET @Result = -2;
        INSERT dbo.TProcedureError DEFAULT VALUES;
        THROW;

    END CATCH
