/*

(1), (2), (3), (4), (5);
('Green'), ('Blue'), ('Yellow'), ('White'), ('Red');
('Norway'), ('Germany'), ('Denmark'), ('Sweden'), ('England');
('Coffee'), ('Tea'), ('Milk'), ('Water'), ('Beer');
('Cat'), ('Dog'), ('Bird'), ('Horse'), (NULL);
('Pallmall'), ('Dunhill'), ('BlueMaster'), ('Prince'), ('Blend');

전제
    벽지 색깔이 다른 집이 일렬로 5채 있다.
    각 집마다 서로 다른 국적을 가진 사람이 살고 있다.
    다섯 사람은 어떤 음료를 마시고, 어느 담배를 피우고, 어느 동물을 기르고 있다.
    어느 두 사람도 마시는 음료, 피우는 담배, 기르는 동물은 일치하지 않는다.

조건
    1영국인은 빨간 집에 산다.
    2스웨덴인은 개를 기른다.
    3덴마크인은 차를 마신다.
    4초록 집은 하얀 집의 바로 왼쪽에 있다.
    5초록 집에 사는 사람은 커피를 마신다.
    6팰맬(Pall mall) 담배를 피우는 사람은 새를 기른다.
    7노란 집 사람은 던힐(Dunhill) 담배를 피운다.
    8한 가운데 사는 사람은 우유를 마신다.
    9노르웨이인은 첫 번째 집에 산다.
    10블렌드(Blend) 담배를 피우는 사람은 고양이를 기르는 사람의 옆집에 산다.
    11말을 기르는 사람은 던힐 담배를 피우는 사람의 옆집에 산다.
    12블루매스터(Blue master) 담배를 피우는 사람은 맥주를 마신다.
    13독일인은 프린스(Prince) 담배를 피운다.
    14노르웨이인은 파란 집 옆에 산다.
    15블렌드 담배를 피우는 사람은 생수를 마시는 사람과 이웃이다.



    그렇다면, 물고기를 기르는 사람은 어느 나라 사람일까? ?????


*/
DECLARE @TNo  TABLE (No  INT);
INSERT  @TNo  VALUES (1), (2), (3), (4), (5);
;
DROP TABLE IF EXISTS TEin
SELECT
    X1.No X1, X2.No X2, X3.No X3, X4.No X4, X5.No X5
INTO TEin
FROM 
    @TNo X1
    JOIN @TNo X2 ON X1.No <> X2.No
    JOIN @TNo X3 on X3.No NOT IN (X1.No, X2.No)
    JOIN @TNo X4 on X4.No NOT IN (X1.No, X2.No, X3.No)
    JOIN @TNo X5 on X5.No NOT IN (X1.No, X2.No, X3.No, X4.No)

DROP TABLE IF EXISTS TEin2
SELECT
     CASE A.X1 WHEN 1 THEN 'Green' WHEN 2 THEN 'Blue' WHEN 3 THEN 'Yellow' WHEN 4 THEN 'White' WHEN 5 THEN 'Red' END AX1,
     CASE A.X2 WHEN 1 THEN 'Green' WHEN 2 THEN 'Blue' WHEN 3 THEN 'Yellow' WHEN 4 THEN 'White' WHEN 5 THEN 'Red' END AX2,
     CASE A.X3 WHEN 1 THEN 'Green' WHEN 2 THEN 'Blue' WHEN 3 THEN 'Yellow' WHEN 4 THEN 'White' WHEN 5 THEN 'Red' END AX3,
     CASE A.X4 WHEN 1 THEN 'Green' WHEN 2 THEN 'Blue' WHEN 3 THEN 'Yellow' WHEN 4 THEN 'White' WHEN 5 THEN 'Red' END AX4,
     CASE A.X5 WHEN 1 THEN 'Green' WHEN 2 THEN 'Blue' WHEN 3 THEN 'Yellow' WHEN 4 THEN 'White' WHEN 5 THEN 'Red' END AX5,

     CASE B.X1 WHEN 1 THEN 'Norway' WHEN 2 THEN 'Germany' WHEN 3 THEN 'Denmark' WHEN 4 THEN 'Sweden' WHEN 5 THEN 'England' END BX1,
     CASE B.X2 WHEN 1 THEN 'Norway' WHEN 2 THEN 'Germany' WHEN 3 THEN 'Denmark' WHEN 4 THEN 'Sweden' WHEN 5 THEN 'England' END BX2,
     CASE B.X3 WHEN 1 THEN 'Norway' WHEN 2 THEN 'Germany' WHEN 3 THEN 'Denmark' WHEN 4 THEN 'Sweden' WHEN 5 THEN 'England' END BX3,
     CASE B.X4 WHEN 1 THEN 'Norway' WHEN 2 THEN 'Germany' WHEN 3 THEN 'Denmark' WHEN 4 THEN 'Sweden' WHEN 5 THEN 'England' END BX4,
     CASE B.X5 WHEN 1 THEN 'Norway' WHEN 2 THEN 'Germany' WHEN 3 THEN 'Denmark' WHEN 4 THEN 'Sweden' WHEN 5 THEN 'England' END BX5,

     CASE C.X1 WHEN 1 THEN 'Coffee' WHEN 2 THEN 'Tea' WHEN 3 THEN 'Milk' WHEN 4 THEN 'Water' WHEN 5 THEN 'Beer' END CX1,
     CASE C.X2 WHEN 1 THEN 'Coffee' WHEN 2 THEN 'Tea' WHEN 3 THEN 'Milk' WHEN 4 THEN 'Water' WHEN 5 THEN 'Beer' END CX2,
     CASE C.X3 WHEN 1 THEN 'Coffee' WHEN 2 THEN 'Tea' WHEN 3 THEN 'Milk' WHEN 4 THEN 'Water' WHEN 5 THEN 'Beer' END CX3,
     CASE C.X4 WHEN 1 THEN 'Coffee' WHEN 2 THEN 'Tea' WHEN 3 THEN 'Milk' WHEN 4 THEN 'Water' WHEN 5 THEN 'Beer' END CX4,
     CASE C.X5 WHEN 1 THEN 'Coffee' WHEN 2 THEN 'Tea' WHEN 3 THEN 'Milk' WHEN 4 THEN 'Water' WHEN 5 THEN 'Beer' END CX5,

     CASE D.X1 WHEN 1 THEN 'Cat' WHEN 2 THEN 'Dog' WHEN 3 THEN 'Bird' WHEN 4 THEN 'Horse' WHEN 5 THEN 'Fish' END DX1,
     CASE D.X2 WHEN 1 THEN 'Cat' WHEN 2 THEN 'Dog' WHEN 3 THEN 'Bird' WHEN 4 THEN 'Horse' WHEN 5 THEN 'Fish' END DX2,
     CASE D.X3 WHEN 1 THEN 'Cat' WHEN 2 THEN 'Dog' WHEN 3 THEN 'Bird' WHEN 4 THEN 'Horse' WHEN 5 THEN 'Fish' END DX3,
     CASE D.X4 WHEN 1 THEN 'Cat' WHEN 2 THEN 'Dog' WHEN 3 THEN 'Bird' WHEN 4 THEN 'Horse' WHEN 5 THEN 'Fish' END DX4,
     CASE D.X5 WHEN 1 THEN 'Cat' WHEN 2 THEN 'Dog' WHEN 3 THEN 'Bird' WHEN 4 THEN 'Horse' WHEN 5 THEN 'Fish' END DX5,

     CASE E.X1 WHEN 1 THEN 'Pallmall' WHEN 2 THEN 'Dunhill' WHEN 3 THEN 'BlueMaster' WHEN 4 THEN 'Prince' WHEN 5 THEN 'Blend' END EX1,
     CASE E.X2 WHEN 1 THEN 'Pallmall' WHEN 2 THEN 'Dunhill' WHEN 3 THEN 'BlueMaster' WHEN 4 THEN 'Prince' WHEN 5 THEN 'Blend' END EX2,
     CASE E.X3 WHEN 1 THEN 'Pallmall' WHEN 2 THEN 'Dunhill' WHEN 3 THEN 'BlueMaster' WHEN 4 THEN 'Prince' WHEN 5 THEN 'Blend' END EX3,
     CASE E.X4 WHEN 1 THEN 'Pallmall' WHEN 2 THEN 'Dunhill' WHEN 3 THEN 'BlueMaster' WHEN 4 THEN 'Prince' WHEN 5 THEN 'Blend' END EX4,
     CASE E.X5 WHEN 1 THEN 'Pallmall' WHEN 2 THEN 'Dunhill' WHEN 3 THEN 'BlueMaster' WHEN 4 THEN 'Prince' WHEN 5 THEN 'Blend' END EX5
INTO
    TEin2
FROM
    (SELECT * FROM TEin) A 
    CROSS JOIN (SELECT * FROM TEin) B
    CROSS JOIN (SELECT * FROM TEin) C
    CROSS JOIN (SELECT * FROM TEin) D
    CROSS JOIN (SELECT * FROM TEin) E
WHERE
    (--1
        (A.X1 = 5 AND B.X1 = 5)
        OR (A.X2 = 5 AND B.X2 = 5)
        OR (A.X3 = 5 AND B.X3 = 5)
        OR (A.X4 = 5 AND B.X4 = 5)
        OR (A.X5 = 5 AND B.X5 = 5)
    )
    AND
    (--2
        (B.X1 = 4 AND D.X1 = 2)
        OR (B.X2 = 4 AND D.X2 = 2)
        OR (B.X3 = 4 AND D.X3 = 2)
        OR (B.X4 = 4 AND D.X4 = 2)
        OR (B.X5 = 4 AND D.X5 = 2)
    )
    AND
    (--3
        (B.X1 = 3 AND C.X1 = 2)
        OR (B.X2 = 3 AND C.X2 = 2)
        OR (B.X3 = 3 AND C.X3 = 2)
        OR (B.X4 = 3 AND C.X4 = 2)
        OR (B.X5 = 3 AND C.X5 = 2)
    )
    AND
    (--4
        (A.X2 = 4 AND A.X1 = 1)
        OR (A.X3 = 4 AND A.X2 = 1)
        OR (A.X4 = 4 AND A.X3 = 1)
        OR (A.X5 = 4 AND A.X4 = 1)
    )
    AND
    (--5
        (A.X1 = 1 AND C.X1 = 1)
        OR (A.X2 = 1 AND C.X2 = 1)
        OR (A.X3 = 1 AND C.X3 = 1)
        OR (A.X4 = 1 AND C.X4 = 1)
        OR (A.X5 = 1 AND C.X5 = 1)
    )
    AND
    (--6
        (E.X1 = 1 AND D.X1 = 3)
        OR (E.X2 = 1 AND D.X2 = 3)
        OR (E.X3 = 1 AND D.X3 = 3)
        OR (E.X4 = 1 AND D.X4 = 3)
        OR (E.X5 = 1 AND D.X5 = 3)
    )
    AND
    (--7
        (A.X1 = 3 AND E.X1 = 2)
        OR (A.X2 = 3 AND E.X2 = 2)
        OR (A.X3 = 3 AND E.X3 = 2)
        OR (A.X4 = 3 AND E.X4 = 2)
        OR (A.X5 = 3 AND E.X5 = 2)
    )
    AND (C.X3 = 3) -- 8
    AND (B.X1 = 1) -- 9
    AND
    (--10
        (E.X1 = 5 AND D.X2 = 1)
        OR (E.X2 = 5 AND (D.X1 = 1 OR D.X3 = 1))
        OR (E.X3 = 5 AND (D.X2 = 1 OR D.X4 = 1))
        OR (E.X4 = 5 AND (D.X3 = 1 OR D.X5 = 1))
        OR (E.X5 = 5 AND D.X4 = 1)
    )
    AND
    (--11
        (D.X1 = 4 AND E.X2 = 2)
        OR (D.X2 = 4 AND (E.X1 = 2 OR E.X3 = 2))
        OR (D.X3 = 4 AND (E.X2 = 2 OR E.X4 = 2))
        OR (D.X4 = 4 AND (E.X3 = 2 OR E.X5 = 2))
        OR (E.X5 = 4 AND E.X4 = 2)
    )
    AND
    (--12
        (C.X1 = 5 AND E.X1 = 3)
        OR (C.X2 = 5 AND E.X2 = 3)
        OR (C.X3 = 5 AND E.X3 = 3)
        OR (C.X4 = 5 AND E.X4 = 3)
        OR (C.X5 = 5 AND E.X5 = 3)
    )
    AND
    (--13
        (B.X1 = 2 AND E.X1 = 4)
        OR (B.X2 = 2 AND E.X2 = 4)
        OR (B.X3 = 2 AND E.X3 = 4)
        OR (B.X4 = 2 AND E.X4 = 4)
        OR (B.X5 = 2 AND E.X5 = 4)
    )
    AND (A.X2 = 2) --14
    AND
    (--15
        (E.X1 = 5 AND C.X2 = 4)
        OR (E.X2 = 5 AND (C.X1 = 4 OR C.X3 = 4))
        OR (E.X3 = 5 AND (C.X2 = 4 OR C.X4 = 4))
        OR (E.X4 = 5 AND (C.X3 = 4 OR C.X5 = 4))
        OR (E.X4 = 5 AND C.X5 = 4)
    );

DECLARE @TColumn TABLE (Col VARCHAR(MAX))
INSERT @TColumn
SELECT STRING_AGG(COLUMN_NAME, ',') FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME = 'TEin2' GROUP BY (ORDINAL_POSITION - 1)/ 5 

DECLARE @Result TABLE ([1] VARCHAR(30), [2] VARCHAR(30), [3] VARCHAR(30), [4] VARCHAR(30), [5] VARCHAR(30));
DECLARE @Query NVARCHAR(MAX)
DECLARE @Column VARCHAR(100) = ''

WHILE 1 = 1
BEGIN
    
    SELECT TOP 1 @Column = Col FROM @TColumn WHERE @Column < Col ORDER BY Col;

    IF @@ROWCOUNT = 0
        BREAK;

     SET @Query = N'SELECT ' + @Column + ' FROM TEin2';

    INSERT @Result EXEC (@Query);

END

SELECT * FROM @Result;
