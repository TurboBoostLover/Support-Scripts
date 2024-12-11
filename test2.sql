use sbccd

-- Create a temporary table to hold the results
CREATE TABLE #TempTable (
    ID INT IDENTITY(1,1), -- Identity column for insertion order
    MetaSelectedSectionId INT,
    SectionName NVARCHAR(MAX),
    ParentSectionId INT,
    LevelName NVARCHAR(MAX),
    TemplateId INT,
    RowPosition INT
);

-- Your recursive CTE
WITH SectionHierarchy AS (
    -- Anchor member: select top-level sections
    SELECT
        MetaSelectedSectionId,
        ISNULL(SectionName, 'NO SECTION NAME') AS SectionName,
        MetaSelectedSection_MetaSelectedSectionId AS ParentSectionId,
        ISNULL(SectionName, 'NO SECTION NAME') AS Path,
        CONCAT(ISNULL(SectionName, 'NO SECTION NAME'), ' - Top Level') AS LevelName,
        mt.MetaTemplateId AS TemplateId,
        mss.RowPosition, -- Include RowPosition
        0 AS Level,
        ROW_NUMBER() OVER (PARTITION BY MetaSelectedSection_MetaSelectedSectionId ORDER BY mss.RowPosition) AS ParentOrder
    FROM
        MetaSelectedSection AS mss
    INNER JOIN 
        MetaTemplate AS mt ON mss.MetaTemplateId = mt.MetaTemplateId
    INNER JOIN 
        MetaTemplateType AS mtt ON mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
    WHERE
        MetaSelectedSection_MetaSelectedSectionId IS NULL
        AND mtt.IsPresentationView = 0
        AND mtt.Active = 1
        AND mt.Active = 1

    UNION ALL

    -- Recursive member: select child sections
    SELECT
        mss.MetaSelectedSectionId,
        ISNULL(mss.SectionName, 'NO SECTION NAME') AS SectionName,
        mss.MetaSelectedSection_MetaSelectedSectionId AS ParentSectionId,
        CONCAT(parent.Path, ' -> ', ISNULL(mss.SectionName, 'NO SECTION NAME')) AS Path,
        CONCAT(parent.LevelName, ' -> ', ISNULL(mss.SectionName, 'NO SECTION NAME')) AS LevelName,
        parent.TemplateId,
        mss.RowPosition, -- Include RowPosition
        parent.Level + 1 AS Level,
        parent.ParentOrder
    FROM
        MetaSelectedSection AS mss
    INNER JOIN
        SectionHierarchy AS parent ON mss.MetaSelectedSection_MetaSelectedSectionId = parent.MetaSelectedSectionId
)

--Insert into the temporary table
INSERT INTO #TempTable (MetaSelectedSectionId, SectionName, ParentSectionId, LevelName, TemplateId, RowPosition)
SELECT
    MetaSelectedSectionId,
    SectionName,
    ParentSectionId,
    LevelName,
    TemplateId,
    RowPosition -- Include RowPosition
FROM
    SectionHierarchy
ORDER BY
    TemplateId, -- Group by MetaTemplateId
    ParentOrder, -- Order by ParentOrder to get parents first
    RowPosition; -- Then order by RowPosition within each level

 --Select from the temporary table
--SELECT ID, MetaSelectedSectionId FROM #TempTable AS t order by t.ID; -- Order by the identity column

DECLARE @TABLE2 TABLE (orders int, fieldId int, formulaId int)
INSERT INTO @TABLE2
SELECT t.Id, msf.MetaSelectedFieldId, mff.Id FROM MetaFieldFormula AS mff
INNER JOIN MetaSelectedField AS msf on mff.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN #TempTable AS t on msf.MetaSelectedSectionId = t.MetaSelectedSectionId
order by t.ID --order


DECLARE @TABLE3 TABLE (orders int, fieldId int, formulaId int)
INSERT INTO @TABLE3
SELECT t.Id, msf.MetaSelectedFieldId, mffd.MetaFieldFormulaId FROM MetaFieldFormulaDependency AS mffd
INNER JOIN MetaSelectedField As msf on mffd.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN #TempTable AS t on msf.MetaSelectedSectionId = t.MetaSelectedSectionId
order by t.Id

IF EXISTS (
    SELECT 1
    FROM @TABLE2 AS t2
    INNER JOIN @TABLE3 AS t3 ON t2.formulaId = t3.formulaId
    WHERE t3.orders > t2.orders
)
BEGIN
    SELECT 
        CONVERT(NVARCHAR(MAX), t2.orders) AS [Field Order], 
        CONVERT(NVARCHAR(MAX), t2.fieldId) AS [Field Id], 
        CONVERT(NVARCHAR(MAX), t3.orders) AS [Dependencies order], 
        CONVERT(NVARCHAR(MAX), t3.fieldId) AS [Dependencies FieldId], 
        CONVERT(NVARCHAR(MAX), t2.formulaId) AS [FormulaId],
				mt.MetaTemplateId AS [TemplateId],
				mss2.SectionName AS [Tab Name or Section Name],
				msf.DisplayName AS [Field Name]
    FROM @TABLE2 AS t2
    INNER JOIN @TABLE3 AS t3 ON t2.formulaId = t3.formulaId
		INNER JOIN MetaSelectedField AS msf on t2.fieldId = msf.MetaSelectedFieldId
		INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
		INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
		INNER JOIN MetaTemplate As mt on mss.MetaTemplateId = mt.MetaTemplateId
		INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
    WHERE t3.orders > t2.orders
    ORDER BY t2.fieldId
END
ELSE
BEGIN
    SELECT 'Pass' AS [Result]
END
-- Drop the temporary table
DROP TABLE #TempTable;