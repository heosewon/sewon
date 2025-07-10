/*
100만 동시 접속 환경에서 실시간 조회수 집계 방법 설계
    특정 콘텐츠(예: 게시물 등 )의 조회수를 실시간으로 집계하여 DB에 저장해야합니다. 
    100만 동시 접속자가 존재하는 환경에서 효율적으로 조회수를 저장하고 관리할 방법을 설계하세요. 
    성능, 확장성, 데이터 정확성을 모두 고려해야 하며 효율적인 데이터 설계 와 구성 방안을 생각해주세요.

    클라이언트에서는 실시간으로 조회수 카운팅을 해주고
    디비와 동기화를 1분에 한번씩 해줌

    성능
        ContentID별로 하나씩 처리하기 보다 Json으로 받아 sp 호출수를 줄임.
        Json 파싱을 먼저 하고 transaction 시간을 조금이라도 줄임.
        DB 동기화를 1분에 한번씩 누적 전송으로 부담 줄임.

        동기화 프로시저에서 Merge를 사용하여 구문을 간결하게 할 수 있지만
        Outerjoin이 들어가기때문에 Insert, Update가 더 최적이라고 판단.

    확장성
        ContetType 타입별로 ContentID가 종속되어있고, ContentID는 전부 유니크함
        조회수 테이블엔 ContentID와 Count만 존재.
        새로운 컨텐츠의 조회수를 카운팅해도 동기화 프로시저에서 Insert하기에
        프로시저외 테이블에 별도 작업이 필요하지 않음.

    정확성
        서버에서 보내준 변경정보와 실제 테이블에 영향받은 수가 다르면 예외처리.
        서버가 알고있는 디비 Count값 실제 디비 Count값이 일치해야 변경될 Count로 Update.
*/
-- Table
CREATE TABLE dbo.TViewCount
(   
    ContentID   INT    NOT NULL,
    Count       INT    NOT NULL,
    CONSTRAINT PK_TViewCount PRIMARY KEY (ContentID)
)
GO
-- List Procedure
DECLARE @ContentID INT = 100001; 

SELECT 
    [Count]
FROM 
    dbo.TViewCount
WHERE
    ContentID = @ContentID
;

-- Update Procedure 1분에 한번씩 동기화 작업 ( Flag 1 : Insert, 2 : Update)
DECLARE @Result    INT; -- OUTPUT -1:. 기본 실패값, 0 : 성공, -2 : 익셉션
DECLARE @JsonCount VARCHAR(8000) = '[{"ci" :..., "pt" : ...., "c" : ...., "f"....}, {.....}]';

SET @Result = -1;
DECLARE @TJson TABLE 
(
    ContentID   INT     NOT NULL DEFAULT 0,
    PrevCount   INT     NOT NULL DEFAULT 0,
    Count       INT     NOT NULL DEFAULT 0,
    Flag        TINYINT NOT NULL DEFAULT 0
)

Insert @TJson (ContentID, PrevCount, Count, Flag)
SELECT 
    ContentID, PrevCount, Count, Flag
FROM 
    OPENJSON(@Json)
    WITH
    (
        ContentID  BIGINT '$.ci',
        PrevCount  INT    '$.pt',
        Count      INT    '$.c'
    )
;

DECLARE @RowCnt INT = @@ROWCOUNT;

BEGIN TRY
    BEGIN TRAN

    Insert dbo.TViewCount (ContentID, Count)
    SELECT ContentID, Count FROM @TJson WHERE Flag = 1;

    SET @RowCnt -= @@ROWCOUNT;

    UPDATE
        A
    SET
        A.Count = B.Count
    FROM
        dbo.TViewCount A
        JOIN @TJson B ON A.ContentID = B.ContentID AND B.Flag = 2
    WHERE
        A.Count = B.PrevCount
    
    SET @RowCnt -= @@ROWCOUNT;

    IF @RowCnt <> 0
        THROW 50000, N'RowCount 일치 하지 않음', 1

    SET @Result = 0;
    COMMIT TRAN;
END TRY
BEGIN CATCH
    
    ROLLBACK TRAN;
    SET @Result = ERROR_NUMBER();
    
END CATCH
GO
/*
분산된 회원 및 게시물 데이터의 통합 설계 및 처리 방안
    현재 두 개의 물리적인 데이터베이스(DB A, DB B)에 각각 100만 건의 회원 정보와 1000만 건 이상의 게시물 데이터를 보유하고 있습니다.
    각 DB의 회원 ID는 해당 DB 내에서는 유니크하지만, 통합 시에는 중복될 가능성이 있습니다.
    각 회원은 해당 DB에서 작성한 게시물 데이터를 보유하고 있으며, 게시물 또한 회원 ID를 기반으로 관리됩니다.
    회사의 요구사항에 따라 두 개의 데이터베이스를 하나의 통합된 데이터베이스로 병합하려고 합니다.
    이 과정은 온라인 상태(서비스 운영 중) 에서 진행되어야 하며, 서비스 중단 없이 데이터 정합성을 유지해야 합니다.
    해당 상황에서의 데이터 통합 설계 및 처리 방안을 제시해 주세요.

    방안
    B -> A 로 통합을 하기에 서버 안정화를 위한 작업이 있다고 B 유저들에게 공지, 재접속 유도함.

    Procedure 1
        공통으로 관리되는 회원DB가 있다면 로그 아웃후 이전이 될때까지 로그인을 못하게 상태값을 바꿔 놓음.

    DB C 데이터베이스를 생성
        B 회원 정보 데이터, 게시물 데이터를 DB C에 같은 구조의 테이블에 새로운 회원 ID Seq 컬럼을 추가해 만듦

    유저 로그아웃.

    Procedure 2 B -> C
        DB A의 새로운 회원 ID Seq를 발급 받아 B 데이터를 DB C에 Insert
        C 회원정보 데이터에 새로운 ID와 기존 B ID가 둘다 있기에 게시물 데이터엔 새로운 ID를 추가할 필요없음.
        매핑해서 C에 Insert
        
    Procedure 3 C -> A
        DB C에 이관이 완료되면, 다시 DB A에 기존 회원ID를 제외하고 새로운ID와 정보들을 Insert
        게시물 데이터는 기존 B 회원 ID 와 게시물 데이터에 B 회원 ID를 Join해 새로운 A 회원ID와 기존게시물 데이터를 Insert

    Procedure 1
        성공적으로 프로시저가 마치면 로그인 할수있도록 상태값을 바꿔준다.

    유저 로그인 할때 
    회원정보, 게시물 데이터 리스트 로드.
*/

/*
한정판 상품 주문 처리 시스템 설계
    온라인 쇼핑몰에서 한정판 상품 을 판매한다고 가정해봅시다 
    이 상품은 초당 수천 건의 주문 요청을 받을 수 있으며, 재고가 한정적이므로 정확한 트랜잭션 처리가 중요합니다. 
    초과 주문은 방지 되어야 하며, 동시에 주문 시에도 데이터 일관성을 유지해야 하며
    주문 요청이 많아도 DB 성능 저하가 발생하지 않도록 설계해야 합니다. 
    해당 내용들을 모두 만족 할 수 있게 데이터 구조 설계 및 데이터 처리 방법에 대해 생각해 주세요


    표준 데이터
        ProductID, ProductName, LimitBuyCount, PurchaseExpireTime

    천건씩 묶어서 보냄
    서버는 표준데이터를 로드해감.

    10만개 한정상품이라는 가정.
    최대 1만개 초과해서 데이터를 받음.
    서버에서 천건씩 묶어서 보내지만 초과가 될수도 있다고 생각함.

    Procedure 1
    A 테이블에
        서버 틱(100ns), 회원ID

    A -> B INSERT

    B 테이블에 
        서버틱으로 순위, 
        회원 ID, 
        상품 구매 가능 여부 상태 (구매를 누르고 다음 페이지로 들어갔지만 다른 화면을 보여주기위해 또는 컬럼이 불필요 할 수도있음.)

    그 다음 구매 프로세스 진행.

*/

