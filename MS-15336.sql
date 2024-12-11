USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15336';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog View Query';
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
declare @requisitestabs table (id int,Parents int)

;with Parents
as (select id,Parent_Id FROM CourseRequisite WHERE courseid = @entityId
	union ALL
	select P.id,CR.Parent_Id
	from Parents P
		inner join CourseRequisite CR on P.Parent_Id = CR.id
)
insert into @requisitestabs
select ID,Count(Parent_Id)
from Parents
group by ID


declare @requisites table (
Id int identity(1,1),
RequisteTypeTitle nvarchar(max),
SubjectCode nvarchar(max),
CourseNumber nvarchar(max),
RequisiteComment nvarchar(max),
NonCourseRequirement nvarchar(max),
MinimumGrade nvarchar(max),
Condition nvarchar(max),
ProgramPlan nvarchar(max),
grouptitle nvarchar(max),
listitemtypeid int,
Parents int,
EligibilityCriteria nvarchar(max),
Parent_Id int
)

INSERT INTO @requisites
(RequisteTypeTitle, SubjectCode, CourseNumber, RequisiteComment, NonCourseRequirement, MinimumGrade, Condition, ProgramPlan,grouptitle,listitemtypeid, Parents,EligibilityCriteria,Parent_Id)
SELECT
	rt.Title
    ,s.SubjectCode
    ,cc.CourseNumber
    ,cr.EntrySkill
    ,cr.CourseRequisiteComment
    ,concat(case
		when rt.id In (1,2,3)
		then ''with a Grade of "C" or better, or equivalent''
		Else NULL
	End,
	'' or Milestone '' + CCt.txt)
    ,c.Title
    ,p.Title
	,CR.Text25501 as grouptitle
	, CR.listitemtypeid
	, RTab.Parents
	, Coalesce(EC.Code + '' '' + EC.Title,EC.Title) as EligibilityCriteria
	, CR.Parent_Id as Parent_Id
FROM CourseRequisite cr
	LEFT JOIN RequisiteType rt ON rt.id = cr.RequisiteTypeId
	Left join CourseRequisite cr2 on CR.Parent_Id = CR2.Id
	outer apply(select top 1 ICR.id as id from CourseRequisite ICR where coalesce(CR.Parent_Id,0) = coalesce(Parent_Id,0) and CR.courseid = courseid Order by ICR.SortOrder,id) cr3
	LEFT JOIN Condition c ON (c.id = cr2.GroupConditionId or (Cr2.id is null and C.id = 1)) and CR.id <> CR3.id
	LEFT JOIN Subject s ON s.id = cr.SubjectId
	LEFT JOIN course cc ON cc.Id = cr.Requisite_CourseId
	LEFT JOIN Program p ON p.id = cr.Requisite_ProgramId
	inner join @requisitestabs RTab on CR.id = RTab.id
	LEFT JOIN EligibilityCriteria EC on CR.EligibilityCriteriaId = EC.id
	outer apply (select dbo.ConcatWithSepOrdered_Agg(''/'',Ct.SortOrder,isnull(Ct.Code, '''') + isnull('' - '' + Ct.Title,'''')) as txt
	from CourseCohort CCt
		inner join [Cohort] Ct on Cct.cohortid = Ct.id
	where CC.id = courseid) CCt
WHERE cr.courseid = @entityId
ORDER BY Cr.SortOrder

declare @final nvarchar(max)

SELECT
	@final = COALESCE(@final, '''') +
	case when R.listitemtypeid = 30 and (R.Grouptitle is not null or R.Condition is not null) then 
	CONCAT(REPLICATE(''&emsp;'', R.Parents) + R.Condition + ''<br>''
	,REPLICATE(''&emsp;'', R.Parents)
	,''<b>'' + R.Grouptitle + ''</b> '' + ''<br>''
	)
	when R.listitemtypeid <> 30 and coalesce(R.RequisteTypeTitle,''NULL'') <> coalesce(R2.RequisteTypeTitle,''NULL'') then
	CONCAT(REPLICATE(''&emsp;'', R.Parents) + R.Condition + ''<br>''
	,REPLICATE(''&emsp;'', R.Parents)
	,''<b>'' + R.RequisteTypeTitle + ''</b> ''
	, R.SubjectCode + '' ''
	, R.CourseNumber + '' ''
	, R.NonCourseRequirement + '' ''
    , R.RequisiteComment + '' ''
	, R.ProgramPlan + '' ''
	, R.MinimumGrade + '' ''
	, R.EligibilityCriteria + '' ''
	, ''<br>''
	)
	when R.listitemtypeid <> 30 and coalesce(R.RequisteTypeTitle,''NULL'') = coalesce(R2.RequisteTypeTitle,''NULL'') then
	CONCAT(REPLICATE(''&emsp;'', R.Parents) + R.Condition + ''<br>''
	,REPLICATE(''&emsp;'', R.Parents)
	, R.SubjectCode + '' ''
	, R.CourseNumber + '' ''
	, R.NonCourseRequirement + '' ''
    , R.RequisiteComment + '' ''
	, R.ProgramPlan + '' ''
	, R.MinimumGrade + '' ''
	, R.EligibilityCriteria + '' ''
	, ''<br>''
	)
	else ''''
	end
FROM @requisites r
	left join @requisites r2 on R.id = R2.id + 1 and coalesce(R.Parent_Id,0) = coalesce(R2.Parent_Id,0)

SELECT
	0 AS Value
   ,Coalesce(
	 CASE 
		WHEN LEN(@final) > 5 
		THEN LEFT(@final, LEN(@final) - 5)  + ''.''
	 ELSE ''''
	 END,''None.'')
	 AS Text
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 1

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = NULL
, IsRequired = 1
WHERE MetaAvailableFieldId = 3427

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 1
	or msf.MetaAvailableFieldId = 3427
)