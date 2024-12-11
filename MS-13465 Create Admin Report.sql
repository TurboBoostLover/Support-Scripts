USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13465';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin report to show all their Gateway Courses in their active Programs';
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
	  s.SubjectCode AS [Subject Code]
	, c.CourseNumber AS [Course Number]
	, c.Title AS [Course Title]
	, p.Title AS [Program Title]
	, at.Title AS [Award Type]

FROM Program AS p
	INNER JOIN AwardType AS at On at.Id = p.AwardTypeId
	INNER JOIN CourseOption AS co ON co.ProgramId = p.Id
	INNER JOIN ProgramCourse AS pc ON pc.CourseOptionId = co.Id
	INNER JOIN Course AS c ON c.Id = pc.CourseId
	INNER JOIN Subject AS s ON s.Id = C.SubjectId
	INNER JOIN StatusAlias AS sa ON sa.StatusBaseId = c.StatusAliasId
WHERE pc.Bit01 = 1
and p.Active = 1
and p.StatusAliasId = 1
ORDER BY 'Program Title'
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Gateway Courses Report', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)
