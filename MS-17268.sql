use peralta

SELECT c.Id AS [Id],
c.EntityTitle AS [Title],
'Active' AS [Status]
FROM Course as c
INNER JOIN CourseProposal AS cp on cp.CourseId = c.Id
WHERE c.ClientId = 2 and c.StatusAliasId = 1
and cp.SemesterId IS NULL
and c.Active = 1
UNION
SELECT c.Id AS [Id],
c.EntityTitle AS [Title],
'Historical' AS [Status]
FROM Course as c
INNER JOIN CourseProposal AS cp on cp.CourseId = c.Id
INNER JOIN ProposalType AS pt on c.ProposalTypeId = pt.Id
WHERE c.ClientId = 2 and c.StatusAliasId = 5
and cp.SemesterId IS NULL
and c.Active = 1
and pt.ProcessActionTypeId = 3
and c.Id not in (
	SELECT PreviousId FROM Course WHERE PreviousId IS NOT NULL
)
order by c.Id