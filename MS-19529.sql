USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19529';
DECLARE @Comments nvarchar(Max) = 
	'Update SLO Assessment';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
DECLARE @ScriptTypeId int = 2; /*  Default 1 is Support,  
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
Declare @clientId int =3, -- SELECT Id, Title FROM Client 
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
		AND mtt.MetaTemplateTypeId in (112)		--comment back in if just doing some of the mtt's

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
('Assessment', 'ModuleCourseOutcome', 'MaxText01','1'),
('Assessment', 'ModuleExtension01', 'TextMax02', '2'),
('Section Level Student Data', 'ModuleCourseOutcomeEvaluationMethod', 'EvaluationMethodId', '3'),
('Section Level Student Data', 'ModuleCourseOutcomeEvaluationMethod', 'MaxText01', '4')

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
DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 2;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		--Create more Variables here using Sort if needed
DECLARE @MAX2 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 2)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
select Id as Value,
Title as Text
from ItemType where Active = 1
AND ItemTableName = 'ModuleCourseOutcomeEvaluationMethod' 
AND ClientId = @ClientId
AND Description = 'Direct'
Order By Title
"

DECLARE @RSQL NVARCHAR(MAX) = "
select Id as Value, Title as Text from ItemType where Id = @Id
"

DECLARE @CSQL2 NVARCHAR(MAX) = "
select Id as Value,
Title as Text
from ItemType where Active = 1
AND ItemTableName = 'ModuleCourseOutcomeEvaluationMethod' 
AND ClientId = @ClientId
AND Description = 'Indirect'
Order By Title
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'ItemType', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Assessment Methods for Assessment', 1),
(@MAX2, 'ItemType', 'Id', 'Title', @CSQL2, @RSQL, 'Order By SortOrder', 'Assessment Methods for Assessment', 1)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MEtaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1'
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Criteria for Success', -- [DisplayName]
6099, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
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
FROM @Fields WHERE Action = '1'
UNION
SELECT
'<ul>
	<li>What conclustions might be drawn from the data?</li>
		<ul>
			<li>What about the assessment went well?</li>
			<li>What about the assessment might be improved?</li>
			<li>What steps might be taken to improve students’ level of attainment or success around the outcome?</li>
		</ul>
</ul>
', -- [DisplayName]
4144, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
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
FROM @Fields WHERE Action = '2'

UPDATE MetaSelectedSection
SET MetaSelectedSection_MetaSelectedSectionId = 8460
, SectionName = 'Assessment Methods'
, RowPosition = 5
, SortOrder = 5
WHERE MetaSelectedSectionId = 9253

UPDATE MetaSelectedSection
SET MetaSelectedSection_MetaSelectedSectionId = 9253
, RowPosition = 0
, SortOrder = 0
WHERE MetaSelectedSectionId = 9023

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT
3, -- [ClientId]
9253, -- [MetaSelectedSection_MetaSelectedSectionId]
'Indirect Assessment Methods', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
32, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
3610, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Fields WHERE Action = '4'

DECLARE @Check int = SCOPE_IDENTITY()

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'Assessment Methods', -- [DisplayName]
1192, -- [MetaAvailableFieldId]
@Check, -- [MetaSelectedSectionId]
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
@MAX2, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'', -- [DisplayName]
6123, -- [MetaAvailableFieldId]
@Check, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
2, -- [ColSpan]
'Textarea', -- [DefaultDisplayType]
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

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'columns', '1', @Check
UNION
SELECT 'lookuptablename', 'ModuleCourseOutcomeEvaluationMethod', @Check
UNION
SELECT 'lookupcolumnname', 'ItemTypeId', @Check

UPDATE MetaSelectedSection
SET MetaSelectedSection_MetaSelectedSectionId = 9253
, RowPosition = 2
, SortOrder = 2
WHERE MetaSelectedSectionId = 9024

UPDATE MetaSelectedSection
SET MetaSelectedSection_MetaSelectedSectionId = 9253
, RowPosition = 3
, SortOrder = 3
WHERE MetaSelectedSectionId = 9025

DECLARE @SectionswithFields TABLE (MaxSort INT, SecId INT);
INSERT INTO @SectionswithFields
SELECT MAX(RowPosition) AS MaxSort, MetaSelectedSectionId AS SecId
FROM MetaSelectedField
GROUP BY MetaSelectedSectionId;

WITH OrderedSubsections AS (
    SELECT 
        mss.MetaSelectedSectionId,
        ROW_NUMBER() OVER (PARTITION BY s.SecId ORDER BY mss.SortOrder) AS NewOrder,
        s.MaxSort
    FROM 
        MetaSelectedSection AS mss
    INNER JOIN 
        @SectionswithFields AS s 
    ON 
        mss.MetaSelectedSection_MetaSelectedSectionId = s.SecId
)
UPDATE mss
SET 
    SortOrder = oss.MaxSort + oss.NewOrder,
    RowPosition = oss.MaxSort + oss.NewOrder
FROM 
    MetaSelectedSection AS mss
INNER JOIN 
    OrderedSubsections AS oss
ON 
    mss.MetaSelectedSectionId = oss.MetaSelectedSectionId;

INSERT INTO ItemType
(Title, ItemTableName, SortOrder, StartDate, ClientId, Description)
VALUES
('Course embedded test', 'ModuleCourseOutcomeEvaluationMethod', 0, GETDATE(), 3, 'Direct'),
('Research paper', 'ModuleCourseOutcomeEvaluationMethod', 1, GETDATE(), 3, 'Direct'),
('Written exam ', 'ModuleCourseOutcomeEvaluationMethod', 2, GETDATE(), 3, 'Direct'),
('Problem sets', 'ModuleCourseOutcomeEvaluationMethod', 3, GETDATE(), 3, 'Direct'),
('Standardized test', 'ModuleCourseOutcomeEvaluationMethod', 4, GETDATE(), 3, 'Direct'),
('Oral examination', 'ModuleCourseOutcomeEvaluationMethod', 5, GETDATE(), 3, 'Direct'),
('Portfolio', 'ModuleCourseOutcomeEvaluationMethod', 6, GETDATE(), 3, 'Direct'),
('Objective test', 'ModuleCourseOutcomeEvaluationMethod', 7, GETDATE(), 3, 'Direct'),
('Performance assessment ', 'ModuleCourseOutcomeEvaluationMethod', 8, GETDATE(), 3, 'Direct'),
('Essay', 'ModuleCourseOutcomeEvaluationMethod', 9, GETDATE(), 3, 'Direct'),
('Lab report', 'ModuleCourseOutcomeEvaluationMethod', 10, GETDATE(), 3, 'Direct'),
('Discussion', 'ModuleCourseOutcomeEvaluationMethod', 11, GETDATE(), 3, 'Direct'),
('Survey', 'ModuleCourseOutcomeEvaluationMethod', 12, GETDATE(), 3, 'Indirect'),
('Interview', 'ModuleCourseOutcomeEvaluationMethod', 12, GETDATE(), 3, 'Indirect'),
('Discussion', 'ModuleCourseOutcomeEvaluationMethod', 12, GETDATE(), 3, 'Indirect'),
('Reflective Statement', 'ModuleCourseOutcomeEvaluationMethod', 12, GETDATE(), 3, 'Indirect'),
('Focus Group', 'ModuleCourseOutcomeEvaluationMethod', 12, GETDATE(), 3, 'Indirect'),
('Instructor Observation', 'ModuleCourseOutcomeEvaluationMethod', 12, GETDATE(), 3, 'Indirect')

UPDATE MetaSelectedSection
SET SectionName = 'Direct Assessment Methods'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '3'
)

UPDATE MetaSelectedSectionAttribute
SET Value = 'ItemTypeId'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '3'
)
and Name = 'lookupcolumnname'

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 1192
, MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '3'
)

UPDATE MetaSelectedField
SET ColPosition = 0
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '4'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback