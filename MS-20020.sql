USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-20020';
DECLARE @Comments nvarchar(Max) = 
	'Up GE tab';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
('General Education/Transfer Request', 'CourseDescription', 'HasSpecialTopics','1'),
('General Education/Transfer Request', 'CourseGeneralEducation', 'GeneralEducationElementId','1'),
('General Education/Transfer Request', 'GenericBit', 'Bit07','1'),
('General Education/Transfer Request', 'Course', 'ISCSUTransfer','1'),
('General Education/Transfer Request', 'Course', 'ComparableCsuUc','2'),
('General Education/Transfer Request', 'Course', 'History','3'),
('General Education/Transfer Request', 'GenericBit', 'Bit30','4'),
('General Education/Transfer Request', 'GenericBit', 'Bit31','5'),
('General Education/Transfer Request', 'GenericBit', 'Bit32','6'),
('General Education/Transfer Request', 'GenericBit', 'Bit17','1'),
('General Education/Transfer Request', 'GenericBit', 'Bit18','1'),
('General Education/Transfer Request', 'GenericBit', 'Bit19','1'),
('General Education/Transfer Request', 'Course', 'RCFaculty','1'),
('General Education/Transfer Request', 'GenericBit', 'Bit20','1'),
('General Education/Transfer Request', 'GenericMaxText', 'TextMax17','1')

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
UPDATE GenericBit
SET Bit31 = 1
WHERE CourseId IS NOT NULL
and Bit32 = 1

UPDATE GenericBit
SET Bit32 = NULL
WHERE CourseId IS NOT NULL
and Bit32 IS NOT NULL

DECLARE @Sections TABLE (SecId int)
INSERT INTO @Sections
SELECT SectionId FROM @Fields WHERE Action = '1'

DELETE FROM MetaSelectedFieldRolePermission
WHERE MetaSelectedFieldId in (
	SELECT MetaSelectedFieldId FROM MetaSelectedField
	WHERE MetaSelectedSectionId in (
		SELECT SecId FROM @Sections
	)
)

while exists(select top 1 1 from @Sections)
begin
    declare @TID int = (select top 1 SecId from @Sections)
    EXEC spBuilderSectionDelete @clientId, @TID
    delete @Sections
    where SecId = @TID
end

DELETE FROM MetaSelectedFieldRolePermission
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in ('6', '4', '5')
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in ('6', '4', '5')
)

DECLARE @GECheck TABLE (TempId int, SecId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaTemplateId, inserted.MetaSelectedSectionId INTO @GECheck
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'General Education', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
32, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
131, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Fields WHERE Action = '4'

DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 2;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		--Create more Variables here using Sort if needed
DECLARE @MAX2 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 2)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
select [Id] as [Value], (Title) as [Text], SortOrder AS SortOrder
from [GeneralEducation] 
where Active = 1
UNION
SELECT ge.Id as Value, CONCAT('<span class=""text-danger"">', ge.Title, '</span>') as [Text], SortOrder AS SortOrder
FROM GeneralEducation ge
WHERE ge.Active = 0
and ge.Id in (
	SELECT gee.GeneralEducationId FROM CourseGeneralEducation AS cge
	INNER JOIN GeneralEducationElement AS gee on cge.GeneralEducationElementId = gee.Id
	WHERE cge.CourseId = @EntityId
)
Order By SortOrder
"

DECLARE @RSQL NVARCHAR(MAX) = "
select (Title) as [Text]
from [GeneralEducation] 
where [Id] = @Id
"

DECLARE @CSQL2 NVARCHAR(MAX) = "
declare @now datetime = getdate(); 

select gee.Id as Value,
gee.Title as Text, 
ge.Id as filterValue,
IsNull(gee.SortOrder, gee.Id) as SortOrder,
IsNull(ge.SortOrder, ge.Id) as FilterSortOrder
from  [GeneralEducation] ge 
inner join [GeneralEducationElement] gee on gee.GeneralEducationId = ge.Id
where @now between gee.StartDate 
and IsNull(gee.EndDate, @now)
UNION
SELECT gee.Id as Value,
CONCAT('<span class=""text-danger"">', gee.Title, '</span>') as [Text],
ge.Id as filterValue,
IsNull(gee.SortOrder, gee.Id) as SortOrder,
IsNull(ge.SortOrder, ge.Id) as FilterSortOrder
FROM GeneralEducation ge
INNER JOIN GeneralEducationElement AS gee on gee.GeneralEducationId = ge.Id
WHERE gee.Active = 0
and gee.Id in (
	SELECT cge.GeneralEducationElementId FROM CourseGeneralEducation AS cge
	WHERE cge.CourseId = @EntityId
)
Order By filterValue, SortOrder
"

DECLARE @RSQL2 NVARCHAR(MAX) = "
select (Title) as [Text]
from [GeneralEducationElement] 
where [Id] = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'GeneralEducation', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', '', 2),
(@MAX2, 'GeneralEducationElement', 'Id', 'Title', @CSQL2, @RSQL2, 'Order By SortOrder', '', 2)

DECLARE @NewFields TABLE (FieldId int, nam NVARCHAR(MAX))

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId, inserted.DisplayName INTO @NewFields
SELECT
'General Education', -- [DisplayName]
348, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
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
FROM @GECheck
UNION
SELECT
'General Education Element', -- [DisplayName]
1371, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
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
FROM @GECheck
UNION
SELECT
'Comments', -- [DisplayName]
1925, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
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
FROM @GECheck
UNION
SELECT
'Approved', -- [DisplayName]
4669, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
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
FROM @GECheck

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'lookuptablename', 'CourseGeneralEducation', SecId FROM @GECheck
UNION
SELECT 'lookupcolumnname', 'GeneralEducationElementId', SecId FROM @GECheck
UNION
SELECT 'grouptablename', 'CourseGeneralEducation', SecId FROM @GECheck
UNION
SELECT 'groupcolumnname', 'GeneralEducationId', SecId FROM @GECheck

INSERT INTO MetaSelectedFieldRolePermission
(RoleId, AccessRestrictionType, MetaSelectedFieldId)
SELECT 1, 2, FieldId FROM @NewFields
UNION
SELECT 4, 1, FieldId FROM @NewFields

UPDATE GeneralEducation
SET EndDate = GETDATE()
WHERE Id in (
	6, --CSU
	3 --IGETC
)

UPDATE GeneralEducationElement
SET EndDate = GETDATE()
WHERE GeneralEducationId in (
	3, 6
)

UPDATE GeneralEducation
SET Title = 'CSU Transfer'
, SortOrder = 0
WHERE Id = 8

UPDATE GeneralEducation
SET Title = 'Cal-GETC'
, SortOrder = 1
WHERE Id = 10

UPDATE GeneralEducation
SET Title = 'UC Transfer'
, SortOrder = 2
WHERE Id = 9

UPDATE GeneralEducation
SET SortOrder = 3
WHERE Id = 11

UPDATE GeneralEducation
SET SortOrder = 4
WHERE Id = 7

UPDATE GeneralEducation
SET SortOrder = 7
WHERE Id = 3
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

commit
--rollback