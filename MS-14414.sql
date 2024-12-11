USE [ccsf];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14414';
DECLARE @Comments nvarchar(Max) = 
	'Upate Adchoc Report';
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

DECLARE @SQL NVARCHAR(MAX) = 
'DECLARE @Min INT = 
(SELECT SUM(CAST(cd.MinCreditHour AS decimal(16,3)))
FROM ProgramCourse pc
	INNER JOIN CourseDescription cd ON cd.Id = pc.CourseId
	INNER JOIN CourseOption co ON co.Id = pc.CourseOptionId
WHERE co.ProgramId = @entityId)

DECLARE @Max INT =
(SELECT SUM(CAST(cd.MaxCreditHour AS decimal(16,3)))
FROM ProgramCourse pc
	INNER JOIN CourseDescription cd ON cd.Id = pc.CourseId
	INNER JOIN CourseOption co ON co.Id = pc.CourseOptionId
WHERE co.ProgramId = @entityId)

SELECT 0 AS Value, CONCAT(
							CASE 
							WHEN @Min is null then ''''
							ELSE CONCAT(@Min, '' - '')
							END,
							@Max
							) as Text'

INSERT INTO MetaForeignKeyCriteriaClient 
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Program', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'Query for adhocreport', 2)

UPDATE AdHocReport
SET Definition = CONCAT('{"id":"19","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Active Programs with Department","description":"","outputFormatId":"1","isPublic":true,"columns":[{"caption":"Division","sorting":"Ascending","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Tier1_OrganizationEntityId_OrganizationEntity_Program.OrganizationEntityTitle"}},{"caption":"Department","sorting":"Ascending","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Tier2_OrganizationEntityId_OrganizationEntity_Program.OrganizationEntityTitle"}},{"caption":"Program Title","sorting":"Ascending","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Title"}},{"caption":"Award Type","sorting":"Ascending","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"AwardTypeId_AwardType_Program.AwardTypeTitle"}},{"caption":"Academic and Career Community","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Building_ProgramDetail_Program.Title"}},{"caption":"Proposal Type","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProposalTypeId_ProposalType_Program.Title"}},{"caption":"Effective Semester","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"SemesterId_Semester_ProgramProposal.Title"}},{"caption":"Effective Year","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProgramProposal_Program.StartYear"}},{"caption":"Curriculum Committee Approval Date","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProgramDate_Program.ProgramDate"}},{"caption":"Program Id","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Id"}},{"caption":"Units","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Program.Text"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Program.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"active","text":"active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"ProgramDateType_ProgramDate_Program.Title"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Curriculum Committee Approval Date","text":"Curriculum Committee Approval Date"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL1_Program.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"', @MAX,'","text":"', @MAX,'"}]}]}}')
WHERE Id = 19