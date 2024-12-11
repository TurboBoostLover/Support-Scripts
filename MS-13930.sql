USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13930';
DECLARE @Comments nvarchar(Max) = 
	'Update Laney Admin report drop down and add two new ones';
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
UPDATE AdminReport
SET ShowOnMenu = 0
WHERE Id in (3, 4, 5, 6, 7, 8, 9, 15)

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId INT;
DECLARE @sql NVARCHAR(MAX) =
"
SELECT 
	s.SubjectCode AS [Subject Code],
	c.CourseNumber AS [Number],
	co.OutcomeText AS [Outcome],
	cl.Title AS [College]
	FROM
		Course AS c
		LEFT JOIN Subject as s on c.SubjectId = s.Id
		INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
		INNER JOIN Client AS cl on c.ClientId = cl.Id
		LEFT JOIN CourseOutcome AS co on co.CourseId = c.Id
	WHERE sa.Id = 1
	AND cl.Id = 4
	AND c.Active = 1
	ORDER BY s.SubjectCode, c.CourseNumber
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Laney SLOs active courses', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 4)

/************************************************************************************/

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId2 INT;
DECLARE @sql2 NVARCHAR(MAX) =
"
SELECT
	s.SubjectCode AS [Subject Code],
	p.Title AS [Title],
	po.Outcome AS [Outcome],
	sa.Title AS [Status],
	cl.Title AS [College],
	aw.Title AS [Award Type]
	FROM
		Program as p
		INNER JOIN Subject AS s ON p.SubjectId = s.Id
		INNER JOIN StatusAlias AS sa ON p.StatusAliasId = sa.Id
		INNER JOIN Client AS cl ON p.ClientId = cl.Id
		INNER JOIN AwardType AS aw ON p.AwardTypeId = aw.Id
		INNER JOIN ProgramOutcome AS po ON po.ProgramId = p.Id
	WHERE cl.Id = 4
	AND sa.Id = 1
	AND p.Active = 1
	ORDER BY s.SubjectCode, Title, aw.Title
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Laney PLOs', @sql2, 1, 0)
SET @adminReportId2 = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId2, 4)