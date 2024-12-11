use Cuesta

DECLARE @ID int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "

select 0 as Value,
CONCAT(
CASE 
  WHEN gb.Bit01 = 1 THEN 'Lab, '
  ELSE ''
END, 
CASE 
  WHEN gb.Bit02 = 1 THEN 'Lecture, '
  ELSE ''
END,
CASE 
  WHEN gb.Bit05 = 1 THEN 'Activity, '
  ELSE ''
END, 
CASE 
  WHEN gb.Bit21 = 1 THEN 'Distance Education, '
  ELSE ''
END, 
CASE 
  WHEN gb.Bit22 = 1 THEN 'Correspondence Education, '
  ELSE ''
END, 
CASE 
  WHEN gb.Bit23 = 1 THEN 'Work Experience, '
  ELSE ''
END, 
CASE 
  WHEN gb.Bit24 = 1 THEN 'Directed Study, '
  ELSE ''
END,
CASE 
  WHEN gb.Bit04 = 1 THEN 'Field Trips, '
  ELSE ''
END, 
CASE 
  WHEN gb.Bit25 = 1 THEN 'Field Experience, '
  ELSE ''
END, 
CASE 
  WHEN gb.Bit26 = 1 THEN 'Tutor Non-credit, '
  ELSE ''
END, 
CASE 
  WHEN gb.Bit27 = 1 THEN 'DE Synchronous, '
  ELSE ''
END, 
CASE 
  WHEN gb.Bit28 = 1 THEN 'DE Asynchronous, '
  ELSE ''
END, 
CASE 
  WHEN gb.Bit17 = 1 THEN 'Lecture/Lab '
  ELSE ''
END
)
as Text
FROM 
Course AS c
INNER JOIN GenericBit AS gb ON gb.CourseId = c.Id
WHERE c.Id = @EntityId

"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@ID ,'CourseQueryText', 'Id', 'Title', @SQL, @SQL, NULL, 'Methods of Instruction', 2)


UPDATE MetaSelectedField
SET LabelVisible = 0
, MetaPresentationTypeId = 103
, FieldTypeId = 5
, ReadOnly = 1
, DefaultDisplayType = 'QueryText'
WHERE MetaSelectedFieldId = 14391

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId = 71

SELECT * FROM MetaForeignKeyCriteriaClient

UPDATE MetaForeignKeyCriteriaClient
SET ResolutionSql = 'select null'
WHERE Id = 56174201

SELECT * FROM MetaPresentationType