 * 중복지급 이슈 - 버그, 허점도 아닌 개선

각 서버에서 계정별로 푸쉬 수령을 마지막 받은 시간으로 체크를 해서 발송하고 있음.

서버 이전시 후 서버에 캐릭터가 생성되어있는 상태라면 
전서버의 수령시간이 아닌 해당서버의 수령시간으로 진행됨.
(캐릭터가 없다면 전 서버의 정보를 가져감. 이때는 푸쉬를 한번만 받게 됨.)

생성 되어있는 캐릭터들의 로그아웃 시간을 보면
푸쉬 시작날짜보다 한참 전으로 수령시간 또한 그 전임

Except ㅠ	
	1군 1서버에서는 받고
	여기서 만약 User가
	떨어진다면
	User는 기록이 안되고
	
	1군 2서버 접속해서
	또받을수있어
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
개선 설계 사항
  추가된 프로시저 2
    UserDB
      spAccountPostSupplyCheckList
      spAccountPostSupplyCheck
  개선된 프로시저 2
    GameDB
      spHeroSelectSimpleHeros
      spHeroSelectDetail
      spHeroUpdateInfoOnTime


CREATE TABLE dbo.TAccountPostSupplyCheck
(
    AccountUniqueID    INT     NOT NULL,
    ServerGroupID      TINYINT NOT NULL, -- 계산된 열로..
    ServerID           INT     NOT NULL,
    LastPostSupplyTime DATETIMEOFFSET  NOT NULL,
    CONSTRAINT PK_TAccountPostSupplyCheck PRIMARY KEY (AccountUniqueID)
)

캐릭터 접속 할 때.
1.
    UserDB
        spAccountPostSupplyCheckList
        List  서버에게 줌.

2.
    GameDB
        innerPostSupply가 종속되어있는 프로시저
            innerPostSupply
                @LastPostSupplyTime DATETIME OUTPUT
            spHeroSelectDetail
                @LastPostSupplyTime DATETIME OUTPUT
            spHeroUpdateInfoOnTime
                @LastPostSupplyTime DATETIME OUTPUT
            추가

3.
    군이 달라도 여기는 무조건 업데이트가 되어야 한다.
    최근 접속서버 어디서 받았는지 확인해야하기 때문
    UserDB
        EXEC spAccountPostSupplyCheck

        UPDATE 
            dbo.TAccountPostSupplyCheck 
        SET 
            LastPostSupplyTime = @LastPostSupplyTime
        WHERE
            AccountUniqueID = @AccountUniqueIDUser  리스트에 있으니까 
            AND LastPostSupplyTime <= @LastPostSupplyTime
        ;
4.
    로그아웃 하고 다른 서버로 접속할 때 
    최근 Conn 서버보고 업데이트 해도되는지 아닌지 서버에게 판단해달라고 함. --> 이게 가능한지 물어봐야함.
    현재 1, 2군은 푸쉬가 다름.

        spHeroSelectDetail 보다 [spHeroSelectSimpleHeros] or  Create New Procedure.
            @LastPostSupplyTimeFromUserDB  추가 (User에 있는값.)
            @IsReceivable bit 
            @IsReceived bit


            TAccountShareData 
                LastPostSupplyTime이 @LastPostSupplyTimeFromUser 작으면 업데이트 해줌

            UPDATE  
                dbo.TAccountSharedData
            SET
                LastPostSupplyTime = @LastPostSupplyTimeFromUserDB
            WHERE
                AccountUniqueID = @AccountUniqueID
                AND LastPostSupplyTime <= @LastPostSupplyTimeFromUserDB
                AND @IsReceived = 1
            ;

Flow
-----------------------------------------------------------------------------------------------------------------------

User.spAccountPostSupplyCheckList	LastPostSupplyTime
▼	
Game.spHeroSelectSimpleHeros	@LastPostSupplyTimeFromUserDB
▼	
"Game.spHeroSelectDetail
Game.spHeroUpdateInfoOnTime"	@LastPostSupplyTime
▼	
User.spAccountPostSupplyCheck	@LastPostSupplyTime

-----------------------------------------------------------------------------------------------------------------------

TAccountShareData 수정이 없으니				
받을수 있는 상태				
푸쉬 받음				
spHeroSelectDetail, spHeroUpdateInfoOnTime	여기서 LastTime Output 서버에게 줌			
User 업데이트				
계속 접속해있는 한 	Output Null이면 업데이트 안함			
푸쉬 받고				
User 업데이트				
				
로그아웃				
1군 2서버 접속				
리스트에 있음 (위에 1 서버 받은거)				
spHeroSelectSimpleHeros	User  리스트에 있으니까 		있는 값으로 보내달라함	Update 돼야함
	수령여부		1 같은 군이기에..	Update 돼야함
로그아웃				
2군 1서버 접속				
리스트에 있음  (위에 1 서버 받은거)				
spHeroSelectSimpleHeros	User  리스트에 있지만 접속한 군이 다름		있는 값으로 보내달라해도 상관없음 가능여부에서 걸림	
	수령여부는 서버에서 판별에서 보내줌 1, 2군은 푸쉬가 달라서 가능해야함		0으로 보냄	
TAccountShareData 수정이 없으니				
받을 수 있는 상태				
푸쉬 받음				
spHeroSelectDetail, spHeroUpdateInfoOnTime	여기서 LastTime Output 서버에게 줌			
User 업데이트				
계속 접속해있는 한 				
푸쉬 받고				
User 업데이트				
				
로그아웃				
다시 1군 접속해도 동일				
-----------------------------------------------------------------------------------------------------------------------


