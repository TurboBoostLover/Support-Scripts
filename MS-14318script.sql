use gavilan
SELECT
  oe.Title AS [Division],
  oe2.Title AS [Department],
  oe3.Title AS [Unit],
  s.Title AS [Subject],
  COUNT(oe2.Id) + COUNT(oe3.Id) + COUNT(s.Id) AS InfoCount
FROM OrganizationEntity AS oe 
LEFT JOIN OrganizationLink AS ol ON ol.Parent_OrganizationEntityId = oe.Id AND oe.OrganizationTierId = 107
LEFT JOIN OrganizationEntity AS oe2 ON ol.Child_OrganizationEntityId = oe2.Id AND oe2.OrganizationTierId = 108
LEFT JOIN OrganizationLink AS ol2 ON ol2.Parent_OrganizationEntityId = oe2.Id
LEFT JOIN OrganizationEntity AS oe3 ON ol2.Child_OrganizationEntityId = oe3.Id AND oe3.OrganizationTierId = 109
LEFT JOIN OrganizationSubject AS os ON os.OrganizationEntityId = oe2.Id
LEFT JOIN Subject AS s ON os.SubjectId = s.Id
WHERE oe.Active = 1 AND oe2.Id IS NOT NULL
GROUP BY oe.Title, oe2.Title, oe3.Title, s.Title
ORDER BY InfoCount DESC;



--SELECT * FROM OrganizationEntity WHERE title like '%Academic Affairs%'

--SELECT CONCAT(Code, ' ', Title) AS [Unit] FROM OrganizationEntity WHERE OrganizationTierId = 109 order by Title

--SELECT * FROM OrganizationLink
--SELECT * FROM OrganizationSubject
--SELECT * FROM OrganizationTier