USE [ucdavis];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17877';
DECLARE @Comments nvarchar(Max) = 
	'Update Every Step to get notified at 15 days';
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
DECLARE @Steps INTEGERS
INSERT INTO @Steps
SELECT --p.Title as [Workflow title], Day AS [Reminder], pv.Id as [Version Id], DaysToDefaultAction, DaysPriorToDefaultActionWarning, CASE WHEN DefaultActionId = 5 THEN 'Approve' ELSE '' END, 
s.Id FROM Step As s
INNER JOIN StepLevel As sl on s.StepLevelId = sl.Id
INNER JOIN ProcessVersion AS pv on sl.ProcessVersionId = pv.Id
INNER JOIN Process As p on pv.ProcessId = p.Id
WHERE s.Title like '%College Committee Chair%'
and p.Active = 1
and pv.EndDate IS NULL
and pv.Active = 1
--order BY [Workflow title]

UPDATE Step
SET Day = 15
WHERE Id in (
	SELECT Id FROM @Steps
)