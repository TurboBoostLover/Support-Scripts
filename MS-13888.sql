USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13888';
DECLARE @Comments nvarchar(Max) = 
	'Create two admin reports';
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
	CONCAT(p.Title, ' (', at.Title, ')') AS [Title],
	p.Associations AS [Code],
	sa.Title AS [Status],
	CONCAT(ccf.Code, ' - ' ,ccf.Title) AS [FL CIP Code],
	CONCAT(ccs.Code, ' - ' ,ccs.Title) AS [Federal CIP Code]

FROM Program AS p
INNER JOIN StatusAlias AS sa on p.StatusAliasId = sa.Id
INNER JOIN AwardType AS at on at.Id = p.AwardTypeId
LEFT JOIN ProgramStateCode AS psc on psc.ProgramId = p.Id
LEFT JOIN CipCode_Florida AS ccf on psc.CipCode_FloridaId = ccf.Id
LEFT JOIN ProgramSeededLookup AS psl on psl.ProgramId = p.Id
LEFT JOIN CipCode_Seeded AS ccs on psl.CipCode_SeededId = ccs.Id
WHERE p.Active = 1
AND sa.Id = 1
Order by Title
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Program Florida CIP', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)

/************************************************************************************/

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId2 INT;
DECLARE @sql2 NVARCHAR(MAX) =
"
SELECT 
	CONCAT(p.Title, ' (', at.Title, ')') AS [Title],
	p.Associations AS [Code],
	sa.Title AS [Status],
	CONCAT(ccf.Code, ' - ' ,ccf.Title) AS [FL CIP Code],
	CONCAT(ccs.Code, ' - ' ,ccs.Title) AS [Federal CIP Code]

FROM Program AS p
INNER JOIN StatusAlias AS sa on p.StatusAliasId = sa.Id
INNER JOIN AwardType AS at on at.Id = p.AwardTypeId
LEFT JOIN ProgramStateCode AS psc on psc.ProgramId = p.Id
LEFT JOIN CipCode_Florida AS ccf on psc.CipCode_FloridaId = ccf.Id
LEFT JOIN ProgramSeededLookup AS psl on psl.ProgramId = p.Id
LEFT JOIN CipCode_Seeded AS ccs on psl.CipCode_SeededId = ccs.Id
WHERE p.Active = 1
AND sa.Id = 1
AND (ccf.Code IS NULL or ccs.Code IS NULL)
Order by Title
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Programs missing FL CIP', @sql2, 1, 0)
SET @adminReportId2 = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId2, 1)