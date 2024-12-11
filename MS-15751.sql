USE [sdccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15751';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Requisites query';
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (10)		--comment back in if just doing some of the mtt's

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('Colleges', 'CourseDEAddendum', 'MaxText01','Update'),
('Entry Skills', 'CourseEntrySkill', 'MaxText01', 'Update2'),
('Entry Skills', 'CourseEntrySkillCourseObjective', 'Requisite_CourseId', 'Update3')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedSection
SET ReadOnly = 0
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedSection
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('Update2', 'Update3')
)

UPDATE OutputTemplateClient
SET TemplateQuery = '
-- README:
-- This query is shared between different views: forms, COR and Admin Reports. As of 01/29/2024
-- This query renders the requisites summary view from the meta requisite ordered list by default. If param bit ''RenderV2Requisites'' is true, then it will render data from the Course.SpecifyDegree. Every v2 migrated course that had requisites data should have data in that backendstore.


declare @modelRoot table (
	InsertOrder int identity primary key,
	CourseId int
);

declare 
	@RenderV2Requisites bit
;

select
	@RenderV2Requisites = atc.RenderV2Requisites
from openjson(@additionalTemplateConfig)
with (
	RenderV2Requisites bit ''$.RenderV2Requisites''
) atc;

insert into @modelRoot
select [Key]
from @entityModels


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
		when rt.Id = 2 then 2 -- Corequisite
		when rt.Id = 3 then 3 -- Corequisite: Completion...
		when rt.Id = 4 then 4 -- Advisory
		when rt.Id = 5 then 5 -- Advisory: Concurrent...
		when rt.Id = 6 then 6 -- Advisory: Completion...
		when rt.Id = 7 then 7 -- Limitation...
		when rt.Id = 8 then 8 -- Alternate...
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
				, concat(s.SubjectCode + '''' '''', cast(c.CourseNumber as varchar) + '''' '''', '''''''') --Requisite Course
				, case
						when (rt.Id in (1, 3, 4, 6) and c.Id IS NOT NULL) then '''' with a Grade of "C" or better, or equivalent ''''
						else ''''''''
						end -- min grade text
				, coalesce(cr.RequisiteOutcome + '''' '''','''''''') -- required statue
				, coalesce(ec.Title + '''' '''','''''''') -- enroll limit title
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
WHERE Id = 1
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback