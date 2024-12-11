USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17455';
DECLARE @Comments nvarchar(Max) = 
	'Adhoc report';
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

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
SELECT DISTINCT p.Id AS Value, p.Id As text
FROM Program AS p
INNER JOIN ProgramSequence AS ps on ps.ProgramId = p.Id
WHERE ps.CourseId in (
	SELECT ID FROM Course 
	WHERE 
	(CourseNumber like '%1A%' and SubjectId in (52, 202, 203, 204)) 
	or (CourseNumber like '%1AS%' and SubjectId in (52, 202, 203, 204))
	or (CourseNumber like '%13%' and SubjectId in (86, 238, 239, 240))
	or (CourseNumber like '%45%' and SubjectId in (31, 185, 186, 187))
	or (CourseNumber like '%1%' and SubjectId in (106, 255, 256, 257))
	or (CourseNumber like '%1A%' and SubjectId in (107, 258, 259, 260))
)
"


SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Program', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'Custom Adhoc query', 2)


INSERT INTO AdHocReport
(ClientId, Title, Description, Definition, IsPublic, Active, OutputFormatId)
SELECT Id, 'Program CCN Report', '', CONCAT('{"id":0,"modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Program CCN Report","description":"","outputFormatId":1,"isPublic":false,"columns":[{"caption":"Program Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Title"}},{"caption":"College","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ClientId_Client_Program.ClientTitle"}},{"caption":"Award Type","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"AwardTypeId_AwardType_Program.AwardTypeTitle"}},{"caption":"Meta ID","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Program.Text"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Program.Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Program.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Active","text":"Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL1_Program.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"',@MAX,'","text":"',@MAX,'"}]}]}}'), 0, 1, 1 FROM Client WHERE Id <> 1