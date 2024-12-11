USE [aurak];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17781';
DECLARE @Comments nvarchar(Max) = 
	'Lock Down CLO Tab to new position called "CLO Advisor"';
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
INSERT INTO Position
(Title, Active, ClientId, FilterSubject, PositionTypeId, HasAgendaReport, CanEditInReview, IsGlobal, CanCensorComments, CrossListingAdmin, CrossListingNotification, CanAttachInReview, PublishNotification)
VALUES
('CLO Advisor', 1, 1, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0)

DECLARE @Id int = SCOPE_IDENTITY()

DECLARE @Sections INTEGERS
INSERT INTO @Sections
SELECT MetaSelectedSectionId FROM MetaSelectedSection WHERE MetaBaseSchemaId = 449
UNION
SELECT MetaSelectedSectionId FROM MetaSelectedSection AS mss
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mss.MetaBaseSchemaId = 105
and mtt.IsPresentationView = 0
and mtt.MetaTemplateTypeId = 1

INSERT INTO EditMap
Default VALUES

DECLARE @Id2 int = SCOPE_IDENTITY()

INSERT INTO EditMapStatus
(EditMapId, StatusAliasId, PositionId, RoleId)
VALUES
(@Id2, 1,@Id, NULL),
(@Id2, 2,@Id, NULL),
(@Id2, 3,@Id, NULL),
(@Id2, 4,@Id, NULL),
(@Id2, 5,@Id, NULL),
(@Id2, 6,@Id, NULL),
(@Id2, 7,@Id, NULL),
(@Id2, 8,@Id, NULL),
(@Id2, 9,@Id, NULL)

UPDATE MetaSelectedSection
SET EditMapId = @Id2
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

UPDATE MetaSelectedField
SET EditMapId = @Id2
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.IsPresentationView = 0
and mtt.MetaTemplateTypeId = 1
and msf.MetaAvailableFieldId = 530

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MEtaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 1
)