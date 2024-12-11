USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14178';
DECLARE @Comments nvarchar(Max) = 
	'Add query text to program forms and program narrative report';
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
    --AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (2, 5, 6, 7) --7 is report

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
('Description/Narrative', 'ProgramDetail', 'MasterPlanning','Update'),
('Description/Narrative', 'ProgramDetail', 'AcademicProgram','Update2'),
('Description/Narrative', 'ProgramDetail', 'ProgramAlignment','Update3'),
('Description/Narrative', 'ProgramDetail', 'SimilarPrograms','Update4'),
('Description/Narrative', 'ProgramDetail', 'StudentDemand','Update5')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @TABLE TABLE(id int, po nvarchar(max), co nvarchar(max), clo nvarchar(max))
INSERT INTO @TABLE
SELECT 
	po.Id,
	po.Outcome as [Program Outcome],
	co.OutcomeText as [Course Outcome],
	dbo.ConcatWithSep_Agg(''<li>'', clo.Title) as [CLO]
FROM Program AS p
INNER JOIN ProgramOutcome AS po on po.ProgramId = p.Id
LEFT JOIN ProgramOutcomeMatching AS pom on pom.ProgramOutcomeId = po.Id
LEFT JOIN CourseOutcome AS co on pom.CourseOutcomeId = co.Id
LEFT JOIN ClientLearningOutcomeProgramOutcome AS clopo on clopo.ProgramOutcomeId = po.Id
LEFT JOIN ClientLearningOutcome AS clo on clopo.ClientLearningOutcomeId = clo.Id
WHERE p.Id = @EntityId
group by po.Id, po.Outcome, co.OutcomeText

DECLARE @TABLE2 TABLE(id int, po nvarchar(max), co nvarchar(max), clo nvarchar(max))
INSERT INTO @TABLE2
SELECT id as VALUE,
po AS po,
dbo.ConcatWithSep_Agg(''<li>'', co) as co,
 CASE
	WHEN clo IS NOT NULL
	 THEN CONCAT(''<ul><li>'',clo, ''</ul>'')
	 ELSE ''''
	END AS clo
FROM @TABLE
group by id, po, clo

SELECT
    0 AS Value,
    CONCAT(po, 
           CASE
               WHEN co IS NOT NULL THEN CONCAT(''<ul><li>'', co, ''</ul>'')
               ELSE ''''
           END, 
           clo) AS Text
FROM @TABLE2
ORDER BY po;
'

DECLARE @MAX int = (SELECT MAX(id) FROM MetaForeignKeyCriteriaClient) + 1

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Program', 'Id', 'Title', @SQL, @SQL, 'Mappings for programs', 2)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in ('Update', 'Update2', 'Update3', 'Update4', 'Update5') and mtt <> 7
)

DECLARE @SEC1 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update' and mtt = 2)
DECLARE @SEC2 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update' and mtt = 5)
DECLARE @SEC3 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update' and mtt = 6)
DECLARE @SEC4 int = (SELECT SectionId FROM @Fields WHERE Action = 'Update' and mtt = 7)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'Program Outcomes and Mapping', -- [DisplayName]
8516, -- [MetaAvailableFieldId]
@SEC1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
)
,
(
'Program Outcomes and Mapping', -- [DisplayName]
8516, -- [MetaAvailableFieldId]
@SEC2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
)
,
(
'Program Outcomes and Mapping', -- [DisplayName]
8516, -- [MetaAvailableFieldId]
@SEC3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
)
,
(
'Program Outcomes and Mapping', -- [DisplayName]
8516, -- [MetaAvailableFieldId]
@SEC4, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
6, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback