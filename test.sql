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
        0 AS Level
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
        parent.Level + 1 AS Level
    FROM
        MetaSelectedSection AS mss
    INNER JOIN
        SectionHierarchy AS parent ON mss.MetaSelectedSection_MetaSelectedSectionId = parent.MetaSelectedSectionId
)
-- Insert into the temporary table with correct insertion order
INSERT INTO #TempTable (MetaSelectedSectionId, SectionName, ParentSectionId, LevelName, TemplateId, RowPosition)
SELECT
    MetaSelectedSectionId,
    SectionName,
    ParentSectionId,
    LevelName,
    TemplateId,
    RowPosition -- Include RowPosition
FROM
    (
        SELECT
            MetaSelectedSectionId,
            SectionName,
            ParentSectionId,
            LevelName,
            TemplateId,
            RowPosition,
            ROW_NUMBER() OVER (ORDER BY TemplateId, Level, RowPosition) AS InsertOrder
        FROM
            SectionHierarchy
    ) AS InsertionOrder
ORDER BY
    InsertOrder;

-- Select from the temporary table
SELECT * FROM #TempTable order by ID;

-- Drop the temporary table
DROP TABLE #TempTable;
