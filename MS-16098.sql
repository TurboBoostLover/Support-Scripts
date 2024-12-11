USE [Fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16098';
DECLARE @Comments nvarchar(Max) = 
	'Fix List Item Title fields';
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
DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
SELECT 0 AS Value, ISNULL(l.Title, '') AS Text, gol.Lookup14Id AS FilterValue, gol.Lookup14Id AS filterValue
FROM Lookup14 AS l
INNER JOIN GenericOrderedList02 as gol on gol.Lookup14Id = l.Id
WHERE ModuleId = @EntityId
and gol.Id = @pkIdValue
"

DECLARE @SQL2 NVARCHAR(MAX) = "
SELECT 0 AS Value, ISNULL(MaxText02, '') AS Text
FROM GenericOrderedList01 as gol
WHERE ModuleId = @EntityId
and gol.Id = @pkIdValue
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'GenericOrderedList02', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'Title field for Generic Ordered List02', 3),
(@MAX2, 'GenericOrderedList01', 'Id', 'Title', @SQL2, @SQL2, 'Order By SortOrder', 'Title field for Generic Ordered List01', 3)

UPDATE ListItemType
SET ListItemTitleColumn = 'MaxText04'
WHERE Id = 31

DECLARE @Sections TABLE (SecId int, TempId Int)
INSERT INTO @Sections
SELECT mss.MEtaSelectedSectionId, MetaTemplateId FROM MetaSelectedSection AS mss
WHERE mss.MetaBaseSchemaId = 2512
and mss.SectionName like '%staff%'
and mss.MetaTemplateId in (
20, 40, 42
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 31
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @Sections
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSection_MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN @Sections AS s on mss.MetaSelectedSectionId = s.SecId
)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @Sections
)

DECLARE @Field INTEGERS

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId INTO @Field
SELECT
'Title Field', -- [DisplayName]
345, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
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
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Sections

insert into MetaSelectedFieldAttribute
(Name,Value,MetaSelectedFieldId)
SELECT 'UpdateSubscriptionTable1','GenericOrderedList02',Id FROM @Field
UNION
SELECT 'UpdateSubscriptionColumn1','Lookup14Id',Id FROM @Field

DECLARE @Section INT = (
	SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection AS mss
	WHERE mss.MetaBaseSchemaId = 2512
	and mss.SectionName not like '%staff%'
	and mss.MetaTemplateId = 20
)

UPDATE MetaSelectedSection
SET MetaBaseSchemaId = 1672
, MetaSectionTypeId = 31
WHERE MetaSelectedSectionId = @Section

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSection_MetaSelectedSectionId FROM MetaSelectedSection AS mss
	WHERE mss.MetaSelectedSectionId = @Section
)

DECLARE @Fields TABLE (FieldId int, Maf int)
INSERT INTO @Fields
SELECT msf.MetaSElectedFieldId, msf.MetaAvailableFieldId fROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
WHERE mss.MetaSelectedSectionId = @Section

UPDATE msf
SET MetaAvailableFieldId = 
CASE 
	WHEN msf.MetaAvailableFieldId = 342 THEN 4692
	WHEN msf.MetaAvailableFieldId = 345 THEN 4693
	WHEN msf.MetaAvailableFieldId = 343 THEN 4694
	WHEN msf.MetaAvailableFieldId = 344 THEN 4695
	WHEN msf.MetaAvailableFieldId = 346 THEN 4696
ELSE MetaAvailableFieldId
END
FROM MetaSelectedField AS msf
INNER JOIN @Fields AS f on msf.MetaSelectedFieldId = f.FieldId

INSERT INTO ListItemType
(Title, ListItemTypeOrdinal, ListItemTableName, ListItemTitleColumn, SortOrder, StartDate, ClientId)
VALUES
('New Item', 1, 'EntityLearningPlan', 'TextMax_02', 1, GETDATE(), 1)

DECLARE @Lt int = SCOPE_IDENTITY()

DECLARE @Modules INTEGERS
INSERT INTO @Modules
SELECT Id FROM Module WHERE MetaTemplateId = 20

INSERT INTO EntityLearningPlan
(ModuleId, TextMax_01,TextMax_02,TextMax_03,TextMax_04,TextMax_05, SortOrder, CreatedDate, ListItemTypeId)
SELECT m.Id, gol.Text100001, gol.Text100004, gol.Text100002, gol.Text100003, gol.Text100005, gol.SortOrder, GETDATE(), @Lt FROM @Modules AS m
INNER JOIN GenericOrderedList02 AS gol on gol.ModuleId = m.Id

exec EntityExpand @clientId =1 , @entityTypeId =6

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = 6