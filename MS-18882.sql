USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18882';
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
''<div class="h4 section-name">Target Students:</div>
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

SET @text += (
SELECT dbo.ConcatWithSep_Agg(''<br>'',Concat(''<tr>'',''<td>'', ec.Title, ''</td><td>'', case when dt.Code = ''C'' then ''C'' else ''N/A'' end, ''</td><td>'', @majors, ''</td><td>'', @Specialization, ''</td><td>'',ct.Title, ''</td><td>'', c.CourseNumber, ''</td><td>'', @semesters, ''</td></tr>''))
FROM Course c
	INNER JOIN CourseEligibility ce ON c.Id = ce.CourseId
	LEFT JOIN EligibilityCriteria ec ON ce.EligibilityCriteriaId = ec.Id
	LEFT JOIN DisciplineType dt ON c.DisciplineTypeId = dt.Id
	INNER JOIN CourseProposal cp ON cp.CourseId = c.Id
	Left JOIN CreditType ct ON cp.CreditTypeId = ct.Id
WHERE c.Id = @entityId)

SET @text += ''</table>''

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