USE [cuesta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14382';
DECLARE @Comments nvarchar(Max) = 
	'Update Work flows';
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
UPDATE Process 
SET Title = 'Standard'
WHERE Active = 1
AND Id = 3

exec spActivateWorkflow 3, 44

UPDATE Process 
SET Title = 'Deletion'
WHERE Active = 1
AND Id = 8

exec spActivateWorkflow 8, 45
exec spActivateWorkflow 20, 46

UPDATE ProcessProposalType
SET ProcessId = 8
WHERE Id in (8, 7)

UPDATE ProcessProposalType
SET ProcessId = 3
WHERE Id in (16, 6, 15, 9, 2, 1, 5, 4)

UPDATE ProcessProposalType
SET ProcessId = 20
WHERE Id = 3

UPDATE ProcessProposalType
SET ProcessId = 14
WHERE Id in (12, 11)