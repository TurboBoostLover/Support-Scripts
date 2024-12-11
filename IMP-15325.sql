use NUKZ

DECLARE @MAX int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

SET QUOTED_IDENTIFIER OFF
DECLARE @SQL NVARCHAR(MAX) = "
select 0 as Value,
sum(COALESCE(coa.Decimal01,0)) + COALESCE(co.Decimal01,0)
as Text
from CourseOutcome co
    left join CourseOutcomeAssessment coa on coa.CourseOutcomeId = co.Id
	INNER JOIN Course As c on co.CourseId = c.Id
where co.Id = @contextid
AND c.Id = @entityid
GROUP BY co.Decimal01
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseOutcome', 'OtherText', 'Title', @SQL, @SQL, 'Total Assessment Weight', 3)


UPDATE MetaSelectedField
SET MetaAvailableFieldId = 528
, MetaPresentationTypeId = 1
, FieldTypeId = 5
,ReadOnly = 1
, DefaultDisplayType = 'QueryText'
, MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId = 1090

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
VALUES
('UpdateSubscriptionTable1', 'CourseOutcomeAssessment', 1090),
('UpdateSubscriptionColumn1', 'Decimal01', 1090),
('UpdateSubscriptionTable2', 'CourseOutcome', 1090),
('UpdateSubscriptionColumn2', 'Decimal01', 1090)

UPDATE MetaSqlStatement
SET SqlStatement = '
SELECT 
	CASE
		WHEN SUM(text) =100
		THEN 1
		ELSE 0
	END
		FROM (
select sum(COALESCE(coa.Decimal01,0)) + COALESCE(co.Decimal01,0)
as Text
from CourseOutcome co
    left join CourseOutcomeAssessment coa on coa.CourseOutcomeId = co.Id
	INNER JOIN Course As c on co.CourseId = c.Id
WHERE c.Id = @entityid
GROUP BY co.Decimal01) a
'
WHERE Id = 9

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId = 1