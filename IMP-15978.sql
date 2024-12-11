use cinc

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, FieldTypeId = 5
, ReadOnly = 1
, DefaultDisplayType = 'QueryText'
WHERE MetaSelectedFieldId  in (
	SELECT MetaSelectedFieldId FROM MetaFieldFormula WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.MetaSelectedSection_MetaSelectedSectionId = 4
	)
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
DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)
DECLARE @MAX3 int = (SELECT Id FROM #SeedIds WHERE row_num = 3)
DECLARE @MAX4 int = (SELECT Id FROM #SeedIds WHERE row_num = 4)
DECLARE @MAX5 int = (SELECT Id FROM #SeedIds WHERE row_num = 5)
DECLARE @MAX6 int = (SELECT Id FROM #SeedIds WHERE row_num = 6)
DECLARE @MAX7 int = (SELECT Id FROM #SeedIds WHERE row_num = 7)
DECLARE @MAX8 int = (SELECT Id FROM #SeedIds WHERE row_num = 8)
DECLARE @MAX9 int = (SELECT Id FROM #SeedIds WHERE row_num = 9)
DECLARE @MAX10 int = (SELECT Id FROM #SeedIds WHERE row_num = 10)
DECLARE @MAX11 int = (SELECT Id FROM #SeedIds WHERE row_num = 11)
DECLARE @MAX12 int = (SELECT Id FROM #SeedIds WHERE row_num = 12)
DECLARE @MAX13 int = (SELECT Id FROM #SeedIds WHERE row_num = 13)
DECLARE @MAX14 int = (SELECT Id FROM #SeedIds WHERE row_num = 14)
DECLARE @MAX15 int = (SELECT Id FROM #SeedIds WHERE row_num = 15)
DECLARE @MAX16 int = (SELECT Id FROM #SeedIds WHERE row_num = 16)
DECLARE @MAX17 int = (SELECT Id FROM #SeedIds WHERE row_num = 17)
DECLARE @MAX18 int = (SELECT Id FROM #SeedIds WHERE row_num = 18)
DECLARE @MAX19 int = (SELECT Id FROM #SeedIds WHERE row_num = 19)

SET QUOTED_IDENTIFIER OFF

DECLARE @1SQL NVARCHAR(MAX) = "
SELECT 0 as Value,
gd.Decimal12 * 48 AS Text
FROM GenericDecimal AS gd
WHERE gd.CourseId = @EntityId
"

DECLARE @2SQL NVARCHAR(MAX) = "
SELECT 0 as Value,
  CASE
    WHEN cyn.YesNo07Id = 1
      THEN
        CASE
          WHEN ISNULL(gd.Decimal15, 0) = 0 THEN 0
          ELSE gd.Decimal15 * 54
        END
    ELSE
      CASE
        WHEN ISNULL(gd.Decimal12, 0) = 0 THEN 0
        ELSE gd.Decimal12 * 48
      END
  END AS Text
FROM GenericDecimal AS gd
INNER JOIN CourseYesNo AS cyn ON cyn.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @3SQL NVARCHAR(MAX) = "
SELECT 0 as Value,
gd.Decimal13 * 48 AS Text
FROM GenericDecimal AS gd
WHERE gd.CourseId = @EntityId
"

DECLARE @4SQL NVARCHAR(MAX) = "
SELECT 0 as Value,
  CASE
    WHEN cyn.YesNo07Id = 1
      THEN
        CASE
          WHEN ISNULL(gd.Decimal16, 0) = 0 THEN 0
          ELSE gd.Decimal16 * 54
        END
    ELSE
      CASE
        WHEN ISNULL(gd.Decimal13, 0) = 0 THEN 0
        ELSE gd.Decimal13 * 48
      END
  END AS Text
FROM GenericDecimal AS gd
INNER JOIN CourseYesNo AS cyn ON cyn.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @5SQL NVARCHAR(MAX) = "
SELECT 0 AS Value,
MAX(
    (
        (ISNULL(gd.Decimal11, 0) * 36)
        + (ISNULL(gd.Decimal12, 0) * 48)
        + (ISNULL(cd.ShortTermLabHour, 0) * 24)
    )
) AS Text
FROM CourseDescription AS cd
INNER JOIN GenericDecimal AS gd ON cd.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @6SQL NVARCHAR(MAX) = "
SELECT 0 AS Value,
  CASE
    WHEN cyn.YesNo07Id = 1
    THEN
      ISNULL(
        (ISNULL(gd.Decimal14, 0) * 36) + (ISNULL(gd.Decimal15, 0) * 54) + (ISNULL(cd.ShortTermLectureHour, 0) * 27),
        0
      )
  ELSE
    0
  END AS Text
FROM GenericDecimal AS gd
INNER JOIN CourseDescription AS cd ON cd.CourseId = gd.CourseId
INNER JOIN CourseYesNo AS cyn ON cyn.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @7SQL NVARCHAR(MAX) = "
SELECT
  0 AS Value,
  ISNULL(gd.Decimal14, 0) + ISNULL(gd.Decimal15, 0) + ISNULL(gd.Decimal16, 0) + ISNULL(cd.ShortTermLectureHour, 0) AS Text
FROM CourseDescription AS cd
INNER JOIN GenericDecimal AS gd ON cd.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @8SQL NVARCHAR(MAX) = "
SELECT
  0 AS Value,
  CASE
    WHEN cyn.YesNo07Id = 1
    THEN
      ISNULL(gd.Decimal14, 0) * 36
    ELSE
      0
  END AS Text
FROM GenericDecimal AS gd
INNER JOIN CourseDescription AS cd ON cd.CourseId = gd.CourseId
INNER JOIN CourseYesNo AS cyn ON cyn.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId

"

DECLARE @9SQL NVARCHAR(MAX) = "
SELECT
  0 AS Value,
  ISNULL(gd.Decimal11, 0) * 36 AS Text
FROM CourseDescription AS cd
INNER JOIN GenericDecimal AS gd ON cd.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId

"

DECLARE @10SQL NVARCHAR(MAX) = "
SELECT
  0 AS Value,
  (
    ISNULL(gd.Decimal11, 0) * 18
    + ISNULL(gd.Decimal13, 0) * 48
    + ISNULL(cd.ShortTermLabHour, 0) * 48
  ) AS Text
FROM CourseDescription AS cd
INNER JOIN GenericDecimal AS gd ON cd.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @11SQL NVARCHAR(MAX) = "
SELECT
  0 AS Value,
  CASE
    WHEN cyn.YesNo07Id = 1
    THEN
      (ISNULL(gd.Decimal14, 0) * 18) + (ISNULL(gd.Decimal16, 0) * 54) + (ISNULL(cd.ShortTermLectureHour, 0) * 54)
    ELSE
      0
  END AS Text
FROM GenericDecimal AS gd
INNER JOIN CourseDescription AS cd ON cd.CourseId = gd.CourseId
INNER JOIN CourseYesNo AS cyn ON cyn.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @12SQL NVARCHAR(MAX) = "
SELECT
  0 AS Value,
  CASE
    WHEN cyn.YesNo07Id = 1
    THEN
      ISNULL(gd.Decimal14, 0) * 18
      + ISNULL(gd.Decimal15, 0) * 54
      + ISNULL(gd.Decimal16, 0) * 54
      + ISNULL(cd.ShortTermLectureHour, 0) * 54
      + ISNULL(cd.ShortTermLectureHour, 0) * 27
    ELSE
      0
  END AS Text
FROM GenericDecimal AS gd
INNER JOIN CourseDescription AS cd ON cd.CourseId = gd.CourseId
INNER JOIN CourseYesNo AS cyn ON cyn.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @13SQL NVARCHAR(MAX) = "
SELECT
  0 AS Value,
  (
    ISNULL(gd.Decimal11, 0) * 18
    + ISNULL(gd.Decimal11, 0) * 36
    + ISNULL(gd.Decimal12, 0) * 48
    + ISNULL(gd.Decimal13, 0) * 48
    + ISNULL(cd.ShortTermLabHour, 0) * 48
    + ISNULL(cd.ShortTermLabHour, 0) * 24
  ) AS Text
FROM CourseDescription AS cd
INNER JOIN GenericDecimal AS gd ON cd.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @14SQL NVARCHAR(MAX) = "
SELECT
  0 AS Value,
    ISNULL(cd.ShortTermLabHour, 0) * 48
 AS Text
FROM CourseDescription AS cd
INNER JOIN GenericDecimal AS gd ON cd.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @15SQL NVARCHAR(MAX) = "
SELECT
  0 AS Value,
  CASE
    WHEN cyn.YesNo07Id = 1
    THEN
    ISNULL(cd.ShortTermLectureHour, 0) * 54
    ELSE
      0
  END AS Text
FROM GenericDecimal AS gd
INNER JOIN CourseDescription AS cd ON cd.CourseId = gd.CourseId
INNER JOIN CourseYesNo AS cyn ON cyn.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId
"

DECLARE @16SQL NVARCHAR(MAX) = "

"

DECLARE @17SQL NVARCHAR(MAX) = "

"

DECLARE @18SQL NVARCHAR(MAX) = "

"

DECLARE @19SQL NVARCHAR(MAX) = "

"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, '', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', '', 2)




UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8913
, MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId = 16

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8914
, MetaForeignKeyLookupSourceId = @MAX2
WHERE MetaSelectedFieldId = 17

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8915
, MetaForeignKeyLookupSourceId = @MAX3
WHERE MetaSelectedFieldId = 19

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8916
, MetaForeignKeyLookupSourceId = @MAX4
WHERE MetaSelectedFieldId = 20

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8917
, MetaForeignKeyLookupSourceId = @MAX5
WHERE MetaSelectedFieldId = 23

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8918
, MetaForeignKeyLookupSourceId = @MAX6
WHERE MetaSelectedFieldId = 24

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8919
, MetaForeignKeyLookupSourceId = @MAX7
WHERE MetaSelectedFieldId = 26

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8920
, MetaForeignKeyLookupSourceId = @MAX8
WHERE MetaSelectedFieldId = 189

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8921
, MetaForeignKeyLookupSourceId = @MAX9
WHERE MetaSelectedFieldId = 190

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8922
, MetaForeignKeyLookupSourceId = @MAX10
WHERE MetaSelectedFieldId = 193

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8923
, MetaForeignKeyLookupSourceId = @MAX11
WHERE MetaSelectedFieldId = 194

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8924
, MetaForeignKeyLookupSourceId = @MAX12
WHERE MetaSelectedFieldId = 195

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8925
, MetaForeignKeyLookupSourceId = @MAX13
WHERE MetaSelectedFieldId = 196

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8926
, MetaForeignKeyLookupSourceId = @MAX14
WHERE MetaSelectedFieldId = 212

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8927
, MetaForeignKeyLookupSourceId = @MAX15
WHERE MetaSelectedFieldId = 213

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8928
, MetaForeignKeyLookupSourceId = @MAX16
WHERE MetaSelectedFieldId = 214

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8929
, MetaForeignKeyLookupSourceId = @MAX17
WHERE MetaSelectedFieldId = 215

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8930
, MetaForeignKeyLookupSourceId = @MAX18
WHERE MetaSelectedFieldId = 372

UPDAte MetaSelectedField
SET MetaAvailableFieldId = 8931
, MetaForeignKeyLookupSourceId = @MAX19
WHERE MetaSelectedFieldId = 374