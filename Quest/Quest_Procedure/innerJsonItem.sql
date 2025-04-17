/*
    JsonItem 처리

    모든 아이템은 여기서 처리 지향
*/
CREATE PROCEDURE [dbo].[innerJsonItem]
    @AccountUniqueID    INT,
    @HeroUniqueID       BIGINT,
    @Position           INT,
    @JsonItem           VARCHAR (MAX), -- MAX 필수
    @NeedInsertSelect   BIT
AS
    SET NOCOUNT, XACT_ABORT ON;

    BEGIN TRY

        DECLARE @ResultTable TABLE
        (
            ItemUniqueID   BIGINT DEFAULT (0),
            ItemTemplateID INT    DEFAULT (0),
            StackCount     INT    DEFAULT (0)
        );

        DECLARE @TotalCount INT = 0;

        DECLARE @JsonTable TABLE
        (
            [ItemUniqueID]    BIGINT,
            [ItemTemplateID]  INT,
            [StackCount]      INT,
            [DBFlag]          INT,
            [PrevStackCount]  INT,
            [AcquisitionPath] INT,
            [SpecialOption1]  INT,
            [SpecialOption2]  INT,
            [SpecialOption3]  INT,
            [SpecialOption4]  INT,
            [SpecialOption5]  INT,
            [SocketCount]     TINYINT,
            [Enchant]         TINYINT
        );

        INSERT @JsonTable
        SELECT
            [ItemUniqueID]   ,
            [ItemTemplateID] ,
            [StackCount]     ,
            [DBFlag]         ,
            [PrevStackCount] ,
            ISNULL([AcquisitionPath], 0),
            ISNULL([SpecialOption1] , 0),
            ISNULL([SpecialOption2] , 0),
            ISNULL([SpecialOption3] , 0),
            ISNULL([SpecialOption4] , 0),
            ISNULL([SpecialOption5] , 0),
            ISNULL([SocketCount]    , 0),
            ISNULL([Enchant]        , 0)
        FROM
            OPENJSON ( @JsonItem )
            WITH
            (
                [ItemUniqueID]    BIGINT  '$.uid',
                [ItemTemplateID]  INT     '$.tid',
                [StackCount]      INT     '$.sc',
                [DBFlag]          INT     '$.flag',
                [PrevStackCount]  INT     '$.psc',
                [AcquisitionPath] INT     '$.ap',
                [SpecialOption1]  INT     '$.so1',
                [SpecialOption2]  INT     '$.so2',
                [SpecialOption3]  INT     '$.so3',
                [SpecialOption4]  INT     '$.so4',
                [SpecialOption5]  INT     '$.so5',
                [SocketCount]     TINYINT '$.skc',
                [Enchant]         TINYINT '$.en'
            );

        SET @TotalCount = @@ROWCOUNT;

        DELETE
            A
        FROM
            [dbo].[TItem] A
            JOIN @JsonTable B ON A.[ItemUniqueID] = B.[ItemUniqueID] AND A.[StackCount] = B.[PrevStackCount]
        WHERE
            B.[DBFlag] = 3;

        SET @TotalCount = @TotalCount - @@ROWCOUNT;

        UPDATE
            A
        SET
            A.[StackCount] = B.[StackCount]
        FROM
            [dbo].[TItem] A
            JOIN @JsonTable B ON A.[ItemUniqueID] = B.[ItemUniqueID] AND A.[StackCount] = B.[PrevStackCount]
        WHERE
            B.[DBFlag] = 2;

        SET @TotalCount = @TotalCount - @@ROWCOUNT;

        INSERT [dbo].[TItem]
        (
            [ItemUniqueID],
            [AccountUniqueID], [HeroUniqueID], [ItemTemplateID],
            [Position],
            [StackCount], [Enchant],
            [AcquisitionPath], [SpecialOption1], [SpecialOption2], [SpecialOption3], [SpecialOption4], [SpecialOption5],
            [SocketCount]
        )
        OUTPUT
            INSERTED.ItemUniqueID, INSERTED.ItemTemplateID, INSERTED.StackCount
        INTO
            @ResultTable
        SELECT 
            NEXT VALUE FOR dbo.ItemUniqueIDSeq, 
            @AccountUniqueID, @HeroUniqueID, ItemTemplateID, 
            @Position,
            StackCount, [Enchant],
            [AcquisitionPath], [SpecialOption1], [SpecialOption2], [SpecialOption3], [SpecialOption4], [SpecialOption5],
            [SocketCount]
        FROM 
            @JsonTable
        WHERE
            DBFlag = 1;

        DECLARE @InsertCount INT = @@ROWCOUNT
        SET @TotalCount = @TotalCount - @InsertCount;

        IF @TotalCount <> 0
            THROW 50014, N'아이템 처리 실패', 1;

        -- * 서버에 ItemUniqueID 전달
        IF @NeedInsertSelect = 1
        BEGIN

            IF @InsertCount = 0
                INSERT @ResultTable DEFAULT VALUES;

            SELECT * FROM @ResultTable;

        END

    END TRY
    BEGIN CATCH

        THROW;

    END CATCH
