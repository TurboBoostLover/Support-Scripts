USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14174';
DECLARE @Comments nvarchar(Max) = 
	'Deleted bad data from program "Kinesiology" (1832)';
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
	--SELECT CourseId ,*
	DELETE
	FROM ProgramSequenceDetail
	WHERE ProgramSequenceId in (
		SELECT Id FROM ProgramSequence
		WHERE ProgramId = 1832
		AND CourseId in (
	17217,
	17213,
	16115,
	16117
	)
	AND Parent_Id IS NULL
	)

	--SELECT CourseId, *
	delete 
	from ProgramOutcomeMatching
	where ProgramSequenceId in (
		SELECT Id FROM ProgramSequence
		WHERE ProgramId = 1832
		AND CourseId in (
	17217,
	17213,
	16115,
	16117
	)
	AND Parent_Id IS NULL
	)

	--select CourseId, *
	delete 
	from ProgramSequence
	where ProgramId = 1832
	AND CourseId in (
	17217,
	17213,
	16115,
	16117
	)
	AND Parent_Id IS NULL