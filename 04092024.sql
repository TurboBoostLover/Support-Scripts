use hkapa

UPDATE MetaFieldFormula 
SET Formula = 'let NLH = 0;

if ([3] == 1) {
    NLH = [4] * 36;
} else if ([3] == 2 || [3] == 5) {
    NLH = [4] * 42;
} else if ([3] == 3) {
    NLH = [4] * 48;
} else if ([3] == 4) {
    NLH = [4] * 39;
} else {
    NLH = 0;
}

if ([0] == 1 || [0] == 5) {
    [2];
} else if ([0] == 2) {
    NLH = (NLH / 3) * 2;
} else if ([0] == 3) {
    NLH = (NLH / 3) * 1.5;
} else if ([0] == 4) {
    NLH = NLH / 3;
} else {
    NLH = 0;
}


let NLH2 = 0;

if ([3] == 1) {
    NLH2 = [4] * 36;
} else if ([3] == 2 || [3] == 5) {
    NLH2 = [4] * 42;
} else if ([3] == 3) {
    NLH2 = [4] * 48;
} else if ([3] == 4) {
    NLH2 = [4] * 39;
} else {
    NLH2 = 0;
}

if ([0] == 1 || [0] == 5) {
    [5];
} else if ([0] == 2) {
    NLH2 = (NLH2 / 3);
} else if ([0] == 3) {
    NLH2 = (NLH2 / 3) * 1.5;
} else if ([0] == 4) {
    NLH2 = (NLH2 / 3) * 2;
} else {
    NLH2 = 0;
}

if (1 == 1) {
   NLH / NLH2;
}
'
WHERE MetaSelectedFieldId = 978

DELETE FROM MetaFieldFormulaDependency WHERE MetaFieldFormulaId = 18

INSERT INTO MetaFieldFormulaDependency
(MetaFieldFormulaId, MetaSelectedFieldId, FormulaIndex)
VALUES
(18, 636, 0),
(18, 24, 1),
(18, 650, 2),
(18, 599, 3), 
(18, 37, 4),
(18, 652, 5)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()