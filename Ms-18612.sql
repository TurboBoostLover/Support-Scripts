USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18612';
DECLARE @Comments nvarchar(Max) = 
	'Update Old Requisites to new Requisites';
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
DECLARE @Info TABLE ([RequisitesId] int, Course int, ReqCourse int)
INSERT INTO @Info
SELECT 
	cr.Id AS [RequisitesId],
	c.Id AS [Course],
	c3.Id AS [ReqCourse]
FROM Course c
	inner join StatusAlias sa on c.StatusAliasId = sa.Id
	inner join CourseProposal cp on c.Id = cp.CourseId
	inner join Semester s on cp.SemesterId = s.Id
	inner join CourseRequisite cr on c.Id = cr.CourseId
	inner join Course c2 on cr.Requisite_CourseId = c2.Id
	inner join StatusAlias sa2 on c2.StatusAliasId = sa2.Id
	inner join CourseProposal cp2 on c2.Id = cp2.CourseId
	inner join Semester s2 on cp2.SemesterId = s2.Id
	INNER JOIN BaseCourse AS bc on c2.BaseCourseId = bc.Id
	INNER JOIN Course AS c3 on bc.Id = c3.BaseCourseId 
WHERE c.Active = 1
	and c.StatusAliasId in (1,2)
	and c2.StatusAliasId in (4,5)
	and c3.StatusAliasId = 1
Order by c.EntityTitle,sa.Title,c2.EntityTitle,sa2.Title

UPDATE cr
SET Requisite_CourseId = ReqCourse
FROM CourseRequisite AS cr
INNER JOIN @Info AS info on info.RequisitesId = cr.Id

UPDATE AdminReport
SET ReportSQL = '
SELECT 
	c.EntityTitle as Course,
	c.Id AS [Course Id],
	sa.Title as [Course Status],
	s.Title as [Course effective semester],
	c2.EntityTitle as [Requisite Course],
	c2.Id AS [Requisite Course Id],
	sa2.Title as [Requisite Course Status],
	s2.Title as [Requisite Course effective semester],
	COALESCE(CAST(c3.Id AS NVARCHAR), ''No New Version'') AS [Updated Id]
FROM Course c
	inner join StatusAlias sa on c.StatusAliasId = sa.Id
	inner join CourseProposal cp on c.Id = cp.CourseId
	inner join Semester s on cp.SemesterId = s.Id
	inner join CourseRequisite cr on c.Id = cr.CourseId
	inner join Course c2 on cr.Requisite_CourseId = c2.Id
	inner join StatusAlias sa2 on c2.StatusAliasId = sa2.Id
	inner join CourseProposal cp2 on c2.Id = cp2.CourseId
	inner join Semester s2 on cp2.SemesterId = s2.Id
	INNER JOIN BaseCourse AS bc on c2.BaseCourseId = bc.Id
	LEFT JOIN Course AS c3 on bc.Id = c3.BaseCourseId and c3.StatusAliasId = 1
WHERE c.Active = 1
	and c.StatusAliasId in (1,2)
	and c2.StatusAliasId in (4,5)
Order by c.EntityTitle,sa.Title,c2.EntityTitle,sa2.Title
'
WHERE Id = 25