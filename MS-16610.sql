USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16610';
DECLARE @Comments nvarchar(Max) = 
	'Update Queries for Assist';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql= '

declare @modelRoot table (
	InsertOrder int identity primary key,
	CourseId int
);

declare 
	@RenderV2Requisites bit
;



insert into @modelRoot
select @EntityId


if (isnull(@RenderV2Requisites, 0) = 0)
begin;

declare @renderQuery nvarchar(max);
declare @renderIds integers;

drop table if exists #reqTypeOutput;
create table #reqTypeOutput (
	CourseId int,
	CourseRequisiteId int,
	ParentId int,
	ReqTypeId int,
	_ReqType nvarchar(max),
	_condition nvarchar(max),
	_course nvarchar(max),
	SortOrder int,
	IsCondition bit,
	_ReSortOrder int,
	_ReSortCourseRequisiteId int,
	OutputReqType bit,
	NestedNumber int,
	NewSortOrder int
);

insert into #reqTypeOutput (cr.CourseId, CourseRequisiteId, ParentId, ReqTypeId, SortOrder, _course, _condition, _ReqType, IsCondition)
select cr.CourseId
, cr.Id, cr.Parent_Id, cr.RequisiteTypeId
, row_number() over (partition by cr.CourseId order by cr.SortOrder, cr.Id)
, concat(s.SubjectCode, '' '', c.CourseNumber)
, gc.Title
, substring(rt.Title, 1, 1)
, case when gc.Id is not null then 1 else 0 end
from CourseRequisite cr
	inner join @modelRoot mr on cr.CourseId = mr.CourseId
	left join Course c on cr.Requisite_CourseId = c.Id
	left join [Subject] s on c.SubjectId = s.Id
	left join GroupCondition gc on cr.GroupConditionId = gc.Id
	left join RequisiteType rt on cr.RequisiteTypeId = rt.Id


drop table if exists #reqTypeOrder;
create table #reqTypeOrder (
	ReqTypeId int,
	SortOrder int
);

-- intetionally I didn''t want to use the sortorder of the lookup because to not tied the requisite type dropdown presentation vs this presentation query
insert into #reqTypeOrder
select fn.Id
, row_number() over (order by fn.SortOrder, fn.Id)
from (
	select rt.Id
	, case
		when rt.Id = 1 then 1 -- Prerequisite
		end as SortOrder
	from RequisiteType rt
) fn


;with Recur as (
	select r.CourseRequisiteId
	, r.ParentId
	, 1 as NestedNumber
	from #reqTypeOutput r
	where r.ParentId is null
	union all
	select t.CourseRequisiteId
	, t.ParentId
	, r.NestedNumber + 1 as NestedNumber
	from Recur r
		inner join #reqTypeOutput t on r.CourseRequisiteId = t.ParentId
)
	update o
	set o.NestedNumber = r.NestedNumber
	from Recur r
		inner join #reqTypeOutput o on r.CourseRequisiteId = o.CourseRequisiteId

update r
set r._ReSortCourseRequisiteId = r.CourseRequisiteId
from #reqTypeOutput r
where r.IsCondition = 0

DELETE FROM #reqTypeOutput
WHERE ReqTypeId in (2, 3, 4, 5, 6, 7, 11)

declare @SortOrderQuery nvarchar(max) = ''

declare @childIds integers;

insert into @childIds (Id)
select cr2.Id
from CourseRequisite cr
inner join @renderIds ri on cr.Id = ri.Id
inner join CourseRequisite cr2 on cr.Id = cr2.Parent_Id;


if ((select count(*) from @childIds) > 0)
begin;
	exec sp_executesql @renderQuery, N''''@renderIds integers readonly, @renderQuery nvarchar(max)'''', @childIds, @renderQuery;
end;

;with temp as (
	select r.ParentId
	, r2.CourseRequisiteId
	, row_number() over (partition by r.CourseId, r.ParentId order by so2.SortOrder, so2.ReqTypeId, r.SortOrder, r.CourseRequisiteId) as SortOrder
	from #reqTypeOutput r
		inner join @childIds c on r.CourseRequisiteId = c.Id
		inner join #reqTypeOutput r2 on r._ReSortCourseRequisiteId = r2.CourseRequisiteId
		left join #reqTypeOrder so2 on r2.ReqTypeId = so2.ReqTypeId
)
	update r
	set r._ReSortCourseRequisiteId = t.CourseRequisiteId
	--select r.*
	--, t.SortOrder
	from temp t
		inner join #reqTypeOutput r on t.ParentId = r.CourseRequisiteId
	where t.SortOrder = 1

''

declare @childIds_SortOrder integers;
insert into @childIds_SortOrder (Id)
select Id
from CourseRequisite cr
	inner join @modelRoot mr on cr.CourseId = mr.CourseId
where cr.Parent_Id is null;

exec sp_executesql @SortOrderQuery, N''@renderIds integers readonly, @renderQuery nvarchar(max)'', @childIds_SortOrder, @SortOrderQuery;

;with temp as (
	select r.CourseRequisiteId
	, row_number() over (partition by r.CourseId order by
		so.SortOrder,
		so.ReqTypeId,
		r.SortOrder,
		r.CourseRequisiteId
	) as SortOrder
	--, ''=>''
	--, so.SortOrder
	--, so.ReqTypeId
	--, r.SortOrder
	--, r.CourseRequisiteId
	--, ''=>''
	--, o.CourseRequisiteId
	from #reqTypeOutput r
		inner join #reqTypeOutput o on r._ReSortCourseRequisiteId = o.CourseRequisiteId
		inner join #reqTypeOrder so on o.ReqTypeId = so.ReqTypeId
	where r.ParentId is null
)
	update r
	set r._ReSortOrder = t.SortOrder
	from temp t
		inner join #reqTypeOutput r on t.CourseRequisiteId = r.CourseRequisiteId

;with temp as (
	select r.CourseRequisiteId
	, row_number() over (partition by r.CourseId, r.ParentId order by
		so.SortOrder,
		so.ReqTypeId,
		r.SortOrder,
		r.CourseRequisiteId
	) as SortOrder
	--, ''=>''
	--, r.*
	from #reqTypeOutput r
		inner join #reqTypeOutput o on r._ReSortCourseRequisiteId = o.CourseRequisiteId
		inner join #reqTypeOrder so on o.ReqTypeId = so.ReqTypeId
	where r.ParentId is not null
	--order by r.SortOrder
)
	update r
	set r._ReSortOrder = t.SortOrder
	from #reqTypeOutput r
		inner join temp t on r.CourseRequisiteId = t.CourseRequisiteId

;with SortOrderChain as (
	select CourseRequisiteId
	, ParentId
	, format(_ReSortOrder, ''D10'') as SortChain
	from #reqTypeOutput
	where ParentId is null
	union all
	select r.CourseRequisiteId
	, r.ParentId
	, concat(s.SortChain, ''_'', format(r._ReSortOrder, ''D10'')) as SortChain
	from SortOrderChain s
		inner join #reqTypeOutput r on s.CourseRequisiteId = r.ParentId
)
, temp as (
	select r.CourseRequisiteId
	, row_number() over (partition by r.CourseId order by s.SortChain) as NewSortOrder
	from SortOrderChain s
		inner join #reqTypeOutput r on s.CourseRequisiteId = r.CourseRequisiteId
)
	update rto
	set rto.NewSortOrder = t.NewSortOrder
	from #reqTypeOutput rto 
		inner join temp t on rto.CourseRequisiteId = t.CourseRequisiteId

;

;with ReqTypeOutputCheck as
(
	select
	    rto.CourseId,
		rto.CourseRequisiteId,
		rto.ReqTypeId as CurrReqTypeId,
		rto.NewSortOrder,
		cast(case when rto.ReqTypeId is not null then 1 else 0 end as bit) as OutputReqType,
		case when rto.ReqTypeId is not null then rto.ReqTypeId else null end as PrevReqTypeId
	from #reqTypeOutput rto
		cross apply (
			select *
			from (
				select min(r.NewSortOrder) as MinSortOrder
				from #reqTypeOutput r
				where rto.CourseId = r.CourseId
				group by r.CourseId
			) fn2
			where rto.NewSortOrder = fn2.MinSortOrder
		) fn
	union all
	select
	    rto.CourseId,
		rto.CourseRequisiteId,
		rto.ReqTypeId as CurrReqTypeId,
		rto.NewSortOrder,
		cast(
			case
				when isnull(rtoc.PrevReqTypeId, 0) != isnull(rto.ReqTypeId, 0) then 1
				else 0 
			end 
			as bit
		) as OutputReqType,
		case
			when rtoc.PrevReqTypeId is not null and rto.ReqTypeId is null then rtoc.PrevReqTypeId
			when rtoc.PrevReqTypeId is null and rto.ReqTypeId is not null then rto.ReqTypeId
			when rtoc.PrevReqTypeId is null and rto.ReqTypeId is null then null
			when rtoc.PrevReqTypeId = rto.ReqTypeId then rto.ReqTypeId
			when rtoc.PrevReqTypeId != rto.ReqTypeId then rto.ReqTypeId
			end as PrevReqTypeId
	from #reqTypeOutput rto
		inner join ReqTypeOutputCheck rtoc on (rto.NewSortOrder = (rtoc.NewSortOrder + 1))
										and (rto.CourseId = rtoc.CourseId)
)
update rto
set rto.OutputReqType = rtoc.OutputReqType
from #reqTypeOutput rto
inner join ReqTypeOutputCheck rtoc on rto.CourseRequisiteId = rtoc.CourseRequisiteId;

drop table if exists #renderedOutcomes;
create table #renderedOutcomes (
	CourseId int,
	Id int primary key,
	Parent_Id int index ixRenderedOutcomes_Parent_Id,
	RenderedText nvarchar(max),
	SortOrder int index ixRenderedOutcomes_SortOrder,
	ListItemTypeId int
);

set @renderQuery = ''
declare @childIds integers;

insert into @childIds (Id)
select cr2.Id
from CourseRequisite cr
inner join @renderIds ri on cr.Id = ri.Id
inner join CourseRequisite cr2 on cr.Id = cr2.Parent_Id;

--select ''''@childIds'''', *
--from @childIds

if ((select count(*) from @childIds) > 0)
begin;
	--print ''''@renderQuery:[''''
	--print @renderQuery
	--print '''']''''
	exec sp_executesql @renderQuery, N''''@renderIds integers readonly, @renderQuery nvarchar(max)'''', @childIds, @renderQuery;
end;

insert into #renderedOutcomes (CourseId, Id, Parent_Id, RenderedText, SortOrder, ListItemTypeId)
select cr.CourseId
, cr.Id
, cr.Parent_Id
, concat(
	dbo.fnHtmlOpenTag(''''div'''',
		concat(
			dbo.fnHtmlAttribute(''''data-requisite-id'''', cr.Id),
			dbo.fnHtmlAttribute(''''data-is-condition'''', case when cr.GroupConditionId is not null then ''''true'''' else ''''false'''' end)
		)),
		dbo.fnTrimWhitespace(
			concat(
				  coalesce(cr.[Description] + '''' '''', '''''''') --Group Title
				, case 
					when rto.OutputReqType = 1 then 
						case
							when rt.Title is not null then 
								dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''requisite-type mt-3'''')) 
								+ dbo.fnHtmlElement(''''b'''', rt.Title + '''': '''', null)
								+ dbo.fnHtmlCloseTag(''''div'''')
							else ''''''''
						end
					else '''''''' 
					end --Requisite Type
				, case
						when
							ec.Title = ''''This course is not open to students with previous credit for''''
						THEN CONCAT(ec.Title, '''' '''')
						ELSE ''''''''
					END
				, concat(s.SubjectCode + '''' '''', cast(c.CourseNumber as varchar) + '''' '''', '''''''') --Requisite Course
				, case
						when (rt.Id in (1, 3, 4, 6) and c.Id IS NOT NULL) then '''' with a Grade of "C" or better, or equivalent ''''
						else ''''''''
						end -- min grade text
				, coalesce(cr.RequisiteOutcome + '''' '''','''''''') -- required statue
				, CASE
					WHEN ec.Title <> ''''This course is not open to students with previous credit for''''
						THEN coalesce(ec.Title + '''' '''','''''''') -- enroll limit title
						ELSE ''''''''
					END
				, coalesce(cr.EntrySkill + '''' '''','''''''') -- same req desc
				, coalesce(''''or Milestone '''' + fn.AssessmentLevel + '''' '''','''''''') -- assessment
				, coalesce(cr.CourseRequisiteComment + '''' '''','''''''') --Course Requisite Comment
				, dbo.fnHtmlOpenTag(''''div class="requisite-children"'''', null)
					, rc.RenderedChildren
				, dbo.fnHtmlCloseTag(''''div'''')
			)
		),
	dbo.fnHtmlCloseTag(''''div'''')
)
--, cr.SortOrder
, rto.NewSortOrder
, cr.ListItemTypeId
from CourseRequisite cr
inner join @renderIds ri on cr.Id = ri.Id
inner join #reqTypeOutput rto on cr.Id = rto.CourseRequisiteId
left join RequisiteType rt on rt.Id = cr.RequisiteTypeId
left join [Subject] s on s.Id = cr.SubjectId
left join Course c on c.Id = cr.Requisite_CourseId
left join EligibilityCriteria ec on cr.EligibilityCriteriaId = ec.Id
outer apply (
	select dbo.ConcatWithSepOrdered_Agg(''''/'''', fn2.RowId, fn2.AssessmentLevel) as AssessmentLevel
	from (
		select cch.CourseId
		, ch.Code as AssessmentLevel
		, row_number() over (partition by cch.CourseId order by ch.Code) as RowId
		from CourseCohort cch
			inner join [Cohort] ch on cch.cohortid = ch.Id
		where cr.Requisite_CourseId = cch.CourseId
	) fn2
) fn
outer apply (
	select 
		dbo.ConcatWithSepOrdered_Agg(
			concat(dbo.fnHtmlOpenTag(''''div'''', null), ct.ConditionText, dbo.fnHtmlCloseTag(''''div'''')),
			ro.SortOrder,
			ro.RenderedText
		) as RenderedChildren
	from #renderedOutcomes ro
	cross apply (
		select case 
			when cr.GroupConditionId = 1 then '''' and '''' 
			when cr.GroupConditionId = 2 then '''' or '''' 
			else ''''(no group condition set)'''' 
			end 
			as ConditionText
	) ct
	where ro.Parent_Id = cr.Id
) rc

--select ''''#renderedOutcomes'''', *
--from #renderedOutcomes
''
declare @childIds integers;

insert into @childIds (Id)
select Id
from CourseRequisite cr
	inner join @modelRoot mr on cr.CourseId = mr.CourseId
and cr.Parent_Id is null;

--select ''end-@childIds'', *
--from @childIds

--select ''@renderIds'', *
--from @renderIds

--print ''@renderQuery:[''
--print @renderQuery
--print '']''

exec sp_executesql @renderQuery, N''@renderIds integers readonly, @renderQuery nvarchar(max)'', @childIds, @renderQuery;

--select ''end-#renderedOutcomes'', *
--from #renderedOutcomes

--select *
--from #reqTypeOutput
--order by NewSortOrder

select ro.CourseId as [Value]
   , dbo.ConcatWithSepOrdered_Agg(
		''<div>and</div>'',
		ro.SortOrder,
		ro.RenderedText
	) as [Text]
from #renderedOutcomes ro
where ro.Parent_Id is null
group by ro.CourseId;

drop table if exists #renderedOutcomes;
drop table if exists #reqTypeOutput;
drop table if exists #reqTypeOrder;

end;
else
begin;

	select c.Id as [Value]
	, c.SpecifyDegree as [Text]
	from Course c
		inner join @modelRoot mr on c.Id = mr.CourseId
end;


'
, ResolutionSql = '

declare @modelRoot table (
	InsertOrder int identity primary key,
	CourseId int
);

declare 
	@RenderV2Requisites bit
;



insert into @modelRoot
select @EntityId


if (isnull(@RenderV2Requisites, 0) = 0)
begin;

declare @renderQuery nvarchar(max);
declare @renderIds integers;

drop table if exists #reqTypeOutput;
create table #reqTypeOutput (
	CourseId int,
	CourseRequisiteId int,
	ParentId int,
	ReqTypeId int,
	_ReqType nvarchar(max),
	_condition nvarchar(max),
	_course nvarchar(max),
	SortOrder int,
	IsCondition bit,
	_ReSortOrder int,
	_ReSortCourseRequisiteId int,
	OutputReqType bit,
	NestedNumber int,
	NewSortOrder int
);

insert into #reqTypeOutput (cr.CourseId, CourseRequisiteId, ParentId, ReqTypeId, SortOrder, _course, _condition, _ReqType, IsCondition)
select cr.CourseId
, cr.Id, cr.Parent_Id, cr.RequisiteTypeId
, row_number() over (partition by cr.CourseId order by cr.SortOrder, cr.Id)
, concat(s.SubjectCode, '' '', c.CourseNumber)
, gc.Title
, substring(rt.Title, 1, 1)
, case when gc.Id is not null then 1 else 0 end
from CourseRequisite cr
	inner join @modelRoot mr on cr.CourseId = mr.CourseId
	left join Course c on cr.Requisite_CourseId = c.Id
	left join [Subject] s on c.SubjectId = s.Id
	left join GroupCondition gc on cr.GroupConditionId = gc.Id
	left join RequisiteType rt on cr.RequisiteTypeId = rt.Id


drop table if exists #reqTypeOrder;
create table #reqTypeOrder (
	ReqTypeId int,
	SortOrder int
);

-- intetionally I didn''t want to use the sortorder of the lookup because to not tied the requisite type dropdown presentation vs this presentation query
insert into #reqTypeOrder
select fn.Id
, row_number() over (order by fn.SortOrder, fn.Id)
from (
	select rt.Id
	, case
		when rt.Id = 1 then 1 -- Prerequisite
		end as SortOrder
	from RequisiteType rt
) fn


;with Recur as (
	select r.CourseRequisiteId
	, r.ParentId
	, 1 as NestedNumber
	from #reqTypeOutput r
	where r.ParentId is null
	union all
	select t.CourseRequisiteId
	, t.ParentId
	, r.NestedNumber + 1 as NestedNumber
	from Recur r
		inner join #reqTypeOutput t on r.CourseRequisiteId = t.ParentId
)
	update o
	set o.NestedNumber = r.NestedNumber
	from Recur r
		inner join #reqTypeOutput o on r.CourseRequisiteId = o.CourseRequisiteId

update r
set r._ReSortCourseRequisiteId = r.CourseRequisiteId
from #reqTypeOutput r
where r.IsCondition = 0

DELETE FROM #reqTypeOutput
WHERE ReqTypeId in (2, 3, 4, 5, 6, 7, 11)

declare @SortOrderQuery nvarchar(max) = ''

declare @childIds integers;

insert into @childIds (Id)
select cr2.Id
from CourseRequisite cr
inner join @renderIds ri on cr.Id = ri.Id
inner join CourseRequisite cr2 on cr.Id = cr2.Parent_Id;


if ((select count(*) from @childIds) > 0)
begin;
	exec sp_executesql @renderQuery, N''''@renderIds integers readonly, @renderQuery nvarchar(max)'''', @childIds, @renderQuery;
end;

;with temp as (
	select r.ParentId
	, r2.CourseRequisiteId
	, row_number() over (partition by r.CourseId, r.ParentId order by so2.SortOrder, so2.ReqTypeId, r.SortOrder, r.CourseRequisiteId) as SortOrder
	from #reqTypeOutput r
		inner join @childIds c on r.CourseRequisiteId = c.Id
		inner join #reqTypeOutput r2 on r._ReSortCourseRequisiteId = r2.CourseRequisiteId
		left join #reqTypeOrder so2 on r2.ReqTypeId = so2.ReqTypeId
)
	update r
	set r._ReSortCourseRequisiteId = t.CourseRequisiteId
	--select r.*
	--, t.SortOrder
	from temp t
		inner join #reqTypeOutput r on t.ParentId = r.CourseRequisiteId
	where t.SortOrder = 1

''

declare @childIds_SortOrder integers;
insert into @childIds_SortOrder (Id)
select Id
from CourseRequisite cr
	inner join @modelRoot mr on cr.CourseId = mr.CourseId
where cr.Parent_Id is null;

exec sp_executesql @SortOrderQuery, N''@renderIds integers readonly, @renderQuery nvarchar(max)'', @childIds_SortOrder, @SortOrderQuery;

;with temp as (
	select r.CourseRequisiteId
	, row_number() over (partition by r.CourseId order by
		so.SortOrder,
		so.ReqTypeId,
		r.SortOrder,
		r.CourseRequisiteId
	) as SortOrder
	--, ''=>''
	--, so.SortOrder
	--, so.ReqTypeId
	--, r.SortOrder
	--, r.CourseRequisiteId
	--, ''=>''
	--, o.CourseRequisiteId
	from #reqTypeOutput r
		inner join #reqTypeOutput o on r._ReSortCourseRequisiteId = o.CourseRequisiteId
		inner join #reqTypeOrder so on o.ReqTypeId = so.ReqTypeId
	where r.ParentId is null
)
	update r
	set r._ReSortOrder = t.SortOrder
	from temp t
		inner join #reqTypeOutput r on t.CourseRequisiteId = r.CourseRequisiteId

;with temp as (
	select r.CourseRequisiteId
	, row_number() over (partition by r.CourseId, r.ParentId order by
		so.SortOrder,
		so.ReqTypeId,
		r.SortOrder,
		r.CourseRequisiteId
	) as SortOrder
	--, ''=>''
	--, r.*
	from #reqTypeOutput r
		inner join #reqTypeOutput o on r._ReSortCourseRequisiteId = o.CourseRequisiteId
		inner join #reqTypeOrder so on o.ReqTypeId = so.ReqTypeId
	where r.ParentId is not null
	--order by r.SortOrder
)
	update r
	set r._ReSortOrder = t.SortOrder
	from #reqTypeOutput r
		inner join temp t on r.CourseRequisiteId = t.CourseRequisiteId

;with SortOrderChain as (
	select CourseRequisiteId
	, ParentId
	, format(_ReSortOrder, ''D10'') as SortChain
	from #reqTypeOutput
	where ParentId is null
	union all
	select r.CourseRequisiteId
	, r.ParentId
	, concat(s.SortChain, ''_'', format(r._ReSortOrder, ''D10'')) as SortChain
	from SortOrderChain s
		inner join #reqTypeOutput r on s.CourseRequisiteId = r.ParentId
)
, temp as (
	select r.CourseRequisiteId
	, row_number() over (partition by r.CourseId order by s.SortChain) as NewSortOrder
	from SortOrderChain s
		inner join #reqTypeOutput r on s.CourseRequisiteId = r.CourseRequisiteId
)
	update rto
	set rto.NewSortOrder = t.NewSortOrder
	from #reqTypeOutput rto 
		inner join temp t on rto.CourseRequisiteId = t.CourseRequisiteId

;

;with ReqTypeOutputCheck as
(
	select
	    rto.CourseId,
		rto.CourseRequisiteId,
		rto.ReqTypeId as CurrReqTypeId,
		rto.NewSortOrder,
		cast(case when rto.ReqTypeId is not null then 1 else 0 end as bit) as OutputReqType,
		case when rto.ReqTypeId is not null then rto.ReqTypeId else null end as PrevReqTypeId
	from #reqTypeOutput rto
		cross apply (
			select *
			from (
				select min(r.NewSortOrder) as MinSortOrder
				from #reqTypeOutput r
				where rto.CourseId = r.CourseId
				group by r.CourseId
			) fn2
			where rto.NewSortOrder = fn2.MinSortOrder
		) fn
	union all
	select
	    rto.CourseId,
		rto.CourseRequisiteId,
		rto.ReqTypeId as CurrReqTypeId,
		rto.NewSortOrder,
		cast(
			case
				when isnull(rtoc.PrevReqTypeId, 0) != isnull(rto.ReqTypeId, 0) then 1
				else 0 
			end 
			as bit
		) as OutputReqType,
		case
			when rtoc.PrevReqTypeId is not null and rto.ReqTypeId is null then rtoc.PrevReqTypeId
			when rtoc.PrevReqTypeId is null and rto.ReqTypeId is not null then rto.ReqTypeId
			when rtoc.PrevReqTypeId is null and rto.ReqTypeId is null then null
			when rtoc.PrevReqTypeId = rto.ReqTypeId then rto.ReqTypeId
			when rtoc.PrevReqTypeId != rto.ReqTypeId then rto.ReqTypeId
			end as PrevReqTypeId
	from #reqTypeOutput rto
		inner join ReqTypeOutputCheck rtoc on (rto.NewSortOrder = (rtoc.NewSortOrder + 1))
										and (rto.CourseId = rtoc.CourseId)
)
update rto
set rto.OutputReqType = rtoc.OutputReqType
from #reqTypeOutput rto
inner join ReqTypeOutputCheck rtoc on rto.CourseRequisiteId = rtoc.CourseRequisiteId;

drop table if exists #renderedOutcomes;
create table #renderedOutcomes (
	CourseId int,
	Id int primary key,
	Parent_Id int index ixRenderedOutcomes_Parent_Id,
	RenderedText nvarchar(max),
	SortOrder int index ixRenderedOutcomes_SortOrder,
	ListItemTypeId int
);

set @renderQuery = ''
declare @childIds integers;

insert into @childIds (Id)
select cr2.Id
from CourseRequisite cr
inner join @renderIds ri on cr.Id = ri.Id
inner join CourseRequisite cr2 on cr.Id = cr2.Parent_Id;

--select ''''@childIds'''', *
--from @childIds

if ((select count(*) from @childIds) > 0)
begin;
	--print ''''@renderQuery:[''''
	--print @renderQuery
	--print '''']''''
	exec sp_executesql @renderQuery, N''''@renderIds integers readonly, @renderQuery nvarchar(max)'''', @childIds, @renderQuery;
end;

insert into #renderedOutcomes (CourseId, Id, Parent_Id, RenderedText, SortOrder, ListItemTypeId)
select cr.CourseId
, cr.Id
, cr.Parent_Id
, concat(
	dbo.fnHtmlOpenTag(''''div'''',
		concat(
			dbo.fnHtmlAttribute(''''data-requisite-id'''', cr.Id),
			dbo.fnHtmlAttribute(''''data-is-condition'''', case when cr.GroupConditionId is not null then ''''true'''' else ''''false'''' end)
		)),
		dbo.fnTrimWhitespace(
			concat(
				  coalesce(cr.[Description] + '''' '''', '''''''') --Group Title
				, case 
					when rto.OutputReqType = 1 then 
						case
							when rt.Title is not null then 
								dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''requisite-type mt-3'''')) 
								+ dbo.fnHtmlElement(''''b'''', rt.Title + '''': '''', null)
								+ dbo.fnHtmlCloseTag(''''div'''')
							else ''''''''
						end
					else '''''''' 
					end --Requisite Type
				, case
						when
							ec.Title = ''''This course is not open to students with previous credit for''''
						THEN CONCAT(ec.Title, '''' '''')
						ELSE ''''''''
					END
				, concat(s.SubjectCode + '''' '''', cast(c.CourseNumber as varchar) + '''' '''', '''''''') --Requisite Course
				, case
						when (rt.Id in (1, 3, 4, 6) and c.Id IS NOT NULL) then '''' with a Grade of "C" or better, or equivalent ''''
						else ''''''''
						end -- min grade text
				, coalesce(cr.RequisiteOutcome + '''' '''','''''''') -- required statue
				, CASE
					WHEN ec.Title <> ''''This course is not open to students with previous credit for''''
						THEN coalesce(ec.Title + '''' '''','''''''') -- enroll limit title
						ELSE ''''''''
					END
				, coalesce(cr.EntrySkill + '''' '''','''''''') -- same req desc
				, coalesce(''''or Milestone '''' + fn.AssessmentLevel + '''' '''','''''''') -- assessment
				, coalesce(cr.CourseRequisiteComment + '''' '''','''''''') --Course Requisite Comment
				, dbo.fnHtmlOpenTag(''''div class="requisite-children"'''', null)
					, rc.RenderedChildren
				, dbo.fnHtmlCloseTag(''''div'''')
			)
		),
	dbo.fnHtmlCloseTag(''''div'''')
)
--, cr.SortOrder
, rto.NewSortOrder
, cr.ListItemTypeId
from CourseRequisite cr
inner join @renderIds ri on cr.Id = ri.Id
inner join #reqTypeOutput rto on cr.Id = rto.CourseRequisiteId
left join RequisiteType rt on rt.Id = cr.RequisiteTypeId
left join [Subject] s on s.Id = cr.SubjectId
left join Course c on c.Id = cr.Requisite_CourseId
left join EligibilityCriteria ec on cr.EligibilityCriteriaId = ec.Id
outer apply (
	select dbo.ConcatWithSepOrdered_Agg(''''/'''', fn2.RowId, fn2.AssessmentLevel) as AssessmentLevel
	from (
		select cch.CourseId
		, ch.Code as AssessmentLevel
		, row_number() over (partition by cch.CourseId order by ch.Code) as RowId
		from CourseCohort cch
			inner join [Cohort] ch on cch.cohortid = ch.Id
		where cr.Requisite_CourseId = cch.CourseId
	) fn2
) fn
outer apply (
	select 
		dbo.ConcatWithSepOrdered_Agg(
			concat(dbo.fnHtmlOpenTag(''''div'''', null), ct.ConditionText, dbo.fnHtmlCloseTag(''''div'''')),
			ro.SortOrder,
			ro.RenderedText
		) as RenderedChildren
	from #renderedOutcomes ro
	cross apply (
		select case 
			when cr.GroupConditionId = 1 then '''' and '''' 
			when cr.GroupConditionId = 2 then '''' or '''' 
			else ''''(no group condition set)'''' 
			end 
			as ConditionText
	) ct
	where ro.Parent_Id = cr.Id
) rc

--select ''''#renderedOutcomes'''', *
--from #renderedOutcomes
''
declare @childIds integers;

insert into @childIds (Id)
select Id
from CourseRequisite cr
	inner join @modelRoot mr on cr.CourseId = mr.CourseId
and cr.Parent_Id is null;

--select ''end-@childIds'', *
--from @childIds

--select ''@renderIds'', *
--from @renderIds

--print ''@renderQuery:[''
--print @renderQuery
--print '']''

exec sp_executesql @renderQuery, N''@renderIds integers readonly, @renderQuery nvarchar(max)'', @childIds, @renderQuery;

--select ''end-#renderedOutcomes'', *
--from #renderedOutcomes

--select *
--from #reqTypeOutput
--order by NewSortOrder

select ro.CourseId as [Value]
   , dbo.ConcatWithSepOrdered_Agg(
		''<div>and</div>'',
		ro.SortOrder,
		ro.RenderedText
	) as [Text]
from #renderedOutcomes ro
where ro.Parent_Id is null
group by ro.CourseId;

drop table if exists #renderedOutcomes;
drop table if exists #reqTypeOutput;
drop table if exists #reqTypeOrder;

end;
else
begin;

	select c.Id as [Value]
	, c.SpecifyDegree as [Text]
	from Course c
		inner join @modelRoot mr on c.Id = mr.CourseId
end;


'
WHERE Id = 21

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
;WITH OrderedObjectives AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY CourseId ORDER BY SortOrder, id) AS rn
    FROM CourseObjective
    WHERE CourseId = @EntityID
)

SELECT 
    CONCAT(
        ''Upon successful completion of the course the student will be able to: '', 
        ''<ol>'', 
        STRING_AGG(CONCAT(''<li>'', Text, ''</li>''), '''') WITHIN GROUP (ORDER BY rn), 
        ''</ol>''
    ) AS Text, 
    0 AS Value
FROM OrderedObjectives
'
,ResolutionSql = '
;WITH OrderedObjectives AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY CourseId ORDER BY SortOrder, id) AS rn
    FROM CourseObjective
    WHERE CourseId = @EntityID
)

SELECT 
    CONCAT(
        ''Upon successful completion of the course the student will be able to: '', 
        ''<ol>'', 
        STRING_AGG(CONCAT(''<li>'', Text, ''</li>''), '''') WITHIN GROUP (ORDER BY rn), 
        ''</ol>''
    ) AS Text, 
    0 AS Value
FROM OrderedObjectives
'
WHERE Id = 25

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @text nvarchar(max);

SET @text = (
SELECT concat(''<span>Methods of instruction may include, but are not limited to, the following:</span><ul><strong><li>'',dbo.ConcatWithSepOrdered_Agg(''</li><li>'', it.SortOrder,it.Title))
FROM CourseInstructionType cit
	INNER JOIN InstructionType it ON it.Id = cit.InstructionTypeId
	INNER JOIN GenericMaxText mt ON mt.CourseId = cit.CourseId
WHERE cit.CourseId = @entityId)


SELECT @text +	CASE 
					WHEN cit.Id IS NOT NULL
					THEN CONCAT('': '', TextMax07)
					ELSE ''''
				END
			+ ''</li></strong></ul>'' AS Text, 0 AS Value, cit.InstructionTypeId
FROM GenericMaxText mt
	LEFT JOIN CourseInstructionType cit ON cit.CourseId = mt.CourseId AND cit.InstructionTypeId = 1022
WHERE mt.CourseId = @entityId
'
,ResolutionSql = '
DECLARE @text nvarchar(max);

SET @text = (
SELECT concat(''<span>Methods of instruction may include, but are not limited to, the following:</span><ul><strong><li>'',dbo.ConcatWithSepOrdered_Agg(''</li><li>'', it.SortOrder,it.Title))
FROM CourseInstructionType cit
	INNER JOIN InstructionType it ON it.Id = cit.InstructionTypeId
	INNER JOIN GenericMaxText mt ON mt.CourseId = cit.CourseId
WHERE cit.CourseId = @entityId)


SELECT @text +	CASE 
					WHEN cit.Id IS NOT NULL
					THEN CONCAT('': '', TextMax07)
					ELSE ''''
				END
			+ ''</li></strong></ul>'' AS Text, 0 AS Value, cit.InstructionTypeId
FROM GenericMaxText mt
	LEFT JOIN CourseInstructionType cit ON cit.CourseId = mt.CourseId AND cit.InstructionTypeId = 1022
WHERE mt.CourseId = @entityId
'
WHERE Id = 26

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @text nvarchar(max) =
(SELECT CONCAT(''<span>A student''''s grade will be based on multiple measures of performance unless the course requires no grade. Multiple measures may include, but are not limited to, the following:</span>'', dbo.ConcatWithSepOrdered_Agg(''<br>'', em.SortOrder, em.Title))
FROM CourseEvaluationMethod cem
	INNER JOIN EvaluationMethod em ON em.Id = cem.EvaluationMethodId
WHERE cem.CourseId = @entityId)

SELECT (@text +	CASE 
					WHEN cem.Id IS NOT NULL
					THEN CONCAT('': '', c.AdvisoryCommittee)
					ELSE ''''
				END) AS Text, 0 AS Value
FROM Course c 
	INNER JOIN CourseEvaluationMethod cem ON cem.courseId = c.Id 
WHERE c.Id = @entityId
'
,ResolutionSql = '
DECLARE @text nvarchar(max) =
(SELECT CONCAT(''<span>A student''''s grade will be based on multiple measures of performance unless the course requires no grade. Multiple measures may include, but are not limited to, the following:</span>'', dbo.ConcatWithSepOrdered_Agg(''<br>'', em.SortOrder, em.Title))
FROM CourseEvaluationMethod cem
	INNER JOIN EvaluationMethod em ON em.Id = cem.EvaluationMethodId
WHERE cem.CourseId = @entityId)

SELECT (@text +	CASE 
					WHEN cem.Id IS NOT NULL
					THEN CONCAT('': '', c.AdvisoryCommittee)
					ELSE ''''
				END) AS Text, 0 AS Value
FROM Course c 
	INNER JOIN CourseEvaluationMethod cem ON cem.courseId = c.Id 
WHERE c.Id = @entityId
'
WHERE Id = 27

Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
SELECT 0 AS Value,
CASE
	WHEN LectureOutline IS NOT NULL
	THEN CONCAT('<span>The following topics are included in the framework of the course but are not intended as limits on content. The order of presentation and relative emphasis will vary with each instructor.</span>', LectureOutline)
	ELSE NULL
END AS Text
FROM Course WHERE Id = @EntityID
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'LectureOutline', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'ASSIST PREVIEW', 2)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 8996
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, FieldTypeId = 5
, MetaForeignKeyLookupSourceId = @MAX
WHERE MetaAvailableFieldId = 3454
and MetadataAttributeMapId IS NOT NULL

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (
		21, 25, 26, 27
	)
)