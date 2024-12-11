USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14917';
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
WITH StepTitles AS (
    SELECT
        plah.ProposalId,
        dbo.ConcatWithSep_Agg(', ', step.Title) AS [Review Process step]
    FROM
        ProcessLevelActionHistory AS plah
        INNER JOIN StepLevel AS sl ON plah.StepLevelId = sl.Id
        INNER JOIN Step AS step ON step.StepLevelId = sl.Id
    WHERE
        plah.LevelActionResultTypeId = 1
    GROUP BY
        plah.ProposalId
)
SELECT
    CONVERT(varchar, po.LaunchDate, 10) AS [Launch Date],
    CONCAT(u.FirstName, ' ', u.LastName) AS [Originator],
    pt.Title AS [Type of proposal],
    c.Title AS [Title],
    st.[Review Process step]
FROM
    ProposalType AS pt
    INNER JOIN Course AS c ON c.ProposalTypeId = pt.Id
    INNER JOIN Proposal AS po ON c.ProposalId = po.Id
    INNER JOIN [User] AS u ON c.UserId = u.Id
    INNER JOIN StatusAlias AS sa ON c.StatusAliasId = sa.Id
    LEFT JOIN StepTitles AS st ON po.Id = st.ProposalId
WHERE
    c.Active = 1
    AND po.LaunchDate IS NOT NULL
    AND sa.Id = 9
GROUP BY
    po.LaunchDate, u.FirstName, u.LastName, pt.Title, c.Title, st.[Review Process step], st.ProposalId
UNION
SELECT
    CONVERT(varchar, po.LaunchDate, 10) AS [Launch Date],
    CONCAT(u.FirstName, ' ', u.LastName) AS [Originator],
    pt.Title AS [Type of proposal],
    p.Title AS [Title],
    st.[Review Process step]
FROM
    ProposalType AS pt
    INNER JOIN Program AS p ON p.ProposalTypeId = pt.Id
    INNER JOIN Proposal AS po ON p.ProposalId = po.Id
    INNER JOIN [User] AS u ON p.UserId = u.Id
    INNER JOIN StatusAlias AS sa ON p.StatusAliasId = sa.Id
    LEFT JOIN StepTitles AS st ON po.Id = st.ProposalId
WHERE
    p.Active = 1
    AND po.LaunchDate IS NOT NULL
    AND sa.Id = 9
GROUP BY
    po.LaunchDate, u.FirstName, u.LastName, pt.Title, p.Title, st.[Review Process step], st.ProposalId
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('In Review Proposals', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)

INSERT INTO ClientReports
(Title, ClientReportsGroupId, ClientReportsConfigurationId, ClientId, SortOrder, StartDate)
VALUES
('In Review Proposals', 4, 12, 1, 5, GETDATE())
