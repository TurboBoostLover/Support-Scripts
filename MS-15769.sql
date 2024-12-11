USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15769';
DECLARE @Comments nvarchar(Max) = 
	'Update Dates on semester table';
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
UPDATE Semester
SET TermStartDate = '2022-12-10 00:00:00.000'
, TermEndDate = '2023-05-12 00:00:00.000'
WHERE Id = 101

UPDATE Semester
SET TermStartDate = '2023-05-13 00:00:00.000'
, TermEndDate = '2023-07-28 00:00:00.000'
WHERE Id = 102

UPDATE Semester
SET TermStartDate = '2023-07-29 00:00:00.000'
, TermEndDate = '2023-12-08 00:00:00.000'
WHERE Id = 103

UPDATE Semester
SET TermStartDate = '2023-12-09 00:00:00.000'
, TermEndDate = '2024-05-10 00:00:00.000'
WHERE Id = 104

UPDATE Semester
SET TermStartDate = '2024-05-11 00:00:00.000'
, TermEndDate = '2024-07-26 00:00:00.000'
WHERE Id = 105

UPDATE Semester
SET TermStartDate = '2024-07-27 00:00:00.000'
, TermEndDate = '2024-12-06 00:00:00.000'
WHERE Id = 106

UPDATE Semester
SET TermStartDate = '2024-12-07 00:00:00.000'
, TermEndDate = '2025-05-09 00:00:00.000'
WHERE Id = 107

UPDATE Semester
SET TermStartDate = '2025-05-10 00:00:00.000'
, TermEndDate = '2025-07-25 00:00:00.000'
WHERE Id = 108

UPDATE Semester
SET TermStartDate = '2025-07-26 00:00:00.000'
, TermEndDate = '2025-12-05 00:00:00.000'
WHERE Id = 109

UPDATE Semester
SET TermStartDate = '2025-12-06 00:00:00.000'
, TermEndDate = '2026-05-08 00:00:00.000'
WHERE Id = 110

UPDATE Semester
SET TermStartDate = '2026-05-09 00:00:00.000'
, TermEndDate = '2026-07-24 00:00:00.000'
WHERE Id = 111

UPDATE Semester
SET TermStartDate = '2026-07-25 00:00:00.000'
, TermEndDate = '2026-12-04 00:00:00.000'
WHERE Id = 112

UPDATE Semester
SET TermStartDate = '2026-12-05 00:00:00.000'
, TermEndDate = '2027-05-07 00:00:00.000'
WHERE Id = 115

UPDATE Semester
SET TermStartDate = '2027-05-08 00:00:00.000'
, TermEndDate = '2027-07-23 00:00:00.000'
WHERE Id = 116

UPDATE Semester
SET TermStartDate = '2027-07-24 00:00:00.000'
, TermEndDate = '2027-12-03 00:00:00.000'
WHERE Id = 117

UPDATE Semester
SET TermStartDate = '2027-12-04 00:00:00.000'
, TermEndDate = '2028-05-05 00:00:00.000'
WHERE Id = 118

UPDATE Semester
SET TermStartDate = '2028-05-06 00:00:00.000'
, TermEndDate = '2028-07-21 00:00:00.000'
WHERE Id = 119

UPDATE Semester
SET TermStartDate = '2028-07-22 00:00:00.000'
, TermEndDate = '2028-12-01 00:00:00.000'
WHERE Id = 120

UPDATE Semester
SET TermStartDate = '2028-12-02 00:00:00.000'
, TermEndDate = '2029-05-04 00:00:00.000'
WHERE Id = 121

UPDATE Semester
SET TermStartDate = '2029-05-05 00:00:00.000'
, TermEndDate = '2029-07-20 00:00:00.000'
WHERE Id = 122