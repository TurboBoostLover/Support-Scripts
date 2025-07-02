USE [fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18796';
DECLARE @Comments nvarchar(Max) = 
	'Update Semester Date';
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
UPDATE CurriculumPresentation
SET Config = '{"statusBaseMapping":[{"catalogStatusBaseId":1,"entityStatusBaseId":1},{"catalogStatusBaseId":1,"entityStatusBaseId":2},{"catalogStatusBaseId":1,"entityStatusBaseId":5},{"catalogStatusBaseId":2,"entityStatusBaseId":1},{"catalogStatusBaseId":2,"entityStatusBaseId":2},{"catalogStatusBaseId":2,"entityStatusBaseId":5},{"catalogStatusBaseId":4,"entityStatusBaseId":1},{"catalogStatusBaseId":4,"entityStatusBaseId":2},{"catalogStatusBaseId":4,"entityStatusBaseId":5},{"catalogStatusBaseId":5,"entityStatusBaseId":1},{"catalogStatusBaseId":5,"entityStatusBaseId":2},{"catalogStatusBaseId":5,"entityStatusBaseId":5},{"catalogStatusBaseId":5,"entityStatusBaseId":6},{"catalogStatusBaseId":6,"entityStatusBaseId":1},{"catalogStatusBaseId":6,"entityStatusBaseId":2},{"catalogStatusBaseId":6,"entityStatusBaseId":5},{"catalogStatusBaseId":7,"entityStatusBaseId":1},{"catalogStatusBaseId":7,"entityStatusBaseId":2},{"catalogStatusBaseId":7,"entityStatusBaseId":4},{"catalogStatusBaseId":7,"entityStatusBaseId":5},{"catalogStatusBaseId":7,"entityStatusBaseId":6}],"filerHeadOfFamily":false,"filterDeactivations":true}'
WHERE Id = 4