USE [fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18751';
DECLARE @Comments nvarchar(Max) = 
	'Update Validation on drop down';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
		declare @now dateTime = (getDate());

		with AllTerms as (
			select sem.Id
			   , sem.Title
			   , sem.CatalogYear
			   , sem.Active
			   , sem.ClientId
			   , sem.EndDate
			   , sem.Code as SortOrder
			   , sem.Code
			   , sem.StartDate
			   , sem.TermStartDate
			   , sem.TermEndDate
			   , sem.AcademicYearStart
			   , sem.AcademicYearEnd
			from Semester sem
			where (sem.active = 1
				and @now between StartDate and isNull(sem.EndDate, @now)
				and AcademicYearStart >= year(current_timestamp) - 2
				and AcademicYearStart < year(current_timestamp) + 4
				or exists(
					select 1
					from ModuleTerm mt
					where sem.Id = mt.SemesterId
					and mt.ModuleId = @entityId
				)
			)
		)
		select Id as [Value]
		   , Title as [Text]
		from AllTerms
		order by SortOrder;
'
WHERE Id = 110

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
WITH OrderedOutcomes AS (
    SELECT co.Id,
           co.OutcomeText,
           co.SortOrder,
           s.Title,
           mcoem.MaxText01,
           mcoem.MaxText02,
           mcoem.MaxText03,
           -- Ensure unique ordering by falling back to Id
           ROW_NUMBER() OVER (PARTITION BY co.SortOrder ORDER BY co.Id) AS RowNum
    FROM Module AS m
    INNER JOIN ModuleCourseOutcome AS mco ON mco.ModuleId = m.Id
    INNER JOIN CourseOutcome AS co ON mco.CourseOutcomeId = co.Id
    INNER JOIN ModuleCourseOutcomeEvaluationMethod AS mcoem ON mcoem.ModuleCourseOutcomeId = mco.Id
    INNER JOIN Semester AS s ON mcoem.SemesterId = s.Id
    WHERE m.Id = @EntityId
      AND mco.YesNoId_01 = 1
)
SELECT 0 AS Value,
       CONCAT(
           ''<ol style="list-style-type: none; padding: 0; margin: 0;"><li>'',
           dbo.ConcatWithSepOrdered_Agg(''<li>'', SortOrder * 100000 + RowNum, 
               CONCAT(''<b>'', OutcomeText, ''</b>'', ''<br>'', Title, ''<br>'',
                      ''<b>Assessment Methods & Criteria</b>'', ''<br>'', MaxText01, ''<br>'',
                      ''<b>Assessment Results</b><br>'', MaxText02, ''<br>'',
                      ''<b>Assessment Reflection and Analysis</b><br>'', MaxText03))
           , ''</ol>'') AS Text
FROM OrderedOutcomes;
'
, ResolutionSql = '
WITH OrderedOutcomes AS (
    SELECT co.Id,
           co.OutcomeText,
           co.SortOrder,
           s.Title,
           mcoem.MaxText01,
           mcoem.MaxText02,
           mcoem.MaxText03,
           -- Ensure unique ordering by falling back to Id
           ROW_NUMBER() OVER (PARTITION BY co.SortOrder ORDER BY co.Id) AS RowNum
    FROM Module AS m
    INNER JOIN ModuleCourseOutcome AS mco ON mco.ModuleId = m.Id
    INNER JOIN CourseOutcome AS co ON mco.CourseOutcomeId = co.Id
    INNER JOIN ModuleCourseOutcomeEvaluationMethod AS mcoem ON mcoem.ModuleCourseOutcomeId = mco.Id
    INNER JOIN Semester AS s ON mcoem.SemesterId = s.Id
    WHERE m.Id = @EntityId
      AND mco.YesNoId_01 = 1
)
SELECT 0 AS Value,
       CONCAT(
           ''<ol style="list-style-type: none; padding: 0; margin: 0;"><li>'',
           dbo.ConcatWithSepOrdered_Agg(''<li>'', SortOrder * 100000 + RowNum, 
               CONCAT(''<b>'', OutcomeText, ''</b>'', ''<br>'', Title, ''<br>'',
                      ''<b>Assessment Methods & Criteria</b>'', ''<br>'', MaxText01, ''<br>'',
                      ''<b>Assessment Results</b><br>'', MaxText02, ''<br>'',
                      ''<b>Assessment Reflection and Analysis</b><br>'', MaxText03))
           , ''</ol>'') AS Text
FROM OrderedOutcomes;
'
WHERE Id = 219

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (110, 219)