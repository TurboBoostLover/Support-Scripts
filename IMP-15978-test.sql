use cinc

SELECT * FROM MetaSelectedField AS msf
INNER JOIN MetaFieldFormula AS mff on mff.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaFieldFormulaDependency AS msffd on msffd.MetaFieldFormulaId = mff.Id
INNER JOIN MetaSelectedField AS msf2 on msffd.MetaSelectedFieldId = msf2.MetaSelectedFieldId
INNER JOIN MetaAvailableField AS maf on msf2.MetaAvailableFieldId = maf.MetaAvailableFieldId
WHERE msf.MetaSelectedFieldID = 213

DECLARE @EntityId int = 13

SELECT
  0 AS Value,
    ISNULL(cd.ShortTermLabHour, 0) * 48
 AS Text
FROM CourseDescription AS cd
INNER JOIN GenericDecimal AS gd ON cd.CourseId = gd.CourseId
WHERE gd.CourseId = @EntityId




DECLARE @EntityId int = 13

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