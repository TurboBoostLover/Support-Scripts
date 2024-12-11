USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13780';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog Display ';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 2; /*  Default 1 is Support,  
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
SET QUOTED_IDENTIFIER OFF

Update OutputTemplateClient
SET TemplateQuery = "
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
	Term nvarchar(max)
);

declare @unitHourRanges table
(
	Id int not null identity primary key,
	CourseId int,
	UnitHourTypeId int,
	RenderedRange nvarchar(100)
);


------testing
----
---- insert into @modelRoot
---- (CourseId, InsertOrder, RootData)
---- values
---- (8464,1,'
----        {
----            'CourseId': 8464,
----            'SubjectCode': 'FIRET',
----            'CourseNumber': '19',
----            'CourseTitle': 'Work Experience (Cooperative), Occupational ',
----            'Weeks': 17,
----            'Variable': true,
----            'MinUnit': 5.000,
----            'MaxUnit': 8.000,
----            'MinLec': 4.000,
----            'MaxLec': 0.000,
----            'MinLab': 3.330,
----            'MaxLab': 33.330,
----            'MinTotal': 7.330,
----            'MaxTotal': 37.330,
----            'CourseGrading': 'Pass/No Pass Only',
----            'Repeats': '1',
----            'CrossList': '<ul class=\'cross-listing-list\'>Test<\/ul>',
----            'Formerly': 'test formerly',
----            'RequisiteCatalogView': '<b>Prerequisite: <\/b>None<br><b>Corequisite: <\/b>  Fall and Spring Semesters: Must be enrolled in at least one other course, in addition to occupational work experience. Summer Session: Enrollment in another college course is optional. Supervised employment directly related to the student''s major. Offered under specific majors.  <br><b>Advisory: <\/b>None<br><b>Anti Requisite: <\/b>None',
----            'CatalogDescription': 'Supervised employment extending the classroom based on occupational learning related to fire technology. Collaborative learning objectives established specific to the particular occupational field. Seventy-five (75) hours of paid work or 60 hours of non-paid work per unit per semester. Maximum of 8 units per semester. Maximum 16 units total. Orientation hours may be required.',
----            'Cb05': 'B - Transferable to CSU only.',
---- 		   'NonCredit': true,
----            'CIdNumber': 'asdfg 2012SP',
----            'Term': '2021 Spring Semester'
----        }'
---- )
-- --end testing
insert into @modelRoot
(CourseId, InsertOrder, RootData)
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
;

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
	Term
)
	select
		m.CourseId
	   ,case
			when m.SubjectCode IS NOT NULL AND
				LEN(m.SubjectCode) > 0 then m.SubjectCode
			else null
		end as SubjectCode
	   ,case
			when m.CourseNumber IS NOT NULL AND
				LEN(m.CourseNumber) > 0 then m.CourseNumber
			else null
		end as CourseNumber
	   ,case
			when m.CourseTitle IS NOT NULL AND
				LEN(m.CourseTitle) > 0 then m.CourseTitle
			else null
		end as CourseTitle
        ,m.Weeks
	   ,m.Variable
	   ,m.MinUnit
	   ,m.MaxUnit
	   ,m.MinLec
	   ,m.MaxLec
	   ,m.MinLab
	   ,m.MaxLab
	   ,m.MinTotal
	   ,m.MaxTotal
	   ,case
			when m.CourseGrading IS NOT NULL AND
				LEN(m.CourseGrading) > 0 then m.CourseGrading
			else null
		end as CourseGrading
        ,m.OpenEntry
        ,case 
            when m.Repeats is not null and len(m.Repeats) > 0 then m.Repeats
            else null
        end as Repeats
        ,case
            when m.CrossList is not null and len(m.CrossList) > 0 then m.CrossList
            else null
        end as CrossList
        ,case when m.Formerly is not null and len(m.Formerly) > 0 then m.Formerly
            else null
        end
	   ,case
			when m.RequisiteCatalogView IS NOT NULL AND
				LEN(m.RequisiteCatalogView) > 0 then m.RequisiteCatalogView
			else null
		end as RequisiteCatalogView
	   ,case
			when m.CatalogDescription IS NOT NULL AND
				LEN(m.CatalogDescription) > 0 then m.CatalogDescription
			else null
		end as CatalogDescription
        ,case
			when m.Cb05 IS NOT NULL AND LEN(m.Cb05) > 0 then m.Cb05
			else null
		end as CB05
		,m.NonCredit
	   ,case
			when m.CIdNumber IS NOT NULL AND LEN(m.CIdNumber) > 0 then m.CIdNumber
			else null
		end as CIdNumber
        ,case
            when m.Term is not null and len(m.Term) > 0 then m.term
            else null
        end
	from @modelRoot mr
		cross apply openjson(mr.RootData)
			with (
				CourseId INT '$.CourseId',
				SubjectCode nvarchar(MAX) '$.SubjectCode',
				CourseNumber nvarchar(MAX) '$.CourseNumber',
				CourseTitle nvarchar(MAX) '$.CourseTitle',
				Weeks nvarchar(max) '$.Weeks',
				Variable BIT '$.Variable',
				MinUnit decimal(16, 3) '$.MinUnit',
				MaxUnit decimal(16, 3) '$.MaxUnit',
				MinLec decimal(16, 3) '$.MinLec',
				MaxLec decimal(16, 3) '$.MaxLec',
				MinLab decimal(16, 3) '$.MinLab',
				MaxLab decimal(16, 3) '$.MaxLab',
				MinTotal decimal(16, 3) '$.MinTotal',
				MaxTotal decimal(16, 3) '$.MaxTotal',
				CourseGrading nvarchar(MAX) '$.CourseGrading',
				OpenEntry bit '$.OpenEntry',
				Repeats nvarchar(max) '$.Repeats',
				CrossList nvarchar(max) '$.CrossList',
				Formerly nvarchar(max) '$.Formerly',
				RequisiteCatalogView nvarchar(MAX) '$.RequisiteCatalogView',
				CatalogDescription nvarchar(MAX) '$.CatalogDescription',
				Cb05 nvarchar(MAX) '$.Cb05',
				NonCredit bit '$.NonCredit',
				CIdNumber nvarchar(MAX) '$.CIdNumber',
				Term nvarchar(MAX) '$.Term'
			) m;

insert into @unitHourRanges
(CourseId, UnitHourTypeId, RenderedRange)
	select
		mrd.CourseId
	   ,uht.UnitHourTypeId
	   ,uhr.RenderedRange
	from @modelRootData mrd
		cross apply (
				select
					1 as UnitHourTypeId -- units
				   ,case  
						when mrd.NonCredit = 1
						then
						CASE WHEN 
								dbo.fnCourseNumberToNumeric(mrd.CourseNumber)
								BETWEEN 300 AND 399
								THEN mrd.minUnit
								ELSE mrd.MinTotal
							END
						else mrd.MinUnit 
					end as MinVal

				   ,case 
						when mrd.NonCredit = 1 
						then
						CASE WHEN 
								dbo.fnCourseNumberToNumeric(mrd.CourseNumber)
								BETWEEN 300 AND 399
								THEN mrd.MaxUnit
								ELSE mrd.MaxTotal
							END
						else mrd.MaxUnit 
						end as MaxVal

				   ,1 as RenderIfZero
				   ,0 as ForceRange
				   ,mrd.Variable
				   ,2 as FormatType
				   ,1 as Render

				UNION ALL

				select
					2 as UnitHourTypeId -- -lec
				   ,mrd.MinLec as MinVal
				   ,mrd.MaxLec as MaxVal
				   ,1 as RenderIfZero
				   ,0 as ForceRange
				   ,mrd.Variable
				   ,2 as FormatType
				   ,1 as Render

				UNION ALL

				select
					3 as UnitHourTypeId -- lab
				   ,mrd.MinLab as MinVal
				   ,mrd.MaxLab as MaxVal
				   ,1 as RenderIfZero
				   ,0 as ForceRange
				   ,mrd.Variable
				   ,2 as FormatType
				   ,1 as Render
			) uht
		cross apply (
				select
					case
						when
							uht.Render = 1 AND
							(
							(
							uht.Variable = 1 AND
							uht.MinVal IS NOT NULL AND
							uht.MaxVal IS NOT NULL AND
							uht.MinVal != uht.MaxVal
							) OR
							(
							uht.ForceRange = 1
							)
							) then concat(
							format(
							uht.MinVal,
							case
								when uht.FormatType = 0 then @hoursDecimalFormat0
								when uht.FormatType = 1 then @hoursDecimalFormat1
								else @hoursDecimalFormat2
							end
							),
							'-',
							format(
							uht.MaxVal,
							case
								when uht.FormatType = 0 then @hoursDecimalFormat0
								when uht.FormatType = 1 then @hoursDecimalFormat1
								else @hoursDecimalFormat2
							end
							)
							)
						when
							(
							uht.Render = 1 AND
							uht.MinVal IS NOT NULL AND
							(uht.MinVal > 0 OR
							uht.RenderIfZero = 1)
							) then format
							(
							uht.MinVal,
							case
								when uht.FormatType = 0 then @hoursDecimalFormat0
								when uht.FormatType = 1 then @hoursDecimalFormat1
								else @hoursDecimalFormat2
							end
							)
						else NULL
					end as RenderedRange
			) uhr

select
	mr.CourseId as [Value]
   ,
	-- custom-course-summary-context-wrapper
	
	concat(
		dbo.fnHtmlOpenTag(@summaryWrapperTag,
		dbo.fnHtmlAttribute(@classAttrib, 'custom-course-summary-context-wrapper')
	),
	-- another nested wrapper
	dbo.fnHtmlOpenTag(@summaryWrapperTag, concat(
			dbo.fnHtmlAttribute(@classAttrib, 'container-fluid course-summary-wrapper'), @space,
			dbo.fnHtmlAttribute('data-course-id', mrd.CourseId)
		)
	),
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
		dbo.fnHtmlOpenTag(@rowTag, dbo.fnhtmlattribute(@classAttrib, concat(ecfw.Wrapper, @space, 'course-units-row'))),
			dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
--Units
					Case
						When unithr.RenderedRange is not NULL
							then CONCAT(
								dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-unit-label')),
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
								dbo.fnHtmlCloseTag(@labelTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'course-unit-range')),
									isnull(unithr.RenderedRange, @emptyNumericValueDisplay),
									CASE
										WHEN lecthr.RenderedRange is not NULL or labhr.RenderedRange is not NULL or mrd.Weeks is not NULL
											then @seperator
										ELSE @empty
									END,
								dbo.fnHtmlCloseTag(@dataElementTag)
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
							dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, 'course-week-label')),
								--here 
								'Weeks:', @space,
							dbo.fnHtmlCloseTag(@labelTag),
							dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, 'weeks')),
								isnull(mrd.Weeks, @emptyNumericValueDisplay), 
							dbo.fnHtmlCloseTag(@dataElementTag)
						)
					ELSE @empty
				End,
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
								isnull(mrd.Cb05,@emptyValueDisplay), 
								CASE
									WHEN  mrd.CIdNumber is not NULL
										then @seperator
									ELSE @empty	
								END,
								
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
	dbo.fnHtmlCloseTag(@summaryWrapperTag)
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
WHERE Id = 1

UPDATE OutputModelClient
SET ModelQuery = "
--#region query

declare @entityList_internal table (
	InsertOrder int identity(1, 1) primary key,
	CourseId int
);

insert into @entityList_internal
(CourseId)
select el.Id
from @entityList el;
--values (7907);

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
	Term NVARCHAR(max)
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
	@mCurriculumPresentationId int = 7,
	@mOutputFormatId int = 5,
	@mEntityTypeId int = 1,
	@mEntityIds integers
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
)

select
		c.Id
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
	, c.[Description]
	, case when cb05.Id is not null then concat(cb05.Code,' - ',cb05.[Description]) else null end
	, case when ccc.Cb04Id = 3 then 1 else 0 end
	, sem.Title
from Course c
	inner join @entityList_internal eli on c.id = eli.CourseId
	inner join CourseDescription cd on c.Id = cd.CourseId
	inner join CourseProposal cp on cd.CourseId = cp.CourseId
	inner join Coursecbcode ccc on c.Id = ccc.CourseId
	inner join ProposalType pt on pt.Id = c.ProposalTypeId
	left join Semester sem on sem.Id = cp.SemesterId
	left join Repeatability rep on rep.id = cp.RepeatabilityId
	left join GradeOption gdopt on gdopt.Id = cd.GradeOptionId
	left join [Subject] s on c.SubjectId = s.Id
	left join GradeOption gon on cd.GradeOptionId = gon.Id
	left join #RequisitesResult r on c.Id = r.[Value]
	left join Cb05 cb05 on ccc.Cb05Id = cb05.Id
	outer apply (
		select dbo.ConcatWithSepOrdered_Agg(', ', crc.SortOrder, crc.RenderedText) as RenderedText
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
	,dbo.ConcatWithSep_Agg('',SUBSTRING(Description, 0, len(Description)-7))
from CourseSupply cs
	inner join @entityRootData erd on erd.CourseId = cs.CourseId
group by cs.CourseId    

update @entityRootData
set CIdNumber = cs.Text
from @entityRootData erd
	inner join @courseSupply cs on cs.courseId = erd.CourseId

select
	eli.CourseId AS Id
	,m.Model
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
"
WHERE Id = 1

UPDATE OutputTemplateClient
SET TemplateQuery = "

/* Note hade to use the bulkresolvequery to add the tottal*/


declare @entityModels_internal table (
	InsertOrder int identity (1, 1) primary key,
	Id int index ixEntityModels_internal_Id,
	Model nvarchar(max)
);

insert into @entityModels_internal (Id, Model)
select em.[Key], em.[Value]
from @entityModels em;


declare @entityId int = (select id from @entityModels_internal)

declare @IsNonCredit bit = (select case when ai.[Description] like '%noncredit%' then 1 else 0 end from Program p left join AreaOfInterest ai on ai.Id = p.PrimaryAreaOfInterestId where p.Id = @entityId);

DECLARE @queryString nvarchar(max) =
'
declare @config stringpair;
declare @IsNonCredit bit = (select case when ai.Description like ''%noncredit%'' then 1 else 0 end from Program p left join AreaOfInterest ai on ai.Id = p.PrimaryAreaOfInterestId where p.Id = @entityId);

insert into @config
(String1,String2)
values
(''BlockItemTable'',''ProgramSequence'');

create table #renderedInjections (
	TableName sysname,
	Id int,
	InjectionType nvarchar(255),
	RenderedText nvarchar(max),
	primary key (TableName, Id, InjectionType)
);

INSERT INTO #renderedInjections
(TableName, Id, InjectionType, RenderedText)
	SELECT
		''ProgramSequence'' AS TableName
	   ,ps.Id
	   ,''CourseEntryRightColumnReplacement''
	   ,CASE WHEN @IsNonCredit = 0
	   THEN
	   CONCAT(
		FORMAT(ps.CalcMin,''##0.###''),
		CASE 
			WHEN ps.CalcMin <> ps.CalcMax
				then CONCAT(''-'',FORMAT(ps.CalcMax,''##0.###''))
			ELSE ''''
		END
	   )
	   ELSE
	    CONCAT(
		FORMAT(cd.MinLabLecHour,''##0.###''),
		CASE 
			WHEN isnull(cd.MinLabLecHour,0) <> isnull(cd.MaxLabLecHour,0) AND cd.MaxLabLecHour <> 0
				then CONCAT(''-'',FORMAT(cd.MaxLabLecHour,''##0.###''))
			ELSE ''''
		END
		)
		END
	    AS RenderedText
	FROM ProgramSequence ps
	left join CourseDescription cd on cd.CourseId = ps.CourseId
	WHERE (
	ps.ProgramId = @entityId
	);

INSERT INTO #renderedInjections
(TableName, Id, InjectionType, RenderedText)
	SELECT
		''ProgramSequence'' AS TableName
	   ,ps.Id
	   ,''NonCourseEntryRightColumnReplacement''
	   ,CONCAT(
		FORMAT(ps.CalcMin,''###.###''),
		CASE 
			WHEN ps.CalcMin <> ps.CalcMax
				then CONCAT(''-'',FORMAT(ps.CalcMax,''###.###''))
			ELSE ''''
		END
	   ) AS RenderedText
	FROM ProgramSequence ps
	WHERE (
	ps.ProgramId = @entityId
	);

declare @CourseUnitsOveride nvarchar(max) =
''select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''''ProgramSequence'''' and ri.Id = @id and ri.InjectionType = ''''CourseEntryRightColumnReplacement'''';'';
declare @NonCourseUnitsOveride nvarchar(max) =
''select
	Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''''ProgramSequence'''' and ri.Id = @id and ri.InjectionType = ''''NonCourseEntryRightColumnReplacement'''';''

declare @extraDetailsDisplay StringPair;

INSERT INTO @extraDetailsDisplay
(String1, String2)
VALUES
(''CourseEntryRightColumnReplacement'', @CourseUnitsOveride ),
(''NonCourseEntryRightColumn'',@NonCourseUnitsOveride) ;

declare @classOverrides stringtriple;

INSERT INTO @classOverrides
(String1, String2, String3)
VALUES
(''CourseCrossListingListLeftParen'', ''Wrapper'', ''d-none hidden course-cross-listing-list-label'')
, (''CourseCrossListingListLabel'', ''Wrapper'', ''d-none hidden course-cross-listing-list-left-paren'')
, (''CourseCrossListingEntry'', ''Wrapper'', ''d-none hidden course-cross-listing-entry'')
, (''CourseCrossListingListRightParen'', ''Wrapper'', ''d-none hidden course-cross-listing-list-right-paren'')
, (''CourseCrossListingListDelimiter'', ''Wrapper'', ''d-none hidden course-cross-listing-list-delimiter'')
, (''BlockEntryUnitsDisplay'', ''Wrapper'', ''d-none hidden units-display block-entry-units-display'');

EXEC upGenerateGroupConditionsCourseBlockDisplay 
	@entityId ,
	@elementClassOverrides = @classOverrides, 
	@extraDetailsDisplay = @extraDetailsDisplay,
	@config = @config, 
	@combineBlocks =0, 
	@outputTotal = 0;

DROP TABLE IF EXISTS #renderedInjections;'

declare @serializedParameters nvarchar(max) = (
	select
		emi.Id as [id], json_query(p.Parameters) as [parameters]
	from @entityModels_internal emi
	cross apply (
		select
			concat(
				'[',
					dbo.fnGenerateBulkResolveQueryParameter('@entityId', emi.Id, 'int'), 
				']'
			) as Parameters
	) p
	for json path
);

declare @serializedResults nvarchar(max);
exec dbo.upBulkResolveQuery @queryString = @queryString, @serializedParameters = @serializedParameters, @serializedResults = @serializedResults output;

DECLARE @Results table (Value int, Text nvarchar(max), sortorder int,  MinimumCreditHours decimal, MaximumCreditHours decimal)
INSERT INTO @Results
select 
	@entityId as Value, out.Text, Out.SortOrder, Out.MinimumCreditHours, Out.MaximumCreditHours
from openjson(@serializedResults)
with (
    ParamsParseSuccess bit '$.paramsParseSuccess',
    EntityResultSets nvarchar(max) '$.entityResultSets' as json,
    StatusMessages nvarchar(max) '$.statusMessages' as json
) srr --srr = serialized results root
outer apply openjson(srr.EntityResultSets)
with (
    Id int '$.id',
    SortOrder int '$.sortOrder',
    QuerySuccess bit '$.querySuccess',
    ResultSets nvarchar(max) '$.resultSets' as json
) ers
outer apply openjson(ers.ResultSets)
with (
    ResultSetNumber int '$.resultSetNumber',
    Results nvarchar(max) '$.results' as json
) rs
outer apply openjson(rs.Results)
with (
    SerializedResult nvarchar(max) '$.serializedResult' as json,
    StatusMessages nvarchar(max) '$.statusMessages' as json
) res
outer apply openjson(res.SerializedResult) with (
    value int '$.Value',
    Text nvarchar(max) '$.Text' ,
	SortOrder int '$.SortOrder',
	MinimumCreditHours decimal '$.MinimumCreditHours',
	MaximumCreditHours decimal '$.MaximumCreditHours'
) out

DECLARE @tottalmin decimal(16,3) =
(
	SELECT sum(CalcMin) 
	FROM (
		select case when @IsNonCredit = 0 then CalcMin else isnull(cd.MinLabLecHour,0) end as CalcMin  
		from programsequence ps 
		left join CourseDescription cd on cd.CourseId = ps.CourseId
		WHERE ProgramId = @entityId
			and (Parent_Id is null or @IsNonCredit = 1)
			) s
)

DECLARE @tottalmax decimal (16,3) =
(
	SELECT sum(CalcMax) 
	FROM (
		select case when @IsNonCredit = 0 then CalcMax else isnull(cd.MaxLabLecHour,0) end as CalcMax  
		from programsequence ps 
		left join CourseDescription cd on cd.CourseId = ps.CourseId
		WHERE ProgramId = @entityId
			and (Parent_Id is null or @IsNonCredit = 1)
			) s
)



insert INTO @Results (value, Text,sortorder)
SELECT 
	@entityId AS Value, 
	CONCAT(
		'<div  class=""row course-blocks-total-credits""><div  class=""col-xs-12 col-sm-12 col-md-12 full-width-column text-right text-end""><span  class=""grand-total-units-label"">',case when @IsNonCredit = 1 then 'Total Hours' else 'Total' end,'</span><span  class=""grand-total-units-label-colon"">:</span> <span  class=""grand-total-units-display"">',
		FORMAT(@tottalmin,'##0.###'),
		CASE
			WHEN @tottalmin <> @tottalmax and @tottalmax <> 0
			THEN concat('-<wbr>',FORMAT(@tottalmax,'##0.###'))
			ELSE ''
		END
	) AS Text
	,(SELECT Max(sortorder)FROM @Results) + 1


SELECT 
	 Value,
	dbo.ConcatOrdered_Agg(sortorder,Text,1) As Text
FROM @results
GROUP by Value
"
WHERE Id = 2


SET QUOTED_IDENTIFIER ON

--commit