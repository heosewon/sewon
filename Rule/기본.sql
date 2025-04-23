# 기본

- 서버에서 3001-01-19 22:00:00.000 이후 부터 인식불가
- 모든 국가간 스키마가 동일하게 관리 될 수 있도록 설계
- 라이브에서 사용된 쿼리는 따로 저장해서 가지고 있기
- 라이브에서 Delete 및 Update 를 할 때 테이블 한 번 백업

# 서버

- Server Collation = Korean_Wansung_CI_AS
    - 설치 할 때 지정할 수 있다.
    - 이미 설치된 장비를 받은경우 데이터베이스 Collate 설정을 잘 설정해서 사용
- SQL Server 메모리는 Physical Memory 에 맞게 설정할것 (70% ~ 90% 권장)

# 데이터베이스

- Transaction Log Backup 이 필요없는 데이터베이스은 Recovery Mode Simple 로 설정
    - Live 를 제외한 모든 데이터베이스는 Simple 로 설정
- Database Collation = Korean_Wansung_CI_AS
    - COLLATE 옵션을 지정안하면 Server Default Collation 으로 되므로 항상 지정하는 습관을 들이자.
    
    ```sql
    CREATE DATABASE [GameHistory]
        CONTAINMENT = NONE
        ON PRIMARY 
        (
            NAME = N'GameHistory',
            FILENAME = N'D:\SQL SERVER DATA\GameHistory.mdf',
            SIZE = 8192KB,
            FILEGROWTH = 65536KB 
        )
        LOG ON 
        (
            NAME = N'GameHistory_log',
            FILENAME = N'D:\SQL SERVER DATA\GameHistory_log.ldf',
            SIZE = 8192KB,
            FILEGROWTH = 65536KB
        )
        COLLATE Korean_Wansung_CI_AS
    GO
    ```
    
- 서비스 중에 자동증가가 이루어지면 렉이 발생할 수 있으므로 처음 크기를 여유있게 지정하고 점검 및 매일 마다 데이터가 얼마나 쌓이는지 확인한다. 추세를 확인하여 점검 이후 증가가 될 것 같다면 점검 날 미리 파일 크기를 늘린다.
- 파일 최대 크기는 제한 없음으로 지정한다.

# 테이블

- Table Collation = Korean_Wansung_CI_AS
    - 데이터베이스 Collation 을 잘 설정했다면 문제 없다.
- 클러스터드 키가 항상 존재하도록 설계
- 실제 게임에 사용되는 데이터베이스에 임시테이블 생성하지 않기
    - 예외
        - [라이브 상황에서 급하게 프로시저 실행 될 때 데이터를 수집해서 저장해야하는 상황이 온다면 프로시저와 같은 데이터베이스에서 데이터를 저장하도록 한다.](https://www.notion.so/1cbf86512ae680068633cc5a3e03e6b2?pvs=21)

# 프로시저

- 프로시저는 최대한 다른 사람이 이해할 수 있도록
    - 특정 로직이 성능이 월등이 좋을경우에는 지키지 않아도 괜찮다.
- 프로시저 작성할 때 들여쓰기는 탭이 아닌 공백으로 처리
- 프로시저 작성할 때 들여쓰기는 다양한 방법으로 해도 좋지만 일관성 있게할 것
    - 들여쓰기를 안하는건 안됨
- SET NOCOUNT, XACT_ABORT ON 는 필수로 작성
- Warning : NULL value is eliminated by an aggregate or other SET operation.
    - 이 경고가 서버에 전달되지 않도록
- 항상 BEGIN TRY ~ END TRY BEGIN CATCH ~ END CATCH 구문 사용해서 작성
- INSERT 구문 작성할 때 컬럼 지정하기
    - 테이블 변수는 지정하지 않아도 괜찮다.
- 프로시저 생성시 CREATE 문에 [dbo].[ProcedureName] 으로 생성할것
    
    ```sql
    CREATE PROCEDURE ProcedureName  -- X
    
    CREATE PROCEDURE dbo.ProcedureName  -- X
    
    CREATE PROCEDURE [dbo].[ProcedureName] -- O
    ```
    
    - 스크립트를 생성할 때 만들었던 그대로 표기되어서 생성된다. 스크립트를 비교해서 모든 서버와 프로시저가 같은지 다른지를 비교할 때 이렇게 통일하지 않으면 문제가 발생될 수 있다.
- 트랜잭션을 열 때 (BEGIN TRAN) 이름을 지정하도록 한다.
    - Transaction Log 파일을 읽을 때 도움이 된다.
- 프로시저 에러번호는 50000 이후로 설정
    - SQL Server 기본 에러번호랑 충돌 방지 및 THROW 로 에러관리 편리
- 라이브 상황에서 급하게 프로시저 실행 될 때 데이터를 수집해서 저장해야하는 상황이 온다면 프로시저와 같은 데이터베이스에서 데이터를 저장하도록 한다.
    
    ```sql
    ALTER PROCEDURE [dbo].[ProcedureName]
    AS
    		-- [Game] 데이터베이스에서 실행되는 프로시저인데 [GameManage] 에 저장하도록 되어있다.
    		-- 이렇게 하지말고 [Game] 에 데이터가 저장되도록 한다.
    		-- 편하게 데이터베이스 부분은 제거하고 SELECT * INTO [dbo].[TQuestdaily_0403_0500] 이런식으로 만든다.
        SELECT * INTO GameManage.dbo.TQuestDaily_0403_0500 FROM Game.dbo.TQuestDaily WITH (NOLOCK);
    
        BEGIN TRY
    			
    				...
    
        END TRY
        BEGIN CATCH
            
            INSERT TProcedureError DEFAULT VALUES;
    
        END CATCH
    ```
    
    - 프로시저와 같은 데이터베이스, 스키마가 동일하다면 권한을 따로 주지 않아도 된다.
        - 주의 ! 스키마까지 동일해야함.
        프로시저 스키마가 [test].[ProcedureName] 인데 테이블에 [dbo].[temp_table]  안됨.
- 테이블 변수 만들 때 PK 를 걸수있는 경우라면 걸자.
    
    ```sql
    DECLARE @PostUIDList TABLE (PostUniqueID BIGINT PRIMARY KEY);
    ```
    
- ORDER BY 절에 숫자 입력 금지
    
    ```sql
    ORDER BY [ColumnName]  -- 이렇게 컬럼 이름으로 명시
    
    ORDER BY 2  -- 이런식으로 컬럼 순서에 대해서 정렬 금지
    ```
    
- 정규화된 이름 사용
    
    ```sql
    -- 테이블 및 다른 프로시저 등 사용할 때
    Select * From [dbo].[THero] -- 스키마 이름을 지정해 줄것.
    ```
