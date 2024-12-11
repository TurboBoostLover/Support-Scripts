USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15000';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog Query';
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
declare 
	  @hoursScale0 int = 0
	, @hoursScale1 int = 1
	, @hoursScale2 int = 2
;

declare 
	  @hoursDecimalFormat0 nvarchar(10) = concat(''F'', @hoursScale0)
	, @hoursDecimalFormat1 nvarchar(10) = concat(''F'', @hoursScale1)
	, @hoursDecimalFormat2 nvarchar(10) = concat(''F'', @hoursScale2)
	, @empty nvarchar(1) = ''''
	, @space nvarchar(5) = '' ''
	, @newLine nvarchar(5) = ''
	''
	, @classAttrib nvarchar(10) = ''class''
	, @titleAttrib nvarchar(10) = ''title''
	, @openComment nvarchar(10) = ''<!-- ''
	, @closeComment nvarchar(10) = '' -->''
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
(9, ''SecondaryLabel'', ''u'')
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

declare @modelRoot table 
(
	CourseId int primary key,
	InsertOrder int,
	RootData nvarchar(max)
);

declare @modelRootData table
(
	CourseId int primary key,
	SubjectCode nvarchar(max),
	CourseNumber nvarchar(max),
	CourseTitle nvarchar(max),
	Variable bit,
	MinUnit decimal(16, 3),
	MaxUnit decimal(16, 3),
	MinLec decimal(16, 3),
	LecStandard decimal(16, 3),
	MinLab decimal(16, 3),
	LabStandard decimal(16, 3),
	CourseType int,
	CourseGrading nvarchar(max),
	CreditByExamination nvarchar(max),
	RequisiteCatalogView nvarchar(max),
	CatalogDescription nvarchar(max),
	CIdNumber nvarchar(max),
	CB03 nvarchar(max),
	Cb05 nvarchar(max)
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
	CourseId,
	SubjectCode,
	CourseNumber,
	CourseTitle,
	Variable,
	MinUnit,
	MaxUnit,
	MinLec,
	LecStandard,
	MinLab,
	LabStandard,
	CourseType,
	CourseGrading,
	CreditByExamination,
	RequisiteCatalogView,
	CatalogDescription,
	CIdNumber,
	CB03,
	Cb05
)
select
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
	, m.LecStandard
	, m.MinLab
	, m.LabStandard
	, case
		when m.CourseType is not null
			and len(m.CourseType) > 0
				then m.CourseType
		else @empty
	end as CourseType
	, case
		when m.CourseGrading is not null
			and len(m.CourseGrading) > 0
				then m.CourseGrading
		else @empty
	end as CourseGrading
	, case
		when m.CreditByExamination is not null
			and len(m.CreditByExamination) > 0
				then m.CreditByExamination
		else @empty
	end as CreditByExamination
	, case
		when m.RequisiteCatalogView is not null
			and len(m.RequisiteCatalogView) > 0
				then m.RequisiteCatalogView
		else @empty
	end as RequisiteCatalogView
	, case
		when m.CatalogDescription is not null
			and len(m.CatalogDescription) > 0
				then m.CatalogDescription
		else @empty
	end as CatalogDescription
	, case
		when m.CIdNumber is not null
			and len(m.CIdNumber) > 0
				then m.CIdNumber
		else @empty
	end as CIdNumber
	, case
		when m.CB03 is not null
			and len(m.CB03) > 0
				then m.CB03
		else @empty
	end as CB03
	, case
		when m.Cb05 is not null
			and len(m.Cb05) > 0
				then m.Cb05
		else @empty
	end as CB05
from @modelRoot mr
cross apply openjson(mr.RootData)
	with (
		CourseId int ''$.CourseId'',
		SubjectCode nvarchar(max) ''$.SubjectCode'',
		CourseNumber nvarchar(max) ''$.CourseNumber'',
		CourseTitle nvarchar(max) ''$.CourseTitle'',
		Variable bit ''$.Variable'',
		MinUnit decimal(16, 3) ''$.MinUnit'',
		MaxUnit decimal(16, 3) ''$.MaxUnit'',
		MinLec decimal(16, 3) ''$.MinLec'',
		LecStandard decimal(16, 3) ''$.LecStandard'',
		MinLab decimal(16, 3) ''$.MinLab'',
		LabStandard decimal(16, 3) ''$.LabStandard'',
		CourseType int ''$.CourseType'',
		CourseGrading nvarchar(max) ''$.CourseGrading'',
		CreditByExamination nvarchar(max) ''$.CreditByExamination'',
		RequisiteCatalogView nvarchar(max) ''$.RequisiteCatalogView'',
		CatalogDescription nvarchar(max) ''$.CatalogDescription'',
		CIdNumber nvarchar(max) ''$.CIdNumber'',
		CB03 nvarchar(max) ''$.CB03'',
		Cb05 nvarchar(max) ''$.Cb05''
	) m

insert into @unitHourRanges (CourseId, UnitHourTypeId, RenderedRange)
select mrd.CourseId, uht.UnitHourTypeId, uhr.RenderedRange
from @modelRootData mrd
cross apply (
	select 1 as UnitHourTypeId -- units
		, mrd.MinUnit as MinVal
		, mrd.MaxUnit as MaxVal
		, 1 as RenderIfZero
		, 0 as ForceRange
		, mrd.Variable
		, 2 as FormatType
		, 1 as Render
	union all
	select 2 as UnitHourTypeId -- lec
		, mrd.MinLec as MinVal
		, mrd.LecStandard as MaxVal
		, 1 as RenderIfZero
		, 1 as ForceRange
		, 0 as FormatType
		, 0 as Variable
		, case
			when mrd.CourseType in (7, 11,19)
				and mrd.MinLec is not null
				and mrd.LecStandard is not null
					then 1
			else 0
		end as Render
	union all
	select 3 as UnitHourTypeId -- lab
		, mrd.MinLab as MinVal
		, mrd.LabStandard as MaxVal
		, 1 as RenderIfZero
		, 1 as ForceRange
		, 3 as FormatType
		, 0 as Variable
		, case
			when mrd.CourseType in (8, 9, 10, 17, 18, 11)
				and mrd.MinLab is not null
				and mrd.LabStandard is not null
					then 1
			else 0
		end as Render
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
						format(uht.MinVal,
							case
								when uht.FormatType = 0 
									then @hoursDecimalFormat0
								when uht.FormatType = 1
									then @hoursDecimalFormat1
								else @hoursDecimalFormat2
							end
						),
						''-'',
						format(
							uht.MaxVal,
							case
								when uht.FormatType = 0
									then @hoursDecimalFormat0
								when uht.FormatType = 1
									then @hoursDecimalFormat1
								else @hoursDecimalFormat2
							end
						)
					)
			when (uht.Render = 1
					and uht.MinVal is not null
					and (uht.MinVal > 0
						or uht.RenderIfZero = 1
					)
				) then format(
					uht.MinVal,
					case
						when uht.FormatType = 0
							then @hoursDecimalFormat0
						when uht.FormatType = 1
							then @hoursDecimalFormat1
						else @hoursDecimalFormat2
					end
				)
			else null
		end as RenderedRange
) uhr

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
				-- Course Title row (Course subject code, number, and title)
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-title-header''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, ''course-subject'')),
							mrd.SubjectCode,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-title-course-number-delimeter'')),
							''-'',
						dbo.fnHtmlCloseTag(@dataElementTag),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-number'')),
							mrd.CourseNumber, @space,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-title'')),
							mrd.CourseTitle,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- units
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-units-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-unit-label'')),
							''Units:'', @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-unit-range'')),
							 isNull(unithr.RenderedRange, ''0.00''),
						dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- hours
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-lab-lec-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lab-lec-label'')),
							''Hours:'', @space, case when MRD.CourseType = 12 then ''One course unit will equal 60 hours of volunteer/unpaid work OR one unit will equal 75 hours of paid work.'' else '''' end,
						dbo.fnHtmlCloseTag(@dataElementTag),
						-- lecture
						case
							when lecthr.RenderedRange is not null
								and len(lecthr.RenderedRange) > 0 
									then concat(
										dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-hours-wrapper'')),
											dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-hours-range'')),
												lecthr.RenderedRange,
											dbo.fnHtmlCloseTag(@dataElementTag),
											dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-hours-label'')),
												@space, case when MRD.CourseType = 19 then ''Studio.'' else ''Lecture.'' end,
											dbo.fnHtmlCloseTag(@dataElementTag),
										dbo.fnHtmlCloseTag(@dataElementTag)
									)
							else concat(@openComment, ''No lecture hours'', @closeComment, @empty)
						end,
						-- lab
						case
							when labhr.RenderedRange is not null
								and len(labhr.RenderedRange) > 0
								then concat(
									@space,
									dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lab-hours-wrapper'')),
										dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lab-hours-range'')),
											labhr.RenderedRange,
										dbo.fnHtmlCloseTag(@dataElementTag),
										dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lab-hours-label'')),
											@space, ''Laboratory.'',
										dbo.fnHtmlCloseTag(@dataElementTag),
									dbo.fnHtmlCloseTag(@dataElementTag)
								)
							else concat(@openComment, ''No laboratory hours'', @closeComment, @empty)
						end,
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- grading
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-grading-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-grading-label'')),
							''Grading:'', @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-grading-value'')),
							isNull(mrd.CourseGrading, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- credit by examniation
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-credit-examination-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-credit-examination-label'')),
							''Credit for Prior Learning:'', @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-credit-examination-value'')),
							isNull(mrd.CreditByExamination, @empty), @space,
						dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- summary
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-requisite-description-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, ''course-requisite-catalog-view'')),
							isNull(mrd.RequisiteCatalogView, @empty),
						dbo.fnHtmlCloseTag(@rowTag),
						case
							when mrd.RequisiteCatalogView is not null
								then @space
							else @empty
						end,
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-catalog-description-view'')),
							isNull(mrd.CatalogDescription, @empty),
						dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
				-- c-id, cb03, cb05
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, ''course-cidnumber-cb03-cb05-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						-- cidnumber
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cidnumber-wrapper'')),
							dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cidnumber-label'')),
								case 
									when mrd.CIDNumber is not null
										and mrd.CIDNumber <> ''''
											then concat(''C-ID:'', @space)
									else @empty
								end,
							dbo.fnHtmlCloseTag(@dataElementTag),
							dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cidnumber-value'')),
								isNull(mrd.CIdNumber, @empty),
							dbo.fnHtmlCloseTag(@dataElementTag),
						dbo.fnHtmlCloseTag(@dataElementTag),
						-- delimeter
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cidnumber-cb03-cb05-delimeter'')),
							case
								when mrd.CIDNumber is not null
									and mrd.CIDNumber <> ''''
										then concat(@space, ''-'', @space)
								else @empty
							end,
						dbo.fnHtmlCloseTag(@dataElementTag),
						-- cb03
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cb03-wrapper'')),
							dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cidnumber-label'')),
								concat(''TOP Code:'', @space),
							dbo.fnHtmlCloseTag(@dataElementTag),
							dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cidnumber-value'')),
								isNull(mrd.CB03, @empty),
							dbo.fnHtmlCloseTag(@dataElementTag),
						dbo.fnHtmlCloseTag(@dataElementTag),
						-- delimeter
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cidnumber-cb03-cb05-delimeter'')),
							concat(@space, ''-'', @space),
						dbo.fnHtmlCloseTag(@dataElementTag),
						-- cb05
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cb05-wrapper'')),
							dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cidnumber-value'')),
								concat(''Transfer Status:'',@space),
								isNull(mrd.CB05, @empty),
							dbo.fnHtmlCloseTag(@dataElementTag),
						dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),
			dbo.fnHtmlCloseTag(@summaryWrapperTag),
		dbo.fnHtmlCloseTag(@summaryWrapperTag)
	) as [Text]
from @modelRoot mr
inner join @modelRootData mrd on mr.CourseId = mrd.CourseId
left join @unitHourRanges unithr on (mr.CourseId = unithr.CourseId 
	and unithr.UnitHourTypeId = 1)
left join @unitHourRanges lecthr on (mr.CourseId = lecthr.CourseId 
	and lecthr.UnitHourTypeId = 2)
left join @unitHourRanges labhr on (mr.CourseId = labhr.CourseId 
	and labhr.UnitHourTypeId = 3)
inner join @elementClasses ecfw on ecfw.Id = 4 --4 = FullWidthRow
order by mr.InsertOrder;
'
WHERE Id = 2
