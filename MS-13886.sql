USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13886';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Proposals and set to not active';
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
DECLARE @PID TABLE (Id int)
INSERT INTO @PID (Id)
SELECT p.Id FROM Course AS c
INNER JOIN Proposal AS p on c.ProposalId = p.Id
WHERE c.Id in (11815, 10416, 19760, 19743, 19725, 18116, 19393, 16481, 19609, 19608, 19708)


DECLARE @R TABLE (Id int, date1 datetime)
INSERT INTO @R (Id, date1)
SELECT ProposalId, MAX(ResultDate)
FROM ProcessLevelActionHistory
WHERE ProposalId in (SELECT Id FROM @PID)
GROUP By ProposalId

DECLARE @X TABLE (Id int)
INSERT INTO @X
SELECT plah.Id FROM ProcessLevelActionHistory AS plah
JOIN @R AS r on plah.ResultDate = r.date1 and plah.ProposalId = r.Id

UPDATE Proposal
SET IsImplemented = 0
, ImplementDate = NULL
, ProposalComplete = 0
WHERE Id in (SELECT Id FROM @PID)

UPDATE Course
SET StatusAliasId = 7
WHERE Id in (11815, 10416, 19760, 19743, 19725, 18116, 19393, 16481, 19609, 19608, 19708)

UPDATE Course
SET StatusAliasId = 1
WHERE Id in (368, 376, 7781, 15631, 16672, 17505, 16988)

UPDATE BaseCourse
SET ActiveCourseId = 368
WHERE Id = 368

UPDATE BaseCourse
SET ActiveCourseId = 376
WHERE Id = 376

UPDATE BaseCourse
SET ActiveCourseId = 7781
WHERE Id = 813

UPDATE BaseCourse
SET ActiveCourseId = 15631
WHERE Id = 4725

UPDATE BaseCourse
SET ActiveCourseId = 16672
WHERE Id = 6294

UPDATE BaseCourse
SET ActiveCourseId = 17505
WHERE Id = 6537

UPDATE BaseCourse
SET ActiveCourseId = 16988
WHERE Id = 6557

UPDATE ProcessLevelActionHistory
SET LevelActionResultTypeId = 1
, ResultDate = NULL
WHERE Id in (
SELECT Id FROM @X
)

UPDATE ProcessStepActionHistory
SET StepActionResultTypeId = 1
, ResultDate = NULL
, Comments = NULL
WHERE ProcessLevelActionHistoryId in (
SELECT Id FROM @X
)

--DELETE FROM ProcessStepActionHistory
--WHERE Id in (431674)

--SELECT * FROM ProcessLevelActionHistory WHERE ProposalId in (20002, 20004, 19811, 17375, 19125, 20322, 20285, 20046, 20040, 20696, 20086) AND LevelActionResultTypeId = 1 -- most recnt one needs to have levelaction result type of pending
DELETE FROM ProcessStepActionHistory WHERE ProcessLevelActionHistoryId in (113918, 114239, 114240, 114229, 114228, 114237, 11390, 114236, 114604, 114605, 114243) AND ActionLevelRouteId IS NOT NULL--update stepactionresult type to be pending

--commit