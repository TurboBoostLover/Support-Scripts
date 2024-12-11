use hkapa	

SELECT msf.MetaSelectedFieldId, mffd.*, mff.Formula FROM MetaFieldFormula AS mff
INNER JOIN MetaFieldFormulaDependency AS mffd on mffd.MetaFieldFormulaId = mff.Id
INNER JOIN MetaSelectedField As msf on mffd.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaAvailableField AS maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
WHERE mff.MetaSelectedFieldId = 978

SELECT msf.MetaSelectedFieldId, mffd.*, mff.Formula  FROM MetaFieldFormula AS mff
INNER JOIN MetaFieldFormulaDependency AS mffd on mffd.MetaFieldFormulaId = mff.Id
INNER JOIN MetaSelectedField As msf on mffd.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaAvailableField AS maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
WHERE mff.MetaSelectedFieldId = 18

SELECT msf.MetaSelectedFieldId, mffd.*, mff.Formula  FROM MetaFieldFormula AS mff
INNER JOIN MetaFieldFormulaDependency AS mffd on mffd.MetaFieldFormulaId = mff.Id
INNER JOIN MetaSelectedField As msf on mffd.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaAvailableField AS maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
WHERE mff.MetaSelectedFieldId = 21