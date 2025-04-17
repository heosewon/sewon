CREATE TABLE [dbo].[TQuestRequestGroup] (
    [OwnerType]            INT                NOT NULL,
    [OwnerUniqueID]        BIGINT             NOT NULL,
    [QuestGroupID]         INT                NOT NULL,
    [QuestResetCount]      INT                NOT NULL,
    [QuestResetUpdateTime] DATETIMEOFFSET (7) NOT NULL,
    [QuestLastInitTime]    DATETIMEOFFSET (7) NOT NULL,
    CONSTRAINT [PK_TQuestRequestGroup] PRIMARY KEY CLUSTERED ([OwnerType] ASC, [OwnerUniqueID] ASC, [QuestGroupID] ASC)
);
