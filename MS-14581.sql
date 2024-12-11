USE [imperial];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14581';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report';
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
SET ReportSQL = '
DECLARE @TABLE TABLE (Id INT, Type INT, Author NVARCHAR(MAX), Title NVARCHAR(MAX), Edition NVARCHAR(MAX), CalendarYear NVARCHAR(MAX), IsbnNum NVARCHAR(MAX), Rational NVARCHAR(MAX))

INSERT INTO @TABLE
(Id, Type, Author, Title, Edition, CalendarYear, IsbnNum, Rational)
SELECT c.Id, 1, ct.Author, ct.Title, ct.Edition, CONVERT(nvarchar, ct.CalendarYear), ct.IsbnNum, ct.Rational
FROM Course AS c
INNER JOIN CourseTextbook AS ct ON ct.CourseId = c.Id
UNION
SELECT c.Id, 2, cm.Author, cm.Title, NULL, CAST(cm.PubDate AS NVARCHAR), NULL, NULL
FROM Course AS c
INNER JOIN CourseManual AS cm ON cm.CourseId = c.Id
UNION
SELECT c.Id, 3, cp.Author, cp.Title, cp.Volume, CAST(cp.PublicationYear AS NVARCHAR), NULL, NULL
FROM Course AS c
INNER JOIN CoursePeriodical AS cp ON cp.CourseId = c.Id
UNION
SELECT c.Id, 4, cs.Publisher, cs.Title, cs.Edition, NULL, NULL, cs.Description
FROM Course AS c
INNER JOIN CourseSoftware AS cs ON cs.CourseId = c.Id
UNION
SELECT c.Id, 5, NULL, NULL, NULL, NULL, NULL, cto.TextOther
FROM Course AS c
INNER JOIN CourseTextOther AS cto ON cto.CourseId = c.Id

SELECT
s.SubjectCode AS [Subject],
c.CourseNumber AS [Course Number],
c.Title AS [Course Title],
CASE
    WHEN t.Type = 1 THEN ''Textbook''
    WHEN t.Type = 2 THEN ''Manual''
    WHEN t.Type = 3 THEN ''Periodical''
    WHEN t.Type = 4 THEN ''Software''
    WHEN t.Type = 5 THEN ''Text Other''
    ELSE ''''
END AS [Type],
t.Author AS [Textbook Author],
t.Title AS [Textbook Title],
t.Edition AS [Edition],
t.CalendarYear AS [Year],
t.IsbnNum AS [ISBN],
t.Rational AS [Description]
FROM @TABLE AS t
INNER JOIN Course AS c ON c.Id = t.Id
INNER JOIN Subject AS s ON c.SubjectId = s.Id
WHERE c.StatusAliasId = (SELECT Id FROM StatusAlias WHERE Title = ''Active'')
AND c.Active = 1
ORDER BY s.Title, c.CourseNumber

'
WHERE Id = 1