USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17175';
DECLARE @Comments nvarchar(Max) = 
	'Clean bad data';
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
--SELECT c.Id AS [Course Id],
--c.EntityTitle AS [Title]
--FROM Course AS c
--INNER JOIN Proposal AS p on c.ProposalId = p.Id
--INNER JOIN CourseProposal AS cp on cp.CourseId = c.Id
--WHERE c.StatusAliasId = 11
--and p.ProcessVersionId in (189, 10)
--and cp.SemesterId <= 138
--UNION
--SELECT c.Id AS [Course Id],
--c.EntityTitle AS [Title]
--FROM Course AS c
--INNER JOIN Proposal AS p on c.ProposalId = p.Id
--INNER JOIN CourseProposal AS cp on cp.CourseId = c.Id
--WHERE c.StatusAliasId = 2
--and ProposalComplete = 0
--and cp.SemesterId <= 138
--and p.ImplementDate < GETDATE()
--order by c.EntityTitle

DECLARE @Course TABLE (CourseId int, ProposalId int, BaseId int)
INSERT INTO @Course
SELECT c.Id, p.Id, c.BaseCourseId FROM Course AS c
INNER JOIN Proposal AS p on c.ProposalId = p.Id
WHERE c.Id in (
5184, 5229, 5216, 5190, 5222, 5205, 5211, 5198, 5199, 5200, 5201, 5214, 5189, --client gave
5177, 5301, 5247, 5300, 5224, 5204, 5210, 5226, 5220, 5219, 5223, 5217, 5329, 5231, 5326, 5194, 5195, 5183, 5192, 5296, 5188, 5343, 5347, 5344 --I found
)

UPDATE Course
SET StatusAliasId = 7
WHERE Id in (
	SELECT c.Id FROM Course AS c
	INNER JOIN @Course AS cc on c.BaseCourseId = cc.BaseId
)

UPDATE Course
SET StatusAliasId = 1
WHERE ID in (
	SELECT CourseId FROM @Course
)

UPDATE BaseCourse
SET ActiveCourseId = c.CourseId
FROM BaseCourse AS bc
INNER JOIN @Course AS c on bc.Id = c.BaseId

UPDATE Proposal
SET ProposalComplete = 1
, IsImplemented = 1
, ImplementDate = GETDATE()
WHERE Id in (
	SELECT ProposalId FROM @Course
)