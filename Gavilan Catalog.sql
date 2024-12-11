
		declare @entityList_internal table (
			InsertOrder int Identity(1, 1) primary key
			, CourseId int
		);

		insert into @entityList_internal (CourseId)
		select TOP 5000 Id FROM Course WHERE Active = 1 and Id not in (2578)

		declare @entityRootData table (	
			[Transfer] nvarchar(max),
			CSUArea nvarchar(max),
			IGETCArea nvarchar(max),
			TopCode nvarchar(max),
			CourseId int primary key,
			SubjectCode nvarchar(max),
			CourseNumber nvarchar(max),
			CourseTitle nvarchar(max),
			Variable bit,
			MinUnit decimal(16, 3),
			MaxUnit decimal(16, 3),
			MinLec decimal(16, 3),
			MaxLec decimal(16, 3),
			MinLab decimal(16, 3),
			MaxLab decimal(16, 3),
			MinLearn decimal(16,3),
			MaxLearn decimal(16,3), 
			TransferType nvarchar(max),
			Requisite nvarchar(max),
			Limitation nvarchar(max),
			Preperation nvarchar(max),
			CatalogDescription nvarchar(max),
			CourseGrading nvarchar(max),
			Suffix nvarchar(500),
			CID nvarchar(500),
			CIDStatus nvarchar(255),
			CIDNotes nvarchar(max),
			AdminRepeat nvarchar(max),
			EffectiveTerm nvarchar(255),
			MinTBA decimal(16, 3),
			MaxTBA decimal(16, 3),
			newcourse int,
			EFT nvarchar(255)
		);

		declare @clientId int = (
			select top 1 c.ClientId 
			from Course c
				inner join @entityList_internal eli on c.Id = eli.CourseId
		)


		declare @limitRequisiteQuery nvarchar(max) = (
			select CustomSql
			from MetaForeignKeyCriteriaClient
			where Title = 'Catalog Limit'
		)

		declare @prepRequisiteQuery nvarchar(max) = (
			select CustomSql
			from MetaForeignKeyCriteriaClient
			where Title = 'Catalog Prep'
		)

		declare @requisite_mfkccId int = 4012;
		declare @requisite_mfkccQuery nvarchar(max) = (
			select ResolutionSql
			from MetaForeignKeyCriteriaClient
			where Id = @requisite_mfkccId
		);

		-- ============================
		-- return
		-- ============================
		insert into @entityRootData (
			[Transfer]
			, CSUArea
			, IGETCArea
			, TopCode
			, CourseId
			, SubjectCode
			, CourseNumber
			, CourseTitle
			, Variable
			, MinUnit
			, MaxUnit
			, MinLec
			, MaxLec
			, MinLab
			, MaxLab
			, MinLearn
			, MaxLearn
			, TransferType
			, Requisite
			, Limitation
			, Preperation
			, CatalogDescription
			, CourseGrading
			, Suffix
			, CID
			, CIDStatus
			, CIDNotes
			, AdminRepeat
			, EffectiveTerm
			, MinTBA
			, MaxTBA
			, newcourse
			, EFT
		)
		select distinct
			replace(
				concat('',
					stuff(
						(select concat('~@', stuff((
							select '~@'+ coalesce(gee.text, '')
							from CourseGeneralEducation cge
								inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
								inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
							where cge.Active = 1 
								and gee.Active = 1 
								and cge.CourseId = c.Id
								and ge.Title = a.Title
							for xml path('')
							), 1, 2, '') 
						)
						from (select distinct ge.Title, ge.SortOrder
						from CourseGeneralEducation cge 
							inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
						where cge.Active = 1 
							and ge.Active = 1
							and cge.CourseId = c.Id
							and ge.Id in (22)) a
						order by a.SortOrder
						for xml path('') 
						)
					, 1, 2, '') 
				)
			,'~@',', '),
			replace(
				concat('',
					stuff(
						(select concat('~@', stuff((
							select '~@'+ coalesce(gee.text, '')
							from CourseGeneralEducation cge
								inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
								inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
							where cge.Active = 1 
								and gee.Active = 1 
								and cge.CourseId = c.Id
								and ge.Title = a.Title
							for xml path('')
							), 1, 2, '') 
						)
						from (select distinct ge.Title,ge.SortOrder
						from CourseGeneralEducation cge 
							inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
						where cge.Active = 1 
							and ge.Active = 1
							and cge.CourseId = c.Id
							and ge.Id in (5,15,16,17,18,20,23)) a
						order by a.SortOrder
						for xml path('') 
						)
					, 1, 2, '') 
				)
			,'~@',', '),
			replace(
				concat('',
					stuff(
						(select concat('~@', stuff((
							select '~@'+ coalesce(case when ge.id in (11,13,25) then LEFT(gee.text,1) else gee.text end, '')
							from CourseGeneralEducation cge
								inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
								inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
							where cge.Active = 1 
								and gee.Active = 1 
								and cge.CourseId = c.Id
								and ge.Title = a.Title
							for xml path('')
							), 1, 2, '') 
						)
						from (select distinct ge.Title,ge.SortOrder
						from CourseGeneralEducation cge 
							inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
						where cge.Active = 1 
							and ge.Active = 1
							and cge.CourseId = c.Id
							and ge.Id in (6,11,12,13,14,19,21,25)) a
						order by a.SortOrder
						for xml path('') 
						)
					, 1, 2, '') 
				)
			,'~@',', ')
			,stuff(CB03.Code, Len(CB03.Code)-1, 0, '.')
			, c.Id
			, s.SubjectCode
			, c.CourseNumber
			, c.Title
			, cd.Variable
			, cd.MinCreditHour
			, cd.MaxCreditHour
			, cd.MinLectureHour
			, cd.MaxLectureHour
			, cd.MinLabHour
			, cd.MaxLabHour
			, cd.MinContHour
			, cd.MaxContHour
			, ta.[Description]
			, REQ.[Text] as Requisite
			, limit.[Text]
			, prep.[Text]
			, lTrim(rTrim(c.[Description]))
			, gon.Title -- course grading
			, cs.Code --suffix
			, c.PatternNumber --CID
			, cwes.Title --CID Status
			, c.TangibleProperty --CID Notes
			, cp.TimesOfferedRationale --admin repeat
			, sem.Title
			, cd.MinFieldHour
			, cd.MaxFieldHour
			,CASE
        WHEN bc.ActiveCourseId IS NULL OR bc.ActiveCourseId <> c.Id
            THEN 
                CASE
                    WHEN pt2.ProcessActionTypeId = 2 -- modify
                        THEN 1
                    WHEN pt2.ProcessActionTypeId = 3 -- deactivate
                        THEN 2
                    ELSE 0
                END
        ELSE 0
    END
		, Semester2.Title
		from Course c
			left join BaseCourse AS bc  on c.BaseCourseId = bc.Id
			LEFT JOIN Course AS c2 ON c2.PreviousId = c.Id and c2.Active = 1 and c.BaseCourseId = c2.BaseCourseId
			LEFT JOIN CourseProposal AS cp2 on cp2.CourseId = c2.Id
			LEFT JOIN ProposalType AS pt2 on c2.ProposalTypeId = pt2.Id
			LEFT JOIN Semester AS Semester2 on cp2.SemesterId = Semester2.Id
			inner join @entityList_internal eli on c.Id = eli.CourseId
			inner join CourseDescription cd on c.Id = cd.CourseId
			inner join CourseProposal cp on cd.CourseId = cp.CourseId
			left join Semester sem on cp.SemesterId = sem.Id
			left join CourseCBCode ccc on c.Id = ccc.CourseId
			left join CourseCBCode ccbc on ccbc.CourseId = c.Id
			left join CB03 on ccbc.CB03Id = CB03.Id
			left join [Subject] s on c.SubjectId = s.Id
			left join GradeOption gon on cd.GradeOptionId = gon.Id
			left join ProposalType pt on c.ProposalTypeId = pt.Id
			left join ProcessActionType pat on pt.ProcessActionTypeId = pat.Id
			left join CourseYesNo cyn on c.Id = cyn.CourseId
			left join YesNo yn on cyn.YesNo05Id = yn.Id
			left join TransferApplication ta on ta.Id = cd.TransferAppsId
			left join CourseSuffix cs on cs.Id = c.CourseSuffixId
			left join ContinuingWorkforceEducationStudyCode cwes on c.AdvancedPro_ContinuingWorkforceEducationStudyCodeId = cwes.Id
			outer apply (
				select fn.[Text]
				from (
						select c.Id as entityId
						, @requisite_mfkccQuery as [query]
						, null as isAdmin
						, 1 as serializeRows
						, c.ClientId as client
						, null as userId
						, null as extraParams
					) p
					outer apply (
						select *
						from dbo.fnBulkResolveCustomSqlQuery(p.Query, p.serializeRows, p.entityId, p.client, p.userId, p.isAdmin, p.extraParams) q
					) fn
				where fn.QuerySuccess = 1 
				and fn.TextSuccess = 1
			) req
			outer apply (
				select *
				from dbo.fnBulkResolveCustomsqlquery(@limitRequisiteQuery, 1, c.Id, @clientId, NULL, NULL, NULL)
			) limit
			outer apply (
				select *
				from dbo.fnBulkResolveCustomsqlquery(@prepRequisiteQuery, 1, c.Id, @clientId, NULL, NULL, NULL)
			) prep

		select eli.CourseId as Id
			, m.Model
		from @entityList_internal eli
			cross apply (
				select (
					select *
					from @entityRootData erd
					where eli.CourseId = erd.CourseId
					for json path, without_array_wrapper
				) RootData
			) erd
			cross apply (
				select (
					select eli.InsertOrder
						, json_query(erd.RootData) as RootData
					for json path
				) Model
			) m
		;
	














	
--#region hide
declare 
	  @hoursScale0 int = 0
	, @hoursScale1 int = 1
	, @hoursScale2 int = 2
	, @hoursScale3 int = 3
;

declare 
	  @hoursDecimalFormat0 nvarchar(10) = concat('F', @hoursScale0)
	, @hoursDecimalFormat1 nvarchar(10) = concat('F', @hoursScale1)
	, @hoursDecimalFormat2 nvarchar(10) = concat('F', @hoursScale2)
	, @hoursDecimalFormat3 nvarchar(10) = '##0.0##'
	, @empty nvarchar(1) = ''
	, @space nvarchar(5) = ' '
	, @newLine nvarchar(5) = '
	'
	, @classAttrib nvarchar(10) = 'class'
	, @titleAttrib nvarchar(10) = 'title'
	, @openComment nvarchar(10) = '<!-- '
	, @closeComment nvarchar(10) = ' -->'
	, @styleAttribute nvarchar(5) = 'style'
;

declare @elementTags table (
	Id int,
	ElementTitle nvarchar(255) unique nonclustered,
	ElementTag nvarchar(10)
);

insert into @elementTags (Id, ElementTitle, ElementTag)
values
(1, 'SummaryWrapper', 'div'),
(2, 'Row', 'div'),
(3, 'Column', 'div'),
(4, 'DataElement', 'span'),
(5, 'Block', 'div'),
(6, 'Label', 'b'),
(7, 'Spacer', 'br'),
(8, 'BoldDataElement', 'b'),
(9, 'SecondaryLabel', 'u'),
(10, 'ItalicElement','i')
;

declare
	--The tag name to use for the group wrappers
	@summaryWrapperTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = 'SummaryWrapper'
)
,
--The tag name to use for the row wrappers
@rowTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = 'Row'
)
,
--The tag name to use for the column wrappers
@columnTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = 'Column'
)
,
--The tag name to use for the wrappers of the individual data elements inside the columns
@dataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = 'DataElement'
)
,
--The tag name to use for generic layout blocks
@blockTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = 'Block'
)
,
--The tag name to use for wrapping labels
@labelTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = 'Label'
)
,
--The tag name for elements to insert vertical blank lines between other elements
@spacerTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = 'Spacer'
)
,
--The tag name to use for wrappers around invidual data elements that should be bolded by default
--This allows for bolding of elements w/o having to edit the CSS
@boldDataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = 'BoldDataElement'
)
,
--The tag name for secondary labels; ones that need a different formatting than the primary labels
@secondaryLabelTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = 'SecondaryLabel'
),
@italicDataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = 'ItalicElement'
)
;

declare @elementClasses table (
	Id int primary key,
	ClassSetTitle nvarchar(255) unique nonclustered,
	Wrapper nvarchar(255),
	LeftColumn nvarchar(255),
	MiddleColumn nvarchar(255),
	RightColumn nvarchar(255),
	FullWidthColumn nvarchar(255),

	--Computed full class attributes
	WrapperAttrib as coalesce('class="' + Wrapper + '"', ''),
	LeftColumnAttrib as coalesce('class="' + LeftColumn + '"', ''),
	MiddleColumnAttrib as coalesce('class="' + MiddleColumn + '"', ''),
	RightColumnAttrib as coalesce('class="' + RightColumn + '"', ''),
	FullWidthColumnAttrib as coalesce('class="' + FullWidthColumn + '"', '')
);

insert into @elementClasses (Id, ClassSetTitle, Wrapper, LeftColumn, MiddleColumn, RightColumn, FullWidthColumn)
values
(1, 'ThreeColumn', 'row', 'col-xs-3 col-sm-3 col-md-1 text-left left-column', 'col-xs-6 col-sm-6 col-md-10 text-left middle-column', 'col-xs-3 col-sm-3 col-md-1 text-right right-column', null),
(2, 'TwoColumnShorterRight', 'row', 'col-xs-9 col-md-9 col-md-9 text-left left-column', null, 'col-xs-3 col-sm-3 col-md-3 text-right right-column', null),
(3, 'TwoColumnShortRight', 'row', 'col-xs-8 col-sm-8 col-md-8 text-left left-column', null, 'col-xs-4 col-sm-4 col-md-4 text-left right-column', null),
(4, 'FullWidthRow', 'row', null, null, null, 'col-xs-12 col-sm-12 col-md-12 text-left full-width-column')
;

declare @transferType1 NVARCHAR(max) = 'Acceptable to CSU, UC or Private'
declare @transferType2 NVARCHAR(max) = 'Acceptable to CSU or Private College'

--#endregion

declare @modelRoot table 
(
	CourseId int primary key,
	InsertOrder int,
	RootData nvarchar(max)
);

declare @modelRootData table
(
	Transfer nvarchar(max),
	CSUArea nvarchar(max),
	IGETCArea nvarchar(max),
	TopCode nvarchar(max),
	Department nvarchar(max),
	CourseId int primary key,
	SubjectCode nvarchar(max),
	CourseNumber nvarchar(max),
	CourseTitle nvarchar(max),
	Variable bit,
	MinUnit decimal(16, 3),
	MaxUnit decimal(16, 3),
	MinLec decimal(16, 3),
	MaxLec decimal(16, 3),
	MinLab decimal(16, 3),
	MaxLab decimal(16, 3),
  MinLearn decimal(16,3),
  MaxLearn decimal(16,3), 
  TransferType NVARCHAR(max),
  Requisite NVARCHAR(max),
  Limitation NVARCHAR(max),
  Preperation NVARCHAR(max),
  CatalogDescription nvarchar(max),
  CourseGrading nvarchar(max),
	Suffix NVARCHAR(500),
  CID NVARCHAR(500),
	CIDStatus nvarchar(255),
	CIDNotes nvarchar(max),
  AdminRepeat NVARCHAR(max),
	EffectiveTerm nvarchar(255),
	MinTBA decimal(16, 3),
	MaxTBA decimal(16, 3),
	newcourse int,
	EFT nvarchar(255)
);

declare @unitHourRanges table
(
	Id int not null identity primary key,
	CourseId int,
	UnitHourTypeId int,
	RenderedRange nvarchar(100)
);


DECLARE @entityModels TABLE ([key] int, value NVARCHAR(MAX))
INSERT INTO @entityModels
		select eli.CourseId as Id
			, m.Model
		from @entityList_internal eli
			cross apply (
				select (
					select *
					from @entityRootData erd
					where eli.CourseId = erd.CourseId
					for json path, without_array_wrapper
				) RootData
			) erd
			cross apply (
				select (
					select eli.InsertOrder
						, json_query(erd.RootData) as RootData
					for json path
				) Model
			) m
		;


insert into @modelRoot (CourseId, InsertOrder, RootData)
	select em.[Key]
	   , m.InsertOrder
	   , m.RootData
	from @entityModels em
	cross apply openjson(em.[Value])
		with (
			InsertOrder int '$.InsertOrder',
			RootData nvarchar(max) '$.RootData' as json
		) m
;

insert into @modelRootData (
	[Transfer],
	CSUArea,
	IGETCArea,
	TopCode,
	Department,
    CourseId
    , SubjectCode
    , CourseNumber
    , CourseTitle
    , Variable
    , MinUnit
    , MaxUnit
    , MinLec
    , MaxLec
    , MinLab
    , MaxLab
    , MinLearn
    , MaxLearn
    , TransferType
    , Requisite
    , Limitation
    , Preperation
    , CatalogDescription
    , CourseGrading
		, Suffix
    , CID
		, CIDStatus
		, CIDNotes
    , AdminRepeat
		, EffectiveTerm
		, MinTBA
		, MaxTBA
		, newcourse
		, EFT
)
select
	m.Transfer,
	m.CSUArea,
	m.IGETCArea,
	m.TopCode,
	m.Department,
	m.CourseId
	, case
		when m.SubjectCode is not null
			and len(m.SubjectCode) > 0
				then m.SubjectCode
		else @empty
	end as SubjectCode
	, case
		when m.CourseNumber is not null
			and len(m.CourseNumber) > 0
				then m.CourseNumber
		else @empty
	end as CourseNumber
	, case
		when m.CourseTitle is not null
			and len(m.CourseTitle) > 0
				then m.CourseTitle
		else @empty
	end as CourseTitle
	, m.Variable
	, m.MinUnit
	, m.MaxUnit
	, m.MinLec
	, m.MaxLec
	, m.MinLab
	, m.MaxLab
	, m.MinLearn
    , m.MaxLearn
    , case
        when m.TransferType is not null and len(m.TransferType) > 0
            then m.TransferType
            else @empty 
        end as TransferType
    , case
        when m.Requisite is not null and len(m.Requisite) > 0
            then m.Requisite
            else @empty
        end as Requisite
    , case
        when m.Limitation is not null and len(m.Limitation) > 0
            then m.Limitation
            else @empty
        end as Limitation
     , case
        when m.Preperation is not null and len(m.Preperation) > 0
            then m.Preperation
            else @empty
        end as Preperation
	, case
		when m.CatalogDescription is not null and len(m.CatalogDescription) > 0
            then m.CatalogDescription
		    else @empty
	end as CatalogDescription
	, case
		when m.CourseGrading is not null and len(m.CourseGrading) > 0
            then m.CourseGrading
		    else @empty
	end as CourseGrading
	,case
		when m.Suffix is not null and len(m.Suffix) > 0
			then m.Suffix
			else @empty
    end
    , case
        when m.CID is not null and len(m.CID) > 0
            then m.CID
        else @empty
    end
	, case
        when m.CIDStatus is not null and len(m.CIDStatus) > 0
            then m.CIDStatus
        else @empty
    end
	, case
        when m.CIDNotes is not null and len(m.CIDNotes) > 0
            then m.CIDNotes
        else @empty
    end
   ,  case
        when m.AdminRepeat is not null and len(m.AdminRepeat) > 0
            then m.AdminRepeat
        else @empty
    end
		 ,  case
        when m.EffectiveTerm is not null and len(m.EffectiveTerm) > 0
            then m.EffectiveTerm
        else @empty
    end
		, m.MinTBA
		, m.MaxTBA
		, m.newcourse
		, m.EFT
from @modelRoot mr
cross apply openjson(mr.RootData)
	with (
		Transfer nvarchar(max) '$.Transfer',
		CSUArea nvarchar(max) '$.CSUArea',
		IGETCArea nvarchar(max) '$.IGETCArea',
		TopCode nvarchar(max) '$.TopCode',
		Department nvarchar(max) '$.Department',
		CourseId int '$.CourseId',
		SubjectCode nvarchar(max) '$.SubjectCode',
		CourseNumber nvarchar(max) '$.CourseNumber',
		CourseTitle nvarchar(max) '$.CourseTitle',
		Variable bit '$.Variable',
		MinUnit decimal(16, 3) '$.MinUnit',
		MaxUnit decimal(16, 3) '$.MaxUnit',
		MinLec decimal(16, 3) '$.MinLec',
		MaxLec decimal(16, 3) '$.MaxLec',
		MinLab decimal(16, 3) '$.MinLab',
		MaxLab decimal(16, 3) '$.MaxLab',
    MinLearn decimal(16,3) '$.MinLearn',
    MaxLearn decimal(16,3) '$.MaxLearn',
    TransferType NVARCHAR(max) '$.TransferType',
    Requisite NVARCHAR(max) '$.Requisite',
    Limitation NVARCHAR(max) '$.Limitation',
    Preperation NVARCHAR(max) '$.Preperation',
    CatalogDescription NVARCHAR(max) '$.CatalogDescription',
    CourseGrading NVARCHAR(max) '$.CourseGrading',
		Suffix nvarchar(500) '$.Suffix',
    CID NVARCHAR(500) '$.CID',
		CIDStatus NVARCHAR(500) '$.CIDStatus',
		CIDNotes NVARCHAR(500) '$.CIDNotes',
    AdminRepeat NVARCHAR(500) '$.AdminRepeat',
		EffectiveTerm NVARCHAR(255) '$.EffectiveTerm',
		MinTBA decimal(16, 3) '$.MinTBA',
		MaxTBA decimal(16, 3) '$.MaxTBA',
		newcourse int '$.newcourse',
		EFT NVARCHAR(255) '$.EFT'
	) m


insert into @unitHourRanges (CourseId, UnitHourTypeId, RenderedRange)
select mrd.CourseId, uht.UnitHourTypeId, uhr.RenderedRange
from @modelRootData mrd
cross apply (
	select 1 as UnitHourTypeId -- units
		, mrd.MinUnit as MinVal
		, case when isnull(mrd.MaxUnit,0) = 0 then mrd.MinUnit else mrd.MaxUnit end as MaxVal
		, 1 as RenderIfZero
		, 0 as ForceRange
		, mrd.Variable
		, 3 as FormatType
		, 1 as Render
	union all
	select 2 as UnitHourTypeId -- lec
		, CEILING(mrd.MinLec * 10)/10.0 as MinVal
		, case when isnull(mrd.MaxLec,0) = 0 then CEILING(mrd.MinLec * 10) / 10.0 else CEILING(mrd.MaxLec * 10) / 10 end as MaxVal
		, 0 as RenderIfZero
		, 0 as ForceRange
		, mrd.Variable
		, 3 as FormatType
		, 1 as Render
	union all
	select 3 as UnitHourTypeId -- lab
		, CEILING(mrd.MinLab * 10) / 10.0 as MinVal
		, case when isnull(mrd.MaxLab,0) = 0 then CEILING(mrd.MinLab * 10) / 10 else CEILING(mrd.MaxLab * 10) / 10 end as MaxVal
		, 0 as RenderIfZero
		, 0 as ForceRange
		, mrd.Variable
		, 3 as FormatType
    , 1 as Render
   union all
   select 4 as UnitHourTypeId --learn
        ,mrd.MinLearn as MinVal
        , case when isnull(mrd.MaxLearn,0) = 0 then mrd.MinLearn else mrd.MaxLearn end as MaxVal
        , 0 as RenderIfZero
        , 0 as ForceRange
        , mrd.Variable
        , 3 as FormatType
        , 1 as Render
		union all
		select 5 as UnitHourTypeId --tba
				,mrd.MinTBA as MinVal
				, case when isnull(mrd.MaxTBA,0) = 0 then mrd.MinTBA else mrd.MaxTBA end as MaxVal
        , 0 as RenderIfZero
        , 0 as ForceRange
        , mrd.Variable
        , 3 as FormatType
        , 1 as Render
) uht
cross apply (
	select
		case
			when uht.Render = 1
				and (
						(
							uht.Variable = 1
							and uht.MinVal is not null
							and uht.MaxVal is not null
							and uht.MinVal != uht.MaxVal
						)
						or (
							uht.ForceRange = 1
						)
					) then concat(
						case when uht.MinVal <> 0 then format(uht.MinVal,
							case
								when uht.FormatType = 0 
									then @hoursDecimalFormat0
								when uht.FormatType = 1
									then @hoursDecimalFormat1
								when uht.FormatType = 3
									then @hoursDecimalFormat3
								else @hoursDecimalFormat2
							end
						) else '0' end,
						' - ',
						format(
							uht.MaxVal,
							case
								when uht.FormatType = 0
									then @hoursDecimalFormat0
								when uht.FormatType = 1
									then @hoursDecimalFormat1
								when uht.FormatType = 3
									then @hoursDecimalFormat3
								else @hoursDecimalFormat2
							end
						)
					) 
			when (uht.Render = 1
					and uht.MaxVal is not null
					and (uht.MaxVal > 0
						or uht.RenderIfZero = 1
					)
				) then case when uht.MaxVal <> 0 then format(
					uht.MaxVal,
					case
						when uht.FormatType = 0
							then @hoursDecimalFormat0
						when uht.FormatType = 1
							then @hoursDecimalFormat1
						when uht.FormatType = 3
							then @hoursDecimalFormat3
						else @hoursDecimalFormat2
					end
				)else '0.0' end
			else null
		end as RenderedRange
) uhr;

select mr.CourseId as [Value]
	-- custom-course-summary-context-wrapper
   , concat(
		dbo.fnHtmlOpenTag(@summaryWrapperTag,
			dbo.fnHtmlAttribute(@classAttrib, 'custom-course-summary-context-wrapper')
			),
			-- another nested wrapper
			dbo.fnHtmlOpenTag(@summaryWrapperTag, concat(
				dbo.fnHtmlAttribute(@classAttrib, 'container-fluid course-summary-wrapper'), @space,
				dbo.fnHtmlAttribute('data-course-id', mrd.CourseId)
				)
				),
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, 'course-summary-paragraph-header'))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
							UPPER(mrd.SubjectCode),@space,
							UPPER(SUBSTRING(mrd.CourseNumber, PATINDEX('%[^0]%', mrd.CourseNumber+'.'), LEN(mrd.CourseNumber)) ), case when mrd.Suffix is not null and len(mrd.Suffix) > 0 then concat(mrd.Suffix,@space) else '' end,
						'—',
							mrd.CourseTitle,
							' (',
							unithr.RenderedRange,
							')',


							case
								when mrd.newcourse = 0
									then ''
								when mrd.newcourse = 1
									then CONCAT('<span style="color: red;"> A new version of this course will be effective ', mrd.EFT, '</span>')
								when mrd.newcourse = 2
									then CONCAT('<span style="color: red;"> This course will be discontinued effective ', mrd.EFT, '</span>')
								else ''
								end,


					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
          --lecture
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-lecture-range')),
							isNull(lecthr.RenderedRange, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-lecture-label')),
							case 
								when len(lecthr.RenderedRange) > 0 then 
								case 
									when len(labhr.RenderedRange) > 0 then  ' Lecture' 
									else ' Lecture.' 
								end
								else @empty 
							end,
							case
								when len(lecthr.RenderedRange) is not null and len(labhr.RenderedRange) is not null then ', '
								else ''
							end,
						dbo.fnHtmlCloseTag(@dataElementTag),
--lab
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-lecture-range')),
														isNull(labhr.RenderedRange, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-lecture-label')),
							case 
								when len(labhr.RenderedRange) > 0 then 
									case 
										when labhr.RenderedRange <> '1' then  ' Lab.' 
										else ' Lab.' 
									end
								else @empty 
							end,
							case
								when len(learnhr.RenderedRange) is not null then ','
							end,
							@space,
						dbo.fnHtmlCloseTag(@dataElementTag),
----TBA
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-tba-range')),
														isNull(tba.RenderedRange, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-tba-label')),
							case 
								when len(tba.RenderedRange) > 0 then 
									case 
										when tba.RenderedRange <> '1' then  ' TBA.' 
										else ' TBA.' 
									end
								else @empty 
							end,
							@space,
						dbo.fnHtmlCloseTag(@dataElementTag),
				-- Course description
                    dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-description-value')),
                        case
                            when mrd.CatalogDescription is not null and len(mrd.CatalogDescription) > 0
                                then mrd.CatalogDescription
                                else @empty
                        end,@space,
                    dbo.fnHtmlCloseTag(@dataElementTag),
               		-- topcode
					dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, 'course-topcode-value')),
						@space,UPPER(mrd.TopCode),
					dbo.fnHtmlCloseTag(@DataElementTag),
										-- grading policy
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-grading-label')),
							'(', 
						dbo.fnHtmlCloseTag(@dataElementTag),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-grading-value')),
							case
								when mrd.CourseGrading = 'GC' then 'GR or P/NP'
								when mrd.CourseGrading = 'P/NP/SP' then 'SP or P/NP'
								else isNull(mrd.CourseGrading, @empty)
							end, ')',
							' Effective: ',
							mrd.EffectiveTerm,
							case
								when mrd.newcourse = 0
									then ''
								when mrd.newcourse = 1
									then CONCAT(' to ', mrd.EFT)
								when mrd.newcourse = 2
									then CONCAT(' to ', mrd.EFT)
								else ''
								end,


						dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- C-ID number, if applicable.
                dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, 'course-CID-row'))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					case
						when lower(mrd.CIDStatus) = 'approved' and mrd.CID is not null and len(mrd.CID) > 0
							then concat(
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-CID-value-prefix')),
									'(',
								dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-CID-value')),
									'C-ID: ', mrd.CID, 
								dbo.fnHtmlCloseTag(@dataElementTag),
								case 
									when mrd.CIDNotes is not null and len(mrd.CIDNotes) > 0 then concat(
										dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-CID-value-notes')),
											' ', mrd.CIDNotes,
										dbo.fnHtmlCloseTag(@dataElementTag)
									) -- Removed comma for MS-13571
									else @empty
								end,
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-CID-value-suffix')),
									')',
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
						else @empty
					end,
				dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
			dbo.fnHtmlCloseTag(@summaryWrapperTag),
		dbo.fnHtmlCloseTag(@summaryWrapperTag),'</div>'
	) as [Text]
from @modelRoot mr
inner join @modelRootData mrd on mr.CourseId = mrd.CourseId
left join @unitHourRanges unithr on (mr.CourseId = unithr.CourseId 
	and unithr.UnitHourTypeId = 1)
left join @unitHourRanges lecthr on (mr.CourseId = lecthr.CourseId 
	and lecthr.UnitHourTypeId = 2)
left join @unitHourRanges labhr on (mr.CourseId = labhr.CourseId 
	and labhr.UnitHourTypeId = 3)
left join @unitHourRanges learnhr on (mr.CourseId = learnhr.CourseId 
	and learnhr.UnitHourTypeId = 4)
left join @unitHourRanges tba on (mr.CourseId = tba.CourseId 
	and tba.UnitHourTypeId = 5)
inner join @elementClasses ecfw on ecfw.Id = 4 --4 = FullWidthRow
order by mr.InsertOrder;
