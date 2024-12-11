USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16660';
DECLARE @Comments nvarchar(Max) = 
	'Delete Bad Data';
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
DECLARE @Valid INTEGERS
INSERT INTO @Valid
select pc.Id as Value from ProgramCourse pc
left join CourseOption co on pc.CourseOptionId = co.Id
left join Program p on co.ProgramId = p.Id 
inner join Course c on pc.CourseId = c.Id 
inner join Subject s on c.SubjectId = s.Id 
where co.IsCore = 1 
and p.Id = 25149

DECLARE @Valid2 INTEGERS
INSERT INTO @Valid2
SELECT DISTINCT ProgramCourseId FROM ProgramOutcomeMatching WHERE ProgramOutcomeId in (
	SELECT Id FROM ProgramOutcome WHERE ProgramId = 25149
)

DECLARE @BAD INTEGERS
INSERT INTO @BAD
SELECT Id FROM @Valid2
WHERE Id not in (
	SELECT Id FROM @Valid
)

DELETE FROM ProgramOutcomeCheckbox WHERE ProgramOutcomeMatchingId in (
SELECT Id FROM ProgramOutcomeMatching WHERE ProgramCourseId in (
	SELECT Id FROM @BAD
	)
)

DELETE FROM ProgramOutcomeMatching
WHERE ID in (
SELECT Id FROM ProgramOutcomeMatching WHERE ProgramCourseId in (
	SELECT Id FROM @BAD
	)
)