USE [whatcom];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14076';
DECLARE @Comments nvarchar(Max) = 
	'Update reports to include CTE dual credit course check box';
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
SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(Max) = "
declare 
	@hoursDecimalFormat nvarchar(10) = 'F2',
	@empty nvarchar(2) = '',
	@space nvarchar(2) = ' '
;

declare @CourseCreditHoursSource table
(
	Id int identity primary key,
	CourseId int,
	Credit_Min_Total decimal(16, 3),
	Credit_Min_Lec decimal(16, 3),
	Credit_Min_Lab decimal(16, 3),
	Credit_Min_WorkSite decimal(16, 3),

	Credit_Max_Total decimal(16, 3),
	Credit_Max_Lec decimal(16, 3),
	Credit_Max_Lab decimal(16, 3),
	Credit_Max_WorkSite decimal(16, 3),

	Hour_Min_Total decimal(16, 3),
	Hour_Min_Lec decimal(16, 3),
	Hour_Min_Lab decimal(16, 3),
	Hour_Min_WorkSite decimal(16, 3),
	Hour_Min_Other decimal(16, 3),

	Hour_Max_Total decimal(16, 3),
	Hour_Max_Lec decimal(16, 3),
	Hour_Max_Lab decimal(16, 3),
	Hour_Max_WorkSite decimal(16, 3),
	Hour_Max_Other decimal(16, 3),

	Variable bit
);

declare @CreditHourSummary table
(
	Id int identity primary key,
	CourseId int,
	CreditSummary nvarchar(max),
	HourSummary nvarchar(max)
)

insert into @CourseCreditHoursSource
select cd.CourseId
, cd.MinCreditHour
, cd.MinLectureHour
, cd.MinLabHour
, cd.MinWorkHour

, cd.MaxCreditHour
, cd.MaxLectureHour
, cd.MaxLabHour
, cd.MaxWorkHour

, isnull(cd.MinContactHoursLecture, 0) + isnull(cd.MinContactHoursLab, 0) + isnull(cd.MinContactHoursClinical, 0) + isnull(cd.MinContactHoursOther, 0) as Hour_Min_Total
, cd.MinContactHoursLecture
, cd.MinContactHoursLab
, cd.MinContactHoursClinical
, cd.MinContactHoursOther

, isnull(cd.MaxContactHoursLecture, 0) + isnull(cd.MaxContactHoursLab, 0) + isnull(cd.MaxContactHoursClinical, 0) + isnull(cd.MaxContactHoursOther, 0) as Hour_Max_Total
, cd.MaxContactHoursLecture
, cd.MaxContactHoursLab
, cd.MaxContactHoursClinical
, cd.MaxContactHoursOther

, coalesce(cd.Variable, 0)
from CourseDescription cd
where cd.CourseId = @entityId

--select *
--from @CourseCreditHoursSource

--select MinLectureHour
--from CourseDescription
--where CourseId = @entityId

declare @CreditHoursValues table
(
	Id int identity primary key,
	CourseId int,
	[Key] sysname,
	[MinValue] decimal(16, 3),
	[MaxValue] decimal(16, 3),
	Variable bit
);

insert into @CreditHoursValues
-- Hour
select c.CourseId, 'Credit_Min_Total', c.Credit_Min_Total, c.Credit_Max_Total, c.Variable
from @CourseCreditHoursSource c
union
select c.CourseId, 'Credit_Min_Lec', c.Credit_Min_Lec, c.Credit_Max_Lec, c.Variable
from @CourseCreditHoursSource c
union
select c.CourseId, 'Credit_Min_Lab', c.Credit_Min_Lab, c.Credit_Max_Lab, c.Variable
from @CourseCreditHoursSource c
union
select c.CourseId, 'Credit_Min_WorkSite', c.Credit_Min_WorkSite, c.Credit_Max_WorkSite, c.Variable
from @CourseCreditHoursSource c
-- hours
union
select c.CourseId, 'Hour_Min_Total', c.Hour_Min_Total, c.Hour_Max_Total, c.Variable
from @CourseCreditHoursSource c
union
select c.CourseId, 'Hour_Min_Lec', c.Hour_Min_Lec, c.Hour_Max_Lec, c.Variable
from @CourseCreditHoursSource c
union
select c.CourseId, 'Hour_Min_Lab', c.Hour_Min_Lab, c.Hour_Max_Lab, c.Variable
from @CourseCreditHoursSource c
union
select c.CourseId, 'Hour_Min_WorkSite', c.Hour_Min_WorkSite, c.Hour_Max_WorkSite, c.Variable
from @CourseCreditHoursSource c;

with ComposedRanges as 
(
	select hr.*
	, case 
		when hr.MinValue is not null then
			case
				when hr.Variable = 1 and hr.MaxValue is not null and hr.MaxValue >= hr.MinValue then concat(format(hr.MinValue, @hoursDecimalFormat), ' - ', format(hr.MaxValue, @hoursDecimalFormat))
				else format(hr.MinValue, @hoursDecimalFormat)
				end
		when hr.MaxValue is not null then format(hr.MaxValue, @hoursDecimalFormat)
		else @empty
		end as ComposedRange
	from @CreditHoursValues hr
)
	insert into @CreditHourSummary (CourseId, CreditSummary, HourSummary)
	select i.EntityId
	, concat(
		cmt.ComposedRange,
		@space,
		'(',
		cmle.ComposedRange, ' lecture, ',
		cmla.ComposedRange, ' lab, ',
		cmw.ComposedRange, ' work site',
		').'
	) as [CreditSummary] 
	, concat(
		hmt.ComposedRange,
		@space,
		'(',
		hmle.ComposedRange, ' lecture, ',
		hmla.ComposedRange, ' lab, ',
		hmw.ComposedRange, ' work site',
		').'
	) as [HourSummary] 
	from (
		select @entityId as EntityId
	) i
		left join ComposedRanges cmt on cmt.[Key] = 'Credit_Min_Total' and i.EntityId = cmt.CourseId
		left join ComposedRanges cmle on cmle.[Key] = 'Credit_Min_Lec' and i.EntityId = cmle.CourseId
		left join ComposedRanges cmla on cmla.[Key] = 'Credit_Min_Lab' and i.EntityId = cmla.CourseId
		left join ComposedRanges cmw on cmw.[Key] = 'Credit_Min_WorkSite' and i.EntityId = cmw.CourseId
		
		left join ComposedRanges hmt on hmt.[Key] = 'Hour_Min_Total' and i.EntityId = hmt.CourseId
		left join ComposedRanges hmle on hmle.[Key] = 'Hour_Min_Lec' and i.EntityId = hmle.CourseId
		left join ComposedRanges hmla on hmla.[Key] = 'Hour_Min_Lab' and i.EntityId = hmla.CourseId
		left join ComposedRanges hmw on hmw.[Key] = 'Hour_Min_WorkSite' and i.EntityId = hmw.CourseId


select 0 as [Value]
, concat(
	-- originator
	dbo.fnHtmlOpenTag('div', 'class=""originator""'),
		dbo.fnHtmlOpenTag('span', 'style=""font-weight: bold;""'),
			'Originator:',
		dbo.fnHtmlCloseTag('span'),
		@space,
		dbo.fnHtmlOpenTag('span', null),
			u.FirstName,
			@space,
			u.LastName,
		dbo.fnHtmlCloseTag('span'),
	dbo.fnHtmlCloseTag('div'),

	-- abbreviated title
	dbo.fnHtmlOpenTag('div', 'class=""abbreviated-title""'),
		dbo.fnHtmlOpenTag('span', 'style=""font-weight: bold;""'),
			'Abbreviated title:',
		dbo.fnHtmlCloseTag('span'),
		@space,
		dbo.fnHtmlOpenTag('span', null),
			c.ShortTitle,
		dbo.fnHtmlCloseTag('span'),
	dbo.fnHtmlCloseTag('div'),

	 --total quarterly hours
	dbo.fnHtmlOpenTag('div', 'class=""abbreviated-title""'),
		dbo.fnHtmlOpenTag('span', 'style=""font-weight: bold;""'),
			'Total quarterly hours:',
		dbo.fnHtmlCloseTag('span'),
		@space,
		dbo.fnHtmlOpenTag('span', null),
			chs.HourSummary,
		dbo.fnHtmlCloseTag('span'),
	dbo.fnHtmlCloseTag('div'),

	-- total quarterly credits
	dbo.fnHtmlOpenTag('div', 'class=""abbreviated-title""'),
		dbo.fnHtmlOpenTag('span', 'style=""font-weight: bold;""'),
			'Total quarterly credits:',
		dbo.fnHtmlCloseTag('span'),
		@space,
		dbo.fnHtmlOpenTag('span', null),
			chs.CreditSummary,
		dbo.fnHtmlCloseTag('span'),
	dbo.fnHtmlCloseTag('div'),

	-- max enrollment
	dbo.fnHtmlOpenTag('div', 'class=""max-enrollment""'),
		dbo.fnHtmlOpenTag('span', 'style=""font-weight: bold;""'),
			'Max enrollment:',
		dbo.fnHtmlCloseTag('span'),
		@space,
		dbo.fnHtmlOpenTag('span', null),
			cp.MaxEnrollment,
		dbo.fnHtmlCloseTag('span'),
	dbo.fnHtmlCloseTag('div'),

	-- grading method
	dbo.fnHtmlOpenTag('div', 'class=""grading-method""'),
		dbo.fnHtmlOpenTag('span', 'style=""font-weight: bold;""'),
			'Grading method:',
		dbo.fnHtmlCloseTag('span'),
		@space,
		dbo.fnHtmlOpenTag('span', null),
			gon.[Description],
		dbo.fnHtmlCloseTag('span'),
	dbo.fnHtmlCloseTag('div'),

	-- AAS distribution
	dbo.fnHtmlOpenTag('div', 'class=""aas-distribution""'),
		dbo.fnHtmlOpenTag('span', 'style=""font-weight: bold;""'),
			'AAS distribution:',
		dbo.fnHtmlCloseTag('span'),
		@space,
		dbo.fnHtmlOpenTag('span', null),
			aasDist.[Text],
		dbo.fnHtmlCloseTag('span'),
	dbo.fnHtmlCloseTag('div'),

	-- Additional requirements
	dbo.fnHtmlOpenTag('div', 'class=""additional-requirements""'),
		dbo.fnHtmlOpenTag('span', 'style=""font-weight: bold;""'),
			'Additional requirements:',
		dbo.fnHtmlCloseTag('span'),
		@space,
		dbo.fnHtmlOpenTag('span', null),
			adr.[Text],
		dbo.fnHtmlCloseTag('span'),
	dbo.fnHtmlCloseTag('div'),

		-- CTE dual credit
	dbo.fnHtmlOpenTag('div', 'class=""dual-credit""'),
		dbo.fnHtmlOpenTag('span', 'style=""font-weight: bold;""'),
			'CTE dual credit course:',
		dbo.fnHtmlCloseTag('span'),
		@space,
		dbo.fnHtmlOpenTag('span', null),
			CASE 
				WHEN cp.IsRequired3 = 1 THEN 'Yes'
				ELSE 'No'
			END,
		--	adr.[Text],
		dbo.fnHtmlCloseTag('span'),
	dbo.fnHtmlCloseTag('div')
) as [Text]
from Course c
	left join CourseDescription cd on c.Id = CourseId
	left join CourseProposal cp on c.Id = cp.CourseId
	left join GradeOption gon on cd.GradeOptionId = gon.Id
	left join [User] u on c.UserId = u.Id
	left join @CreditHourSummary chs on c.Id = chs.CourseId

	outer apply (
		select dbo.ConcatWithSepOrdered_Agg(', ', a.RowId, a.Text) as [Text]
		from (
			select concat(l14.Title, '(', l14.Code, ')') as [Text]
			, row_number() over (order by cl14.SortOrder, cl14.Id) as RowId
			, cl14.CourseId
			from CourseLookup14 cl14
				left join Lookup14 l14 on cl14.Lookup14Id = l14.Id
			where cl14.CourseId = c.Id
		) a
		group by a.CourseId		
	) aasDist

	outer apply (
		select dbo.ConcatWithSepOrdered_Agg(', ', a.RowId, a.Text) as [Text]
		from (
			select concat('""', lower(ast.Title), '"" ', ast.Description) as [Text]
			, row_number() over (order by ca.SortOrder, ast.Id) as RowId
			, ca.CourseId
			from CourseAssignment ca
				left join AssignmentType ast on ca.AssignmentTypeId = ast.Id
			where ca.CourseId = c.ID
		) a
		group by a.CourseId 
	) adr
	
where c.Id = @entityId
"

SET QUOTED_IDENTIFIER ON

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 129

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId
	FROM MetaTemplateType mtt
		INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
	WHERE mt.Active = 1 
		AND mtt.EntityTypeId = 1
		AND mt.IsDraft = 0
		AND mt.EndDate IS NULL
		AND mtt.Active = 1
		AND mtt.IsPresentationView = 1
		AND mtt.ClientId = 1
)