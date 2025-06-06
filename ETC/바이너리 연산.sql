-- 원래 있는 값
DECLARE @DATA BINARY(125) = 0x0127489172894718927894178927489172

-- 바이너리 끼리 비트 연산이 안되기 때문에 정수형으로 변경하고 싶다.
-- tinyint, smallint, int, bigint
-- 비트 연산을 하고 싶다!

-- 0x0127489172894718927894178927489172
-- 0x1127489172894718927894178927489172 
-- 첫 번째 바이트를 1로 변경하고 싶다.
-- 두 번째 바이트인 0x27 을 가져옴 이게 의미가 있을까? 의미 X
-- 내가 원하는 바이트만 쏙 

-- 0x0127489172894718927894178927489172
-- 이 중에 내가 원하는 바이트가 어디에 있냐?
-- 왼쪽으로 부터 (0부터 시작) 99 번째 비트는 어디에 있나?
-- 1 바이트가 8 비트이니까
-- select 99 / 8 <- 12 번째 바이트에 있다 (0 부터 시작)

--  그런데 서브스트링은 1부터 시작이니까
SELECT SUBSTRING(0x0127489172894718927894178927489172, 12 + 1, 1)

-- 0x89

-- 이걸 왼쪽으로 부터 2번째 (0부터) 비트를 on 하고 싶다.

-- SELECT 0x89 | ??
-- ?? 어떻게 ? select (8-1) - 2
SELECT 0x89 | power(2, 5)
-- select cast(169 as binary(1)) -- A9

SELECT
    SUBSTRING(0x0127489172894718927894178927489172, 12 + 1, 1),
    SUBSTRING(0x0127489172894718927894178927489172, 1, 12),
    SUBSTRING(0x0127489172894718927894178927489172, 14, 125),


    SUBSTRING(0x0127489172894718927894178927489172, 1, 12) +
    0xA9 +
    SUBSTRING(0x0127489172894718927894178927489172, 14, 125)
SELECT @DATA

--*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*----*--

/*
    정보의 상태가 2개 라서
        ON, OFF, 
        ISREWARD

    상태가 2개니까 비트연산으로 처리가 가능하다. (0, 1)

        0x012748917289471892789417892748
        어떤 비트에 값을 ON ( 1) 만드는 프로시저
        각각의 비트를 전부 컬럼으로 생각한다.
        EXEC dbo.spTest03 @NO = 8
        0 부터 시작해서 8 번째 컬럼의 값을 1로 변경한다.
        Case1
            0 부터 시작해서 8 번째 컬럼의 값을 0로 변경한다.

        계산기에서 보는게 2진수


    상태가 3개 (0,1,2) 가능하다는것만 알아두시고 진짜 사용해야할때 (챗 GPT)
        a, b, c
        비트로 할 수가 없다.
        EXEC dbo.spTest03 @DATA = 0x00, @NO = 0, @V = 2 -- 0x02
        EXEC dbo.spTest03 @DATA = 0x00, @NO = 1, @V = 0 

        0x1234124 => 3 진수로 변경가능??
        122112102(3) => 16진수로 변경.

    상태가 4개 (0,1,2,3)
        EXEC dbo.spTest03 @DATA = 0x00, @NO = 0, @V = 2 -- 0x02 
        EXEC dbo.spTest03 @DATA = 0x00, @NO = 0, @V = 3 -- 0x03
        EXEC dbo.spTest03 @DATA = 0x00, @NO = 1, @V = 3 -- 0x0C

        4 진수
        0 -> 1 -> 2 -> 3 -> 10

        00000(4)  3번째를 1로 바꾸고 싶다. => 0 0 1 0 0(4)

        4진수 2진수는 연관이 크다. 딱 나눠짐.
            4을 2의 n 승으로 표현할 수 있다. (정수로 안됨)

        8진수 2진수는 연관이 크다. 딱 나눠짐. 
            8을 2의 n 승으로 표현할 수 있다. (정수로 안됨)


    상태가 10개
        0x00 <- 16진수
        10 진수로 표현   00000 5개 5개의 컬럼이 있다. 뒤에서 부터 0번째

        0 번째를 1로 변경   00001
        0 번째를 3으로 변경 00003
        2 번째를 3으로 변경 10300
        

*/

