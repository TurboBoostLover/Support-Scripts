USE [nu];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14923';
DECLARE @Comments nvarchar(Max) = 
	'Update Adhoc Report';
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

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
SELECT 0 AS Value,
    oe.Code AS Text,
    CASE
        WHEN dbo.ConcatWithSep_Agg(', ', an.Text) IS NULL THEN 'empty'
        ELSE dbo.ConcatWithSep_Agg(', ', an.Text)
    END AS [Program Modality],
    CASE
        WHEN dbo.ConcatWithSep_Agg(', ', aet.Text) IS NULL THEN 'empty'
        ELSE dbo.ConcatWithSep_Agg(', ', aet.Text)
    END AS [Unit Modality],
    CONCAT('https://nu.curriqunet.com/Form/Program/Index/', p.Id) AS [Link]
FROM Program AS p
INNER JOIN OrganizationEntity AS oe on p.Tier1_OrganizationEntityId = oe.Id
LEFT JOIN ProgramAwardNote AS pan on pan.ProgramId = p.Id
LEFT JOIN AwardNote AS an on pan.AwardNoteId = an.Id
LEFT JOIN ProgramAdmissionExamType AS paet on paet.ProgramId = p.Id
LEFT JOIN AdmissionExamType AS aet on paet.AdmissionExamTypeId = aet.Id
WHERE p.Id = @EntityId
GROUP BY oe.Code, p.Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Program', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'Custom Query for adhoc report', 2)

UPDATE Adhocreport
SET Definition = CONCAT('{"id":"59","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Spreadsheet - Programs","description":"","outputFormatId":"1","isPublic":false,"columns":[{"caption":"Program Status","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Program.StatusAliasTitle"}},{"caption":"School Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Program.Text"}},{"caption":"Department","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Tier2_OrganizationEntityId_OrganizationEntity_Program.OrganizationEntityTitle"}},{"caption":"Program Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.EntityTitle"}},{"caption":"Proposal Type","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ProposalTypeId_ProposalType_Program.Title"}},{"caption":"Program Modality","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Program.3"}},{"caption":"Unit Modality","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Program.4"}},{"caption":"CNET Link","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Program.5"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"InList","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Program.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"List","value":"in review,draft,approved","text":"in review,draft,approved"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"NotContains","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Program.EntityTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"test","text":"test"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL1_Program.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"', @MAX, '","text":"', @MAX, '"}]}]}}')
WHERE Id = 59