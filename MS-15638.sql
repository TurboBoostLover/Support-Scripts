use sdccd_2_v2

DECLARE @TABLE TABLE (id int, campus nvarchar(max))
INSERT INTO @TABLE
select distinct pc.PROGRAM_CODES_ID
, col.COLLEGE_TITLE
from PROGRAM_CODES pc
	left join DEPARTMENT_PROGRAM_CODES d on pc.PROGRAM_CODES_ID = d.PROGRAM_CODES_ID
	left join DEPARTMENTS de on d.DEPARTMENTS_ID = de.DEPARTMENTS_ID
	left join SCHOOLS s on de.SCHOOLS_ID = s.SCHOOLS_ID
	left join COLLEGE_SCHOOLS cs on s.SCHOOLS_ID = cs.SCHOOLS_ID
	left join COLLEGES col on cs.COLLEGES_ID = col.COLLEGES_ID

	use sdccd

	UPDATE pc
	SET Title = CONCAT(Title , COALESCE(
		CASE
			WHEN t.campus IS NOT NULL
			THEN CONCAT(' - ', t.campus)
			ELSE ''
		END
	, ''))
	FROM ProgramCode AS pc
	INNER JOIN @TABLE AS t on pc.Id = t.id

	SELECT * FROM ProgramCode
	WHERE Active = 1
	order by Title


	SELECT * FROM Program
	WHERE ProgramCodeId in (
	535, 549, 548, 57, 482, 107, 108, 449, 220, 497, 498, 499, 550, 483, 450, 507, 69, 48, 505, 514, 320, 485, 481, 79, 80, 46, 486, 487, 341, 444, 160, 280, 130
	)