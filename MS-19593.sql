USE [cuesta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19593';
DECLARE @Comments nvarchar(Max) = 
	'Version course forms just to add a OL';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

--------------------------Version-------------------------------------------------------

DECLARE @templateId2 INTEGERS
INSERT INTO @templateId2
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
		AND mtt. MetaTemplateTypeId in (
			1, 9, 12
		)

UPDATE MetaTemplate
SET EndDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Id FROM @templateId2
		)

DECLARE @UserId int = (
SELECT Id FROM [User]
WHERE FirstName = 'Curriqunet'							--get user id
AND Username = 'SupportAdmin@CurriQunet.com'
)

while exists(select top 1 1 from @templateId2)
begin
    declare @TID int = (select top 1 * from @templateId2)

EXEC spBuilderTemplateCopy @clientId = @clientId, @userId = @UserId,  @templateId = @TID

DECLARE @Templateid3 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new program
DECLARE @Templatetypeid int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of new program

EXEC spBuilderTemplateActivate @clientId = @clientId, @metaTemplateId = @Templateid3 , @metaTemplateTypeId = @Templatetypeid -- activates the new template

    delete @templateId2
    where id = @TID
end

----------------------------------------------------------------------------------------

DECLARE @Tabs TABLE (TabId int, TempId int)
INSERT INTO @Tabs
SELECT mss.MetaSelectedSectionId, mt.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mt.Active = 1
and mt.EndDate IS NULL
and mtt.MetaTemplateTypeId in (
	1, 9, 12
)
and mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
and mss.SectionName like '%Cuesta General Education%'

UPDATE MetaSelectedSection
SET SortOrder = SortOrder + 1
, RowPosition = RowPosition + 1
WHERE MetaSelectedSection_MetaSelectedSectionId in (
	SELECT TabId FROM @Tabs
)

DECLARE @OL TABLE (SecId int, TempId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @OL
SELECT DISTINCT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'General Education Categories (effective 2025)', -- [SectionName]
1, -- [DisplaySectionName]
'To propose adding a course to one of the eight G.E. Areas, please review the Area Rubric definitions, objectives, and/or core competencies that the course may satisfy. Click on Help link for documents for individual G.E. Areas to complete and upload to the Attached Files section of this proposal.', -- [SectionDescription]
1, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
31, -- [MetaSectionTypeId]
TempId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
2489, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Tabs

DECLARE @CheckList INTEGERS

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId INTO @CheckList
SELECT
1, -- [ClientId]
SecId, -- [MetaSelectedSection_MetaSelectedSectionId]
'2025 GE', -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
6, -- [RowPosition]
2, -- [SortOrder]
1, -- [SectionDisplayId]
32, -- [MetaSectionTypeId]
TempId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
6487, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @OL

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'lookuptablename', 'GenericOrderedList01Lookup05', Id FROM @CheckList
UNION
SELECT 'lookupcolumnname', 'Lookup05Id', Id FROM @CheckList
UNION
SELECT 'columns', '1', Id FROM @CheckList

INSERT INTO Lookup05
(Lookup05ParentId, ClientId, LongText, StartDate, SortOrder)
VALUES
(NULL, 1, 'General Education Categories', GETDATE(), 0)

DECLARE @ParentId int = SCOPE_IDENTITY()

INSERT INTO Lookup05
(Lookup05ParentId, ClientId, LongText, StartDate, SortOrder)
VALUES
(@ParentId, 1, 'Area 1A: English Composition', GETDATE(), 0),
(@ParentId, 1, 'Area 1B: Oral Communication and Critical Thinking', GETDATE(), 1),
(@ParentId, 1, 'Area 2: Mathematical Concepts and Quantitative Reasoning ', GETDATE(), 2),
(@ParentId, 1, 'Area 3: Arts and Humanities ', GETDATE(), 3),
(@ParentId, 1, 'Area 4: Social and Behavioral Sciences ', GETDATE(), 4),
(@ParentId, 1, 'Area 5: Natural Sciences', GETDATE(), 5),
(@ParentId, 1, 'Area 6: Ethnic Studies ', GETDATE(), 6),
(@ParentId, 1, 'Area 7: Cultural and Civic Engagement ', GETDATE(), 7),
(@ParentId, 1, 'Area 8: Wellness and Lifelong Development', GETDATE(), 8)

DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 1;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		--Create more Variables here using Sort if needed

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
SELECT Id AS Value,
LongText AS Text
FROM Lookup05
WHERE Lookup05ParentId in (
	SELECT Id FROM Lookup05 WHERE Lookup05ParentId IS NULL and LongText = 'General Education Categories'
)
"

DECLARE @RSQL NVARCHAR(MAX) = "
select LongText as [Text]       
from [Lookup05]  
where Id = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Lookup05', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', '2025 GE', 1)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Lookup05Id', -- [DisplayName]
11310, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
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
FROM @CheckList

DECLARE @GeneralEdCat INTEGERS
INSERT INTO @GeneralEdCat
SELECT MetaSelectedSectionId FROM MetaSelectedSection
WHERE MetaBaseSchemaId = 5311
AND SectionName = 'General Education Categories and Requirements'

UPDATE MetaSelectedSection
SET SectionName = 'General Education Categories and Requirements (ended 2025)'
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @GeneralEdCat
)

DECLARE @GradReq INTEGERS
INSERT INTO @GradReq
SELECT MetaSelectedSectionId FROM MetaSelectedSection
WHERE MetaBaseSchemaId = 5311
AND SectionName = 'Graduation Requirements'

UPDATE MetaSelectedSection
SET SectionName = 'Graduation Requirements (ended 2025)'
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @GradReq
)

DECLARE @Courses TABLE (MetaTemplateId int, Id int, Status int, NewTemplateId int)
INSERT INTO @Courses
SELECT mt.MetaTemplateId, c.Id, c.StatusAliasId, mt2.MetaTemplateId
FROM Course AS c
INNER JOIN MetaTemplate AS mt on c.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaTemplate As mt2 on mtt.MetaTemplateTypeId = mt2.MetaTemplateTypeId and mt2.Active = 1 and mt2.EndDate IS NULL
WHERE c.Active = 1
and c.StatusAliasId in (
	1, --Active
	2, --Approved
	10, --Launched
	3 --Draft
)

UPDATE Course
SET MetaTemplateId = c2.NewTemplateId
FROM Course AS c
INNER JOIN @Courses AS c2 on c.Id = c2.Id

UPDATE GeneralEducation
SET Title = 'General Education Categories and Requirements (ended 2025)'
WHERE Id = 40

UPDATE GeneralEducation
SET Title = 'Graduation Requirements (ended 2025)'
WHERE Id = 42

DECLARE @SQL NVARCHAR(MAX) = '
declare @outputText nvarchar(max);

DECLARE @OL NVARCHAR(MAX) = (
	SELECT 
		CASE 
			WHEN l5.LongText IS NOT NULL THEN 
				CONCAT(
					''<ul style="list-style-type: circle;">'',
					STRING_AGG(CONCAT(''<li>'', l5.LongText, ''</li>''), ''''),
					''</ul>''
				)
			ELSE ''''
		END
	FROM Course AS C
	INNER JOIN GenericOrderedList01 AS gol1 ON gol1.CourseId = C.Id
	INNER JOIN GenericOrderedList01Lookup05 AS gol5 ON gol5.GenericOrderedList01Id = gol1.Id
	INNER JOIN Lookup05 AS l5 ON gol5.Lookup05Id = l5.Id
	group by l5.LongText
)

		SELECT @outputText += @OL

		select @outputText += STRING_AGG(rt.RenderedText, '''') WITHIN GROUP (ORDER BY rt.SortOrder)
		from (
			select 
				concat(
					''<b>''
						, ge.Title
					, ''</b>''
					, dbo.fnHtmlOpenTag(''li'', dbo.fnHtmlAttribute(''style'', ''list-style-type: none;''))
						, dbo.fnHtmlOpenTag(''ul'', null)
							, gee2.RenderedTextTwo
						, dbo.fnHtmlCloseTag(''ul'')
					, dbo.fnHtmlCloseTag(''li'')
				) as RenderedText
				, row_number() over (order by gee.SortOrder) as SortOrder
			from CourseGE cge
				inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
				inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id
				inner join Course c on cge.CourseId = c.Id
				cross apply (
					select STRING_AGG(gee2.RenderedText, '''') WITHIN GROUP (ORDER BY gee2.SortOrder) as RenderedTextTwo
					from (
						select 
							concat(
								dbo.fnHtmlOpenTag(''li'', dbo.fnHtmlAttribute(''style'', ''list-style-type: circle;''))
									, gee2.Title
								, dbo.fnHtmlCloseTag(''li'')
							) as RenderedText
							, row_number() over (order by gee2.SortOrder) as SortOrder
						from GeneralEducationElement gee2
						where cge.GeneralEducationElementId = gee2.Id
					) gee2
				) gee2
			where c.Id = @entityId
		) rt;

		select 0 as [Value]
			, concat(
				''<b>Cuesta General Education</b><br />''
				, dbo.fnHtmlOpenTag(''ol'', null)
					, @outputText
				, dbo.fnHtmlCloseTag(''ol'')
			) as [Text]
		;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql= @SQL
WHERE Id = 56174221
-----------------------------------------------------------------------------------------
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select TempId FROM @Tabs
UNION
SELECT mt.MetaTemplateId
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 56174221
)

exec EntityExpand @clientId =1 , @entityTypeId =1