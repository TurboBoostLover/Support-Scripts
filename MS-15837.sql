USE [clovis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15837';
DECLARE @Comments nvarchar(Max) = 
	'Update SUO Assessment';
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =6; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (30)		--comment back in if just doing some of the mtt's

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
('Assessment Information', 'ModuleOrganizationEntityOutcome', 'OrganizationEntityOutcomeId','Update'),
('Assessment Results', 'ModuleExtension02', 'TextMax04', 'Update2'),
('Assessment Results', 'ModuleExtension02', 'TextMax05', 'Update3'),
('Reflection', 'ModuleExtension02', 'TextMax06', 'Update4'),
('Reflection', 'ModuleExtension02', 'TextMax07', 'Update5'),
('Reflection', 'ModuleExtension02', 'TextMax08', 'Update6'),
('Reflection', 'ModuleExtension02', 'TextMax09', 'Update7')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt)
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action in ('Update', 'Update2', 'Update4')
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 32
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update'
)

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update'
)

INSERT INTO MetaSelectedSectionAttribute
(Name,Value, MetaSelectedSectionId)
SELECT 'lookuptablename','ModuleOrganizationEntityOutcome', SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'lookupcolumnname','OrganizationEntityOutcomeId', SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'columns','1', SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'lookuptablename','ModuleOrganizationEntityOutcome', SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'lookupcolumnname','OrganizationEntityOutcomeId', SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'columns','1', SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'static','true', SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'staticAccordion','true', SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'lookuptablename','ModuleOrganizationEntityOutcome', SectionId FROM @Fields WHERE Action = 'Update4'
UNION
SELECT 'lookupcolumnname','OrganizationEntityOutcomeId', SectionId FROM @Fields WHERE Action = 'Update4'
UNION
SELECT 'columns','1', SectionId FROM @Fields WHERE Action = 'Update4'
UNION
SELECT 'static','true', SectionId FROM @Fields WHERE Action = 'Update4'
UNION
SELECT 'staticAccordion','true', SectionId FROM @Fields WHERE Action = 'Update4'

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 32
, MetaBaseSchemaId = 6229
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in (
		'Update2', 'Update4'
	)
)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in (
		'Update2', 'Update3', 'Update4', 'Update5', 'Update6', 'Update7'
	)
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'SUO Evaluated', -- [DisplayName]
13003, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
28, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action in ('Update2', 'Update4')

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 13016
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 13017
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update3'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 13018
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update4'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 13019
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update5'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 13020
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update6'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 13005
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update7'
)

UPDATE moeo
SET MaxText01 = me.TextMax04,
MaxText02 = me.TextMax05,
MaxText03 = me.TextMax06,
MaxText04 = me.TextMax07,
MaxText05 = me.TextMax08,
Rationale = me.TextMax09
FROM ModuleOrganizationEntityOutcome AS moeo
INNER JOIN ModuleExtension02 AS me on me.ModuleId = moeo.ModuleId
WHERE moeo.ModuleId in (
	SELECT m.Id FROM Module As m
	INNER JOIN MetaTemplate AS mt on m.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateId in (
		SELECT Id FROM @templateId
	)
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback