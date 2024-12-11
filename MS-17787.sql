USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17787';
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
DECLARE @SQL NVARCHAR(MAX) = '
-- Step 1: Get the list of program courses
DECLARE @programCourses TABLE (Id INT IDENTITY PRIMARY KEY, Value NVARCHAR(MAX), CourseId INT);
INSERT INTO @programCourses (Value, CourseId)
SELECT CONCAT(s.SubjectCode, '' '', c.Title, '' '', c.CourseNumber) AS Text, c.Id
FROM ProgramSequence pc
INNER JOIN Course c ON c.Id = pc.CourseId
INNER JOIN Subject s ON s.Id = pc.SubjectId
WHERE pc.ProgramId = @EntityId;


-- Step 2: Get the list of Majors and Specializations for the program
DECLARE @Majors TABLE (MajorId INT, Spec INT);
INSERT INTO @Majors
SELECT Parent_Lookup14Id, Lookup14Id 
FROM ProgramLookup14 
WHERE ProgramId = @EntityId;


-- Step 3: Get the coded courses (courses with Majors and Specializations)
DECLARE @codedCourses TABLE (MajorId INT, Spec INT, CourseId INT);
INSERT INTO @codedCourses
SELECT gol1.Lookup14Id, gol14.Lookup14Id, c.Id
FROM Course c
INNER JOIN Subject s ON c.SubjectId = s.Id
INNER JOIN GenericOrderedList01 gol1 ON gol1.CourseId = c.Id
LEFT JOIN GenericOrderedList01Lookup14 AS gol14 ON gol14.GenericOrderedList01Id = gol1.Id
WHERE c.Active = 1;


-- Step 4: Identify courses mapped to program based on Major and Specialization match
DECLARE @MappedCourses TABLE (CourseId INT, CourseText NVARCHAR(MAX));
INSERT INTO @MappedCourses (CourseId, CourseText)
SELECT c.Id, CONCAT(''<a href="/Form/Course/Index/'',c.Id,''" target="_blank">'', s.SubjectCode, '' '', c.Title, '' '', c.CourseNumber, ''</a>'') AS CourseText
FROM Course c
INNER JOIN Subject s ON s.Id = c.SubjectId
LEFT JOIN @codedCourses mc ON mc.CourseId = c.Id
LEFT JOIN @Majors mj ON mc.MajorId = mj.MajorId 
WHERE c.Active = 1
and c.StatusAliasId in (1, 2, 4, 6);

-- Step 5: Get courses included in Program Content & Structure
DECLARE @IncludedCourses TABLE (CourseId INT);
INSERT INTO @IncludedCourses
SELECT DISTINCT CourseId
FROM ProgramSequence
WHERE ProgramId = @EntityId
and CourseId IS NOT NULL;

-- Step 6: Generate the HTML table with red text in both columns when applicable
SELECT 
    ''<table border="1" cellpadding="10" cellspacing="0" style="border-collapse: collapse; width: 100%;">'' + 
    ''<tr>'' +
    ''<th style="border: 1px solid black;">Courses mapped to programme on course side</th>'' +
    ''<th style="border: 1px solid black;">Courses included in programme Content & Structure</th>'' +
    ''</tr>'' + 
    STRING_AGG(
        ''<tr>'' +
        ''<td style="border: 1px solid black;">'' +
        CASE 
            WHEN mc.CourseId IS NULL THEN ''<span style="color: red;">'' + '' (Missing - Not mapped to Majors/Specializations)</span>''
            ELSE mc.CourseText
        END
        + ''</td>'' +
        ''<td style="border: 1px solid black;">'' +
        CASE 
            -- If included in Program Content, show it normally
            WHEN ic.CourseId IS NOT NULL THEN mc.CourseText
            -- If not included in Program Content, display red text
            ELSE ''<span style="color: red;">(Missing - Not included in Program Content)</span>''
        END
        + ''</td>'' +
        ''</tr>'',
    '''') +
    ''</table>'' AS Text, 0 AS Value
FROM @MappedCourses mc
LEFT JOIN @IncludedCourses ic ON mc.CourseId = ic.CourseId
--WHERE NOT (mc.IsMapped = 0 AND ic.CourseId IS NULL);  -- Exclude rows where both are missing
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 47

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 47
)