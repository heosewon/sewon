CREATE TABLE [dbo].[TQuestRequest] (
    [OwnerType]     INT    NOT NULL,
    [OwnerUniqueID] BIGINT NOT NULL,
    [QuestGroupID]  INT    NOT NULL,
    [QuestID]       INT    NOT NULL,
    CONSTRAINT [PK_TQuestRequest] PRIMARY KEY CLUSTERED ([OwnerType] ASC, [OwnerUniqueID] ASC, [QuestGroupID] ASC, [QuestID] ASC)
);
