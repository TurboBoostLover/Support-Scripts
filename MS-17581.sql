USE [laspositas];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17581';
DECLARE @Comments nvarchar(Max) = 
	'Update GE tab';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
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
('General Education/Transfer Request', 'CourseGeneralEducation', 'SemesterId','delete'),
('General Education/Transfer Request', 'Course', 'History','cid'),
('General Education/Transfer Request', 'Course', 'RCFaculty', 'secgone'),
('General Education/Transfer Request', 'GenericBit', 'Bit18', 'secgone'),
('General Education/Transfer Request', 'CourseGeneralEducation', 'GeneralEducationElementId', 'secgone2'),
('General Education/Transfer Request', 'CourseGeneralEducation', 'Comments', 'secgone2'),
('General Education/Transfer Request', 'CourseGeneralEducation', 'Bit01', 'secgone2'),
('General Education/Transfer Request', 'CourseGeneralEducation', 'Bit02', 'secgone2'),
('General Education/Transfer Request', 'CourseGeneralEducation', 'Bit03', 'secgone2')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int,
	secsort int,
	nam nvarchar(max)
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt, secsort, nam)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId, mss2.SortOrder, mss2.SectionName
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
DELETE FROM MetaSelectedFieldRolePermission
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'delete'
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'delete'
)

DECLARE @NewCID TABLE (FieldId int, SecId int)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId, inserted.MetaSelectedSectionId INTO @NewCID
SELECT
'New Request', -- [DisplayName]
2651, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
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
FROM @Fields WHERE Action = 'cid'
UNION
SELECT
'Already approved substantial change', -- [DisplayName]
2652, -- [MetaAvailableFieldId]
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
FROM @Fields WHERE Action = 'cid'
UNION
SELECT
'Already approved unsubstantial change', -- [DisplayName]
2653, -- [MetaAvailableFieldId]
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
FROM @Fields WHERE Action = 'cid'

INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, RoleId, AccessRestrictionType)
SELECT FieldId, 1, 2 FROM @NewCID

DELETE FROM MetaDisplaySubscriber
WHERE MetaDisplayRuleId in (
	SELECT Id FROM MetaDisplayRule
	WHERE ExpressionId in (
		SELECT ExpressionId FROM ExpressionPart
		WHERE Operand1_MetaSelectedFieldId in (
			SELECT FieldId FROM @Fields WHERE Action = 'secgone' and mtt <> 1
		)
	)
)

DELETE FROM MetaDisplayRule
WHERE ExpressionId in (
	SELECT ExpressionId FROM ExpressionPart
		WHERE Operand1_MetaSelectedFieldId in (
			SELECT FieldId FROM @Fields WHERE Action = 'secgone' and mtt <> 1
		)
)

DELETE FROM ExpressionPart
WHERE Operand1_MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'secgone' and mtt <> 1
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
SELECT FieldId FROM @Fields WHERE Action = 'secgone' and mtt <> 1
)

DELETE FROM MetaSelectedSection
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'secgone' and mtt <> 1
)

DELETE FROM MetaSelectedFieldRolePermission
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'secgone2' and mtt <> 1 and secsort in (16, 12)
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'secgone2' and mtt <> 1 and secsort in (16, 12)
)

UPDATE MetaForeignKeyCriteriaClient
sET CustomSql = '
declare @now datetime = getdate(); 
select gee.Id as Value, gee.Title as Text from  [GeneralEducation] ge 
	inner join [GeneralEducationElement] gee on gee.GeneralEducationId = ge.Id 
where @now between gee.StartDate and IsNull(gee.EndDate, @now) 
	and ge.Title = ''Las Positas College GE''
Order By gee.SortOrder
'
WHERE Id = 35

INSERT INTO GeneralEducation
(Title, SortOrder, ClientId, StartDate)
VALUES
('Las Positas College GE', 5, 1, GETDATE())

DECLARE @GE int = SCOPE_IDENTITY()

INSERT INTO GeneralEducationElement
(GeneralEducationId, Title, SortOrder, StartDate, ClientId)
VALUES
(@GE, '1A - English Composition', 0, GETDATE(), 1),
(@GE, '1B - Oral Communication and Critical Thinking', 1, GETDATE(), 1),
(@GE, '2 - Mathematical Concepts and Quantitative Reasoning', 2, GETDATE(), 1),
(@GE, '3 - Arts and Humanities', 3, GETDATE(), 1),
(@GE, '4 - Social and Behavioral Sciences', 4, GETDATE(), 1),
(@GE, '5 - Natural Sciences', 5, GETDATE(), 1),
(@GE, '6 - Ethnic Studies', 6, GETDATE(), 1),
(@GE, '7 - Kinesiology', 7, GETDATE(), 1),
(@GE, '8 - Health', 8, GETDATE(), 1),
(@GE, '9 - American Institutions', 9, GETDATE(), 1)

UPDATE GeneralEducation
SET EndDate = GETDATE()
WHERE Id = 5

UPDATE GeneralEducationElement
SET EndDate = GETDATE()
WHERE GeneralEducationId = 5

DECLARE @ShowHIDE TABLE (TemplateId int, TriggerId int, ListenerId int)
INSERT INTO @ShowHIDE
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId, msf2.MetaSelectedFieldId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedField AS msf2 on msf2.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 4667
and msf2.MetaAvailableFieldId = 1925

while exists(select top 1 1 from @ShowHIDE)
begin
    declare @TID int = (select top 1 TemplateId from @ShowHIDE)
		declare @Trig int = (SELECT Top 1 TriggerId FROM @ShowHIDE WHERE TemplateId = @TID)
		DECLARE @list int = (SELECT Top 1 ListenerId FROM @ShowHIDE WHERE TemplateId = @TID and TriggerId = @Trig)
		exec upAddShowHideRule @Trig, null, 2, 3, 4, 'false', @list, null, null, 'Show or Hide Comment box only when new is checked', 'Show or Hide Comment box only when new is checked'
		delete from @ShowHIDE WHERE TemplateId = @TID and TriggerId = @Trig and ListenerId = @list
end
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields
UNION
SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE Msf.MetaForeignKeyLookupSourceId = 35)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

commit
--rollback