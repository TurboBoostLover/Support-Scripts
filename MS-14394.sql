USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14394';
DECLARE @Comments nvarchar(Max) = 
	'Add Diversity tab to every course template';
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
		--AND mtt.MetaTemplateTypeId in ()		--comment back in if just doing some of the mtt's
/********************** Changes go HERE **************************************************/
INSERT INTO Lookup14
(Parent_Lookup14Id, Title, SortOrder, ClientId, StartDate)
VALUES
(NULL, '(DEIA) principles/strategies', 1, 2, GETDATE())

DECLARE @PARENTID int = SCOPE_IDENTITY()

INSERT INTO Lookup14
(Parent_Lookup14Id, Title, SortOrder, ClientId, StartDate)
VALUES
(@PARENTID, 'Catalog Description', 1, 2, GETDATE()),
(@PARENTID, 'Class Assignments', 2, 2, GETDATE()),
(@PARENTID, 'Content', 3, 2, GETDATE()),
(@PARENTID, 'Course Learning Outcomes', 4, 2, GETDATE()),
(@PARENTID, 'Credit for Prior Learning', 5, 2, GETDATE()),
(@PARENTID, 'Distance Education (course can be offered in different modalities)', 6, 2, GETDATE()),
(@PARENTID, 'Methods of Evaluation (Formative and summative assessments were selected)', 7, 2, GETDATE()),
(@PARENTID, 'Methods of Instruction (Equity-minded instruction, active-learning, and personalized learning strategies were selected)', 8, 2, GETDATE()),
(@PARENTID, 'Objectives', 9, 2, GETDATE()),
(@PARENTID, 'Resources (Zero cost textbooks and/or strategies to lower the costs of resources)', 10, 2, GETDATE())

Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
SELECT
	Id AS Value
   ,COALESCE(Title, '') AS Text
FROM Lookup14
WHERE Parent_Lookup14Id = (SELECT
		Id
	FROM lookup14
	WHERE Title = '(DEIA) principles/strategies')
AND Active = 1
Order By SortOrder
"

DECLARE @RSQL NVARCHAR(MAX) = "
SELECT
	Id AS Value
   ,COALESCE(Title, '') AS Text
FROM Lookup14
WHERE Parent_Lookup14Id = (SELECT
		Id
	FROM lookup14
	WHERE Title = '(DEIA) principles/strategies')
AND Active = 1
ORDER BY Text
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Lookup14', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', '(DEIA) principles/strategies Checklist', 2)

DECLARE @TABLE TABLE (Id int, TId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId into @TABLE
SELECT
2, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Diversity, Equity, Inclusion, and Accessibility (DEIA)', -- [SectionName]
1, -- [DisplaySectionName]
'', -- [SectionDescription]
1, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
13, -- [RowPosition]
13, -- [SortOrder]
1, -- [SectionDisplayId]
15, -- [MetaSectionTypeId]
Id, -- [MetaTemplateId]
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
FROM @templateId

DECLARE @TABLE2 TABLE (Id int, SecName NVARCHAR(MAX))

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted. MetaSelectedSectionId, inserted.SectionName into @TABLE2
SELECT
2, -- [ClientId]
Id, -- [MetaSelectedSection_MetaSelectedSectionId]
'To facilitate committee DEIA review, please select which COR components incorporate Diversity, Equity, Inclusion, and Accessibility (DEIA) principles/strategies (select all that apply):', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
3, -- [MetaSectionTypeId]
TId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
3501, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @TABLE
UNION
SELECT
2, -- [ClientId]
Id, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
TId, -- [MetaTemplateId]
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
FROM @TABLE

INSERT INTO MetaSelectedSectionAttribute
(GroupId, AttributeTypeId, Name, Value, MetaSelectedSectionId)
SELECT 1,1,'ForeignKeyToLookup','Lookup14Id', Id FROM @TABLE2 WHERE SecName = 'To facilitate committee DEIA review, please select which COR components incorporate Diversity, Equity, Inclusion, and Accessibility (DEIA) principles/strategies (select all that apply):'
UNION
SELECT 1,1,'ForeignKeyToParent','CourseId', Id FROM @TABLE2 WHERE SecName = 'To facilitate committee DEIA review, please select which COR components incorporate Diversity, Equity, Inclusion, and Accessibility (DEIA) principles/strategies (select all that apply):'
UNION
SELECT 1,1,'LookupTable','Lookup14', Id FROM @TABLE2 WHERE SecName = 'To facilitate committee DEIA review, please select which COR components incorporate Diversity, Equity, Inclusion, and Accessibility (DEIA) principles/strategies (select all that apply):'
UNION
SELECT 1,1,'ParentTable','Course', Id FROM @TABLE2 WHERE SecName = 'To facilitate committee DEIA review, please select which COR components incorporate Diversity, Equity, Inclusion, and Accessibility (DEIA) principles/strategies (select all that apply):'

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Lookup14', -- [DisplayName]
6250, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
100, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
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
FROM @TABLE2 WHERE SecName = 'To facilitate committee DEIA review, please select which COR components incorporate Diversity, Equity, Inclusion, and Accessibility (DEIA) principles/strategies (select all that apply):'
UNION
SELECT
'Are there any additional DEIA opportunities for this course you would like to discuss? Please respond here, if applicable.', -- [DisplayName]
3292, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
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
275, -- [Height]
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
FROM @TABLE2 WHERE SecName IS NULL
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct Id from @templateId)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback