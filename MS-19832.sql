USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19832';
DECLARE @Comments nvarchar(Max) = 
	'Roll back programs into work flow';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
UPDATE Program 
SET StatusAliasId = 7
WHERE Id in (
461, 462, 463
)

UPDATE BaseProgram
SET ActiveProgramId = NULL
WHERE Id in (
	SELECT BaseProgramId FROM Program WHERE Id in (
		461, 462, 463
	)
)

UPDATE ProcessStepActionHistory
SET StepActionResultTypeId =1
, ResultDate = NULL
, Comments = NULL
, ActionLevelRouteId = NULL
WHERE Id in (
	134585, 134582, 134745
)

--SELECT pp.Id, psah.* FROM Program AS p
--INNER JOIN Proposal AS pp on p.ProposalId = pp.Id
--INNER JOIN ProcessLevelActionHistory AS PLAH on PLAH.ProposalId = pp.Id
--INNER JOIN ProcessStepActionHistory AS psah on psah.ProcessLevelActionHistoryId = PLAH.Id
--WHERE p.Id in (
--	461, 462, 463
--)
--ORDER BY pp.Id, psah.ResultDate DESC

--SELECT * FROM StepActionResultType