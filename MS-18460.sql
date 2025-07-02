USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18460';
DECLARE @Comments nvarchar(Max) = 
	'Update Rubric Query Text';
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
declare @rubricTitle NVARCHAR(max) = (select Title from [Module] where id = @entityId)
declare @rubricMethod NVARCHAR(max) = (
	select case when MD.ImprovementActionTypeId <> 10 then IAT.Title else ME1.TextMax01 end
	from ModuleDetail MD
		left join ImprovementActionType IAT on IAT.id = MD.ImprovementActionTypeId
		inner join [ModuleExtension01] ME1 on MD.ModuleId = ME1.ModuleId
	where MD.moduleid = @entityId
)

declare @style NVARCHAR(max) = ''<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0; width:100%}
.tg td{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
  overflow:hidden;padding:10px 5px;word-break:normal;}
.tg th{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
  font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
.tg .tg-baqh{text-align:center;vertical-align:top}
.tg .tg-nrix{text-align:center;vertical-align:middle}
</style>''

declare @outcomeNum nvarchar = (select count(id) from StrategicGoal where Active = 1)
IF (@outcomeNum > 0)
begin

declare @tableStart NVARCHAR(max) = concat(
    ''<table class="tg">
<thead>
  <tr>
    <th class="tg-baqh">''
    ,@rubricTitle
    ,N''</th>
    <th class="tg-baqh" colspan="'',@outcomeNum,N''">Grades (Performance Level)</th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-baqh">Assessment method</td>
    '',(select dbo.ConcatWithSepOrdered_Agg(Char(13),sortorder,''<td class="tg-baqh">'' + code + ''</td>'') from (select code,ROW_NUMBER() over (order by sortorder,id) as sortorder from StrategicGoal where Active = 1 and Id in (SELECT StrategicGoalId FROM ModuleObjectiveStrategicGoal AS mos INNER JOIN ModuleObjective AS mo on mo.Id = mos.ModuleObjectiveId WHERE mo.ModuleId = @EntityId)) A),''
  </tr>
   <tr>
    <td class="tg-baqh">''
    ,@rubricMethod
    ,N''</td>
    '',(select dbo.ConcatWithSepOrdered_Agg(Char(13),sortorder,''<td class="tg-baqh">'' + Title + '' '' + Description + ''</td>'') from (select Title,Description,ROW_NUMBER() over (order by sortorder,id) as sortorder from StrategicGoal where Active = 1 and Id in (SELECT StrategicGoalId FROM ModuleObjectiveStrategicGoal AS mos INNER JOIN ModuleObjective AS mo on mo.Id = mos.ModuleObjectiveId WHERE mo.ModuleId = @EntityId)) B),''
  </tr>
   <tr>
    <td class="tg-baqh" colspan="'',@outcomeNum + 1,N''">Assessment Dimensions</td>
  </tr>''
)

declare @tableEnd NVARCHAR(max) = ''</tbody></table>''

declare @bodyOutput table (Id int, Criteria NVARCHAR(max),CombinedComments NVARCHAR(max),sortorder int)

insert into @bodyOutput
(id,Criteria,sortorder)
select id,MaxText01,ROW_NUMBER() over (order by sortorder)
from ModuleObjective
where ModuleId = @entityId


declare @innerOutput table (RubricCriteriaId int, CombinedText NVARCHAR(max),sortorder int)

insert into @innerOutput
SELECT 
    bo.Id,
    dbo.ConcatWithSepOrdered_Agg(
        '''',
        rs.SortOrder,
        CONCAT(''<td class="tg-baqh">'', ISNULL(mrs.MaxText01, ''''), ''</td>'')
    ) AS HtmlCells,
    bo.SortOrder
FROM @bodyOutput bo
CROSS JOIN (
    SELECT 
        id, 
        ROW_NUMBER() OVER (ORDER BY sortorder, id) AS SortOrder 
    FROM StrategicGoal 
    WHERE Active = 1 
      AND Id IN (
          SELECT StrategicGoalId 
          FROM ModuleObjectiveStrategicGoal AS mos
          INNER JOIN ModuleObjective AS mo ON mo.Id = mos.ModuleObjectiveId
          WHERE mo.ModuleId = @EntityId
      )
) rs
LEFT JOIN ModuleObjectiveStrategicGoal mrs ON mrs.ModuleObjectiveId = bo.Id AND mrs.StrategicGoalId = rs.id
GROUP BY bo.Id, bo.SortOrder;

update @bodyOutput
set CombinedComments = inn.CombinedText
from @bodyOutput bo
    inner join @innerOutput inn on inn.RubricCriteriaId = bo.Id

declare @finalOutput nvarchar(max) = N''''

SELECT
@finalOutput = COALESCE(@finalOutput, '''') + concat(
    ''<tr>''
    ,''<td class="tg-baqh">'',Criteria,''</td>''
    ,CombinedComments
    ,''</tr>''
)
FROM @bodyOutput
order by sortorder

select 0 as Value, concat(@style,@tableStart,@finalOutput,@tableEnd) as Text

END
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 200

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection As mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 200