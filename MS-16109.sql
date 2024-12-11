USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16109';
DECLARE @Comments nvarchar(Max) = 
	'Restore backup data for in review program reviews';
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

If exists(select top 1 1 from History.ScriptsRunOnDatabase where TicketNumber = @JiraTicketNumber and Developer = @Developer and Comments = @Comments)
	THROW 51000, 'This Script has already been run', 1;

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
DECLARE @TABLE TABLE (mId int, ProposalId int)
INSERT INTO @TABLE
SELECT Id, ProposalId FROM chaffey_old.dbo.Module WHERE Active = 1 and ProposalTypeId = 43 and StatusAliasId = 14

DECLARE @Redo TABLE (mId int)
INSERT INTO @Redo
SELECT Id FROM chaffey.dbo.Module WHERE ProposalTypeId = 44
and Id in (
	SELECT mId FROM @TABLE
)

DECLARE @Proposal TABLE (proposalId int, mId int)
INSERT INTO @Proposal
SELECT ProposalId, Id FROM chaffey_old.dbo.Module WHERE Id in (
	SELECT mId FROM @Redo
)

DECLARE @Proposal2 TABLE (Id int, ProcessVersionId int, LaunchDate Datetime, ProposalComplete bit, IsImplemented bit, userId int, ImplementDate datetime, clientId int, ProcessHold bit)
INSERT INTO @Proposal2
SELECT Id, ProcessVersionId, LaunchDate, ProposalComplete, IsImplemented, UserId, ImplementDate, ClientId, ProcessOnHoldForChanges FROM chaffey_old.dbo.Proposal WHERE Id in (
	SELECT ProposalId FROM @Proposal
)

DECLARE @Level TABLE (id int, createdDate datetime, StepLevelId int, ProposalId int, LevelActionResultTypeId int, ResultDate DateTime)
INSERT INTO @Level
SELECT Id, CreatedDate, StepLevelId, ProposalId, LevelActionResultTypeId, ResultDate FROM chaffey_old.dbo.ProcessLevelActionHistory
WHERE ProposalId in (
	SELECT ProposalId FROM @Proposal
)

DECLARE @Step TABLE (Id int, CreatedDate Datetime, ProcessLevelActionHistoryId int, StepId int, WaitingForChagnes bit, StepActionResultTypeId int, ResultDate Datetime, UserId int, Comments Nvarchar(max), ActionLevelRouteId int, AgingWorkflow bit, commentIsPrivate bit)
INSERT INTO @Step
SELECT Id, CreatedDate, ProcessLevelActionHistoryId, StepId, WaitingForChanges, StepActionResultTypeId, ResultDate, UserId, Comments, ActionLevelRouteId, AgingWorkflowDefaultActionReminderQueued, CommentIsPrivate FROM chaffey_old.dbo.ProcessStepActionHistory
WHERE ProcessLevelActionHistoryId in (
 SELECT Id FROM @Level
)

SET IDENTITY_INSERT chaffey.dbo.Proposal ON;

INSERT INTO chaffey.dbo.Proposal
(Id, ProcessVersionId, LaunchDate, ProposalComplete, IsImplemented, UserId, ImplementDate, ClientId, ProcessOnHoldForChanges)
SELECT Id, ProcessVersionId, LaunchDate, ProposalComplete, IsImplemented, userId, ImplementDate, clientId, ProcessHold FROM @Proposal2

SET IDENTITY_INSERT chaffey.dbo.Proposal OFF;

UPDATE cdm
SET ProposalId = p.proposalId
, StatusAliasId = 14
FROM chaffey.dbo.Module as cdm
INNER JOIN @Proposal AS p on cdm.Id = p.mId

SET IDENTITY_INSERT chaffey.dbo.ProcessLevelActionHistory ON;

INSERT INTO chaffey.dbo.ProcessLevelActionHistory
(Id, CreatedDate, StepLevelId, ProposalId, LevelActionResultTypeId, ResultDate)
SELECT Id, CreatedDate, StepLevelId, ProposalId, LevelActionResultTypeId, ResultDate FROM @Level

SET IDENTITY_INSERT chaffey.dbo.ProcessLevelActionHistory OFF;

SET IDENTITY_INSERT chaffey.dbo.ProcessStepActionHistory ON;

INSERT INTO chaffey.dbo.ProcessStepActionHistory
(Id, CreatedDate, ProcessLevelActionHistoryId, StepId, WaitingForChanges, StepActionResultTypeId, ResultDate, UserId, Comments, ActionLevelRouteId, AgingWorkflowDefaultActionReminderQueued, CommentIsPrivate)
SELECT Id, CreatedDate, ProcessLevelActionHistoryId, StepId, WaitingForChagnes, StepActionResultTypeId, ResultDate, UserId, Comments, ActionLevelRouteId, AgingWorkflow, commentIsPrivate FROM @Step

SET IDENTITY_INSERT chaffey.dbo.ProcessStepActionHistory OFF;