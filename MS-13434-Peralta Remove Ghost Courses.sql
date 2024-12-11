USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13434';
DECLARE @Comments nvarchar(Max) = 
	'Deleted bad data from program "Building Codes And Inspections" (1411)';
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
	DECLARE @PSID integers

	INSERT INTO @PSID
	SELECT Id FROM ProgramSequence AS PS
	WHERE ProgramId = 1411
	AND NOT EXISTS (SELECT * FROM ProgramSequenceDetail WHERE ProgramSequenceId = PS.Id)

	DELETE FROM ProgramOutcomeMatching
	WHERE ProgramSequenceId IN (SELECT * FROM @PSID);

	DELETE FROM ProgramSequence
	WHERE Id IN (SELECT * FROM @PSID);