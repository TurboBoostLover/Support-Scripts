USE [madera];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19755';
DECLARE @Comments nvarchar(Max) = 
	'Add Catalog query for Course';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
INSERT INTO CurriculumPresentation
(Title, Description, CurriculumPresentationGroupId, ClientId, StartDate)
VALUES
('Course Requisites Summary', 'Summary of course requisites for use in the course catalog summaries and reports.', 1, 1, GETDATE())

DECLARE @Req int = SCOPE_IDENTITY()

INSERT INTO OutputTemplateClient
(TemplateQuery, Title, Description, StartDate)
VALUES
('
declare @modelRoot table (
	InsertOrder int identity primary key,
	CourseId int
);

insert into @modelRoot
select [Key]
from @entityModels;
--values (346), (347)

DECLARE @SQL NVARCHAR(MAX) = (SELECT CustomSQL FROM MetaForeignKeyCriteriaClient WHERE Id = 90)

SELECT r.Text AS Text,
c.ID AS Value
FROM Course AS c
INNER JOIN @modelRoot AS mr on mr.CourseId = c.Id
CROSS APPLY dbo.fnBulkResolveCustomSqlQuery(@SQL, 1, c.Id, 1, 2, 1, NULL) r
', 'Course Requisites Summary', 'Summary of course requisites for use in the course catalog summaries and reports.', GETDATE())

DECLARE @ReqTemp int = SCOPE_IDENTITY()

INSERT INTO OutputTemplateModelMappingClient
(OutputTemplateBaseId, OutputTemplateClientId, OutputModelBaseId, OutputModelClientId, Title, Description)
VALUES
(NULL, @ReqTemp, 1, NULL, 'Course requisites summary mapping', 'This mapping is for mapping together the model and template for the course requisites summaries')

DECLARE @Reqmap int = SCOPE_IDENTITY()

INSERT INTO CurriculumPresentationOutputFormat
(CurriculumPresentationId, OutputTemplateModelMappingBaseId, OutputTemplateModelMappingClientId, OutputFormatId)
VALUES
(@Req, NULL, @Reqmap, 4),
(@Req, NULL, @Reqmap, 5)

SET QUOTED_IDENTIFIER OFF

DECLARE @TempQuery NVARCHAR(MAX)= "
--#region query
declare 
	  @hoursScale0 int = 0
	, @hoursScale1 int = 1
	, @hoursScale2 int = 2
;

declare 
	  @hoursDecimalFormat0 nvarchar(10) = concat('F', @hoursScale0)
	, @hoursDecimalFormat1 nvarchar(10) = concat('F', @hoursScale1)
	, @hoursDecimalFormat2 nvarchar(10) = concat('F', @hoursScale2)
	, @empty nvarchar(1) = ''
	, @space nvarchar(5) = ' '
	, @newLine nvarchar(5) = 
	'
	'
	, @classAttrib nvarchar(10) = 'class'
	, @titleAttrib nvarchar(10) = 'title'
	, @openComment nvarchar(10) = '<!-- '
	, @closeComment nvarchar(10) = ' -->'
	, @emptyValueDisplay nvarchar(5) = 'None'
	, @emptyNumericValueDisplay nvarchar(5) = '0'
	, @seperator nvarchar(5) = '. '
;

declare @elementTags table (
	Id int,
	ElementTitle nvarchar(255) unique nonclustered,
	ElementTag nvarchar(10)
);

insert into @elementTags
(Id, ElementTitle, ElementTag)
values
(1, 'SummaryWrapper', 'div'),
(2, 'Row', 'div'),
(3, 'Column', 'div'),
(4, 'DataElement', 'span'),
(5, 'Block', 'div'),
(6, 'Label', 'span'),
(7, 'Spacer', 'br'),
(8, 'BoldDataElement', 'b'),
(9, 'SecondaryLabel', 'u')
;

declare
	--The tag name to use for the group wrappers
	@summaryWrapperTag nvarchar(10) = (
	select
		ElementTag
	from @elementTags
	where ElementTitle = 'SummaryWrapper'
)
,
--The tag name to use for the row wrappers
@rowTag nvarchar(10) = (
	select
		ElementTag
	from @elementTags
	where ElementTitle = 'Row'
)
,
--The tag name to use for the column wrappers
@columnTag nvarchar(10) = (
	select
		ElementTag
	from @elementTags
	where ElementTitle = 'Column'
)
,
--The tag name to use for the wrappers of the individual data elements inside the columns
@dataElementTag nvarchar(10) = (
	select
		ElementTag
	from @elementTags
	where ElementTitle = 'DataElement'
)
,
--The tag name to use for generic layout blocks
@blockTag nvarchar(10) = (
	select
		ElementTag
	from @elementTags
	where ElementTitle = 'Block'
)
,
--The tag name to use for wrapping labels
@labelTag nvarchar(10) = (
	select
		ElementTag
	from @elementTags
	where ElementTitle = 'Label'
)
,
--The tag name for elements to insert vertical blank lines between other elements
@spacerTag nvarchar(10) = (
	select
		ElementTag
	from @elementTags
	where ElementTitle = 'Spacer'
)
,
--The tag name to use for wrappers around invidual data elements that should be bolded by default
--This allows for bolding of elements w/o having to edit the CSS
@boldDataElementTag nvarchar(10) = (
	select
		ElementTag
	from @elementTags
	where ElementTitle = 'BoldDataElement'
)
,
--The tag name for secondary labels; ones that need a different formatting than the primary labels
@secondaryLabelTag nvarchar(10) = (
	select
		ElementTag
	from @elementTags
	where ElementTitle = 'SecondaryLabel'
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
	WrapperAttrib as coalesce('class=""' + Wrapper + '""', ''),
	LeftColumnAttrib as coalesce('class=""' + LeftColumn + '""', ''),
	MiddleColumnAttrib as coalesce('class=""' + MiddleColumn + '""', ''),
	RightColumnAttrib as coalesce('class=""' + RightColumn + '""', ''),
	FullWidthColumnAttrib as coalesce('class=""' + FullWidthColumn + '""', '')
);

insert into @elementClasses
(Id, ClassSetTitle, Wrapper, LeftColumn, MiddleColumn, RightColumn, FullWidthColumn)
values
(1, 'ThreeColumn', 'row', 'col-xs-3 col-sm-3 col-md-1 text-left left-column', 'col-xs-6 col-sm-6 col-md-10 text-left middle-column', 'col-xs-3 col-sm-3 col-md-1 text-right right-column', NULL),
(2, 'TwoColumnShorterRight', 'row', 'col-xs-9 col-md-9 col-md-9 text-left left-column', NULL, 'col-xs-3 col-sm-3 col-md-3 text-right right-column', NULL),
(3, 'TwoColumnShortRight', 'row', 'col-xs-8 col-sm-8 col-md-8 text-left left-column', NULL, 'col-xs-4 col-sm-4 col-md-4 text-left right-column', NULL),
(4, 'FullWidthRow', 'row', NULL, NULL, NULL, 'col-xs-12 col-sm-12 col-md-12 text-left full-width-column')
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
	Weeks int,
	Variable bit,
	MinUnit decimal(16, 3),
	MaxUnit decimal(16, 3),
	MinLec decimal(16, 3),
	MaxLec decimal(16, 3),
	MinLab decimal(16, 3),
	MaxLab decimal(16, 3),
	MinTotal decimal(16, 3),
	MaxTotal decimal(16, 3),
	CourseGrading nvarchar(max),
	OpenEntry bit,
	Repeats nvarchar(max),
	CrossList nvarchar(max),
	Formerly nvarchar(max),
	RequisiteCatalogView nvarchar(max),
	CatalogDescription nvarchar(max),
	Cb05 nvarchar(max),
	NonCredit bit,
	CIdNumber nvarchar(max),
	Term nvarchar(max),
	CourseDescOld nvarchar(max)
);

declare @unitHourRanges table
(
	Id int not null identity primary key,
	CourseId int,
	UnitHourTypeId int,
	RenderedRange nvarchar(100)
);

----testing
--declare @entityModels table ([Key] nvarchar(max), InsertOrder int, [Value] nvarchar(max));

-- insert into @entityModels ([Key], InsertOrder, [Value])
-- values (9646,1,'[{""InsertOrder"":1,""RootData"":{""CourseId"":9646,""SubjectCode"":""CHDEV"",""CourseNumber"":""15"",""CourseTitle"":""Diversity and Culture in Early Childhood Education Programs"",""Weeks"":18,""Variable"":false,""MinUnit"":3.000,""MaxUnit"":0.000,""MinLec"":3.000,""MinTotal"":162.000,""MaxTotal"":0.000,""CourseGrading"":""Letter Grade"",""OpenEntry"":false,""Repeats"":""0"",""CrossList"":"""",""RequisiteCatalogView"":""Advisory: ENGL 1A."",""CatalogDescription"":""Examines the historical and current perspectives of diversity, values, culture, racism, and oppression and the impacts of these factors on children?s development, learning, and educational experiences.  Strategies for developmentally, culturally, and linguistically appropriate anti-bias curriculum will be explored as well as approaches to promote inclusive and anti-racist classroom communities. Includes self-reflection on the influence of teachers'' own values, culture, beliefs, and experiences on teaching and interactions with children and families. (A, CSU)"",""Cb05"":""B - Transferable to CSU only."",""NonCredit"":false,""CIdNumber"":""ECE 230 "",""Term"":""2023 Fall Semester""}}]');
----end testing



insert into @modelRoot (CourseId, InsertOrder, RootData)
select
	em.[Key]
	,m.InsertOrder
	,m.RootData
from @entityModels em
	cross apply openjson(em.[Value])
	with (
		InsertOrder INT '$.InsertOrder',
		RootData nvarchar(MAX) '$.RootData' as json
	) m
--;

insert into @modelRootData
(
	CourseId,
	SubjectCode,
	CourseNumber,
	CourseTitle,
	Weeks,
	Variable,
	MinUnit,
	MaxUnit,
	MinLec,
	MaxLec,
	MinLab,
	MaxLab,
	MinTotal,
	MaxTotal,
	CourseGrading,
	OpenEntry,
	Repeats,
	CrossList,
	Formerly,
	RequisiteCatalogView,
	CatalogDescription,
	Cb05,
	NonCredit,
	CIdNumber,
	Term,
	CourseDescOld
)
select m.CourseId
	, case
		when m.SubjectCode is not null
		and len(m.SubjectCode) > 0
			then m.SubjectCode
		else null
	end as SubjectCode
	, case
		when m.CourseNumber is not null
		and len(m.CourseNumber) > 0
			then m.CourseNumber
		else null
	end as CourseNumber
	, case
		when m.CourseTitle is not null
		and len(m.CourseTitle) > 0
			then m.CourseTitle
		else null
	end as CourseTitle
	, m.Weeks
	, m.Variable
	, m.MinUnit
	, m.MaxUnit
	, m.MinLec
	, m.MaxLec
	, m.MinLab
	, m.MaxLab
	, m.MinTotal
	, m.MaxTotal
	, case
		when m.CourseGrading is not null
		and len(m.CourseGrading) > 0
			then m.CourseGrading
		else null
	end as CourseGrading
	, m.OpenEntry
	, case 
		when m.Repeats is not null
		and len(m.Repeats) > 0
			then m.Repeats
		else null
	end as Repeats
	, case
		when m.CrossList is not null
		and len(m.CrossList) > 0
			then m.CrossList
		else null
	end as CrossList
	, case
		when m.Formerly is not null
		and len(m.Formerly) > 0
			then m.Formerly
		else null
	end
	, case
		when m.RequisiteCatalogView is not null
		and len(m.RequisiteCatalogView) > 0
			then m.RequisiteCatalogView
		else null
	end as RequisiteCatalogView
	, case
		when m.CatalogDescription is not null
		and len(m.CatalogDescription) > 0
			then m.CatalogDescription
		else null
	end as CatalogDescription
	, case
		when m.Cb05 is not null
		and len(m.Cb05) > 0
			then m.Cb05
		else null
	end as CB05
	, m.NonCredit
	, case
		when m.CIdNumber is not null
		and len(m.CIdNumber) > 0
			then m.CIdNumber
		else null
	end as CIdNumber
	, case
		when m.Term is not null
		and len(m.Term) > 0
			then m.term
		else null
	end
	, m.CourseDescOld
from @modelRoot mr
	cross apply openjson(mr.RootData)
	with (
		CourseId int '$.CourseId',
		SubjectCode nvarchar(max) '$.SubjectCode',
		CourseNumber nvarchar(max) '$.CourseNumber',
		CourseTitle nvarchar(max) '$.CourseTitle',
		Weeks nvarchar(max) '$.Weeks',
		Variable bit '$.Variable',
		MinUnit decimal(16, 3) '$.MinUnit',
		MaxUnit decimal(16, 3) '$.MaxUnit',
		MinLec decimal(16, 3) '$.MinLec',
		MaxLec decimal(16, 3) '$.MaxLec',
		MinLab decimal(16, 3) '$.MinLab',
		MaxLab decimal(16, 3) '$.MaxLab',
		MinTotal decimal(16, 3) '$.MinTotal',
		MaxTotal decimal(16, 3) '$.MaxTotal',
		CourseGrading nvarchar(max) '$.CourseGrading',
		OpenEntry bit '$.OpenEntry',
		Repeats nvarchar(max) '$.Repeats',
		CrossList nvarchar(max) '$.CrossList',
		Formerly nvarchar(max) '$.Formerly',
		RequisiteCatalogView nvarchar(max) '$.RequisiteCatalogView',
		CatalogDescription nvarchar(max) '$.CatalogDescription',
		Cb05 nvarchar(max) '$.Cb05',
		NonCredit bit '$.NonCredit',
		CIdNumber nvarchar(max) '$.CIdNumber',
		Term nvarchar(max) '$.Term',
		CourseDescOld nvarchar(max) '$.CourseDescOld'
	) m
;

insert into @unitHourRanges (CourseId, UnitHourTypeId, RenderedRange)
select mrd.CourseId
	, uht.UnitHourTypeId
	, uhr.RenderedRange
from @modelRootData mrd
	cross apply (
		select 1 as UnitHourTypeId --units
			, case  
				when mrd.NonCredit = 1
					then
						case
							when dbo.fnCourseNumberToNumeric(mrd.CourseNumber) between 300 and 399
								then mrd.minUnit
							else mrd.MinTotal
						end
				else mrd.MinUnit 
			end as MinVal
			, case 
				when mrd.NonCredit = 1 
					then
						case
							when dbo.fnCourseNumberToNumeric(mrd.CourseNumber) between 300 and 399
								then mrd.MaxUnit
							else mrd.MaxTotal
						end
				else mrd.MaxUnit 
			end as MaxVal
			, 1 as RenderIfZero
			, 0 as ForceRange
			, mrd.Variable
			, 2 as FormatType
			, 1 as Render
		union all
		select 2 as UnitHourTypeId --lec
			, mrd.MinLec as MinVal
			, mrd.MaxLec as MaxVal
			, 1 as RenderIfZero
			, 0 as ForceRange
			, mrd.Variable
			, 2 as FormatType
			, 1 as Render
		union all
		select 3 as UnitHourTypeId --lab
			, mrd.MinLab as MinVal
			, mrd.MaxLab as MaxVal
			, 1 as RenderIfZero
			, 0 as ForceRange
			, mrd.Variable
			, 2 as FormatType
			, 1 as Render
	) uht
	cross apply (
		select
			case
				when
					uht.Render = 1
					and (
							(
								uht.Variable = 1
								and uht.MinVal is not null
								and uht.MaxVal is not null
								and uht.MinVal != uht.MaxVal
							)
							or (uht.ForceRange = 1)
					) then 
						concat(
							format(
								uht.MinVal
								, case
									when uht.FormatType = 0
										then @hoursDecimalFormat0
									when uht.FormatType = 1
										then @hoursDecimalFormat1
									else @hoursDecimalFormat2
								end
							)
							, '-'
							, format(
								uht.MaxVal
								, case
									when uht.FormatType = 0
										then @hoursDecimalFormat0
									when uht.FormatType = 1
										then @hoursDecimalFormat1
									else @hoursDecimalFormat2
								end
							)
						)
				when (
						uht.Render = 1 
						and uht.MinVal is not null
						and (
							uht.MinVal > 0
							or uht.RenderIfZero = 1
						)
					) then
						format(
							uht.MinVal
							, case
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
;

select mr.CourseId as [Value]
	-- custom-course-summary-context-wrapper
   , concat(
			-- Course Title row (Course subject code, number)
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, 'course-title-header'))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnhtmlattribute(@classAttrib, ecfw.FullWidthColumn)),
					dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnhtmlattribute(@classAttrib, 'course-subject')),
						isnull(mrd.SubjectCode, @emptyValueDisplay),
					dbo.fnHtmlCloseTag(@boldDataElementTag),
					dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-title-course-number-delimeter')),
						@space,
					dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-number')),
						isnull(mrd.CourseNumber, @emptyValueDisplay), @space,
					dbo.fnHtmlCloseTag(@boldDataElementTag),
					dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-title')),
						coalesce(mrd.CourseTitle, concat('(', @emptyValueDisplay, ')')),
					dbo.fnHtmlCloseTag(@boldDataElementTag),
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),
			--Units
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, 'course-Units-row'))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					Case
						When unithr.RenderedRange is not NULL
							then CONCAT(
									CASE WHEN mrd.NonCredit = 1 
									THEN 
										CASE WHEN 
									dbo.fnCourseNumberToNumeric(mrd.CourseNumber)
										BETWEEN 300 AND 399
												THEN 'Units:' 
											ELSE 'Hours:'
											END
									ELSE 'Units:' 
									END, 
								@space,
									isnull(unithr.RenderedRange, @emptyNumericValueDisplay),
									CASE
										WHEN lecthr.RenderedRange is not NULL or labhr.RenderedRange is not NULL or mrd.Weeks is not NULL
											then @seperator
										ELSE @empty
									END
							)
						ELSE @empty
					End,
					--Weekly Lecture Hours
					CASE
						When lecthr.RenderedRange is not NULL
							then CONCAT(
								dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-lec-label')),
									--here 
									'Weekly Lecture Hours:', @space,
								dbo.fnHtmlCloseTag(@labelTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'lecture-hours-range')),
									isnull(lecthr.RenderedRange, @emptyNumericValueDisplay),
									CASE
										WHEN  labhr.RenderedRange is not NULL or mrd.Weeks is not NULL
											then @seperator
										ELSE @empty	
									END,
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
						Else @empty
					End,
					--Weekly Lab Hours
					CASE
						When labhr.RenderedRange is not NULL
							then CONCAT(
								dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-lab-label')),
									--here 
									'Weekly Lab Hours:', @space,
								dbo.fnHtmlCloseTag(@labelTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'lab-hours-range')),
									isnull(labhr.RenderedRange, @emptyNumericValueDisplay),
									CASE
										WHEN  mrd.Weeks is not NULL
											then @seperator
										ELSE @empty	
									END,
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
						Else @empty
					End,
			--Weeks
					CASE
						When mrd.Weeks is not NULL AND mrd.Weeks != 18
							Then CONCAT(
									--here 
									'Weeks:', @space,
									CASE
										WHEN mrd.Weeks IS NULL
										THEN @emptyNumericValueDisplay
										ELSE CONCAT(mrd.Weeks, '.')
										END
							)
						ELSE @empty
					End,							
					--Course was formerly
					case
						when mrd.CourseDescOld is not null
							then concat(
								' Formerly: '
								, mrd.CourseDescOld
								, '.'
							)
						else ''
					end,
					-- crosslist
					CASE
						WHEN mrd.CrossList IS NOT NULL
							THEN CONCAT(
											' Cross-Listed Courses:', @space,
											isnull(mrd.CrossList,@emptyValueDisplay),
							CASE
								WHEN mrd.CrossList IS NULL THEN ''
								ELSE '.'
								END)
						ELSE @empty
					END,
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, 'course-grading-row'))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					-- grading
					CASE
						When mrd.CourseGrading is not NULL AND mrd.CourseGrading = 'Pass/No Pass Only'
							Then CONCAT(
								dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-grading-label')),
									'Grading:', @space,
								dbo.fnHtmlCloseTag(@labelTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-grading-value')),
									isnull(mrd.CourseGrading, @emptyValueDisplay),
									CASE
										WHEN  mrd.OpenEntry is not NULL or mrd.Repeats is not NULL
											then @seperator
										ELSE @empty	
									END,
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
						Else @empty
					END,
					--Open Entry/Open Exit
					CASE
						When mrd.OpenEntry = 1
							THEN CONCAT(
								dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-openentry-label')),
									'Open Entry/Open Exit:', @space,
								dbo.fnHtmlCloseTag(@labelTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-openentry-value')),
									case when mrd.OpenEntry = 1 then 'Yes' else 'No' end,
									CASE
										WHEN   mrd.OpenEntry = 1
											then @seperator
										ELSE @empty	
									END,
						
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
						Else @empty
					End,
					--Times Repeated
					CASE
						WHEN mrd.Repeats > 0
							THEN CONCAT(
								dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-repeat-label')),
									'Times Repeated:', @space,
								dbo.fnHtmlCloseTag(@labelTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-repeat-value')),
									isnull(mrd.Repeats, @emptyValueDisplay)
									, case 
										when mrd.Repeats > 0
											then @seperator
										else @empty
									end
									, @space,
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
						ELSE @empty
					End,
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),
			-- requisites
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, 'course-requisite-description-row'))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, 'course-requisite-catalog-view')),
						isnull(mrd.RequisiteCatalogView, @empty),
					dbo.fnHtmlCloseTag(@rowTag),
					case
						when mrd.RequisiteCatalogView IS NOT NULL then @space
						else @empty
					end,
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),
			--description
			CASE
				WHEN mrd.CatalogDescription is not NULL
					then CONCAT (
						dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, 'course-description-row'))),
							dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
								dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-description-label')),
									'Description:', @space,
								dbo.fnHtmlCloseTag(@labelTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-description-value')),
										isnull(mrd.CatalogDescription,@emptyValueDisplay),
								dbo.fnHtmlCloseTag(@dataElementTag),
							dbo.fnHtmlCloseTag(@columnTag),
						dbo.fnHtmlCloseTag(@rowTag)
					)
				ELse @empty
			END,
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, 'course-transferability-row'))),
				dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
					--cbo5 (transferability)
					CASE
						WHEN mrd.Cb05 is not NULL
							THEN CONCAT (
								dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-transferability-label')),
									'Transferability:', @space,
								dbo.fnHtmlCloseTag(@labelTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-transferability-value')),
									isnull(mrd.Cb05, @emptyValueDisplay), 
									case
										when mrd.CIdNumber is not null
										and right(mrd.Cb05, 1) != '.'
											then @seperator
										else @space
									end,
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
						Else @empty
					End,
					--C-ID
					CASE
						WHEN mrd.CIdNumber is not NULL
							then CONCAT(
								dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-CID-label')),
									'C-ID:', @space,
								dbo.fnHtmlCloseTag(@labelTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-CID-value')),
									isnull(mrd.CIdNumber,@emptyValueDisplay),
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
						Else @empty
					END,
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),
			--term
			CASE 
				WHEN mrd.Term is not NULL
					Then CONCAT(
						dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, 'course-term-row'))),
							dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
								dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-term-label')),
									'Term:', @space,
								dbo.fnHtmlCloseTag(@labelTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-term-value')),
									isnull(mrd.Term,@emptyValueDisplay),
								dbo.fnHtmlCloseTag(@dataElementTag),
							dbo.fnHtmlCloseTag(@columnTag),
						dbo.fnHtmlCloseTag(@rowTag)
					)
				ELSE @empty
			END,
			--final closing
			dbo.fnHtmlCloseTag(@summaryWrapperTag),
		dbo.fnHtmlCloseTag(@summaryWrapperTag),'<br>'
	) as [Text]
from @modelRoot mr
	inner join @modelRootData mrd on mr.CourseId = mrd.CourseId
	left outer join @unitHourRanges unithr on (mr.CourseId = unithr.CourseId AND unithr.UnitHourTypeId = 1)
	left outer join @unitHourRanges lecthr on (mr.CourseId = lecthr.CourseId AND lecthr.UnitHourTypeId = 2)
	left outer join @unitHourRanges labhr on (mr.CourseId = labhr.CourseId AND labhr.UnitHourTypeId = 3)
	inner join @elementClasses ecfw on ecfw.Id = 4 --4 = FullWidthRow
order by mr.InsertOrder
--#endregion query
"

DECLARE @ModelQuery NVARCHAR (MAX) = CONCAT("
--#region query
declare @entityList_internal table (
	InsertOrder int identity(1, 1) primary key,
	CourseId int
);

insert into @entityList_internal (CourseId)
select el.Id
from @entityList el;
--values (9646);

declare @entityRootData table 
(	
	CourseId int primary key,
	SubjectCode nvarchar(max),
	CourseNumber nvarchar(max),
	CourseTitle nvarchar(max),
	Weeks int,
	Variable bit,
	MinUnit decimal(16, 3),
	MaxUnit decimal(16, 3),
	MinLec decimal(16, 3),
	MaxLec decimal(16, 3),
	MinLab decimal(16, 3),
	MaxLab decimal(16, 3),
	MinTotal decimal(16, 3),
	MaxTotal decimal(16, 3),
	CourseGrading nvarchar(max),
	OpenEntry bit,
	Repeats NVARCHAR(max),
	CrossList NVARCHAR(max),
	Formerly NVARCHAR(max),
	RequisiteCatalogView nvarchar(max),
	CatalogDescription nvarchar(max),
	Cb05 nvarchar(max),
	NonCredit bit,
	CIdNumber nvarchar(max),
	Term NVARCHAR(max),
	CourseDescOld nvarchar(max)
)

declare 
	@clientId int = (
	select
		Id
	from Client
	where Active = 1
)
, @RequisiteCatalogViewQueryString nvarchar(max) = (
	select TOP 1
		Customsql
	from MetaForeignKeyCriteriaClient
	where Id = 62
)

declare 
	@mCurriculumPresentationId int = ", @Req,",
	@mOutputFormatId int = 5,
	@mEntityTypeId int = 1,
	@mEntityIds OrderedIntegers
;

declare @additionalTemplateConfig nvarchar(max) = '{""IsLabelBolded"": false}';

insert into @mEntityIds
select CourseId
from @entityList_internal

drop table if exists #RequisitesResult

create table #RequisitesResult
(
	[Value] int primary key,
	[Text] nvarchar(max)
);

exec upRenderCurriculumPresentation @mCurriculumPresentationId, @mOutputFormatId, @mEntityTypeId, @mEntityIds, @additionalTemplateConfig = @additionalTemplateConfig, @resultTable = '#RequisitesResult'

insert into @entityRootData
(
	CourseId
	, SubjectCode
	, CourseNumber
	, CourseTitle
	, Weeks
	, Variable
	, MinUnit
	, MaxUnit
	, MinLec
	, MaxLec
	, MinLab
	, MaxLab
	, MinTotal
	, MaxTotal
	, CourseGrading
	, OpenEntry
	, Repeats
	, CrossList
	, Formerly
	, RequisiteCatalogView
	, CatalogDescription
	, Cb05
	, NonCredit
	, Term
	, CourseDescOld
)

select c.Id
	, s.SubjectCode
	, c.CourseNumber
	, c.Title
	, cd.ShortTermWeek
	, cd.Variable
	, cd.MinCreditHour
	, cd.MaxCreditHour
	, cd.MinLectureHour
	, cd.MaxLectureHour
	, cd.MinLabHour
	, cd.MaxLabHour
	, cd.MinLabLecHour
	, cd.MaxLabLecHour
	, gdopt.Title
	, c.OpenEntry
	, rep.[Code]
	, coalesce(crc.RenderedText, c.CrosslistedCourses) as CrossListedCourses
	, c.CourseDescOld
	, ltrim(rtrim(r.[Text]))
	, case when CYN.YesNo01Id = 1 then concat(c.Description,' ',c.[COURSE_DESC]) else c.[COURSE_DESC] end
	, case when cb05.Id is not null then concat(cb05.Code,' - ',cb05.[Description]) else null end
	, case when ccc.Cb04Id = 3 then 1 else 0 end
	, sem.Title
	, c.CourseDescOld
from Course c
	inner join @entityList_internal eli on c.id = eli.CourseId
	inner join CourseDescription cd on c.Id = cd.CourseId
	inner join CourseProposal cp on cd.CourseId = cp.CourseId
	inner join Coursecbcode ccc on c.Id = ccc.CourseId
	inner join ProposalType pt on pt.Id = c.ProposalTypeId
	inner join GenericMaxText GMT on C.id = GMT.CourseId
	inner join CourseYesNo CYN on C.id = CYN.CourseId
	left join Semester sem on sem.Id = cp.SemesterId
	left join Repeatability rep on rep.id = cp.RepeatabilityId
	left join GradeOption gdopt on gdopt.Id = cd.GradeOptionId
	left join [Subject] s on c.SubjectId = s.Id
	left join GradeOption gon on cd.GradeOptionId = gon.Id
	left join #RequisitesResult r on c.Id = r.[Value]
	left join Cb05 cb05 on ccc.Cb05Id = cb05.Id
	outer apply (
		select STRING_AGG(crc.RenderedText,', ') WITHIN GROUP ( ORDER BY crc.SortOrder ) as RenderedText
		from (
			select row_number() over (partition by crc.CourseId order by crcS.SubjectCode, crcC.CourseNumber) as SortOrder
				, concat(
					crcS.SubjectCode
					, ' '
					, crcC.CourseNumber
				) as RenderedText
			from CourseRelatedCourse crc
				inner join Course crcC on crc.RelatedCourseId = crcC.Id
				inner join [Subject] crcS on crcC.SubjectId = crcS.Id
			where c.Id = crc.CourseId
		) crc
	) crc
where pt.ProcessActionTypeId != 3

declare @courseSupply table (courseId int, Text nvarchar(max))

insert into @courseSupply
select
	cs.courseId
	,STRING_AGG(SUBSTRING(Description, 0, len(Description)-7),'')
from CourseSupply cs
	inner join @entityRootData erd on erd.CourseId = cs.CourseId
group by cs.CourseId    

update @entityRootData
set CIdNumber = cs.Text
from @entityRootData erd
	inner join @courseSupply cs on cs.courseId = erd.CourseId

select eli.CourseId AS Id
	, m.Model
from @entityList_internal eli
	CROSS APPLY (
			select
				(
					select
						*
					from @entityRootData erd
					where eli.CourseId = erd.CourseId
					for json path, without_array_wrapper
				)
				RootData
		) erd
	CROSS APPLY (
			select
				(
					select
						eli.InsertOrder
						,JSON_QUERY(erd.RootData) AS RootData
					for json path
				)
				Model
		) m

drop table if exists #RequisitesResult;
--#endregion query
")

SET QUOTED_IDENTIFIER ON

INSERT INTO OutputTemplateClient
(TemplateQuery, Title, Description, StartDate)
VALUES
(@TempQuery, 'Custom Course Template', 'Custom Course Template', GETDATE())

DECLARE @Temp int = SCOPE_IDENTITY()

INSERT INTO OutputModelClient
(ModelQuery, Title, Description, StartDate, EntityTypeId)
VALUES
(@ModelQuery, 'Custom Course Template', 'This course model is custom.', GETDATE(), 1)

DECLARE @Model int = SCOPE_IDENTITY()

INSERT INTO OutputTemplateModelMappingClient
(OutputTemplateBaseId, OutputTemplateClientId, OutputModelBaseId, OutputModelClientId, Title, Description)
VALUES
(NULL, @Temp, NULL, @Model, 'Course Summary', 'Custom Course Summary model and template mapping')

DECLARE @map int = scope_identity()

UPDATE CurriculumPresentationOutputFormat
SET OutputTemplateModelMappingBaseId = NULL
, OutputTemplateModelMappingClientId = @map
WHERE Id in (1, 2)