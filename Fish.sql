UPDATE OutputModelClient
SET ModelQuery = '
--#region model query

--#region model tables
declare @entityList_internal table (
	InsertOrder int identity (1,1),
	Id int primary key
);

declare @entityRootData table (
	Id int primary key,
	Variable bit,
	MinCreditHour decimal(16,3),
	MaxCreditHour decimal(16,3),
	MinLectureHour decimal(16,3),
	MaxLectureHour decimal(16,3),
	MinLabHour decimal(16,3),
	MaxLabHour decimal(16,3),
	TransferStatus nvarchar(500),
	IsGenEd bit,
	IsRepeatable bit,
	MaxRepeatsAllowed nvarchar(100),
	UnitsRepeatLimit decimal(16,3),
	GradeOption nvarchar(100),
	IsCrossListed bit,
	Cid nvarchar(max),
	FamilyCount int,
	BaseCourseId int,
	ProcessActionType nvarchar(50),
	StatusBase nvarchar(50),
	StatusAlias nvarchar(50),
	SubjectTitle nvarchar(100),
	SubjectCode nvarchar(10),
	CourseNumber nvarchar(10),
	CourseTitle nvarchar(255),
	IsCreditCourse bit,
	CourseDescription nvarchar(max),
	AddCatalogNotes bit,
	CatalogNotes nvarchar(max)
);

declare @entityGenEdAreas table (
	InsertOrder int identity(1,1),
	CourseId int,
	GeneralEducationId int,
	Title nvarchar(1000),
	primary key (CourseId, GeneralEducationId),
	index ixEntityGenEdAreas_InsertOrder nonclustered (InsertOrder)
);

declare @entityGenEdElements table (
	InsertOrder int identity(1,
1),
	CourseId int,
	GeneralEducationId int,
	GeneralEducationElementId int,
	Code nvarchar(1000),
	Title nvarchar(1000),
	primary key (CourseId, GeneralEducationElementId),
	index ixEntityGenEdElements_Area nonclustered (GeneralEducationId),
	index ixEntityGenEdElements_InsertOrder nonclustered (InsertOrder)
);

declare @entityRelatedCourses table (
	InsertOrder int identity(1,
1),
	CourseId int,
	RelatedCourseId int,
	CourseIdentifier nvarchar(25),
	primary key (CourseId, RelatedCourseId),
	index ixEntityRelatedCourses_InsertOrder nonclustered (InsertOrder)
);

declare @effectiveTermRanges table (
	Id int primary key,
	NextId int index ixEffectiveTermRange_NextId nonclustered,
	NextCourseProcessActionType nvarchar(50),
	NextStatusBase nvarchar(50),
	NextStatusAlias nvarchar(50),
	--Semester.Title is currently 150 chars, but I do not want to have to come back
	--in here and fix this if that ever gets expanded, so just using nvarchar(max)
	EffectiveTermRangeStart nvarchar(max),
	EffectiveTermRangeEnd nvarchar(max)
);

--#endregion model tables

INSERT INTO @entityList_internal (Id)
	SELECT Id FROM @entityList;

--#region entity root data
INSERT INTO @entityRootData
(Id, Variable, MinCreditHour, MaxCreditHour, MinLectureHour, MaxLectureHour, MinLabHour, MaxLabHour,
TransferStatus, IsGenEd, IsRepeatable, MaxRepeatsAllowed, UnitsRepeatLimit, GradeOption, IsCrossListed,
Cid, FamilyCount, BaseCourseId, ProcessActionType, StatusBase, StatusAlias, SubjectTitle, SubjectCode,
CourseNumber, CourseTitle, IsCreditCourse, CourseDescription, AddCatalogNotes, CatalogNotes)
	SELECT
		c.Id
	   ,cd.Variable
	   ,ROUND((Coalesce(cast(cd.MinLectureHour AS FLOAT), 0) + (Coalesce(cast(cd.MinLabHour AS FLOAT), 0) / 3)) * 2, 0) / 2 
	   ,ROUND((Coalesce(cast(cd.MaxLectureHour AS FLOAT), 0) + (Coalesce(cast(cd.MaxLabHour AS FLOAT), 0) / 3)) * 2, 0) / 2
	   ,cd.MinLectureHour
	   ,cd.MaxLectureHour
	   ,cd.MinLabHour
	   ,cd.MaxLabHour
	   ,CASE
			WHEN ts.TransferStatusCode = ''A'' THEN ''UC/CSU''
			WHEN ts.TransferStatusCode = ''B'' THEN ''CSU''
			ELSE NULL
		END AS TransferStatus
	   ,CAST(CASE cyn.YesNo30Id
			WHEN 1 THEN 1
			ELSE 0
		END AS BIT) AS IsGenEd
	   ,CAST(CASE cyn.YesNo04Id
			WHEN 1 THEN 1
			ELSE 0
		END AS BIT) AS IsRepeatable
	   ,rl.Title AS MaxRepeatsAllowed
	   ,cp.UnitsRepeatLimit
	   ,gopt.[Description] as GradeOption
	   , CASE 
			-- handle courses using the old cross listing model
			WHEN ocm.IsCrossListed = 1 and cyn.YesNo03Id = 1 THEN 1
			-- handle courses using the new cross listing model
			ELSE c.IsCrossListed
		END AS IsCrossListed
	   ,gmt.TextMax07 AS Cid
	   ,COUNT(*) OVER (PARTITION BY c.BaseCourseId) AS FamilyCount
	   ,c.BaseCourseId
	   ,dbo.fnTrimWhitespace(pat.Title) AS ProcessActionType
	   ,sb.Title AS StatusBase
	   ,sa.Title AS StatusAlias
	   ,s.Title AS SubjectTitle
	   ,s.SubjectCode
	   ,c.CourseNumber
	   ,c.Title AS CourseTitle
	   ,
		--null values for the credit status are assumed to be Credit Courses
		--If this causes a non-credit course to be treated as a credit course, then
		--the non-credit value needs to be set for CB04 on that course
		CASE cs.CreditStatusCode
			WHEN ''N'' THEN 0
			ELSE 1
		END AS IsCreditCourse
	   ,c.[Description] AS CourseDescription
	   ,COALESCE(gb.Bit06,
0) AS AddCatalogNotes
	   ,g1kt.Text100007 AS CatalogNotes
	FROM Course c
		INNER JOIN @entityList_internal eli ON c.Id = eli.Id
		--Extension tables
		LEFT OUTER JOIN CourseDescription cd ON c.Id = cd.CourseId
		LEFT OUTER JOIN CourseCBCode ccc ON c.Id = ccc.CourseId
		LEFT OUTER JOIN CourseYesNo cyn ON c.Id = cyn.CourseId
		LEFT OUTER JOIN CourseProposal cp ON c.Id = cp.CourseId
		LEFT OUTER JOIN GenericMaxText gmt ON c.Id = gmt.CourseId
		LEFT OUTER JOIN CourseAttribute ca ON c.Id = ca.CourseId
		LEFT OUTER JOIN GenericBit gb ON c.Id = gb.CourseId
		LEFT OUTER JOIN Generic1000Text g1kt ON c.Id = g1kt.CourseId
		--Look-ups and transforms
		LEFT OUTER JOIN TransferApplication ta ON cd.TransferAppsId = ta.Id
		LEFT OUTER JOIN CB05 cb05 ON ccc.CB05Id = cb05.Id
		CROSS APPLY (
				SELECT
					--They are currently using the legacy backing store for this field
					--instead of the new seeded backing store; put this coalesce in here
					--as a bit of future-proofing for when they are eventually migrated to
					--the new backing store
					COALESCE(cb05.Code, ta.Title) AS TransferStatusCode
			) ts
		LEFT OUTER JOIN RepeatLimit rl ON cp.RepeatlimitId = rl.Id
		LEFT OUTER JOIN GradeOption gopt ON cd.GradeOptionId = gopt.Id
		LEFT OUTER JOIN ProposalType pt ON c.ProposalTypeId = pt.Id
		LEFT OUTER JOIN ProcessActionType pat ON pt.ProcessActionTypeId = pat.Id
		LEFT OUTER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
		LEFT OUTER JOIN StatusBase sb ON sa.StatusBaseId = sb.Id
		LEFT OUTER JOIN [Subject] s ON c.SubjectId = s.Id
		LEFT OUTER JOIN CourseCreditStatus ccs ON ca.CourseCreditStatusId = ccs.Id
		LEFT OUTER JOIN CB04 cb04 ON ccc.CB04Id = cb04.Id
		CROSS APPLY (
				SELECT
					--They are currently using the legacy backing store for this field
					--instead of the new seeded backing store; put this coalesce in here
					--as a bit of future-proofing for when they are eventually migrated to
					--the new backing store
					COALESCE(cb04.Code, ccs.Code) AS CreditStatusCode
			) cs
		OUTER APPLY (
			SELECT TOP 1 1 as IsCrossListed
			FROM MetaSelectedSection mss
			WHERE c.MetaTemplateId = mss.MetaTemplateId
			and mss.MetaBaseSchemaId = 124
		) ocm
	ORDER BY eli.InsertOrder;
--#endregion entity root data

--#region entity gen ed areas
/*INSERT INTO @entityGenEdAreas
(CourseId, GeneralEducationId, Title)
	SELECT
		eli.Id AS CourseId
	   ,ge.Id AS GeneralEducationId
	   ,ge.Title
	FROM GeneralEducation ge
		CROSS JOIN @entityList_internal eli
	WHERE EXISTS (
		SELECT TOP 1
			1
		FROM CourseGeneralEducation cge
			INNER JOIN GeneralEducationElement gee ON cge.GeneralEducationElementId = gee.Id
		WHERE cge.CourseId = eli.Id
		AND gee.GeneralEducationId = ge.Id
        /*not showing GE area title if the Gen Ed Element doesn''t have approved checkbox checked*/
		and cge.Bit02 = 1
	)
	--Exclude the Transfer gen ed areas
	AND (ge.GeneralEducationGroupId IS NULL
	OR ge.GeneralEducationGroupId <> 1)
	ORDER BY eli.InsertOrder, ge.SortOrder, ge.Id;*/
--#endregion entity gen ed areas

--#region entity gen ed elements
/*INSERT INTO @entityGenEdElements
(CourseId, GeneralEducationId, GeneralEducationElementId, Code, Title)
	SELECT
		cge.CourseId
	   ,gee.GeneralEducationId
	   ,cge.GeneralEducationElementId
	   ,COALESCE(gee.Text, gee.Title) AS Code
	   ,gee.Title
	FROM (
		--Sometimes there is bad data where the same GeneralEducationElementId is in the table more than once for the same course
		--This distinct clause should take care of that
		--The performance impact should be negligible because it is a distinct over two int columns
		SELECT DISTINCT
			cge.CourseId
		   ,cge.GeneralEducationElementId
		FROM CourseGeneralEducation cge
			INNER JOIN @entityList_internal eli ON cge.CourseId = eli.Id
		/*They only want to show GE areas that have ''approved'' checked*/
		where cge.Bit02 = 1
	) cge
		INNER JOIN GeneralEducationElement gee ON cge.GeneralEducationElementId = gee.Id
	ORDER BY cge.CourseId, gee.GeneralEducationId, gee.SortOrder;*/
--#endregion entity gen ed elements

--#region entity related courses
INSERT INTO @entityRelatedCourses (CourseId, RelatedCourseId, CourseIdentifier)
SELECT
	crc.CourseId
	,c.Id AS RelatedCourseId
	,CONCAT(s.SubjectCode, '' '', c.CourseNumber) AS CourseIdentifier
FROM CourseRelatedCourse crc
	INNER JOIN @entityList_internal eli ON crc.CourseId = eli.Id
	INNER JOIN Course c ON crc.RelatedCourseId = c.Id
	INNER JOIN [Subject] s ON c.SubjectId = s.Id
where exists (
	select top 1 1 as OldCrossListing from course c 
	join MetaSelectedSection mss on mss.MetaTemplateId = c.MetaTemplateId AND mss.MetaBaseSchemaId = 124
	where c.Id = eli.Id
)
	
/*
THIS IS A HACK. THIS IS A COPY OF [fn_GetCurrentCoursesInCrosslisting] as of 06/2/2022 with some modifications:
	- don''t show the title
	- don''t show the suffix
	- remove code not needed
	- handle multiple courses
*/
declare 
	@IncludeSelected BIT = 0
;

Declare @GetCrossListedCourses table 
(
	Id int identity primary key,
	TargetCoursesId int,
	CrossedCourseId int,
	OriginalCrossCourseTitle nvarchar(max),
	IncludeCrossListCourse bit
	index ix_getCrossListedCourses_coursesid (TargetCoursesId, CrossedCourseId)
);


declare @targetCourses table (
	Id int identity primary key,
	CourseId int, -- previousid if any
	ActualCourseId int, -- the course passed in
	CourseCrossListingId int,
	NoOtherCoursesInCrosslisting int
);

insert into @targetCourses (CourseId, ActualCourseId)
select coalesce(oa.PreviousCourseId, ei.Id)
, ei.Id
from @entityList_internal ei
	inner join Course c on ei.Id = c.Id
	outer apply (
		select c.PreviousId as PreviousCourseId
		from Course c
			inner join StatusAlias sa on sa.Id = c.StatusAliasId
									and sa.StatusBaseId in (2, 4, 6)
			inner join CrosslistingCourse clc on clc.CourseId = c.PreviousId
									and clc.Active = 1
									and clc.IsSynced = 1
									and c.Id = ei.Id
		where not exists (
			select 1
			from CrosslistingCourse clc2
			where clc2.CourseId = c.Id
			and clc2.Active = 1
		)
	) oa
where not exists (
	select 1
	from MetaSelectedSection mss
	where c.MetaTemplateId = mss.MetaTemplateId
	and mss.MetaBaseSchemaId = 124
)
;

update tc
set tc.CourseCrossListingId = ca.CrossListingId
from @targetCourses tc
	cross apply (
		select top 1 CrosslistingId
		from CrosslistingCourse
		where CourseId = tc.CourseId
		group by CrosslistingId
				,SyncedOn
		order by SyncedOn desc
	) ca
;


update tc
set tc.NoOtherCoursesInCrosslisting = ca.[count]
from @targetCourses tc
cross apply (
	select
		count(*) as [count]
	from (
		select CourseId
		from CrosslistingCourse clc
		where clc.Active = 1
		and clc.CrosslistingId = tc.CourseCrossListingId
		union
		select tc.CourseId as courseid
	) s
) ca;

with StartDates as (
	select tc.Id
	, oa.*
	from @targetCourses tc
		outer apply (
			select distinct
				C.EntityTitle as StartTitle
				,cast(format(min(SyncedOn), ''MM-dd-yyyy'') as nvarchar) as StartDate
			from CrosslistingCourse clc
				inner join Course c on CourseId = c.Id
			where clc.CrosslistingId = tc.CourseCrossListingId
			and SyncedOn is not null
			group by c.EntityTitle
		) oa
), EndDates as (
	select tc.Id
	, oa2.*
	from @targetCourses tc
	outer apply (
		select c.EntityTitle as EndTitle
		, cast(format(max(RemovedOn), ''MM-dd-yyyy'') as nvarchar) as EndDate
		from Course c
			inner join CrosslistingCourse clc on CourseId = c.Id
		where clc.CrosslistingId = tc.CourseCrossListingId
		and not exists (
			select 1
			from crosslistingcourse clc
			inner join Course c2
				on clc.CourseId = c2.Id
				and c.EntityTitle = c2.EntityTitle
				and clc.Active = 1
		)
		group by c.EntityTitle
	) oa2
), courses as (
	select tc.Id as targetCoursesId
	, tc.ActualCourseId
	, oa.*
	from @targetCourses tc
		outer apply (
			/*This section returns courses that are active in the crosslisting and are synced*/
			select
				 CourseId
			   , EntityTitle as Courses
			   , case
					when CourseId = tc.CourseId then @IncludeSelected
					else 1
				 end as IncludeCourse
			   , cl.Title as CrosslistingTitle
			from course c
				inner join CrosslistingCourse clc on clc.CourseId = c.Id
				inner join Crosslisting cl on cl.Id = clc.CrosslistingId
			where clc.Active = 1
			and clc.IsSynced = 1
			and tc.CourseId = tc.ActualCourseId
			and clc.CrosslistingId = tc.CourseCrossListingId

			union

			/*This section returns courses that are active in the crosslisting and are synced for display in modifications that are not yet in the crosslisting table.*/
			select
				CourseId
			   , EntityTitle + '' (Pending Approval)'' as Courses
			   , case
					when CourseId = tc.CourseId then @IncludeSelected
					else 1
				 end as IncludeCourse
			   , cl.Title as CrosslistingTitle
			from course c
			inner join CrosslistingCourse clc
				on clc.CourseId = c.Id
			inner join Crosslisting cl
				on cl.Id = clc.CrosslistingId
			where clc.Active = 1
			and clc.IsSynced = 1
			and tc.CourseId <> tc.ActualCourseId
			and (select
					statusbaseId
				from StatusAlias sa
				inner join Course c
					on c.StatusAliasId = sa.Id
				where c.Id = tc.ActualCourseId)
			in (4, 6)
			and clc.CrosslistingId = tc.CourseCrossListingId

			union

			/*This section returns courses that are active in the crosslisting and are synced for display in modifications that approved but are not yet in the crosslisting table.*/
			select
				 CourseId
			   , EntityTitle + '' (Pending Activation)'' as Courses
			   , case
					when CourseId = tc.CourseId then @IncludeSelected
					else 1
				 end as IncludeCourse
			   , cl.Title as CrosslistingTitle
			from course c
			inner join CrosslistingCourse clc
				on clc.CourseId = c.Id
			inner join Crosslisting cl
				on cl.Id = clc.CrosslistingId
			where clc.Active = 1
			and clc.IsSynced = 1
			and tc.CourseId <> tc.ActualCourseId
			and (select distinct
					statusbaseId
				from StatusAlias sa
				inner join Course c
					on c.StatusAliasId = sa.Id
				where c.Id = tc.ActualCourseId)
			in (2)
			and clc.CrosslistingId = tc.CourseCrossListingId

			union

			/*This section returns courses that are active in the crosslisting and are not yet synced*/
			select
				 CourseId
			   , S.SubjectCode + '' '' + CourseNumber + '' (Pending Synchronization)'' as Courses
			   , case
					when CourseId = tc.CourseId then @IncludeSelected
					else 1
				 end as IncludeCourse
			   , cl.Title as CrosslistingTitle
			from course c
				inner join StatusAlias sa
					on sa.Id = c.StatusAliasId
					and sa.StatusBaseId in (1)
				inner join Subject s
					on s.Id = c.SubjectId
				inner join CrosslistingCourse clc
					on clc.CourseId = c.Id
				inner join Crosslisting cl
					on cl.Id = clc.CrosslistingId
			where clc.Active = 1
			and tc.CourseId = tc.ActualCourseId
			and clc.IsSynced = 0
			and clc.CrosslistingId = tc.CourseCrossListingId

			union

			/*This section returns courses that are pre-active and approved, are in the crosslisting and are not synced*/
			select
				 CourseId
			   , S.SubjectCode + '' '' + CourseNumber + '' (Pending Activation)'' as Courses
			   , case
					when CourseId = tc.CourseId then @IncludeSelected
					else 1
				 end as IncludeCourse
			   , cl.Title as CrosslistingTitle
			from course c
			inner join StatusAlias sa
				on sa.Id = c.StatusAliasId
				and sa.StatusBaseId in (2) --Approved
			inner join Subject s
				on s.Id = c.SubjectId
			inner join CrosslistingCourse clc
				on clc.CourseId = c.Id
			inner join Crosslisting cl
				on cl.Id = clc.CrosslistingId
			where clc.Active = 1
			and clc.IsSynced = 0
			and tc.CourseId = tc.ActualCourseId
			and clc.CrosslistingId = tc.CourseCrossListingId

			union

			/*This section returns courses that are pre-active and pre-approved, are in the crosslisting and are not synced*/
			select
				 CourseId
			   , S.SubjectCode + '' '' + CourseNumber + '' (Pending Approval)'' as Courses
			   , case
					when CourseId = tc.CourseId then @IncludeSelected
					else 1
				 end as IncludeCourse
			   , cl.Title as CrosslistingTitle
			from course c
			inner join StatusAlias sa
				on sa.Id = c.StatusAliasId
				and sa.StatusBaseId in (4, 6) -- Draft, and In review
			inner join Subject s
				on s.Id = c.SubjectId
			inner join CrosslistingCourse clc
				on clc.CourseId = c.Id
			inner join Crosslisting cl
				on cl.Id = clc.CrosslistingId
			where clc.Active = 1
			and clc.IsSynced = 0
			and tc.CourseId = tc.ActualCourseId
			and clc.CrosslistingId = tc.CourseCrossListingId

			--union

			--/*This section returns courses that are historic, are in the crosslisting and are synced but no longer active with a date the course was added to the cross-listing
			--	and The date it was removed if it is no longer an active participant in the cross-listing*/
			--select
			--	 CourseId
			--   , EntityTitle + '' ('' + coalesce(''Added To Cross-listing '' + sd.StartDate + coalesce('' Removed From Cross-listing '' + ed.EndDate, ''''), ''Historic Proposal'') + '')'' as Courses
			--   , 1 as IncludeCourse
			--   , cl.Title as CrosslistingTitle
			--from course c
			--	inner join CrosslistingCourse clc on clc.CourseId = c.Id
			--	inner join Crosslisting cl on cl.Id = clc.CrosslistingId
			--	left join StartDates sd on tc.Id = sd.Id
			--							and c.EntityTitle = sd.StartTitle
			--	left join EndDates ed on tc.Id = ed.Id
			--							and c.EntityTitle = ed.EndTitle
			--where clc.Active = 0
			--and tc.CourseId = tc.ActualCourseId
			--and clc.IsSynced = 1
			--and clc.CrosslistingId = tc.CourseCrossListingId
			--and (clc.RemovedOn = (select top 1
			--		RemovedOn
			--	from CrossListingCourse
			--	where CourseId = tc.CourseId
			--	order by RemovedOn desc)
			--or clc.SyncedOn = (select top 1
			--		SyncedOn
			--	from CrossListingCourse
			--	where CourseId = tc.CourseId
			--	order by SyncedOn asc)
			--)
			--union

			--/* This section returns a message when the selected course is the only active course in the crosslisting */
			--select
			--	null as CourseId
			--   ,''There are no other active participants in this cross-listing'' as Courses
			--   ,1 as IncludeCourse
			--   ,cl.Title as CrosslistingTitle
			--from CrosslistingCourse clc
			--inner join Crosslisting cl
			--	on cl.Id = clc.CrosslistingId
			--	and clc.CourseId = tc.CourseId
			--	and tc.NoOtherCoursesInCrosslisting = 1
		) oa

)
	-- insert to match the order from the original function, if needed
	insert into @GetCrossListedCourses
	select c.targetCoursesId -- id of the TargetCourses variable table
	, c.CourseId -- the CrossListCourse.CourseId
	, c.Courses -- the original title from the fn
	, c.IncludeCourse -- should incoude cross listing course in display?
	from courses c

insert into @entityRelatedCourses (CourseId, RelatedCourseId, CourseIdentifier)
select f.CourseId
, f.CrossedCourseId
, f.CrossedCourse
from (
	select tc.ActualCourseId as CourseId
	, row_number() over (partition by gclc.TargetCoursesId order by gclc.Id) as SortOrder
	, gclc.CrossedCourseId
	-- this is for comparing against the real fn
	--, coalesce(concat(s.SubjectCode, '' '', c.CourseNumber), gclc.OriginalCrossCourseTitle)  as CrossedCourse
	, concat(s.SubjectCode, '' '', c.CourseNumber) as CrossedCourse
	, gclc.OriginalCrossCourseTitle
	from @targetCourses tc
		inner join @GetCrossListedCourses gclc on tc.Id = gclc.TargetCoursesId
		left join Course c on gclc.CrossedCourseId = c.Id
		left join [Subject] s on c.SubjectId = s.Id
	where gclc.IncludeCrossListCourse = 1
	and exists (
		select 1
		from @GetCrossListedCourses g
		where tc.Id = g.TargetCoursesId
		and tc.CourseId = g.CrossedCourseId
	)
) f
order by f.CourseId, f.SortOrder
;

--#endregion entity related courses

--#region effective term ranges
WITH CourseFamilies
AS
(
	--If multiple courses in the same family are included in @entityList_Internal, then we will get duplicates from this CTE
	--Using distinct to filter them out because it is a single column and that should be more efficient than an exists in this case
	SELECT DISTINCT
		c2.Id
	FROM @entityList_Internal eli
		INNER JOIN Course c ON eli.Id = c.Id
		--We want to pull in both the courses that are in @entityList_Internal and the other courses in their families
		--By just joining in c2 on BaseCourseId and not intentionally filtering out by c.Id <> c2.Id, that is what we will get
		INNER JOIN Course c2 ON c.BaseCourseId = c2.BaseCourseId
),
ConsideredCourses
AS
(
	SELECT
		c.Id
	   ,c.BaseCourseId
	   ,c.EntityTitle
	   ,sem.Title AS TermTitle
	   ,sem.TermStartDate
	   ,sem.TermEndDate
	   ,sb.Title AS StatusBase
	   ,sa.Title AS StatusAlias
	   ,dbo.fnTrimWhitespace(pat.Title) AS ProcessActionType
	   ,pat.Id AS ProcessActionTypeId
	FROM Course c
		INNER JOIN CourseFamilies cf ON c.Id = cf.Id
		INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
		INNER JOIN StatusBase sb ON sa.StatusBaseId = sb.Id
		INNER JOIN ProposalType pt ON c.ProposalTypeId = pt.Id
		INNER JOIN ProcessActionType pat ON pt.ProcessActionTypeId = pat.Id
		INNER JOIN CourseProposal cp ON c.Id = cp.CourseId
		INNER JOIN [Semester] sem ON cp.SemesterId = sem.Id
	WHERE c.Active = 1
	AND sa.StatusBaseId IN (1,2,5) --StatusBaseId 1 = Active,2 = Approved,5 = Historical
	AND sem.TermStartDate IS NOT NULL
	AND sem.TermEndDate IS NOT NULL
)
INSERT INTO @effectiveTermRanges
(Id, NextId, NextCourseProcessActionType, NextStatusBase, NextStatusAlias, EffectiveTermRangeStart, EffectiveTermRangeEnd)
	SELECT
		cc.Id
	   ,nc.Id AS NextId
	   ,nc.ProcessActionType AS NextCourseProcessActionType
	   ,nc.StatusBase AS NextStatusBase
	   ,nc.StatusAlias AS NextStatusAlias
	   ,cc.TermTitle AS EffectiveTermRangeStart
	   ,nc.TermTitle AS EffectiveTermRangeEnd
	FROM ConsideredCourses cc
		OUTER APPLY (
				SELECT TOP 1
					*
				FROM ConsideredCourses cc2
				WHERE cc.BaseCourseId = cc2.BaseCourseId
				AND cc2.TermStartDate > cc.TermStartDate
				ORDER BY cc2.TermStartDate, cc2.Id
			) nc;
--#endregion effective term ranges

--#region compose model
SELECT
	eli.Id
   ,m.Model
FROM @entityList_internal eli
	CROSS APPLY (
			SELECT
				(
					SELECT
						*
					FROM @entityRootData erd
					WHERE erd.Id = eli.Id
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
				)
				RootData
		) erd
	CROSS APPLY (
			SELECT
				(
					SELECT
						*
					FROM @entityGenEdAreas egea
					WHERE egea.CourseId = eli.Id
					ORDER BY egea.InsertOrder
					FOR JSON PATH
				)
				GenEdAreas
		) egea
	CROSS APPLY (
			SELECT
				(
					SELECT
						*
					FROM @entityGenEdElements egee
					WHERE egee.CourseId = eli.Id
					ORDER BY egee.InsertOrder
					FOR JSON PATH
				)
				GenEdElements
		) egee
	CROSS APPLY (
			SELECT
				(
					SELECT
						*
					FROM @entityRelatedCourses erc
					WHERE erc.CourseId = eli.Id
					ORDER BY erc.InsertOrder
					FOR JSON PATH
				)
				RelatedCourses
		) erc
	CROSS APPLY (
			SELECT
				(
					SELECT
						*
					FROM @effectiveTermRanges etr
					WHERE etr.Id = eli.Id
					FOR JSON PATH
				)
				EffectiveTermRanges
		) etr
	CROSS APPLY (
			SELECT
				(
					SELECT
						eli.InsertOrder
					   ,JSON_QUERY(erd.RootData) AS RootData
					   ,JSON_QUERY(egea.GenEdAreas) AS GenEdAreas
					   ,JSON_QUERY(egee.GenEdElements) AS GenEdElements
					   ,JSON_QUERY(erc.RelatedCourses) AS RelatedCourses
					   ,JSON_QUERY(etr.EffectiveTermRanges) AS EffectiveTermRanges
					FOR JSON PATH
				)
				Model
		) m
where (select ProcessActionType from @entityRootData erd where eli.Id = erd.Id) <> ''Deactivate''
ORDER BY eli.InsertOrder;
--#endregion compose model

--#endregion model query
'
WHERE Id = 2