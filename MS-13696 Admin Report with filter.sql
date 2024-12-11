USE [gavilan];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13696';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin report for program reviews';
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
Please do not alter the script above this comment� except to set
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
SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId INT;
DECLARE @sql NVARCHAR(MAX) =
"
DECLARE @useAllYears bit = 
CASE 
    WHEN @year < (select min(Id) from Semester)
        THEN  1
    ELSE
        0
END

DECLARE @useAll bit = 
CASE 
    WHEN @status < (select min(Id) from StatusAlias)
        THEN  1
    ELSE
        0
END

SELECT
	  m.Title AS [Title]
	, sa.Title AS [Status]
	, s.Title AS [Semester]
	, mg.Goal AS [Goal]
	, mg.ConnectionToMissionStatement AS [Connection of Goal to Mission Statement]
	, mg.PlanToAchieveGoal AS [Plan to Achieve Goal]
	, mg.ResponsibleParty AS [Responsible Party]
	, mg.FundAmountRequested AS [Fund Amount Requested]
	, mg.ResourceAllocation AS [Total Resource Allocation Request]
	, mg.Timeline AS [Timeline to Completion]
	, mg.EvaluationPlan AS [Evaluation Method]

FROM Module AS m
	INNER JOIN Modulegoal AS mg ON mg.ModuleId = m.Id
	INNER JOIN StatusAlias AS sa ON m.StatusAliasId = sa.Id
	INNER JOIN ModuleDetail AS md ON md.ModuleId = m.Id
	INNER JOIN Semester AS s on s.Id = md.AcademicYear_SemesterId
WHERE m.Active = 1
AND (@useAllYears = 1 OR md.AcademicYear_SemesterId = @year)
AND (@useAll = 1 OR m.StatusAliasId = @status)
ORDER BY m.Id
";


DECLARE @filterSql NVARCHAR(MAX) = 
"
select 
    Id as Value
    ,Coalesce(Cast(AcademicYearStart as nvarchar) + '-' +	Cast(AcademicYearEnd as nvarchar)
    ,'The AcademicYearStart and/or AcademicYearEnd field is not populated. This uses Catalog configuration of the semester table.') as Text, 
    AcademicYearStart,
    SortOrder 
from Semester 
Where EndDate Is NULL 
and Active = 1 
and Title like '%Fall%' 
UNION
SELECT (select min(Id) from Semester)-1 AS Value
   ,'All Years' as Text,
   (select min(AcademicYearStart) from Semester)-1 as AcademicYearStart,
   (select min(SortOrder) from Semester)-1 as SortOrder
from Semester 
Order by AcademicYearStart, SortOrder
";


DECLARE @filterSql2 NVARCHAR(MAX) = 
"
select 
    Id as Value
    ,Coalesce(Cast(Title as nvarchar)
    ,'The Status field is not populated. This uses Catalog configuration of the Status table.') as Text		
from StatusAlias
WHERE Active = 1
UNION
SELECT (select min(Id) from StatusAlias)-1 AS Value
,'All Status' as Text
FROM StatusAlias
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Program Review Goals', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 57)

INSERT INTO AdminReportFilter 
	(
	  AdminReportId
	, AdminReportFilterTypeId
	, FilterSQL
	, VariableName
	, FilterLabel
	, FilterRequired
	)
VALUES  
	(
	  @adminReportId
	, 2
	, @filterSql
	, 'year'
	, 'Year'
	, 1
	)
	,
		(
	  @adminReportId
	, 2
	, @filterSql2
	, 'status'
	, 'Status'
	, 0
	)