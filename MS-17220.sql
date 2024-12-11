USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17220';
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
--SELECT pp.Id AS [Program Id],
--pp.EntityTitle AS [Title]
--FROM Program AS pp
--INNER JOIN Proposal AS p on pp.ProposalId = p.Id
--INNER JOIN ProgramProposal AS ppp on ppp.ProgramId = pp.Id
--WHERE pp.StatusAliasId = 2
--and ProposalComplete = 0
--and ppp.SemesterId <= 138
--and p.ImplementDate < GETDATE()
--order by pp.EntityTitle

DECLARE @Program TABLE (ProgramId int, ProposalId int, BaseId int)
INSERT INTO @Program
SELECT pp.Id, p.Id, pp.BaseProgramId FROM Program AS pp
INNER JOIN Proposal AS p on pp.ProposalId = p.Id
WHERE pp.Id in (
751, 702, 747, 750, 744, 762, 763, 761, 755, 753, 756, 757, 758, 759, 754, 789, 794, 760, 790, 793, 787, 765, 766, 788, 771, 764, 791, 772, 773, 786, 798, 799, 800, 779, 769, 768, 785, 795, 796,
797, 776, 802, 792, 781, 784, 774, 775, 770, 783, 767, 752, 813, 812, 811, 810
)

UPDATE Program
SET StatusAliasId = 7
WHERE Id in (
	SELECT p.Id FROM Program AS p
	INNER JOIN @Program AS pp on p.BaseProgramId = pp.BaseId
)

UPDATE Program
SET StatusAliasId = 1
WHERE ID in (
	SELECT ProgramId FROM @Program
)

UPDATE BaseProgram
SET ActiveProgramId = p.ProgramId
FROM BaseProgram AS bp
INNER JOIN @Program AS p on bp.Id = p.BaseId

UPDATE Proposal
SET ProposalComplete = 1
, IsImplemented = 1
, ImplementDate = GETDATE()
WHERE Id in (
	SELECT ProposalId FROM @Program
)

DECLARE @Course TABLE (CourseId int, ProposalId int, BaseId int)
INSERT INTO @Course
SELECT c.Id, p.Id, c.BaseCourseId FROM Course AS c
INNER JOIN Proposal AS p on c.ProposalId = p.Id
WHERE c.Id in (
5182, 5185, 5196, 5197, 5202, 5203, 5208, 5209, 5213, 5215, 5225, 5232, 5235, 5238, 5239, 5241, 5245, 5246, 5248, 5249, 5251, 5252, 5254, 5257, 5261, 5265, 5266, 5267, 5269, 5270, 5271, 5272, 5273, 5274, 5275,
5276, 5277, 5278, 5281, 5282, 5283, 5284, 5285, 5286, 5287, 5288, 5289, 5293, 5297, 5298, 5299, 5307, 5308, 5309, 5310, 5311, 5314, 5316, 5317, 5319, 5320, 5321, 5322, 5323, 5325, 5327, 5328, 5345, 5348, 5349, 
5350, 5351, 5373, 5394, 5478, 5504, 5505, 5506, 5539, 5551, 5553, 5554, 5559, 5560
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

UPDATE  Program
SET StatusAliasId = 7
WHERE Id in (
	SELECT P.Id FROM Program AS p
	 WHERE ProposalTypeId in (
		SELECT Id FROM ProposalType WHERE ProcessActionTypeId = 3
	 )
	 and StatusAliasId = 1
)

UPDATE  Course
SET StatusAliasId = 7
WHERE Id in (
	SELECT c.Id FROM Course AS c
	 WHERE ProposalTypeId in (
		SELECT Id FROM ProposalType WHERE ProcessActionTypeId = 3
	 )
	 and StatusAliasId = 1
)