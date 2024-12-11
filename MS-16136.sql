USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16136';
DECLARE @Comments nvarchar(Max) = 
	'Set a package back in review';
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
UPDATE Package 
SET StatusAliasId = 633
WHERE Id = 1470

DECLARE @Course TABLE (CourseId int, prevId int)
INSERT INTO @Course
SELECT pc.CourseId, c.PreviousId FROM PackageCourse AS pc
INNER JOIN Course AS c on pc.CourseId = c.Id
WHERE PackageId = 1470

UPDATE Course
SET StatusAliasId = 633
WHERE Id in (
	SELECT CourseId FROM @Course
)

DECLARE @Program TABLE (ProgramId int, prevId int)
INSERT INTO @Program
SELECT pp.ProgramId, p.PreviousId FROM PackageProgram AS pp
INNER JOIN Program AS p on pp.ProgramId = p.Id
WHERE PackageId = 1470

UPDATE Program
SET StatusAliasId = 633
WHERE Id in (
	SELECT ProgramId FROM @Program
)

UPDATE Course
SET StatusAliasId = 628
WHERE Id in (
	SELECT PrevId FROM @Course
)

UPDATE Program
SET StatusAliasId = 628
WHERE Id in (
	SELECT PrevId FROM @Program
)

UPDATE bc
SET ActiveCourseId = c2.prevId
FROM BaseCourse AS Bc
INNER JOIN Course AS c on c.BaseCourseId = bc.Id
INNER JOIN @Course AS c2 on c.Id = c2.CourseId

UPDATE bp
SET ActiveProgramId = p2.prevId
FROM BaseProgram AS Bp
INNER JOIN Program AS p on p.BaseProgramId = bp.Id
INNER JOIN @Program AS p2 on p.Id = p2.ProgramId

UPDATE ProcessLevelActionHistory
SET LevelActionResultTypeId = 1
, ResultDate = NULL
WHERE Id = 108090

UPDATE ProcessStepActionHistory
SET StepActionResultTypeId = 1
, ResultDate = NULL
, Comments = NULL
,ActionLevelRouteId = NULL
WHERE Id = 231267

UPDATE Proposal
SET LaunchDate = NULL
, IsImplemented = 0
, ImplementDate = NULL
WHERE ID = 16581