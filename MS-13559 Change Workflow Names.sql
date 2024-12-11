USE [reedley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13559';
DECLARE @Comments nvarchar(Max) = 
	'Change Names Of Workflows';
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
UPDATE Process
SET Title = 'Admin New Course'
WHERE Id = 8
AND Title = 'New Course'

UPDATE Process
SET Title = 'Admin New Degree Certificate'
WHERE Id = 9
AND Title = 'New Degree Certificate'

UPDATE Process
SET Title = 'Admin Course Modification'
WHERE Id = 10
AND Title = 'Course Modification'

UPDATE Process
SET Title = 'Admin Degree Certificate Modification'
WHERE Id =11
AND Title = 'Degree Certificate Modification'

UPDATE Process
SET Title = 'Admin Course Deactivation'
WHERE Id =12
AND Title = 'Course Deactivation'

UPDATE Process
SET Title = 'Admin Degree Certificate Deactivation'
WHERE Id = 13
AND Title = 'Degree Certificate Deactivation'