USE [victorvalley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14162';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin report Degree & Certificate Programs update award types to have the code to call in the admin report as before it was all NULL. Used document they attached to set codes';
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
UPDATE AwardType
SET Code = 'AS'
WHERE Id = 3
AND Title = 'AS Associate of Science'

UPDATE AwardType
SET Code = 'AA'
WHERE Id = 2
AND Title = 'AA Associate of Arts'

UPDATE AwardType
SET Code = 'CA'
WHERE Id = 1
AND Title = 'Certificate of Achievement'

UPDATE AwardType
SET Code = 'CCN'
WHERE Id = 10
AND Title = 'Certificate of Completion (NC)'

UPDATE AwardType
SET Code = 'CCY'
WHERE Id = 9
AND Title = 'Certificate of Competency (NC)'

UPDATE AwardType
SET Code = 'AA-T'
WHERE Id = 6
AND Title = 'Associate of Arts for Transfer (AA-T, ADT)'

UPDATE AwardType
SET Code = 'AS-T'
WHERE Id = 7
AND Title = 'Associate of Science for Transfer (AS-T, ADT)'

UPDATE AwardType
SET Code = '-T'
WHERE Id = 8
AND Title = 'Transfer Certification'

UPDATE AwardType
SET Code = 'AAS'
WHERE Id = 4
AND Title = 'AAS Associate of Applied Science'

UPDATE AwardType
SET Code = 'Certificate of Career Preparation'
WHERE Id = 5
AND Title = 'Certificate of Career Preparation'

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId INT;
DECLARE @sql NVARCHAR(MAX) =
"
SELECT 
	CONCAT(p.Title, ', ', at.Code) AS Programs
FROM Program AS p
INNER JOIN AwardType AS at on p.AwardTypeId = at.Id
WHERE p.StatusAliasId = 1
ORDER BY at.Code, p.Title
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Degree & Cerificate Programs', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)