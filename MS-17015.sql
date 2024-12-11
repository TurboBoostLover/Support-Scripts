USE [compton];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17015';
DECLARE @Comments nvarchar(Max) = 
	'Update and Activate Courses';
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
Please do not alter the script above this comment� except to set
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
UPDATE Course
SET StatusAliasId = 1
WHERE Id in (
2043, 1401, 2106, 2088, 2075, 2097, 2095, 2096
)

UPDATE Proposal
SET ProposalComplete = 1
, ImplementDate = GETDATE()
WHERE Id in (
	SELECT p.Id FROM Course AS c
	INNER JOIN Proposal AS p on c.ProposalId = p.Id
	WHERE c.Id in (
	2043, 1401, 2106, 2088, 2075, 2097, 2095, 2096
	)
)

UPDATE bc
SET ActiveCourseId = c.Id
FROM BaseCourse as bc
INNER JOIN Course AS c on c.BaseCourseId = bc.Id
WHERE c.Id in (
2043, 1401, 2106, 2088, 2075, 2097, 2095, 2096
)

UPDATE Course
SET StatusAliasId = 6
WHERE Id in (
1196, 1810
)