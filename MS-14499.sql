USE [sbcc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14499';
DECLARE @Comments nvarchar(Max) = 
	'New Adhoc Report';
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
SELECT 0 AS Value,
mq.Title AS Text,
	CASE
		WHEN LEN(dbo.ConcatWithSep_Agg(', ', co.Text)) > 30000 THEN 'Too long for excel'
		ELSE
dbo.ConcatWithSep_Agg(', ', co.Text) 
	END AS Objectives,
	CASE
		WHEN LEN(dbo.ConcatWithSep_Agg(', ', com.OutcomeText)) > 30000 THEN 'Too long for excel'
		ELSE
dbo.ConcatWithSep_Agg(', ', com.OutcomeText) 
	END AS SLO,
	CASE
		WHEN LEN(dbo.ConcatWithSep_Agg(', ', it.Title)) > 30000 THEN 'Too long for excel'
		ELSE
dbo.ConcatWithSep_Agg(', ', it.Title) 
	END AS Instruction,
	CASE
		WHEN LEN(cmoi.OtherMethod) > 30000 THEN 'Too long for excel'
		ELSE
cmoi.OtherMethod 
END AS Other,
	CASE
		WHEN LEN(cad.AssignmentText) > 30000 THEN 'Too long for excel'
		ELSE
cad.AssignmentText 
END AS Req
FROM Course AS c
LEFT JOIN CourseMinimumQualification as cmq on cmq.CourseId = c.Id
LEFT JOIN MinimumQualification AS mq on cmq.MinimumQualificationId = mq.Id
LEFT JOIN CourseObjective As co on co.CourseId = c.Id
LEFT JOIN CourseOutcome AS com on com.CourseId = c.Id
LEFT JOIN CourseInstructionType AS cit on cit.CourseId = c.Id
LEFT JOIN InstructionType AS it on cit.InstructionTypeId = it.Id
LEFT JOIN CourseMethodOfInstruction AS cmoi on cmoi.CourseId = c.Id
LEFT JOIN CourseAchievementData AS cad on cad.CourseId = c.Id
WHERE c.Id = @EntityId
group by cmoi.OtherMethod, mq.Title, cad.AssignmentText
"

DECLARE @CSQL2 NVARCHAR(MAX) = "
SELECT
  0 AS Value,
  CASE
    WHEN LEN(cme.MethodOfEvaluation) > 30000 THEN 'Too long for excel'
    ELSE cme.MethodOfEvaluation
  END AS Text,
	CASE
    WHEN LEN(CAST(dbo.stripHtml (dbo.regex_replace(c.LectureOutline, N'['+nchar(8203)+N']', N'')) AS NVARCHAR(MAX))) > 30000 THEN 'Too long for excel'
    ELSE CAST(dbo.stripHtml (dbo.regex_replace(c.LectureOutline, N'['+nchar(8203)+N']', N'')) AS NVARCHAR(MAX))
  END AS Content
FROM CourseMethodOfEvaluation AS cme
LEFT JOIN Course AS c on cme.CourseId = c.Id
WHERE c.Id = @EntityId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Adhoc', 'Id', 'Title', @CSQL, @CSQL, 'Order By SortOrder', 'Adhoc custom sql', 2),
(@MAX2, 'Adhoc', 'Id', 'Title', @CSQL2, @CSQL2, 'Order By SortOrder', 'Adhoc custom sql', 2)

INSERT INTO AdHocReport
(ClientId, Title, Description, Definition, OutputFormatId, IsPublic, Active)
VALUES
(1, 'NC COR Report', '#38072', CONCAT('{"id":"46","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"NC COR Report","description":"#38072","outputFormatId":"1","isPublic":false,"columns":[{"caption":"Subject","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Subject_Course.Title"}},{"caption":"Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.CourseNumber"}},{"caption":"Long Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.Title"}},{"caption":"Catalog Course Description","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.Description"}},{"caption":"Disciplines","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL_Course.Text"}},{"caption":"Min Units","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_25"}},{"caption":"Max Units","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_26"}},{"caption":"Min Lecture Hour","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_29"}},{"caption":"Max Lecture Hour","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_30"}},{"caption":"Min Lab Hour","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_28"}},{"caption":"Max Lab Hour","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_27"}},{"caption":"Class Size","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseDescription_Course.ClassMaximumSize"}},{"caption":"Objectives","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Course.3"}},{"caption":"Student Learning Outcomes","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Course.4"}},{"caption":"Course Content","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL2_Course.3"}},{"caption":"Methods of Instruction","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Course.5"}},{"caption":"Other Methods","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Course.6"}},{"caption":"Sample Assignment","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.SupplementalComments"}},{"caption":"Required Assignment","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL1_Course.7"}},{"caption":"Methods of Evaluation","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL2_Course.Text"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Course.Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Active","text":"Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL_Course.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"', @MAX, '","text":"', @MAX, '"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL2_Course.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"', @MAX2, '","text":"', @MAX2, '"}]}]}}'), 1, 0, 1)