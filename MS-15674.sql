USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15674';
DECLARE @Comments nvarchar(Max) = 
	'Create new admin report';
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
CONCAT(s.SubjectCode, '/', s.Title) AS [Subject],
c.CourseNumber AS [Course Number],
c.Title AS [Title],
CASE 
	WHEN cyn.YesNo22Id = 1
	THEN 'A'
	WHEN cyn.YesNo22Id = 2
	THEN 'B'
	WHEN cyn.YesNo22Id = 3
	THEN 'C'
	ELSE ''
END AS [Minimum passing grade],
sa.Title AS [Status]
FROM Course AS C
INNER JOIN Subject AS s on c.SubjectId = s.Id
INNER JOIN CourseYesNo AS cyn  on cyn.CourseId = c.Id
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
WHERE cyn.YesNo16Id = 1
and Sa.Id not in(
8, 5,  6
)
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Requisites All min grade', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)

INSERT INTO ClientReports
(Title, ClientReportsGroupId, ClientReportsConfigurationId, ClientId, SortOrder, StartDate)
VALUES
('Requisites All min grade', 4, 12, 1, 5, GETDATE())