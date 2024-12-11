USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13861';
DECLARE @Comments nvarchar(Max) = 
	'Add section with 3 fields to not let them copy over and let all other fields copy over and deactivate some date types';
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
	@Entitytypeid int =2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
	AND mtt.MetaTemplateTypeId NOT IN (5, 17 ,18)


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
('Codes and Dates', 'Program', 'Quality','Delete'),
('Codes and Dates', 'Program', 'ProgramCodeId','Delete'),
('Codes and Dates', 'ProgramYesNo', 'YesNo07Id','Delete'),
('Codes and Dates', 'ProgramDate', 'ProgramDateTypeId','Update')

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
DECLARE @SecId TABLE (SecId int, Id int IDENTITY)

DECLARE @TabIds TABLE (TabId int, TempId int)
INSERT INTO @TabIds (TabId, TempId)
SELECT Distinct TabId, TemplateId FROM @Fields WHERE Action = 'Delete'

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Delete')

UPDATE MetaSelectedField
SET RowPosition = RowPosition - 3
WHERE MetaSelectedFieldId in (
	SELECT MetaSelectedFieldId 
	FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.MetaSelectedSectionId in (
		SELECT DISTINCT SectionId 
		FROM @Fields 
		WHERE Action = 'Delete'
		)
)

UPDATE ProgramDateType
SET Title = 'SACS notified of closure'
WHERE Id = 14

UPDATE ProgramDateType
SET Title = 'SACS acknowledged closure'
WHERE Id = 15

UPDATE ProgramDateType
SET EndDate = GETDATE()
, Active_Old = 0
WHERE Id in (5, 16, 17, 18, 8, 10, 11)

UPDATE MetaSelectedSection
SET DisplaySectionName = 0
WHERE MetaSelectedSectionId in (SELECT SectionId FROM @Fields WHERE Action = 'Update')

UPDATE MetaSelectedSection
SET RowPosition = RowPosition + 1
, SortOrder = SortOrder + 1
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId 
	FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	WHERE mss2.MetaSelectedSectionId in (SELECT TabId FROM @TabIds)
)

while exists(select top 1 1 from @TabIds)
BEGIN
	declare @TID int = (select top 1 TabId from @TabIds)
	declare @TempId int = (select top 1 TempId from @TabIds)

	insert into [MetaSelectedSection]
	([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
	OUTPUT inserted.MetaSelectedSectionId INTO @SecId (SecId)
	values
	(
	1, -- [ClientId]
	@TID, -- [MetaSelectedSection_MetaSelectedSectionId]
	'Approval Dates', -- [SectionName]
	1, -- [DisplaySectionName]
	NULL, -- [SectionDescription]
	0, -- [DisplaySectionDescription]
	NULL, -- [ColumnPosition]
	0, -- [RowPosition]
	0, -- [SortOrder]
	1, -- [SectionDisplayId]
	1, -- [MetaSectionTypeId]
	@TempId, -- [MetaTemplateId]
	NULL, -- [DisplayFieldId]
	NULL, -- [HeaderFieldId]
	NULL, -- [FooterFieldId]
	0, -- [OriginatorOnly]
	NULL, -- [MetaBaseSchemaId]
	NULL, -- [MetadataAttributeMapId]
	NULL, -- [EntityListLibraryTypeId]
	NULL, -- [EditMapId]
	0, -- [AllowCopy]
	0, -- [ReadOnly]
	NULL-- [Config]
	)

	DECLARE @NEWSECID int = (SELECT SecId FROM @SecId WHERE Id = (SELECT MAX(id) FROM @SecId))

	INSERT INTO MetaSelectedSectionAttribute
	(GroupId, AttributeTypeId, Name, Value, MetaSelectedSectionId)
	VALUES
	(1,1,'LabelWidth', 290, @NEWSECID)

		insert into [MetaSelectedField]
	([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
	values
	(
	'Approved by C&I Committee', -- [DisplayName]
	2616, -- [MetaAvailableFieldId]
	@NEWSECID, -- [MetaSelectedSectionId]
	0, -- [IsRequired]
	NULL, -- [MinCharacters]
	NULL, -- [MaxCharacters]
	0, -- [RowPosition]
	0, -- [ColPosition]
	1, -- [ColSpan]
	'TelerikDate', -- [DefaultDisplayType]
	27, -- [MetaPresentationTypeId]
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
	1, -- [FieldTypeId]
	NULL, -- [ValidationRuleId]
	NULL, -- [LiteralValue]
	0, -- [ReadOnly]
	0, -- [AllowCopy]
	NULL, -- [Precision]
	NULL, -- [MetaForeignKeyLookupSourceId]
	NULL, -- [MetadataAttributeMapId]
	NULL, -- [EditMapId]
	NULL, -- [NumericDataLength]
	NULL-- [Config]
	)
	,
	(
	'BOT approval date', -- [DisplayName]
	2617, -- [MetaAvailableFieldId]
	@NEWSECID, -- [MetaSelectedSectionId]
	0, -- [IsRequired]
	NULL, -- [MinCharacters]
	NULL, -- [MaxCharacters]
	1, -- [RowPosition]
	0, -- [ColPosition]
	1, -- [ColSpan]
	'TelerikDate', -- [DefaultDisplayType]
	27, -- [MetaPresentationTypeId]
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
	1, -- [FieldTypeId]
	NULL, -- [ValidationRuleId]
	NULL, -- [LiteralValue]
	0, -- [ReadOnly]
	0, -- [AllowCopy]
	NULL, -- [Precision]
	NULL, -- [MetaForeignKeyLookupSourceId]
	NULL, -- [MetadataAttributeMapId]
	NULL, -- [EditMapId]
	NULL, -- [NumericDataLength]
	NULL-- [Config]
	)
	,
	(
	'Dean''s Council approval date', -- [DisplayName]
	2618, -- [MetaAvailableFieldId]
	@NEWSECID, -- [MetaSelectedSectionId]
	0, -- [IsRequired]
	NULL, -- [MinCharacters]
	NULL, -- [MaxCharacters]
	2, -- [RowPosition]
	0, -- [ColPosition]
	1, -- [ColSpan]
	'TelerikDate', -- [DefaultDisplayType]
	27, -- [MetaPresentationTypeId]
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
	1, -- [FieldTypeId]
	NULL, -- [ValidationRuleId]
	NULL, -- [LiteralValue]
	0, -- [ReadOnly]
	0, -- [AllowCopy]
	NULL, -- [Precision]
	NULL, -- [MetaForeignKeyLookupSourceId]
	NULL, -- [MetadataAttributeMapId]
	NULL, -- [EditMapId]
	NULL, -- [NumericDataLength]
	NULL-- [Config]
	)
	DELETE @TabIds
	WHERE TabId = @TID
END

DECLARE @App TABLE (PId int, date datetime )
INSERT INTO @App (PId, date)
SELECT ProgramId, ProgramDate FROM ProgramDate
WHERE Active =1
aND ProgramDateTypeId = 8

DECLARE @BOT TABLE (PId int, date datetime )
INSERT INTO @BOT (PId, date)
SELECT ProgramId, ProgramDate FROM ProgramDate
WHERE Active =1
aND ProgramDateTypeId = 10

DECLARE @DEAN TABLE (PId int, date datetime )
INSERT INTO @DEAN (PId, date)
SELECT ProgramId, ProgramDate FROM ProgramDate
WHERE Active =1
aND ProgramDateTypeId = 11

UPDATE GenericDate
SET Date05 = a.date
, Date06 = b.date
, Date07 = d.date
FROM GenericDate AS gd
LEFT JOIN @App AS a on gd.ProgramId = a.PId
LEFT JOIN @BOT AS b on gd.ProgramId = b.PId
LEFT JOIN @DEAN AS d on gd.ProgramId = d.PId
WHERE ProgramId IS NOT NULL
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

exec EntityExpand

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback