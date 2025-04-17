CREATE TABLE [dbo].[TQuestComplete] (
    [OwnerType]            TINYINT            NOT NULL,
    [OwnerUniqueID]        BIGINT             NOT NULL,
    [QuestID]              INT                NOT NULL,
    [QuestType]            TINYINT            NOT NULL,
    [CompleteHeroUniqueID] BIGINT             NOT NULL,
    [CompleteTime]         DATETIMEOFFSET (7) CONSTRAINT [DF_TQuestComplete_CompleteTime] DEFAULT (sysdatetimeoffset()) NOT NULL,
    CONSTRAINT [PK_TQuestComplete] PRIMARY KEY CLUSTERED ([OwnerType] ASC, [OwnerUniqueID] ASC, [QuestID] ASC, [CompleteTime] ASC)
);
