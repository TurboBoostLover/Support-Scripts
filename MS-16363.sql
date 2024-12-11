USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16363';
DECLARE @Comments nvarchar(Max) = 
	'Huge overhaul to the Comprehensive program review';
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
Declare @clientId int =4, -- SELECT Id, Title FROM Client 
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
		AND mtt.MetaTemplateTypeId in (43)		--comment back in if just doing some of the mtt's

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
('Program Strategic Goals', 'ModuleGoal', 'EvaluationPlan','delete1'),
('Program Strategic Goals', 'ModuleGoal', 'GoalStatusComments','delete2'),
('Enrollment Trends', 'ModuleFormQuestion', 'FormQuestionId', 'move'),
('Course Completion', 'ModuleStudentDemographic', 'Parent_StudentDemographicId', 'update1')

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
DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId IN (
    SELECT FieldId FROM @Fields WHERE Action IN ('delete1', 'delete2')
);

-- Update FormQuestion
UPDATE FormQuestion
SET FormQuestion = CASE 
        WHEN Id = 24 THEN 'Using the Course Completion and Retention Rate Dashboard – Student Services, what are the course completion rates over the past 3 years for students in your program?'
        WHEN Id = 25 THEN 'If equity gaps exist, what is your plan? Describe activities your program is doing, or plans to do, to address the differences. How will your program evaluate the effectiveness of these activities?'
				WHEN Id = 30 THEN 'What new curriculum does your program plan or is in the process of developing?  Include evidence of need in the box below or in the Attachments tab. This may be based off of industry advisory committee approvals, technological advancements, or tangible indicators of need. Please include an estimated timeline for curriculum development and implementation.'
        WHEN Id = 31 THEN 'During Year 3 of the Annual Program Review, your department participated in Curriculum Content Review (CCR). Detail your program''s progress in following this plan over the past year and your plan to keep curriculum in compliance over the next three years.'
        WHEN Id = 56 THEN 'Discuss how faculty and classified professionals have engaged in institutional efforts (i.e. college events, etc).'
        WHEN Id = 63 THEN 'What has the program done to improve course completion?'
        WHEN Id = 77 THEN 'What new curriculum does your program plan or is in the process of developing? Include evidence of need in the box below or attached. This may be based off of industry advising committee approvals, technological advancements, or tangible indicators of need. Please include estimated timeline for curriculum development and implementation.'
        WHEN Id = 80 THEN 'Review the employment outlook form the Labor Market Information (LMI). How is your discipline or program responding to changes in labor market demand?'
        WHEN Id = 81 THEN 'When did your advisory board meet last? Write down board members and their company/organization.'
        ELSE FormQuestion
    END,
    EndDate = CASE WHEN Id IN (22, 27, 28, 29, 54, 55, 60, 62, 82, 86, 88, 89) THEN GETDATE() ELSE EndDate END,
    SortOrder = CASE 
        WHEN Id IN (23, 24, 61, 83, 84, 85) THEN SortOrder - 1
        WHEN Id IN (25) THEN SortOrder + 1
        WHEN Id IN (63, 64, 65, 87) THEN SortOrder - 2
        ELSE SortOrder
    END
WHERE Id IN (22, 23, 24, 25, 27, 28, 29, 30, 31, 54, 55, 56, 60, 61, 62, 63, 64, 65, 77, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89);

-- Delete from ModuleFormQuestion
DELETE FROM ModuleFormQuestion
WHERE FormQuestionId IN (22, 27, 28, 29, 54, 55, 60, 62, 82, 86, 88, 89);

-- Insert into FormQuestion
INSERT INTO FormQuestion (FormQuestion, FormQuestionGroupId, SortOrder, ClientId, StartDate)
VALUES
    ('How do they compare to the college average?', 4, 4, 4, GETDATE()),
    ('Do equity gaps exist for specific demographic groups? Choose 3 groups that are of interest. Note: an equity gap exists if the course completion rate falls 3% points or more below average.', 4, 5, 4, GETDATE()),
    ('Describe any notable changes and why you think it may be occurring. If your trends are increasing, what effective or innovative strategies is the department performing? If trends are decreasing, are there effective or innovative strategies that may be designed?', 5, 2, 4, GETDATE()),
    ('Describe any notable increases or degrees in student award attainment. If your trends are increasing, what effective or innovative strategies is the department performing? If trends are decreasing, are there effective or innovative strategies that may be designed?', 12, 2, 4, GETDATE());

-- Update MetaSelectedSection
UPDATE MetaSelectedSection
SET SortOrder = SortOrder + 1, RowPosition = RowPosition + 1
WHERE MetaSelectedSectionId IN (
    SELECT SectionId FROM @Fields WHERE Action = 'move'
);

DECLARE @TABS TABLE (Id int, nam nvarchar(max))
INSERT INTO @TABS
SELECT mss.MetaSelectedSectionId, mss.SectionName FROM MetaSelectedSection AS mss
INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL

UPDATE mss
SET RowPosition = 
    CASE t.nam
        WHEN 'Mission Statement/Strategic Goals' THEN 0
        WHEN 'Co-Contributor' THEN 1
        WHEN 'Career Education' THEN 2
        WHEN 'Students Served' THEN 3
        WHEN 'Enrollment Trends' THEN 4
        WHEN 'Course Completion' THEN 5
        WHEN 'Degrees & Certificates' THEN 6
        WHEN 'Curriculum' THEN 7
        WHEN 'Assessment' THEN 8
        WHEN 'Engagement' THEN 9
        WHEN 'Resource Request' THEN 10
        WHEN 'Validation' THEN 11
        WHEN 'Attachments' THEN 12
        ELSE RowPosition -- Keep the current value if nam doesn't match any condition
    END,
    SortOrder = 
    CASE t.nam
        WHEN 'Mission Statement/Strategic Goals' THEN 0
        WHEN 'Co-Contributor' THEN 1
        WHEN 'Career Education' THEN 2
        WHEN 'Students Served' THEN 3
        WHEN 'Enrollment Trends' THEN 4
        WHEN 'Course Completion' THEN 5
        WHEN 'Degrees & Certificates' THEN 6
        WHEN 'Curriculum' THEN 7
        WHEN 'Assessment' THEN 8
        WHEN 'Engagement' THEN 9
        WHEN 'Resource Request' THEN 10
        WHEN 'Validation' THEN 11
        WHEN 'Attachments' THEN 12
        ELSE SortOrder -- Keep the current value if nam doesn't match any condition
    END
FROM MetaSelectedSection AS mss
INNER JOIN @TABS AS t ON mss.MetaSelectedSectionId = t.Id
WHERE t.nam IN (
    'Mission Statement/Strategic Goals', 
    'Co-Contributor', 
    'Career Education', 
    'Students Served', 
    'Enrollment Trends', 
    'Course Completion', 
    'Degrees & Certificates', 
    'Curriculum', 
    'Assessment', 
    'Engagement', 
    'Resource Request', 
    'Validation', 
    'Attachments'
);

DECLARE @OL TABLE (id int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId INTO @OL
SELECT
@clientId, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'1. Using the Enrollment Trends & Productivity dashboard, provide the following data for you department for the last 3 years:', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
500, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
2381, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Fields WHERE Action = 'move'

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
DECLARE @now datetime = GETDATE()

SELECT Id AS Value,  CatalogYear AS Text FROM Semester
WHERE TermEndDate < @now
AND TermStartDate > DATEADD(YEAR, -3, @now)
and Title like '%fall%'
UNION
SELECT s.Id AS Value, s.CatalogYear AS Text FROM Semester AS s
INNER JOIN ModuleCourseCompletion AS mcc on mcc.SemesterId =s.Id
WHERE mcc.ModuleId = @EntityId
"

DECLARE @RSQL NVARCHAR(MAX) = "
SELECT CatalogYear AS Text from Semester WHERE Id = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Semester', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Look up dates for Program Review', 2)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Semester', -- [DisplayName]
6196, -- [MetaAvailableFieldId]
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
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @OL
UNION
SELECT
'Enrollment numbers', -- [DisplayName]
6214, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
0, -- [IsRequired]
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
FROM @OL
UNION
SELECT
'FTES', -- [DisplayName]
6215, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
0, -- [IsRequired]
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
FROM @OL
UNION
SELECT
'Productivity numbers', -- [DisplayName]
6216, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
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
FROM @OL

INSERT INTO ListItemType
(Title, ListItemTypeOrdinal, ListItemTableName, ListItemTitleColumn, SortOrder, StartDate, ClientId)
VALUES
('Year', 1, 'ModuleCourseCompletion', 'SemesterId', 1, GETDATE(), @clientId)

INSERT INTO MetaSelectedSectionAttribute 
(Name, Value, MetaSelectedSectionId)
SELECT 'TitleTable', 'ModuleCourseCompletion', Id FROM @OL
UNION
SELECT 'TitleColumn', 'SemesterId', Id FROM @OL
UNION
SELECT 'SortOrderTable', 'ModuleCourseCompletion', Id FROM @OL
UNION
SELECT 'SortOrderColumn', 'SortOrder', Id FROM @OL
UNION
SELECT 'ShowDetails', 'True', Id FROM @OL
UNION
SELECT 'EmptyListText', 'There is no data entered here', Id FROM @OL

INSERT INTO MetaDisplaySubscriber 
(SubscriberName, MetaSelectedSectionId, MetaDisplayRuleId)
SELECT 'Hide Enrollment Trends', Id, 4368 FROM @OL
UNION
SELECT 'Hide Enrollment Trends', Id, 4369 FROM @OL
UNION
SELECT 'Hide Enrollment Trends', Id, 4381 FROM @OL

UPDATE MetaSelectedSection
SET SectionName = '1. Use the dashboard filters to disaggregate program data from three groups below that may be of interest to the department. Describe any differences or trends you observe in the 3 group''s completion rates for the last three years.'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update1'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback