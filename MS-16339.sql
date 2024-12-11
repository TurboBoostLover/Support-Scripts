USE [laspositas];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16339';
DECLARE @Comments nvarchar(Max) = 
	'Update GE tab';
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
('General Education/Transfer Request', 'GenericBit', 'Bit07','calGETC'),
('General Education/Transfer Request', 'CourseGeneralEducation', 'Bit02', 'Remove'),
('General Education/Transfer Request', 'CourseGeneralEducation', 'Bit03', 'Update'),
('General Education/Transfer Request', 'CourseGeneralEducation', 'SemesterId', 'Update2'),
('General Education/Transfer Request', 'GenericBit', 'Bit18', 'Read'),
('General Education/Transfer Request', 'Course', 'RCFaculty', 'Read'),
('General Education/Transfer Request', 'Generic255Text', 'Text25501', 'Move'),
('General Education/Transfer Request', 'Generic2000Text', 'Text200001', 'Move')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int,
	Secorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt, Secorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId, mss2.SortOrder
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
UPDATE GeneralEducationElement
SET Title = 'VII. American Institutions'
, SortOrder = 11
WHERE Id = 78

INSERT INTO GeneralEducationElement
(GeneralEducationId, Title, SortOrder, StartDate, ClientId)
VALUES
(5, 'VI. Ethnic Studies', 10, GETDATE(), 1)

DECLARE @Sections INTEGERS
INSERT INTO @Sections
SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (
	1, 36
)

UPDATE mss
SET ReadOnly = 1
FROM MetaSelectedSection AS mss
INNER JOIN @Sections AS s on mss.MetaSelectedSectionId = s.Id

UPDATE msf
SET ReadOnly = 1
FROM MetaSelectedField AS msf
INNER JOIN @Sections As s on msf.MetaSelectedSectionId = s.Id

UPDATE MetaSelectedField
SET DisplayName = 'Already Approved'
, RowPosition = RowPosition - 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update' and Secorder = 1
)

DELETE FROM MetaSelectedFieldRolePermission
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Remove' and Secorder = 1
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Remove' and Secorder = 1
)

UPDATE MetaSelectedField
SET  RowPosition = RowPosition - 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2' and Secorder = 1
)

UPDATE MetaSelectedField
SET ReadOnly = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Read'
)

DECLARE @MOVE TABLE (Id int)
INSERT INTO @MOVE
SELECT DISTINCT Mss.MEtaSelectedSectionId FROM MetaSelectedSection AS mss
INNER JOIN @Fields AS f on mss.MetaSelectedSection_MetaSelectedSectionId = f.TabId
WHERE mss.RowPosition not in (1, 2)

UPDATE MetaSelectedSection
SET RowPosition = RowPosition + 2
, SortOrder = SortOrder + 2
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @MOVE
)

UPDATE MetaSelectedSection
SET RowPosition = 3
, SortOrder = 3
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'calGETC'
)

UPDATE MetaSelectedSection
SET RowPosition = 4
, SortOrder = 4
, MetaBaseSchemaId = 131
, MetaSectionTypeId = 23
WHERE MetaSelectedSectionId in (
	SELECT DISTINCT SectionId FROM @Fields WHERE Action = 'Move'
)

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'ParentTable', 'Course', SectionId FROM @Fields WHERE Action = 'Move'
UNION
SELECT 'ForeignKeyToParent', 'CourseId', SectionId FROM @Fields WHERE Action = 'Move'
UNION
SELECT 'LookupTable', 'GeneralEducationElement', SectionId FROM @Fields WHERE Action = 'Move'
UNION
SELECT 'ForeignKeyToLookup', 'GeneralEducationElementId', SectionId FROM @Fields WHERE Action = 'Move'
UNION
SELECT 'ColumnCount', '2', SectionId FROM @Fields WHERE Action = 'Move'


DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Move'
)

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

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
declare @now datetime = getdate();
SELECT
	gee.Id AS Value
   ,CONCAT(gee.Title, '<br>', gee.Header) AS Text
FROM [GeneralEducation] ge
INNER JOIN [GeneralEducationElement] gee
	ON gee.GeneralEducationId = ge.Id
WHERE @now BETWEEN gee.StartDate AND ISNULL(gee.EndDate, @now)
AND ge.Title LIKE 'calGETC'
ORDER BY gee.SortOrder
"

DECLARE @RSQL NVARCHAR(MAX) = "
select gee.Id as Value,
gee.Title as Text 
from  [GeneralEducation] ge 
inner join [GeneralEducationElement] gee on gee.GeneralEducationId = ge.Id 
where gee.id = @id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'GeneralEducationElement', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'CalGETC', 2)

INSERT INTO GeneralEducation
(Title, SortOrder, ClientId, StartDate)
VALUES
('calGETC', 10, 1, GETDATE())

DECLARE @GE int = SCOPE_IDENTITY()

INSERT INTO GeneralEducationElement
(GeneralEducationId, Title, SortOrder, StartDate, ClientId)
VALUES
(@GE, '1A - English Composition ', 0, GETDATE(), 1),
(@GE, '1B - Critical Thinking Composition', 1, GETDATE(), 1),
(@GE, '1C - Oral Communication', 2, GETDATE(), 1),
(@GE, '2 -  Mathematical Concepts and Quantitative Reasoning', 3, GETDATE(), 1),
(@GE, '3A - Arts', 4, GETDATE(), 1),
(@GE, '3B - Humanities ', 5, GETDATE(), 1),
(@GE, '4 - Social and Behavioral Sciences', 6, GETDATE(), 1),
(@GE, '5A - Physical Science', 7, GETDATE(), 1),
(@GE, '5B - Biological Science', 8, GETDATE(), 1),
(@GE, '5C - Laboratory', 9, GETDATE(), 1),
(@GE, '6 - Ethnic Studies', 10, GETDATE(), 1)


DECLARE @Fields5 TABLE (nam nvarchar(max), id int)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.DisplayName, inserted.MetaSelectedFieldId into @Fields5
SELECT
'General Education Element', -- [DisplayName]
1371, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
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
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = 'Move'
UNION
SELECT
'Comments', -- [DisplayName]
1925, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
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
FROM @Fields WHERE Action = 'Move'
UNION
SELECT
'New Request', -- [DisplayName]
4667, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Checkbox', -- [DefaultDisplayType]
5, -- [MetaPresentationTypeId]
60, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
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
FROM @Fields WHERE Action = 'Move'
UNION
SELECT
'Already approved substantial change', -- [DisplayName]
4668, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Checkbox', -- [DefaultDisplayType]
5, -- [MetaPresentationTypeId]
60, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
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
FROM @Fields WHERE Action = 'Move'
UNION
SELECT
'Already approved unsubstantial change', -- [DisplayName]
4669, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
4, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Checkbox', -- [DefaultDisplayType]
5, -- [MetaPresentationTypeId]
60, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
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
FROM @Fields WHERE Action = 'Move'
UNION
SELECT
'Effective Semester', -- [DisplayName]
53, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
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
57, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = 'Move'

INSERT INTO MetaSelectedFieldRolePermission
(RoleId, AccessRestrictionType, MetaSelectedFieldId)
SELECT 1, 2, Id FROM @Fields5 WHERE nam in (
'New Request', 'Already approved substantial change', 'Already approved unsubstantial change', 'Effective Semester'
)

DECLARE @Courses TABLE (id int)
INSERT INTO @Courses
SELECT c.Id FROM Course as C
INNER JOIN CourseDescription AS cd on cd.CourseId = c.Id
WHERE cd.HasSpecialTopics = 1
UNION
SELECT CourseId FROM GenericBit 
WHERE Bit07 = 1
or Bit17 = 1
or Bit18 = 1
or Bit19 = 1
or Bit20 = 1
UNION
SELECT Id FROM Course
WHERE ISCSUTransfer = 1
or ComparableCsuUc = 1
or RCFaculty = 1
order by c.Id

UPDATE CourseYesNo
SET YesNo50Id = 1
WHERE CourseId in (
	SELECT Id FROM @Courses
)

INSERT INTO CourseGeneralEducation
(CourseId, GeneralEducationElementId)
SELECT c.Id, 95 FROM Course as C
INNER JOIN CourseDescription AS cd on cd.CourseId = c.Id
WHERE cd.HasSpecialTopics = 1
and c.Id not in(
	SELECT CourseId FROM CourseGeneralEducation WHERE GeneralEducationElementId = 95
)

DECLARE @TABLE TABLE (OldId int, new bit, old bit)
INSERT INTO @TABLE
SELECT c.COURSES_ID, 
 CASE WHEN cge.ALREADY_APPROVED = 1
 THEN 1
 ELSE NULL
 END, 
	CASE WHEN cge.NEW_REQUEST = 1
	THEN 1
	ELSE NULL
	END FROM LasPositas_v2.dbo.COURSES AS c
INNER JOIN LasPositas_v2.dbo.COURSE_GEN_ED AS cge on cge.COURSES_ID = c.COURSES_ID
INNER JOIN LasPositas_v2.dbo.GEN_ED AS ge on cge.GEN_ED_ID = ge.GEN_ED_ID
WHERE ge.GEN_ED_TITLE = 'CSU Transfer Course'
and ((cge.ALREADY_APPROVED IS NOT NULL or cge.ALREADY_APPROVED <> 0) or (cge.NEW_REQUEST IS NOT NULL or cge.NEW_REQUEST <> 0))

UPDATE cge
SET Bit01 = t.New
, Bit03 = t.old
FROM CourseGeneralEducation AS cge
INNER JOIN Course AS c on cge.CourseId = c.Id
INNER JOIN vKeyTranslation AS vkey on vkey.NewId = c.Id and DestinationTable = 'Course'
INNER JOIN @TABLE AS t on vkey.OldId = t.OldId
WHERE cge.GeneralEducationElementId = 95
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback