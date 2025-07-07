-- 임시 테이블 테스트 쿼리
DECLARE @JSON VARCHAR(MAX) = (SELECT TOP 100 ItemUniqueID FROM [dbo].[TItem] ORDER BY NEWID() FOR JSON AUTO)
DROP TABLE IF EXISTS #TEMP;

DECLARE @START DATETIMEOFFSET = SYSDATETIMEOFFSET();

CREATE TABLE #TEMP  (
[ItemUniqueID] BIGINT
);
INSERT #TEMP SELECT * FROM OPENJSON( @JSON ) WITH ( ItemUniqueID BIGINT );

DECLARE @X BIGINT
SELECT @X = A.ItemUniqueID FROM [dbo].[TItem] A JOIN #TEMP B ON A.[ItemUniqueID] = B.[ItemUniqueID];

DECLARE @END DATETIMEOFFSET = SYSDATETIMEOFFSET();

SELECT DATEDIFF(MICROSECOND, @START, @END);



-- 테이블 변수 테스크 쿼리
DECLARE @JSON VARCHAR(MAX) = (SELECT TOP 100 ItemUniqueID FROM [dbo].[TItem] ORDER BY NEWID() FOR JSON AUTO)

DECLARE @START DATETIMEOFFSET = SYSDATETIMEOFFSET();

DECLARE @TEMP TABLE (
[ItemUniqueID] BIGINT
);
INSERT @TEMP SELECT * FROM OPENJSON( @JSON ) WITH ( ItemUniqueID BIGINT );

DECLARE @X BIGINT
SELECT @X = A.ItemUniqueID FROM [dbo].[TItem] A JOIN @TEMP B ON A.[ItemUniqueID] = B.[ItemUniqueID];

DECLARE @END DATETIMEOFFSET = SYSDATETIMEOFFSET();

SELECT DATEDIFF(MICROSECOND, @START, @END);

SELECT COUNT(*) FROM dbo.TItem

--------------------------------------------------------------------------------------------------------------------
Live - TItem 
14,465,581건

1. SELECT TOP 2000 까지 전부 Index Seek, Nested Loop 속도 차이 크게 없음.

Dev - TItem 
12,755건

1. SELECT TOP 2000 까지 임시 테이블 테이블 풀스캔 Mergejoin, Sort 작업 들어감  
2. 테이블 변수 Index Seek, Nested Loop
  
