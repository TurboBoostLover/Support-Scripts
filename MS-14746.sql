USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14746';
DECLARE @Comments nvarchar(Max) = 
	'Update Division drop down sql';
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
DECLARE @Admin bit = (
SELECT 1 FROM Module AS m
INNER JOIN [User] AS u on m.UserId = u.Id
INNER JOIN UserRole AS ur on u.Id = ur.UserId and ur.Active = 1 and ur.RoleId = 1
AND m.Id = @EntityId
)

IF @Admin = 1
	BEGIN
		SELECT oe.Title AS Text,
		oe.Id AS Value
		FROM OrganizationEntity As oe
		WHERE oe.OrganizationTierId = 1
		and (oe.Active = 1 or
			oe.Id in (
				SELECT Tier1_OrganizationEntityId FROM ModuleDetail WHERE ModuleId = @EntityId
			)
		)
	Order by Text
	END
ELSE
	BEGIN
			SELECT oe2.Title AS Text,
		oe2.Id AS Value
		FROM Module AS m
			INNER JOIN [User] AS u on m.UserId = u.ID	
			INNER JOIN UserOriginationSubjectPermission AS uop on uop.UserId = u.ID	and uop.Active = 1
			INNER JOIN OrganizationSubject AS oes on uop.SubjectId = oes.SubjectId and uop.Active = 1
			LEFT JOIN UserOriginationOrganizationEntityPermission AS uo on uo.UserId = u.ID	and uo.Active = 1
			INNER JOIN OrganizationEntity AS oe on oes.OrganizationEntityId = oe.Id and oe.OrganizationTierId = 2 and oe.Active = 1
			INNER JOIN OrganizationLink As ol on oe.Id = ol.Child_OrganizationEntityId and ol.Active = 1
			INNER JOIN OrganizationEntity AS oe2 on ol.Parent_OrganizationEntityId = oe2.Id AND oe2.OrganizationTierId = 1 and oe2.Active = 1
		WHERE m.Id = @EntityId
		or oe2.Id in (
			SELECT Tier1_OrganizationEntityId FROM ModuleDetail WHERE ModuleId = @EntityId
		)
		UNION
		SELECT oe2.Title AS Text,
		oe2.Id AS Value
		FROM Module AS m
			INNER JOIN [User] AS u on m.UserId = u.ID	
			INNER JOIN UserOriginationOrganizationEntityPermission AS uoop on uoop.UserId = u.Id and uoop.Active = 1
			INNER JOIN OrganizationEntity AS oe on uoop.OrganizationEntityId = oe.Id and oe.OrganizationTierId = 2 and oe.Active = 1
			INNER JOIN OrganizationLink As ol on oe.Id = ol.Child_OrganizationEntityId and ol.Active = 1
			INNER JOIN OrganizationEntity AS oe2 on ol.Parent_OrganizationEntityId = oe2.Id AND oe2.OrganizationTierId = 1 and oe2.Active = 1
		WHERE m.Id = @EntityId
		or oe2.Id in (
			SELECT Tier1_OrganizationEntityId FROM ModuleDetail WHERE ModuleId = @EntityId
		)
		Order by Text
	END
	'
WHERE Id = 122

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	inner join MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 122
)