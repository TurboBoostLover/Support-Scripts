USE [gavilan];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18791';
DECLARE @Comments nvarchar(Max) = 
	'Update Curriculum Presentation to remove the ?';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 1; /*  Default 1 is Support,  
For a complete list run the following query

Select * from history.ScriptType
*/

SELECT
 @@servername AS 'Server Name' 
,DB_NAME() AS 'Database Name'
,@JiraTicketNumber as 'Jira Ticket Number';

SET XACT_ABORT ON
BEGIN TRAN

If exists(select top 1 1 from History.ScriptsRunOnDatabase where TicketNumber = @JiraTicketNumber and Developer = @Developer and Comments = @Comments)
	THROW 51000, 'This Script has already been run', 1;

INSERT INTO History.ScriptsRunOnDatabase
(TicketNumber,Developer,Comments,ScriptTypeId)
VALUES
(@JiraTicketNumber, @Developer, @Comments, @ScriptTypeId); 

/*--------------------------------------------------------------------
Please do not alter the script above this comment  except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing somehting 
		 that is against meta best practices but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql

-----------------Script details go below this line------------------*/
UPDATE OutputTemplateClient
SET TemplateQuery = '
--#region hide
declare 
	  @hoursScale0 int = 0
	, @hoursScale1 int = 1
	, @hoursScale2 int = 2
	, @hoursScale3 int = 3
;

declare 
	  @hoursDecimalFormat0 nvarchar(10) = concat(''F'', @hoursScale0)
	, @hoursDecimalFormat1 nvarchar(10) = concat(''F'', @hoursScale1)
	, @hoursDecimalFormat2 nvarchar(10) = concat(''F'', @hoursScale2)
	, @hoursDecimalFormat3 nvarchar(10) = ''##0.0##''
	, @empty nvarchar(1) = ''''
	, @space nvarchar(5) = '' ''
	, @newLine nvarchar(5) = ''
	''
	, @classAttrib nvarchar(10) = ''class''
	, @titleAttrib nvarchar(10) = ''title''
	, @openComment nvarchar(10) = ''<!-- ''
	, @closeComment nvarchar(10) = '' -->''
	, @styleAttribute nvarchar(5) = ''style''
;

declare @elementTags table (
	Id int,
	ElementTitle nvarchar(255) unique nonclustered,
	ElementTag nvarchar(10)
);

insert into @elementTags (Id, ElementTitle, ElementTag)
values
(1, ''SummaryWrapper'', ''div''),
(2, ''Row'', ''div''),
(3, ''Column'', ''div''),
(4, ''DataElement'', ''span''),
(5, ''Block'', ''div''),
(6, ''Label'', ''b''),
(7, ''Spacer'', ''br''),
(8, ''BoldDataElement'', ''b''),
(9, ''SecondaryLabel'', ''u''),
(10, ''ItalicElement'',''i'')
;

declare
	--The tag name to use for the group wrappers
	@summaryWrapperTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''SummaryWrapper''
)
,
--The tag name to use for the row wrappers
@rowTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Row''
)
,
--The tag name to use for the column wrappers
@columnTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Column''
)
,
--The tag name to use for the wrappers of the individual data elements inside the columns
@dataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''DataElement''
)
,
--The tag name to use for generic layout blocks
@blockTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Block''
)
,
--The tag name to use for wrapping labels
@labelTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Label''
)
,
--The tag name for elements to insert vertical blank lines between other elements
@spacerTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''Spacer''
)
,
--The tag name to use for wrappers around invidual data elements that should be bolded by default
--This allows for bolding of elements w/o having to edit the CSS
@boldDataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''BoldDataElement''
)
,
--The tag name for secondary labels; ones that need a different formatting than the primary labels
@secondaryLabelTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''SecondaryLabel''
),
@italicDataElementTag nvarchar(10) = (
	select ElementTag
	from @elementTags
	where ElementTitle = ''ItalicElement''
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
	WrapperAttrib as coalesce(''class="'' + Wrapper + ''"'', ''''),
	LeftColumnAttrib as coalesce(''class="'' + LeftColumn + ''"'', ''''),
	MiddleColumnAttrib as coalesce(''class="'' + MiddleColumn + ''"'', ''''),
	RightColumnAttrib as coalesce(''class="'' + RightColumn + ''"'', ''''),
	FullWidthColumnAttrib as coalesce(''class="'' + FullWidthColumn + ''"'', '''')
);

insert into @elementClasses (Id, ClassSetTitle, Wrapper, LeftColumn, MiddleColumn, RightColumn, FullWidthColumn)
values
(1, ''ThreeColumn'', ''row'', ''col-xs-3 col-sm-3 col-md-1 text-left left-column'', ''col-xs-6 col-sm-6 col-md-10 text-left middle-column'', ''col-xs-3 col-sm-3 col-md-1 text-right right-column'', null),
(2, ''TwoColumnShorterRight'', ''row'', ''col-xs-9 col-md-9 col-md-9 text-left left-column'', null, ''col-xs-3 col-sm-3 col-md-3 text-right right-column'', null),
(3, ''TwoColumnShortRight'', ''row'', ''col-xs-8 col-sm-8 col-md-8 text-left left-column'', null, ''col-xs-4 col-sm-4 col-md-4 text-left right-column'', null),
(4, ''FullWidthRow'', ''row'', null, null, null, ''col-xs-12 col-sm-12 col-md-12 text-left full-width-column'')
;

declare @transferType1 NVARCHAR(max) = ''Acceptable to CSU, UC or Private''
declare @transferType2 NVARCHAR(max) = ''Acceptable to CSU or Private College''

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

insert into @modelRoot (CourseId, InsertOrder, RootData)
	select em.[Key]
	   , m.InsertOrder
	   , m.RootData
	from @entityModels em
	cross apply openjson(em.[Value])
		with (
			InsertOrder int ''$.InsertOrder'',
			RootData nvarchar(max) ''$.RootData'' as json
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
		Transfer nvarchar(max) ''$.Transfer'',
		CSUArea nvarchar(max) ''$.CSUArea'',
		IGETCArea nvarchar(max) ''$.IGETCArea'',
		TopCode nvarchar(max) ''$.TopCode'',
		Department nvarchar(max) ''$.Department'',
		CourseId int ''$.CourseId'',
		SubjectCode nvarchar(max) ''$.SubjectCode'',
		CourseNumber nvarchar(max) ''$.CourseNumber'',
		CourseTitle nvarchar(max) ''$.CourseTitle'',
		Variable bit ''$.Variable'',
		MinUnit decimal(16, 3) ''$.MinUnit'',
		MaxUnit decimal(16, 3) ''$.MaxUnit'',
		MinLec decimal(16, 3) ''$.MinLec'',
		MaxLec decimal(16, 3) ''$.MaxLec'',
		MinLab decimal(16, 3) ''$.MinLab'',
		MaxLab decimal(16, 3) ''$.MaxLab'',
    MinLearn decimal(16,3) ''$.MinLearn'',
    MaxLearn decimal(16,3) ''$.MaxLearn'',
    TransferType NVARCHAR(max) ''$.TransferType'',
    Requisite NVARCHAR(max) ''$.Requisite'',
    Limitation NVARCHAR(max) ''$.Limitation'',
    Preperation NVARCHAR(max) ''$.Preperation'',
    CatalogDescription NVARCHAR(max) ''$.CatalogDescription'',
    CourseGrading NVARCHAR(max) ''$.CourseGrading'',
		Suffix nvarchar(500) ''$.Suffix'',
    CID NVARCHAR(500) ''$.CID'',
		CIDStatus NVARCHAR(500) ''$.CIDStatus'',
		CIDNotes NVARCHAR(500) ''$.CIDNotes'',
    AdminRepeat NVARCHAR(500) ''$.AdminRepeat'',
		EffectiveTerm NVARCHAR(255) ''$.EffectiveTerm'',
		MinTBA decimal(16, 3) ''$.MinTBA'',
		MaxTBA decimal(16, 3) ''$.MaxTBA'',
		newcourse int ''$.newcourse'',
		EFT NVARCHAR(255) ''$.EFT''
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
						) else ''0'' end,
						'' - '',
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
				)else ''0.0'' end
			else null
		end as RenderedRange
) uhr;

select mr.CourseId as [Value]
	-- custom-course-summary-context-wrapper
   , concat(
		dbo.fnHtmlOpenTag(@summaryWrapperTag,
			dbo.fnHtmlAttribute(@classAttrib, ''custom-course-summary-context-wrapper'')
			),
			-- another nested wrapper
			dbo.fnHtmlOpenTag(@summaryWrapperTag, concat(
				dbo.fnHtmlAttribute(@classAttrib, ''container-fluid course-summary-wrapper''), @space,
				dbo.fnHtmlAttribute(''data-course-id'', mrd.CourseId)
				)
				),
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-summary-paragraph-header''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
							UPPER(mrd.SubjectCode),@space,
							UPPER(SUBSTRING(mrd.CourseNumber, PATINDEX(''%[^0]%'', mrd.CourseNumber+''.''), LEN(mrd.CourseNumber)) ), case when mrd.Suffix is not null and len(mrd.Suffix) > 0 then concat(mrd.Suffix,@space) else '''' end,
						''-'',
							mrd.CourseTitle,
							'' ('',
							unithr.RenderedRange,
							'')'',


							case
								when mrd.newcourse = 0
									then ''''
								when mrd.newcourse = 1
									then CONCAT(''<span style="color: red;"> A new version of this course will be effective '', mrd.EFT, ''</span>'')
								when mrd.newcourse = 2
									then CONCAT(''<span style="color: red;"> This course will be discontinued effective '', mrd.EFT, ''</span>'')
								else ''''
								end,


					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
          --lecture
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-range'')),
							isNull(lecthr.RenderedRange, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-label'')),
							case 
								when len(lecthr.RenderedRange) > 0 then 
								case 
									when len(labhr.RenderedRange) > 0 then  '' Lecture'' 
									else '' Lecture.'' 
								end
								else @empty 
							end,
							case
								when len(lecthr.RenderedRange) is not null and len(labhr.RenderedRange) is not null then '', ''
								else ''''
							end,
						dbo.fnHtmlCloseTag(@dataElementTag),
--lab
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-range'')),
														isNull(labhr.RenderedRange, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-label'')),
							case 
								when len(labhr.RenderedRange) > 0 then 
									case 
										when labhr.RenderedRange <> ''1'' then  '' Lab.'' 
										else '' Lab.'' 
									end
								else @empty 
							end,
							case
								when len(learnhr.RenderedRange) is not null then '',''
							end,
							@space,
						dbo.fnHtmlCloseTag(@dataElementTag),
----TBA
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-tba-range'')),
														isNull(tba.RenderedRange, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
                        dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-tba-label'')),
							case 
								when len(tba.RenderedRange) > 0 then 
									case 
										when tba.RenderedRange <> ''1'' then  '' TBA.'' 
										else '' TBA.'' 
									end
								else @empty 
							end,
							@space,
						dbo.fnHtmlCloseTag(@dataElementTag),
				-- Course description
                    dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-description-value'')),
                        case
														when mrd.CatalogDescription is not null and len(mrd.CatalogDescription) > 0 and gmt.TextMax01 IS NOT NULL and len(gmt.TextMax01) > 0
														Then CONCAT(''Description Part 1: '', gmt.TextMax01, ''Description Part 2: '', mrd.CatalogDescription)
                            when mrd.CatalogDescription is not null and len(mrd.CatalogDescription) > 0
                                then mrd.CatalogDescription
                                else @empty
                        end,@space,
                    dbo.fnHtmlCloseTag(@dataElementTag),
               		-- topcode
					dbo.fnHtmlOpenTag(@DataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-topcode-value'')),
						@space,UPPER(mrd.TopCode),
					dbo.fnHtmlCloseTag(@DataElementTag),
										-- grading policy
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-grading-label'')),
							''('', 
						dbo.fnHtmlCloseTag(@dataElementTag),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-grading-value'')),
							case
								when mrd.CourseGrading = ''GC'' then ''GR or P/NP''
								when mrd.CourseGrading = ''P/NP/SP'' then ''SP or P/NP''
								else isNull(mrd.CourseGrading, @empty)
							end, '')'',
							'' Effective: '',
							mrd.EffectiveTerm,
							case
								when mrd.newcourse = 0
									then ''''
								when mrd.newcourse = 1
									then CONCAT('' to '', mrd.EFT)
								when mrd.newcourse = 2
									then CONCAT('' to '', mrd.EFT)
								else ''''
								end,


						dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- C-ID number, if applicable.
                dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-CID-row''))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					case
						when lower(mrd.CIDStatus) = ''approved'' and mrd.CID is not null and len(mrd.CID) > 0
							then concat(
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CID-value-prefix'')),
									''('',
								dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CID-value'')),
									''C-ID: '', mrd.CID, 
								dbo.fnHtmlCloseTag(@dataElementTag),
								case 
									when mrd.CIDNotes is not null and len(mrd.CIDNotes) > 0 then concat(
										dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CID-value-notes'')),
											'' '', mrd.CIDNotes,
										dbo.fnHtmlCloseTag(@dataElementTag)
									) -- Removed comma for MS-13571
									else @empty
								end,
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CID-value-suffix'')),
									'')'',
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
						else @empty
					end,
				dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
			dbo.fnHtmlCloseTag(@summaryWrapperTag),
		dbo.fnHtmlCloseTag(@summaryWrapperTag),''</div>''
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
left join GenericMaxText AS gmt on gmt.CourseId = mr.CourseId
order by mr.InsertOrder;
'
WHERE Id = 2