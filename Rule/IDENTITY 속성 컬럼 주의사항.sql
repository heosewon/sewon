- TRUNCATE 하게되면 IDENTITY 값 이 초기화 됨.
    - 그래서 큰 이슈 없으면 DELETE 로 할것.

### TRUNCATE 로 할거면…

1. 트렁케이트 하기전에 값이 몇인지 확인한다.  → N 이라고 하자
    
    DBCC CHECKIDENT ('[User].[dbo].[TStorageBox]' )
    
2. 트렁케이트
3. DBCC CHECKIDENT ('[User].[dbo].[TStorageBox]', RESEED,  N + 5);
    1. 그냥 N을 딱 넣지말고… 조금 크게
4. 인설트~

### 현재 문제 발생.

1. 트렁케이트 했고
2. 인설트를 하는데 아래 쿼리를 같이 함
    
    ```sql
    SET IDENTITY_INSERT [User].[dbo].[TStorageBox] ON
    ```
    
3. 시드 재조정
    
    ```sql
    DBCC CHECKIDENT ('[User].[dbo].[TStorageBox]', RESEED );
    ```
    
- 2 번째에서 인설트를 할 때 최고값이 들어간다는 보장이 없음. 그런데 3번째에서 시드 재조정할 때 인설트된 최고값 기준으로 재조정이 됨.

### 이런 문제가 자주 발생된다면…

- 차라리 설계를 시퀀스로 하자
