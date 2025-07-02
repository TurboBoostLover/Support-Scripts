USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18596';
DECLARE @Comments nvarchar(Max) = 
	'Create Admin Report';
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
SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId INT;
DECLARE @sql NVARCHAR(MAX) =
"
SELECT 
CONCAT('(',s.SubjectCode,') ', s.Title) AS [Subject],
c.CourseNumber AS [Course Number],
c.Title AS [Title],
CASE WHEN p.LaunchDate IS NULL THEN 'Imported'
ELSE FORMAT(p.LaunchDate, 'MM/dd/yyyy')
END AS [Launch Date],
Coalesce(LEFT(cb03.Code,4) + '.' + RIGHT(cb03.Code,2) + ' - ' + cb03.Description,cb03.Description,cb03.Code) + Case When cb03.Vocational = 1 then '*' Else '' End AS [TOP Code]
FROM Course AS c
INNER JOIN Subject AS s on c.SubjectId = s.Id
LEFT JOIN Proposal AS p on c.ProposalId = p.Id
LEFT JOIN CourseCBCode AS cb on cb.CourseId = c.Id
LEFT JOIN CB03 AS cb03 on cb.CB03Id = CB03.Id
WHERE c.Active = 1
and c.StatusAliasId = 1
ORDER BY s.SubjectCode, c.CourseNumber
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Course Information', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)

INSERT INTO ClientReports
(Title, ClientReportsGroupId, ClientReportsConfigurationId, ClientId, SortOrder, StartDate)
VALUES
('Course Information', 4, 12, 1, 15, GETDATE())