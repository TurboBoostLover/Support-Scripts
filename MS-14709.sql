USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14709';
DECLARE @Comments nvarchar(Max) = 
	'Update Custom sql to not error out';
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
Drop table if EXISTS #OL
create table #OL ( Text nvarchar(max), Id int, parent int, sort int, listitemtype int)
Insert into #OL
SELECt 
    Case 
        WHEn lit.ListItemTypeOrdinal = 1 and ot.Title is not NULL
            then concat(ot.Title,'': '', co.text)
		WHEN lit.ListItemTypeOrdinal = 1 and ot.Title is NULL
			THEN co.Text
           ELSE co.header
        End As Text, co.id As ID, co.Parent_Id as Parent, co.SortOrder as sort, co.ListItemTypeId as Listitemtype
FROM CourseObjective co
	INNER JOIN ListItemType lit on co.ListItemTypeId = lit.id
	LEFT JOIN ObjectiveType ot on co.ObjectiveTypeId = ot.Id
WHERE co.CourseId = @entityID
declare @renderQuery nvarchar(max);
declare @renderIds integers;

DROP TABLE IF EXISTS #renderedOutcomes;
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
select
	co.Id, co.Parent, ro.RenderedOutcome, co.Sort,co.ListItemType
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
				dbo.fnHtmlOpenTag(''''div'''', null), coalesce(co.text,''''''''),dbo.fnHtmlCloseTag(''''div''''),
				rcw.RenderedChildrenWithListWrapper,
			dbo.fnHtmlCloseTag(''''li'''')
		) as RenderedOutcome
) ro;''
declare @childIds integers

INSERT INTO @childIds
(Id)
	SELECT
		Id
	FROM #OL
	WHERE Parent IS NULL;

EXEC sp_executesql @renderQuery
				  ,N''@renderIds integers readonly, @renderQuery nvarchar(max)''
				  ,@childIds
				  ,@renderQuery;

SELECT
	CONCAT(
	dbo.fnHtmlOpenTag(''ol'', null),
	dbo.ConcatWithSep_Agg(NULL, ro.RenderedText),
	dbo.fnHtmlCloseTag(''ol'')
	) AS [Text], 0 As Value
FROM #renderedOutcomes ro
WHERE ro.Parent_Id IS NULL;

DROP TABLE IF EXISTS #renderedOutcomes;
DROP TABLE IF EXISTS #OL;
'

UPDATE MetaForeignKeyCriteriaClient
SET ResolutionSql = @SQL
, CustomSql = @SQL
WHERE Id = 280

UPDATE MetaTemplate
sET LastUpdatedDate = gETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField As msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 280
)