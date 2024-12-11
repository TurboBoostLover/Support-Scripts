SELECT c.EntityTitle, c2.EntityTitle FROM Course AS c	
INNER JOIN Course AS c2 on c.Title = c2.Title
WHERE c.BaseCourseId <> c2.BaseCourseId
and c2.StatusAliasId in (1)
and c.StatusAliasId in (1)
and c.Id <> c2.Id
and c.SubjectId <> c2.SubjectId
and c.Id in (
	SELECT CourseId FROM CourseRelatedCourse
)
and c2.Id in (
	SELECT CourseId FROM CourseRelatedCourse
)
and c.CourseNumber = c2.CourseNumber

--DECLARE @cl Table (Text NVARCHAR(MAX), base INT, related INT, non int)

--INSERT INTO @cl (text, base, related, non)
--select  c1.Title, c1.Id, c2.Id, c1.ProposalTypeId
--FROM CourseRelatedCourse crc
--	INNER JOIN Course c1 on c1.Id = crc.CourseId
--	Inner JOIN StatusAlias sa1 on sa1.Id = c1.StatusAliasId
--	Inner JOIN Course c2 ON c2.Id = crc.RelatedCourseId
--	INNER JOIN StatusAlias sa2 ON sa2.Id = c2.StatusAliasId
--WHERE courseId != crc.RelatedCourseId
--	AND courseId != c1.PreviousId
--	AND sa1.StatusBaseId IN (1)
--	AND sa2.StatusBaseId IN (1) 
--	and C1.BaseCourseId <> C2.BaseCourseId
--UNION
--select  c1.Title, c1.Id, c2.Id,c1.ProposalTypeId
--FROM CourseRelatedCourse crc
--	INNER JOIN Course c1 on c1.Id = crc.CourseId
--	Inner JOIN StatusAlias sa1 on sa1.Id = c1.StatusAliasId
--	Inner JOIN Course c2 ON c2.Id = crc.RelatedCourseId
--	INNER JOIN StatusAlias sa2 ON sa2.Id = c2.StatusAliasId
--WHERE courseId != crc.RelatedCourseId
--	AND courseId != c1.PreviousId
--	AND sa1.StatusBaseId IN (6)
--	AND sa2.StatusBaseId IN (1) 
--	and C1.BaseCourseId <> C2.BaseCourseId

----	DELETE FROM @cl WHERE base in (
----	SELECT DISTINCT related FROM @cl
----) 

--	SELECT * FROM @cl