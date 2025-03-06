SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- 이 방법이 어떻게 동작하길래 더티리드가 발생되지 않는가?

-- 커밋되지 않은 데이터는 읽지 않는다.
--    이걸  SQL SERVER 개발자들은 어떻게 구현했을까요?

-- 셀렉트를 할 때 S-LOCK 획득을 시도한다.


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- 셀렉트를 할 때 S-LOCK 획득을 시도하지 않는다. WITH (NOLOCK)
-- 데이터가 수정될 때 X-LOCK 이 걸리기 때문에 S-LOCK 획득을 시도하면 기다리는 상태가 된다.



-------------------------------------------------------------------------------------------


SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
-- 이 방법이 어떻게 동작하길래 NON REPEATABLE READ 가 발생되지 않는가?

-- 다른 트랜잭션에서 수정이 불가능하게 막는다.
-- 트랜잭션이 획득을 했던 S-LOCK 을 트랜잭션이 끝나야 반납한다.
SELECT HeroLevel FROM GAME.DBO.THero WHERE HeroUniqueID = 478; -- S-LOCK 획득. 

-- S-LOCK 을 반납을 안하니까 다른 트랜잭션에서 X-LOCK 을 획득할 수 없음 = 기다림.

SELECT HeroLevel FROM GAME.DBO.THero WHERE HeroUniqueID = 478; -- 그래서 같은 결과가 나오게 됨. 


SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
-- 얘들은 왜 발생될까?
-- 트랜잭션이 끝나기 전에 획득을 했던 S-LOCK 을 반납한다.

SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
BEGIN TRAN;

SELECT HeroLevel FROM GAME.DBO.THero WHERE HeroUniqueID = 478; -- S-LOCK 획득.
-- S-LOCK 반납 (릴리즈)

-- 다른 트랜잭션에서 X-LOCK 을 획득할 수 있음 = 수정할 수 있음

SELECT HeroLevel FROM GAME.DBO.THero WHERE HeroUniqueID = 478;

ROLLBACK;




-------------------------------------------------------------------------------------------



SET TRANSACTION ISOLATION LEVEL SERIALIZABLE;
-- 이 방법이 어떻게 동작하길래 팬텀 리드가 발생되지 않는가?
BEGIN TRAN;

SELECT * FROM GAME.DBO.TEST_A WHERE ID = 11000; -- 셀렉트를 했더니 결과가 없음.

-- 이 현상을 방지하는건 여러가지 방법이 존재
-- 각 RDBMS 마다 다르게 구현되어있음
-- SQL SERVER 에서 하는 방법이 정론은 아님.

-- 테이블 잠금 = 직렬화
SELECT * FROM GAME.DBO.TEST_A WHERE ID = 11000;

ROLLBACK;



SELECT HeroLevel FROM GAME.DBO.THero WHERE HeroUniqueID = 4781111; -- 그래서 같은 결과가 나오게 됨. 

----------------
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ; 
SET TRANSACTION ISOLATION LEVEL READ COMMITTED;
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;
-- 얘들은 왜 발생될까?

BEGIN TRAN

SELECT HeroLevel FROM GAME.DBO.THero WHERE HeroUniqueID = 4781111; -- 셀렉트를 했더니 결과가 없음.
-- 잠금을 걸 대상이 없다.

-- 다른 트랜잭션이 INSERT 를 할 수 있음.

SELECT HeroLevel FROM GAME.DBO.THero WHERE HeroUniqueID = 4781111; -- 결과가 있음.

ROLLBACK;
