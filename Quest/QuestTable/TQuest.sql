CREATE TABLE [dbo].[TQuest] (
    [HeroUniqueID]    BIGINT             NOT NULL,
    [InitialQuestID]  INT                NOT NULL,
    [QuestID]         INT                NOT NULL,
    [QuestType]       TINYINT            NOT NULL,
    [IsComplete]      BIT                CONSTRAINT [DF_TQuest_IsComplete] DEFAULT ((0)) NOT NULL,
    [PerformingCount] INT                CONSTRAINT [DF_TQuest_PerformingCount] DEFAULT ((0)) NOT NULL,
    [ExpireTick]      BIGINT             NOT NULL,
    [UpdateTime]      DATETIMEOFFSET (7) CONSTRAINT [DF_TQuest_UpdateTime] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreateTime]      DATETIMEOFFSET (7) CONSTRAINT [DF_TQuest_CreateTime] DEFAULT (sysdatetimeoffset()) NOT NULL,
    CONSTRAINT [PK_TQuest] PRIMARY KEY CLUSTERED ([HeroUniqueID] ASC, [InitialQuestID] ASC)
);

