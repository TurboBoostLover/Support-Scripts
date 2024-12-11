USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15139';
DECLARE @Comments nvarchar(Max) = 
	'Update Queires to only pull in LAN ILO';
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
declare @now datetime = getDate();
select clo.Id as [Value]
	, ''<b>'' +  
		coalesce(clo.Title, '''') + 
		''</b> '' + 
		case 
			when clo.Active = 0 then ''<span style="color: red;">'' + coalesce(clo.[Description], '''') + ''</span>''
			else coalesce(clo.[Description], '''')
		end + 
		''<br />'' 
	as [Text]
	, clo.ParentId as filterValue
	, isNull(clo.SortOrder, clo.Id) as sortOrder
	, isNull(clop.SortOrder, clop.Id) as filterSortOrder
from ClientLearningOutcome clop
	inner Join ClientLearningOutcome clo on clo.ParentId = clop.Id
where (@now between clo.StartDate and isNull(clo.EndDate, @now)
	or exists (
		select 1
		from ClientLearningOutcomeProgramOutcome clopo
			inner join ProgramOutcome po on clopo.ProgramOutcomeId = po.Id
		where clo.Id = clopo.ClientLearningOutcomeId
		and po.ProgramId = @entityId
	)
)
and clo.ParentId is not null
and clo.ParentId = 45
and clo.ClientId = 1
order by filterValue, sortOrder;
'
WHERE Id = 4018

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 4018
)