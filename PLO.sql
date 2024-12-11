USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-16274';
DECLARE @Comments nvarchar(Max) = 
	'Create PLO Modify Program Template, and set field to read only for users besides the PLO tab';
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
DECLARE @UserId int = (
SELECT Id FROM [User]
WHERE FirstName = 'Curriqunet'							--get user id
AND Username = 'SupportAdmin@CurriQunet.com'
)

EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 23, @Templatename = 'Program PLO Modification' --copy new Program and Create Program Modification

DECLARE @Templateid2 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new course slo modification
DECLARE @Templatetypeid int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of course slo modifcation

EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Templateid2 , @metaTemplateTypeId = @Templatetypeid -- activates the new template

DECLARE @OldTT int = (
SELECT MetaTemplateTypeId
FROM ProposalType
WHERE Title = 'Program Modification'		------Gets TemplateType currently being used and stores it for later
AND Active = 1
)

INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
select MetaReportId, @Templatetypeid, GETDATE()					--Insert Reports
from MetaReportTemplateType 
where MetaTemplateTypeId = @OldTT

Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId = @Templatetypeid


declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('General Program Information', 'Program', 'ChangeRationale','Update'),
('Program Learning Outcomes', 'ProgramOutcomeMatching', 'ProgramCourseId', 'bye'),
('Program Learning Outcomes', 'ClientLearningOutcomeProgramOutcome', 'ClientLearningOutcomeId', 'bye')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	process int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, process)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)
where mt.MetaTemplateId  in (select * from @templateId)
/******************************************************************************************/
DECLARE @Sections INTEGERS
INSERT INTO @Sections
SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection AS mss
INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
WHERE (mss.MetaBaseSchemaId not in (160, 204, 203) or mss.MetaBaseSchemaId IS NULL)
and mss.MetaSelectedSection_MetaSelectedSectionId IS NOT NULL

DECLARE @Fields2 INTEGERS
INSERT INTO @Fields2
SELECT msf.MEtaSelectedFieldId fROM MetaSelectedField AS msf
INNER JOIN @Sections AS s on msf.MetaSelectedSectionId = s.Id

INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, RoleId, AccessRestrictionType)
SELECT Id, 1, 2 FROM @Fields2
UNION
SELECT Id, 4, 1 FROM @Fields2

INSERT INTO MetaSelectedSectionRolePermission
(MetaSelectedSectionId, RoleId, AccessRestrictionType)
SELECT Id, 1, 2 FROM @Sections
UNION
SELECT Id, 4, 1 FROM @Sections

UPDATE MetaSelectedField
SET ReadOnly = 0
, IsRequired = 0
WHERE MetaSelectedFieldId in (
	SELECT ID FROM @Fields2
)

UPDATE MetaSelectedSection
SET ReadOnly = 0
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

UPDATE MetaSelectedSectionSetting
Set MinElem = NULL
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

INSERT INTO ProposalType
(ClientId, Title, EntityTypeId, ProcessActionTypeId, MetaTemplateTypeId, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, CloneRequired, AllowDistrictClone, AllowCloning, HideProposalRequirementFields, AllowNonAdminReactivation)
VALUES
(1, 'Program PLO Modification', 2, 2, @Templatetypeid, 0, 0, 0, 0, 0, 2, 0, 0, 0, 0, 0)

DECLARE @ID int = SCOPE_IDENTITY()

DECLARE @ID2 int = (SELECT Id FROM Process WHERE Title = 'SLO/PLO' and Active = 1)

INSERT INTO ProcessProposalType
(ProposalTypeId, ProcessId)
VALUES
(@ID, @ID2)

DECLARE @Sections2 INTEGERS
INSERT INTO @Sections2
SELECT MetaSelectedSectionId
FROM MetaSelectedSectionSetting
WHERE IsRequired  IS NOT NULL
AND MinElem IS NULL
AND MaxElem IS NULL
AND LabelWidth IS NULL
AND Height IS NULL

DELETE FROM MetaSelectedSectionSetting
WHERE IsRequired  IS NOT NULL
AND MinElem IS NULL
AND MaxElem IS NULL
AND LabelWidth IS NULL
AND Height IS NULL

DECLARE @table TABLE (id int)
INSERT INTO @table
SELECT SectionId FROM @Fields WHERE Action = 'bye'

while exists(select top 1 Id from @table)
begin
    declare @TID int = (select top 1 Id from @table)
			EXEC spBuilderSectionDelete @clientId, @TID
    delete @table
    where id = @TID
end
/****************************** update templates ******************************************/
INSERT INTO @templateId
VALUES							--insert new templateid into table to keep updates below same
(@templateId2)

update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select templateId FROM @Fields
UNION
SELECT mt.MetaTemplateId FROM MetaTemplate As mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN @Sections2 AS s on s.Id = mss.MetaSelectedSectionId
)					--update metareports

commit
--rollback