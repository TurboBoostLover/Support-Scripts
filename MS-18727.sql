USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18727';
DECLARE @Comments nvarchar(Max) = 
	'Update COR for Common Course Numbering';
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
    AND mtt.IsPresentationView = 1	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (9)		--comment back in if just doing some of the mtt's

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
('Course Content', 'GenericMaxText', 'TextMax07','lec1'),
('Course Content', 'GenericMaxText', 'TextMax01','lec2'),
('Course Content', 'GenericMaxText', 'TextMax08','lab1'),
('Course Content', 'GenericMaxText', 'TextMax02','lab2'),
('Methods of Evaluation', 'Course', 'MathIntensityId', 'm'),
('Methods of Evaluation', 'CourseYesNo', 'YesNo07Id', 'm2')

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
DECLARE @MAX3 int = (SELECT Id FROM #SeedIds WHERE row_num = 3)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
SELECT 0 AS Value,
CASE WHEN cyn.YesNo14Id = 1
	THEN CONCAT('<span><b>Part 1 </b></span>', gmt.TextMax05, '<span><b>Part 2</b></span>')
	ELSE NULL
END AS Text
FROM Course AS c
INNER JOIN CourseYesNo AS cyn on cyn.CourseId = c.Id
INNER JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @EntityId
"

DECLARE @SQL2 NVARCHAR(MAX) = "
SELECT 0 AS Value,
CASE WHEN cyn.YesNo14Id = 1 THEN CONCAT('<span><b>Lecture Content Part 1: </b></span><br>', gmt.TextMax07, '<span><b>Lecture Content Part 2: </b></span><br>', gmt.TextMax01)
ELSE gmt.TextMax01
END AS Text
FROM Course AS c
INNER JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
INNER JOIN CourseYesNo AS cyn on cyn.CourseId = c.Id
WHERE c.Id = @EntityId
"

DECLARE @SQL3 NVARCHAR(MAX) = "
SELECT 0 AS Value,
CASE WHEN cyn.YesNo14Id = 1 THEN CONCAT('<span><b>Lab Content Part 1: </b></span><br>', gmt.TextMax08, '<span><b>Lab Content Part 2: </b></span><br>', gmt.TextMax02)
ELSE gmt.TextMax01
END AS Text
FROM Course AS c
INNER JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
INNER JOIN CourseYesNo AS cyn on cyn.CourseId = c.Id
WHERE c.Id = @EntityId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'GenericMaxText', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'Methods of Evaluation Part 1', 2),
(@MAX2, 'GenericMaxText', 'Id', 'Title', @SQL2, @SQL2, 'Order By SortOrder', 'Lecture Content', 2),
(@MAX3, 'GenericMaxText', 'Id', 'Title', @SQL3, @SQL3, 'Order By SortOrder', 'Lab Content', 2)


UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in ('m', 'm2')
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Part 1', -- [DisplayName]
8901, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
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
FROM @Fields WHERE Action = 'm'

DECLARE @Methods int = SCOPE_IDENTITY()

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
declare @textbooks nvarchar(max)
declare @manuals NVARCHAR(max)
declare @periodicals NVARCHAR(max)
declare @software NVARCHAR(max)
declare @other NVARCHAR(max)
declare @notes NVARCHAR(max)

SELECT
	@textbooks = COALESCE(@textbooks, '''') +
	CASE WHEN ListItemTypeId = 54 THEN CONCAT(''<b>'', lo1.ShortText, ''</b>: <br>'') ELSE
	CONCAT(ct.Title, '', '', Author, '', '', Publisher, '', '', CalendarYear, '','', case when IsTextbookFiveYear = 1 then ''Texts and/or readings are classics or the most recent edition is over five years old'' else '''' end, ''<br>'')
END
FROM CourseTextbook AS ct
LEFT JOIN Lookup01 AS lo1 on ct.Lookup01Id = lo1.Id
WHERE CourseId = @entityId
ORDER BY ct.SortOrder

SELECT
	@manuals = COALESCE(@manuals, '''') +
	CASE WHEN ListItemTypeId = 55 THEN CONCAT(''<b>'', lo1.ShortText, ''</b>: <br>'') ELSE
	CONCAT(cm.Title, '', '', Author, '', '', Publisher, '', '', CalendarYear, ''<br>'')
END
FROM CourseManual AS cm
LEFT JOIN Lookup01 AS lo1 on cm.Lookup01Id = lo1.Id
WHERE CourseId = @entityId
ORDER BY cm.SortOrder

SELECT
	@periodicals = COALESCE(@periodicals, '''') +
	CASE WHEN ListItemTypeId = 56 THEN CONCAT(''<b>'', lo1.ShortText, ''</b>: <br>'') ELSE
	CONCAT(cp.Title, '', '', Author, '', '', PublicationName, '', '', Volume, '', '', PublicationYear, ''<br>'')
END
FROM CoursePeriodical AS cp
LEFT JOIN Lookup01 AS lo1 on cp.Lookup01Id = lo1.Id
WHERE courseid = @entityId
ORDER By cp.SortOrder

SELECT
	@software = COALESCE(@software, '''') +
	CASE WHEN ListItemTypeId = 57 THEN CONCAT(''<b>'', lo1.ShortText, ''</b>: <br>'') ELSE
	CONCAT(cs.Title, '', '', Edition, '', '', Publisher, ''<br>'')
END
FROM CourseSoftware AS cs
LEFT JOIN Lookup01 AS lo1 on cs.Lookup01Id = lo1.Id
WHERE CourseId = @entityId
ORDER BY cs.SortOrder

SELECT
	@other = COALESCE(@other, '''') +
	CASE WHEN ListItemTypeId = 58 THEN CONCAT(''<b>'', lo1.ShortText, ''</b>: <br>'') ELSE
	CONCAT(TextOther, ''<br>'')
END
FROM CourseTextOther AS ct
LEFT JOIN Lookup01 AS lo1 on ct.Lookup01Id = lo1.Id
WHERE CourseId = @entityId
ORDER BY ct.SortOrder

SELECT
	@notes = COALESCE(@notes, '''') + 
	CASE WHEN ListItemTypeId = 59 THEN CONCAT(''<b>'', cn.Rationale, ''</b>: <br>'') ELSE
	CONCAT(Text, ''<br>'')
END
FROM CourseNote AS cn
WHERE courseid = @entityId
ORDER BY cn.SortOrder

SELECT
	0 AS Value
   ,CONCAT(
	''<b>Textbooks:</b> <br>'', @textbooks,
	''<b>Manuals: </b><br>'', @manuals,
	''<b>Periodicals: </b><br>'', @periodicals,
	''<b>Software: </b><br>'', @software,
	''<b>Other: </b><br>'', @other,
	''<b>Notes: </b><br>'', @notes
	) AS Text
'
, ResolutionSql = '
declare @textbooks nvarchar(max)
declare @manuals NVARCHAR(max)
declare @periodicals NVARCHAR(max)
declare @software NVARCHAR(max)
declare @other NVARCHAR(max)
declare @notes NVARCHAR(max)

SELECT
	@textbooks = COALESCE(@textbooks, '''') +
	CASE WHEN ListItemTypeId = 54 THEN CONCAT(''<b>'', lo1.ShortText, ''</b>: <br>'') ELSE
	CONCAT(ct.Title, '', '', Author, '', '', Publisher, '', '', CalendarYear, '','', case when IsTextbookFiveYear = 1 then ''Texts and/or readings are classics or the most recent edition is over five years old'' else '''' end, ''<br>'')
END
FROM CourseTextbook AS ct
LEFT JOIN Lookup01 AS lo1 on ct.Lookup01Id = lo1.Id
WHERE CourseId = @entityId
ORDER BY ct.SortOrder

SELECT
	@manuals = COALESCE(@manuals, '''') +
	CASE WHEN ListItemTypeId = 55 THEN CONCAT(''<b>'', lo1.ShortText, ''</b>: <br>'') ELSE
	CONCAT(cm.Title, '', '', Author, '', '', Publisher, '', '', CalendarYear, ''<br>'')
END
FROM CourseManual AS cm
LEFT JOIN Lookup01 AS lo1 on cm.Lookup01Id = lo1.Id
WHERE CourseId = @entityId
ORDER BY cm.SortOrder

SELECT
	@periodicals = COALESCE(@periodicals, '''') +
	CASE WHEN ListItemTypeId = 56 THEN CONCAT(''<b>'', lo1.ShortText, ''</b>: <br>'') ELSE
	CONCAT(cp.Title, '', '', Author, '', '', PublicationName, '', '', Volume, '', '', PublicationYear, ''<br>'')
END
FROM CoursePeriodical AS cp
LEFT JOIN Lookup01 AS lo1 on cp.Lookup01Id = lo1.Id
WHERE courseid = @entityId
ORDER By cp.SortOrder

SELECT
	@software = COALESCE(@software, '''') +
	CASE WHEN ListItemTypeId = 57 THEN CONCAT(''<b>'', lo1.ShortText, ''</b>: <br>'') ELSE
	CONCAT(cs.Title, '', '', Edition, '', '', Publisher, ''<br>'')
END
FROM CourseSoftware AS cs
LEFT JOIN Lookup01 AS lo1 on cs.Lookup01Id = lo1.Id
WHERE CourseId = @entityId
ORDER BY cs.SortOrder

SELECT
	@other = COALESCE(@other, '''') +
	CASE WHEN ListItemTypeId = 58 THEN CONCAT(''<b>'', lo1.ShortText, ''</b>: <br>'') ELSE
	CONCAT(TextOther, ''<br>'')
END
FROM CourseTextOther AS ct
LEFT JOIN Lookup01 AS lo1 on ct.Lookup01Id = lo1.Id
WHERE CourseId = @entityId
ORDER BY ct.SortOrder

SELECT
	@notes = COALESCE(@notes, '''') + 
	CASE WHEN ListItemTypeId = 59 THEN CONCAT(''<b>'', cn.Rationale, ''</b>: <br>'') ELSE
	CONCAT(Text, ''<br>'')
END
FROM CourseNote AS cn
WHERE courseid = @entityId
ORDER BY cn.SortOrder

SELECT
	0 AS Value
   ,CONCAT(
	''<b>Textbooks:</b> <br>'', @textbooks,
	''<b>Manuals: </b><br>'', @manuals,
	''<b>Periodicals: </b><br>'', @periodicals,
	''<b>Software: </b><br>'', @software,
	''<b>Other: </b><br>'', @other,
	''<b>Notes: </b><br>'', @notes
	) AS Text
'
WHERE Id = 88

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action in (
		'lec2', 'lab2'
	)
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 8902
, DefaultDisplayType = 'QueryText'
, FieldTypeId = 5
, MetaPresentationTypeId = 103
, MetaForeignKeyLookupSourceId = @MAX2
, LabelVisible = 0
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'lec1'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 8903
, DefaultDisplayType = 'QueryText'
, FieldTypeId = 5
, MetaPresentationTypeId = 103
, MetaForeignKeyLookupSourceId = @MAX3
, LabelVisible = 0
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'lab1'
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
VALUES
('ShouldDisplayCheckQuery', 'DECLARE @CCN int = (SELECT YesNo14Id FROM CourseYesNo WHERE CourseId = @EntityId)

select
	case
		when @CCN = 1 THEN 1
		else 0
	end as ShouldDisplay, null as JsonAttributes', @Methods)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select templateId FROM @Fields
UNION
SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (
	88
)
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback