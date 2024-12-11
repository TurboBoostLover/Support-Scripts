USE [clovis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14306';
DECLARE @Comments nvarchar(Max) = 
	'Enable Group Votes and set them up';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 1; /*  Default 1 is Support,  
For a complete list run the following query

Select * from history.ScriptType
*/

SELECT
 @@servername AS 'Server Name' 
,DB_NAME() AS 'Database Name'
,@JiraTicketNumber as 'Jira Ticket Number';

SET XACT_ABORT ON
BEGIN TRAN

INSERT INTO History.ScriptsRunOnDatabase
(TicketNumber,Developer,Comments,ScriptTypeId)
VALUES
(@JiraTicketNumber, @Developer, @Comments, @ScriptTypeId); 

/*--------------------------------------------------------------------
Please do not alter the script above this comment  except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing somehting 
		 that is against meta best practices but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql

-----------------Script details go below this line------------------*/
UPDATE Config.ClientSetting
SET AllowGroupVote = 1
WHERE Id = 1

DECLARE @TABLE TABLE (Id int, title nvarchar(max))

INSERT INTO PositionGroup
(Title, StartDate, SortOrder, ClientId, Active)
output inserted.Id, inserted.Title into @TABLE
VALUES
('Level 3 New Course Workflow', GETDATE(), 1, 1, 1),
('Level 4 New Course Workflow', GETDATE(), 1, 1, 1),
('Level 6 New Course Workflow', GETDATE(), 1, 1, 1),
('Level 7 New Course Workflow', GETDATE(), 1, 1, 1),
('Level 9 New Course Workflow', GETDATE(), 1, 1, 1),
('Level 3 New Course', GETDATE(), 1, 1, 1),
('Level 4 New Course', GETDATE(), 1, 1, 1),
('Level 6 New Course', GETDATE(), 1, 1, 1),
('Level 3 Modify', GETDATE(), 1, 1, 1),
('Level 4 Modify', GETDATE(), 1, 1, 1),
('Level 5 Modify', GETDATE(), 1, 1, 1),
('Level 6 Modify', GETDATE(), 1, 1, 1)

INSERT INTO PositionGroupAttribute
(PositionGroupId, PositionGroupAttributeTypeId)
SELECT Id, 1 FROM @TABLE

DECLARE @3neww int = (SELECT Id FROM @TABLE WHERE Title = 'Level 3 New Course Workflow')
DECLARE @4neww int = (SELECT Id FROM @TABLE WHERE Title = 'Level 4 New Course Workflow')
DECLARE @6neww int = (SELECT Id FROM @TABLE WHERE Title = 'Level 6 New Course Workflow')
DECLARE @7neww int = (SELECT Id FROM @TABLE WHERE Title = 'Level 7 New Course Workflow')
DECLARE @9neww int = (SELECT Id FROM @TABLE WHERE Title = 'Level 9 New Course Workflow')
DECLARE @3new int = (SELECT Id FROM @TABLE WHERE Title = 'Level 3 New Course')
DECLARE @4new int = (SELECT Id FROM @TABLE WHERE Title = 'Level 4 New Course')
DECLARE @6new int = (SELECT Id FROM @TABLE WHERE Title = 'Level 6 New Course')
DECLARE @3mod int = (SELECT Id FROM @TABLE WHERE Title = 'Level 3 Modify')
DECLARE @4mod int = (SELECT Id FROM @TABLE WHERE Title = 'Level 4 Modify')
DECLARE @5mod int = (SELECT Id FROM @TABLE WHERE Title = 'Level 5 Modify')
DECLARE @6mod int = (SELECT Id FROM @TABLE WHERE Title = 'Level 6 Modify')

DECLARE @TABLE2 TABLE (Id int, PosId int, PosgId int)

INSERT INTO PositionGroupMember
(PositionId, PositionGroupId)
output inserted.Id, inserted.PositionId, inserted.PositionGroupId into @TABLE2
VALUES
(5, @3neww),
(15, @3neww),
(21, @3neww),
(20, @3neww),
(6, @4neww),
(18, @4neww),
(21, @4neww),
(20, @4neww),
(9, @6neww),
(8, @6neww),
(3, @6neww),
(22, @6neww),
(7, @6neww),
(9, @9neww),
(8, @9neww),
(8, @7neww),
(10, @7neww),
(5,	@3new),
(21,	@3new),
(15,	@3new),
(16,	@3new),
(6,	@4new),
(19,	@4new),
(20,	@4new),
(21,	@4new),
(9,	@6new),
(8,	@6new),
(3,	@6new),
(22,	@6new),
(7,	@6new),
(9,	@4mod),
(3,	@4mod),
(4,	@4mod),
(8,	@4mod),
(22,	@4mod),
(10,	@6mod),
(13,	@6mod),
(14,	@6mod),
(4,	@6mod),
(8,	@6mod),
(10,	@5mod),
(12,	@5mod),
(14,	@5mod),
(4,	@5mod),
(8,	@5mod),
(13,	@5mod),
(5,	@3mod),
(15,	@3mod),
(16,	@3mod),
(17,	@3mod),
(18,	@3mod),
(19,	@3mod),
(20,	@3mod),
(21,	@3mod),
(4,	@3mod),
(8,	@3mod)



INSERT INTO PositionGroupMemberAttribute
(PositionGroupMemberId, PositionGroupMemberAttributeTypeId)
SELECT Id, 1 FROM PositionGroupMember