USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15545';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Review';
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
declare @actualClientId int = (
	select ClientId
	from Course
	where Id = @entityId
)
declare @actualTierId int = 2

if exists (
	select top 1 1
	from UserOriginationOrganizationEntityPermission uo
	where uo.OrganizationEntityId is null
	and UserId = @userId
	union select top 1 1
	from UserRole ur
	where ur.UserId = @userId
	and ur.RoleId = 1
)
begin
	select DISTINCT
		oe.Id as [Value]
	   , coalesce(oe.code, '''') + '' - '' + oe.Title as [Text]
	from OrganizationEntity oe
	INNER JOIN OrganizationLink AS OL on ol.Child_OrganizationEntityId = oe.Id
	INNER JOIN OrganizationEntity AS oe2 on ol.Parent_OrganizationEntityId = oe2.Id
	where oe.OrganizationTierId = @actualTierId
	and oe.Active = 1
	and ol.Parent_OrganizationEntityId <> 1231
	and oe.Id <> 1236
	order by Text
	end;
else
	begin
		select
			oe.Id as [Value]
		   , coalesce(oe.code, '''') + '' - '' + oe.Title as [Text]
		   , oe.Code as Code
		   , oe.Title as Title
		from OrganizationEntity oe
			inner join UserOriginationOrganizationEntityPermission uo on uo.OrganizationEntityId = oe.Id
				INNER JOIN OrganizationLink AS OL on ol.Child_OrganizationEntityId = oe.Id
		where (oe.OrganizationTierId = @actualTierId
			and oe.Active = 1
			and uo.UserId = @userId
			and uo.Active =1
		)
			and ol.Parent_OrganizationEntityId <> 1231
			and oe.Id <> 1236
			order by Text
end;
'
WHERE Id = 58

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 58
)