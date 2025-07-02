USE [cscc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19577';
DECLARE @Comments nvarchar(Max) = 
	'Add Reactivation for CSCC';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
INSERT INTO ProposalType
(ClientId, Title, EntityTypeId, ProcessActionTypeId, MetaTemplateTypeId, Active, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, CloneRequired, AllowDistrictClone, AllowCloning, HideProposalRequirementFields, AllowNonAdminReactivation)
VALUES
(1, 'Course Reactivation', 1, 2, 12, 1, 0, 1, 0, 1, 0, 1, 0, 0, 1, 0, 0)

DECLARE @ProposalType int = SCOPE_IDENTITY()

INSERT INTO ProcessProposalType
(ProposalTypeId, ProcessId)
VALUES
(@ProposalType, 27)

exec upGetUpdateClientSetting @setting = 'AllowReactivation', @newValue = 1, @clientId = 1, @valuedatatype = 'bit', @section = 'Curriqunet'

UPDATE ProposalType
SET AllowReactivation = 1
WHERE ProcessActionTypeId = 3
AND Active = 1
AND EntityTypeId IN (
	SELECT EntityTypeId 
	FROM ProposalType 
	WHERE AllowReactivation = 1
);