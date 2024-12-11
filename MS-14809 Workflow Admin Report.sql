USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14809';
DECLARE @Comments nvarchar(Max) = 
	'Custom Admin Report';
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
SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId INT;
DECLARE @sql NVARCHAR(MAX) =
"
SELECT
CASE
	WHEN pr.EntityTitle IS NOT NULL
	THEN pr.EntityTitle
	ELSE c.EntityTitle
END AS [Title],
s.Title AS [Step],
CONCAT (u.FirstName, ' ', u.LastName) AS [User],
a.Title AS [Action],
psah.Comments AS [Comment]
FROM Proposal As p
LEFT JOIN Course As c on c.ProposalId = p.Id
LEFT JOIN Program As pr on pr.ProposalId = p.Id
INNER JOIN ProcessLevelActionHistory AS plah on plah.ProposalId = p.Id
INNER JOIN ProcessStepActionHistory AS psah on psah.ProcessLevelActionHistoryId = plah.Id
INNER JOIN Step As s on s.Id = psah.StepId
INNER JOIN [User] AS u on psah.UserId = u.Id
INNER JOIN ActionLevelRoute AS alr on psah.ActionLevelRouteId = alr.Id
INNER JOIN Action AS a on alr.ActionId = a.Id
WHERE (c.StatusAliasId in (1, 2) or pr.StatusAliasId in (1, 2))
AND (pr.EntityTitle IS NOT NULL or c.EntityTitle IS NOT NULL)
AND (psah.Comments IS NOT NULL and LEN(psah.Comments) > 1)
order by Title
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Workflow Comments', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 3)

INSERT INTO ClientReports
(Title, ClientReportsGroupId, ClientReportsConfigurationId, ClientId, SortOrder, StartDate)
VALUES
('Workflow Comments', 14, 12, 3, 10, GETDATE())