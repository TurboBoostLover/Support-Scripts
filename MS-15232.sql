USE [riohondo];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15232';
DECLARE @Comments nvarchar(Max) = 
	'Update NonCredit SLO Cousre Proposal to mainly only be admin only';
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
Declare @clientId int =6, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (433)		--comment back in if just doing some of the mtt's

DECLARE @Sections INTEGERS
INSERT INTO @Sections
SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection AS mss
INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
WHERE (mss.MetaBaseSchemaId <> 105 or mss.MetaBaseSchemaId IS NULL)
and mss.MetaSelectedSectionId not in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaAvailableFieldId = 871
	UNION
		SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
		INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
		WHERE msf.MetaAvailableFieldId in (892, 7344)
)

DECLARE @Fields INTEGERS
INSERT INTO @Fields
SELECT msf.MEtaSelectedFieldId fROM MetaSelectedField AS msf
INNER JOIN @Sections AS s on msf.MetaSelectedSectionId = s.Id
WHERE msf.MetaAvailableFieldId <> 871

INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, RoleId, AccessRestrictionType)
SELECT Id, 1, 2 FROM @Fields
UNION
SELECT Id, 4, 1 FROM @Fields

INSERT INTO MetaSelectedSectionRolePermission
(MetaSelectedSectionId, RoleId, AccessRestrictionType)
SELECT Id, 1, 2 FROM @Sections
UNION
SELECT Id, 4, 1 FROM @Sections

UPDATE MetaSelectedField
SET ReadOnly = 0
WHERE MetaSelectedFieldId in (
	SELECT ID FROM @Fields
)

UPDATE MetaSelectedSection
SET ReadOnly = 0
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Id FROM @templateId
)