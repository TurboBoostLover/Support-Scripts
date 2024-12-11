use chaffey




DECLARE @Formulas2 TABLE (formulaId int, TempId int)
INSERT INTO @Formulas2
	SELECT mff.Id, mt.MetaTemplateId FROM MetaFieldFormula AS mff
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedFieldId = mff.MetaSelectedFieldId
	INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mff.MetaSelectedFieldId in (
			SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId = 179
	)

UPDATE MetaFieldFormula
SET Formula = '
let zero = ([4] == 4) ? [2] * 16 : [3] * 16;
let one = ([4] == 4) ? [1] * 48 : (~[8,9,10,11].indexOf([5])) ? [6] * 48 : 0
let two = ([4] == 4) ? [2] * 48 : [0] * 48;
let three = ([4] == 4) ? [2] * 60 : [3] * 60;
let four = ([5] == 7 || [5] == 11) ? ([4] == 4 ? [2] * 32 : [3] * 32) : ([5] == 19 ? ([4] == 4 ? [2] * 24 : [3] * 24) : 0)


if ([5] == 7 || [5] == 15)
    { zero + [4]}
else if ([5] == 8 || [5] == 9 || [5] == 10 || [5] == 16 || [5] == 17 || [5] == 18)
    {one + [4]}
else if ([5] == 11)
    {zero + one + four}
else if ([5] == 19)
    {two + four}
else if ([5] == 12) 
    {three + four}
else if ([5] == 13)
    {four}
else if ([5] == 14)
    {zero + two}
else { 0 }
'
WHERE Id in (
	SELECT formulaId FROM @Formulas2
)


DELETE FROM MetaFieldFormulaDependency WHERE MetaFieldFormulaId in (
	SELECT formulaId FROM @Formulas2
)

INSERT INTO MetaFieldFormulaDependency
(MetaFieldFormulaId, MetaSelectedFieldId, FormulaIndex)
SELECT f.formulaId, msf.MetaSelectedFieldId, 0 FROM @Formulas2 AS f
INNER JOIN MetaTemplate AS mt on f.TempId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 180
UNION
SELECT f.formulaId, msf.MetaSelectedFieldId, 1 FROM @Formulas2 AS f
INNER JOIN MetaTemplate AS mt on f.TempId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 181
UNION
SELECT f.formulaId, msf.MetaSelectedFieldId, 2 FROM @Formulas2 AS f
INNER JOIN MetaTemplate AS mt on f.TempId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 185
UNION
SELECT f.formulaId, msf.MetaSelectedFieldId, 3 FROM @Formulas2 AS f
INNER JOIN MetaTemplate AS mt on f.TempId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 186
UNION
SELECT f.formulaId, msf.MetaSelectedFieldId, 4 FROM @Formulas2 AS f
INNER JOIN MetaTemplate AS mt on f.TempId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 950
UNION
SELECT f.formulaId, msf.MetaSelectedFieldId, 5 FROM @Formulas2 AS f
INNER JOIN MetaTemplate AS mt on f.TempId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 191
UNION
SELECT f.formulaId, msf.MetaSelectedFieldId, 6 FROM @Formulas2 AS f
INNER JOIN MetaTemplate AS mt on f.TempId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2483
UNION
SELECT f.formulaId, msf.MetaSelectedFieldId, 7 FROM @Formulas2 AS f
INNER JOIN MetaTemplate AS mt on f.TempId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2484
UNION
SELECT f.formulaId, msf.MetaSelectedFieldId, 8 FROM @Formulas2 AS f
INNER JOIN MetaTemplate AS mt on f.TempId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2623



UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()