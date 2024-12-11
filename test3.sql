DECLARE @Sections2 TABLE (SectionId int, TemplateId int)
INSERT INTO @Sections2
SELECT mss2.MetaSelectedSectionId, mss2.MetaTemplateId 
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 5314


DECLARE @Rules TABLE (SectionId int, RuleId int, id int)
INSERT INTO @Rules
SELECT mds.MetaselectedSectionId, mds.MetaDisplayRuleId, mds.Id
FROM MetaDisplaySubscriber AS mds
INNER JOIN @Sections2 AS s ON mds.MetaSelectedSectionId = s.SectionId
ORDER BY mds.MetaselectedSectionId

DECLARE @3 INTEGERS
INSERT INTO @3
SELECT SectionId FROM @Rules
group by SectionId
having COUNT(SectionId) > 2
order by SectionId

DECLARE @2 INTEGERS
INSERT INTO @2
SELECT SectionId FROM @Rules
group by SectionId
having COUNT(SectionId) > 1
order by SectionId

SELECT * FROM @3

DECLARE @New TABLE (SectionId int, TemplateId int, rowpos int, sort int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId, inserted.RowPosition, inserted. SortOrder INTO @New
SELECT
49, -- [ClientId]
[MetaSelectedSection_MetaSelectedSectionId],
'Fix show/hide', -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
RowPosition, -- [RowPosition]
SortOrder, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
[MetaTemplateId],
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM MetaSelectedSection As mss
INNER JOIN @2 AS a on mss.MetaSelectedSectionId = a.Id

UPDATE mss
SET MetaSelectedSection_MetaSelectedSectionId = n.SectionId
FROM MetaSelectedSection as mss
INNER JOIN @2 AS a on mss.MetaSelectedSectionId = a.Id
INNER JOIN @New As n on mss.RowPosition = n.rowpos and mss.SortOrder = n.sort and mss.MetaTemplateId = n.TemplateId

DECLARE @MOVE TABLE (oldId int, ruleid int, templateId int, ruleId2 int)
INSERT INTO @MOVE
SELECT oldId, ruleid, templateId, ruleId2
FROM (
    SELECT s.Id AS oldId, r.RuleId AS ruleid, mss.MetaTemplateId AS templateId, r.Id AS ruleId2,
           ROW_NUMBER() OVER(PARTITION BY mss.MetaSelectedSectionId ORDER BY (SELECT NULL)) AS rn
    FROM MetaSelectedSection AS mss
    INNER JOIN @2 as s ON mss.MetaSelectedSectionId = s.Id
    INNER JOIN @Rules AS r ON mss.MetaSelectedSectionId = r.SectionId
) AS sub
WHERE rn = 1


UPDATE mds
SET MetaSelectedSectionId = n.SectionId
FROM MetaDisplaySubscriber AS mds
INNER JOIN MetaSelectedSection AS mss on mds.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @2 AS a on mss.MetaSelectedSectionId = a.Id
INNER JOIN @New As n on mss.RowPosition = n.rowpos and mss.SortOrder = n.sort and mss.MetaTemplateId = n.TemplateId
INNER JOIN @MOVE AS m on mds.Id = m.ruleId2