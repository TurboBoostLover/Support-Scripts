USE [riohondo];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13759';
DECLARE @Comments nvarchar(Max) = 
	'Update Course From Credit Course SLO Revision';
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
Declare @clientId int =6, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    INNER JOIN ProposalType pt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND pt.Active = 1
    AND pt.ProcessActionTypeId = 2 -- SELECT * FROM ProcessActionType (1 = New, 2 = Modify, 6 = Deactivate)
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
	AND mtt.MetaTemplateTypeId = 434 --Hard code to remove all other template types as there where still a bunch

/********************** Changes go HERE **************************************************/

DECLARE @AllFields TABLE (msfId int, Maf int, mssId int, mssTitle NVARCHAR(MAX))
INSERT INTO @AllFields
SELECT msf.MetaSelectedFieldId, msf.MetaAvailableFieldId, mss.MetaSelectedSectionId, mss2.SectionName FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 ON mss2.MetaSelectedSectionId = mss.MetaSelectedSection_MetaSelectedSectionId			--Get all field id's of the template
INNER JOIN MetaTemplate AS mt ON mss2.MetaTemplateId = mt.MetaTemplateId
WHERE mt.MetaTemplateId = (SELECT Id FROM @templateId)


DECLARE @Ignore TABLE (Id int, Tab NVARCHAR(MAX))
INSERT INTO @Ignore
SELECT mss.MetaSelectedSectionId, mss2.SectionName
FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId		--Get sections the two sections to ignore by the fields in them using meta availablefield
WHERE msf.MetaAvailableFieldId in (530, 586)
AND mss.MetaTemplateId = (SELECT Id FROM @templateId)

UPDATE MetaSelectedField
SET ReadOnly = 0
WHERE MetaSelectedFieldId in (SELECT msfId FROM @AllFields)		--set all fields to not be read only

UPDATE MetaSelectedSection
SET ReadOnly = 0
WHERE MetaSelectedSectionId in (SELECT mssId FROM @AllFields)	--set all sections to not be read only

DELETE FROM MetaSelectedFieldRolePermission
WHERE MetaSelectedFieldId in (SELECT msfId FROM @AllFields)		--clean slate of all field roles

DELETE FROM MetaSelectedSectionRolePermission
WHERE MetaSelectedSectionId in (SELECT mssId FROM @AllFields)	--clean slate of all section roles

INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, RoleId, AccessRestrictionType)		--Make all fields only admin editable and visable to user but Student Learning outcome fields
SELECT msfId, 1, 2 FROM @AllFields 
WHERE Maf NOT in (530, 586)
UNION
SELECT msfId, 4, 1 FROM @AllFields 
WHERE Maf NOT in (530, 586)

INSERT INTO MetaSelectedSectionRolePermission
(MetaSelectedSectionId, RoleId, AccessRestrictionType)		--Make all sections only admin editable and visable to user but Studen Learning outcome Sections
SELECT mssId, 1, 2 FROM @AllFields
WHERE mssId NOT IN (SELECT Id FROM @Ignore)
UNION
SELECT mssId, 4, 1 FROM @AllFields
WHERE mssId NOT IN (SELECT Id FROM @Ignore)


--/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Id FROM @templateId)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback