USE [aurak];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17922';
DECLARE @Comments nvarchar(Max) = 
	'Add ABET info to Program Form and Syllabus report';
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
('Program Learning Outcomes', 'ProgramOutcome', 'Outcome','1')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
INSERT INTO ListSequenceNumber
(IntSequence, SortOrder, StartDate, ClientID)
VALUES
(1, 0, GETDATE(), 1),
(2, 1, GETDATE(), 1),
(3, 2, GETDATE(), 1),
(4, 3, GETDATE(), 1),
(5, 4, GETDATE(), 1),
(6, 5, GETDATE(), 1),
(7, 6, GETDATE(), 1)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'ABET Standard', -- [DisplayName]
16, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
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
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = '1'

DECLARE @Section TABLE (SecId int, TempId int)
INSERT INTO @Section
SELECT mss.MetaSelectedSectionId, mss.MetaTemplateId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE MetaAvailableFieldId = 8955
and mtt.IsPresentationView = 1

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

DECLARE @SQL NVARCHAR(MAX) = "
DECLARE @ShouldShow BIT = (SELECT CASE WHEN c.SubjectId IN (38, 57) THEN 1 ELSE 0 END FROM Course AS c WHERE c.Id = @EntityId);

DECLARE @Programs TABLE (Id INT, CourseId INT);
INSERT INTO @Programs
SELECT 
    p.Id, c.Id
FROM Course c
INNER JOIN Course AS c2 ON c.CloneSourceId = c2.Id
INNER JOIN ProgramSequence ps ON c2.Id = ps.CourseId
INNER JOIN Program p ON ps.ProgramId = p.Id
WHERE c.Id = @EntityId;

DECLARE @Assessed TABLE (poId INT);
INSERT INTO @Assessed
SELECT ProgramOutcomeId FROM CourseOutcomeProgramOutcome AS copo
INNER JOIN CourseOutcome AS co ON copo.CourseOutcomeId = co.Id
INNER JOIN Course As c on co.CourseId = c.Id
INNER JOIN Course AS c2 on c2.CloneSourceId = c.Id
WHERE c2.Id = @EntityId;

DECLARE @Text TABLE (Txt NVARCHAR(MAX));

WITH AggregatedOutcomes AS (
    SELECT 
        DISTINCT p2.Id AS ProgramId,
        p2.EntityTitle,
        po.Id AS ProgramOutcomeId,
        lsn.IntSequence,
        po.Outcome,
        CASE WHEN a.poId IS NOT NULL THEN 'X' ELSE '' END AS AddressedInCourse
    FROM Program AS p2
    INNER JOIN ProgramOutcome AS po ON p2.Id = po.ProgramId
    LEFT JOIN @Assessed AS a ON po.Id = a.poId
    LEFT JOIN ListSequenceNumber AS lsn ON po.ListSequenceNumberId = lsn.Id
    WHERE p2.Id IN (SELECT Id FROM @Programs)
)

INSERT INTO @Text
SELECT 
    CASE WHEN @ShouldShow = 0 THEN ''
    ELSE CONCAT(
        'Mapping ABET Standards and Course Learning Outcomes to ', p2.Title,
        '<table style=""width:100%; border-collapse:collapse; border:1px solid black;"">',
        '<tr><th style=""border:1px solid black; padding:8px; background-color:#f2f2f2;"">ABET Standards</th>',
        '<th style=""border:1px solid black; padding:8px; background-color:#f2f2f2;"">Program Learning Outcomes</th>',
        '<th style=""border:1px solid black; padding:8px; background-color:#f2f2f2;"">Program Learning Outcomes Addressed in Course</th></tr>',
        dbo.ConcatWithSepOrdered_Agg(
            '', AggregatedOutcomes.ProgramOutcomeId,
            CONCAT(
                '<tr><td style=""border:1px solid black; padding:8px;"">', CAST(AggregatedOutcomes.IntSequence AS NVARCHAR), '</td>',
                '<td style=""border:1px solid black; padding:8px;"">', AggregatedOutcomes.Outcome, '</td>',
                '<td style=""border:1px solid black; padding:8px; text-align:center;"">', AggregatedOutcomes.AddressedinCourse, '</td></tr>'
            )
        ),
        '</table>'
    ) 
    END AS Text
FROM Course AS c
INNER JOIN @Programs AS p ON p.CourseId = c.Id
INNER JOIN Program AS p2 ON p.Id = p2.Id
INNER JOIN AggregatedOutcomes ON AggregatedOutcomes.ProgramId = p2.Id
WHERE c.Id = @EntityId
GROUP BY p2.Title;

SELECT dbo.ConcatWithSep_Agg('<br>', Txt) AS Text FROM @Text
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'CLO to PLO for ABET', 2)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'', -- [DisplayName]
8963, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Querytext', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
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
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Section

INSERT INTO EditMapStatus
(EditMapId, StatusAliasId, RoleId)
SELECT EditMapId, StatusAliasId, 4 FROM EditMapStatus
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select Distinct templateId FROM @Fields
UNION
SELECT TempId FROM @Section
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback