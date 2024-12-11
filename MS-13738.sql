USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13738';
DECLARE @Comments nvarchar(Max) = 
	'Update Service Unit Program Review';
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
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
	AND mtt.MetaTemplateTypeId = 21		--hardcode

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
('Unit Overview', 'Module', 'Description','Update'), --tab 1 (1A)
('Unit Overview', 'ModuleYesNo', 'YesNo01Id', 'Update2'), --(1B)
('Unit Overview', 'ModuleYesNo', 'YesNo02Id', 'Update3'), --(1C)
('Unit Overview', 'ModuleExtension01', 'TextMax01', 'Update4'),  --(1D)
('Unit Overview', 'ModuleExtension01', 'LongText03', 'Update5'),  --(1E)
('Unit Overview', 'GenericOrderedList01', 'MaxText01', 'Update6'),  --(1F)
('Service Unit Data And Service Unit Outcomes (SUOs)', 'ModuleExtension01', 'TextMax02', 'Update7'),  --tab2 (2A)
('Service Unit Data And Service Unit Outcomes (SUOs)', 'ModuleExtension01', 'TextMax03', 'Update8'),		--(2B)
('Service Unit Resources', 'GenericOrderedList02', 'Lookup14Id', 'Update9'),		--tab3 (3A)
('Service Unit Resources', 'ModuleYesNo', 'YesNo04Id', 'Update10'), --(3B)
('Service Unit Resources', 'ModuleExtension01', 'TextMax05', 'Update11'), --(3C)
('Service Unit Resources', 'ModuleExtension01', 'LongText10', 'Update12'),  --(3D)
('Service Unit Resources', 'ModuleYesNo', 'YesNo05Id', 'Update13'),  --(3E)
('Service Unit Resources', 'ModuleExtension02', 'LongText02', 'Update14'),  --(3F)
('Service Unit Resources', 'ModuleYesNo', 'YesNo06Id', 'Update15'),  --(3G)
('Summary, Recommendations, And Long-term Goals', 'ModuleExtension02', 'TextMax01', 'Update16'),  --tab4 (4A)
('Summary, Recommendations, And Long-term Goals', 'ModuleExtension02', 'TextMax02', 'Update17'),  --(4B)
('Summary, Recommendations, And Long-term Goals', 'ModuleExtension02', 'TextMax03', 'Update18'),  --(4C)
('Unit Overview', 'ModuleExtension01', 'LongText04', 'Update19'), --Make RTE
('Service Satisfaction', 'ModuleExtension01', 'LongText05', 'Delete'), --Delete tab
('Service Unit Resources', 'ModuleExtension01', 'TextMax04', 'Delete2'),
('Unit Overview', 'ModuleContributor', 'UserId', 'Sort11'),
('Unit Overview', 'ModuleExtension01', 'LongText02', 'Remove'),
('Unit Overview', 'ModuleYesNo', 'YesNo03Id', 'Sort5'),
('Unit Overview', 'ModuleExtension01', 'LongText01', 'Sort6'),
('Service Unit Resources', 'ModuleExtension02', 'LongText03', 'RTE'),
('Service Unit Resources', 'ModuleExtension02', 'LongText04', 'RTE2')


declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	rowposition int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, rowposition)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, msf.RowPosition
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
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
DECLARE @NoUse int = (SELECT SectionId FROM @Fields WHERE Action = 'Update5')
DECLARE @NoUse2 int = (SELECT sortorder FROM @Fields WHERE Action = 'Update5')

--------------------------------------------------------------------------------------------
DECLARE @Template int = (SELECT Id FROM @templateId)
DECLARE @TABLE TABLE (Id int Identity, Sec int)
--------------------------------------------------------------------------------------------
DECLARE @Tab1 int = (SELECT TabId FROM @Fields WHERE Action = 'Update')
DECLARE @Tab2 int = (SELECT TabId FROM @Fields WHERE Action = 'Update7')
DECLARE @Tab3 int = (SELECT TabId FROM @Fields WHERE Action = 'Update9')
DECLARE @Tab4 int = (SELECT TabId FROM @Fields WHERE Action = 'Update16')
DECLARE @Tab5 int = (SELECT TabId FROM @Fields WHERE Action = 'Delete')
--------------------------------------------------------------------------------------------
DECLARE @Sec1 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update6')
DECLARE @Sec2 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update9')
DECLARE @Sec3 int = (SELECT SectionId FROM @Fields WHERE Action = 'Sort11')
DECLARE @Sec4 int = (SELECT SectionId FROM @Fields WHERE Action = 'Remove')
DECLARE @Sec5 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update3')
DECLARE @Sec6 int = (SELECT SectionId FROM @Fields WHERE Action = 'Sort5')
DECLARE @Sec7 int = (SELECT SectionId FROM @Fields WHERE Action = 'Sort6')
DECLARE @Sec8 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update4')
--------------------------------------------------------------------------------------------
DECLARE @Fld1 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update')
DECLARE @Fld2 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update2')
DECLARE @Fld3 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update3')
DECLARE @Fld4 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update4')
DECLARE @Fld5 int = (SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaSelectedSectionId = @NoUse AND RowPosition = @NoUse2 - 1)
DECLARE @Fld6 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update7')
DECLARE @Fld7 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update8')
DECLARE @Fld8 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update10')
DECLARE @Fld9 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update11')
DECLARE @Fld10 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update12')
DECLARE @Fld11 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update13')
DECLARE @Fld12 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update14')
DECLARE @Fld13 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update15')
DECLARE @Fld14 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update16')
DECLARE @Fld15 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update17')
DECLARE @Fld16 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update18')
DECLARE @Fld17 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update5')
DECLARE @Fld18 int = (SELECT FieldId FROM @Fields WHERE Action = 'Update19')
DECLARE @Fld19 int = (SELECT FieldId FROM @Fields WHERE Action = 'Delete2')
DECLARE @Fld20 int = (SELECT FieldId FROM @Fields WHERE Action = 'Remove')
DECLARE @Fld21 int = (SELECT FieldId FROM @Fields WHERE Action = 'RTE')
DECLARE @Fld22 int = (SELECT FieldId FROM @Fields WHERE Action = 'RTE2')
--------------------------------------------------------------------------------------------
UPDATE MetaSelectedSection
Set SectionName = 'I. Unit Overview'
WHERE MetaSelectedSectionId = @Tab1

UPDATE MetaSelectedField
SET DisplayName = 'A. Describe the service unit’s purpose and the population served (students, college personnel, community, etc.). Utilize bullet points to indicate how the service unit aligns to the college mission, strategic plan, and applicable state-wide initiatives.'
WHERE MetaSelectedFieldId = @Fld1

UPDATE MetaSelectedField
SET DisplayName = 'C. Were there recommendations made in the prior comprehensive review?'
WHERE MetaSelectedFieldId = @Fld3

UPDATE MetaSelectedField
SET DisplayName = 'D. Describe an example of collaboration (since the last comprehensive review) with on-campus and/or off-campus areas (programs, service units, divisions, etc.). If applicable, include collaborations/partnerships with statewide or national organizations.'
WHERE MetaSelectedFieldId = @Fld4

UPDATE MetaSelectedField
SET DisplayName = '<b>E. If applicable, complete the fields below identifying internal and/or external factors since the last comprehensive review that have impacted the service unit.</b><br> Consider federal and state laws, changing demographics, characteristics of the population served by the service unit, changes in staffing, etc.'
WHERE MetaSelectedFieldId = @Fld5

UPDATE MetaSelectedSection
SET SectionName = 'F. Provide examples of evidence-based practices utilized by the service unit which support equitable outcomes for your population served utilizing the table below'
, SortOrder = 10
, RowPosition = 10
WHERE MetaSelectedSectionId = @Sec1

UPDATE MetaSelectedSection
SET SortOrder = 11
, RowPosition = 11
WHERE MetaSelectedSectionId = @Sec3

UPDATE MetaSelectedSection
SET SortOrder = 4
, RowPosition = 4
WHERE MetaSelectedSectionId = @Sec5

UPDATE MetaSelectedSection
SET SortOrder = 5
, RowPosition = 5
WHERE MetaSelectedSectionId = @Sec6

UPDATE MetaSelectedSection
SET SortOrder = 6
, RowPosition = 6
WHERE MetaSelectedSectionId = @Sec7

UPDATE MetaSelectedSection
SET SortOrder = 7
, RowPosition = 7
WHERE MetaSelectedSectionId = @Sec8
-----------------------------------------------------------------------------------------------------------------------------------------------------------------------


UPDATE MetaSelectedFieldAttribute
SET Value = 'If all SUOs have not been assessed since the last comprehensive review, specify which have not been assessed and provide an explanation. If part of your SUO data is a satisfaction survey be sure to include population surveyed, time frame, and modality.'
WHERE MetaSelectedFieldId = @Fld6

UPDATE MetaSelectedField
SET DisplayName = 'A. Review and analyze the last four years of service unit outcomes and assessment data. Describe any trends and anticipated changes (i.e. changes to the program, outcome statement, assessment method, identified training, professional development).'
WHERE MetaSelectedFieldId = @Fld6

UPDATE MetaSelectedSection
SET SectionName = 'II. Service Unit Data And Service Unit Outcomes (SUOs)'
WHERE MetaSelectedSectionId = @Tab2

UPDATE MetaSelectedField
SET DisplayName = 'B. Discuss other data that is relevant to your service unit.'
WHERE MetaSelectedFieldId = @Fld7

UPDATE MetaSelectedFieldAttribute
SET Value = 'This section could include the any of the following:<br>
•	Dashboard Data<br>
•	Survey Data (if not already included as a part of SUO Assessment)<br>
•	Or any other data that is relevant to your program <br>
•	Provide an analysis of trends, any equity gaps, and recommendations for improvement. Please include a PDF of the data discussed here in Appendix B
'
WHERE MetaSelectedFieldId = @Fld7


----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------


UPDATE MetaSelectedSection
SET SectionName = 'III. Service Unit Resources'
WHERE MetaSelectedSectionId = @Tab3

UPDATE MetaSelectedSection
SET SectionName = 'A. Complete the staffing table below.'
WHERE MetaSelectedSectionId = @Sec2

UPDATE MetaSelectedField
SET DisplayName = 'B. Are the current staffing levels sufficient to support the needs of the service unit?'
WHERE MetaSelectedFieldId = @Fld8

UPDATE MetaSelectedField
SET DisplayName = 'C. What are the specific hours of operation for the service unit? Describe how the hours support the needs of diverse student and/or populations.'
WHERE MetaSelectedFieldId = @Fld9

UPDATE MetaSelectedFieldAttribute
SET Value = 'Indicate the hours of operation and provide examples of how the hours support the needs of the population served. If an adjustment to the hours of operation is needed, provide a rationale, and indicate the impact the population served. Indicate the costs associated with the change.'
WHERE MetaSelectedFieldId = @Fld9

UPDATE MetaSelectedField
SET DisplayName = 'D. Review the last four-year budget (in Appendix C). Provide a brief summary and describe any trends.'
WHERE MetaSelectedFieldId = @Fld10

UPDATE MetaSelectedField
SET DisplayName = 'E. Are there sufficient opportunities and funding for professional development for service unit staff?'
WHERE MetaSelectedFieldId = @Fld11

UPDATE MetaSelectedField
SET DisplayName = 'F. Give at least one example of how professional development (since the last program review) was used by the program.'
WHERE MetaSelectedFieldId = @Fld12

UPDATE MetaSelectedField
SET DisplayName = 'G. Does the facility and equipment (including technology) meet the needs of the service unit?'
WHERE MetaSelectedFieldId = @Fld13


-------------------------------------------------------------------------------------------------------------------------------------------------------------


UPDATE MetaSelectedSection
SET SectionName = 'IV. Summary, Recommendations, And Long-term Goals'
WHERE MetaSelectedSectionId = @Tab4

UPDATE MetaSelectedField
SET DisplayName = 'A. Briefly describe or list the strengths of the program.'
WHERE MetaSelectedFieldId = @Fld14

UPDATE MetaSelectedField
SET DisplayName = 'B. Briefly describe or list areas of the service unit with the potential to be improved.  Outline your strategies, current or proposed, to address these areas.'
WHERE MetaSelectedFieldId = @Fld15

UPDATE MetaSelectedField
SET DisplayName = 'C. List the service unit’s top three goals for the next four years, including details of how and when they will be evaluated.'
WHERE MetaSelectedFieldId = @Fld16


-------------------------------------------------------------------------------------------------------------------------------------------------------------


UPDATE MetaSelectedField
SET DefaultDisplayType = 'CKEditor'
, MetaPresentationTypeId = 25														--Make requested fields RTE's
WHERE MetaSelectedFieldId in (@Fld17, @Fld18, @Fld16, @Fld21, @Fld22)

DELETE FROM MetaSelectedFieldPositionPermission WHERE MetaSelectedFieldId in (
SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE mss2.MetaSelectedSectionId = @Tab5
)

DELETE FROM MetaSelectedFieldRolePermission WHERE MetaSelectedFieldId in (
SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE mss2.MetaSelectedSectionId = @Tab5
)

DELETE FROM MetaDisplaySubscriber 
WHERE MetaSelectedFieldId in (@Fld20, @Fld2, @Fld19)
OR MetaSelectedSectionId in (@Sec4)

DELETE FROM MetaDisplayRule 
WHERE MetaSelectedFieldId in (@Fld20, @Fld2, @Fld19)

DELETE FROM ExpressionPart 
WHERE Operand1_MetaSelectedFieldId in (@Fld20, @Fld19, @Fld2)

DELETE FROM ModuleSectionSummary WHERE MetaSelectedSectionId = @Tab5

EXEC spBuilderSectionDelete @clientId, @Tab5										--Delete Tab
EXEC spBuilderSectionDelete @clientId, @Sec4										--Delete Section

DELETE FROM MetaSelectedField														--Delete Fields
WHERE MetaSelectedFieldId in (@Fld19, @Fld2)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
OUTPUT inserted.MetaSelectedSectionId INTO @TABLE(Sec)
values
(
1, -- [ClientId]
@Tab1, -- [MetaSelectedSection_MetaSelectedSectionId]
'Strategic Plan (Check all that Apply)', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
18, -- [MetaSectionTypeId]
@Template, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
1898, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)
,
(
1, -- [ClientId]
@Tab1, -- [MetaSelectedSection_MetaSelectedSectionId]
'', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
2, -- [RowPosition]
2, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Template, -- [MetaTemplateId]
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
1, -- [ClientId]
@Tab1, -- [MetaSelectedSection_MetaSelectedSectionId]
'Goals', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
3, -- [RowPosition]
3, -- [SortOrder]
1, -- [SectionDisplayId]
500, -- [MetaSectionTypeId]
@Template, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
3207, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)

DECLARE @Section1 int = (SELECT Sec FROM @TABLE WHERE Id = 1)
DECLARE @Section2 int = (SELECT Sec FROM @TABLE WHERE Id = 2)
DECLARE @Section3 int = (SELECT Sec FROM @Table WHERE Id = 3)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'', -- [DisplayName]
4974, -- [MetaAvailableFieldId]
@Section1, -- [MetaSelectedSectionId]
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
165, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'Strategic Plan Comment', -- [DisplayName]
4085, -- [MetaAvailableFieldId]
@Section2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
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
,
(
'<br><b>B. Provide a breif summary of, and update of progress toward, programmatic goals.</b>', -- [DisplayName]
NULL, -- [MetaAvailableFieldId]
@Section2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'StaticText', -- [DefaultDisplayType]
35, -- [MetaPresentationTypeId]
NULL, -- [Width]
0, -- [WidthUnit]
NULL, -- [Height]
0, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
NULL, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
2, -- [FieldTypeId]
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
'Goal', -- [DisplayName]
3915, -- [MetaAvailableFieldId]
@Section3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
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
,
(
'Goal Status', -- [DisplayName]
3835, -- [MetaAvailableFieldId]
@Section3, -- [MetaSelectedSectionId]
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
'Please explain the status of the Goal', -- [DisplayName]
3916, -- [MetaAvailableFieldId]
@Section3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
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

insert into [MetaSelectedSectionAttribute]
([GroupId], [AttributeTypeId], [Name], [Value], [MetaSelectedSectionId])
values
(
1,
1,
'TitleTable',
'ModuleGoal',
@Section3
)
,
(
1,
1,
'TitleColumn',
'Goal',
@Section3
)
,
(
1,
1,
'SortOrderTable',
'ModuleGoal',
@Section3
)
,
(
1,
1,
'SortOrderColumn',
'SortOrder',
@Section3
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

exec EntityExpand

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback