USE [riohondo];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16360';
DECLARE @Comments nvarchar(Max) = 
	'Update Non-credit course proposal';
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
Declare @clientId int =6, -- SELECT Id, Title FROM Client 
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
		AND mtt.MetaTemplateTypeId in (418, 419, 422, 432, 433)		--comment back in if just doing some of the mtt's

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
('Course Cover Sheet', 'CourseProposal', 'MaxEnrollment','Delete'),
('Course Attributes', 'CourseDescription', 'MinWorkHour','Delete'),
('Course Attributes', 'CourseDescription', 'MinOtherHour','Delete'),
('Course Attributes', 'CourseDescription', 'MinFieldHour','Delete'),
('Course Attributes', 'CourseDescription', 'InClassHour','Delete'),
('Course Attributes', 'CourseDescription', 'LoadValue','Delete'),
('Course Attributes', 'CourseYesNo', 'YesNo02Id', 'Delete'),
('Course Attributes', 'Course', 'AchievementStandards', 'Delete2'),
('Course Attributes', 'Generic500Text', 'Text50001', 'Delete'),
('Course Attributes', 'CourseProposal', 'MaxTaken', 'Delete'),
('Course Attributes', 'GenericBit', 'Bit18', 'Update1'),
('Course Attributes', 'GenericBit', 'Bit19', 'Update2'),
('Course Attributes', 'GenericBit', 'Bit20', 'Update3'),
('Course Attributes', 'GenericBit', 'Bit21', 'Update4'),
('Course Attributes', 'GenericBit', 'Bit22', 'Update5'),
('Course Attributes', 'CourseProposal', 'IsAppropriate', 'Update6'),
('Course Attributes', 'GenericBit', 'Bit24', 'Update7')

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
DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE ACtion in ('Delete', 'Delete2')
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE ACtion in ('Delete', 'Delete2')
)

DELETE FROM MetaSelectedSection 
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Delete2'
)

UPDATE MetaSelectedSection
SET SectionName = 'Noncredit Category'
, SectionDescription = '(Select the appropriate noncredit category for this course)'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields wHERE Action = 'Update1'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2647
, DisplayName = 'ESL'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update1'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2648
, DisplayName = 'Citizenship for Immigrants'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2649
, DisplayName = 'Elementary and Secondary Basic Skills'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update3'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2650
, DisplayName = 'Health and Safety'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update4'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2651
, DisplayName = 'Courses for Persons with Substantial Disabilities'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update5'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2652
, DisplayName = 'Parenting'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update6'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2653
, DisplayName = 'Home Economics'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update7'
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Older Adults', -- [DisplayName]
2637, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
7, -- [RowPosition]
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
FROM @Fields WHERE Action = 'Update1'
UNION
SELECT
'Short-term Vocational', -- [DisplayName]
2644, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
8, -- [RowPosition]
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
FROM @Fields WHERE Action = 'Update1'
UNION
SELECT
'Workforce Preparation', -- [DisplayName]
2646, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
9, -- [RowPosition]
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
FROM @Fields WHERE Action = 'Update1'
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback