USE [imperial];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14501';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin report Course Textbooks';
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
s.Title AS [Subject],
c.CourseNumber AS [Course Number],
c.Title AS [Course Title],
ct.Author AS [Textbook Author],
ct.Title AS [Textbook Title],
ct.Edition AS [Edition],
ct.CalendarYear AS [Year],
ct.IsbnNum AS [ISBN],
ct.Rational AS [Description]
FROM Course AS C
LEFT JOIN Subject As s on c.SubjectId = s.Id
LEFT JOIN CourseTextbook AS ct on ct.CourseId = c.Id
WHERE c.StatusAliasId = (SELECT Id FROM StatusAlias WHERE Title = 'Active')
AND c.Active = 1
order by S.Title, c.CourseNumber
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Course Textbooks', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)