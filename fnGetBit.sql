USE GameUnion
GO
DROP TABLE IF EXISTS GameUnion.dbo.TBit
GO
WITH TBit AS
(
    SELECT 0 N, POWER(2, 0) [Bit]
    UNION ALL
    SELECT N+1, POWER(2, N+1) FROM TBit WHERE N < 25
)
SELECT 
    * INTO GameUnion.dbo.TBit
FROM 
    TBit 
GO
DROP FUNCTION IF EXISTS [dbo].[fnGetBit];
GO
CREATE FUNCTION [dbo].[fnGetBit]
(
    @StepFlag INT,
    @No       INT
)
    RETURNS INT
AS
BEGIN
    

    RETURN
    (
        SELECT
            IIF([Bit] & @Stepflag <> 0, 1, 0) BitFlag 
        FROM
            dbo.TBit
        WHERE
            N = @No
    )

END
GO
