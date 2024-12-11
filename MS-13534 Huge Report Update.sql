USE [reedley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13534';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Distance Report';
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
    --INNER JOIN ProposalType pt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    --AND pt.Active = 1
    --AND pt.ProcessActionTypeId = 3 -- SELECT * FROM ProcessActionType (1 = New, 2 = Modify, 6 = Deactivate)
    AND mtt.IsPresentationView = 1
    AND mtt.ClientId = @clientId
	AND mtt.ClientEntityTypeId = 1
	AND mtt.MetaTemplateTypeId <>3


declare @FieldCriteria table (
	--TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (/*TabName,*/ TableName, ColumnName,Action)
values
(/*NULL,*/ 'Course', 'UserId','Remove'),
(/*NULL,*/ 'CourseYesNo', 'YesNo01Id','Remove2'),
(/*NULL,*/ 'Course', 'ConsultText','Edit'),
(/*NULL,*/ 'CourseDEAddendum', 'YesNoId_02','Update'),
(/*NULL,*/ 'CourseDEAddendumQuality', 'DistanceEducationQualityId','Remove3'),
(/*NULL,*/ 'CourseDEAddendum', 'DeliveryMethodId','Title'),
(/*NULL,*/ 'CourseDEAddendum', 'SemesterId','Title2'),
(/*NULL,*/ 'CourseDEAddendum', 'MaxText11','Title3'),
(/*NULL,*/ 'CourseDEAddendum', 'MaxText01','Remove4'),
(/*NULL,*/ 'CourseDEAddendum', 'MaxText10','Title4'),
(/*NULL,*/ 'CourseDEAddendumContactType', 'DEContactTypeId','Title5'),
(/*NULL,*/ 'CourseDEAddendum', 'YesNoId_01','Title6'),
(/*NULL,*/ 'CourseDEAddendum', 'YesNoId_04','Title7'),
(/*NULL,*/ 'CourseDEAddendum', 'YesNoId_03','Title8')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,	
	sortorder int,					
	mfk int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder,mfk)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition,msf.MetaForeignKeyLookupSourceId
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName /*and mss.SectionName = rfc.TabName*/)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/

DECLARE @Rms int = (SELECT TabId FROM @Fields WHERE Action = 'Remove')
DECLARE @Rms2 int = (SELECT SectionId FROM @Fields WHERE Action = 'Remove2')
DECLARE @Rms3 int = (SELECT FieldId FROM @Fields WHERE Action = 'Edit')
DECLARE @Up int = (SELECT FieldId FROM @Fields WHERE Action = 'Update')
DECLARE @Ups int = (SELECT SectionId FROM @Fields WHERE Action = 'Update')
DECLARE @Add int = (SELECT SectionId FROM @Fields WHERE Action = 'Edit')
DECLARE @Ttle int = (SELECT TabId FROM @Fields WHERE Action = 'Update')
DECLARE @Rms4 int = (SELECT SectionId FROM @Fields WHERE Action = 'Remove3' AND mfk = 1592)-------------------------------------------------------------------------
DECLARE @Up2 int = (SELECT FieldId FROM @Fields WHERE Action = 'Title')
DECLARE @Up3 int = (SELECT FieldId FROM @Fields WHERE Action = 'Title2')
DECLARE @Up16 int = (SELECT SectionId FROM @Fields WHERE Action = 'Title3')
DECLARE @Up4 int = (SELECT FieldId FROM @Fields WHERE Action = 'Title3')
DECLARE @Up5 int = (SELECT SectionId FROM @Fields WHERE Action = 'Remove4')
DECLARE @Up6 int = (SELECT SectionId FROM @Fields WHERE Action = 'Remove3' AND mfk = 441)-------------------------------------------------------------------------
DECLARE @Up7 int = (SELECT FieldId FROM @Fields WHERE Action = 'Remove3' AND mfk = 441)-------------------------------------------------------------------------
DECLARE @Up8 int = (SELECT SectionId FROM @Fields WHERE Action = 'Title4')
DECLARE @Up9 int = (SELECT FieldId FROM @Fields WHERE Action = 'Title4')
DECLARE @Up10 int = (SELECT FieldId FROM @Fields WHERE Action = 'Title5')
DECLARE @Up11 int = (SELECT SectionId FROM @Fields WHERE Action = 'Title5')
DECLARE @Up12 int = (SELECT SectionId FROM @Fields WHERE Action = 'Title6')
DECLARE @Up13 int = (SELECT FieldId FROM @Fields WHERE Action = 'Title6')
DECLARE @Up14 int = (SELECT SectionId FROM @Fields WHERE Action = 'Title7')
DECLARE @Up15 int = (SELECT SectionId FROM @Fields WHERE Action = 'Title8')

DECLARE @json nvarchar(MAX) = 
'--.section-name{font-size: 14px}
.report-title{font-size: 32px; max-width: 50%}
.bottom-margin-small::before{display: none !important} 
.report-header{margin-bottom: 0; padding-bottom: 0 !important}
.report-entity-title{padding-top: 1vh}'

UPDATE MetaReport
SET ReportAttributes = json_modify(ReportAttributes,'$.cssOverride',(select @json as 'cssOverride'))
, Title = 'Distance Education Addendum'
WHERE Id = 385

UPDATE MetaSelectedSection
SET SectionName = '7. Selected course objectives will allow students to meet course learning outcomes through distance education:'
WHERE MetaSelectedSectionId = @Up15

UPDATE MetaSelectedSection
SET SectionName = '8. Course methods selected above will be accessible according to the Americans with Disabilities Act (42 U.S.C. §12100 et seq.) and 
section 508 of the Rehabilitation Act of 1973, as amended, (29 U.S.C§ 749D) (Title 5 §55206).'
WHERE MetaSelectedSectionId = @Up14

UPDATE MetaSelectedSection
SET SectionName = '10. Additional resources or clerical support needed or anticipated:'
WHERE MetaSelectedSectionId = @Up12

UPDATE MetaSelectedSection
SET SectionName = '9. Regular and Effective Contact Methods:',
SectionDescription = 'Methods below that ensure regular and effective contact will take place among students and among students and faculty (Title 5 §55204)<br><br>Instructor to Student – Communication',
DisplaySectionDescription = 1
WHERE MetaSelectedSectionId = @Up11

UPDATE MetaSelectedSection
SET SectionName = NULL
WHERE MetaSelectedSectionId in( @Up8, @Ttle)

UPDATE MetaSelectedSection
Set SectionName = '6. Methods of instruction, applies to both lecture and lab:'
WHERE MetaSelectedSectionId = @Up6

UPDATE MetaSelectedSection
Set SectionName = '1. This addendum is for:'
WHERE MetaSelectedSectionId = @Ups

UPDATE MetaSelectedField
SET DisplayName = NULL
WHERE MetaSelectedFieldId in (@Up13, @Up7)

UPDATE MetaSelectedField
SET DisplayName = 'Instructor to Student - Communication'
WHERE MetaSelectedFieldId = @Up10

UPDATE MetaSelectedField
SET DisplayName = '11. Contingency Plans if access to the delivery system is interrupted:'
WHERE MetaSelectedFieldId = @Up9

UPDATE MetaSelectedField
SET DisplayName = '1. This addendum is for:',
LabelVisible = 1
WHERE MetaSelectedFieldId = @Up

UPDATE MetaSelectedField
SET DisplayName = '2. Delivery Method:'
WHERE MetaSelectedFieldId = @Up2

UPDATE MetaSelectedField
SET DisplayName = '3. Start Semester:'
WHERE MetaSelectedFieldId = @Up3


insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@Ups, -- [MetaSelectedSection_MetaSelectedSectionId]
'4. Reasons for DE:', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
3, -- [MetaSectionTypeId]
12, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
5168, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)
DECLARE @TEMPID int = SCOPE_IDENTITY()


insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@Ups, -- [MetaSelectedSection_MetaSelectedSectionId]
'', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
11, -- [MetaSectionTypeId]
12, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
5168, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)
DECLARE @TEMPID2 int = SCOPE_IDENTITY()


insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'Originator', -- [DisplayName]
1392, -- [MetaAvailableFieldId]
@Add, -- [MetaSelectedSectionId]
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
)
,
(
'4. Reasons for DE:', -- [DisplayName]
7561, -- [MetaAvailableFieldId]
@TEMPID, -- [MetaSelectedSectionId]--------------------------------------------------------------------------------------------------------------------------------------------------
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
1592, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)


UPDATE MetaSelectedField
SET DisplayName = '5. Adjustments to ways course is delivered or presented:',
MetaSelectedSectionId = @TEMPID2,
RowPosition = 0 
WHERE MetaSelectedFieldId = @Up4


INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
VALUES
('ParentTable', 'CourseDEAddendumQuality', @TEMPID),
('ForeignKeyToParent', 'DistanceEducationQualityId', @TEMPID),
('LookupTable', 'DistanceEducationQuality', @TEMPID),
('ForeignKeyToLookup', 'DistanceEducationQualityId', @TEMPID)


DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId = @Rms3


EXEC spBuilderSectionDelete @clientId, @Rms
EXEC spBuilderSectionDelete @clientId, @Rms2
EXEC spBuilderSectionDelete @clientId, @Rms4
EXEC spBuilderSectionDelete @clientId, @Up5

/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback