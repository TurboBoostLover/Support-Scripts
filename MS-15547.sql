USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15547';
DECLARE @Comments nvarchar(Max) = 
	'Implement Courses';
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
DECLARE @ProposalId INTEGERS
INSERT INTO @ProposalId
SELECT Id FROM Proposal
 WHERE ImplementDate = '2024-01-02 00:00:00.000'

UPDATE Proposal	
SET IsImplemented = 1
 WHERE ID in (
	SELECT Id FROM @ProposalId
 )

UPDATE Course
SET StatusAliasId = 1
WHERE ProposalId in (
	SELECT Id FROM @ProposalId
)

UPDATE Course
SET StatusAliasId = 5
WHERE Id in (
	SELECT PreviousId FROM Course
	WHERE ProposalId in (
		SELECT Id FROM @ProposalId
	)
)

UPDATE bc
SET ActiveCourseId = c.Id
FROM BaseCourse AS bc
INNER JOIN Course AS c on c.BaseCourseId = bc.Id
WHERE c.ProposalId in (
	SELECT Id FROM @ProposalId
)