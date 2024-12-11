USE [sdccd];


/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15345';
DECLARE @Comments nvarchar(Max) = 
	'Add Entry Skills tab and content from V2 to course forms';
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
('Content Review (Entry Skills)', 'CourseYesNo', 'YesNo11Id','Ping'),
('Requisites', 'CourseRequisite', 'RequisiteTypeId', 'Ping2')

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

DECLARE @SQL1 NVARCHAR(MAX) = "
select c.Id as Value, 
s.SubjectCode + ' ' + c.CourseNumber + ' - ' + c.Title + ' (' + sa.Title + ')' as Text
from Course c
inner join [Subject] s on s.Id = c.SubjectId 
inner join StatusAlias sa on sa.Id = c.StatusAliasId
where c.ClientId = @clientId
and c.Active = 1 
and exists (
	select * from 
	CourseRequisite cr 
	where cr.CourseId = @entityId
	and cr.Requisite_CourseId = c.Id
) 
UNION
select c.Id as Value, 
'<span class=""text-danger"">' + s.SubjectCode + ' ' + c.CourseNumber + ' - ' + c.Title + ' (' + sa.Title + ')' + '</span>' as Text
from Course c
inner join [Subject] s on s.Id = c.SubjectId 
inner join StatusAlias sa on sa.Id = c.StatusAliasId
where c.ClientId = @clientId
and c.Active = 1 
AND c.Id in (
	SELECT co.CourseId FROM CourseEntrySkillCourseObjective AS sko
	INNER JOIN CourseObjective AS co on sko.CourseObjectiveId = co.Id
	INNER JOIN CourseEntrySkill AS sk on sko.CourseEntrySkillId = sk.Id
	WHERE sk.CourseId = @ENtityId
)
order by Text
"

DECLARE @SQL1r NVARCHAR(MAX) = "
select s.SubjectCode + ' ' + c.CourseNumber + ' - ' + c.Title + ' (' + sa.Title + ')' as Text 
from Course c
inner join [Subject] s on s.Id = c.SubjectId 
inner join StatusAlias sa on sa.Id = c.StatusAliasId
where c.Id = @id
"

DECLARE @SQL2 NVARCHAR(MAX) = "
Select Id as Value,
Text as Text, 
CourseId AS filterValue,
CourseId AS FilterValue,
SortOrder as filterSortOrder
from CourseObjective
where Active = 1  
and ListItemTypeId <> 3
and CourseId in (
	SELECT Requisite_CourseId FROM CourseRequisite
	WHERE CourseId = @EntityId
)
UNION
Select Id as Value,
Text as Text, 
CourseId AS filterValue,
CourseId AS FilterValue,
SortOrder as filterSortOrder
from CourseObjective
where Active = 1  
and ListItemTypeId <> 3
AND CourseId in (
	SELECT co.CourseId FROM CourseEntrySkillCourseObjective AS sko
	INNER JOIN CourseObjective AS co on sko.CourseObjectiveId = co.Id
	INNER JOIN CourseEntrySkill AS sk on sko.CourseEntrySkillId = sk.Id
	WHERE sk.CourseId = @ENtityId
)
Order by CourseId,SortOrder
"

DECLARE @SQL2r NVARCHAR(MAX) = "
Select Text as Text from CourseObjective where id = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseEntrySkillCourseObjective', 'Id', 'Title', @SQL1, @SQL1r, 'Order By SortOrder', 'Parent Look up for Group Checklist', 2),
(@MAX2, 'CourseEntrySkillCourseObjective', 'Id', 'Title', @SQL2, @SQL2r, 'Order By SortOrder', 'Child Look up for Group Checklist', 3)

UPDATE MetaSelectedSection
SET SectionName = 'Content Review'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = 'Ping'
)

UPDATE MetaSelectedSection
SET RowPosition = RowPosition + 1
, SortOrder = SortOrder + 1
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN @Fields AS f on mt.MetaTemplateTypeId = f.mtt
	where mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
	AND mss.RowPosition > 31
	AND mss.SortOrder > 31
)

DECLARE @TABS TABLE (ID int, mt int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @TABS
SELECT DISTINCT
1, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Entry Skills', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
32, -- [RowPosition]
32, -- [SortOrder]
1, -- [SectionDisplayId]
30, -- [MetaSectionTypeId]
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
FROM @Fields WHERE Action = 'Ping'

DECLARE @Sections TABLE (id int, mt int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @Sections
SELECT DISTINCT
1, -- [ClientId]
Id, -- [MetaSelectedSection_MetaSelectedSectionId]
'Entry Skills', -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
31, -- [MetaSectionTypeId]
mt, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
94, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @TABS

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Opt Heading', -- [DisplayName]
3875, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
0, -- [IsRequired]
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
FROM @Sections 
UNION
SELECT
'Entry Skill', -- [DisplayName]
10560, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
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
FROM @Sections 

DECLARE @Sub TABLE (Id int, mt int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @Sub
SELECT DISTINCT
1, -- [ClientId]
Id, -- [MetaSelectedSection_MetaSelectedSectionId]
'Course Objectives', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
4, -- [RowPosition]
4, -- [SortOrder]
1, -- [SectionDisplayId]
32, -- [MetaSectionTypeId]
mt, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
1304, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Sections

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT 
'Requisite Course', -- [DisplayName]
3878, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
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
FROM @Sub
UNION
SELECT
'Requisite Course Outcome', -- [DisplayName]
3879, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
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
@MAX2, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Sub

INSERT INTO MetaSelectedSectionAttribute
(Name,[Value],MetaSelectedSectionId)
SELECT 'lookuptablename','CourseEntrySkillCourseObjective', Id FROM @Sub
UNION
SELECT 'lookupcolumnname','CourseObjectiveId', Id FROM @Sub
UNION
SELECT 'columns','1', Id FROM @Sub
UNION
SELECT 'grouptablename', 'CourseEntrySkillCourseObjective', Id FROM @Sub
UNION
SELECT 'groupcolumnname', 'Requisite_CourseId', Id FROM @Sub

INSERT INTO ListItemType
(Title, ListItemTypeOrdinal, ListItemTableName, ListItemTitleColumn, SortOrder, StartDate, ClientId)
VALUES
('Entry Skill', 1, 'CourseEntrySkill', 'MaxText01', 0, GETDATE(), 1)

DECLARE @LIST INT = SCOPE_IDENTITY()

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'triggersectionrefresh', s.Id, f.SectionId
FROM @Sections AS s
INNER JOIN MetaTemplate AS mt on s.mt = mt.MetaTemplateId
INNER JOIN @Fields AS f on mt.MetaTemplateTypeId = f.mtt
WHERE f.Action = 'Ping2'

DECLARE @TABLE TABLE (oldId int, newId int);

MERGE INTO CourseEntrySkill t
USING (
    SELECT vkey.NewId, cs.Course_SKILL, cs.OPTIONAL_TEXT, cs.ORDER_NUM, cs.Course_SKILLS_ID
    FROM sdccd_2_V2.dbo.COURSE_SKILLS AS cs
    INNER JOIN vKeyTranslation AS vkey ON cs.COURSES_ID = vkey.OldId
    AND vkey.DestinationTable = 'Course'
) s ON 1 <> 0
WHEN NOT MATCHED BY TARGET THEN
    INSERT (CourseId, MaxText01, OptionalText, SortOrder, ListItemTypeId)
    VALUES (s.NEWId, s.Course_SKILL, s.OPTIONAL_TEXT, s.ORDER_NUM, @LIST)
    OUTPUT s.Course_SKILLS_ID, inserted.Id INTO @TABLE;

 ;MERGE INTO CourseEntrySkillCourseObjective t
using (
SELECT t.NewId, co3.Id FROM sdccd_2_V2.dbo.COURSE_SKILL_OBJECTIVES AS co
INNER JOIN sdccd_2_v2.dbo.Course_SKILLS AS cs on co.Course_SKILLS_ID = cs.COURSE_SKILLS_ID
INNER JOIN @TABLE AS t on cs.Course_SKILLS_ID = t.OldId
INNER JOIN sdccd_2_V2.dbo.COURSE_OBJECTIVES AS co2 on co.Course_OBJECTIVES_ID = co2.Course_OBJECTIVES_ID
INNER JOIN vKeyTranslation AS vkey on co2.COURSES_ID = vkey.OldId
INNER JOIN CourseObjective AS co3 on co2.COURSE_OBJECTIVE_TEXT = co3.Text and co3.CourseId = vkey.NewId
) s on 1 = 0
when not matched by target then
insert (CourseEntrySkillId, CourseObjectiveId)
 VALUES
 (s.NewId, s.Id);
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback