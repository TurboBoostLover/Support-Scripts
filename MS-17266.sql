USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17266';
DECLARE @Comments nvarchar(Max) = 
	'Fix bad data from a courses that should be approved and Implements for Fall 2025';
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
UPDATE Course
SET StatusAliasId = 2
WHERE Id = 5369

UPDATE Proposal
SET ImplementDate = '2025-08-15 00:00:00.000'
WHERE Id in  (3501,3577, 3816, 4152, 4153, 4154, 4157, 4158, 4159, 4160, 4163, 4164, 4168, 4169, 4171, 4192, 4193, 4194, 4195, 4196, 4197, 4198, 4199, 4200, 4201, 4208, 4209)

DECLARE @Proposals TABLE (p int, id int)
INSERT INTO @Proposals
SELECT ProposalId, Id FROM ProcessLevelActionHistory where LevelActionResultTypeId = 1 AND ProposalId in (3501,3577, 3816, 4152, 4153, 4154, 4157, 4158, 4159, 4160, 4163, 4164, 4168, 4169, 4171, 4192, 4193, 4194, 4195, 4196, 4197, 4198, 4199, 4200, 4201, 4208, 4209,
3735, 3802, 4005, 4045, 4046, 4047, 4130, 4142, 4211, 4212, 4213, 4217, 4218
)

DECLARE @IDs INTEGERS

INSERT INTO ProcessLevelActionHistory
(ProposalId, CreatedDate, LevelActionResultTypeId, StepLevelId, ResultDate)
output inserted.Id INTO @IDs
SELECT P, GETDATE(), 2, 12, GETDATE() FROM @Proposals

INSERT INTO ProcessStepActionHistory
(CreatedDate, ProcessLevelActionHistoryId, StepId, WaitingForChanges, StepActionResultTypeId, ResultDate, UserId, Comments, ActionLevelRouteId)
SELECT GETDATE(), Id, 22, 0, 3, GETDATE(), 475, 'Clean Bad Data from V2 Import', 23 FROM @IDs

UPDATE ProcessLevelActionHistory
SET LevelActionResultTypeId = 2
WHERE Id in (
	SELECT Id FROM @Proposals
)