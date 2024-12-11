USE [cuesta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15311';
DECLARE @Comments nvarchar(Max) = 
	'Move PHIL 208 ID=8681 back into review';
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
declare @inReview int = (select Id from StatusAlias where StatusBaseId = 6)
declare @Active int = (select Id from StatusAlias where StatusBaseId = 1)

update Course
set StatusAliasId = @inReview
where id = 8681

UPDATE Course
SET StatusAliasId = @Active
WHERE Id = 8567

update Proposal
set IsImplemented = 0,
ImplementDate = null,
ProposalComplete = 0
where id in (
    select ProposalId
    from Course
    where id = 8681
)

UPDATE BaseCourse
SET ActiveCourseId = 8567
WHERE Id = 1372

UPDATE ProcessLevelActionHistory
SET LevelActionResultTypeId = 1
, ResultDate = NULL
WHERE Id = 25577

DELETE FROM ProcessStepActionHistory
WHERE Id = 51192