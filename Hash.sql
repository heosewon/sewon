SELECT HASHBYTES('MD5', N'ABCE') -- 0xBE4E174400A60695703953752D6C25BF
SELECT HASHBYTES('SHA2_512', N'ABCDEEFEFEE')

select
    HASHBYTES('SHA2_512', x)
from
(
    select
        UniqueID
    from
        ItemCraft
    where
        IsActive = 1
        order by UniqueID
    for json auto
) a (x)

select
    HASHBYTES('SHA2_512', W)
from
(
    SELECT 
        NAME,
        HASHBYTES('MD5', OBJECT_DEFINITION(object_id) ) [X]
    FROM SYS.procedures WHERE name LIKE 'sp%'
    ORDER BY
        [NAME]
    for json auto
) a (W)


MD5 : 0xBEC419C8380DBE9EC3B86A7023A55107 = 32개 16바이트

-- 1바이트  0xFF
-- 최대숫자 = 255 = 0xFF
-- MD5 = 16바이트
-- 캐릭터이름 NVARCHAR(100); 100바이트 = 
/*
    해쉬
        무결성 확인하기 위함
        역함수가 존재하지 않는다. = 서로다른 원본데이터가 같은 해쉬값을 가질수있다.
        사실 해쉬는 암호화가 아니다.
        md5, sha-1, sha-2, sha-3.

        해쉬 인덱스

    암호화
        RSA, S...
        역함수가 존재한다.

    인코딩
        역함수가 존재한다.
        감추려고 하지 않는다.
        BASE64 (웹개발자들하고 일할때 많이)

*/
/*
    원본 : 경우의 수가 무제한
    MD5  : 16바이트 : 128BIT : 3.4028236692093846346337460743177 * 10^38
    
    서로다른 원본이 MD5는 같을 수 있다. 하지만 흔하지 않다.
    MD5 는 보안이 취약하다. (보안에 중요한 데이터들은 사용하지 않는다)

    해쉬 = 무결성을 알아봄

    SELECT HASHBYTES('MD5', N'ABCD') -- 0xBEC419C8380DBE9EC3B86A7023A55107

    f(x) = 0xBEC419C8380DBE9EC3B86A7023A55107
    f(y) = 0xBEC419C8380DBE9EC3B86A7023A55107
    g(0xBEC419C8380DBE9EC3B86A7023A55107) = x ? y ? . ? .....
    반대로가는길이 여러개다. 역함수가 존재하지 않는다.

    MD5 는 보안이 취약하다.
    0xBEC419C8380DBE9EC3B86A7023A55107 이걸보고 y

    보안에 중요한 데이터를 해쉬해서 저장하려면 md5 가 아닌 sha-2이런걸로 사용해야함.


    반대로가는길이 유일하다. 역함수가 존재한다.
    f(x) = A, g(A) = x : 암호화 및 복호화

*/
