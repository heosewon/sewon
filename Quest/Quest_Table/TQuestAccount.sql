CREATE TABLE [dbo].[TQuestAccount] (
    [AccountUniqueID] INT                NOT NULL,
    [InitialQuestID]  INT                NOT NULL,
    [QuestID]         INT                NOT NULL,
    [QuestType]       TINYINT            NOT NULL,
    [IsComplete]      BIT                CONSTRAINT [DF_TQuestAccount_IsComplete] DEFAULT ((0)) NOT NULL,
    [PerformingCount] INT                CONSTRAINT [DF_TQuestAccount_PerformingCount] DEFAULT ((0)) NOT NULL,
    [ExpireTick]      BIGINT             NOT NULL,
    [UpdateTime]      DATETIMEOFFSET (7) CONSTRAINT [DF_TQuestAccount_UpdateTime] DEFAULT (sysdatetimeoffset()) NOT NULL,
    [CreateTime]      DATETIMEOFFSET (7) CONSTRAINT [DF_TQuestAccount_CreateTime] DEFAULT (sysdatetimeoffset()) NOT NULL,
    CONSTRAINT [PK_TQuestAccount] PRIMARY KEY CLUSTERED ([AccountUniqueID] ASC, [InitialQuestID] ASC)
);
