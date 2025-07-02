USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18779';
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
DECLARE @Id int = 266

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @count int = 
(SELECT Count(Id) FROM CourseObjective
WHERE COURSEId = @entityId)

DECLARE @ILC TABLE (Id INT IDENTITY PRIMARY KEY, Title nvarchar(max))

DECLARE @text NVARCHAR(MAX) =
CONCAT (''<table border="2" style="width:100%; table-layout: fixed; margin: auto;">
	<tr>
		<th rowspan="2" style="text-align: center;">Course Intended Learning Outcomes (CILOs)</th>
		<th colspan="'',@count,''" style="text-align: center;">Indicative Learning Contents</th>
	</tr>
	<tr>'')

INSERT INTO @ILC
SELECT CONCAT(''<td style="text-align: left;">'',co.SortOrder, ''</td>'')
FROM CourseObjective co
WHERE co.CourseId = @entityId
ORDER BY co.SortOrder

SET @text +=
(SELECT string_agg(Title,'''') within group (order by Id)
FROM @ILC)

SET @text += ''</tr>''

DECLARE @cos TABLE(ID INT IDENTITY PRIMARY KEY,coId INT, cobj INT, cobjSort INT)
INSERT INTO @cos(coId, cobj, cobjSort)
SELECT co.Id, cobj.Id, cobj.SortOrder
FROM CourseObjective cobj
	Left JOIN CourseOutcome co ON co.CourseId = cobj.CourseId
WHERE co.CourseId = @entityId
ORDER BY co.CourseId

DECLARE @temp Table(coId INT IDENTITY PRIMARY KEY, Id INT, value NVARCHAR(MAX))
INSERT INTO @temp
SELECT coId, CONCAT(	''<td style="text-align:center">'',
				CASE
				WHEN coId IN (SELECT CourseOutcomeId FROM CourseOutcomeCourseObjective WHERE CourseObjectiveId = co.cobj)
					THEN ''&#10003''
				ELSE '' ''
				END,
				''</td>'')
FROM @cos co
ORDER BY co.cobjSort

DECLARE @checks Table(Id Int, checks NVARCHAR(Max))
INSERT INTO @checks (Id, checks)
SELECT Id, string_agg(value, ''  '') within group(order by coId)
FROM @temp
GROUP BY Id

SET @text +=
(SELECT Distinct string_agg(Concat(''<tr><td style="text-align: left;">'',
										co.SortOrder,
										ck.checks,
										''</tr>''),'' '') within group (order by sortorder)
FROM CourseOutcome co
	Inner JOIN @checks ck ON ck.Id = co.Id
WHERE co.CourseId = @entityId)

SET @text += ''</table>''

SELECT  @text AS Text, 0 AS Value
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

SET @SQL = '
DECLARE @text NVARCHAR(MAX) = 
''<table class="tla-table" border="2" style="width: 100%; table-layout: fixed; margin: auto;">
	<tr class="tla-table-tr1">
		<th class="tla-table-col" rowspan="2" colspan="10">Course Intended Learning Outcomes (CILOs)</th>
		<th colspan="16" style="text-align: center;">Teaching and Learning Activities (Note)</th>
	</tr>
	<tr class="tla-table-tr2">
		<td class="tla-activities">1</td>
        <td class="tla-activities">2</td>
        <td class="tla-activities">3</td>
        <td class="tla-activities">4</td>
        <td class="tla-activities">5</td>
        <td class="tla-activities">6</td>
        <td class="tla-activities">7</td>
        <td class="tla-activities">8</td>
        <td class="tla-activities">9</td>
        <td class="tla-activities">10</td>
        <td class="tla-activities">11</td>
        <td class="tla-activities">12</td>
        <td class="tla-activities">13</td>
        <td class="tla-activities">14</td>
        <td class="tla-activities">15</td>
        <td class="tla-activities">16</td>
	</tr>''

DECLARE @cos TABLE (Id INT, Title NVARCHAR(MAX), Value INT)

INSERT INTO @cos (Id, Title, Value)
SELECT co.Id, co.OutcomeText, it.SortOrder
FROM CourseOutcome co
	LEFT JOIN CourseOutcomeInstructionType coit ON coit.CourseOutcomeId	  = co.Id
	LEFT JOIN InstructionType it				ON coit.InstructionTypeId = it.Id
WHERE CourseId = @entityId
ORDER BY co.SortOrder

DECLARE @checks TABLE (Id INT IDENTITY PRIMARY KEY, Text NVARCHAR(MAX))
INSERT INTO @checks
SELECT CONCAT(	
''<tr>
	<td class="tla-table-col" colspan="10">'', co.SortOrder,''</td>
	<td class="tla-activities">'', (CASE WHEN 1  IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 2  IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 3  IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 4  IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 5  IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 6  IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 7  IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 8  IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 9  IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 10 IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 11 IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 12 IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 13 IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 14 IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 15 IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
	<td class="tla-activities">'', (CASE WHEN 16 IN (SELECT Value FROM @cos WHERE Id = co.Id) THEN ''&#10003'' ELSE '' '' END), ''</td>
</tr>''
)
FROM CourseOutcome co WHERE CourseId = @entityId
ORDER BY co.SortOrder

SET @text += (SELECT dbo.ConcatWithSepOrdered_Agg('' '', Id, Text) FROM @checks)
SET @text += ''</table>''

SELECT @text AS Text, 0 AS Value
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= 267

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id