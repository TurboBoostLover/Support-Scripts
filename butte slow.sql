use butte

DELETE FROM MetaDisplaySubscriber

DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 10;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		--Create more Variables here using Sort if needed

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
DECLARE @Subject int = (SELECT SubjectId FROM CourseRequisite WHERE Id = @pkIdValue)

select c.Id as Value, 
s.SubjectCode + ' ' + c.CourseNumber + ' - ' + c.Title + ' (' + sa.Title + ')' as Text
from Course c 
inner join [Subject] s on s.Id = c.SubjectId 
inner join StatusAlias sa on sa.Id = c.StatusAliasId 
where c.ClientId = @clientId
and c.Active = 1 
and c.SubjectId = @subjectId
and sa.StatusBaseId in(1, 2, 4, 6) 
and c.SubjectId = @Subject
order by Text
"

DECLARE @RSQL NVARCHAR(MAX) = "
select s.SubjectCode + ' ' + c.CourseNumber + ' - ' + c.Title + ' (' + sa.Title + ')' as Text from Course c inner join [Subject] s on s.Id = c.SubjectId inner join StatusAlias sa on sa.Id = c.StatusAliasId where c.Id = @id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Active, Pending, Approved, In Review Courses', 3)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaForeignKeyLookupSourceId IS NULL
and MetaAvailableFieldId = 298

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @Subject int = (SELECT SubjectId FROM ProgramSequence WHERE Id = @pkIdValue)

select c.Id as [Value]
	, coalesce(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title, s.SubjectCode + '' '' + c.CourseNumber, c.Title) + 	
		case
			when sa.StatusBaseId != 1 then '' ('' + sa.Title + '')'' 		
			when sa.StatusBaseId = 1 then ''''
		end as [Text]
	, s.Id as FilterValue
from Course c
	inner join [Subject] s on c.SubjectId = s.Id
	inner join StatusAlias sa on c.StatusAliasId = sa.Id
where (
	(c.Active = 1
		and c.SubjectId = @Subject
		and sa.StatusBaseId in (1, 2, 4, 6, 8) /* 1 = Active, 2 = Approved, 4 = Draft, 6 = In Review, 8 = Tabled */
	)
	or exists (
		select 1
		from ProgramSequence ps
		where c.Id = ps.CourseId
		and ps.ProgramId = @entityId 
	)
)
order by s.SubjectCode, cast(dbo.RegEx_Replace(c.CourseNumber, ''[^0-9]'', '''') as int);
'
WHERE Id = 209

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (
@MAX, 209
)