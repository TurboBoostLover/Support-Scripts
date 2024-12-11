USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14377';
DECLARE @Comments nvarchar(Max) = 
	'Two adhoc reports';
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
Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)
DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
SELECT 0 AS Value, CONCAT(l6.ShortText, ' - ', l6.LongText) as Text FROM ModuleLookup06 AS ml6
INNER JOIN Lookup06 AS l6 on ml6.Lookup06Id = l6.Id
WHERE ModuleId = @entityId
"

DECLARE @CSQL2 NVARCHAR(MAX) = "
SELECT 0 AS Value,
yl.Title as Text,
gol1.MaxText01,
CONCAT(it.Title, ' - ', it.Description)
FROM ModuleDetail AS md
INNER JOIN YearLookup AS yl on md.YearLookupId = yl.Id
INNER JOIN GenericOrderedList01 AS gol1 on gol1.ModuleId = md.ModuleId
INNER JOIN ItemType AS it on gol1.ItemTypeId = it.Id
WHERE md.ModuleId = @entityId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Adhoc', 'Id', 'Title', @CSQL, @CSQL, 'Order By SortOrder', 'Adhoc custom sql', 2),
(@MAX2, 'Adhoc', 'Id', 'Title', @CSQL2, @CSQL2, 'Order By SortOrder', 'Adhoc custom sql', 2)

INSERT INTO AdHocReport
(ClientId, Title, Definition, OutputFormatId, IsPublic, Active)
VALUES
(1, 'Program Resources tied to Goals', CONCAT('{"id":"4","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Program Resources tied to Goals","description":"","outputFormatId":"1","isPublic":true,"columns":[{"caption":"Title and Year","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Module.Title"}},{"caption":"Goals","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Module.Text"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL1_Module.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"', @MAX, '","text":"',@MAX, '"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Module.Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"ProposalType_Module.Title"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Instruct","text":"Instruct"}]}]}}'), 1, 1, 1),
(1, 'Mapping Program Goals to Strategic Plan Goals', CONCAT('{"id":0,"modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Mapping Program Goals to Strategic Plan Goals","description":"","outputFormatId":"1","isPublic":true,"columns":[{"caption":"Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Module.Title"}},{"caption":"Year","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Module.Text"}},{"caption":"Goals","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Module.3"}},{"caption":"Mapping to Goals","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Module.4"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL1_Module.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"', @MAX2, '","text":"', @MAX2, '"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Module.Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"ProposalType_Module.Title"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Annual","text":"Annual"}]}]}}'), 1, 1, 1)