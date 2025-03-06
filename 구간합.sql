
DECLARE @T TABLE (AccountUniqueID INT, ServerID INT, Mileage INT)
DECLARE @Temp TABLE (AccountUniqueID INT, Mileage INT)

--DECLARE @TMileage TABLE (AccountUniqueID INT, TransferNo INT, Mileage INT)

INSERT @T
SELECT AccountUniqueID, InServer, 200 Mileage FROM dbo.[Transfer] WHERE TransferNo = 1;

DECLARE @I INT = 2;

WHILE 1 = 1
BEGIN

    DELETE FROM @Temp;
    INSERT @Temp
    SELECT A.AccountUniqueID, B.Mileage FROM dbo.[Transfer] A JOIN @T B ON A.AccountUniqueID = B.AccountUniqueID AND A.OutServer = B.ServerID WHERE TransferNo = @I

    IF @@ROWCOUNT = 0
        BREAK;

    DELETE B FROM dbo.[Transfer] A JOIN @T B ON A.AccountUniqueID = B.AccountUniqueID AND A.OutServer = B.ServerID WHERE TransferNo = @I;

    INSERT @T
    SELECT
        AccountUniqueID, InServer,
        200 + ISNULL((SELECT SUM(Mileage) FROM @Temp B WHERE A.AccountUniqueID = B.AccountUniqueID), 0)
    FROM
        dbo.[Transfer] A 
    WHERE
        TransferNo = @I;

    SET @I += 1;
END

SELECT * FROM @T WHERE AccountUniqueID = 1
SELECT AccountUniqueID, ServerID, SUM(Mileage) FROM @T WHERE AccountUniqueID = 1 GROUP BY AccountUniqueID, ServerID

SELECT * FROM @Temp

--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*
  
SET NOCOUNT ON;

DECLARE @No              INT = 0;
DECLARE @AccountUniqueID INT;
DECLARE @TransferNo      INT;
DECLARE @OutServer       INT;
DECLARE @InServer        INT;
DECLARE @Mileage         INT;

DECLARE @M TABLE (Mileage INT);

DECLARE @TMileage TABLE ([No] INT, Mileage INT);
WITH M AS ( SELECT 1 N, 200 M UNION ALL SELECT N + 1, M FROM M WHERE N < 20 ) INSERT @TMileage SELECT * FROM M

DECLARE @T1108 TABLE (AccountUniqueID INT, TransferNo INT, Outserver INT, InServer INT, Mileage INT);

WHILE 1 = 1
BEGIN

    SELECT TOP 1 
        @No = RowNo,
        @AccountUniqueID = AccountUniqueID,
        @TransferNo      = TransferNo,
        @OutServer       = OutServer,
        @InServer        = InServer,
        @Mileage         = Mileage
    FROM 
    (
        SELECT *, ROW_NUMBER() OVER(ORDER BY AccountUniqueID, TransferNo) RowNo FROM [Test].[dbo].[Transfer] A
        JOIN @TMileage B ON A.TransferNo = B.[No]
         --WHERE  AccountUniqueID BETWEEN 1 AND 2000
         WHERE  AccountUniqueID = 1
    ) A
        WHERE
            @No < RowNo
        ORDER BY RowNo

    IF @@ROWCOUNT = 0
        BREAK;

    INSERT @T1108 (AccountUniqueID, TransferNo, Outserver, InServer, Mileage)
    SELECT @AccountUniqueID, @TransferNo, @OutServer, @InServer, @Mileage;

    IF EXISTS
    (
        SELECT 1 FROM @T1108 WHERE AccountUniqueID = @AccountUniqueID AND TransferNo < @TransferNo AND InServer = @OutServer
    )
    BEGIN

        SELECT @Mileage += Mileage FROM @T1108 WHERE AccountUniqueID = @AccountUniqueID AND TransferNo < @TransferNo AND InServer = @OutServer

        UPDATE 
            @T1108
        SET
            Mileage = @Mileage 
        WHERE
            AccountUniqueID = @AccountUniqueID
            AND TransferNo = @TransferNo 

        UPDATE 
            @T1108
        SET
            Mileage = 0
        WHERE
            AccountUniqueID = @AccountUniqueID
            AND TransferNo < @TransferNo 
            AND InServer = @OutServer

    END

END

SELECT AccountUniqueID, InServer ServerID, SUM(Mileage)  Mileage
--INTO Test.dbo.OK2
FROM @T1108 GROUP BY AccountUniqueID, InServer HAVING SUM(Mileage) <> 0


--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*

--게임에 적용 했던거

SET NOCOUNT ON;

DECLARE @T TABLE (AccountUniqueID INT, ServerID INT, Mileage INT)
DECLARE @Temp TABLE (AccountUniqueID INT, Mileage INT)

DROP TABLE IF EXISTS GameManage.dbo.T1113_HSW 
SELECT
    TransferUniqueID,
    OutServerID,
    InServerID,
    GuildUniqueID,
    AccountUniqueID,
    HeroUniqueID,
    [Status],
    FailCount,
    UpdateDate,
    CreateDate,
    ROW_NUMBER() OVER(PARTITION BY AccountUniqueID ORDER BY TransferUniqueID) TransferNo
INTO GameManage.dbo.T1113_HSW
FROM 
    [User].[dbo].[TTransferForm]
    CROSS APPLY OPENJSON (HeroJson) WITH (AccountUniqueID INT '$.a', HeroUniqueID BIGINT '$.h') 
WHERE
    '2024-11-01 00:00:00 +09:00' <= [CreateDate] and [CreateDate] < '2024-11-07 16:00:00 +09:00'

--SELECT * FROM GameManage.dbo.T1113_HSW 

INSERT @T
SELECT AccountUniqueID, InserverID, 200 Mileage FROM GameManage.dbo.T1113_HSW WHERE TransferNo = 1;

DECLARE @I INT = 2;
WHILE 1 = 1
BEGIN

    DELETE FROM @Temp
    INSERT @Temp
    SELECT A.AccountUniqueID, Mileage FROM GameManage.dbo.T1113_HSW A JOIN @T B ON A.AccountUniqueID = B.AccountUniqueID AND A.OutServerID = B.ServerID WHERE TransferNo = @I;

    IF @@ROWCOUNT = 0
        BREAK;

    DELETE B FROM GameManage.dbo.T1113_HSW A JOIN @T B ON A.AccountUniqueID = B.AccountUniqueID AND A.OutServerID = B.ServerID WHERE TransferNo = @I;

    INSERT @T
    SELECT 
        AccountUniqueID,
        InServerID,
        200 + ISNULL((SELECT SUM(Mileage) FROM @Temp B WHERE A.AccountUniqueID = B.AccountUniqueID), 0)
    FROM
        GameManage.dbo.T1113_HSW A
    WHERE
        TransferNo = @I;

    SET @I += 1;

END

SELECT AccountUniqueID, ServerID, SUM(Mileage) Mileage FROM @T GROUP BY AccountUniqueID, ServerID
