USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13807';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Cover Tab';
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
Declare @clientId int =3, -- SELECT Id, Title FROM Client 
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
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
--------------------------------------------------------------------------------------
DECLARE @UserId int = (
SELECT Id FROM [User]
WHERE FirstName = 'Curriqunet'							--get user id
AND Username = 'SupportAdmin@CurriQunet.com'
)

DECLARE @temp1 TABLE (TemplateId int, typeid int)
INSERT INTO @temp1
SELECT mt.MetaTemplateId, mtt.MetaTemplateTypeId FROM MetaTemplate AS mt
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mt.MetaTemplateId in (SELECT * FROM @templateId)

	WHILE exists(select top 1 1 from @temp1)
	BEGIN	
		DECLARE @Template int = (SELECT TOP 1 TemplateId FROM @temp1)
		DECLARE @TemplateType int = (SELECT TOP 1 typeid FROM @temp1)
		EXEC spBuilderTemplateCopy @clientId = 1, @userId = @UserId, @templateId = @Template, @metaTemplateTypeId = @TemplateType
		DECLARE @Templateid2 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new template
		EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Templateid2 , @metaTemplateTypeId = @TemplateType -- activates the new template

		DELETE @temp1
		WHERE TemplateId = @Template
	END
----------------------------------------------------------------------------------------------------------
declare @templateId3 integers

INSERT INTO @templateId3
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
----------------------------------------------------------------------------------------------------------
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
('Cover', 'Course', 'ConsultText','Update'),
('Cover', 'CourseProposal', 'IsMultiple', 'Update2'),
('Cover', 'Course', 'Description', 'Update3')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	Id int identity
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId3)

/********************** Changes go HERE **************************************************/
DECLARE @Adequate1 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update' AND Id =1)
DECLARE @Adequate2 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update' AND Id =2)
DECLARE @Adequate3 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update' AND Id =3)
DECLARE @Adequate4 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update' AND Id =4)
DECLARE @Stand1 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update2' AND Id =5)
DECLARE @Stand2 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update2' AND Id =6)
DECLARE @Stand3 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update2' AND Id =7)
DECLARE @Stand4 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update2' AND Id =8)
DECLARE @Desc1 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update3' AND Id =9)
DECLARE @Desc2 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update3' AND Id =10)
DECLARE @Desc3 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update3' AND Id =11)
DECLARE @Desc4 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update3' AND Id =12)
----------------------------------------------------------------------------------------
DECLARE @Propinfo1 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update' AND Id =1)
DECLARE @Propinfo2 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update' AND Id =2)
DECLARE @Propinfo3 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update' AND Id =3)
DECLARE @Propinfo4 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update' AND Id =4)
DECLARE @NoName1 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update2' AND Id=5)
DECLARE @NoName2 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update2' AND Id=6)
DECLARE @NoName3 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update2' AND Id=7)
DECLARE @NoName4 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update2' AND Id=8)
------------------------------------------------------------------------------------------
DECLARE @Tab1 int = (SELECT TabId FROM @Fields WHERE Action = 'Update' AND Id=1)
DECLARE @Tab2 int = (SELECT TabId FROM @Fields WHERE Action = 'Update' AND Id=2)
DECLARE @Tab3 int = (SELECT TabId FROM @Fields WHERE Action = 'Update' AND Id=3)
DECLARE @Tab4 int = (SELECT TabId FROM @Fields WHERE Action = 'Update' AND Id=4)
----------------------------------------------------------------------------------------
DECLARE @Template1 int = (SELECT TemplateId FROM @Fields WHERE Action = 'Update' AND Id=1)
DECLARE @Template2 int = (SELECT TemplateId FROM @Fields WHERE Action = 'Update' AND Id=2)
DECLARE @Template3 int = (SELECT TemplateId FROM @Fields WHERE Action = 'Update' AND Id=3)
DECLARE @Template4 int = (SELECT TemplateId FROM @Fields WHERE Action = 'Update' AND Id=4)
-----------------------------------------------------------------------------------------
DECLARE @insert TABLE (mssId int, msfId int, Id int IDENTITY)
-----------------------------------------------------------------------------------------
	declare @bottomsec TABLE (secid int, tempid int, id int identity)  
	INSERT INTO @bottomsec
		SELECT mss.MetaSelectedSectionId, mt.MetaTemplateId
		FROM MetaSelectedSection as mss
		INNER JOIN MetaTemplate as mt on mss.MetaTemplateId = mt.MetaTemplateId
		WHERE mss.MetaSelectedSection_MetaSelectedSectionId in (
			SELECT TabId 
			FROM @Fields 
			WHERE Action = 'Update'
			)
		AND mss.RowPosition = (
			SELECT DISTINCT SortOrder
			FROM @Fields 
			WHERE Action = 'Update'
			)
	
DECLARE @btm1 int = (SELECT secid FROM @bottomsec WHERE Id = 1)		--Bottom Section to hide
DECLARE @btm2 int = (SELECT secid FROM @bottomsec WHERE Id = 2)		--Bottom Section to hide
DECLARE @btm3 int = (SELECT secid FROM @bottomsec WHERE Id = 3)		--Bottom Section to hide
DECLARE @btm4 int = (SELECT secid FROM @bottomsec WHERE Id = 4)		--Bottom Section to hide

DELETE FROM MetaSelectedField
WHERE MetaSelectedSectionId in (SELECT secid FROM @bottomsec)

UPDATE MetaSelectedField
SET MetaSelectedSectionId = @btm1
, DisplayName = 'Justification?'
, RowPosition = 0
WHERE MetaSelectedFieldId = @Adequate1

UPDATE MetaSelectedField
SET MetaSelectedSectionId = @btm2
, DisplayName = 'Justification?'
, RowPosition = 0
WHERE MetaSelectedFieldId = @Adequate2

UPDATE MetaSelectedField
SET MetaSelectedSectionId = @btm3
, DisplayName = 'Justification?'
, RowPosition = 0
WHERE MetaSelectedFieldId = @Adequate3

UPDATE MetaSelectedField
SET MetaSelectedSectionId = @btm4
, DisplayName = 'Justification?'
, RowPosition =0
WHERE MetaSelectedFieldId = @Adequate4

UPDATE MetaSelectedSection
SET RowPosition = RowPosition +1
, SortOrder = SortOrder + 1
WHERE MetaSelectedSectionId in (@btm1, @btm2, @btm3, @btm4, @Propinfo1, @Propinfo2, @Propinfo3, @Propinfo4)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 3
WHERE MetaSelectedSectionId in (@Propinfo1, @Propinfo2, @Propinfo3, @Propinfo4)

UPDATE MetaSelectedField
Set RowPosition = 2
, MetaSelectedSectionId = @Propinfo1
WHERE MetaSelectedFieldId = @Desc1

UPDATE MetaSelectedField
Set RowPosition = 2
, MetaSelectedSectionId = @Propinfo2
WHERE MetaSelectedFieldId = @Desc2

UPDATE MetaSelectedField
Set RowPosition = 2
, MetaSelectedSectionId = @Propinfo3
WHERE MetaSelectedFieldId = @Desc3

UPDATE MetaSelectedField
Set RowPosition = 2
, MetaSelectedSectionId = @Propinfo4
WHERE MetaSelectedFieldId = @Desc4

UPDATE MetaSelectedField
Set RowPosition = 0
, MetaSelectedSectionId = @Propinfo1
WHERE MetaSelectedFieldId = @Stand1

UPDATE MetaSelectedField
Set RowPosition = 0
, MetaSelectedSectionId = @Propinfo2
WHERE MetaSelectedFieldId = @Stand2

UPDATE MetaSelectedField
Set RowPosition = 0
, MetaSelectedSectionId = @Propinfo3
WHERE MetaSelectedFieldId = @Stand3

UPDATE MetaSelectedField
Set RowPosition = 0
, MetaSelectedSectionId = @Propinfo4
WHERE MetaSelectedFieldId = @Stand4

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
OUTPUT inserted.MetaSelectedSectionId INTO @insert (mssId)
values
(
3, -- [ClientId]
@Tab1, -- [MetaSelectedSection_MetaSelectedSectionId]-----------------------
NULL, -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
3, -- [RowPosition]
3, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Template1, -- [MetaTemplateId]----------------------------------------------
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
,
(
3, -- [ClientId]
@Tab2, -- [MetaSelectedSection_MetaSelectedSectionId]-----------------------
NULL, -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
3, -- [RowPosition]
3, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Template2, -- [MetaTemplateId]----------------------------------------------
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
,
(
3, -- [ClientId]
@Tab3, -- [MetaSelectedSection_MetaSelectedSectionId]-----------------------
NULL, -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
3, -- [RowPosition]
3, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Template3, -- [MetaTemplateId]----------------------------------------------
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
,(
3, -- [ClientId]
@Tab4, -- [MetaSelectedSection_MetaSelectedSectionId]-----------------------
NULL, -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
3, -- [RowPosition]
3, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Template4, -- [MetaTemplateId]----------------------------------------------
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

DECLARE @NEWSec1 int = (SELECT mssId FROM @insert WHERE Id = 1)
DECLARE @NEWSec2 int = (SELECT mssId FROM @insert WHERE Id = 2)
DECLARE @NEWSec3 int = (SELECT mssId FROM @insert WHERE Id = 3)
DECLARE @NEWSec4 int = (SELECT mssId FROM @insert WHERE Id = 4)


insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
OUTPUT inserted.MetaSelectedFieldId into @insert (msfId)
values
(
'This course is cross-listed', -- [DisplayName]
892, -- [MetaAvailableFieldId]
@Propinfo1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
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
1, -- [LabelStyleId]
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
)
,
(
'This course is cross-listed', -- [DisplayName]
892, -- [MetaAvailableFieldId]
@Propinfo2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
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
1, -- [LabelStyleId]
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
)
,
(
'This course is cross-listed', -- [DisplayName]
892, -- [MetaAvailableFieldId]
@Propinfo3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
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
1, -- [LabelStyleId]
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
)
,
(
'This course is cross-listed', -- [DisplayName]
892, -- [MetaAvailableFieldId]
@Propinfo4, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
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
1, -- [LabelStyleId]
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
)
,
(
'Adequate Resources – Does the department have the adequate resources to teach this course?', -- [DisplayName]
3427, -- [MetaAvailableFieldId]
@Propinfo1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
7, -- [RowPosition]
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
'Adequate Resources – Does the department have the adequate resources to teach this course?', -- [DisplayName]
3427, -- [MetaAvailableFieldId]
@Propinfo2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
7, -- [RowPosition]
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
'Adequate Resources – Does the department have the adequate resources to teach this course?', -- [DisplayName]
3427, -- [MetaAvailableFieldId]
@Propinfo3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
7, -- [RowPosition]
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
'Adequate Resources – Does the department have the adequate resources to teach this course?', -- [DisplayName]
3427, -- [MetaAvailableFieldId]
@Propinfo4, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
7, -- [RowPosition]
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
'Have you had department discussions about this course', -- [DisplayName]
3428, -- [MetaAvailableFieldId]
@NoName1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
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
'Have you had department discussions about this course', -- [DisplayName]
3428, -- [MetaAvailableFieldId]
@NoName2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
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
'Have you had department discussions about this course', -- [DisplayName]
3428, -- [MetaAvailableFieldId]
@NoName3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
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
'Have you had department discussions about this course', -- [DisplayName]
3428, -- [MetaAvailableFieldId]
@NoName4, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
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
'Justification?', -- [DisplayName]
1758, -- [MetaAvailableFieldId]
@NEWSec1, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textarea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
140, -- [Height]
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
'Justification?', -- [DisplayName]
1758, -- [MetaAvailableFieldId]
@NEWSec2, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textarea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
140, -- [Height]
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
'Justification?', -- [DisplayName]
1758, -- [MetaAvailableFieldId]
@NEWSec3, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textarea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
140, -- [Height]
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
'Justification?', -- [DisplayName]
1758, -- [MetaAvailableFieldId]
@NEWSec4, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textarea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
140, -- [Height]
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
----------------------------------------------------------------------------------------------
DECLARE @SHOWHIDE TABLE (Sec int, field int)
INSERT INTO @SHOWHIDE (Sec)
SELECT mssId FROM @insert WHERE mssId IS NOT NULL
UNION
SELECT @btm1
UNION
SELECT @btm2
UNION 
SELECT @btm3
UNION
SELECT @btm4

INSERT INTO @SHOWHIDE (field)
SELECT msfId FROM @insert WHERE msfId IS NOT NULL
AND Id in (9, 10, 11, 12, 13, 14, 15, 16)

----------------------------------------------------------------------------------------------
while exists(select top 1 1 from @SHOWHIDE)
begin
	declare @Trigger int = (SELECT TOP 1 field FROM @SHOWHIDE WHERE field IS NOT NULL)
	declare @Sec int = (SELECT TOP 1 sec FROM @SHOWHIDE WHERE sec IS NOT NULL)

	DECLARE @TriggerselectedFieldId INT = @Trigger;  -----------------------------------------------------------------------------------------------------------------
	-- The id for the field that triggers the show/hide 

	DECLARE @TriggerselectedSectionId INT = NULL; 

	DECLARE @displayRuleTypeId INT = 2;              
	-- DisplayRuleType 1 = FieldValidation, 2 = FieldDisplay, 3 = FieldCalculation, 4 = SectionDisplay   
	-- Always set to 2

	DECLARE @ExpressionOperatorTypeId INT = 16;       
	-- SELECT * FROM ExpressionOperatorType 
	-- ExpressionOperatorType 16 = NotEqual - Operand 1 must not be the same value as Operand 2
	-- Note: EOT 16 will throw an error if ComparisonDataType is 1

	DECLARE @ComparisonDataTypeId INT = 3;           
	-- ComparisonDataType 1 = Decimal, 2 = DateTime, 3 = String, 4 = Boolean    

	DECLARE @Operand2Literal NVARCHAR(50) = 2;  
	-- When Show/Hide is true the field is hidden - i.e. if this is a checkbox (Boolean) this should be 'false' to show the section when checked     
	-- Only one of these two should be used at a time in the MetaDisplaySubscriber query below. Delete the other one in that query and replace it with a NULL.    
	-- If possible, use a section instead of a field. The reason for this is that, as of this writing (branch 28, 2014-01-13), show/hide for fields is buggy and may not work properly. 
	-- Hiding an entire section is less prone to these issues due to the differences in the dynamic form DOM structure for sections vs. fields.    

	DECLARE @listenerSelectedFieldId INT = NULL;  

	DECLARE @listenerSelectedSectionId INT = @Sec; ----------------------------------------------------------------------------------------------------------------
	-- The id for the section that will show/hide based on the trigger

	DECLARE @DisplayRuleName NVARCHAR(50) = 'Show/hide Justification Textbox';    
	DECLARE @SubscriberName NVARCHAR(50) = 'Show/hide Justification Textbox';    
	-- Inserts a new Expression Id into the Expression table 
	-- This syntax is needed since the auto-incremented Id is the only field in the Expression table 

	INSERT INTO Expression
		OUTPUT inserted.*    
		DEFAULT VALUES    
	-- The new Expression Id you just inserted above    
	
	DECLARE @expressionId INT;    
	SET @expressionId = SCOPE_IDENTITY();    
	-- Inserts a new ExpressionPart Id into the ExpressionPart table

	INSERT INTO MetaDisplayRule (DisplayRuleName, DisplayRuleValue, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleTypeId, ExpressionId)    
		OUTPUT inserted.*    
		VALUES (@DisplayRuleName, NULL, @TriggerselectedFieldId, @TriggerselectedSectionId, @displayRuleTypeId, @expressionId)    
	-- Inserts a new MetaDisplayRule into the MetaDisplayRule table based on the variable values chosen above
	
	DECLARE @displayRuleId INT;    
		SET @displayRuleId = SCOPE_IDENTITY();
	-- Creates a new Id for the MetaDisplayRule inserted above

	INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)   
		OUTPUT inserted.*    
		VALUES (@expressionId, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL)    
	-- The new ExpressionPart Id you just inserted above 
	
	DECLARE @parentExpressionPartId INT;    
	SET @parentExpressionPartId = SCOPE_IDENTITY();
	-- Keep in mind that if this condition is true, it will hide the field or section  
	-- Inserts a new ExpressionPart Id into the ExpressionPart table and makes the previous ExpressionPart Id the Parent_ExpressionPartId for this one


	INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)    
		OUTPUT inserted.*    
		VALUES (@expressionId, @parentExpressionPartId, 1, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerSelectedFieldId, NULL, @Operand2Literal, NULL, NULL)  
	

	INSERT INTO MetaDisplaySubscriber (SubscriberName, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleId)    
		OUTPUT inserted.*    
		VALUES (@SubscriberName, @listenerSelectedFieldId, @listenerSelectedSectionId, @displayRuleId)

	DELETE FROM @SHOWHIDE
	WHERE Sec = @Sec
	DELETE FROM @SHOWHIDE
	WHERE field = @Trigger

end
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--commit
--rollback