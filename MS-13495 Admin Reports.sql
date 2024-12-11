USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13495';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin report to show historical courses attached as requisites';
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
SELECT
	  s2.SubjectCode AS [Subject Code]
	, c2.CourseNumber AS [Course Number]
	, c2.Title AS [Course Title]
	, c2.Id AS [Course Id]
	, s.SubjectCode AS [Parent Course Subject Code]
	, c.CourseNumber As [Parent Course Number]
	, c.Title AS [Parent Course Title]
	, c.Id AS [Parent Course Id]

FROM CourseRequisite AS cr
	INNER JOIN Course AS c ON cr.CourseId = c.Id 
		and cr.Active = 1 and c.StatusAliasId <> 6
	INNER JOIN Course AS c2 ON cr.Requisite_CourseId = c2.Id 
		and c2.StatusAliasId = 6
	INNER JOIN Subject AS s ON s.Id = c.SubjectId
	INNER JOIN Subject AS s2 ON s2.Id = c2.SubjectId
	WHERE c.Active = 1
	AND cr.Requisite_CourseId IS NOT NULL
	AND c.ClientId = 3
ORDER BY c.Title
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Historical Requisite Courses', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 3)

------------------------------------------------------------------------------

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId2 INT;
DECLARE @sql2 NVARCHAR(MAX) =
"
SELECT 
	  s.SubjectCode AS [Subject Code]
	, c.CourseNumber AS [Course Number]
	, c.Title AS [Course Title]
	, c.Id AS [Course Id]
	, p.Title AS [Program Title]
	, at.Title AS [Program Award]
	, p.Id AS [Program Id]


FROM ProgramSequence AS ps
	INNER JOIN Course AS c ON c.Id = ps.CourseId 
		and c.StatusAliasId = 6
	INNER JOIN Program AS p ON ps.ProgramId = p.Id 
		and p.StatusAliasId <> 6
	INNER JOIN Subject AS s ON s.Id = c.SubjectId
	INNER JOIN AwardType AS at ON p.AwardTypeId = at.Id
	WHERE CourseId IS NOT NULL
	AND c.ClientId = 3
	and c.Active = 1
	and ps.CourseId IS NOT NULL
	and p.Active = 1
ORDER BY p.Id
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Historical Program Courses', @sql2, 1, 1)
SET @adminReportId2 = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId2, 3)