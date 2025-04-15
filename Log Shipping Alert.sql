USE [master]
GO
CREATE PROCEDURE [dbo].[schLogShippingCheck]
AS
    SET NOCOUNT, XACT_ABORT ON;

    BEGIN
    
        DECLARE @LimitMinute INT = 120;
        DECLARE @CurrentTime DATETIMEOFFSET = SYSDATETIMEOFFSET();
        DECLARE @TimeZone    INT = DATEPART(TZ, SYSDATETIMEOFFSET());

        DECLARE @TLogShippingList TABLE ([DB] NVARCHAR(30), [LastRestoredFileTime] DATETIMEOFFSET);

        INSERT @TLogShippingList ([DB], [LastRestoredFileTime])
        SELECT 
            [DB],
            [LastRestoredFileTime]
        FROM
        (
            SELECT 
                secondary_database [DB], 
                SWITCHOFFSET(FORMAT(CAST(LEFT(RIGHT(last_restored_file, 18), 14) AS BIGINT), '####-##-## ##:##:##'), @TimeZone) [LastRestoredFileTime]
            FROM
                msdb.dbo.log_shipping_monitor_secondary
        ) X
        WHERE 
            DATEDIFF(MINUTE, [LastRestoredFileTime], @CurrentTime) >= @LimitMinute
            AND [LastRestoredFileTime] >= '2024-01-01 00:00:00.000';

        IF @@ROWCOUNT = 0
        BEGIN
            RETURN;
        END
        ELSE
        BEGIN
            DECLARE @ServerName VARCHAR(20) =
            (
                SELECT
                    CASE CONNECTIONPROPERTY('local_net_address') 
                        WHEN '' THEN 'TW-Live-BackupDB'
                        WHEN ''  THEN 'KR-Live-BackupDB'
                    END
            )
            INSERT dbo.DBStatus ([Nation], [Time], [Why], [Subject], [Body], [ServerName], [DBName])
            SELECT
                LEFT(@ServerName, 2)                                                                   [Nation],
                CAST(@CurrentTime AS DATETIME)                                                         [Time],
                N'로그 쉬핑 문제 있음'                                                                 [Why],
                DB + '-' + N'로그 쉬핑 확인 바람'                                                      [SubJect],
                DB + '-' + N'마지막 복원 시간' + FORMAT(LastRestoredFileTime, '(yyyy-MM-dd HH:mm:ss)') [Body],
                @ServerName                                                                            [ServerName],
                DB                                                                                     [DBName]
            FROM 
                @TLogShippingList;

            --Mail
            DECLARE @TABLE_HTML NVARCHAR (MAX);
            SET @TABLE_HTML =
                N'<br><br>' +
                N'<H3>' + @ServerName + '</H3>' +
                N'<table border="1">' +  
                N'<tr><th>DB</th><th>LastRestoredFileTime</th></tr>' +  
                CAST((
                    SELECT
                        td = DB,       '',  
                        td = N'마지막 복원 시간 : ' + FORMAT(LastRestoredFileTime, 'yyyy-MM-dd HH:mm:ss')
                    FROM @TLogShippingList
                    ORDER BY DB
                    FOR XML PATH('tr'), TYPE
                ) AS NVARCHAR(MAX))

            EXEC msdb..sp_send_dbmail @profile_name =  N'DBMail',
                                      @recipients   =  N'swheo@',
                                      @subject      =  N'대만 로그 쉬핑',
                                      @body         =  @TABLE_HTML,
                                      @body_format  = 'HTML';

        END

    END
