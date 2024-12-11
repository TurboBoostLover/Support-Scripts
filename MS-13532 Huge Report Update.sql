USE [reedley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13532';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Outline Report';
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
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
    AND mtt.IsPresentationView = 1
    AND mtt.ClientId = @clientId
	and mtt.MetaTemplateTypeId <>12

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max),
	IsTabNull bit
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action, IsTabNull)
values
('', 'Course', 'SubjectId','Update', 1),
('Catalog Information', 'CourseProposal', 'SemesterId','Update2', 0),
('General Ed', 'GenericBit', 'Bit17','Update3', 0),
('Course Content', 'CourseQueryText', 'QueryTextId_05','Update4', 0),
('Methods of Delivery/Instruction', 'CourseInstructionType', 'InstructionTypeId','Update5', 0),
('Special Facilities', 'CourseLibraryResource', 'IsFacilities','Update6', 0),
('Sample Homework/Out of Class Assignments', 'Course', 'MathIntensityId','Update7', 0),
('Recommended Materials of Instruction', 'Course', 'ComparableCsuUc','Update8', 0),
('Attached Files', 'CourseAttachedFile', 'Title','Update9', 0),
('Requisites', 'CourseQueryText', 'QueryTextId_09','Update10', 0),
('Course Content', 'CourseQueryText', 'QueryTextId_06','Update11', 0),
('', 'CourseCBCode', 'CB03Id','Update12', 1),
('', 'CourseCBCode', 'CB21Id','Update13', 1),
('', 'CourseProposal', 'ImplementDate','Update14', 1),
('', 'CourseCBCode', 'CB05Id','Update15', 1),
('', 'Course', 'ClientCode','Update16', 1),
('Catalog Information', 'Course', 'SubjectId','Update17', 0),
('Catalog Information', 'CourseQueryText', 'QueryTextId_04','Update18', 0),
('Catalog Information', 'Course', 'OpenEntry','Update19', 0),
('Catalog Information', 'CourseProposal', 'IsRepeatable','Update20', 0),
('Catalog Information', 'CourseDescription', 'ProposedAsId','Update21', 0),
('Catalog Information', 'CourseCBCode', 'CB22Id','Update22', 0),
('Catalog Information', 'Course', 'Description','Update23', 0),
('Course Content', 'GenericMaxText', 'TextMax01','Update24', 0),
('Catalog Information', 'CourseProposal', 'CourseGoal','Update25', 0)

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and (
	(IsTabNull = 1 and mss.SectionName is NULL) or
	mss.SectionName = rfc.TabName))
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/

DECLARE @Tab1 int = (SELECT TabId from @Fields WHERE Action = 'Update')
DECLARE @Tab2 int = (SELECT TabId from @Fields WHERE Action = 'Update2')
DECLARE @Tab3 int = (SELECT TabId from @Fields WHERE Action = 'Update3')
DECLARE @Tab4 int = (SELECT TabId from @Fields WHERE Action = 'Update4')
DECLARE @Tab5 int = (SELECT TabId from @Fields WHERE Action = 'Update5')
DECLARE @Tab6 int = (SELECT TabId from @Fields WHERE Action = 'Update6')
DECLARE @Tab7 int = (SELECT TabId from @Fields WHERE Action = 'Update7')
DECLARE @Tab8 int = (SELECT TabId from @Fields WHERE Action = 'Update8')
DECLARE @Tab9 int = (SELECT TabId from @Fields WHERE Action = 'Update9')
DECLARE @Tab10 int = (SELECT TabId from @Fields WHERE Action = 'Update10')
DECLARE @Sec1 int = (SELECT SectionId from @Fields WHERE Action = 'Update4')
DECLARE @Sec2 int = (SELECT SectionId from @Fields WHERE Action = 'Update11')
DECLARE @Sec3 int = (SELECT SectionId from @Fields WHERE Action = 'Update3')
DECLARE @Sec4 int = (SELECT SectionId from @Fields WHERE Action = 'Update')
DECLARE @Sec5 int = (SELECT SectionId from @Fields WHERE Action = 'Update24')
DECLARE @Sec6 int = (SELECT SectionId from @Fields WHERE Action = 'Update20')
DECLARE @Fld1 int = (SELECT FieldId from @Fields WHERE Action = 'Update')
DECLARE @Fld2 int = (SELECT FieldId from @Fields WHERE Action = 'Update12')
DECLARE @Fld3 int = (SELECT FieldId from @Fields WHERE Action = 'Update13')
DECLARE @Fld4 int = (SELECT FieldId from @Fields WHERE Action = 'Update14')
DECLARE @Fld5 int = (SELECT FieldId from @Fields WHERE Action = 'Update15')
DECLARE @Fld6 int = (SELECT FieldId from @Fields WHERE Action = 'Update3')
DECLARE @Fld7 int = (SELECT FieldId from @Fields WHERE Action = 'Update16')
DECLARE @Fld8 int = (SELECT FieldId from @Fields WHERE Action = 'Update2')
DECLARE @Fld9 int = (SELECT FieldId from @Fields WHERE Action = 'Update17')
DECLARE @Fld10 int = (SELECT FieldId from @Fields WHERE Action = 'Update18')
DECLARE @Fld11 int = (SELECT FieldId from @Fields WHERE Action = 'Update19')
DECLARE @Fld12 int = (SELECT FieldId from @Fields WHERE Action = 'Update20')
DECLARE @Fld13 int = (SELECT FieldId from @Fields WHERE Action = 'Update21')
DECLARE @Fld14 int = (SELECT FieldId from @Fields WHERE Action = 'Update22')
DECLARE @Fld15 int = (SELECT FieldId from @Fields WHERE Action = 'Update23')
DECLARE @Fld16 int = (SELECT FieldId from @Fields WHERE Action = 'Update25')
/************************Tabs*************************************************************/

DECLARE @json nvarchar(MAX) = 
'.report-title{font-size: 32px; max-width: 50%}
.bottom-margin-small::before{display: none !important} 
.report-header{margin-bottom: 0; padding-bottom: 0 !important}
.report-entity-title{padding-top: 1vh; font-weight: bold}
.report-implementdate{display: none}'

UPDATE MetaReport
SET ReportAttributes = json_modify(ReportAttributes,'$.cssOverride',(select @json as 'cssOverride'))
WHERE Id = 362


EXEC spBuilderSectionDelete @clientId, @Tab6
EXEC spBuilderSectionDelete @clientId, @Tab8
EXEC spBuilderSectionDelete @clientId, @Tab9

UPDATE MetaSelectedSection
SET SortOrder = 1
,RowPosition = 1
WHERE MetaSelectedSectionId = @Tab1

UPDATE MetaSelectedSection
SET SortOrder = 2
,RowPosition = 2
, SectionName = 'Units & Hours'
WHERE MetaSelectedSectionId = @Tab2

UPDATE MetaSelectedSection
SET SortOrder = 3
,RowPosition = 3
WHERE MetaSelectedSectionId = @Tab10

UPDATE MetaSelectedSection
SET SortOrder = 4
,RowPosition = 4
WHERE MetaSelectedSectionId = @Tab4

UPDATE MetaSelectedSection
SET SortOrder = 5
,RowPosition = 5
, SectionName = 'Methods of Instruction'
WHERE MetaSelectedSectionId = @Tab5

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Assignments', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
0, -- [ColumnPosition]
6, -- [RowPosition]
6, -- [SortOrder]
1, -- [SectionDisplayId]
15, -- [MetaSectionTypeId]
3, -- [MetaTemplateId]
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
DECLARE @NewT1 int = Scope_Identity()

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@NewT1, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
3, -- [MetaTemplateId]
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

DECLARE @NewS1 int = Scope_Identity()

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'Required Reading', -- [DisplayName]
1780, -- [MetaAvailableFieldId]
@NewS1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TextArea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'Required Writing', -- [DisplayName]
1694, -- [MetaAvailableFieldId]
@NewS1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TextArea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'Other', -- [DisplayName]
1770, -- [MetaAvailableFieldId]
@NewS1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TextArea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'Critical Thinking:', -- [DisplayName]
1755, -- [MetaAvailableFieldId]
@NewS1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TextArea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

UPDATE MetaSelectedSection
SET SortOrder = 7
,RowPosition = 7
, SectionName = 'Methods of Evaluation/Grading'
WHERE MetaSelectedSectionId = @Tab7

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Grade Determination:', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
0, -- [ColumnPosition]
8, -- [RowPosition]
8, -- [SortOrder]
1, -- [SectionDisplayId]
15, -- [MetaSectionTypeId]
3, -- [MetaTemplateId]
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

DECLARE @NewT2 int = Scope_Identity()

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@NewT2, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
'Description/explanation: Based on the categories checked above, it is the recommendation of the department that the instructor''s grading methods fall within the following departmental guidelines; however, the final method of grading is still at the discretion of the individual instructor. The instructor''s syllabus must reflect the criteria by which the student''s grade has been determined. (A minimum of five (5) grades must be recorded on the final roster.)<br><br>If several methods to measure student achievement are used, indicate here the approximate weight or percentage each has in determining student final grades.<br><br>', -- [SectionDescription]
1, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
3, -- [MetaTemplateId]
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

DECLARE @NewS3 int = SCOPE_IDENTITY()

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
NULL, -- [DisplayName]
884, -- [MetaAvailableFieldId]
@NewS3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

UPDATE MetaSelectedSection
SET SortOrder = 9
,RowPosition = 9
, SectionName = 'Transfer / General Education'
WHERE MetaSelectedSectionId = @Tab3

/*****************************Sections****************************************************/

UPDATE MetaSelectedSection
SET SortOrder = 1
,RowPosition = 1 
, SectionName = 'Course Objectives'
, SectionDescription = 'In the process of completing this course, students will:<br>'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId = @Sec2

UPDATE MetaSelectedSection
SET SortOrder = 2
,RowPosition = 2 
, SectionName = 'Student Learning Outcomes'
, SectionDescription = 'Upon successful completion of the course, students will be able to:<br>'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId = @Sec1

UPDATE MetaSelectedSection
SET SortOrder = 3
,RowPosition = 3
,MetaSelectedSection_MetaSelectedSectionId = @Tab5
WHERE MetaSelectedSectionId = @Sec5

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@Tab5, -- [MetaSelectedSection_MetaSelectedSectionId]
'', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
4, -- [RowPosition]
4, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
3, -- [MetaTemplateId]
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
DECLARE @NewS2 int = Scope_IDENTITY()

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'Lab Content', -- [DisplayName]
2553, -- [MetaAvailableFieldId]
@NewS2, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
2, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
500, -- [Height]
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
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

/******************************FIELDS******************************************************/
DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (@Fld1, @Fld2, @Fld3, @Fld4, @Fld9, @Fld10, @Fld11, @Fld13)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'Eligible for Credit for Prior Learning:', -- [DisplayName]
3421, -- [MetaAvailableFieldId]
@Sec6, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
9, -- [RowPosition]
1, -- [ColPosition]
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
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)


UPDATE MetaSelectedField
SET RowPosition = 8
, ColPosition = 1
WHERE MetaSelectedFieldId = @Fld12

UPDATE MetaSelectedField
SET RowPosition = 9
WHERE MetaSelectedFieldId = @Fld16

UPDATE MetaSelectedField
SET RowPosition = 3
WHERE MetaSelectedFieldId = @Fld6

UPDATE MetaSelectedField
SET MetaSelectedSectionId = @Sec3
,RowPosition = 2
WHERE MetaSelectedFieldId = @Fld5

UPDATE MetaSelectedField
Set MetaSelectedSectionId = @Sec3
,RowPosition = 1
WHERE MetaSelectedFieldId = @Fld7

UPDATE MetaSelectedField
SET MetaSelectedSectionId = @Sec3
,RowPosition = 0 
WHERE MetaSelectedFieldId = @Fld14

UPDATE MetaSelectedField
SET MetaSelectedSectionId = @Sec4
,RowPosition = 1
WHERE MetaSelectedFieldId = @Fld8

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@Tab4, -- [MetaSelectedSection_MetaSelectedSectionId]
'Course Description', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
3, -- [MetaTemplateId]
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

DECLARE @NewS4 int = Scope_IDENTITY()

UPDATE MetaSelectedField
SET MetaSelectedSectionId = @NewS4
,RowPosition = 0
,DisplayName = NULL
WHERE MetaSelectedFieldId = @Fld15


/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback