USE [Hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18691';
DECLARE @Comments nvarchar(Max) = 
	'Fix Program Reports from breaking';
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
DECLARE @SQL NVARCHAR(MAX);

	set quoted_identifier off;
	set @sql = ("
DECLARE @CoursesByComponent TABLE (
	Id INT IDENTITY(1,1),
	ComponentId INT, 
	ComponentTitle NVARCHAR(MAX), 
	SemesterId INT, 
	SemesterTitle NVARCHAR(MAX), 
	CourseId INT,
	CourseTitle NVARCHAR(MAX) 
	--AcademyCredit DECIMAL(10,3), 
	--Duration INT
) 

--select*from @CoursesByComponent

INSERT INTO @CoursesByComponent 
(ComponentTitle,SemesterTitle,  CourseId, CourseTitle)
SELECT 
	PS2.GroupTitle AS ComponentTitle,
	PS3.GroupTitle AS SemesterTitle,
	C.Id AS CourseId,
	C.Title AS CourseTitle
FROM ProgramSequence PS
	INNER JOIN Course C
		ON C.Id = PS.CourseId
	INNER JOIN CourseDetail CD	
		ON CD.CourseId = C.Id
	LEFT JOIN ProgramSequence PS2
		inner join ProgramSequence PS3
			ON PS2.Parent_Id = PS3.id
		ON PS.Parent_Id = PS2.id
WHERE  PS.ProgramId = @entityId

--select*from @CoursesByComponent

update CBC
set Componentid = A.sortorder
from @CoursesByComponent CBC
	inner join (
		select ROW_NUMBER() over (Order by S.sortorder) as sortorder,CBC2.ComponentTitle
		from @CoursesByComponent CBC2
			cross apply (select top 1 sortorder from ProgramSequence PS 
				where PS.grouptitle = CBC2.ComponentTitle
					and PS.ProgramId = @entityId) S
		group by CBC2.ComponentTitle,S.sortorder
	) A on CBC.ComponentTitle = A.ComponentTitle

update CBC
set Semesterid = A.sortorder
from @CoursesByComponent CBC
	inner join (
		select ROW_NUMBER() over (Order by S.sortorder) as sortorder,CBC2.SemesterTitle
		from @CoursesByComponent CBC2
			cross apply (select top 1 sortorder from ProgramSequence PS 
				where PS.grouptitle = CBC2.SemesterTitle
					and PS.ProgramId = @entityId) S
		group by CBC2.SemesterTitle,S.sortorder
	) A on CBC.SemesterTitle = A.SemesterTitle

--select*from @CoursesByComponent

--declare @style nvarchar(max) = 
--'<style type=""text/css"">
--.tg .tg-r3ow {
--    border-color: inherit;
--    text-align: right;
--    vertical-align: top;
--}
--.tg .Textblue {
--    color: #0471c9;
--}
--</style>'
DECLARE @AHead NVARCHAR(MAX) = (SELECT CONCAT('<br><br><p>4.2	The latest version of the Course Offering Structure is shown in Tables 4.1-4.2.</p><b style=""font-size:16px"">Table 4.2 Course Offering Structure of the ', Title, ' Programme</b>') FROM Program WHERE Id = @entityId)

DECLARE @tHead nvarchar(max) = 
(select concat(
'
<table class=""tg"">
  <tr>
    <td class=""tg-c3ow blue"">Course Type</td>'
	, string_Agg('<td class=""tg-c3ow"">' + SemesterTitle+ '</td>', CHAR(13)) within group (order by SemesterId),'
  </tr>',CHAR(13))
from (select distinct CBC.SemesterTitle,SemesterId
from @CoursesByComponent CBC
) A )

DECLARE @tBody nvarchar(max) =
(select 
string_Agg(concat(
	'<tr>'
		,CHAR(13)
		,'<td class=""tg-0lax Textblue"">', ComponentTitle, '</td>'
		,CHAR(13)
		,txt
		,CHAR(13)
	,'</tr>'
	,CHAR(13)
	), '') within group (order by ComponentId)
from
(select ComponentId,ComponentTitle,string_Agg(concat('<td class=""tg-c3ow"">', Num, '</td>'), CHAR(13)) within group (order by SemesterId) as txt
from 
(select AB.ComponentId,AB.ComponentTitle,AB.SemesterId,AB.SemesterTitle,isnull(C.Num,'&nbsp') as Num
from (
select ComponentId,ComponentTitle,SemesterId,SemesterTitle
from (
select distinct ComponentId,ComponentTitle
from @CoursesByComponent) A
inner join (
select distinct SemesterId,SemesterTitle
from @CoursesByComponent) B on 1 = 1) AB
left join (
select CBC.ComponentId,CBC.ComponentTitle,CBC.SemesterId,CBC.SemesterTitle,cast(count(id) as NVARCHAR(100)) as Num
from @CoursesByComponent CBC
group by CBC.ComponentId,CBC.ComponentTitle,CBC.SemesterId,CBC.SemesterTitle) C on AB.ComponentId = C.ComponentId 
	and AB.SemesterId = C.SemesterId) D
Group by ComponentId,ComponentTitle) E)

----select CMS.ComponentId,CMS.ComponentTitle,Count(CMS.id) as CourseNum,SUM(CMS.AcademyCredit) as CreditSum,case when @TotalAcademyCredits <> 0 then SUM(CMS.AcademyCredit) / @TotalAcademyCredits else 0 end as Precent
----from @CoursesByMajorSpecialisation CMS
----group by CMS.ComponentId,CMS.ComponentTitle
----order by CMS.ComponentId 

DECLARE @tTotal nvarchar(max) = 
(select concat(
	'<tr>'
		, '<td class=""tg-r3ow"">Total by Semester</td>'
		, char(13)
		, string_Agg(concat('<td class=""tg-c3ow"">', NUM, '</td>'), char(13)) within group (order by SemesterId),
	'</tr>
</table>')
from (select SemesterId,COUNT(id) as NUM
from @CoursesByComponent CBC
group by CBC.SemesterId) A)

SELECT 0 AS Value, CONCAT(@AHead,@tHead,@tBody,@tTotal) AS Text
	");
	set quoted_identifier on;

	update MetaForeignKeyCriteriaClient
	set CustomSql = @sql
		, ResolutionSql = @sql
	where Id = 238;

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MEtaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 238
)