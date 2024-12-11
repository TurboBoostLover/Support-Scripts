USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15623';
DECLARE @Comments nvarchar(Max) = 
	'UPDATE COR Report';
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
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @ActiveCourse int =
(
SELECT 
	case 
		WHEN EXISTS (select bc.ActiveCourseId FROM BaseCourse bc where bc.id = c.BaseCourseId)
		then (select bc.ActiveCourseId FROM BaseCourse bc where bc.id = c.BaseCourseId)
		ELSE
		(
			SELECT Top 1
				c2.id 
			FROM course c2
			WHERE c2.BaseCourseId = c.BaseCourseId
			order by c2.CreatedOn, c2.Id DESC
		)
	END
FROM Course c
WHERE c.id = @entityID
);


declare @Programs table (   ProgramId int,      Title NVARCHAR(max),   Semester nvarchar(500),      StatusAlias NVARCHAR(100)  )
    declare @final NVARCHAR(max) = ''''
INSERT INTO @Programs (ProgramId, Title, Semester, StatusAlias)
	SELECT DISTINCT
		p.id
	   ,COALESCE(p.EntityTitle, p.Title, '''')
	   ,s.Code
	   ,sa.title
	FROM ProgramCourse pc
	INNER JOIN CourseOption co
		ON co.Id = pc.CourseOptionId
	INNER JOIN program p
		ON p.id = co.ProgramId
	INNER JOIN StatusAlias sa
		ON sa.id = p.StatusAliasId
	INNER JOIN ProgramProposal pro
		ON pro.ProgramId = p.Id
	LEFT JOIN Semester s
		ON s.id = pro.SemesterId
	WHERE pc.courseid = @ActiveCourse
	and sa.Id not in (5)
	and p.Id not in (
		SELECT p.Id FROM Program AS p
		INNER JOIN MetaTemplate AS mt on p.MetaTemplateId = mt.MetaTemplateId
		INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateId = mtt.MetaTemplateTypeId
		INNER JOIN ProposalType AS pt on pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
		WHERE pt.Id in (
			SELECT Id FROM ProposalType WHERE Title like ''%Articulation%''
		)
	)
SELECT
	@final = COALESCE(@final, '''') + CONCAT(''<li>'', p.Title, '' ('', p.Semester, '') ('', p.StatusAlias, '')</li>'')
FROM @Programs p
ORDER BY p.Title ASC, p.Semester DESC
SELECT
	0 AS Value
   ,CONCAT(''<ol>'', @final, ''</ol>'') AS Text
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 84

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 84
)