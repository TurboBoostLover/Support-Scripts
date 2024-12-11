use chabot

UPDATE AdminReport
SET ReportSQL = '
SELECT 
	CONCAT(s.SubjectCode,'' '', c.CourseNumber) as [Course Subject & Number],
	c.Title as [full course title],
	cd.MinUnitHour AS [min units],
	cd.MaxUnitHour AS [Max units],
	cd.MinContactHoursLecture AS [Minimum Lecture Hours],
	cd.MinContactHoursLab AS [Minimum Lab Hours],
	CASE 
	WHEN cd.HasSpecialTopics = 1 
	THEN ''Yes''
	ELSE ''No''
	END
	AS [Transfer to UC],
	CASE
	WHEN c.ISCSUTransfer = 1
	THEN ''Yes''
	ELSE ''No''
	END
	AS [Transfer to CSU],
	cb.CB00 AS [CCC Control Number],
	dbo.ConcatWithSep_Agg(
		CASE 
			WHEN c2.Title IS NULL
				THEN ''''
			ELSE
	'', ''
		END
	,  
		CASE
			WHEN c2.Title IS NULL
				THEN ''''
			ELSE
	CONCAT (rt.Title,'': '', s2.SubjectCode, '' '', c2.CourseNumber)
		END
	) AS [Requisite],
	c.Description AS [Catalog Description]

	--sa.Title AS [Status]
FROM Course AS C
	INNER JOIN StatusAlias AS sa ON c.StatusAliasId = sa.Id
	LEFT JOIN CourseDescription AS cd ON cd.CourseId = c.Id
	LEFT JOIN CourseCBCode AS cb ON cb.CourseId = c.Id
	LEFT JOIN CB03 AS cb3 ON cb.CB03Id = cb3.Id
	LEFT JOIN CourseRequisite AS cr ON cr.CourseId = c.Id
	LEFT JOIN Subject AS s ON c.SubjectId = s.Id
	LEFT JOIN RequisiteType AS rt on cr.RequisiteTypeId = rt.Id
	LEFT JOIN Course AS c2 on cr.Requisite_CourseId = c2.Id
	LEFT JOIN Subject AS s2 on c2.SubjectId = s2.Id
	WHERE c.Active = 1
	AND sa.Id = 1
	group by s.SubjectCode, c.CourseNumber, c.Title, cd.MinUnitHour, cd.MaxUnitHour, cd.MinContactHoursLecture, cd.MinContactHoursLab, c.Description, cb3.Code, cb3.Description, cd.HasSpecialTopics, c.ISCSUTransfer, cb.CB00, sa.Title, s2.SubjectCode
'
WHERE Id = 24

UPDATE AdminReport
SET ReportSQL = 'SELECT 
	p.Title AS [Title of the Program],
	at.Title AS [Award Type],
	SUM(co.CalcMin) AS [Minimum Units],
	SUM(co.CalcMax) AS [Maximum Units],
	CONCAT(cb3.Code, '' -'', cb3.Description) AS [TOP Code],
	p.UniqueCode2 AS [CCC Control Number],
	p.Description AS [Catalog Description]
	--[Program Learning Outcomes],
	--sa.Title AS [Status]
FROM Program AS p
	INNER JOIN StatusAlias AS sa ON p.StatusAliasId = sa.Id
	LEFT JOIN AwardType AS at ON p.AwardTypeId = at.Id
	LEFT JOIN CourseOption AS co ON co.ProgramId = p.Id and co.DoNotCalculate = 0
	LEFT JOIN ProgramCBCode AS pcc ON pcc.ProgramId = p.Id
	LEFT JOIN CB03 AS cb3 ON pcc.CB03Id = cb3.Id
	cross apply (
	select dbo.ConcatWithSep_Agg(''; '',
	po.Outcome) AS [Program Learning Outcomes] from ProgramOutcome AS po where po.ProgramId = p.Id) po
WHERE p.Active = 1
	AND sa.Id = 1
GROUP BY 
	p.Id,
	p.Title,
	at.Title,
	p.UniqueCode2,
	cb3.Code, 
	cb3.Description,
	p.Description,
	sa.Title,
	po.[Program Learning Outcomes]
ORDER BY p.Title;'
WHERE Id = 25