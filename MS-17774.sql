USE [clovis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17774';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Forms to Common Course Numbering';
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
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
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
('Cover', 'Course', 'SubjectId','1'),
('Units/Hours', 'CourseDescription', 'MinContHour', '2'),
('Lecture Content', 'GenericMaxText', 'TextMax01', '3'),
('Lab Content', 'GenericMaxText', 'TextMax02', '4'),
('Objectives', 'CourseObjective', 'Text', '5'),
('Assignments and Methods of Evaluation/Grading', 'CourseEvaluationMethod', 'EvaluationMethodId', '6'),
('Text & Course Materials', 'Course', 'ComparableCsuUc', '7'),
('Text & Course Materials', 'Course', 'DoesAffect', '7.2'),
('ASSIST Preview', 'GenericMaxText', 'TextMax01', '8'),
('ASSIST Preview', 'GenericMaxText', 'TextMax02', '9'),
('ASSIST Preview', 'Course', 'Description', '10')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

------------------------------------------------------------------------------------
-- Clean bad tab name that has a hard return after the text
UPDATE MetaSelectedSection 
SET SectionName = 'Units/Hours'
WHERE MetaSelectedSection_MetaSelectedSectionId IS NULL AND SectionName like 'Units/Hours%'
------------------------------------------------------------------------------------

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
UPDATE MetaSelectedField
SET RowPosition = CASE
WHEN RowPosition > 1 and RowPosition < 4  THEN RowPosition + 2
WHEN RowPosition >= 4 THEN RowPosition + 3
ELSE RowPosition + 1
END
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN @Fields AS f on msf.MetaSelectedSectionId = f.SectionId
	WHERE f.Action = '1'
)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in ('3', '4')
)

UPDATE MetaSelectedSection
SET SectionName = 'Course Objectives'
,SectionDescription = 'In the process of completing this course, students will:'
, DisplaySectionDescription = 1
, SortOrder = 1
, RowPosition = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '5'
)

UPDATE MetaSelectedSection
SET SortOrder = SortOrder + 1
, RowPosition = RowPosition + 1
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection As mss
	INNER JOIN @Fields AS f on mss.MetaSelectedSection_MetaSelectedSectionId = f.TabId
	WHERE f.aCtion = '6'
)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId IN (
	SELECT FieldId fROM @Fields WHERE Action in ('7', '7.2')
)

DECLARE @Objectives TABLE (SecId int, TempId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @Objectives
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
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
FROM @Fields WHERE Action = '5'

DECLARE @Evaluation TABLE (SecId int, TempId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @Evaluation
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
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
FROM @Fields WHERE Action = '6'

DECLARE @CCN TABLE (SecId int, FieldId int)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaSelectedFieldId INTO @CCN
SELECT
'Is this a Common Course (AB 1111)?', -- [DisplayName]
3423, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
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
FROM @Fields WHERE Action = '1'

DECLARE @Liseners TABLE (SecId int, FieldId int, nam NVARCHAR(MAX))

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaSelectedFieldId, inserted.MetaSelectedFieldId INTO @Liseners
SELECT
'Course Specialty Identifier (if applicable)', -- [DisplayName]
1698, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
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
FROM @Fields WHERE Action = '1'
UNION
SELECT
'Course Description Part 1 (must stay identical)', -- [DisplayName]
2960, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
6, -- [RowPosition]
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
'Any Rationale or Comment (to justify additional units)', -- [DisplayName]
2961, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
4, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TextArea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
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
UNION
SELECT
'Course Content Part 1: Required Topics (Identical)', -- [DisplayName]
2962, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
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
FROM @Fields WHERE Action = '3'
UNION
SELECT
'Laboratory Activities Part 1 (Identical)', -- [DisplayName]
2963, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
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
FROM @Fields WHERE Action = '4'
UNION
SELECT
'Part 1: Objectives/Outcomes (Identical and Required)', -- [DisplayName]
2964, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
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
FROM @Objectives
UNION
SELECT
'Methods of Evaluation Part 1', -- [DisplayName]
2965, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
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
FROM @Evaluation
UNION
SELECT
'Representative Texts, Manuals, and/or OER that is equivalent; Other Support Materials Part 1', -- [DisplayName]
2966, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
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
FROM @Fields WHERE Action = '7'

INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, RoleId, AccessRestrictionType)
SELECT FieldId, 1, 2 FROM @Liseners WHERE Nam in ('Course Description Part 1 (must stay identical)', 'Course Content Part 1: Required Topics (Identical)', 'Laboratory Activities Part 1 (Identical)', 'Representative Texts, Manuals, and/or OER that is equivalent; Other Support Materials Part 1', 'Methods of Evaluation Part 1', 'Part 1: Objectives/Outcomes (Identical and Required)')
UNION
SELECT FieldId, 4, 1 FROM @Liseners WHERE Nam in ('Course Description Part 1 (must stay identical)', 'Course Content Part 1: Required Topics (Identical)', 'Laboratory Activities Part 1 (Identical)', 'Representative Texts, Manuals, and/or OER that is equivalent; Other Support Materials Part 1', 'Methods of Evaluation Part 1', 'Part 1: Objectives/Outcomes (Identical and Required)')

DECLARE @ShowHIDE TABLE (TemplateId int, TriggerId int, ListenerId int)
INSERT INTO @ShowHIDE
SELECT mss.MetaTemplateId, ccn.FieldId, l.FieldId FROM MetaSelectedSection AS mss
INNER JOIN @CCN AS ccn on ccn.SecId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaTemplateId = mss2.MetaTemplateId
INNER JOIN @Liseners AS l on mss2.MetaSelectedSectionId = l.SecId

while exists(select top 1 1 from @ShowHIDE)
begin
    declare @TID int = (select top 1 TemplateId from @ShowHIDE)
		declare @Trig int = (SELECT Top 1 TriggerId FROM @ShowHIDE WHERE TemplateId = @TID)
		DECLARE @list int = (SELECT Top 1 ListenerId FROM @ShowHIDE WHERE TemplateId = @TID and TriggerId = @Trig)
		exec upAddShowHideRule @Trig, null, 2, 16, 3, '1', NULL, @list, null, 'Show or Hide For Common course Numbering', 'Show or Hide For Common course Numbering'
		delete from @ShowHIDE WHERE TemplateId = @TID and TriggerId = @Trig and ListenerId = @list
end

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
DECLARE @MAX3 int = (SELECT Id FROM #SeedIds WHERE row_num = 3)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

SELECT 0 AS Value,
CASE WHEN @IsCCN = 1 THEN CONCAT('Part 1:', ISNULL(gmt.TextMax16, ' No Data Entered<br>'), 'Part 2:<br>', c.Description)
ELSE c.Description
END AS Text
FROM Course AS c
LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @Entityid
"

DECLARE @SQL2 NVARCHAR(MAX) = "
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

SELECT 0 AS Value,
CASE WHEN @IsCCN = 1 THEN CONCAT('Part 1:', ISNULL(gmt.TextMax18, ' No Data Entered<br>'), 'Part 2:<br>', gmt.TextMax01)
ELSE gmt.TextMax01
END AS Text
FROM Course AS c
INNER JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @Entityid
"

DECLARE @SQL3 NVARCHAR(MAX) = "
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

SELECT 0 AS Value,
CASE WHEN @IsCCN = 1 THEN CONCAT('Part 1:', ISNULL(gmt.TextMax19, ' No Data Entered<br>'), 'Part 2:<br>', gmt.TextMax02)
ELSE gmt.TextMax02
END AS Text
FROM Course AS c
INNER JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @Entityid
"


SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseAssist', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'DescriptionQueryForAssist', 2),
(@MAX2, 'CourseAssist', 'Id', 'Title', @SQL2, @SQL2, 'Order By SortOrder', 'ContentQueryForAssist', 2),
(@MAX3, 'CourseAssist', 'Id', 'Title', @SQL3, @SQL3, 'Order By SortOrder', 'LabQueryForAssist', 2)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, DefaultDisplayType = 'QueryText'
, FieldTypeId = 5
, MetaForeignKeyLookupSourceId = @MAX2
, MetaAvailableFieldId = 8903
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '8'
	UNION
	SELECT msf.MetaSElectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = 11
	and msf.MetaAvailableFieldId = 880
	and mt.Active = 1
	and mt.EndDate IS NULL
)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, DefaultDisplayType = 'QueryText'
, FieldTypeId = 5
, MetaForeignKeyLookupSourceId = @MAX3
, MetaAvailableFieldId = 8904
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '9'
)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, DefaultDisplayType = 'QueryText'
, FieldTypeId = 5
, MetaForeignKeyLookupSourceId = @MAX
, MetaAvailableFieldId = 8905
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '10'
)

DECLARE @SQL4 NVARCHAR(MAX) = '
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

declare @objectives NVARCHAR(max)
select @objectives = coalesce(@objectives,'''') +     ''<li>'' + coalesce(Text,'''') + ''</li>''
from CourseObjective
where courseid = @entityId

SELECT 0 AS Value,
CASE WHEN @IsCCN = 1 THEN CONCAT(''Part 1:'', ISNULL(gmt.TextMax20, '' No Data Entered<br>''), ''Part 2:<br><ul>'', @objectives, ''</ul>'')
ELSE CONCAT(''<ul>'', @objectives, ''</ul>'')
END AS Text
FROM Course AS c
LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @Entityid
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL4
, ResolutionSql = @SQL4
WHERE Id = 937

DECLARE @SQL5 NVARCHAR(MAX) = '
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

declare @final NVARCHAR(max) = ''''

select @final = coalesce(@final,'''') + em.Title + '': '' + coalesce(cem.Rationale,'''') + ''<br>''
from CourseEvaluationMethod cem
    inner join EvaluationMethod em on em.id = cem.EvaluationMethodId
where cem.CourseId = @entityId

SELECT 0 AS Value,
CASE WHEN @IsCCN = 1 THEN CONCAT(''Part 1:'', ISNULL(gmt.TextMax21, '' No Data Entered<br>''), ''Part 2:<br>'', @final)
ELSE @final
END AS Text
FROM Course AS c
LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @Entityid
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL5
, ResolutionSql = @SQL5
WHERE Id = 939

DECLARE @SQL6 NVARCHAR(MAX) = '
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

declare @final NVARCHAR(max) = ''''

select @final = coalesce(@final,'''') + 
    case
        when required is not null then ''Required: True <br>''
        else '''' 
    end + 
    case 
        when Recommended is not null then ''Recommended: True <br>''
        else ''''
    end +
    case
        when c.id is not null then ''Condition: '' + c.Title + ''<br>''
        else ''''
    end +
    coalesce(cto.TextOther + ''<br>'','''')
from CourseTextOther cto
    left join Condition c on c.id = cto.ConditionId
where cto.CourseId = @entityId


SELECT 0 AS Value,
CASE WHEN @IsCCN = 1 THEN CONCAT(''Part 1:'', ISNULL(gmt.TextMax22, '' No Data Entered<br>''), ''Part 2:<br>'', @final)
ELSE @final
END AS Text
FROM Course AS c
LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @Entityid
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL6
, ResolutionSql = @SQL6
WHERE Id = 940

DECLARE @SQL7 NVARCHAR(MAX) = '
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

DECLARE @TEXT1 NVARCHAR(100) = ''<b>Objectives: In the process of completing this course, students will:</b><ol><li>''
DECLARE @TEXT2 NVARCHAR(100) = ''</ol><br><b>Student Learning Outcomes: Upon completion of this course, students will be able to:</b>''

DECLARE @OBJ NVARCHAR(MAX) = (SELECT  dbo.ConcatWithSep_Agg(''<li>'', co.Text) FROM CourseObjective AS co WHERE co.CourseId = @EntityId)
DECLARE @OUT NVARCHAR(MAX) = (SELECT dbo.ConcatWithSep_Agg(''<li>'', co.OutcomeText) FROM CourseOutcome AS co WHERE co.CourseId = @EntityId)

DECLARE @Normal NVARCHAR(MAX) = (SELECT DISTINCT
CONCAT(@TEXT1,
	CASE
		WHEN @OBJ IS NULL THEN ''None''
		ELSE @OBJ
	END,
@TEXT2, ''<ol><li>'',
		CASE
		WHEN @OUT IS NULL THEN ''None''
		ELSE @OUT
	END,
	''</ol>''
))

SELECT 0 AS Value,
CASE WHEN @IsCCN = 1 THEN CONCAT(''Part 1:'', ISNULL(gmt.TextMax20, '' No Data Entered<br>''), ''Part 2:<br>'', @Normal)
ELSE @Normal
END AS Text
FROM Course AS c
LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @Entityid
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL7
, ResolutionSql = @SQL7
, LookupLoadTimingType = 2
WHERE Id = 9

DECLARE @SQL8 NVARCHAR(MAX) = '
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

DECLARE @Normal NVARCHAR(MAX) = (SELECT 
dbo.ConcatWithSepOrdered_Agg(''<br>'', em.SortOrder,CONCAT(''<b>'',em.Title, ''</b> '',
	CASE WHEN LEN(cem.Rationale) > 0
	THEN CONCAT(''<br>'',cem.Rationale)
	ELSE ''''
	END
	))
FROM CourseEvaluationMethod AS cem
INNER JOIN EvaluationMethod AS em on cem.EvaluationMethodId = em.Id
WHERE cem.CourseId = @EntityId
)


SELECT 0 AS Value,
CASE WHEN @IsCCN = 1 THEN CONCAT(''Part 1:'', ISNULL(gmt.TextMax21, '' No Data Entered<br>''), ''Part 2:<br>'', @Normal)
ELSE @Normal
END AS Text
FROM Course AS c
LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @Entityid
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL8
, ResolutionSql = @SQL8
, LookupLoadTimingType = 2
WHERE Id = 12

update mq 
set SortOrder = sorted.rownum 
from EvaluationMethod mq
inner join ( 
select id, ROW_NUMBER() over (order by Title) rownum 
from EvaluationMethod 
) sorted on mq.Id = sorted.Id

DECLARE @SQL9 NVARCHAR(MAX) = '
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

DECLARE @CombinedData TABLE (Category NVARCHAR(50), Details NVARCHAR(MAX), CourseId int)

INSERT INTO @CombinedData (Category, Details, CourseId)
SELECT ''Textbooks'' AS Category, CONCAT(''<ol><li>'', COALESCE(dbo.ConcatWithSep_Agg(''<li>'', t.Details), ''None''), ''</ol>''), t.CourseId
FROM (
    SELECT CONCAT(ct.Author, '', '', ct.Title,
            CASE
                WHEN ct.Edition IS NOT NULL THEN CONCAT('', '', ct.Edition)
                ELSE ''''
            END,
            CASE
                WHEN ct.City IS NOT NULL THEN CONCAT('', '', ct.City)
                ELSE ''''
            END,
            CASE
                WHEN ct.Publisher IS NOT NULL THEN CONCAT('', '', ct.Publisher)
                ELSE ''''
            END,
            CASE
                WHEN ct.CalendarYear IS NOT NULL THEN CONCAT('', '', ct.CalendarYear)
                ELSE ''''
            END,case when IsTextbookFiveYear = 1 then ''<br><b>Texts and/or readings are classics or the most recent edition is over five years old.</b>''end) AS Details, ct.CourseId AS CourseId
    FROM CourseTextbook AS ct
    WHERE ct.CourseId = @EntityId
) AS t group by CourseId

UNION ALL

SELECT ''Manuals'' AS Category, CONCAT(''<ol><li>'', COALESCE(dbo.ConcatWithSep_Agg(''<li>'', m.Details), ''None''), ''</ol>''), m.CourseId
FROM (
    SELECT CONCAT(cm.Author, '', '', cm.Title,
            CASE
                WHEN cm.CalendarYear IS NOT NULL THEN CONCAT('', '', cm.CalendarYear)
                ELSE ''''
            END,
            CASE
                WHEN cm.Publisher IS NOT NULL THEN CONCAT('', '', cm.Publisher)
                ELSE ''''
            END) AS Details, cm.CourseId AS CourseId
    FROM CourseManual AS cm
    WHERE cm.CourseId = @EntityId
) AS m group by CourseId

UNION ALL

SELECT ''Periodicals'' AS Category, CONCAT(''<ol><li>'', COALESCE(dbo.ConcatWithSep_Agg(''<li>'', p.Details), ''None''), ''</ol>''), p.CourseId
FROM (
    SELECT CONCAT(cp.Title,
            CASE
                WHEN cp.Author IS NOT NULL THEN CONCAT('', '', cp.Author)
                ELSE ''''
            END,
            CASE
                WHEN cp.PublicationName IS NOT NULL THEN CONCAT('', '', cp.PublicationName)
                ELSE ''''
            END,
            CASE
                WHEN cp.PublicationYear IS NOT NULL THEN CONCAT('', '', cp.PublicationYear)
                ELSE ''''
            END,
            CASE
                WHEN cp.Volume IS NOT NULL THEN CONCAT('', '', cp.Volume)
                ELSE ''''
            END) AS Details, cp.CourseId AS CourseId
    FROM CoursePeriodical AS cp
    WHERE cp.CourseId = @EntityId
) AS p group by CourseId

UNION ALL

SELECT ''Software'' AS Category, CONCAT(''<ol><li>'', COALESCE(dbo.ConcatWithSep_Agg(''<li>'', s.Details), ''None''), ''</ol>''), s.CourseId
FROM (
    SELECT CONCAT(cs.Title,
            CASE
                WHEN cs.Edition IS NOT NULL THEN CONCAT('', '', cs.Edition)
                ELSE ''''
            END,
            CASE
                WHEN cs.Publisher IS NOT NULL THEN CONCAT('', '', cs.Publisher)
                ELSE ''''
            END) AS Details, cs.CourseId
    FROM CourseSoftware AS cs
    WHERE cs.CourseId = @EntityId
) AS s group by CourseId

UNION ALL

SELECT ''Other'' AS Category, CONCAT(''<ol><li>'', COALESCE(dbo.ConcatWithSep_Agg(''<li>'', o.Details), ''None''), ''</ol>''), o.CourseId
FROM (
    SELECT ct.TextOther AS Details, ct.CourseId
    FROM CourseTextOther AS ct
    WHERE ct.CourseId = @EntityId
) AS o group by CourseId


SELECT 0 AS Value,
CASE WHEN @IsCCN = 1 THEN CONCAT(''Part 1:'', ISNULL(gmt.TextMax22, '' No Data Entered<br>''), ''Part 2:<br>'', ''<b>'', cd.Category, ''</b>'', cd.Details)
ELSE CONCAT(''<b>'', cd.Category, ''</b>'', cd.Details)
END AS Text
FROM Course AS c
INNER JOIN @CombinedData AS cd on cd.CourseId = c.Id
LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @Entityid
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL9
, ResolutionSql = @SQL9
, LookupLoadTimingType = 2
WHERE Id =15

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 8903
, MetaPresentationTypeId = 103
, FieldTypeId = 5
, DefaultDisplayType = 'QueryText'
, MetaForeignKeyLookupSourceId = @MAX2
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSElectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = 11
	and msf.MetaAvailableFieldId = 2552
	and mt.Active = 1
	and mt.EndDate IS NULL
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 8904
, MetaPresentationTypeId = 103
, FieldTypeId = 5
, DefaultDisplayType = 'QueryText'
, MetaForeignKeyLookupSourceId = @MAX3
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSElectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = 11
	and msf.MetaAvailableFieldId = 2553
	and mt.Active = 1
	and mt.EndDate IS NULL
)

DECLARE @SQL10 NVARCHAR(MAX) = '
DECLARE @IsCCN bit = (SELECT CASE WHEN cyn.YesNo07Id = 1 THEN 1 ELSE 0 END FROM CourseYesNo cyn WHERE CourseId = @Entityid)

select 0 as [Value]
	, rs.[Text]
from (
	select @entityId as [Value]
		, dbo.ConcatWithSepOrdered_Agg(''<br />'', rto.SortOrder, rrq.RenderedRequisite) as [Text]
	from (
		select @entityId as CourseId
			, rt.Id as RequisiteTypeId 
			, rt.Title as RequisiteType
			, dbo.ConcatWithSepOrdered_Agg('' '', coalesce(rqs.SortOrder, 0), coalesce(rqs.RequisiteRow, ''None'')) as Requisites
		from RequisiteType rt
			left join (
				select cr.CourseId
					, cr.RequisiteTypeId
					, concat(
						case
							when S.id is not null
							and c.CourseNumber is not null
								then concat(
									S.SubjectCode
									, '' ''
									, c.CourseNumber
								)
							else cr.EntrySkill
						end
						, case
							when con.Title is not null
								then concat(
									'' ''
									, con.Title
									, '' ''
								)
							else ''''
						end
					) as RequisiteRow
					, row_number() over (partition by cr.CourseId order by cr.SortOrder, cr.Id) as SortOrder
				from CourseRequisite cr
					left join [Subject] S on CR.SubjectId = S.Id
					left join Course c on c.Id = cr.Requisite_CourseId
					left join Condition con on con.Id = cr.ConditionId
				where cr.courseId = @entityId
			) rqs on rt.Id = rqs.RequisiteTypeId
		-- Prerequisite, Corequisite, Anti Requisite, Advisory
		where rt.Id in (1, 2, 3, 4, 5, 6, 7)
		group by rt.Id, rt.Title
	) rqs
	cross apply (
		select concat(
			''<b>''
				, CASE WHEN rqs.RequisiteTypeId = 3 and @IsCCN = 1 THEN ''Advisories/Recommended Preparation'' WHEN rqs.RequisiteTypeId = 6 and @IsCCN = 1 THEN ''Other Limitations on Enrollment'' ELSE rqs.RequisiteType END
			, ''</b>: ''
			, rqs.Requisites
		) as RenderedRequisite
	) rrq
	cross apply (
		select 
			case
				-- Prerequisite
				when rqs.RequisiteTypeId = 1
					then 1
				-- Corequisite
				when rqs.RequisiteTypeId = 2
					then 2
				-- Advisory
				when rqs.RequisiteTypeId = 3
					then 3
				-- Anti Requisite
				when rqs.RequisiteTypeId = 4
					then 4
				-- None
				when rqs.RequisiteTypeId = 5
					then 5
				-- Limitations on Enrollment
				when rqs.RequisiteTypeId = 6
					then 6
				-- Entrance Skills
				when rqs.RequisiteTypeId = 7
					then 7
				else -1
			end as SortOrder
	) rto
) rs;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL10
, ResolutionSql = @SQL10
, LookupLoadTimingType = 2
WHERE Id = 8
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select Distinct templateId FROM @Fields
UNION
SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (
	940, 939, 937, 8, 9, 12, 15
)
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback