USE [hancockcollege];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14635';
DECLARE @Comments nvarchar(Max) = 
	'Add Clone Proposal';
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
DECLARE @TABLE TABLE (Id int, Title NVARCHAR(MAX))

UPDATE ProposalType
SET AllowCloning = 0
WHERE AllowCloning = 1

INSERT INTO ProposalType
(ClientId, Title, EntityTypeId, ClientEntitySubTypeId, ProcessActionTypeId, MetaTemplateTypeId, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, CloneRequired, AllowDistrictClone, AllowCloning, HideProposalRequirementFields, AllowNonAdminReactivation)
output inserted.Id, inserted.Title INTO @TABLE
SELECT ClientId, 'Clone Program', EntityTypeId, ClientEntitySubTypeId, ProcessActionTypeId, MetaTemplateTypeId, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, 1, AllowDistrictClone, 1, HideProposalRequirementFields, AllowNonAdminReactivation FROM ProposalType WHERE Title = 'New Program' and Id = 1
UNION
SELECT ClientId, 'Clone Noncredit Course', EntityTypeId, ClientEntitySubTypeId, ProcessActionTypeId, MetaTemplateTypeId, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, 1, AllowDistrictClone, 1, HideProposalRequirementFields, AllowNonAdminReactivation FROM ProposalType WHERE Title = 'Noncredit New Course' and Id = 40
UNION
SELECT ClientId, 'Clone Credit Course', EntityTypeId, ClientEntitySubTypeId, ProcessActionTypeId, MetaTemplateTypeId, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, 1, AllowDistrictClone, 1, HideProposalRequirementFields, AllowNonAdminReactivation FROM ProposalType WHERE Title = 'New Course Proposal' and Id = 4

UPDATE config.ClientSetting
SET AllowCloning = 1
WHERE Id = 1

DECLARE @MAX int = (SELECT Id FROM @TABLE WHERE Title = 'Clone Program')
DECLARE @MAX2 int = (SELECT Id FROM @TABLE WHERE Title = 'Clone Noncredit Course')
DECLARE @MAX3 int = (SELECT Id FROM @TABLE WHERE Title = 'Clone Credit Course')

DECLARE @MAXID int = (SELECT ProcessId FROM ProcessProposalType WHERE ProposalTypeId = 1)
DECLARE @MAXID2 int = (SELECT ProcessId FROM ProcessProposalType WHERE ProposalTypeId = 40)
DECLARE @MAXID3 int = (SELECT ProcessId FROM ProcessProposalType WHERE ProposalTypeId = 4)

INSERT INTO ProcessProposalType
(ProposalTypeId, ProcessId)
VALUES
(@MAX, @MAXID),
(@MAX2, @MAXID2),
(@MAX3, @MAXID3)