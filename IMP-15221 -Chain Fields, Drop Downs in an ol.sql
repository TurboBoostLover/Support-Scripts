SET XACT_ABORT ON
BEGIN TRAN
--commit
DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId = 974

INSERT INTO MetaSelectedFieldAttribute (Name,Value,MetaSelectedFieldId)
VALUES
('FilterSubscriptionTable', 'GenericOrderedList01', 974),
('FilterSubscriptionColumn', 'Related_ProgramId', 974),
('FilterTargetTable', 'GenericOrderedList01', 974),
('FilterTargetColumn', 'ProgramOutcomeId', 974)


DECLARE @Mfcid int = (SELECT MAX(id) FROM MetaForeignKeyCriteriaClient) + 1

DECLARE @SQL NVARCHAR(MAX)	='SELECT Id AS Value,
		coalesce(EntityTitle, Title) AS Text
		FROM Program
		WHERE Active = 1'

DECLARE @SQL3 NVARCHAR(MAX) ='
SELECT coalesce(EntityTitle, Title) AS Text
		FROM Program
		WHERE Id = @Id
'


DECLARE @SQL2 NVARCHAR(MAX)	=	'SELECT Id AS Value, 
		Outcome AS Text,
		ProgramId as FilterValue
		FROM ProgramOutcome 
		WHERE Active = 1'

DECLARE @SQL4 NVARCHAR(MAX) ='
SELECT Outcome AS Text
		FROM ProgramOutcome
		WHERE Id = @Id
'
		
INSERT INTO MetaForeignKeyCriteriaClient
(Id,TableName,DefaultValueColumn,DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@Mfcid, 'GenericOrderedList01','Title', 'Id', @SQL, @SQL3, NULL, 'TestProgramDropDown', 2),
(@Mfcid + 1, 'GenericOrderedList01','Outcome', 'Id', @SQL2, @SQL4, NULL, 'TestProgramDropDown', 3)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @Mfcid
WHERE MetaSelectedFieldId = 973

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @Mfcid+1
WHERE MetaSelectedFieldId = 974

UPDATE MetaTemplate
SET LastUpdatedDate= GETDATE()
WHERE MetaTemplateId = 1

UPDATE ListItemType
SET Title = 'Program Outcome'
, ListItemTitleColumn = 'Related_ProgramId'
WHERE Id = 29

SELECT * FROM MetaSelectedSection WHERE MetaSelectedSectionId in (433, 436)
SELECT * FROM MetaSelectedField WHERE MetaSelectedFieldId in (973, 974)

DELETE FROM GenericOrderedList01
WHERE Id = 3

UPDATE MetaSelectedField
SET FieldTypeId = 5
WHERE MetaSelectedFieldId in (973, 974)
