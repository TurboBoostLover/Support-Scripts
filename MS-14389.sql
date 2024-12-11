USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14389';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Outline report';
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
DECLARE @SQL NVARCHAR(MAX) = '

drop table if exists #OL;

create table #OL (
	[Text] nvarchar(max)
	, Id int
	, Parent int
	, Sort int
	, ListItemType int
);

insert into #OL
select 
    case 
        when lit.ListItemTypeOrdinal = 1
			and co.EvaluationText is null
            then concat(em.Title, '' ('', co.EvaluationPercent, ''-'', co.Int01, ''%)'',
							CASE
								WHEN co.LargeText02 IS NULL
									THEN NULL
									ELSE CONCAT(''<ul><li><b>Comment: </b>'', co.LargeText02, ''</ul>'')
							END
						)
		when lit.ListItemTypeOrdinal = 1
			and co.EvaluationText is not null
            then concat(em.Title, '': '', co.EvaluationText, '' ('', co.EvaluationPercent, ''-'', co.Int01, ''%)'',
						CASE
								WHEN co.LargeText02 IS NULL
									THEN NULL
									ELSE CONCAT(''<ul><li><b>Comment: </b>'', co.LargeText02, ''</ul>'')
							END
						)
        else co.LargeText01
    end as [Text]
	, co.Id
	, co.Parent_Id as Parent
	, co.SortOrder as Sort
	, co.ListItemTypeId as ListItemType
from CourseEvaluationMethod co
	inner join ListItemType lit on co.ListItemTypeId = lit.Id
	left join EvaluationMethod em on co.EvaluationMethodId = em.Id
where co.CourseId = @entityId;

if ((select count(*) from #OL) > 0)
	begin
		declare @renderQuery nvarchar(max);
		declare @renderIds integers;

		drop table if exists #renderedOutcomes;
		create table #renderedOutcomes (
			Id int primary key,
			Parent_Id int index ixRenderedOutcomes_Parent_Id,
			RenderedText nvarchar(max),
			SortOrder int index ixRenderedOutcomes_SortOrder,
			ListItemTypeId int
		);
		--====================
		SET @renderQuery =
		''declare @childIds integers;

		insert into @childIds (Id)
		select co2.Id
		from #OL co
		inner join @renderIds ri on co.Id = ri.Id
		inner join #OL co2 on co.Id = co2.Parent;

		if ((select count(*) from @childIds) > 0)
		begin;
			exec sp_executesql @renderQuery, N''''@renderIds integers readonly, @renderQuery nvarchar(max)'''', @childIds, @renderQuery;
		end;

		insert into #renderedOutcomes (Id, Parent_Id, RenderedText, SortOrder,ListItemTypeId)
		select co.Id, co.Parent, ro.RenderedOutcome, co.Sort, co.ListItemType
		from #OL co
		inner join @renderIds ri on co.Id = ri.Id
		outer apply (
			select dbo.ConcatWithSepOrdered_Agg(null, ro.SortOrder, ro.RenderedText) as RenderedChildren
			from #renderedOutcomes ro
			where ro.Parent_Id = co.Id
		) rc
		outer apply (
			select
				concat(
					dbo.fnHtmlOpenTag(''''ol'''', case when co.ListItemType = 5 and co.Parent is not null then ''''style="list-style-type:lower-roman"'''' else ''''style="list-style-type:lower-alpha"''''end), rc.RenderedChildren, dbo.fnHtmlCloseTag(''''ol'''')
				) RenderedChildrenWithListWrapper
			where rc.RenderedChildren is not null and len(rc.RenderedChildren ) > 0
		) rcw
		cross apply (
			select
				concat(
					dbo.fnHtmlOpenTag(''''li'''', null),
						dbo.fnHtmlOpenTag(''''div'''', null), coalesce(co.Text,''''''''),dbo.fnHtmlCloseTag(''''div''''),
						rcw.RenderedChildrenWithListWrapper,
					dbo.fnHtmlCloseTag(''''li'''')
				) as RenderedOutcome
		) ro;'';

		declare @childIds integers;

		insert into @childIds (Id)
		select Id
		from #OL
		where Parent is null;

		exec sp_executesql 
			@renderQuery
			, N''@renderIds integers readonly, @renderQuery nvarchar(max)''
			, @childIds
			, @renderQuery
		;

		select
			concat(
				dbo.fnHtmlOpenTag(''ol'', null),
					dbo.ConcatWithSepOrdered_Agg(NULL, ro.SortOrder, ro.RenderedText),
				dbo.fnHtmlCloseTag(''ol'')
			) as [Text]
			, 0 as [Value]
		from #renderedOutcomes ro
		where ro.Parent_Id is null;
	end;
else
	begin
		select 0 as [Value]
			, SpecifyDegree as [Text]
		from Course
		where Id = @entityId;
	end;

drop table if exists #renderedOutcomes;
drop table if exists #OL;

'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 278

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
    AND mtt.ClientId = 2
		AND mtt.MetaTemplateTypeId = 97
)