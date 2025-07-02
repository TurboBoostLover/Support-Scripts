USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19530';
DECLARE @Comments nvarchar(Max) = 
	'Update Course history per clients request for 
	-8347
	-6563
	-8346
	-4467
	-8348
	-4608
	-8350
	-4609
	-9349
	-4607
	';
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
DECLARE @Courses TABLE (Id int, NewFam bit)
INSERT INTO @Courses 
VALUES
(8347, 1),
(6563, 0),
(8346, 1),
(4467, 0),
(8348, 1),
(4608, 0),
(8350, 1),
(4609, 0),
(8349, 1),
(4607, 0)

UPDATE Course
SET StatusAliasId = 1
WHERE Id in (
	SELECT Id FROM @Courses WHERE NewFam = 0
)

UPDATE bc
SET ActiveCourseId = c.Id
FROM BaseCourse AS bc
INNER JOIN Course AS c on c.BaseCourseId = bc.Id
INNER JOIN @Courses AS c2 on c.Id = c2.Id
WHERE c2.NewFam = 0

DECLARE @bc TABLE (Id int, CourseId int)

INSERT INTO BaseCourse
(ClientId, ActiveCourseId)
output inserted.Id, inserted.ActiveCourseId INTO @bc
SELECT 1, Id FROM @Courses WHERE NewFam = 1

UPDATE c
SET c.PreviousId = NULL
, c.ProposalTypeId = 4
, c.BaseCourseId = bc.Id
FROM Course AS c
INNER JOIN @Courses AS c2 on c2.Id = c.Id
INNER JOIN @bc AS bc on bc.CourseId = c.Id
WHERE c2.NewFam = 1

DECLARE @Mapping TABLE (OldId int, NewId int)
INSERT INTO @Mapping
VALUES
(6563, 8347),
(4467, 8346),
(4608, 8348),
(4609, 8350),
(4607, 8349)

UPDATE pc
SET SubjectId = 15
, CourseId = m.OldId
FROM ProgramCourse AS pc
INNER JOIN @Mapping AS m on pc.CourseId = m.NewId

UPDATE cr
SET SubjectId = 15
, Requisite_CourseId = m.OldId
FROM CourseRequisite AS cr
INNER JOIN @Mapping AS m on cr.Requisite_CourseId = m.NewId