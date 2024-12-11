USE [cuesta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15391';
DECLARE @Comments nvarchar(Max) = 
	'Fix bad SQL for program Course List';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
select c.Id as Value,
    concat(EntityTitle, '' - '', sa.Title)  as Text,
    s.Id as FilterValue,
    cd.Variable As IsVariable,
    Case 
        when ca.DistrictCourseTypeId in (1,2) --Credit
            then CAST(Coalesce(cd.MinLectureHour,0) + (Floor(Coalesce(cd.MinLabHour,0) / 3 * 2)*.5) + (Coalesce(cd.MinFieldHour,0)  / 2) as DECIMAL(16, 2)) 
        Else (	ISNULL(cd.MinLectureHour, 0.0) + 
				ISNULL(cd.MinContactHoursLecture, 0.0) + 
				IsNULL(cd.MinLabHour,0.0) + 
				ISNULL(cd.MinContactHoursLab, 0.0) + 
				ISNULL(cd.MinStudyHour,0.0)) * 18
    END AS Min,
    Case 
        when ca.DistrictCourseTypeId in (1,2) --Credit
            then CAST(Coalesce(cd.MaxLectureHour,0) + (Floor(Coalesce(cd.MaxLabHour,0) / 3 * 2)*.5) + (Coalesce(cd.MaxFieldHour,0)  / 2) as DECIMAL(16, 2)) 
        Else (	ISNULL(cd.MaxLectureHour,0.0) + 
				ISNULL(cd.MaxContactHoursLecture,0.0) + 
				ISNULL(cd.MaxLabHour,0.0) + 
				ISNULL(cd.MaxContactHoursLab,0.0) + 
				ISNULL(cd.MaxStudyHour,0.0)) * 18
    END AS Max
    from Course c
        inner join StatusAlias sa on sa.Id = c.StatusAliasId
        inner join Subject s on s.id = c.SubjectId
        INNER JOIN ProgramSequence pc on pc.CourseId = c.id and pc.ProgramId = @entityID
        INNER JOIN CourseDescription cd on c.id = cd.CourseId
        INNER JOIN CourseAttribute ca on cd.CourseId = ca.CourseId
order by Text
'
WHERE Id = 218

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MEtaTemplateId fROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 218
)