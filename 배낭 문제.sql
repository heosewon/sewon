--* 행으로

DECLARE @Max INT = 15;

DECLARE @TABLE TABLE (N INT, W INT, D INT)
INSERT @TABLE VALUES (0, 12, 4), (1, 4, 10), (2, 2, 2), (3, 1, 2), (4, 1, 1)
DECLARE @C INT =  (SELECT POWER(2, COUNT(*)) -1 FROM @TABLE);

WITH X AS
(
    SELECT 0 N
    UNION ALL
    SELECT N + 1 FROM X WHERE N < @C
)
SELECT 
     TOP 1 BN, SUM(W), SUM(D)
FROM 
(
    SELECT
        A.N AN, B.N BN, A.W, A.D, GET_BIT(B.N, A.N) K
    FROM
        @TABLE A CROSS JOIN X B
) X
WHERE
    K = 1
GROUP BY BN
HAVING SUM(W) <= 15
ORDER BY SUM(D) DESC
 

--* 열로

DECLARE @Json VARCHAR(MAX) = '[{"w" : 12, "d" : 4}, {"w" : 4, "d" : 10}, {"w" : 2, "d" : 2}, {"w" : 1, "d" : 2}, {"w" : 1, "d" : 1}]'
 
;
WITH B AS
(
    SELECT 0 No, 4 [5], 3 [4], 2 [3], 1 [2], 0 [1]
    UNION ALL
    SELECT No +1, [5], [4], [3], [2], [1] FROM B WHERE No < 31
)
SELECT * FROM 
(
    SELECT *, ROW_NUMBER() OVER(ORDER BY Xd DESC, Xw) R FROM 
    (
        SELECT 
            No, [5], [4], [3], [2], [1],
            Xw5 + Xw4 + Xw3 + Xw2 + Xw1 XW,
            Xd5 + Xd4 + Xd3 + Xd2 + Xd1 XD
        FROM 
        (
            SELECT 
                *,
                CASE WHEN [5] = 1 THEN JSON_VALUE(J, '$[0].w') ELSE 0 END XW5, CASE WHEN [5] = 1 THEN JSON_VALUE(J, '$[0].d') ELSE 0 END XD5,
                CASE WHEN [4] = 1 THEN JSON_VALUE(J, '$[1].w') ELSE 0 END XW4, CASE WHEN [4] = 1 THEN JSON_VALUE(J, '$[1].d') ELSE 0 END XD4,
                CASE WHEN [3] = 1 THEN JSON_VALUE(J, '$[2].w') ELSE 0 END XW3, CASE WHEN [3] = 1 THEN JSON_VALUE(J, '$[2].d') ELSE 0 END XD3,
                CASE WHEN [2] = 1 THEN JSON_VALUE(J, '$[3].w') ELSE 0 END XW2, CASE WHEN [2] = 1 THEN JSON_VALUE(J, '$[3].d') ELSE 0 END XD2,
                CASE WHEN [1] = 1 THEN JSON_VALUE(J, '$[4].w') ELSE 0 END XW1, CASE WHEN [1] = 1 THEN JSON_VALUE(J, '$[4].d') ELSE 0 END XD1
            FROM
            (
                SELECT 
                    No, 
                    GET_BIT([No], [5]) [5],
                    GET_BIT([No], [4]) [4],
                    GET_BIT([No], [3]) [3],
                    GET_BIT([No], [2]) [2],
                    GET_BIT([No], [1]) [1],
                    @Json J
                FROM 
                    B
            ) X1
        ) X2
    ) X3
    WHERE Xw <= 15
) X4 WHERE R = 1
