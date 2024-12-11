USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15544';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Program Review';
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
UPDATE MetaSelectedField
SEt MetaForeignKeyLookupSourceId = NULL
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 42
	AND msf.MetaAvailableFieldId = 4366
)

UPDATE OrganizationEntity
SET Title = 'Office of Student Success'
WHERE Id = 47

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @tier1 TABLE(Id INT, Value NVARCHAR(Max))

INSERT INTO @tier1
SELECT oe.Id, oe.Title FROM OrganizationEntity AS oe
INNER JOIN ModuleDetail As md on md.Tier1_OrganizationEntityId = oe.Id
WHERE md.ModuleId = @EntityId

;with
	Link AS(
	select
		OE.Id,
		OT.Id AS OrganizationTierId,
		OE.Title,
		OL.Parent_OrganizationEntityId
	from OrganizationEntity as OE
	inner join OrganizationTier as OT on OE.OrganizationTierId = OT.Id
	left join OrganizationLink as OL 
		on OE.Id = OL.Child_OrganizationEntityId
		AND ol.Active = 1
	where OE.ClientId = @clientId
	And OE.Active = 1
	AND ot.Active = 1
),
OrgData AS
(      
 --Anchor member definition      
	select
		OE.Id,
		OT.Id AS OrganizationTierId,
		OE.Title,
		OL.Parent_OrganizationEntityId
	from OrganizationEntity OE
	inner join OrganizationTier as OT on OE.OrganizationTierId = OT.Id
	left join OrganizationLink as OL on OE.Id = OL.Child_OrganizationEntityId
	where OE.ClientId = @clientId
	AND oe.Active = 1
	AND ot.Active = 1
	Union All

 --Recursive member definition      
	select 
		l.Id,
		l.OrganizationTierId,
		l.Title,
		l.Parent_OrganizationEntityId
	from Link l
	inner join OrgData as O on O.Parent_OrganizationEntityId = l.Id
)

select distinct od.Id AS Value, oe.Title AS Text, Parent_OrganizationEntityId AS filterValue
from OrgData od
	INNER JOIN OrganizationEntity oe ON oe.Id = od.Id
WHERE od.OrganizationTierId = 2
	AND Parent_OrganizationEntityId IN (SELECT Id FROM @tier1)
	AND od.Id not in (
1248, 1249, 1250, 1251, 1252, 1253, 1254, 1255, 1256, 1257,1260,1261, 1263, 1264, 1265, 1266, 1268
)
	UNION
SELECT oe.ID AS Value, oe.Title AS Text, 1231 AS filterValue
FROM OrganizationEntity AS oe where Id = 47
order by oe.Title
'
WHERE Id = 59

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 42
	AND msf.MetaAvailableFieldId = 4366
)