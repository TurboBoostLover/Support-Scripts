USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14343';
DECLARE @Comments nvarchar(Max) = 
	'Deleted bad data from program "Asian and Asian American Studies" (2181)';
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
DECLARE @PSI TABLE (Id int)
INSERT INTO @PSI
SELECT ps.Id FROM ProgramSequence AS ps
WHERE CourseId in (
	SELECT c.Id FROM Course AS C
	INNER JOIN Subject AS s on c.SubjectId = s.Id
	WHERE c.CourseNumber = '045B'
	AND s.SubjectCode = 'ASAME'
)
AND ProgramId = 2181

DELETE FROM ProgramSequenceDetail
WHERE ProgramSequenceId in (
	SELECT Id FROM @PSI
)


DELETE FROM ProgramOutcomeMatching
WHERE ProgramSequenceId in (
	SELECT Id FROM @PSI
)

DELETE FROM ProgramSequence
WHERE CourseId in (
	SELECT c.Id FROM Course AS C
	INNER JOIN Subject AS s on c.SubjectId = s.Id
	WHERE c.CourseNumber = '045B'
	AND s.SubjectCode = 'ASAME'
)
AND ProgramId = 2181