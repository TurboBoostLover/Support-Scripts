USE [sbcc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14811';
DECLARE @Comments nvarchar(Max) = 
	'Add new GE stuff';
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
UPDATE GeneralEducation
SET SortOrder = SortOrder + 1
WHERE SortOrder > 10

INSERT INTO GeneralEducation
(Title, SortOrder, ClientId, StartDate)
VALUES
('IGETC Area 7 - Ethnic Studies', 11, 1, GETDATE())

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO GeneralEducationElement
(GeneralEducationId, Title, SortOrder, StartDate, ClientId)
VALUES
(@ID, 'IGETC Area 7 - Ethnic Studies', 1, GETDATE(), 1),
(8, 'IGETC Area 4: Social and Behavioral Sciences', 11, GETDATE(), 1),
(12, 'CSU GE Area D: Social Sciences', 11, GETDATE(), 1)