USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16524';
DECLARE @Comments nvarchar(Max) = 
	'Update Ge tab';
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
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		--AND mtt.MetaTemplateTypeId in ()		--comment back in if just doing some of the mtt's

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
('General Education Proposal', 'CourseYesNo', 'YesNo10Id','Relabel1'),
('General Education Proposal', 'CourseGeneralEducation', 'GeneralEducationElementId','Relabel2'),
('General Education Proposal', 'GenericMaxText', 'TextMax01','move'),
('General Education Proposal', 'CourseYesNo', 'YesNo24Id','move')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)
DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
declare @now datetime = getdate(); 
select [Id] as Value, Title as Text 
from [GeneralEducation] 
where @now between StartDate and IsNull(EndDate, @now) and Title in ('English Composition, Oral Communication, and Critical Thinking', 'Arts and Humanities', 'Social and Behavioral Sciences', 'Lifelong Understanding and Self-Development', '')
Order By SortOrder
"

DECLARE @RSQL NVARCHAR(MAX) = "
select (Title) as [Text]
from [GeneralEducation] 
where [Id] = @Id
"

DECLARE @CSQL2 NVARCHAR(MAX) = "
declare @now datetime = getdate(); 
select gee.Id as Value, gee.Title as Text, ge.Id as filterValue, IsNull(gee.SortOrder, gee.Id) as SortOrder, IsNull(ge.SortOrder, ge.Id) as FilterSortOrder 
from  [GeneralEducation] ge 
inner join [GeneralEducationElement] gee on gee.GeneralEducationId = ge.Id 
where @now between gee.StartDate and IsNull(gee.EndDate, @now) and gee.Active = 1 AND ge.Title in ('English Composition, Oral Communication, and Critical Thinking', 'Arts and Humanities', 'Social and Behavioral Sciences', 'Lifelong Understanding and Self-Development', '')
Order By filterValue, SortOrder
"

DECLARE @RSQL2 NVARCHAR(MAX) = "
select gee.Title as Text 
from [GeneralEducationElement] gee 
where gee.Id = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'GeneralEducation', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'FilterGeneralEducation', 2),
(@MAX2, 'GeneralEducationElement', 'Id', 'Title', @CSQL2, @RSQL2, 'Order By SortOrder', 'FilterGeneralEducationElement', 3)

UPDATE MetaSelectedField
SET DisplayName = 'Plan 2: California General Education Transfer Curriculum, Cal-GETC (AA/AS/ADT)'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Relabel1'
)

UPDATE MetaSelectedSection
SET SectionName = 'Plan 2: California General Education Transfer Curriculum, Cal-GETC (AA/AS/ADT)'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Relabel2'
)

UPDATE MetaSelectedSection
SET RowPosition = RowPosition + 3
, SortOrder = SortOrder + 3
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields
)

DECLARE @NewSections TABLE (SecId int, TempId int, nam nvarchar(max), rowid int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId, inserted.SectionName, inserted.RowPosition INTO @NewSections
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
7, -- [RowPosition]
7, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
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
FROM @Fields WHERE Action = 'move'
UNION
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Plan 1: Santa Ana College General Education Requirements for the Associate Degree (AA/AS)', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
8, -- [RowPosition]
8, -- [SortOrder]
1, -- [SectionDisplayId]
32, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
5311, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Fields WHERE Action = 'move'
UNION
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
9, -- [RowPosition]
9, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
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
FROM @Fields WHERE Action = 'move'

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'columns', '1', secId FROM @NewSections WHERE nam = 'Plan 1: Santa Ana College General Education Requirements for the Associate Degree (AA/AS)'
UNION
SELECT 'groupcolumnname', 'GeneralEducationId', secId FROM @NewSections WHERE nam = 'Plan 1: Santa Ana College General Education Requirements for the Associate Degree (AA/AS)'
UNION
SELECT 'grouptablename', 'CourseGE', secId FROM @NewSections WHERE nam = 'Plan 1: Santa Ana College General Education Requirements for the Associate Degree (AA/AS)'
UNION
SELECT 'lookupcolumnname', 'GeneralEducationElementId', secId FROM @NewSections WHERE nam = 'Plan 1: Santa Ana College General Education Requirements for the Associate Degree (AA/AS)'
UNION
SELECT 'lookuptablename', 'CourseGE', secId FROM @NewSections WHERE nam = 'Plan 1: Santa Ana College General Education Requirements for the Associate Degree (AA/AS)'

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Plan 1: Santa Ana College General Education Requirements for the Associate Degree (AA/AS)', -- [DisplayName]
3384, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
75, -- [Width]
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
30, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @NewSections WHERE rowid = 7
UNION
SELECT
'Rationale for all above additions or deletions. If revision(s), please explain the revision and also include rationale.', -- [DisplayName]
2963, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
2, -- [ColSpan]
'Editor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
180, -- [Height]
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
FROM @NewSections WHERE rowid = 9
UNION
SELECT
'General Education Element', -- [DisplayName]
12061, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Checkbox', -- [DefaultDisplayType]
5, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
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
@max2, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @NewSections WHERE rowid = 8
UNION
SELECT
'Proposed For', -- [DisplayName]
12060, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Checkbox', -- [DefaultDisplayType]
5, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
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
@max, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @NewSections WHERE rowid = 8

DECLARE @TABLE TABLE (Id int, sort int)

INSERT INTO GeneralEducation
(Title, StartDate, ClientId, SortOrder)
output inserted.Id, inserted.SortOrder INTO @TABLE
VALUES
('English Composition, Oral Communication, and Critical Thinking', GETDATE(), 1, 0),
('', GETDATE(), 1, 1),
('Arts and Humanities', GETDATE(), 1, 2),
('Social and Behavioral Sciences', GETDATE(), 1, 3),
('', GETDATE(), 1, 4),
('', GETDATE(), 1, 5),
('Lifelong Understanding and Self-Development', GETDATE(), 1, 6)

DECLARE @1 int = (SELECT Id FROM @TABLE WHERE sort = 0)
DECLARE @2 int = (SELECT Id FROM @TABLE WHERE sort = 1)
DECLARE @3 int = (SELECT Id FROM @TABLE WHERE sort = 2)
DECLARE @4 int = (SELECT Id FROM @TABLE WHERE sort = 3)
DECLARE @5 int = (SELECT Id FROM @TABLE WHERE sort = 4)
DECLARE @6 int = (SELECT Id FROM @TABLE WHERE sort = 5)
DECLARE @7 int = (SELECT Id FROM @TABLE WHERE sort = 6)


INSERT INTO GeneralEducationElement
(Title, SortOrder, GeneralEducationId, ClientId, StartDate)
VALUES
('1A. English Composition', 0, @1, 1, GETDATE()),
('1B. Oral Communication and Critical Thinking', 1, @1, 1, GETDATE()),
('2. Mathematical Concepts and Quantitative Reasoning', 2, @2, 1, GETDATE()),
('3A. Arts', 3, @3, 1, GETDATE()),
('3B. Humanities', 4, @3, 1, GETDATE()),
('4A. American Institutions', 5, @4, 1, GETDATE()),
('4B. Social Science', 6, @4, 1, GETDATE()),
('5. Natural Sciences', 7, @5, 1, GETDATE()),
('6. Ethnic Studies', 8, @6, 1, GETDATE()),
('7A. Lifelong Understanding', 9, @7, 1, GETDATE()),
('7B. Lifelong Understanding - Activity', 10, @7, 1, GETDATE())

DECLARE @ShowHide TABLE (RuleId int, TempId int)
INSERT INTO @ShowHide
SELECT DISTINCT MetaDisplayRuleId, mss.MetaTemplateId FROM MetaDisplaySubscriber AS mds
INNER JOIN MetaSelectedSection AS mss on mds.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Fields AS f on mss.MetaTemplateId = f.TemplateId and mss.MetaSelectedSectionId = f.SectionId

INSERT INTO MetaDisplaySubscriber
(MetaDisplayRuleId, MetaSelectedSectionId, SubscriberName)
SELECT DISTINCT sh.RuleId, ns.SecId, 'Hide when no new request' FROM @ShowHide AS sh
INNER JOIN @NewSections AS ns on ns.TempId = sh.TempId
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback