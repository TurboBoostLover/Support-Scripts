USE [socccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16371';
DECLARE @Comments nvarchar(Max) = 
	'auto title';
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
Declare @clientId int =2, -- SELECT Id, Title FROM Client 
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
		AND mtt.MetaTemplateTypeId in (
		45, --SLO Assessment
		46, --AUO Assessment
		41, --Program Review
		42  --AUR
		)		--comment back in if just doing some of the mtt's

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
('Cover', 'Module', 'Title','Delete'),
('Cover', 'ModuleDetail', 'Lookup03Id_01','Move'),
('Cover', 'ModuleDetail', 'SubjectId', '1'),
('Cover', 'Module', 'UserId', '2')

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
DELETE FROM MetaTitleFields
WHERE MetaTemplateId in (
	SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId in (
		41, 42, 45, 46
	)
	and Active = 1
)

DELETE FROM MetaSelectedField WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE ACtion = 'Delete'
)

UPDATE MetaSelectedField
SET RowPosition = 0
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Move'
)

UPDATE MetaTemplate
SET EntityTitleTemplateString = 'AUO - [0] [1]'
, PublicEntityTitleTemplateString = 'AUO - [0] [1]'
WHERE MetaTemplateId in (
	SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 46
	and Active = 1
)

UPDATE MetaTemplate
SET EntityTitleTemplateString = 'SLO - [0] [1]'
, PublicEntityTitleTemplateString = 'SLO - [0] [1]'
WHERE MetaTemplateId in (
	SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 45
	and Active = 1
)

UPDATE MetaTemplate
SET EntityTitleTemplateString = 'Program Review - [0] [1]'
, PublicEntityTitleTemplateString = 'Program Review - [0] [1]'
WHERE MetaTemplateId in (
	SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 41
	and Active = 1
)

UPDATE MetaTemplate
SET EntityTitleTemplateString = 'AUR - [0] [1]'
, PublicEntityTitleTemplateString = 'AUR - [0] [1]'
WHERE MetaTemplateId in (
	SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 42
	and Active = 1
)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1' and mtt = 41
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Department', -- [DisplayName]
4123, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
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
FROM @Fields WHERE Action = '1' and mtt = 41
UNION
SELECT
'Department', -- [DisplayName]
4123, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
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
FROM @Fields WHERE Action = '2' and mtt = 42

INSERT INTO MetaTitleFields
(MetaTemplateId, MetaSelectedFieldId, Ordinal)
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId, 0 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 4123
and mt.MetaTemplateTypeId = 46
UNION
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId, 1 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 4375
and mt.MetaTemplateTypeId = 46
UNION
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId, 0 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 4118
and mt.MetaTemplateTypeId = 45
UNION
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId, 1 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 4375
and mt.MetaTemplateTypeId = 45
UNION
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId, 0 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 4123
and mt.MetaTemplateTypeId = 41
UNION
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId, 1 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 6812
and mt.MetaTemplateTypeId = 41
UNION
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId, 0 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 4123
and mt.MetaTemplateTypeId = 42
UNION
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId, 1 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 6812
and mt.MetaTemplateTypeId = 42

DECLARE @Tempalte1 int = (SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 41)
DECLARE @Tempalte2 int = (SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 42)
DECLARE @Tempalte3 int = (SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 45)
DECLARE @Tempalte4 int = (SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 46)

UPDATE MetaForeignKeyCriteriaClient
SET ResolutionSql = 'SELECT l03.ShortText As Text
FROM Lookup03 l03
WHERE Id = @Id'
WHERE Id = 73

EXEC upCreateEntityTitle @entityTypeId = 6, @metaTemplateId = @Tempalte1
EXEC upCreateEntityTitle @entityTypeId = 6, @metaTemplateId = @Tempalte2
EXEC upCreateEntityTitle @entityTypeId = 6, @metaTemplateId = @Tempalte3
EXEC upCreateEntityTitle @entityTypeId = 6, @metaTemplateId = @Tempalte4
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback