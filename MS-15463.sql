USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15463';
DECLARE @Comments nvarchar(Max) = 
	'Update Annual Unit Plan';
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
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (17)		--comment back in if just doing some of the mtt's

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
('Co-Contributor', 'ModuleContributor', 'UserId','Update1'),
('Main', 'ModuleGoalAssessment', 'CollegeGoalComments', 'Update2'),
('Main', 'ModuleGoal', 'MaxText01', 'Ping'),
('Main', 'ModuleGoal', 'ItemTypeId', 'Ping2'),
('Main', 'ModuleGoalAssessment', 'YesNoId_01', 'Update3'),
('Main', 'ModuleGoal', 'Bit01', 'delete'),
('Main', 'ModuleGoal', 'Bit02', 'delete'),
('Main', 'ModuleGoal', 'Related_ProgramId', 'delete'),
('Main', 'Module', 'SemesterId', 'Move'),
('Main', 'Module', 'UserId', 'Move'),
('Main', 'Module', 'Title', 'Move')

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
UPDATE MetaSelectedField
SET MetaPresentationTypeId = 25
, DisplayName = 'Goal'
, MetaAvailableFieldId = 3915
, DefaultDisplayType = 'CKEditor'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 992
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update3'
)

DECLARE @Main int = (SELECT TabId FROM @Fields WHERE Action = 'Update2')
DECLARE @OL int = (SELECT SectionId FROM @Fields WHERE Action = 'Ping')
DECLARE @Tab2 int = (SELECT TabId FROM @Fields WHERE Action = 'Update1')

UPDATE MetaSelectedSection
SET MetaSelectedSection_MetaSelectedSectionId = @Main
, RowPosition = 1
, SortOrder = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update1'
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
, SectionName = 'Goals'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = 'Update1'
)

UPDATE MetaSelectedField
SET MetaSelectedSectionId = @OL 
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in (
		'Update2', 'Update3'
	)
)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 2
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in (
		'Ping', 'Ping2'
	)
)

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update3'
)

DELETE FROM MetaSelectedSection
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update3'
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 31
, MetaSelectedSection_MetaSelectedSectionId = @Tab2
, SectionName = 'Goals'
, DisplaySectionName = 0
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Ping'
)

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Ping'
)

UPDATE ListItemType
SET Title = 'New Goal'
WHERE Id = 33

INSERT INTO ListItemType
(Title, ListItemTypeOrdinal, ListItemTableName, ListItemTitleColumn, SortOrder, StartDate, ClientId)
VALUES
('Previous Goal', 3, 'ModuleGoal', 'GoalStatusComments', 2, GETDATE(), 1)

DECLARE @PreviousGoal int = SCOPE_IDENTITY()

UPDATE ModuleGoal
SET ListItemTypeId = 33
WHERE ListItemTypeId IS NULL

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('declare @validCount int = 3;
declare @totalCount int = ((select count(*) as [count] from ModuleGoal mg where mg.ModuleId = @EntityId and ListItemTypeId <> 33));

select 
	case
		when @totalCount >= @validCount
			then 1
		else 0
	end
;', 1)

DECLARE @SQL int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'Goals OL', 'Must list 3 previous goals', 6, 'Requires three entires of previous goals', @SQL
FROM @Fields WHERE Action = 'Ping'

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'delete'
)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'select
    Id as Value,
    case
        when Title = ''Yes'' then ''In Progress''
        when Title = ''No'' then ''Completed''
        when Title = ''N/A'' then ''Abandoned''
    end as Text
from YesNo'
, ResolutionSql = 'select case
        when Title = ''Yes'' then ''In Progress''
        when Title = ''No'' then ''Completed''
        when Title = ''N/A'' then ''Abandoned''
    end as Text
from YesNo
where Id = @id'
WHERE Id = 116

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Move'
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Program', -- [DisplayName]
4138, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
4, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
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
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
190, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = 'Move'
UNION
SELECT
'Goal', -- [DisplayName]
3916, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
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
FROM @Fields WHERE Action = 'Ping'

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update3'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback