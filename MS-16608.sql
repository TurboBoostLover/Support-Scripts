USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16608';
DECLARE @Comments nvarchar(Max) = 
	'Update Requisite output';
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
DECLARE @SQL NVARCHAR(MAX) = '
declare @renderQuery nvarchar(max);
declare @renderIds integers;

drop table if exists #reqTypeOutput;
create table #reqTypeOutput (
	CourseRequisiteId int,
	RootId int,
	ParentId int,
	ReqTypeId int,
	SortOrder int,
	SortString nvarchar(255),
	IterationOrder int,
	OutputReqType bit
);

insert into #reqTypeOutput (CourseRequisiteId, ParentId, ReqTypeId, SortOrder)
select cr.Id, cr.Parent_Id, cr.RequisiteTypeId, row_number() over (order by cr.SortOrder, cr.Id)
from CourseRequisite cr
where cr.CourseId = @entityId
order by cr.SortOrder;

with ReqSortString as (
	select rto.CourseRequisiteId, rto.CourseRequisiteId as RootId, cast(concat('''', rto.SortOrder) as nvarchar(255)) as SortString
	from #reqTypeOutput rto
	where rto.ParentId is null
	union all
	select rto.CourseRequisiteId, rss.RootId, cast(concat('''', rto.SortOrder) as nvarchar(255)) as SortString
	from #reqTypeOutput rto
	inner join ReqSortString rss on rto.ParentId = rss.CourseRequisiteId
)

update rto
set rto.SortString = rss.SortString, rto.RootId = rss.RootId
from #reqTypeOutput rto
inner join ReqSortString rss on rto.CourseRequisiteId = rss.CourseRequisiteId;

merge into #reqTypeOutput t
using (
	select rto.CourseRequisiteId, rto.SortString as IterationOrder
	from #reqTypeOutput rto
) s
on (t.CourseRequisiteId = s.CourseRequisiteId)
when matched then update set t.IterationOrder = s.IterationOrder;


with ReqTypeOutputCheck as
(
    select
        rto.CourseRequisiteId, rto.ReqTypeId as CurrReqTypeId, rto.IterationOrder, rto.SortOrder,
        cast(case when rto.ReqTypeId is not null then 1 else 0 end as bit) as OutputReqType
    from #reqTypeOutput rto
    where rto.IterationOrder = 1
    union all
    select
        rto.CourseRequisiteId, rto.ReqTypeId as CurrReqTypeId, rto.IterationOrder, rto.SortOrder,
        cast(case when rto.ReqTypeId is not null and (rtoc.CurrReqTypeId is null or rto.ReqTypeId <> rtoc.CurrReqTypeId) then 1 else 0 end as bit) as OutputReqType
    from #reqTypeOutput rto
    inner join ReqTypeOutputCheck rtoc on rto.SortOrder = (rtoc.SortOrder + 1)
)

update rto
set rto.OutputReqType = rtoc.OutputReqType
from #reqTypeOutput rto
inner join ReqTypeOutputCheck rtoc on rto.CourseRequisiteId = rtoc.CourseRequisiteId;

drop table if exists #renderedOutcomes;
create table #renderedOutcomes (
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

if ((select count(*) from @childIds) > 0)
begin;
	exec sp_executesql @renderQuery, N''''@renderIds integers readonly, @renderQuery nvarchar(max)'''', @childIds, @renderQuery;
end;

insert into #renderedOutcomes (Id, Parent_Id, RenderedText, SortOrder, ListItemTypeId)
select cr.Id, cr.Parent_Id, dbo.fnTrimWhitespace(concat(
			coalesce(cr.[Description] + '''' '''', '''''''') --Group Title
			, case when rto.OutputReqType = 1 then coalesce(rt.Title + '''': '''', '''''''') else '''''''' end --Requisite Type
			, concat(s.SubjectCode + '''' '''', cast(c.CourseNumber as varchar) + '''' '''', '''''''') --Requisite Course
			, coalesce(cr.EntrySkill + '''' '''','''''''') --Requisite Comment
			, coalesce(cr.CourseRequisiteComment + '''' '''','''''''') --Non Course Requisite Comment
			, dbo.fnHtmlOpenTag(''''span'''', null) , rc.RenderedChildren , dbo.fnHtmlCloseTag(''''span'''')
		)), cr.SortOrder, cr.ListItemTypeId
from CourseRequisite cr
inner join @renderIds ri on cr.Id = ri.Id
inner join #reqTypeOutput rto on cr.Id = rto.CourseRequisiteId
left join RequisiteType rt on rt.Id = cr.RequisiteTypeId
left join [Subject] s on s.Id = cr.SubjectId
left join Course c on c.Id = cr.Requisite_CourseId
outer apply (
	select 
		dbo.ConcatWithSepOrdered_Agg(ct.ConditionText, ro.SortOrder, ro.RenderedText) as RenderedChildren
	from #renderedOutcomes ro
	cross apply (
		select case when cr.GroupConditionId = 1 then '''' and '''' when cr.GroupConditionId = 2 then '''' or '''' else '''', '''' end as ConditionText
	) ct
	where ro.Parent_Id = cr.Id
) rc
''


declare @childIds integers;

insert into @childIds (Id)
select Id
from CourseRequisite cr
where cr.CourseId = @entityId
and cr.Parent_Id is null;

exec sp_executesql @renderQuery, N''@renderIds integers readonly, @renderQuery nvarchar(max)'', @childIds, @renderQuery;

select  dbo.ConcatWithSepOrdered_Agg(
		null,
		ro.SortOrder,
		concat(
			dbo.fnHtmlOpenTag(''div'', null),
				dbo.fnTrimWhitespace(ro.RenderedText),
			dbo.fnHtmlCloseTag(''div'')
		)
	) as [Text]
from #renderedOutcomes ro
where ro.Parent_Id is null;

drop table if exists #renderedOutcomes;
drop table if exists #reqTypeOutput;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 138

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 138
)