USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15777';
DECLARE @Comments nvarchar(Max) = 
	'Update Entry Skills Tab';
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
DECLARE @Sections INTEGERS
INSERT INTO @Sections
SELECT MetaSelectedSectionId FROM MEtaSelectedSection WHERE MetaBaseSchemaId = 94

DECLARE @NESTEDSections INTEGERS
INSERT INTO @NESTEDSections
SELECT MetaSelectedSectionId FROM MEtaSelectedSection WHERE MetaSelectedSection_MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

DECLARE @TAB INTEGERS
INSERT INTO @TAB
SELECT MetaSelectedSection_MetaSelectedSectionId FROM MEtaSelectedSection WHERE MetaBaseSchemaId = 94

UPDATE MEtaSelectedSection
SET ReadOnly = 0
WHERE MEtaSelectedSectionId in (
	SELECT Id FROM @Sections
	UNION
	SELECT Id FROM @NESTEDSections
)

UPDATE MEtaSelectedSection
SET SectionDescription = 'Legacy data only. Not editable. Please enter information on content review page.'
, DisplaySectionDescription = 1
WHERE MEtaSelectedSectionId in (
	SELECT Id FROM @TAB
)

INSERT INTO MetaSelectedSectionRolePermission
(MetaSelectedSectionId, RoleId ,AccessRestrictionType)
SELECT Id, 1, 2 FROM @Sections
UNION
SELECT Id, 4, 1 FROM @Sections
UNION
SELECT Id, 1, 2 FROM @NESTEDSections
UNION
SELECT Id, 4, 1 FROM @NESTEDSections
UNION
SELECT Id, 1, 2 FROM @TAB
UNION
SELECT Id, 4, 1 FROM @TAB

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mss.MetaSelectedSectionId in (
		SELECT Id FROM @TAB
	)
)