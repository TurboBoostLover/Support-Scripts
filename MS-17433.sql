USE [sjcc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17433';
DECLARE @Comments nvarchar(Max) = 
	'Fix a course Reactivation';
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
UPDATE ProposalType
SET AllowReactivation = 1
WHERE Id = 489

INSERT INTO ProposalType
(ClientId, Title, EntityTypeId, ProcessActionTypeId, MetaTemplateTypeId, DeletedBy_UserId, DeletedDate, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, CloneRequired, AllowDistrictClone, AllowCloning, HideProposalRequirementFields, AllowNonAdminReactivation, Active)
VALUES
(49, 'New Course', 1, 3, 468, 39202, GETDATE(), 0, 1, 0, 0, 0, 137, 0, 0, 1, 0, 0, 0)

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO ProcessProposalType
(ProposalTypeId, ProcessId)
VALUES
(@Id, 412)

DECLARE @Course TABLE (CourseId int, BaseId int)
INSERT INTO @Course
SELECT Id, BaseCourseId FROM Course WHERE ProposalTypeId = 475 and StatusAliasId = 616 and Active = 1

DECLARE @Course2 TABLE (CourseId int, BaseId int)
INSERT INTO @Course2
SELECT Id, BaseCourseId FROM Course WHERE ACtive = 1 and Id not in (
	SELECT CourseId FROM @Course
)

DECLARE @Course3 INTEGERS
INSERT INTO @Course3
SELECT CourseId FROM @Course WHERE BaseId not in (
	SELECT BaseID FROM @Course2
)

UPDATE Course
SET ProposalTypeId = @ID
WHERE Id in (
	SELECT Id FROM @Course3
)