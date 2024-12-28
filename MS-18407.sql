USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18407';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text to display the correct data on the CSD report';
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
DECLARE @count INT = (SELECT COUNT(Id) FROM CourseOutcome WHERE CourseId = @entityId)

DECLARE @text NVARCHAR(MAX) = (SELECT CONCAT(
''<table border="2" style="width:100%; table-layout: fixed; margin: auto;">
	<tr>
		<th rowspan="2" colspan="2" style="text-align: center">Assessment Methods</th>
		<th rowspan="2" style="text-align: center">Weighting</th>
		<th rowspan="2" style="text-align: center">Rubric</th>
		<th colspan="'', @count,''"rowspan="1" style="text-align: center">Course Intended Learning Outcomes (CILOs)</th>
	</tr>
	<tr>''))

DECLARE @cos Table (Id INT, coId INT)
INSERT INTO @cos   (Id, CoId)
	SELECT Distinct cem.Id, co.Id
	FROM CourseEvaluationMethod cem
		INNER JOIN CourseOutcome co ON co.CourseId = cem.CourseId
	WHERE cem.CourseId = @entityId

SET @text += (
	SELECT dbo.ConcatWithSepOrdered_Agg('''', SortOrder, concat(''<td style="text-align:left">'', OutcomeText, ''</td>'')) 
	FROM CourseOutcome WHERE CourseId = @entityId)

SET @text += ''</tr>''

DECLARE @checks TABLE (Id INT, Value NVARCHAR(MAX))
INSERT INTO @checks   (Id, Value)
	SELECT Id, CONCAT(	
		''<td style="text-align: center">'',
		CASE WHEN coId IN (
			SELECT CourseOutcomeId FROM CourseEvaluationMethodCourseOutcome 
			WHERE CourseEvaluationMethodId = co.Id)
		THEN ''&#10003'' ELSE '' '' END, ''</td>''
		)
	FROM @cos co

DECLARE @temp TABLE(Id INT IDENTITY PRIMARY KEY, Text NVARCHAR(MAX))

--SET @text += 

DECLARE @rows TABLE (Row NVARCHAR(Max))

INSERT INTO @rows
SELECT CONCAT(	
	''<tr>
		<td colspan="2">'', cem.Rationale, ''</td>
		<td style="text-align:center;">'', cem.Int01, ''%</td>
		<td style="text-align:left;">'', m.Title,   ''</td>'',
		dbo.ConcatWithSep_Agg('' '', ck.Value),
	''</tr>'')
FROM CourseEvaluationMethod cem
	INNER JOIN AssignmentType ast ON cem.AssignmentTypeId = ast.Id
	LEFT JOIN  Module m ON m.Id = cem.Related_ModuleId
	LEFT JOIN  @checks ck ON ck.Id = cem.Id
WHERE cem.CourseId = @entityId
GROUP BY cem.Id, cem.Rationale,cem.Int01, m.Title

SET @text += (SELECT dbo.ConcatWithSep_Agg('' '', Row) FROM @rows)

SET @text += ''</table>''

SELECT @text AS Text, 0 AS Value
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 269

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 269