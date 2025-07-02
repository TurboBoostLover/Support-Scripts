USE [chabot];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19205';
DECLARE @Comments nvarchar(Max) = 
	'Update SLO Assessment Configuration';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (24)		--comment back in if just doing some of the mtt's

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
('Main', 'ModuleYesNo', 'YesNo04Id','Title'),
('Outcome to be Assessed', 'ModuleCourseOutcome', 'CourseOutcomeId', 'Outcome'),
('Assessment Plan', 'ModuleCourseOutcome', 'CourseOutcomeId', 'update'),
('Enter Scores', 'ModuleCourseOutcome', 'CourseOutcomeId', 'update')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'triggersectionrefresh', f2.TabId, f.SectionId FROM @Fields AS f
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
WHERE f.Action = 'Outcome'
and f2.Action = 'update'


insert into MetaSelectedFieldAttribute
(Name,Value,MetaSelectedFieldId)
SELECT 'UpdateSubscriptionTable1','ModuleDetail', FieldId FROM @Fields WHERE Action = 'Title'
UNION
SELECT 'UpdateSubscriptionColumn1','Reference_CourseId', FieldId FROM @Fields WHERE Action = 'Title'
UNION
SELECT 'UpdateSubscriptionTable2','Module', FieldId FROM @Fields WHERE Action = 'Title'
UNION
SELECT 'UpdateSubscriptionColumn2','UserId', FieldId FROM @Fields WHERE Action = 'Title'
UNION
SELECT 'UpdateSubscriptionTable3','Module', FieldId FROM @Fields WHERE Action = 'Title'
UNION
SELECT 'UpdateSubscriptionColumn3','SemesterId', FieldId FROM @Fields WHERE Action = 'Title'

INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId)
VALUES
(57, 29)

UPDATE MetaSqlStatement
SET SqlStatement = '
DECLARE @Total int = (SELECT Count(mco.Id) FROM ModuleCourseOutcome AS mco
INNER JOIN CourseOutcome AS co on mco.CourseOutcomeId = co.Id
INNER JOIN Course AS c on co.CourseId = c.Id
INNER JOIN ModuleDetail AS md on md.Reference_CourseId = c.Id and md.ModuleId = mco.ModuleId
WHERE mco.ModuleId = @entityID)

DECLARE @Count1 int = (
SELECT Count(mco.Id) FROM ModuleCourseOutcome AS mco
WHERE ModuleId = @entityID
and mco.YesNoId_01 IS NOT NULL
and mco.MaxText01 IS NOT NULL
and (mco.NeedResources <> 1 or mco.NeedResources IS NULL)
and mco.Id in (
	SELECT ModuleCourseOutcomeId FROM ModuleCourseOutcomeEvaluationMethod AS Mcoe INNER JOIN ModuleCourseOutcome AS mco on mcoe.ModuleCourseOutcomeId = mco.Id WHERE mco.ModuleId = @EntityId
))


DECLARE @Count2 int = (
SELECT Count(mco.Id) FROM ModuleCourseOutcome AS mco 
WHERE ModuleId = @entityID
and mco.YesNoId_01 IS NOT NULL
and mco.MaxText01 IS NOT NULL
and mco.NeedResources = 1
and mco.MaxText05 IS NOT NULL
)

SELECT CASE
	WHEN SUM(ISNULL(@Count1, 0) + ISNULL(@Count2, 0)) = @Total THEN 1
	ELSE 0
	END AS IsValid
'
WHERE Id = 9

UPDATE MetaSqlStatement
SET SqlStatement = '
DECLARE @Total int = (SELECT Count(mco.Id) FROM ModuleCourseOutcome AS mco
INNER JOIN CourseOutcome AS co on mco.CourseOutcomeId = co.Id
INNER JOIN Course AS c on co.CourseId = c.Id
INNER JOIN ModuleDetail AS md on md.Reference_CourseId = c.Id and md.ModuleId = mco.ModuleId
WHERE mco.ModuleId = @entityID)

DECLARE @Count1 int = (
SELECT Count(Id) FROM ModuleCourseOutcome WHERE ModuleId = @entityID
and Int02 IS NOT NULL
and Int03 IS NOT NULL
and Int04 IS NOT NULL
and OutcomeMasteryId IS NOT NULL
and MaxText02 IS NOT NULL
)

SELECT
CASE WHEN @Count1 = @Total THEN 1
ELSE 0
END AS Isvalid
'
WHERE Id = 10

UPDATE MetaSelectedSection
SET SortOrder = SortOrder + 1
, RowPosition = RowPosition + 1
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 23
	and mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
	and mss.SectionName <> 'Assessment Plan'
	and mss.SectionName IS NOT NULL
)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Enter Scores', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
2, -- [RowPosition]
2, -- [SortOrder]
1, -- [SectionDisplayId]
30, -- [MetaSectionTypeId]
27, -- [MetaTemplateId]
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

DECLARE @Tab int = SCOPE_IDENTITY()

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@Tab, -- [MetaSelectedSection_MetaSelectedSectionId]
'Outcomes', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
32, -- [MetaSectionTypeId]
27, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
3593, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)

DECLARE @OL int = SCOPE_IDENTITY()

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@OL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Student Assessment Summary', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
27, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
3593, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)

DECLARE @Form int = SCOPE_IDENTITY()

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
VALUES
('lookuptablename', 'ModuleCourseOutcome', @OL),
('lookupcolumnname', 'CourseOutcomeId', @OL),
('static', '1', @OL),
('staticAccordion', '1', @OL)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'CourseOutcomeId', -- [DisplayName]
1073, -- [MetaAvailableFieldId]
@OL, -- [MetaSelectedSectionId]
0, -- [IsRequired]
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
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Number of students enrolled in class at census', -- [DisplayName]
6094, -- [MetaAvailableFieldId]
@Form, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
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
'Number of students taking assessment', -- [DisplayName]
6095, -- [MetaAvailableFieldId]
@Form, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
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
'Number of students meeting target score', -- [DisplayName]
6096, -- [MetaAvailableFieldId]
@Form, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
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
'Percentage of Assessed / Enrolled', -- [DisplayName]
6100, -- [MetaAvailableFieldId]
@Form, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
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
28086846, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'Percentage of Achievement / Assessed', -- [DisplayName]
6101, -- [MetaAvailableFieldId]
@Form, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
4, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
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
28086847, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'How did the results match the plan''s standard or expectation (choose one)', -- [DisplayName]
1074, -- [MetaAvailableFieldId]
@Form, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
5, -- [RowPosition]
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
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'What actions are recommended to improve student learning for this outcome?', -- [DisplayName]
6099, -- [MetaAvailableFieldId]
@Form, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
6, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
1, -- [WidthUnit]
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
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback