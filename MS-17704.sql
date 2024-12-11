USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17704';
DECLARE @Comments nvarchar(Max) = 
	'Update COR for Non-credit Courses';
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
DECLARE @SQL NVARCHAR(MAX) = '
SELECT 
		CASE 
			WHEN cyn.YesNo05Id = 1  -- Override
			THEN CONCAT
				(
				COALESCE(FORMAT(cd.MinContactHoursClinical, ''0.####''), 0), 
				'' - '', 
				COALESCE(FORMAT(cd.MaxContactHoursClinical, ''0.###''), 0)
				)
			WHEN cyn.YesNo14Id = 1 -- Variable
			THEN CONCAT
				(
				FORMAT(cd.ShortTermLabHour * 16, ''0.###''), 
				'' - '', 
				FORMAT(cd.SemesterHour * 18, ''0.###'')
				)
			ELSE CONCAT
				(
				COALESCE(FORMAT(cd.ShortTermLabHour * 16, ''0.###''), cd.MinClinicalHour), 
				'' - '', 
				COALESCE(FORMAT(cd.ShortTermLabHour * 18, ''0.###''), cd.MaxClinicalHour)
				)
		END AS Text
	FROM Course c
		LEFT JOIN CourseDescription cd ON cd.CourseId = c.Id
		LEFT JOIN CourseYesNo cyn ON cyn.CourseId = c.Id
		LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
	WHERE c.Id = @entityId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 124

DECLARE @SQL2 NVARCHAR(MAX) = '
SELECT
	CASE 
		WHEN cyn.YesNo05Id = 1 -- Override
		THEN CONCAT
			(
			COALESCE(FORMAT(cd.MinContactHoursLecture, ''0.####''), 0), 
			'' - '', 
			COALESCE(FORMAT(cd.MaxContactHoursLecture, ''0.###''), 0)
			)
		WHEN cyn.YesNo14Id = 1 -- Is Variable 
		THEN CONCAT
			(
			COALESCE(FORMAT(cd.MinLabHour * 48, ''0.###''), 0), 
			'' - '', 
			COALESCE(FORMAT(cd.MaxLabHour * 54, ''0.###''), 0)
			)
		ELSE CONCAT
			(
			COALESCE(FORMAT(cd.MinLabHour * 48, ''0.###''), cd.MinLabLecHour),
			'' - '', 
			COALESCE(FORMAT(cd.MinLabHour * 54, ''0.###''), cd.MaxLabLecHour)
			)
	END AS Text
FROM Course c
	LEFT JOIN CourseDescription cd ON cd.CourseId = c.Id
	LEFT JOIN CourseYesNo cyn ON cyn.CourseId = c.Id
WHERE c.Id = @entityId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 125

DECLARE @Field1 int = (SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId WHERE mt.MetaTemplateTypeId = 4 and msf.MetaAvailableFieldId = 8979)
DECLARE @Field2 int = (SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId WHERE mt.MetaTemplateTypeId = 4 and msf.MetaAvailableFieldId = 8980)
DECLARE @Field3 int = (SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId WHERE mt.MetaTemplateTypeId = 4 and msf.MetaAvailableFieldId = 8981)
DECLARE @Field4 int = (SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId WHERE mt.MetaTemplateTypeId = 4 and msf.MetaAvailableFieldId = 8982 and DisplayName like '%student%')
DECLARE @Section1 int = (SELECT mss.MetaSelectedSectionId FROM MetaSelectedField AS msf INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId WHERE mt.MetaTemplateTypeId = 4 and msf.MetaAvailableFieldId = 11510)
DECLARE @Section2 int = (SELECT mss.MetaSelectedSectionId FROM MetaSelectedField AS msf INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId WHERE mt.MetaTemplateTypeId = 4 and msf.MetaAvailableFieldId = 8979)
DECLARE @Section3 int = (SELECT mss.MetaSelectedSectionId FROM MetaSelectedField AS msf INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId WHERE mt.MetaTemplateTypeId = 4 and msf.MetaAvailableFieldId = 8965)
DECLARE @Tab int = (SELECT mss.MetaSelectedSection_MetaSelectedSectionId FROM MetaSelectedField AS msf INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId WHERE mt.MetaTemplateTypeId = 4 and msf.MetaAvailableFieldId = 8965)

DECLARE @Field5 int = (SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId WHERE mt.MetaTemplateTypeId = 4 and msf.MetaAvailableFieldId = 8977)
DECLARE @Field6 int = (SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId WHERE mt.MetaTemplateTypeId = 4 and msf.MetaAvailableFieldId = 8978)

INSERT INTO MetaSelectedFieldAttribute
(MetaSelectedFieldId, Name, Value)
SELECT @Field1, 'ShouldDisplayCheckQuery', 'SELECT CAST(CASE
	WHEN ISNULL(Cb.CB04Id, 1) <> 3
	THEN 1
	ELSE 0
END as bit) as ShouldDisplay, null as JsonAttributes
FROM Course AS c
LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
WHERE c.Id = @EntityId'
UNION
SELECT @Field2, 'ShouldDisplayCheckQuery', 'SELECT CAST(CASE
	WHEN ISNULL(Cb.CB04Id, 1) <> 3
	THEN 1
	ELSE 0
END as bit) as ShouldDisplay, null as JsonAttributes
FROM Course AS c
LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
WHERE c.Id = @EntityId'
UNION
SELECT @Field3, 'ShouldDisplayCheckQuery', 'SELECT CAST(CASE
	WHEN ISNULL(Cb.CB04Id, 1) <> 3
	THEN 1
	ELSE 0
END as bit) as ShouldDisplay, null as JsonAttributes
FROM Course AS c
LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
WHERE c.Id = @EntityId'
UNION
SELECT @Field4, 'ShouldDisplayCheckQuery', 'SELECT CAST(CASE
	WHEN ISNULL(Cb.CB04Id, 1) <> 3
	THEN 1
	ELSE 0
END as bit) as ShouldDisplay, null as JsonAttributes
FROM Course AS c
LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
WHERE c.Id = @EntityId'
UNION
SELECT @Field5, 'ShouldDisplayCheckQuery', '
DECLARE @txt NVARCHAR(MAX) = (
SELECT 
		CASE 
			WHEN cyn.YesNo05Id = 1  -- Override
			THEN CONCAT
				(
				COALESCE(FORMAT(cd.MinContactHoursClinical, ''0.####''), 0), 
				'' - '', 
				COALESCE(FORMAT(cd.MaxContactHoursClinical, ''0.###''), 0)
				)
			WHEN cyn.YesNo14Id = 1 -- Variable
			THEN CONCAT
				(
				FORMAT(cd.ShortTermLabHour * 16, ''0.###''), 
				'' - '', 
				FORMAT(cd.SemesterHour * 18, ''0.###'')
				)
			ELSE CONCAT
				(
				COALESCE(FORMAT(cd.ShortTermLabHour * 16, ''0.###''), cd.MinClinicalHour), 
				'' - '', 
				COALESCE(FORMAT(cd.ShortTermLabHour * 18, ''0.###''), cd.MaxClinicalHour)
				)
		END AS Text
	FROM Course c
		LEFT JOIN CourseDescription cd ON cd.CourseId = c.Id
		LEFT JOIN CourseYesNo cyn ON cyn.CourseId = c.Id
		LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
	WHERE c.Id = @entityId
)

SELECT CAST(CASE
	WHEN LEN(@txt) > 3
	THEN 1
	ELSE 0
END as bit) as ShouldDisplay, null as JsonAttributes
FROM Course AS c
LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
WHERE c.Id = @EntityId
'
UNION
SELECT @Field6, 'ShouldDisplayCheckQuery', '
DECLARE @txt NVARCHAR(MAX) = (

SELECT
	CASE 
		WHEN cyn.YesNo05Id = 1 -- Override
		THEN CONCAT
			(
			COALESCE(FORMAT(cd.MinContactHoursLecture, ''0.####''), 0), 
			'' - '', 
			COALESCE(FORMAT(cd.MaxContactHoursLecture, ''0.###''), 0)
			)
		WHEN cyn.YesNo14Id = 1 -- Is Variable 
		THEN CONCAT
			(
			COALESCE(FORMAT(cd.MinLabHour * 48, ''0.###''), 0), 
			'' - '', 
			COALESCE(FORMAT(cd.MaxLabHour * 54, ''0.###''), 0)
			)
		ELSE CONCAT
			(
			COALESCE(FORMAT(cd.MinLabHour * 48, ''0.###''), cd.MinLabLecHour),
			'' - '', 
			COALESCE(FORMAT(cd.MinLabHour * 54, ''0.###''), cd.MaxLabLecHour)
			)
	END AS Text
FROM Course c
	LEFT JOIN CourseDescription cd ON cd.CourseId = c.Id
	LEFT JOIN CourseYesNo cyn ON cyn.CourseId = c.Id
WHERE c.Id = @entityId

)

SELECT CAST(CASE
	WHEN LEN(@txt) > 3
	THEN 1
	ELSE 0
END as bit) as ShouldDisplay, null as JsonAttributes
FROM Course AS c
LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
WHERE c.Id = @EntityId
'

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 1
WHERE MetaSelectedSectionId in (
	 @Section2, @Section3
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 500
WHERE MetaSelectedSectionId in (
	 @Section1
)

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
VALUES
('TitleTable', 'CourseGoal', @Section1),
('TitleColumn', 'Goal', @Section1),
('SortOrderTable', 'CourseGoal', @Section1),
('SortOrderColumn', 'SortOrder', @Section1)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 15
WHERE MetaSelectedSectionId in (
	@Tab
)

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

DECLARE @SQL5 NVARCHAR(MAX) = "
SELECT
CONCAT(
cd.MinLectureHour, CASE WHEN cd.MaxLectureHour IS NOT NULL and cd.MaxLectureHour <> 0 and cd.MaxLectureHour <> cd.MinLectureHour THEN CONCAT (' - ', cd.MaxLectureHour) ELSE '' END
) AS Text
FROM Course c
	LEFT JOIN CourseDescription cd ON cd.CourseId = c.Id
	Left JOIN CourseCBCode AS cb on cb.CourseId = c.Id
WHERE c.Id = @entityId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseDetail', 'Id', 'Title', @SQL5, @SQL5, 'Order By SortOrder', 'Lab/Lec hours', 2)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'TOTAL LECTURE/LAB HOURS:', -- [DisplayName]
8986, -- [MetaAvailableFieldId]
@Section2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
16, -- [RowPosition]
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
)

DECLARE @NewField int = SCOPE_IDENTITY()

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
VALUES
('ShouldDisplayCheckQuery', 'DECLARE @txt NVARCHAR(MAX) = (
SELECT
CONCAT(
cd.MinLectureHour, CASE WHEN cd.MaxLectureHour IS NOT NULL and cd.MaxLectureHour <> 0 and cd.MaxLectureHour <> cd.MinLectureHour THEN CONCAT ('' - '', cd.MaxLectureHour) ELSE '''' END
) AS Text
FROM Course c
	LEFT JOIN CourseDescription cd ON cd.CourseId = c.Id
	Left JOIN CourseCBCode AS cb on cb.CourseId = c.Id
WHERE c.Id = @entityId
)

SELECT CAST(CASE
	WHEN LEN(@txt) > 3
	THEN 1
	ELSE 0
END as bit) as ShouldDisplay, null as JsonAttributes
FROM Course AS c
LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
WHERE c.Id = @EntityId', @NewField)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (
 125, 124
	)
)