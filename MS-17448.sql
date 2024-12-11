USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17448';
DECLARE @Comments nvarchar(Max) = 
	'Update Fields to positions only';
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
('Attachments', 'ModuleExtension02', 'TextMax13','1'),
('I. Unit Overview', 'Module', 'UserId', '2'),
('II. Service Unit Data And Service Unit Outcomes (SUOs)', 'ModuleExtension01', 'TextMax03', '3'),
('IV. Summary, Recommendations, And Long-term Goals', 'ModuleExtension02', 'TextMax11', '4'),
('V. IPR Addendum', 'ModuleExtension02', 'TextMax08', '5'),
('V. IPR Addendum', 'ModuleExtension01', 'TextMax08', '6'),
('V. IPR Addendum', 'ModuleExtension01', 'TextMax15', '7'),
('Attachments', 'ModuleExtension02', 'TextMax02', '8'),
('Attachments', 'ModuleExtension02', 'TextMax03', '9'),
('I. Program Overview', 'ModuleExtension02', 'TextMax06', '10'),
('I. Program Overview', 'ModuleExtension02', 'TextMax04', '11'),
('I. Program Overview', 'ModuleExtension02', 'TextMax05', '12'),
('IV. Staffing and Professional Development', 'ModuleExtension02', 'TextMax09', '16'),
('IV. Staffing and Professional Development', 'Module', 'Notes', '17'),
('IV. Staffing and Professional Development', 'ModuleCRN', 'TextMax04', '18'),
('V. Resources', 'ModuleQueryText', 'QueryText_47', '20'),
('V. Resources', 'ModuleQueryText', 'QueryText_48', '21'),
('VI. Summary, Recommendations and Long-Term Goals', 'ModuleExtension02', 'TextMax12', '22'),
('VI. Summary, Recommendations and Long-Term Goals', 'ModuleQueryText', 'QueryText_49', '23'),
('VI. Summary, Recommendations and Long-Term Goals', 'ModuleQueryText', 'QueryText_50', '24')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
INSERT INTO MetaSelectedFieldPositionPermission
(MetaSelectedFieldId, PositionId, AccessRestrictionType)
SELECT FieldId, 34, 2 FROM @Fields WHERE mtt = 36

UPDATE ExpressionPart
SET ExpressionOperatorTypeId = 3
WHERE Id = 652

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Comments - Program Division Representative', -- [DisplayName]
1226, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
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
FROM @Fields WHERE Action = '2' and mtt = 36
UNION
SELECT
'Comments - Dean or Administrator', -- [DisplayName]
4145, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
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
FROM @Fields WHERE Action = '2' and mtt = 36
UNION
SELECT
'Comments - Program Review Coordinator', -- [DisplayName]
4147, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
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
FROM @Fields WHERE Action = '2' and mtt = 36
UNION
SELECT
'Comments', -- [DisplayName]
4218, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
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
FROM @Fields WHERE Action = '3' and mtt = 36
UNION
SELECT
'Comments', -- [DisplayName]
1238, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
4, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
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
FROM @Fields WHERE Action = '3' and mtt = 36
UNION
SELECT
'Comments', -- [DisplayName]
1221, -- [MetaAvailableFieldId]
SectionID, -- [MetaSelectedSectionId]
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
FROM @Fields WHERE Action = '4' and mtt = 36
UNION
SELECT
'Comments', -- [DisplayName]
1223, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
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
FROM @Fields WHERE Action = '4' and mtt = 36

DELETE FROM MetaSelectedFieldPositionPermission
WHERE MetaSelectedFieldId in ( SELECT MetaSelectedFieldId FROM MetaSelectedField
WHERE MetaAvailableFieldId in (
1226, 4245, 4147,4215, 4218, 1238, 4217, 1204, 1205, 1221, 1228, 1223
)
and DisplayName like '%Comment%'
)

UPDATE MetaSelectedField
SET DisplayName = CASE
WHEN MetaAvailableFieldId in (1226, 4215, 4217, 1221) THEN 'Comments - Program Division Representative'
WHEN MetaAvailableFieldId in (4245, 4218, 1204, 1228, 4145) THEN 'Comments - Dean or Administrator'
WHEN MetaAvailableFieldId in (4147, 1238, 1205, 1223) THEN 'Comments - Program Review Coordinator'
ELSE DisplayName
END
WHERE MetaAvailableFieldId in (
1226, 4245, 4147,4215, 4218, 1238, 4217, 1204, 1205, 1221, 1228, 1223
)
and DisplayName like '%Comment%'

INSERT INTO MetaSelectedFieldPositionPermission
(MetaSelectedFieldId, AccessRestrictionType, PositionId)
SELECT MetaSelectedFieldId, 2, 28 FROM MetaSelectedField WHERE MetaAvailableFieldId in (1226, 4215, 4217, 1221) and DisplayName = 'Comments - Program Division Representative'
UNION
SELECT MetaSelectedFieldId, 2, 1 FROM MetaSelectedField WHERE MetaAvailableFieldId in (4245, 4218, 1204, 1228, 4145) and DisplayName = 'Comments - Dean or Administrator'
UNION
SELECT MetaSelectedFieldId, 2, 29 FROM MetaSelectedField WHERE MetaAvailableFieldId in (4147, 1238, 1205, 1223) and DisplayName = 'Comments - Program Review Coordinator'

INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, AccessRestrictionType, RoleId)
SELECT MetaSelectedFieldId, 2, 1 FROM MetaSelectedField WHERE MetaAvailableFieldId in (1226, 4215, 4217, 1221) and DisplayName = 'Comments - Program Division Representative'
UNION
SELECT MetaSelectedFieldId, 2, 1 FROM MetaSelectedField WHERE MetaAvailableFieldId in (4245, 4218, 1204, 1228, 4145) and DisplayName = 'Comments - Dean or Administrator'
UNION
SELECT MetaSelectedFieldId, 2, 1 FROM MetaSelectedField WHERE MetaAvailableFieldId in (4147, 1238, 1205, 1223) and DisplayName = 'Comments - Program Review Coordinator'
UNION
SELECT FieldId, 2, 1 FROM @Fields WHERE ACtion = '17' and mtt = 18

UPDATE MetaSelectedField
SET DisplayName = 'Comments - Program Division Representative'
, RowPosition = 3
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE mtt = 36 and Action = '7'
)

UPDATE MetaSelectedField
SET DisplayName = 'Comments - Dean or Administrator'
, RowPosition = 4
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE mtt = 36 and Action = '6'
)

UPDATE MetaSelectedField
SET DisplayName = 'Comments - Program Review Coordinator'
, RowPosition = 5
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE mtt = 36 and Action = '5'
)

UPDATE MetaSelectedField
SET DisplayName = 'Comments - Program Division Representative'
, RowPosition = 3
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE mtt = 18 and Action in ('9', '12', '7', '16', '21', '24')
)

UPDATE MetaSelectedField
SET DisplayName = 'Comments - Dean or Administrator'
, RowPosition = 4
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE mtt = 18 and Action in ('8', '11', '6', '17', '4', '23')
)

UPDATE MetaSelectedField
SET DisplayName = 'Comments - Program Review Coordinator'
, RowPosition = 5
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE mtt = 18 and Action in ('1', '10', '5', '18', '20', '22')
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback