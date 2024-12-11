USE sdccd;

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15608';
DECLARE @Comments nvarchar(Max) = 
	'Bring in Effective Term into Maverick';
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
Select 0 AS Value,
CONCAT(
	''<div class = "CIC"> CIC Approval: '', CONVERT(varchar, cd2.CourseDate, 101), ''</div>'',
	''<div class = "LastReviewed">BOT Approval: '',CONVERT(varchar, cd.CourseDate, 101), ''</div>'',
	''<div class = "state">State Approval: '', CONVERT(varchar, cd3.CourseDate, 101), ''</div>'',
	''<div class = "Effective">Effective Term: '',
	CONCAT(
        SUBSTRING(se2.Title, CHARINDEX('' '', se2.Title) + 1, LEN(se2.Title)), 
        '' '', 
        SUBSTRING(se2.Title, 1, CHARINDEX('' '', se2.Title) - 1)
    )
	,''</div>'',
	''<div><h3><center><b>
    SAN DIEGO COMMUNITY COLLEGE DISTRICT '',B.txt,'' COLLEGE'',D.txt,''<br>
COURSE OUTLINE
</b></center></h3></div>'')
AS Text
FROM Course as c
LEFT JOIN CourseProposal AS cp on cp.CourseId = c.Id
LEFT JOIN CourseYearTerm AS cyt on cyt.CourseId = c.Id
LEFT JOIN Semester AS se on cyt.ActualStartSemesterId = se.Id
LEFT JOIN Semester AS se2 on cp.SemesterId = se2.Id
LEFT JOIN CourseDate AS cd 
	LEFT JOIN CourseDateType AS cdt on cd.CourseDateTypeId = cdt.Id
		on cd.CourseId = c.Id AND (cdt.Title = ''Board of Trustees'')
LEFT JOIN CourseDate AS cd2 
	LEFT JOIN CourseDateType AS cdt2 on cd2.CourseDateTypeId = cdt2.Id
		on cd2.CourseId = c.Id AND (cdt2.Title = ''CIC Approval'')
LEFT JOIN CourseDate AS cd3 
	LEFT JOIN CourseDateType AS cdt3 on cd3.CourseDateTypeId = cdt3.Id
		on cd3.CourseId = c.Id AND (cdt3.Title = ''State Approval'')
outer apply (
	select dbo.ConcatWithSepOrdered_Agg('', '',CAM.sortorder,Cam.title) as txt
	from CourseCampus CC 
		inner join Campus CAM on CC.CampusId = CAM.Id and CAM.id in (1,2,3)
	where C.id = CC.CourseId
) A
outer apply (
	SELECT case when A.txt like ''%,%'' then UPPER(REVERSE(STUFF(REVERSE(A.txt),CHARINDEX('','',REVERSE(A.txt)),1,'' dna ,''))) else UPPER(A.txt) end as txt
) B
outer apply (
	SELECT count(CC.id) as Con
	from CourseCampus CC 
	where C.id = CC.CourseId
) Con
outer apply (
	select case when Con.Con > 1 then ''S'' else '''' end as txt
) D
WHERE c.Id = @entityid
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 2830

DECLARE @SQL2 NVARCHAR(MAX) = '
-- Create a temporary table to hold the data
CREATE TABLE #TempTable (Txt NVARCHAR(MAX), IsHeader BIT, SortOrder INT);

-- Insert headers and text into the temporary table
INSERT INTO #TempTable (Txt, IsHeader, SortOrder)
SELECT 
    CASE
        WHEN co.Header IS NOT NULL THEN CONCAT(''<div><b>'', co.Header, ''</b></div>'')
        ELSE co.Text
    END,
    CASE WHEN co.Header IS NOT NULL THEN 1 ELSE 0 END,
    co.SortOrder
FROM CourseObjective AS co
WHERE co.CourseId = @EntityId
ORDER BY co.SortOrder;

-- Retrieve the formatted text with multiple headers sorted by SortOrder
SELECT 
    CONCAT(''<div>'', 
        STRING_AGG(CASE WHEN IsHeader = 1 THEN Txt ELSE '''' END, ''''),
        ''</div><ol>'',
        STRING_AGG(CASE WHEN IsHeader = 0 THEN CONCAT(''<li>'', Txt) END, ''''),
        ''</ol>''
    ) AS Text
FROM #TempTable
GROUP BY IsHeader
ORDER BY MIN(SortOrder);

-- Drop the temporary table
DROP TABLE #TempTable;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 2860

DECLARE @TABLE TABLE (CourseId int, semester nvarchar(max))
INSERT INTO @TABLE
select vKey.NewId, CONCAT(cp.START_YEAR, ' ',s.SEMESTER_TITLE) 
from sdccd_2_v2.dbo.COURSE_PROPOSAL AS cp
INNER JOIN sdccd_2_v2.dbo.SEMESTERS AS s on cp.SEMESTERS_ID = s.SEMESTERS_ID
INNER JOIN sdccd.dbo.vKeyTranslation AS vKey on vKey.OldId = cp.COURSES_ID
WHERE vKey.DestinationTable = 'Course'

UPDATE cp
SET SemesterId = s.Id	
FROM CourseProposal AS cp
INNER JOIN @TABLE AS t on cp.CourseId = t.CourseId
INNER JOIN Semester AS s on t.semester = s.Title
and s.Active = 1

UPDATE MetaSelectedField 
SET DisplayName = 'Effective Semester'
WHERE MetaAvailableFieldId = 586

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaAvailableFieldId = 586
	or msf.MetaForeignKeyLookupSourceId = 2830
	or msf.MetaForeignKeyLookupSourceId = 2860
)