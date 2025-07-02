USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18704';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Detial query Text on the Program form';
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
DECLARE @now int = (SELECT ISNULL(CourseId, -1) FROM ProgramSequence WHERE Id = @pkIdValue)

declare @results table (Value int, Text varchar(max), FilterValue int);
declare @br NVARCHAR(5) = ''<br>''

declare @courseid int;

declare courses cursor fast_forward for
	select distinct CourseId
	from ProgramSequence
	where ProgramId = @entityId

	open courses;



	fetch next from courses
	into @courseid;

	while @@fetch_status = 0
	begin;

    declare @courseInfo table
    (
        CourseCode NVARCHAR(max),
        Title NVARCHAR(max),
        CHMin decimal(16,1),
        CHMax DECIMAL(16,1),
        SWHMin DECIMAL(16,1),
        SWHMax decimal(16,1),
        RatioMin decimal(16,1),
        RatioMax decimal(16,1),
        Cat NVARCHAR(100),
        AcademyCreditMin DECIMAL(16,1),
        AcademyCreditMax DECIMAL(16,1),
        QFLevel NVARCHAR(100),
		CourseType NVARCHAR(max)
    )

declare @rubrics NVARCHAR(max) = (
    select distinct dbo.ConcatWithSep_Agg(''<br>'',m.Title)
    from CourseEvaluationMethod cem
        inner join Module m on m.Id = cem.Related_ModuleId
    where CourseId = @courseid
)

insert into @courseInfo
(CourseCode,Title,CHMin,CHMax,SWHMin,SWHMax,RatioMin,RatioMax,Cat,AcademyCreditMin,AcademyCreditMax,QFLevel,CourseType)
select
    CourseNumber
    ,c.Title
    ,COALESCE(cd.MinLectureHour, MinimumLHEHours)
    ,COALESCE(cd.MaxLectureHour, MaximumLHEHours)
    ,COALESCE(cd.MinContHour, MinimumArrangeHours)
    ,COALESCE(cd.MaxContHour, MaximumArrangeHours)
    ,cd.MinFieldHour
    ,cd.MaxFieldHour
    ,rt.Title
    ,cd.MinCreditHour
    ,cd.MaxCreditHour
    ,qf.Title
	,CT.Title as CourseType
from Course c
    inner join CourseAttribute ca on ca.CourseId = c.Id
		and (ca.DesignationId = 1 or ca.DesignationId IS NULL)
    inner join CourseDescription cd on cd.CourseId = c.Id
    inner join CourseProposal cp on cp.CourseId = c.Id
	left join CreditType CT on CP.CreditTypeId = CT.id
    left join RevisionType rt on rt.id = cp.RevisionTypeId
    left join QFLevel qf on qf.Id = ca.QFLevelId
where c.Id = @courseId
union
select
    CourseNumber
    ,c.Title
    ,cd.MinLectureHour/2
    ,cd.MaxLectureHour/2
    ,cd.MinContHour/2
    ,cd.MaxContHour/2
    ,cd.MinFieldHour/2
    ,cd.MaxFieldHour/2
    ,rt.Title
    ,cd.MinCreditHour/2
    ,cd.MaxCreditHour/2
    ,qf.Title
	,CT.Title as CourseType
from Course c
    inner join CourseAttribute ca on ca.CourseId = c.Id
		and ca.DesignationId = 2
    inner join CourseDescription cd on cd.CourseId = c.Id
    inner join CourseProposal cp on cp.CourseId = c.Id
	left join CreditType CT on CP.CreditTypeId = CT.id
    left join RevisionType rt on rt.id = cp.RevisionTypeId
    left join QFLevel qf on qf.Id = ca.QFLevelId
where c.Id = @courseId

-- 1 fixed, 2 range, select * from districtcoursetype
declare @creditType int = (select DistrictCourseTypeId from CourseAttribute where CourseId = @courseId)

declare @info NVARCHAR(max)

if @creditType = 2
begin
	set @info = (
		select concat(
			''Course type: '',CourseType,@br,
			''Course Code: '',CourseCode,@br,
			''Course Title: '',Title,@br,
			''CH Min: '',CHMin,@br,
			''CH Max: '',CHMax,@br,
			''SWH Min: '',SWHMin,@br,
			''SWH Max: '',SWHMax,@br,
			''CWH-SWH Ratio Min: '',RatioMin,@br,
			''CWH-SWH Ratio Max: '',RatioMax,@br,
			''CAT: '',Cat,@br,
			''Academy Credit Min: '',AcademyCreditMin,@br,
			''Academy Credit Max: '',AcademyCreditMax,@br,
			''QF Level: '',QFLevel,@br
		) from @courseInfo
	)
end
else
begin
	set @info = (
		select concat(
			''<b>Course type: </b>'',CourseType,@br,
			''<b>Course Code: </b>'',CourseCode,@br,
			''<b>Course Title: </b>'',Title,@br,
			''<b>CH: </b>'',CHMin,@br,
			''<b>SWH: </b>'',SWHMin,@br,
			''<b>CWH-SWH Ratio: </b>'',RatioMin,@br,
			''<b>CAT: </b>'',Cat,@br,
			''<b>Academy Credit: </b>'',AcademyCreditMin,@br,
			''<b>QF Level: </b>'',QFLevel,@br
		) from @courseInfo
	)
end

    declare @requisiteTable table
    (
        SortOrder int,
        Title nvarchar(max)
    );

    INSERT INTO @requisiteTable
    (SortOrder, Title)
        SELECT
            cr.SortOrder
        ,concat(''<li class="list-group-item-compact"><strong>'',rt.Title,'':</strong> '',s.SubjectCode,space(1),rc.CourseNumber,space(1),con.Title,''</li>'') AS Title
        FROM Course c
            INNER JOIN CourseRequisite cr ON cr.CourseId = c.Id
            INNER JOIN Course rc ON cr.Requisite_CourseId = rc.Id
            INNER JOIN Subject s ON rc.SubjectId = s.Id
            left JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
            left join Condition con on con.id = cr.ConditionId
        WHERE c.Id = @courseid
        ORDER BY cr.SortOrder
        
    declare @requisites nvarchar(max) = (
        SELECT
            CONCAT(
            dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold py-1'')),
            ''<b>Requisites & Advisories</b>'',
            dbo.fnHtmlCloseTag(''label''),
            dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2'')),
            cli.CombinedRequisites,
            dbo.fnHtmlCloseTag(''ol'')
            ) AS Text
        FROM (
            SELECT
                dbo.ConcatWithSepOrdered_Agg(NULL, SortOrder, Title) AS CombinedRequisites
            FROM @requisiteTable rt
        ) cli
    );
insert into @results (Value,Text,FilterValue)
SELECT
    0 as Value
    , CONCAT(
        dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''pl-2 pr-2 pb-2 pt-0'')),
        @requisites,
        dbo.fnHtmlCloseTag(''div''),
        dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''pl-2 pr-2 pb-2 pt-0'')),
        dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold py-1'')),
            ''<b>Course Info</b>'',
        dbo.fnHtmlCloseTag(''label''),
        dbo.fnHtmlOpenTag(''div'',dbo.fnHtmlAttribute(''class'', ''pl-2 pr-2 pb-2 pt-0'')),
        @info,
        dbo.fnHtmlCloseTag(''div''),
        dbo.fnHtmlOpenTag(''div'',dbo.fnHtmlAttribute(''class'', ''pl-2 pr-2 pb-2 pt-0'')),
        ''<b>Rubrics: </b><br>'',
        @rubrics,
        dbo.fnHtmlCloseTag(''div''),
        dbo.fnHtmlCloseTag(''div'')
        ) AS Text
    ,CASE WHEN @courseId IS NULL
		THEN 0 
		ELSE @courseid END as FilterValue
		WHERE @courseId = @now

    delete from @requisiteTable;
    delete from @courseInfo

    fetch next from courses
    into @courseid;
end;

close courses;

deallocate courses;

select * from @results
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 276

SET @SQL = '
DEclare @PSCalculations table 
(
	psID int, 
	CHMin decimal(16,1),
    CHMax decimal(16,1),
    SWHMin decimal(16,1),
    SWHMax decimal(16,1),
    NLHMin decimal(16,1),
    NLHMax decimal(16,1),
    RatioMin decimal(16,1),
    RatioMax decimal(16,1),
    CAT NVARCHAR(100),
    Mincredit decimal(16,1),
    Maxcredit decimal(16,1),
    QFLevel NVARCHAR(100)
)

Insert into @PSCalculations
select 
	PS.Id,
    case
		when ca.DesignationId = 2 then  cd.MinLectureHour/2
		when cd.MinimumLHEHours IS NOT NULL THEN cd.MinimumLHEHours
		else cd.MinLectureHour
	end as CHMin
    ,case
		when ca.DesignationId = 2 then  coalesce(cd.MaxLectureHour,cd.MinLectureHour)/2
		when cd.MaximumLHEHours IS NOT NULL THEN cd.MaximumLHEHours
		else coalesce(cd.MaxLectureHour,cd.MinLectureHour)
	end as CHMax
    ,case
		when ca.DesignationId = 2 then  cd.MinContHour/2
		when cd.MinimumArrangeHours IS NOT NULL THEN cd.MinimumArrangeHours
		else cd.MinContHour
	end as SWHMin
    ,case
		when ca.DesignationId = 2 then  coalesce(cd.MaxContHour,cd.MinContHour)/2
		when cd.MaximumArrangeHours IS NOT NULL THEN cd.MaximumArrangeHours
		else coalesce(cd.MaxContHour,cd.MinContHour)
	end as SWHMax
    ,case
		when ca.DesignationId = 2 then  cd.MinLabHour/2
		when cd.MaxClinicalHour IS NOT NULL THEN cd.MaxClinicalHour
		else cd.MinLabHour
	end as NLHMin
    ,case
		when ca.DesignationId = 2 then  coalesce(cd.MaxLabHour,cd.MinLabHour) /2
		else coalesce(cd.MaxLabHour,cd.MinLabHour)
	end as NLHMax
    ,cd.MinFieldHour as RatioMin
    ,case
		when ca.DesignationId = 2 then  coalesce(cd.MaxFieldHour,cd.MinFieldHour)/2
		else coalesce(cd.MaxFieldHour,cd.MinFieldHour)
	end as RatioMax
    ,rt.Title as CAT  
    ,case
		when ca.DesignationId = 2 then  cd.MinCreditHour/2
		else cd.MinCreditHour
	end as Mincredit
    ,case
		when ca.DesignationId = 2 then  coalesce(cd.MaxCreditHour,cd.MinCreditHour)/2
		else coalesce(cd.MaxCreditHour,cd.MinCreditHour)
	end as Maxcredit
    ,qf.Title as QFLevel
 from ProgramSequence PS
	left join ProgramSequence child on PS.Id = child.Parent_Id
    left join course c on c.id = PS.CourseId
    left join CourseAttribute ca on ca.CourseId = c.Id
    lEFT join CourseDescription cd on cd.CourseId = c.Id
    left join CourseProposal cp on cp.CourseId = c.Id
    left join RevisionType rt on rt.id = cp.RevisionTypeId
    left join QFLevel qf on qf.Id = ca.QFLevelId
where PS.ProgramId = @entityId
	and  child.Id is null

Declare @GotAll bit = 
case 
	when Exists (select * FROM ProgramSequence ps left join @PSCalculations c on ps.Id =c.psID where c.psID is Null and PS.ProgramId = @entityId) then 0
	Else 1
End

While (@GotAll = 0)
Begin
	Insert into @PSCalculations
	select 
		PS.Id,
		case
			when ps.GroupConditionId IS null or ps.GroupConditionId = 1 then sum(c.CHMin)
			When ps.GroupConditionId = 2 then MIN(c.CHMin)
			Else MIN(c.CHMin) -- This is not the best solution if the group condition is 3 but I dont have time to do this correctly for everything
		end as CHMin
		,case
			when ps.GroupConditionId IS null or ps.GroupConditionId = 1 then sum(c.CHMax)
			When ps.GroupConditionId = 2 then Max(c.CHMax)
			Else Max(c.CHMax) -- This is not the best solution if the group condition is 3 but I dont have time to do this correctly for everything
		end as CHMax
		,case
			when ps.GroupConditionId IS null or ps.GroupConditionId = 1 then sum(c.SWHMin)
			When ps.GroupConditionId = 2 then MIN(c.SWHMin)
			Else MIN(c.SWHMin) -- This is not the best solution if the group condition is 3 but I dont have time to do this correctly for everything
		end as SWHMin
		,case
			when ps.GroupConditionId IS null or ps.GroupConditionId = 1 then sum(c.SWHMax)
			When ps.GroupConditionId = 2 then max(c.SWHMax)
			Else max(c.SWHMax) -- This is not the best solution if the group condition is 3 but I dont have time to do this correctly for everything
		end as SWHMax
		,case
			when ps.GroupConditionId IS null or ps.GroupConditionId = 1 then sum(c.NLHMin)
			When ps.GroupConditionId = 2 then min(c.NLHMin)
			Else min(c.NLHMin) -- This is not the best solution if the group condition is 3 but I dont have time to do this correctly for everything
		end as NLHMin
		,case
			when ps.GroupConditionId IS null or ps.GroupConditionId = 1 then sum(c.NLHMax)
			When ps.GroupConditionId = 2 then max(c.NLHMax)
			Else max(c.NLHMax) -- This is not the best solution if the group condition is 3 but I dont have time to do this correctly for everything
		end as NLHMax
		,case
			when ps.GroupConditionId IS null or ps.GroupConditionId = 1 then sum(c.RatioMin)
			When ps.GroupConditionId = 2 then min(c.RatioMin)
			Else min(c.RatioMin) -- This is not the best solution if the group condition is 3 but I dont have time to do this correctly for everything
		end as RatioMin
		,case
			when ps.GroupConditionId IS null or ps.GroupConditionId = 1 then sum(c.RatioMax)
			When ps.GroupConditionId = 2 then max(c.RatioMax)
			Else max(c.RatioMax) -- This is not the best solution if the group condition is 3 but I dont have time to do this correctly for everything
		end as RatioMax
		,MAX(c.cat) as CAT  -- This is not the best solution
		,case
			when ps.GroupConditionId IS null or ps.GroupConditionId = 1 then sum(c.Mincredit)
			When ps.GroupConditionId = 2 then min(c.Mincredit)
			Else min(c.Mincredit) -- This is not the best solution if the group condition is 3 but I dont have time to do this correctly for everything
		end as Mincredit
		,case
			when ps.GroupConditionId IS null or ps.GroupConditionId = 1 then sum(c.Maxcredit)
			When ps.GroupConditionId = 2 then max(c.Maxcredit)
			Else max(c.Maxcredit) -- This is not the best solution if the group condition is 3 but I dont have time to do this correctly for everything
		end as Maxcredit
		,MAX(c.QfLevel) as QFLevel -- This is not the best solution
	from ProgramSequence PS
		left join ProgramSequence child on PS.Id = child.Parent_Id
		left join @PSCalculations c on child.Id = c.psID
	WHERE PS.ProgramId = @entityId
		and ps.ListItemTypeId = 8
		and PS.Id not in (select c2.psID from @PSCalculations c2)
	 and Not Exists (
		SELECT * FROM ProgramSequence ps2
		where ps2.Parent_Id = PS.Id
			and ps2.Id not IN (select c2.psID from @PSCalculations c2)
	)
	group by PS.Id, PS.GroupConditionId

	set @GotAll = 
	case 
		when Exists (select * FROM ProgramSequence ps left join @PSCalculations c on ps.Id =c.psID where c.psID is Null and PS.ProgramId = @entityId) then 0
		Else 1
	End
End

declare @style NVARCHAR(max) = ''<style type="text/css">
.tg  {border border-dark-collapse:collapse;border border-dark-spacing:0;}
.tg td{border border-dark-color:black;border border-dark-style:solid;border border-dark-width:1px;font-family:Arial, sans-serif;font-size:14px;
  overflow:hidden;padding:10px 5px;word-break:normal;}
.tg th{border border-dark-color:black;border border-dark-style:solid;border border-dark-width:1px;font-family:Arial, sans-serif;font-size:14px;
  font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
@media screen and (max-width: 767px) {.tg {width: auto !important;}.tg col {width: auto !important;}.tg-wrap {overflow-x: auto;-webkit-overflow-scrolling: touch;}}</style>''

declare @tableStart NVARCHAR(max) = ''<div class="tg-wrap"><table class="tg" width="100%">''

declare @tableEnd NVARCHAR(max) = ''</tbody>
</table></div>''


declare @br NVARCHAR(5) = ''<br>''
declare @sep NVARCHAR(5) = '' - ''

declare @tableMiddle NVARCHAR(max) = ''<tbody>
  <tr>
    <td class="tg-c3ow">Course Code</td>
    <td class="tg-c3ow">Course Title</td>
    <td class="tg-0lax">CH (A)</td>
    <td class="tg-0lax">SWH (B)</td>
    <td class="tg-0lax">NLH = (A) + (B)</td>
    <td class="tg-0lax">CH-SWH Ratio</td>
    <td class="tg-0lax">CAT</td>
    <td class="tg-0lax">Academy Credits</td>
    <td class="tg-0lax">QF Level</td>
  </tr>
''

;with Groups As (
	Select
		ps.Id,
		ps.GroupTitle as title,
		ps.SortOrder ,
		parent.Id as parent,
		parent.Id as major
	FROM ProgramSequence ps
		Inner join ProgramSequence parent on ps.Parent_Id = parent.Id
	Where parent.Parent_Id is null
		and ps.ListItemTypeId = 8
		and ps.ProgramId = @entityID
),
subgroups as (
	Select
		ps.Id,
		ps.SortOrder ,
		FORMAT(ps.SortOrder, ''00000'') as sortstring,
		ps.Parent_Id,
		ps.Id as topSubgroup
	FROM ProgramSequence ps
	Where ps.Parent_Id in (select Id from Groups) 
		and ps.ListItemTypeId = 8
		and ps.ProgramId = @entityID
	Union all
	Select
		ps.Id,
		ps.SortOrder ,
		concat(sg.sortstring, ''-'', FORMAT(ps.SortOrder, ''00000'')) as sortstring,
		ps.Parent_Id,
		sg.topSubgroup
	FROM ProgramSequence ps
		inner join subgroups sg on ps.Parent_Id = sg.Id
),
subgrouptext as (
	Select
		ps.Id,
		CONCAT(
			case when sg.Id <> sg.topSubgroup then ''<li>'' END,
			Coalesce(GroupTitle,OtherRequirementTitle,concat(c.CourseNumber, '' - '', c.title), c.entityTitle),
			Case
				WHen Exists (select 1 from ProgramSequence ps2 where ps.id = ps2.Parent_Id) then ''<ul>''
				when sg.Id <> sg.topSubgroup then ''</li>''
			End,
			Case
				WHen not Exists (select 1 from ProgramSequence ps2 where ps.Parent_Id = ps2.Parent_Id and ps.SortOrder < ps2.SortOrder ) then 
					Case
						when ps.Parent_Id = sg.topSubgroup then ''</ul>''
						else''</ul></li>''
					End
			End
		) as text,
		sg.SortOrder ,
		ROW_NUMBER() over (order by sg.sortstring) as sortstring
	FROM ProgramSequence ps
		inner join subgroups sg on ps.Id = sg.Id
		left join Course c on ps.CourseId = c.Id
)
,subgroupsOutput  as (
	SELECT
		tsg.Id,
		tsg.Parent_Id,
		tsg.SortOrder,
		dbo.ConcatOrdered_Agg(sgt.sortstring,sgt.text, 1) as output
	FROM subgroups tsg
		left Join subgroups sg on tsg.Id = sg.topSubgroup 
		left join subgrouptext sgt on sg.Id = sgt.Id
	WHERE tsg.id = tsg.topSubgroup
	Group by tsg.Id,tsg.Parent_Id,tsg.SortOrder
),
courseInfo as
(select distinct
    c.CourseNumber as CourseCode
    ,c.Title as Title
    ,case
		when ca.DesignationId = 2 then  cd.MinLectureHour/2
		WHEN cd.MinimumLHEHours IS NOT NULL THEN cd.MinimumLHEHours
		else cd.MinLectureHour
	end as CHMin
    ,case
		when ca.DesignationId = 2 then  coalesce(cd.MaxLectureHour,cd.MinLectureHour)/2
		WHEN cd.MaximumLHEHours IS NOT NULL THEN cd.MaximumLHEHours
		else coalesce(cd.MaxLectureHour,cd.MinLectureHour)
	end as CHMax
    ,case
		when ca.DesignationId = 2 then  cd.MinContHour/2
		WHEN cd.MinimumArrangeHours IS NOT NULL THEN cd.MinimumArrangeHours
		else cd.MinContHour
	end as SWHMin
    ,case
		when ca.DesignationId = 2 then  coalesce(cd.MaxContHour,cd.MinContHour)/2
		WHEN cd.MaximumArrangeHours IS NOT NULL THEN cd.MaximumArrangeHours
		else coalesce(cd.MaxContHour,cd.MinContHour)
	end as SWHMax
    ,case
		when ca.DesignationId = 2 then  cd.MinLabHour/2
		when cd.MaxClinicalHour IS NOT NULL THEN cd.MaxClinicalHour
		else cd.MinLabHour
	end as NLHMin
    ,case
		when ca.DesignationId = 2 then  coalesce(cd.MaxLabHour,cd.MinLabHour) /2
		else coalesce(cd.MaxLabHour,cd.MinLabHour)
	end as NLHMax
    ,cd.MinFieldHour as RatioMin
    ,case
		when ca.DesignationId = 2 then  coalesce(cd.MaxFieldHour,cd.MinFieldHour)/2
		else coalesce(cd.MaxFieldHour,cd.MinFieldHour)
	end as RatioMax
    ,rt.Title as CAT  
    ,case
		when ca.DesignationId = 2 then  cd.MinCreditHour/2
		else cd.MinCreditHour
	end as Mincredit
    ,case
		when ca.DesignationId = 2 then  coalesce(cd.MaxCreditHour,cd.MinCreditHour)/2
		else coalesce(cd.MaxCreditHour,cd.MinCreditHour)
	end as Maxcredit
    ,qf.Title as QFLevel
	,PS.SortOrder as SortOrder,
	PS.Parent_Id,
	PS.Id,
	1 as iscourse
 from ProgramSequence PS
    inner join course c on c.id = PS.CourseId
    inner join CourseAttribute ca on ca.CourseId = c.Id
    inner join CourseDescription cd on cd.CourseId = c.Id
    inner join CourseProposal cp on cp.CourseId = c.Id
    left join RevisionType rt on rt.id = cp.RevisionTypeId
    left join QFLevel qf on qf.Id = ca.QFLevelId
where PS.ProgramId = @entityId
	and Parent_Id in (select Id from Groups)
Union
	select distinct
	    '''' as CourseCode
	    ,sgo.output as Title
	    ,c.CHMin as CHMin
	    ,c.CHMax as CHMax
	    ,c.SWHMin as SWHMin
	    ,c.SWHMax as SWHMax
	    ,c.NLHMin as NLHMin
	    ,c.NLHMax as NLHMax
	    ,c.RatioMin as RatioMin
	    ,c.RatioMax as RatioMax
	    ,c.CAT as CAT  
	    ,c.Mincredit as Mincredit
	    ,c.Maxcredit as Maxcredit
	    ,c.QFLevel as QFLevel
		,sgo.SortOrder as SortOrder
		,sgo.Parent_Id,
		sgo.Id,
		0 as iscourse
	FROM subgroupsOutput sgo
		left join @PSCalculations c on sgo.Id = c.psID
)

,CourseTextoutput as (
	SELECT
		g.id as groupid,
		dbo.ConcatWithSepOrdered_Agg('''',CI.SortOrder,
				concat(
					''<tr>'',
						Case 
							when ci.iscourse = 1 then
								CONCAT(
									dbo.fnHtmlElement(''td'',CourseCode,null),
									dbo.fnHtmlElement(''td'',CI.Title,null)
								)
							Else
								CONCAT(
									''<td colspan="2">'',ci.Title,''</td>''
								)
						End,
						dbo.fnHtmlElement(''td'',case when CHMin <> CHMax then concat(FORMAT(CHMin,''0.##''),''-'',FORMAT(CHMax,''0.##'')) else FORMAT(CHMin,''0.##'') end,null),
						dbo.fnHtmlElement(''td'',case when SWHMin <> SWHMax then concat(FORMAT(SWHMin,''0.##''),''-'',FORMAT(SWHMax,''0.##'')) else FORMAT(SWHMin,''0.##'') end,null),
						dbo.fnHtmlElement(''td'',case when NLHMin <> NLHMax then concat(FORMAT(NLHMin,''0.##''),''-'',FORMAT(NLHMax,''0.##'')) else FORMAT(NLHMin,''0.##'') end,null),
						dbo.fnHtmlElement(''td'',case when RatioMin <> RatioMax then concat(FORMAT(RatioMin,''0.##''),''-'',FORMAT(RatioMax,''0.##'')) else FORMAT(RatioMin,''0.##'') end,null),
						dbo.fnHtmlElement(''td'', CAT,null),
						dbo.fnHtmlElement(''td'',case when Mincredit <> Maxcredit then concat(FORMAT(Mincredit,''0.##''),''-'',FORMAT(Maxcredit,''0.##'')) else FORMAT(Mincredit,''0.##'') end,null),
						dbo.fnHtmlElement(''td'', QFLevel,null),
					''</tr>''
				)
			) 
		as OutputText
		
	FROM Groups g
	inner join courseInfo ci on g.Id = ci.Parent_Id
	Group by g.id
),
groupText as (
	SELECT 
		g.id as groupid, 
		CONCAT(
			''<tr ><th class="tg-0lax Textblue "  style="Background-color:#d0d5de;" colspan="16">'',g.title,''</th></tr>'', 
			ct.OutputText ,
            ''</tr><tr style="Background-color:#e8edf7;"><td colspan="2"><b>sub-total</b></td>'',
            ''<td><b>'',case when CHMin <> CHMax then concat(FORMAT(CHMin,''0.##''),''-'',FORMAT(CHMax,''0.##'')) else FORMAT(CHMin,''0.##'') end,''</b></td>'',
            ''<td><b>'',case when SWHMin <> SWHMax then concat(FORMAT(SWHMin,''0.##''),''-'',FORMAT(SWHMax,''0.##'')) else FORMAT(SWHMin,''0.##'') end,''</b></td>'',
            ''<td><b>'',case when NLHMin <> NLHMax then concat(FORMAT(NLHMin,''0.##''),''-'',FORMAT(NLHMax,''0.##'')) else FORMAT(NLHMin,''0.##'') end,''</b></td>'',
            ''<td></td>'',
            ''<td></td>'',
            ''<td><b>'',case when Mincredit <> Maxcredit then concat(FORMAT(Mincredit,''0.##''),''-'',FORMAT(Maxcredit,''0.##'')) else FORMAT(Mincredit,''0.##'') end,''</b></td>'',
            ''<td></td>''
		)as OutputText,
		ROW_NUMBER () over (order by g.sortorder) as sort
	FROM Groups g
		left join CourseTextoutput ct on g.id = ct.groupid
		left Join @PSCalculations c on g.Id = c.psID
)
,	majors as (
	SELECT
		m.Id as majorID,
		CONCAT(
			dbo.fnHtmlOpenTag(''thead'',null),
                dbo.fnHtmlOpenTag(''tr'',null),
                    ''<th class="tg-0lax" style="Background-color:#B4CAF4;" colspan="16">'',
					m.GroupTitle,
                    ''</th>'',
                ''</div>'',
            dbo.fnHtmlCloseTag(''thead''),
			dbo.ConcatWithSepOrdered_Agg('''',gt.sort,gt.outputtext),
            ''</tr><tr style="Background-color:#d0d5de;"><td colspan="2"><b>Programme  Total</b></td>'',
            ''<td><b>'',case when CHMin <> CHMax then concat(FORMAT(CHMin,''0.##''),''-'',FORMAT(CHMax,''0.##'')) else FORMAT(CHMin,''0.##'') end,''</b></td>'',
            ''<td><b>'',case when SWHMin <> SWHMax then concat(FORMAT(SWHMin,''0.##''),''-'',FORMAT(SWHMax,''0.##'')) else FORMAT(SWHMin,''0.##'') end,''</b></td>'',
            ''<td><b>'',case when NLHMin <> NLHMax then concat(FORMAT(NLHMin,''0.##''),''-'',FORMAT(NLHMax,''0.##'')) else FORMAT(NLHMin,''0.##'') end,''</b></td>'',
            ''<td></td>'',
            ''<td></td>'',
            ''<td><b>'',case when Mincredit <> Maxcredit then concat(FORMAT(Mincredit,''0.##''),''-'',FORMAT(Maxcredit,''0.##'')) else FORMAT(Mincredit,''0.##'') end,''</b></td>'',
            ''<td></td>''
     
		)as OutputText,
		ROW_NUMBER() over (order by m.sortorder) as sort
	FROM ProgramSequence m
		left join Groups g on m.Id = g.major
		inner join groupText gt on g.Id = gt.groupid
		left join @PSCalculations c on m.Id = c.psID
	WHERE m.Parent_Id is null
	and m.ListItemTypeId = 8
	and m.ProgramId = @entityID
	Group by m.Id, m.sortorder, m.GroupTitle,CHMin ,
    CHMax ,
    SWHMin ,
    SWHMax ,
    NLHMin ,
    NLHMax ,
    RatioMin,
    RatioMax ,
    CAT ,
    Mincredit ,
    Maxcredit ,
    QFLevel 
) 
SELECT 
	0 as Value,
	concat(@style,@tableStart,@tableMiddle, dbo.ConcatWithSepOrdered_Agg('''',sort,OutputText), @tableEnd) as Text
FROM majors

'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 182

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection As mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (
276, 182
)