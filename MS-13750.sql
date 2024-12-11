USE [compton];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13750';
DECLARE @Comments nvarchar(Max) = 
	'Remove Course Disciplines';
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
DECLARE @Table Table (Id int)
INSERT INTO @Table
SELECT Id FROM Subject  WHERE SubjectCode in (
'AFT',
'ARCH',
'ASTU',
'CADD',
'CHIN',
'COMM',
'CTEC', 
'ECHT', 
'ET',
'FASH', 
'FCS',
'FREN', 
'GERM', 
'GLST',
'HORT', 
'HSCI', 
'IT',
'ITAL',
'NESL', 
'NHDV',
'OCEA', 
'PHOT', 
'RC',
'RECR', 
'RTEC', 
'SCOM',
'SSCI',
'SUPV', 
'SURG', 
'TMAT', 
'WST'
)
And Active = 1

UPDATE Subject
SET EndDate = GETDATE()
WHERE Id in (SELECT * FROM @Table)