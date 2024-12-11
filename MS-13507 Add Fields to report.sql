USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13507';
DECLARE @Comments nvarchar(Max) = 
	'Add Fields to Course Outline Report';
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
Declare @clientId int =2, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

insert into @templateId
select mt.MetaTemplateId
from MetaTemplateType mtt
inner join MetaTemplate mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
where mtt.EntityTypeId = @Entitytypeid
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate is NULL
and mtt.active = 1
and mtt.IsPresentationView = 1 --report
and mtt.ClientId = @clientId
and mtt.TemplateName = 'Course Outline' 

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
('Assignments and Methods of Evaluation', 'CourseQueryText', 'QueryTextId_37','Update')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int
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
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
DECLARE @Section int = 
(SELECT SectionId from @Fields)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 3
WHERE MetaSelectedFieldId IN (SELECT FieldId FROM @Fields)

insert into [MetaSelectedField]  
(
[DisplayName], 
[MetaAvailableFieldId], 
[MetaSelectedSectionId],
[IsRequired], 
[MinCharacters], 
[MaxCharacters], 
[RowPosition], 
[ColPosition], 
[ColSpan], 
[DefaultDisplayType], 
[MetaPresentationTypeId], 
[Width], 
[WidthUnit], 
[Height],
[HeightUnit],
[AllowLabelWrap],
[LabelHAlign],
[LabelVAlign], 
[LabelStyleId], 
[LabelVisible], 
[FieldStyle], 
[EditDisplayOnly], 
[GroupName], 
[GroupNameDisplay], 
[FieldTypeId], 
[ValidationRuleId], 
[LiteralValue], 
[ReadOnly], 
[AllowCopy], 
[Precision], 
[MetaForeignKeyLookupSourceId], 
[MetadataAttributeMapId],
[EditMapId], 
[NumericDataLength], 
[Config]
)  
values 
(  
'Reading Assignments', -- [DisplayName] 
884, -- [MetaAvailableFieldId] 
@Section, -- [MetaSelectedSectionId] 
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
),
(  
'Writing Assignments', -- [DisplayName]
1365, -- [MetaAvailableFieldId] 
@Section, -- [MetaSelectedSectionId] 
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
),
(
'Other Assignments', -- [DisplayName]  
3270, -- [MetaAvailableFieldId] 
@Section, -- [MetaSelectedSectionId] 
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
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2


--commit
--rollback