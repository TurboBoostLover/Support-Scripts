USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16503';
DECLARE @Comments nvarchar(Max) = 
	'set allow copy on all sections and fields on Instructional and Non-Instructional Program Reviews and make proposal types';
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

--This is done incase someone sets something to not copy before this script runs for some reason
DECLARE @SECTIONS INTEGERS
INSERT INTO @SECTIONS
SELECT Mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
INNER JOIN MetaTemplate aS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.MetaTemplateTypeId in (36, 37)
and mss.AllowCopy = 0

DECLARE @Fields INTEGERS
INSERT INTO @Fields
SELECT Msf.MetaSelectedFieldId FROM MetaSelectedField As msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate aS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.MetaTemplateTypeId in (36, 37)
and msf.AllowCopy = 0

DECLARE @Id TABLE (Id int, tit nvarchar(max))

INSERT INTO ProposalType
(ClientId, Title, EntityTypeId, ProcessActionTypeId, MetaTemplateTypeId, Active, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, CloneRequired, AllowDistrictClone, AllowCloning, HideProposalRequirementFields, AllowNonAdminReactivation)
output inserted.Id, inserted.Title INTO @Id
VALUES
(1, 'Modify Instructional PSR Annual Update', 6, 2, 36, 1, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0),
(1, 'Modify Non-Instructional PSR Annual Update', 6, 2, 37, 1, 0, 0, 0, 0, 0, 6, 0, 0, 0, 0, 0)

INSERT INTO ProcessProposalType
(ProposalTypeId, ProcessId)
SELECT Id, 36 FROM @Id WHERE tit = 'Modify Instructional PSR Annual Update'
UNION
SELECT Id, 37 FROM @Id WHERE tit = 'Modify Non-Instructional PSR Annual Update'