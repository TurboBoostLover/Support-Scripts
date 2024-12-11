USE [butte];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14265';
DECLARE @Comments nvarchar(Max) = 
	'Update Semester Backing Store and update catalog start date';
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
UPDATE Semester
SET TermStartDate = '2023-08-21 00:00:00.000'
, TermEndDate = '2023-12-15 00:00:00.000'
WHERE Id = 153
AND Title = '2023 Fall Semester'

UPDATE Semester
SET TermStartDate = '2024-01-02 00:00:00.000'
, TermEndDate = '2024-01-19 00:00:00.000'
WHERE Id = 154
AND Title = '2024 Winter Semester'

UPDATE Semester
SET TermStartDate = '2024-01-22 00:00:00.000'
, TermEndDate = '2024-05-24 00:00:00.000'
WHERE Id = 155
AND Title = '2024 Spring Semester'

UPDATE Semester
SET TermStartDate = '2024-06-10 00:00:00.000'
, TermEndDate = '2024-07-18 00:00:00.000'
WHERE Id = 156
AND Title = '2024 Summer Semester'

UPDATE Semester
SET TermStartDate = '2024-08-26 00:00:00.000'
, TermEndDate = '2024-12-20 00:00:00.000'
WHERE Id = 157
AND Title = '2024 Fall Semester'

UPDATE Semester
SET TermStartDate = '2025-01-06 00:00:00.000'
, TermEndDate = '2025-01-24 00:00:00.000'
WHERE Id = 158
AND Title = '2025 Winter Semester'

UPDATE Semester
SET TermStartDate = '2025-01-27 00:00:00.000'
, TermEndDate = '2025-05-30 00:00:00.000'
WHERE Id = 159
AND Title = '2025 Spring Semester'

UPDATE Semester
SET TermStartDate = '2025-06-09 00:00:00.000'
, TermEndDate = '2025-07-17 00:00:00.000'
WHERE Id = 160
AND Title = '2025 Summer Semester'

UPDATE Semester
SET TermStartDate = '2025-08-25 00:00:00.000'
, TermEndDate = '2025-12-19 00:00:00.000'
WHERE Id = 161
AND Title = '2025 Fall Semester'

UPDATE Semester
SET TermStartDate = '2026-01-05 00:00:00.000'
, TermEndDate = '2026-01-23 00:00:00.000'
WHERE Id = 162
AND Title = '2026 Winter Semester'

UPDATE Semester
SET TermStartDate = '2026-01-26 00:00:00.000'
, TermEndDate = '2026-05-22 00:00:00.000'
WHERE Id = 163
AND Title = '2026 Spring Semester'

UPDATE Semester
SET TermStartDate = '2026-06-08 00:00:00.000'
, TermEndDate = '2026-07-16 00:00:00.000'
WHERE Id = 164
AND Title = '2026 Summer Semester'

UPDATE Semester
SET TermStartDate = '2026-08-24 00:00:00.000'
, TermEndDate = '2026-12-18 00:00:00.000'
WHERE Id = 165
AND Title = '2026 Fall Semester'

UPDATE Semester
SET TermStartDate = '2027-01-04 00:00:00.000'
, TermEndDate = '2027-01-22 00:00:00.000'
WHERE Id = 166
AND Title = '2027 Winter Semester'

UPDATE Semester
SET TermStartDate = '2027-01-25 00:00:00.000'
, TermEndDate = '2027-05-28 00:00:00.000'
WHERE Id = 167
AND Title = '2027 Spring Semester'

UPDATE CatalogDetail
SET CatalogStartDate = '2023-08-22'
WHERE Id = 7
AND CatalogTitle = '2023-2024 Butte College Catalog'