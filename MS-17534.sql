USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17534';
DECLARE @Comments nvarchar(Max) = 
	'Order Programs by Title in the checklist';
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
Please do not alter the script above this comment� except to set
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
SELECT 
	p.Id AS Value, 
	CONCAT(p.entityTitle, '' ('', sa.Title, '')'') AS Text 
FROM Program p 
	left join AwardType at on p.AwardTypeId = at.Id 
	Inner join StatusAlias sa on p.StatusAliasId = sa.Id
WHERE p.ClientId = @clientId 
	and p.Title is not null
	and p.active = 1
	and sa.StatusBaseId in (1)
	and p.Tier1_OrganizationEntityId = (select Tier1_OrganizationEntityId From ModuleDetail where ModuleId = @entityId)
Union
SELECT
	p.Id AS Value, 
	CONCAT(p.entityTitle, '' ('', sa.Title, '')'') AS Text  
FROM Program p
	left join AwardType at on p.AwardTypeId = at.Id 
	Inner join StatusAlias sa on p.StatusAliasId = sa.Id
Where p.Id in (
	select mrm.Reference_ProgramId from ModuleRelatedModule mrm
	WHERE mrm.ModuleId = @entityID
)
order by Text
'
WHERE Id = 25466

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 25466
)