USE [nukz];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17241';
DECLARE @Comments nvarchar(Max) = 
	'Update Custom Course All Fields Report';
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
DECLARE @plos TABLE (Id INT, pId INT,text nvarchar(max));
DECLARE @p    Table (id INT, text nvarchar(max));

INSERT INTO @plos (Id, pId, text)
SELECT co.Id, po.ProgramId, dbo.concatWIthSep_Agg(''<br>'', po.Outcome)
FROM CourseProgramOutcome cpo
	INNER JOIN ProgramOutcome po ON po.Id = cpo.ProgramOutcomeId
	INNER JOIN CourseProgramOutcomeCourseOutcome cpoco ON cpoco.CourseProgramOutcomeId = cpo.Id
	INNER JOIN CourseOutcome co ON cpoco.CourseOutcomeId = co.Id
WHERE cpo.CourseId = @entityId
GROUP By co.Id, po.ProgramId

INSERT INTO @p (id, text)
SELECT plo.pId, CONCAT(
''<table style="border: 1px solid black;
				border-collapse: collapse;
				table-layout: fixed;
				width: 100%;
				margin-top: 15px;">
	<tr>
		<th style="border: 1px solid black; text-align: center;	background-color: #DDAF53">Course Learning Outcomes</th>
		<th style="border: 1px solid black; text-align: center;	background-color: #DDAF53">Program Learning Outcomes</th>
	</tr>'',
	dbo.ConcatWithSepOrdered_Agg('''', co.Id,CONCAT(''
	<tr>
		<td style="border: 1px solid black; text-align: left; vertical-align: top; padding-left: 5px;">'',co.OutcomeText,''</td>
		<td style="border: 1px solid black; text-align: left; vertical-align: top; padding-left: 5px;">'', plo.text,''</td>
	</tr>'')),
	
''
</table>'') AS Text
FROM CourseOutcome co 
	INNER JOIN @plos plo ON co.Id = plo.Id
WHERE co.CourseId = @entityId
GROUP BY plo.pId

SELECT CONCAT(''<b>Program:</b> '',p.Title, '' ('', sa.Title, '')'', text, ''<p><br><br></p>'') AS Text, 0 AS Value
FROM Program p
	INNER JOIN @p po ON po.Id = p.Id
	INNER JOIN StatusAlias sa ON sa.Id = p.StatusAliasId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 107

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 107
)