USE [laspositas];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16237';
DECLARE @Comments nvarchar(Max) = 
	'Create Templates, and set field to read only for users';
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
UPDATE StatusAlias
SET AllowMultiple_Default = 1
WHERE Id = 10

DECLARE @UserId int = (
SELECT Id FROM [User]
WHERE FirstName = 'Curriqunet'							--get user id
AND Username = 'SupportAdmin@CurriQunet.com'
)

EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 11, @Templatename = 'Distance Education'
EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 11, @Templatename = 'Credit For Prior Learning'
EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 11, @Templatename = 'Student Learning Outcomes (SLOs)'
EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 2, @Templatename = 'Guided Map'
EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 2, @Templatename = 'Program Student Learning Outcomes (PSLOs)'

DECLARE @Templatetype1 int = (SELECT MetaTemplateTypeId  FROM MetaTemplateType WHERE TemplateName = 'Distance Education')
DECLARE @Template1 int = (SELECT metaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = @Templatetype1)

DECLARE @Templatetype2 int = (SELECT MetaTemplateTypeId  FROM MetaTemplateType WHERE TemplateName = 'Credit For Prior Learning')
DECLARE @Template2 int = (SELECT metaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = @Templatetype2)

DECLARE @Templatetype3 int = (SELECT MetaTemplateTypeId  FROM MetaTemplateType WHERE TemplateName = 'Student Learning Outcomes (SLOs)')
DECLARE @Template3 int = (SELECT metaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = @Templatetype3)

DECLARE @Templatetype4 int = (SELECT MetaTemplateTypeId  FROM MetaTemplateType WHERE TemplateName = 'Guided Map')
DECLARE @Template4 int = (SELECT metaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = @Templatetype4)

DECLARE @Templatetype5 int = (SELECT MetaTemplateTypeId  FROM MetaTemplateType WHERE TemplateName = 'Program Student Learning Outcomes (PSLOs)')
DECLARE @Template5 int = (SELECT metaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = @Templatetype5)

EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Template1 , @metaTemplateTypeId = @Templatetype1
EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Template2 , @metaTemplateTypeId = @Templatetype2
EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Template3 , @metaTemplateTypeId = @Templatetype3
EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Template4 , @metaTemplateTypeId = @Templatetype4
EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Template5 , @metaTemplateTypeId = @Templatetype5

exec spActivateWorkflow 19, 130
exec spActivateWorkflow 20, 131
exec spActivateWorkflow 21, 132
exec spActivateWorkflow 22, 133
exec spActivateWorkflow 23, 134

DECLARE @TABLE TABLE (Id int, title nvarchar(max))

INSERT INTO ProposalType
(ClientId, Title, EntityTypeId, ProcessActionTypeId, MetaTemplateTypeId, Active, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, CloneRequired, AllowDistrictClone, AllowCloning, HideProposalRequirementFields, AllowNonAdminReactivation)
output inserted.Id, inserted.Title INTO @TABLE
VALUES
(1, 'Distance Education', 1, 2, @Templatetype1, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0),
(1, 'Credit For Prior Learning', 1, 2, @Templatetype2, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0),
(1, 'Student Learning Outcomes (SLOs)', 1, 2, @Templatetype3, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0),
(1, 'Guided Map', 2, 2, @Templatetype4, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0),
(1, 'Program Student Learning Outcomes (PSLOs)', 2, 2, @Templatetype5, 1, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0)

INSERT INTO ProcessProposalType
(ProposalTypeId, ProcessId)
SELECT Id, 19 FROM @TABLE WHERE title = 'Distance Education'
UNION
SELECT Id, 20 FROM @TABLE WHERE title = 'Credit For Prior Learning'
UNION
SELECT Id, 21 FROM @TABLE WHERE title = 'Student Learning Outcomes (SLOs)'
UNION
SELECT Id, 22 FROM @TABLE WHERE title = 'Guided Map'
UNION
SELECT Id, 23 FROM @TABLE WHERE title = 'Program Student Learning Outcomes (PSLOs)'
----------------------------------------------------------------------------------
DECLARE @PSections INTEGERS
INSERT INTO @PSections
SELECT MetaSelectedSectionId FROM MetaSelectedSection As mss
WHERE mss.MetaTemplateId = @Template5
and mss.MetaSelectedSection_MetaSelectedSectionId IS NOT NULL
and (mss.MetaBaseSchemaId not in (
160,
203,
204
)
or mss.MetaBaseSchemaId IS NULL)

UPDATE MetaSelectedSection
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @PSections
)

UPDATE MetaSelectedField
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @PSections
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Distinct mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN @PSections As p on mss.MetaSelectedSectionId = p.Id
)
---------------------------------------------------------------------------------
DECLARE @c1Sections INTEGERS
INSERT INTO @c1Sections
SELECT MetaSelectedSectionId FROM MetaSelectedSection As mss
WHERE mss.MetaTemplateId = @Template1
and mss.MetaSelectedSection_MetaSelectedSectionId IS NOT NULL
and mss.MetaSelectedSectionId not in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	WHERE mss2.SectionName in ('Distance Education', 'DE Course Interactions')
	and mss2.MetaTemplateId = @Template1
)

DELETE FROM MetaControlAttribute
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c1Sections
)

DELETE FROM MetaSelectedSectionSetting
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c1Sections
)

UPDATE MetaSelectedSection
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c1Sections
)

UPDATE MetaSelectedField
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c1Sections
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Distinct mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN @c1Sections As p on mss.MetaSelectedSectionId = p.Id
)
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
DECLARE @c2Sections INTEGERS
INSERT INTO @c2Sections
SELECT MetaSelectedSectionId FROM MetaSelectedSection As mss
WHERE mss.MetaTemplateId = @Template2
and mss.MetaSelectedSection_MetaSelectedSectionId IS NOT NULL
and mss.MetaSelectedSectionId not in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	WHERE mss2.SectionName in ('Credit for Prior Learning', 'Supporting Documents')
	and mss2.MetaTemplateId = @Template2
)

DELETE FROM MetaControlAttribute
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c2Sections
)

DELETE FROM MetaSelectedSectionSetting
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c2Sections
)

UPDATE MetaSelectedSection
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c2Sections
)

UPDATE MetaSelectedField
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c2Sections
)
and MetaAvailableFieldId not in (
2612,
782
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Distinct mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN @c2Sections As p on mss.MetaSelectedSectionId = p.Id
)
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
DECLARE @c3Sections INTEGERS
INSERT INTO @c3Sections
SELECT MetaSelectedSectionId FROM MetaSelectedSection As mss
WHERE mss.MetaTemplateId = @Template3
and mss.MetaSelectedSection_MetaSelectedSectionId IS NOT NULL
and mss.MetaSelectedSectionId not in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	WHERE mss2.SectionName in ('Student Learning Outcomes')
	and mss2.MetaTemplateId = @Template3
)
and (mss.MetaBaseSchemaId not in (939,
449) or mss.MetaBaseSchemaId IS NULL)

DELETE FROM MetaControlAttribute
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c3Sections
)

DELETE FROM MetaSelectedSectionSetting
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c3Sections
)

UPDATE MetaSelectedSection
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c3Sections
)

UPDATE MetaSelectedField
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c3Sections
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Distinct mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN @c3Sections As p on mss.MetaSelectedSectionId = p.Id
)
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
DECLARE @c4Sections INTEGERS
INSERT INTO @c4Sections
SELECT MetaSelectedSectionId FROM MetaSelectedSection As mss
WHERE mss.MetaTemplateId = @Template4
and mss.MetaSelectedSection_MetaSelectedSectionId IS NOT NULL
and mss.MetaSelectedSectionId not in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	WHERE mss2.SectionName in ('Program Requirements', 'Program Mapper')
	and mss2.MetaTemplateId = @Template4
)
--and (mss.MetaBaseSchemaId not in (
--) or mss.MetaBaseSchemaId IS NULL)

DELETE FROM MetaControlAttribute
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c4Sections
)

DELETE FROM MetaSelectedSectionSetting
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c4Sections
)

UPDATE MetaSelectedSection
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c4Sections
)

UPDATE MetaSelectedField
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @c4Sections
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Distinct mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN @c4Sections As p on mss.MetaSelectedSectionId = p.Id
)
---------------------------------------------------------------------------------

--commit
--rollback