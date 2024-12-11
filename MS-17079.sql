USE [aurak];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17079';
DECLARE @Comments nvarchar(Max) = 
	'Update Query';
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
		where cr.CourseId = @entityId;
		
		--select * from #reqTypeOutput;

		with ReqSortString as (
			select rto.CourseRequisiteId, cast(concat('''', rto.SortOrder) as nvarchar(255)) as SortString
			from #reqTypeOutput rto
			where rto.ParentId is null
			union all
			select rto.CourseRequisiteId, cast(concat(rss.SortString, rto.SortOrder) as nvarchar(255)) as SortString
			from #reqTypeOutput rto
				inner join ReqSortString rss on rto.ParentId = rss.CourseRequisiteId
		)
		update rto
		set rto.SortString = rss.SortString
		from #reqTypeOutput rto
			inner join ReqSortString rss on rto.CourseRequisiteId = rss.CourseRequisiteId
		;

		--select * from #reqTypeOutput;

		merge into #reqTypeOutput t
		using (
			select rto.CourseRequisiteId, row_number() over (order by rto.SortOrder) as IterationOrder
			from #reqTypeOutput rto
		) s
		on (t.CourseRequisiteId = s.CourseRequisiteId)
		when matched then update
		set t.IterationOrder = s.IterationOrder;

		--select * from #reqTypeOutput;

		with ReqTypeOutputCheck as
		(
			select rto.CourseRequisiteId
				, rto.ReqTypeId as CurrReqTypeId
				, rto.IterationOrder
				, cast(
					case
						when rto.ReqTypeId is not null
							then 1
						else 0
					end as bit
				) as OutputReqType
			from #reqTypeOutput rto
			where rto.IterationOrder = 1
			union all
			select rto.CourseRequisiteId
				, isnull(rto.ReqTypeId, rtoc.CurrReqTypeId) as CurrReqTypeId
				, rto.IterationOrder
				, cast(
					case
						when rto.ReqTypeId is not null
							and (rtoc.CurrReqTypeId is null
								or rto.ReqTypeId <> rtoc.CurrReqTypeId
							)
							then 1
						else 0
					end as bit
				) as OutputReqType
			from #reqTypeOutput rto
				inner join ReqTypeOutputCheck rtoc on (rto.IterationOrder = (rtoc.IterationOrder + 1))
		)
		update rto
		set rto.OutputReqType = rtoc.OutputReqType
		from #reqTypeOutput rto
			inner join ReqTypeOutputCheck rtoc on rto.CourseRequisiteId = rtoc.CourseRequisiteId
		;

		--select * from #reqTypeOutput;

		drop table if exists #renderedOutcomes;
		create table #renderedOutcomes (
			Id int primary key,
			Parent_Id int index ixRenderedOutcomes_Parent_Id,
			RenderedText nvarchar(max),
			SortOrder int index ixRenderedOutcomes_SortOrder,
			ListItemTypeId int
		);

		set @renderQuery = ''
			declare @courseRequisiteCount int = (select count(*) from #reqTypeOutput);

			--select @courseRequisiteCount as courseRequisiteCount;

			declare @childIds integers;

			insert into @childIds (Id)
			select cr2.Id
			from CourseRequisite cr
				inner join @renderIds ri on cr.Id = ri.Id
				inner join CourseRequisite cr2 on cr.Id = cr2.Parent_Id
			;

			if ((select count(*) from @childIds) > 0)
			begin
				exec sp_executesql @renderQuery, N''''@renderIds integers readonly, @renderQuery nvarchar(max)'''', @childIds, @renderQuery;
			end;
			
			insert into #renderedOutcomes (Id, Parent_Id, RenderedText, SortOrder, ListItemTypeId)
			select cr.Id, cr.Parent_Id, ro.RenderedOutcome, cr.SortOrder, cr.ListItemTypeId
			from CourseRequisite cr
				inner join @renderIds ri on cr.Id = ri.Id
				inner join #reqTypeOutput rto on cr.Id = rto.CourseRequisiteId
				left join RequisiteType rt on rt.Id = cr.RequisiteTypeId
					--and rt.Active = 1 --Removes the display of the requisite type title where requisite type is no longer active
				left join [Subject] s on s.Id = cr.SubjectId
				left join Course c on c.Id = cr.Requisite_CourseId
				left join MinimumGrade mg on cr.MinimumGradeId = mg.Id
				left join CourseRequisite parent on cr.Parent_Id = parent.Id
				left join Condition cd on parent.GroupConditionId = cd.Id
			outer apply (
				select
					gcd.CrossListingId  as Id,
					dbo.ConcatWithSep_Agg('''', '''', concat(s.SubjectCode, '''' '''' , gcd.CourseNumber)) as clc_courses
				from fn_GetClcData(c.Id, 1, NULL) gcd
				inner join Crosslisting cl on gcd.CrossListingId = cl.Id
				inner join Subject s on s.Id = gcd.SubjectId
				where CourseId <> c.Id
				group by gcd.CrossListingId
			) clc
			outer apply (
				select dbo.ConcatWithSepOrdered_Agg(ct.ConditionText, ro.SortOrder, ro.RenderedText) as RenderedChildren
				from #renderedOutcomes ro
					cross apply (
						select
							case
								when cr.GroupConditionId = 1
									then '''' and ''''
								when cr.GroupConditionId = 2
									then '''' or ''''
								when cr.GroupConditionId = 3
									then '''' require ''''
								else '''', ''''
							end as ConditionText
					) ct
				where ro.Parent_Id = cr.Id
			) rc
			outer apply (
				select rc.RenderedChildren AS RenderedChildrenWithListWrapper
				where rc.RenderedChildren is not null
				and len(rc.RenderedChildren) > 0
			) rcw
			cross apply (
				select concat(
					coalesce(cr.[healthtext] + '''' '''', '''''''')--Group Title
					, case
						when rto.OutputReqType = 1
							then coalesce(''''<b>'''' + rt.Title + '''': </b>'''', ''''Other requirement'''')
						else ''''''''
					end --Requisite Type
					, case
						when clc.Id is not null
							then s.SubjectCode + '''' '''' + c.CourseNumber + '''' (same as '''' + clc.clc_courses + '''')'''' --Requisite Course
						else
							s.SubjectCode + '''' '''' + c.CourseNumber
					end
					, 
					CASE WHEN cr.Description IS NOT NULL
					THEN CONCAT(''''<br><b>Other Requirement: </b>'''', cr.Description,''''<br>'''')
					ELSE ''''''''
					END
					, case
						when rto.ParentId is null
							and rto.ReqTypeId is not null
							and rto.IterationOrder <> @courseRequisiteCount
							then '''', ''''
						else ''''''''
					end
					, rcw.RenderedChildrenWithListWrapper
					, ''''''''
				) as RenderedOutcome
			) ro;

			--select * from #renderedOutcomes;
		'';
		
		declare @childIds integers;

		insert into @childIds (Id)
		select Id
		from CourseRequisite cr
		where cr.CourseId = @entityId
		and cr.Parent_Id is null;

		exec sp_executesql @renderQuery, N''@renderIds integers readonly, @renderQuery nvarchar(max)'', @childIds, @renderQuery;

		select 0 as [Value]
		   , dbo.ConcatWithSepOrdered_Agg(
				null,
				ISNULL(ro.SortOrder, 10),
				concat(
					dbo.fnHtmlOpenTag(''span'', null),
						dbo.fnTrimWhitespace(ro.RenderedText),
					dbo.fnHtmlCloseTag(''span''), '' ''
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
WHERE Id = 6

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 6
)