USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18603';
DECLARE @Comments nvarchar(Max) = 
	'Update tab for MC on program review to be editable in review by workflow users';
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
--Program Review
--Program Review Annual Program Update

DECLARE @FieldsToEditMap TABLE (FieldId int, Id int Identity)
INSERT INTO @FieldsToEditMap
SELECT MetaSelectedFieldId
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE MetaAvailableFieldId in (
	4974,
	4975,
	8588,
	4151,
	4068,
	1204,
	4069,
	1205,
	4070,
	4383,
	4071,
	1221,
	3881
)
and mt.MetaTemplateTypeId in (
	96, 95
)

DECLARE @SectionsToEditMap TABLE (SecId int, Id int Identity)
INSERT INTO @SectionsToEditMap
SELECT MetaSelectedSectionId
FROM MetaSelectedSection AS mss
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE MetaBaseSchemaId in (
	1898
)
and mt.MetaTemplateTypeId in (
	96, 95
)

INSERT INTO EditMap
DEFAULT VALUES

DECLARE @Id int = SCOPE_IDENTITY()

INSERT INTO EditMapStatus
(EditMapId, StatusAliasId, PositionId, RoleId)
VALUES
(@Id, 7, 174, NULL),
(@Id, 7, 172, NULL),
(@Id, 1, NULL, 1),
(@Id, 2, NULL, 1),
(@Id, 3, NULL, 1),
(@Id, 5, NULL, 1),
(@Id, 7, NULL, 1),
(@Id, 11, NULL, 1)

UPDATE MetaSelectedField
SET EditMapId = @Id
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @FieldsToEditMap
)

UPDATE MetaSelectedSection
SET EditMapId = @Id
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @SectionsToEditMap
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateTypeId in (
	96, 95
)