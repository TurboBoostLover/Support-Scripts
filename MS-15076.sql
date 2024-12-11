USE [victorvalley];

/*
   Commit
								Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15076';
DECLARE @Comments nvarchar(Max) = 
	'Add Role Permissions to the Articulation Tab for Admins';
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
INSERT INTO MetaSelectedSectionRolePermission
(MetaSelectedSectionId, RoleId, AccessRestrictionType)
SELECT mss.MetaSelectedSectionId, 1, 2 FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mt.MetaTemplateId = mss2.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mss2.MetaSelectedSection_MetaSelectedSectionId IS NULL
AND mss2.SectionName = 'Course Articulation (Articulation Officer Only)'
AND mt.Active = 1 
AND mtt.EntityTypeId = 1
AND mt.IsDraft = 0
AND mt.EndDate IS NULL
AND mtt.Active = 1
AND mtt.IsPresentationView = 0
AND mtt.ClientId = 1

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
SELECT DISTINCT mt.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mt.MetaTemplateId = mss2.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mss2.MetaSelectedSection_MetaSelectedSectionId IS NULL
AND mss2.SectionName = 'Course Articulation (Articulation Officer Only)'
AND mt.Active = 1 
AND mtt.EntityTypeId = 1
AND mt.IsDraft = 0
AND mt.EndDate IS NULL
AND mtt.Active = 1
AND mtt.IsPresentationView = 0
AND mtt.ClientId = 1
)