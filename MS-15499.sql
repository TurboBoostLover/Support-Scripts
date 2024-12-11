USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15499';
DECLARE @Comments nvarchar(Max) = 
	'Update Workflows';
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
INSERT INTO StatusAlias
(StatusBaseId, Title, Description, Active, ClientId, UI_DefaultSelected, AllowMultiple_Default)
VALUES
(6, 'CIC Approval', 'CIC approved', 1, 1, 0, 0)

DECLARE @ID2 int = SCOPE_IDENTITY()

DECLARE @ID INTEGERS
INSERT INTO @ID
SELECT DISTINCT
alr.Id
FROM Step AS s
INNER JOIN StepLevel As sl on s.StepLevelId = sl.Id
INNER JOIN ProcessVersion AS pv on sl.ProcessVersionId = pv.Id
INNER JOIN ActionLevelRoute AS alr on alr.StepLevelId = sl.Id
WHERE s.Title = 'CIC Chair'
and alr.CompletesProposal = 0
and alr.RestartsWorkflow = 0
and pv.EndDate IS NULL

UPDATE ActionLevelRoute
SET StatusAliasId = @ID2
WHERE id in (
	SELECT Id FROM @ID
)

DECLARE @TABLE2 TABLE (id int, nam nvarchar(max))
INSERT INTO @TABLE2
SELECT sa.Id, 'Course'
FROM Step AS s
INNER JOIN StepLevel As sl on s.StepLevelId = sl.Id
INNER JOIN ProcessVersion AS pv on sl.ProcessVersionId = pv.Id
INNER JOIN Process AS p on pv.ProcessId = p.Id
INNER JOIN ProcessProposalType AS ppt on ppt.ProcessId = p.Id
INNER JOIN ProposalType As pt on pt.Id = ppt.ProposalTypeId
INNER JOIN ActionLevelRoute AS alr on alr.StepLevelId = sl.Id
INNER JOIN StepAction AS sa on s.Id = sa.StepId and sa.ActionId = alr.ActionId
WHERE s.Title = 'CIC Chair'
and alr.CompletesProposal = 0
and alr.RestartsWorkflow = 0
and pv.EndDate IS NULL
and pt.EntityTypeId = 1
UNION
SELECT sa.Id, 'Program'
FROM Step AS s
INNER JOIN StepLevel As sl on s.StepLevelId = sl.Id
INNER JOIN ProcessVersion AS pv on sl.ProcessVersionId = pv.Id
INNER JOIN Process AS p on pv.ProcessId = p.Id
INNER JOIN ProcessProposalType AS ppt on ppt.ProcessId = p.Id
INNER JOIN ProposalType As pt on pt.Id = ppt.ProposalTypeId
INNER JOIN ActionLevelRoute AS alr on alr.StepLevelId = sl.Id
INNER JOIN StepAction AS sa on s.Id = sa.StepId and sa.ActionId = alr.ActionId
WHERE s.Title = 'CIC Chair'
and alr.CompletesProposal = 0
and alr.RestartsWorkflow = 0
and pv.EndDate IS NULL
and pt.EntityTypeId = 2

DECLARE @TABLE TABLE (id int, nam nvarchar(max))

INSERT INTO WorkflowTriggeredAction
(StepActionId, TargetElementId, SortOrder, StartDate)
output inserted.Id into @TABLE (id)
SELECT Id ,1, 1, GETDATE() FROM @TABLE2 WHERE nam = 'Course'
UNION
SELECT Id ,2, 1, GETDATE() FROM @TABLE2 WHERE nam = 'Program'

INSERT INTO WorkflowTriggeredActionParameter
(WorkflowTriggeredActionId, WorkflowTriggeredActionQueryId, Value, SortOrder)
SELECT Id, 1, 6,1 FROM @TABLE WHERE nam = 'Course'
UNION
SELECT Id, 1, 3,1 FROM @TABLE WHERE nam = 'Program'