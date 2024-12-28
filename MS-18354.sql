USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18354';
DECLARE @Comments nvarchar(Max) = 
	'Update Query for Assessment 5 to pull in past 4 years of Assessments to Aggregate rather then just the most recent version';
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
declare @AssessmentReviewType int = (select
	case
		when clientid = 2 then 3
		when clientid = 3 then 14
		when clientid = 4 then 25
		when clientid = 5 then 36
	end
from Module
where id = @entityid
)

SELECT 
			    ''<b>'' +
				''[{@{HyperLink}@, @{EntityEdit}@, @{Module}@, @{'' + convert(varchar(20), AGG.ModuleId) + ''}@, @{''
				+ coalesce(AGG.Title, ''This Assessment has no title.'') + ''}@}] ''
				+ ''</b>''
				+ coalesce(''<div style="float:right; color:red"> Created: '' + convert(nvarchar(20),AGG.createdOn,101) + '' </div>'','''')
				+ coalesce(''<br />**'' + AGG.proposaltype + ''**'','''')
				+ coalesce(''<div style="float:right; color:blue"> Originator: '' + AGG.Originator + '' </div>'','''')
				as Text,
				AGG.ModuleId as Value, *
from  udf_GetAssessmentsForAggregation(@EntityId,@AssessmentReviewType,''PLO'',1) AGG
WHERE AGG.CreatedOn > DATEADD(YEAR, -4, GETDATE())
'
WHERE Id = 1991

UPDATE mt
sET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 1991