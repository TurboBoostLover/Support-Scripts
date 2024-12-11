USE [chabot];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14228';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Level Report';
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
UPDATE AdminReport
SET ReportSQL = '
declare @groupstart nvarchar(10) = ''(''
	declare @groupend nvarchar(10) = '')''
	declare @requisiteselect nvarchar(max) = 
		'''''''''' + isnull(rt.Title,''''Non-Course Requirement'''') + '''': '''' + rtrim(concat(s.SubjectCode + space(1), c.CourseNumber + space(1) + ''''-'''' + space(1), c.Title + space(1),	
			--''''Complete with a grade of '''' + mg.code + case when cr.isMinGrade = 1 then '''' or better'''' else '''' '''' end,
			case 
				when rtrim(cr.CourseRequisiteComment) like ''''%.'''' OR rtrim(cr.CourseRequisiteComment) like ''''%,''''
					then subString(cr.CourseRequisiteComment, 1, len(rtrim(cr.CourseRequisiteComment)) - 1)
				else cr.CommText
			end + space(1),
			case 
				when rtrim(cr.EntrySkill) like ''''%.'''' OR rtrim(cr.EntrySkill) like ''''%,''''
					then subString(cr.EntrySkill, 1, len(rtrim(cr.EntrySkill)) - 1)
				else cr.EntrySkill
			end + space(1)
		))''
	declare @requisiteGrouping nvarchar(max) = 
		''select concat(rtrim(dbo.ConcatWithSepOrdered_Agg('''','''' + space(1),t.SortOrder,t.RequisiteText)),''''.'''') as RequisiteText, CourseId, t.SortOrder as SortOrder
			from #temp t 
			--join RequisiteType rt on rt.Title = t.RequisiteTitle
			--join @reqtypes r on r.Id = rt.Id
			where t.Parent_Id is null 
			group by courseid, t.SortOrder''

	declare @defaultText nvarchar(max) --= ''Prerequisite: None.''
	--the query groups by RequisiteType
	declare @requisiteType nvarchar(max) = ''''''req''''''


	declare @reqtypes integers;
		insert into @reqtypes
		values (1), (2), (3), (5);

		declare @modelRoot integers;

		insert into @modelRoot
		--select [Key]
		--from @entityModels;
		--values (904), (6182), (5442), (3050), (9967), (6540), (3659),(10053),(10196)
		select Id from Course where StatusAliasId = 1 --and Id = 5024;

create table #temp (CRId int, CourseId int, RequisiteTitle nvarchar(max), Parent_Id int, RequisiteText nvarchar(max), SortOrder int);
declare @results table (CourseId int, RequisiteText nvarchar(max));

declare @sql nvarchar(max) = ''select  cr.Id as CRId, cr.CourseId, '' + @requisiteType + '' as RequisiteTitle, Parent_Id,'' + @requisiteselect + '' as RequisiteText, cr.SortOrder
	from CourseRequisite cr 
	join @modelRoot mr on mr.Id = cr.CourseId
	join ListItemType lit on lit.Id = cr.ListItemTypeId
	left join RequisiteType rt on rt.Id = cr.RequisiteTypeId
    left join minimumGrade mg on cr.MinimumGradeId = mg.Id
	left join Course c 
		join Subject s on s.Id = c.SubjectId
		on c.Id = cr.Requisite_CourseId
	where ListItemTypeOrdinal in (1,3)''


insert into #temp
exec sp_executesql @sql
	, N''@modelRoot integers readonly''
	, @modelRoot
;


declare @rows int = 0;

while @rows <> (select count(*) from #temp)
begin

set @rows = (select count(*) from #temp);

merge into #temp t
using (
	select cr.Id as CRId, cr.CourseId, t.RequisiteTitle as RequisiteTitle, cr.Parent_Id, 
		case when cr.Parent_Id is not null then
			concat(@groupstart,dbo.ConcatWithSepOrdered_Agg(space(1) + gc.Title + space(1),t.SortOrder,t.RequisiteText),@groupend)
		else 
			dbo.ConcatWithSepOrdered_Agg(space(1) + gc.Title + space(1),t.SortOrder,t.RequisiteText)
		end
		 as RequisiteText, 
		cr.SortOrder
	from CourseRequisite cr 
	join @modelRoot mr on mr.Id = cr.CourseId
	join GroupCondition gc on gc.Id = cr.GroupConditionId
	join #temp t on t.Parent_Id = cr.Id
	group by cr.CourseId, cr.Id, cr.Parent_Id, t.RequisiteTitle, cr.SortOrder) s
on t.CRId = s.CRId and (t.RequisiteTitle = s.RequisiteTitle or (t.RequisiteTitle is null and s.RequisiteTitle is null))
when matched AND t.RequisiteText <> s.RequisiteText then update set RequisiteText = s.RequisiteText
when not matched then insert (CRId, CourseId, RequisiteTitle, Parent_Id, RequisiteText, SortOrder)
values (s.CRId, s.CourseId, s.RequisiteTitle, s.Parent_Id, s.RequisiteText, s.SortOrder);

end

set @sql =
''select CourseId, dbo.ConcatWithSepOrdered_Agg('''' '''',a.SortOrder,RequisiteText)
from ('' + @requisiteGrouping + '') a
group by CourseId;''


insert into @results
exec sp_executesql @sql
	, N''@modelRoot integers readonly,@reqtypes integers readonly''
	, @modelRoot, @reqtypes
;

DECLARE @TABLE2 TABLE (Value int, Text nvarchar(max))
INSERT INTO @TABLE2
select mr.Id as [Value]
	, case
		when RequisiteText is not null
			then replace(replace(rs.RequisiteText,char(13),''''),char(10),'''')
		else @defaultText
	end [Text]
from @modelRoot mr 
left join @results rs on rs.CourseId = mr.Id;



DECLARE @TABLE TABLE (numb NVARCHAR(MAX), CCC NVARCHAR(MAX), id int)
INSERT INTO @TABLE
SELECT 
	CONCAT(s.SubjectCode,'' '', c.CourseNumber) as [Course Subject & Number],
	cb.CB00 AS [CCC Control Number],
	c.Id as id
FROM Course AS C
	INNER JOIN StatusAlias AS sa ON c.StatusAliasId = sa.Id
	LEFT JOIN CourseCBCode AS cb ON cb.CourseId = c.Id
	LEFT JOIN CB03 AS cb3 ON cb.CB03Id = cb3.Id
	LEFT JOIN Subject AS s ON c.SubjectId = s.Id
WHERE c.Active = 1
AND sa.Id = 1;

SELECT 
	t.numb AS [Course Subject & Number],
	t.CCC AS [CCC Control Number],
	t2.Text
 AS [Requisite]
	FROM @TABLE As T
	LEFT JOIN @TABLE2 AS t2 on t2.Value = t.id
	order by t.numb


drop table #temp
'
WHERE Id = 24