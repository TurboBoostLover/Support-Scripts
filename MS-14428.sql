USE [hancockcollege];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14428';
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

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @Min decimal(16,3) = 
(SELECT cd.MinCreditHour 
FROM CourseDescription cd
WHERE cd.CourseId = @entityId)

DECLARE @Max decimal(16,3) =
(SELECT cd.MaxCreditHour
FROM CourseDescription cd 
WHERE cd.CourseId = @entityId)

SELECT 0 AS Value, CONCAT(FORMAT(@Min, ''0.###''), 
							CASE 
							WHEN @Max <= @Min OR @Max IS NULL
								THEN ''''
							ELSE CONCAT('' - '', FORMAT(@Max, ''0.###''))
							END) as Text

'
INSERT INTO MetaForeignKeyCriteriaClient 
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'Query for adhocreport', 2)

UPDATE AdHocReport
SET Definition = CONCAT('{"id":"141","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Program Blocks for DE Percentages 1","description":"Active programs and course blocks, with DE course status","outputFormatId":"1","isPublic":false,"columns":[{"caption":"Department","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Tier1_OrganizationEntityId_OrganizationEntity_Program.OrganizationEntityTitle"}},{"caption":"Program Status","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Program.StatusAliasTitle"}},{"caption":"Program Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Program.Title"}},{"caption":"Program Award ","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"AwardTypeId_AwardType_Program.AwardTypeTitle"}},{"caption":"Program Block Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Block_Program.CourseOptionNote"}},{"caption":"Course Subject","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_14"}},{"caption":"Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_15"}},{"caption":"Course Condition","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_19"}},{"caption":"Course Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course_ProgramCourse_CourseOption_Program.Title"}},{"caption":"Units","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL_Course.Text"}},{"caption":"DE course","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseYesNoDetail_CourseYesNo_Course.YesNo03_Title"}},{"caption":"Delivery Method","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"DeliveryMethod_CourseDistanceEducationDeliveryMethod_Course.Description"}},{"caption":"Course Status","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Tier1_OrganizationEntityId_OrganizationEntity_Program.OrganizationEntityTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Applied","text":"Applied"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Program.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Active","text":"Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL_Course.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"', @MAX, '","text":"', @MAX, '"}]}]}}')
WHERE Id = 141