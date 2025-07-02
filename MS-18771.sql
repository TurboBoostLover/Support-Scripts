USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18771';
DECLARE @Comments nvarchar(Max) = 
	'Add Auto update for Rubrics';
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
INSERT INTO EntityTriggeredActionClient
(ClientId, Title, Description, MetaBaseSchemaId, SqlText)
VALUES
(1, 'Rubric Auto Update', 'Map to the new version of Rubrics when they go active execpt on histoical courses', 8095, '
declare
	@changeBatchId int
;

insert into History.ChangeBatch (
	ParentId
	,Component
	,ClientId
	,UserId
	,SourceData
)
select
	@parentChangeBatchId
	,(case
		when (etacm.EntityTriggeredActionBaseId is not null)
			then N''EntityTriggeredActionBase''
		when (etacm.EntityTriggeredActionClientId is not null)
			then N''EntityTriggeredActionClient''
		else null
		end
	)
	,@clientId
	,@userId
	,(
		select
			@triggeredMappingId as EntityTriggeredActionClientMappingId
			,@triggeringEntityTypeId as Triggering_EntityTypeId
			,etacm.EntityTriggeredActionBaseId
			,etacm.EntityTriggeredActionClientId
			,json_query(@actionData) as ActionData
			--,isnull(etab.Title, etac.Title) as TriggeredAction_Title
		for json path, without_array_wrapper
	)
-- using this dummy select so there will always be one row, even if the left join is empty
from (values (null)) as dummy (dummy)
left join dbo.EntityTriggeredActionClientMapping etacm on etacm.Id = @triggeredMappingId
left join dbo.EntityTriggeredActionBase etab on etab.Id = etacm.EntityTriggeredActionBaseId
left join dbo.EntityTriggeredActionClient etac on etac.Id = etacm.EntityTriggeredActionClientId
;

set @changeBatchId = scope_identity();

-- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --

UPDATE cemm
SET ModuleId = m2.Id
FROM CourseEvaluationMethodModule AS cemm
INNER JOIN CourseEvaluationMethod AS em on cemm.CourseEvaluationMethodId = em.Id
INNER JOIN Course AS c on em.CourseId = c.Id
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
INNER JOIN Module AS m on cemm.ModuleId = m.Id
INNER JOIN BaseModule AS bm on bm.Id = m.BaseModuleId
INNER JOIN Module AS m2 on bm.Id = m2.BaseModuleId
INNER JOIN @triggeringEntityIds AS te on te.Id = m2.Id
WHERE sa.StatusBaseId not in (5, 7, 8)
')

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO EntityTriggeredActionClientMapping
(Active, ClientId, EntityTypeId, StatusAliasId, SortOrder, EntityTriggeredActionClientId)
VALUES
(1, 1, 6, 1, 1, @ID)