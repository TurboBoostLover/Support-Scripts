USE [victorvalley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14161';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin report for 5 year report - courses';
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
DECLARE @useAll bit = 
CASE 
    WHEN @Status < (select min(Id) from StatusAlias)
        THEN  1
    ELSE
        0
END

SELECT 
	c.EntityTitle AS [Course Title],
	c.Id AS [Course Id],
	sa.Title AS [Status],
	pt.Title AS [Proposal Type],
	CONVERT(VARCHAR, cd.CourseDate, 101) AS [CC Approval Date],
	CONVERT(VARCHAR, cd2.CourseDate, 101) AS [Content Review],
	dbo.ConcatWithSep_Agg(' ', psah.Comments) AS [Notes],
	'Active' AS [Review Process step]
FROM Course AS c
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
LEFT JOIN ProposalType AS pt on c.ProposalTypeId = pt.Id
LEFT JOIN Proposal AS p on c.ProposalId = p.Id
LEFT JOIN CourseDate AS cd on cd.CourseId = c.Id and cd.CourseDateTypeId = 6
LEFT JOIN CourseDate AS cd2 on cd2.CourseId = c.Id and cd2.CourseDateTypeId = 7
LEFT JOIN ProcessLevelActionHistory AS plah on plah.ProposalId = p.Id 
LEFT JOIN ProcessStepActionHistory AS psah on psah.ProcessLevelActionHistoryId = plah.Id
LEFT JOIN StepLevel AS sl on plah.StepLevelId = sl.Id
LEFT JOIN Step AS step on step.StepLevelId = sl.Id
WHERE c.Active = 1
AND (@useAll = 1 OR c.StatusAliasId = @Status)
AND sa.Id = 1 --hard code status to active as well to remove work flow objects
GROUP BY c.EntityTitle, c.ID, sa.Title, pt.Title, cd.CourseDate, cd2.CourseDate
UNION
SELECT 
	c.EntityTitle AS [Course Title],
	c.Id AS [Course Id],
	sa.Title AS [Status],
	pt.Title AS [Proposal Type],
	CONVERT(VARCHAR, cd.CourseDate, 101) AS [CC Approval Date],
	CONVERT(VARCHAR, cd2.CourseDate, 101) AS [Content Review],
	dbo.ConcatWithSep_Agg(' ', psah.Comments) AS [Notes],
			dbo.ConcatWithSep_Agg('; ',
		step.Title) AS [Review Process step]
FROM Course AS c
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
LEFT JOIN ProposalType AS pt on c.ProposalTypeId = pt.Id
LEFT JOIN Proposal AS p on c.ProposalId = p.Id
LEFT JOIN CourseDate AS cd on cd.CourseId = c.Id and cd.CourseDateTypeId = 6
LEFT JOIN CourseDate AS cd2 on cd2.CourseId = c.Id and cd2.CourseDateTypeId = 7
LEFT JOIN ProcessLevelActionHistory AS plah on plah.ProposalId = p.Id AND plah.LevelActionResultTypeId = 1
LEFT JOIN ProcessStepActionHistory AS psah on psah.ProcessLevelActionHistoryId = plah.Id
LEFT JOIN StepLevel AS sl on plah.StepLevelId = sl.Id
LEFT JOIN Step AS step on step.StepLevelId = sl.Id
WHERE c.Active = 1
AND (@useAll = 1 OR c.StatusAliasId = @Status)
AND sa.Id <> 1 --hard code as top query will grab them to remove duplicates
GROUP BY c.EntityTitle, c.ID, sa.Title, pt.Title, cd.CourseDate, cd2.CourseDate
ORDER BY c.EntityTitle
";

DECLARE @filterSql NVARCHAR(MAX) = 
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
VALUES ('Five Year Report - Courses', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId) 
VALUES (@adminReportId, 1)

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
	, 'Status'
	, 'Status'
	, 1
	)