
SELECT 
	CONCAT(s.SubjectCode,' ', c.CourseNumber) as [Course Subject & Number],
	c.Title as [Title],
	cd.MinUnitHour AS [Min Units],
	cd.MaxUnitHour AS [Max Units],
	CASE 
	WHEN cd.HasSpecialTopics = 1 
	THEN 'Yes'
	ELSE 'No'
	END
	AS [Transfer to UC],
	CASE
	WHEN c.ISCSUTransfer = 1
	THEN 'Yes'
	ELSE 'No'
	END
	AS [Transfer to CSU],
	CONCAT(cb3.Code,' - ', cb3.Description) AS [Top Code],
	cb.CB00 AS [CCC Control Number],
	cd.MinContactHoursLab AS [Minimum Lab Hours],
	cd.MinContactHoursLecture AS [Minimum Lecture Hours],
	c.Description AS [Description],
	dbo.ConcatWithSep_Agg(
		CASE 
			WHEN c2.Title IS NULL
				THEN ''
			ELSE
	', '
		END
	,  
		CASE
			WHEN c2.Title IS NULL
				THEN ''
			ELSE
	CONCAT (rt.Title,': ', s2.SubjectCode, ' ', c2.CourseNumber)
		END
	) AS [Requisite],
	sa.Title AS [Status]
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
