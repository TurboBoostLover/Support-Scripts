USE [evc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14199';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin report to show users by division and department';
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
DECLARE @TABLE TABLE (names nvarchar(max), div nvarchar(max), dep nvarchar(max))
INSERT INTO @TABLE
SELECT DISTINCT
CONCAT(u.FirstName, ' ', u.LastName),
CASE 
	WHEN oe.Code IS NOT NULL 
	THEN CONCAT('(',oe.Code,') ', oe.Title)
	ELSE oe.Title
END,
CASE 
	WHEN oe2.Code IS NOT NULL 
	THEN CONCAT('(',oe2.Code,') ', oe2.Title)
	ELSE oe2.Title
END
FROM [User] AS u
LEFT JOIN UserOriginationOrganizationEntityPermission AS uo on uo.UserId = u.Id
LEFT JOIN OrganizationEntity AS oe on uo.OrganizationEntityId = oe.Id AND oe.OrganizationTierId = 14
LEFT JOIN OrganizationEntity AS oe2 on uo.OrganizationEntityId = oe2.Id AND oe2.OrganizationTierId = 15
WHERE u.Active = 1
and uo.Active = 1

SELECT 
names AS [Name], 
dbo.ConcatWithSep_Agg(', ', div) AS [Division],
dbo.ConcatWithSep_Agg(', ', dep) AS [Department]
FROM @TABLE AS t
group by t.names
order by t.names
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('CurriQunet Users', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 22)