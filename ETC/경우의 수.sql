
/*
4가지.

중복 허용, 순서가 중요하다			      cross join	            n^m		
중복 불가, 순서가 중요하다			      join not in	            n(n-1)(n-2)(n-3)		
중복 불가, 순서가 중요하지 않는다			join a < b < c < d	    N! / ((N-M)! M!)	=COMBIN(10, 3)	
중복 허용, 순서가 중요하지 않는다			join a <= b <= c <= d		                  =COMBINA(10, 3)	

옵션이 2개
    (ON, ON), (ON, OFF), (OFF, ON), (OFF, OFF)

    1. 중복으로 뽑을 수 있는가?
        중복이 가능할 떄 ON
    2. 순서가 있나?  (1, 2) <> (2, 1) 이게 참이면 순서가 있다.  (1, 2) == (2, 1) 이게 참이면 순서가 없다.
        순서가 있을때 ON


    (ON, ON)   = 복원 순열
    (ON, OFF)  = 복원 조합
    (OFF, ON)  = 비복원 순열
    (OFF, OFF) = 비복원 조합


    1	< 2	 < 3

    가장 낮은 순자를 왼쪽으로~

*/


/*
declare @aaa table ( id int ); -- 많이 넣어보기

declare @c int -- 랜덤으로 데이터 뽑기

insert @aaa values (110) -- 랜덤으로 데이터 넣기 ( 중복 값은 넣지 말기 ) @c 얘보단 작게 세팅
-- 데이터를 3개를 뽑아서 @c 에 가장 가깝게 만드는 데이터가 각각 무엇인가?
-- 중복으로 뽑는건 안됨

declare @aaa table ( id int ); -- 많이 넣어보기

declare @c int -- 랜덤으로 데이터 뽑기

insert @aaa values (110) -- 랜덤으로 데이터 넣기 ( 중복 값은 넣지 말기 ) @c 얘보단 작게 세팅
-- 데이터를 3개를 뽑아서 @c 에 가장 가깝게 만드는 데이터가 각각 무엇인가?
-- 중복으로 뽑는건 안됨
*/
SET NOCOUNT ON;

DECLARE @R INT = FLOOR(RAND(CHECKSUM(NEWID())) * 40) + 10
SET @R = 3333
SELECT @R

DECLARE @Table TABLE ([No] INT);
WITH R AS
(
    SELECT 1 N
    UNION ALL
    SELECT N+1 FROM R WHERE N < 1000
)
INSERT @Table
SELECT * FROM R 
OPTION (MAXRECURSION 0)

DROP TABLE IF EXISTS GameManage.dbo.TRandom
SELECT * INTO GameManage.dbo.TRandom  FROM 
(
    SELECT DISTINCT FLOOR(RAND(CHECKSUM(NEWID())) * 1000) R 
    FROM @Table 
) A WHERE R <> 0 AND R < @R

--DECLARE @a INT = 25

SELECT * FROM dbo.TRandom

SELECT * FROM 
(
    SELECT 
        A.R R1, B.R R2, C.R R3, A.R + B.R + C.R Result, RANK() OVER(ORDER BY A.R + B.R + C.R DESC) RR
    FROM 
        dbo.TRandom A 
        CROSS JOIN dbo.TRandom B 
        CROSS JOIN dbo.TRandom C
    WHERE
        A.R + B.R + C.R <= @R
        AND A.R <> B.R AND A.R <> C.R AND B.R <> C.R
) A WHERE RR = 1


----------------------------------------------------------------------

SET NOCOUNT ON;

DECLARE @R INT = FLOOR(RAND(CHECKSUM(NEWID())) * 40) + 10
SET @R = 3333
SELECT @R

DECLARE @Table TABLE ([No] INT);
WITH R AS
(
    SELECT 1 N
    UNION ALL
    SELECT N+1 FROM R WHERE N < 1000
)
INSERT @Table
SELECT * FROM R 
OPTION (MAXRECURSION 0)

DROP TABLE IF EXISTS GameManage.dbo.TRandom
SELECT * INTO GameManage.dbo.TRandom  FROM 
(
    SELECT DISTINCT FLOOR(RAND(CHECKSUM(NEWID())) * 1000) R 
    FROM @Table 
) A WHERE R <> 0 AND R < @R



--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*--*


WITH NUM AS
(
    SELECT 0 N
    UNION ALL
    SELECT N + 1 FROM NUM WHERE N < 9
)
SELECT
    *
FROM
    NUM A
    JOIN NUM B ON B.N NOT IN (A.N)
    JOIN NUM C ON C.N NOT IN (A.N, B.N)
    JOIN NUM D ON D.N NOT IN (A.N, B.N, C.N)

  
WITH NOC AS
(
    SELECT 0 N
    UNION ALL
    SELECT N + 1 FROM NOC WHERE N < 9
)
SELECT N, N*4 R FROM 
(
    SELECT 
        CAST(
        CAST(A.N AS VARCHAR(10)) + 
        CAST(B.N AS VARCHAR(10)) +
        CAST(C.N AS VARCHAR(10)) + 
        CAST(D.N AS VARCHAR(10))
        AS INT) N
    FROM 
        NOC A
        CROSS JOIN NOC B
        CROSS JOIN NOC C
        CROSS JOIN NOC D
) A
WHERE
    N = REVERSE(N*4)
