USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18883';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text';
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
DECLARE @Id int = 252

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @text NVARCHAR(MAX) = 
''<br><div class="h4 section-name">Target Students:</div>
<table border ="2" style="margin: auto; width: 100%;">
<tr style="background:lightgray;">
	<th>Programme</th>
	<th>Curriculum</th>
	<th>Major(s)</th>
	<th>Specialisation(s)</th>
	<th>Course Type</th>
	<th>Course Code</th>
	<th>Semester, Year to be offered</th>
</tr>''

DECLARE @semesters NVARCHAR(MAX) = 
(SELECT dbo.ConcatWithSepOrdered_Agg(''<br>'',cs.SortOrder,CONCAT(s.Title, '' '', It.Title))
FROM CourseSemester cs
	inner JOIN Semester s ON s.Id = cs.SemesterId
	LEFT JOIN ItemType AS it on cs.ItemTypeId = it.Id
WHERE cs.CourseId = @entityId)

DECLARE @majors NVARCHAR(MAX) =
(SELECT dbo.ConcatWithSep_Agg('', '',Title) 
FROM GenericOrderedList01 gol
	INNER JOIN lookup14 l14 ON gol.Lookup14Id = l14.Id 
WHERE gol.CourseId = @entityId)

DECLARE @Specialization NVARCHAR(MAX) = 
(SELECT dbo.ConcatWithSep_Agg(''<br>'',l14.Title) 
FROM GenericOrderedList01Lookup14 gol14
	INNER JOIN lookup14 l14 ON gol14.Lookup14Id = l14.Id
	INNER JOIN GenericOrderedList01 gol ON gol14.GenericOrderedList01Id = gol.Id
WHERE gol.CourseId = @entityId)

DECLARE @TABLE TABLE (CourseId int, ecId int)
INSERT INTO @TABLE
SELECT DISTINCT CourseId, EligibilityCriteriaId FROM CourseEligibility
WHERE CourseId = @EntityId

SET @text += (
SELECT dbo.ConcatWithSep_Agg('''',Concat(''<tr>'',''<td>'', ec.Title, ''</td><td>'', case when dt.Code = ''C'' then ''C'' else ''N/A'' end, ''</td><td>'', @majors, ''</td><td>'', @Specialization, ''</td><td>'',ct.Title, ''</td><td>'', c.CourseNumber, ''</td><td>'', @semesters, ''</td></tr>''))
FROM Course c
	INNER JOIN @TABLE t ON c.Id = t.CourseId
	INNER JOIN CourseProposal cp ON cp.CourseId = c.Id
	LEFT JOIN EligibilityCriteria ec ON t.ecID = ec.Id
	LEFT JOIN DisciplineType dt ON c.DisciplineTypeId = dt.Id
	Left JOIN CreditType ct ON cp.CreditTypeId = ct.Id
WHERE c.Id = @entityId)

DECLARE @aggregatedTable NVARCHAR(MAX);

-- Step 1: Pre-aggregate dependent fields
WITH SpecializationAggregated AS (
    -- Aggregate DISTINCT specializations per CourseSchoolId
    SELECT 
        csms.CourseSchoolMajorId, 
        dbo.ConcatWithSep_Agg(''<br>'', l142.Title) AS SpecializationTitles
    FROM CourseSchoolMajorSpecialization AS csms
    INNER JOIN lookup14 l142 ON csms.Lookup14Id = l142.Id
    GROUP BY csms.CourseSchoolMajorId
),
MajorAggregated AS (
    -- Aggregate DISTINCT majors per CourseSchoolId
    SELECT 
        csm.CourseSchoolId, 
        dbo.ConcatWithSep_Agg(''<br>'', l14.Title) AS MajorTitles
    FROM CourseSchoolMajor AS csm
    INNER JOIN lookup14 l14 ON csm.Lookup14Id = l14.Id 
    GROUP BY csm.CourseSchoolId
),
AggregatedData AS (
    SELECT 
        cs.Id AS CourseSchoolId,  
        c.Id AS CourseId,
        ec.Title AS EligibilityTitle,
        CASE WHEN dt.Code = ''C'' THEN ''C'' ELSE ''N/A'' END AS DisciplineCode,
        -- Join the pre-aggregated majors
        (SELECT MajorTitles FROM MajorAggregated ma WHERE ma.CourseSchoolId = cs.Id) AS MajorTitles,
        ct.Title AS CreditType,
        c.CourseNumber,
        dbo.ConcatWithSep_Agg(''<br>'', CONCAT(s.Title, '' '', item.Title)) AS SemesterTitles,
        -- Join the pre-aggregated specializations
        (SELECT dbo.ConcatWithSep_Agg(''<br>'', SpecializationTitles)
         FROM SpecializationAggregated sa
         WHERE sa.CourseSchoolMajorId IN 
               (SELECT csm.Id FROM CourseSchoolMajor AS csm WHERE csm.CourseSchoolId = cs.Id)
        ) AS SpecializationTitles
    FROM Course c
    INNER JOIN CourseProposal cp ON cp.CourseId = c.Id
    INNER JOIN CourseSchool AS cs ON cs.CourseId = c.Id  
    LEFT JOIN CourseSchoolEligibility AS cse ON cse.CourseSchoolId = cs.Id    
    LEFT JOIN CourseSchoolMajor AS csm ON csm.CourseSchoolId = cs.Id
    LEFT JOIN CourseSchoolMajorSemester AS csmt ON csmt.CourseSchoolMajorId = csm.Id
    LEFT JOIN Semester AS s ON csmt.SemesterId = s.Id
	LEFT JOIN ItemType AS item ON csmt.ItemTypeId = item.Id
    LEFT JOIN DisciplineType dt ON c.DisciplineTypeId = dt.Id
    LEFT JOIN CreditType ct ON cp.CreditTypeId = ct.Id
    LEFT JOIN EligibilityCriteria AS ec ON ec.Id = cse.EligibilityCriteriaId
    WHERE c.Id = @entityId
    GROUP BY cs.Id, c.Id, ec.Title, dt.Code, ct.Title, c.CourseNumber
)
-- Step 2: Format the output as HTML
SELECT @aggregatedTable = dbo.ConcatWithSep_Agg('''', 
    CONCAT(
        ''<tr>'',
        ''<td>'', EligibilityTitle, ''</td>'',
        ''<td>'', DisciplineCode, ''</td>'',
        ''<td>'', MajorTitles, ''</td>'',   -- Now correctly aggregated
        ''<td>'', SpecializationTitles, ''</td>'',  -- Now correctly aggregated
        ''<td>'', CreditType, ''</td>'',
        ''<td>'', CourseNumber, ''</td>'',
        ''<td>'', SemesterTitles, ''</td>'',
        ''</tr>''
    )
)
FROM AggregatedData;

-- Step 3: Append to @text
SET @text += @aggregatedTable;

SET @text += ''</table><br><br>''

SELECT @text AS Text, 0 AS Value
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id