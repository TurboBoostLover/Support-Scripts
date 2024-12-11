USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13745';
DECLARE @Comments nvarchar(Max) = 
	'Update PLO Assessment';
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
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
	AND mtt.MetaTemplateTypeId = 33		--hard code Template type

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
('Codes/Dates', 'ModuleExtension01', 'Date02','Remove'),
('Section Aggregate', 'ModuleRelatedModule', 'Reference_ModuleId', 'Remove2'),
('Participation', 'ModuleExtension02', 'TextMax01', 'Remove3'),
('Assessment Results', 'ModuleCRN', 'TextMax03', 'Remove4'),
('Reflection', 'ModuleExtension01', 'TextMax03', 'Remove5'),
('Main', 'Module', 'UserId', 'SortOrder0'),
('Main', 'Module', 'Title', 'SortOrder1'),
('Attach Files', 'ModuleAttachedFile', 'Title', 'helpText'),
('Action Plan', 'ModuleYesNo', 'YesNo10Id', 'Remove6'),
('Action Plan', 'ModuleYesNo', 'YesNo11Id', 'Remove7'),
('Action Plan', 'ModuleExtension01', 'TextMax07', 'Remove8'),
('Main', 'ModuleDetail', 'Reference_ProgramOutcomeId', 'Remove9')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/

DECLARE @Table Table (Id int Identity, sIds int)

DECLARE @Template int = (SELECT Id FROM @templateId)
DECLARE @CodesDates int = (SELECT TabId FROM @Fields WHERE Action = 'Remove')
DECLARE @SectionAgg int = (SELECT TabId FROM @Fields WHERE Action = 'Remove2')
DECLARE @Participation int = (SELECT TabId FROM @Fields WHERE Action = 'Remove3')
DECLARE @AssessmentContenet int = (SELECT SectionId FROM @Fields WHERE Action = 'Remove4')
DECLARE @Reflection int = (SELECT TabId FROM @Fields WHERE Action = 'Remove5')
DECLARE @AttachFiles int = (SELECT TabId FROM @Fields WHERE Action = 'helpText')
DECLARE @Assessment int = (SELECT TabId FROM @Fields WHERE Action = 'Remove4')
DECLARE @Action1 int = (SELECT SectionId FROM @Fields WHERE Action = 'Remove6')
DECLARE @Action2 int = (SELECT SectionId FROM @Fields WHERE Action = 'Remove7')
DECLARE @Action3 int = (SELECT SectionId FROM @Fields WHERE Action = 'Remove8')
DECLARE @FieldD int = (SELECT FieldId FROM @Fields WHERE Action = 'Remove9')
DECLARE @SecD int = (SELECT SectionId FROM @Fields WHERE Action = 'Remove9')



DELETE FROM ModuleSectionSummary
WHERE MetaSelectedSectionId in (@CodesDates, @SectionAgg, @Participation, @AssessmentContenet, @Reflection, @Action1, @Action2, @Action3)

EXEC spBuilderSectionDelete @clientId, @CodesDates
EXEC spBuilderSectionDelete @clientId, @SectionAgg
EXEC spBuilderSectionDelete @clientId, @Participation
EXEC spBuilderSectionDelete @clientId, @AssessmentContenet
EXEC spBuilderSectionDelete @clientId, @Reflection
EXEC spBuilderSectionDelete @clientId, @Action1
EXEC spBuilderSectionDelete @clientId, @Action2
EXEC spBuilderSectionDelete @clientId, @Action3


UPDATE MetaSelectedField
SET RowPosition = 0
WHERE MetaSelectedFieldId = (SELECT FieldId FROM @Fields WHERE Action = 'SortOrder0')

UPDATE MetaSelectedField
SET RowPosition = 1
WHERE MetaSelectedFieldId = (SELECT FieldId FROM @Fields WHERE Action = 'SortOrder1')

UPDATE MetaSelectedSection
SET SectionDescription = 'Attachments may include rubrics, assignments, test questions, student scores, analysis reports, example of student work, etc. Please attach your data results and program learning matrix for this program'
WHERE MetaSelectedSectionId = (SELECT TabId FROM @Fields WHERE Action = 'helpText')


insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId into @Table (sIds)
values
(
1, -- [ClientId]
@AttachFiles, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Template, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)
,
(
2, -- [ClientId]
@Assessment, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Template, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)

SET QUOTED_IDENTIFIER OFF

DECLARE @QUERYSQL NVARCHAR(MAX) = "
SELECT CONCAT(po.Outcome, '<br>') AS Text,
1 AS Value
FROM Module AS m
INNER JOIN ModuleDetail AS md ON md.ModuleId = m.Id
INNER JOIN Program AS p ON md.Reference_ProgramId = p.Id
INNER JOIN ProgramOutcome AS po ON po.ProgramId = p.Id
WHERE m.Id = @entityId
"

SET QUOTED_IDENTIFIER ON

DECLARE @AttachSecId int = (SELECT sIds FROM @Table WHERE Id = 1)
DECLARE @MaxId int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

insert into [MetaForeignKeyCriteriaClient]
([Id], [TableName], [DefaultValueColumn], [DefaultDisplayColumn], [CustomSql], [ResolutionSql], [DefaultSortColumn], [Title], [LookupLoadTimingType], [PickListId], [IsSeeded])
values
(
@MaxId, -- [Id]
'YesNo', -- [TableName]
'Id', -- [DefaultValueColumn]
'Title', -- [DefaultDisplayColumn]
'select Id as Value, Title as Text from YesNo where Title = ''Yes''', -- [CustomSql]
NULL, -- [ResolutionSql]
'Order By SortOrder', -- [DefaultSortColumn]
'Yes Only Yes/No', -- [Title]
1, -- [LookupLoadTimingType]
NULL, -- [PickListId]
NULL-- [IsSeeded]
)
,
(
@MaxId+1, -- [Id]
'QueryText', -- [TableName]
'Id', -- [DefaultValueColumn]
'Title', -- [DefaultDisplayColumn]
@QUERYSQL, -- [CustomSql]
@QUERYSQL, -- [ResolutionSql]
NULL, -- [DefaultSortColumn]
'Program Outcomes QueryText', -- [Title]
2, -- [LookupLoadTimingType]
NULL, -- [PickListId]
NULL-- [IsSeeded]
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId into @Table (sIds)
values
(
'Have you attached all required documents?', -- [DisplayName]
5195, -- [MetaAvailableFieldId]
@AttachSecId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
150, -- [Width]
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
@MaxId, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'Program Outcomes', -- [DisplayName]
9266, -- [MetaAvailableFieldId]
@SecD, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
200, -- [Height]
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
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MaxId + 1, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

DECLARE @MSFID int = (SELECT sIDs FROM @Table WHERE Id = 4)

DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId = @FieldD

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId = @FieldD

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId = @SecD

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 1
, MetaBaseSchemaId = NULL
WHERE MetaSelectedSectionId = @SecD

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
VALUES
('SubText','Save the page for the Outcomes to reload',@MSFID)

/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

exec EntityExpand

exec upUpdateEntitySectionSummary @entityTypeId = @Entitytypeid, @templateId = @Template, @entityId = null; --badge update

--commit
--rollback