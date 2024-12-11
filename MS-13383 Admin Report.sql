USE [compton];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13383';
DECLARE @Comments nvarchar(Max) = 
	'Created Copy of their Ad Hoc COR Report as an admin report to fill all request.';
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
	  s.SubjectCode AS [Subject Code]
	, c.CourseNumber AS [Course Number]
	, sa.Title AS [Course Status]
	, c.Title AS [Course Title]
	, sem.Title AS [Effective Date]
	, cd.CourseDate AS [College Curriculum Committee Approval]
	, cp.AdviseResults AS [Academic Senate Approval]
	, cdd.CourseDate AS [Board of Trustees Approval Date]
FROM Course AS c
	LEFT JOIN StatusAlias AS sa ON c.StatusAliasId = sa.StatusBaseId
	LEFT JOIN CourseProposal AS cp on cp.CourseId = c.Id
	LEFT JOIN Semester AS sem ON sem.Id = cp.SemesterId
	LEFT JOIN Subject AS s ON s.Id = c.SubjectId
	LEFT JOIN CourseDate AS cd ON cd.CourseId = c.Id and cd.CourseDateTypeId = 6
	LEFT Join CourseDate AS cdd on cdd.CourseId = c.Id and cdd.CourseDateTypeId = 10
WHERE c.Active = 1

";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('COR Report', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)