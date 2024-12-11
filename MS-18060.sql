USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18060';
DECLARE @Comments nvarchar(Max) = 
	'Update Data to copy over from Initial Program to Detailed Program correctly';
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
DECLARE @mt int = (
SELECT mt.MetaTemplateID 
FROM MetaTemplate AS mt
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE Mtt.MetaTemplateTypeId = 16
and mt.EndDate IS NULL
)

DECLARE @Sections INTEGERS
INSERT INTO @Sections
SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss WHERE mss.MetaTemplateId = @mt

DECLARE @Fields INTEGERS
INSERT INTO @Fields
SELECT msf.MEtaSelectedFieldId FROM MetaSelectedField AS msf INNER JOIN @Sections AS s on msf.MetaSelectedSectionId = s.Id
WHERE msf.MetaAvailableFieldId not in (1367, 1214)

DECLARE @Fields2 INTEGERS
INSERT INTO @Fields2
SELECT msf.MEtaSelectedFieldId FROM MetaSelectedField AS msf INNER JOIN @Sections AS s on msf.MetaSelectedSectionId = s.Id
WHERE msf.MetaAvailableFieldId in (1367, 1214)

UPDATE MetaSelectedSection
SET AllowCopy = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

UPDATE MetaSelectedField
SET AllowCopy = 1
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @Fields
)

UPDATE MetaSelectedField
SET AllowCopy = 0
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @Fields2
)

DECLARE @mt2 int = (
SELECT mt.MetaTemplateID 
FROM MetaTemplate AS mt
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE Mtt.MetaTemplateTypeId = 2
and mt.EndDate IS NULL
and mt.IsDraft = 0
)

DECLARE @Sections2 INTEGERS
INSERT INTO @Sections2
SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss WHERE mss.MetaTemplateId = @mt2

DECLARE @Fields3 INTEGERS
INSERT INTO @Fields3
SELECT msf.MEtaSelectedFieldId FROM MetaSelectedField AS msf INNER JOIN @Sections2 AS s on msf.MetaSelectedSectionId = s.Id
WHERE msf.MetaAvailableFieldId not in (1367, 1214)

DECLARE @Fields4 INTEGERS
INSERT INTO @Fields4
SELECT msf.MEtaSelectedFieldId FROM MetaSelectedField AS msf INNER JOIN @Sections2 AS s on msf.MetaSelectedSectionId = s.Id
WHERE msf.MetaAvailableFieldId in (1367, 1214)

UPDATE MetaSelectedSection
SET AllowCopy = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections2
)

UPDATE MetaSelectedField
SET AllowCopy = 1
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @Fields3
)

UPDATE MetaSelectedField
SET AllowCopy = 0
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @Fields4
)

UPDATE MetaSelectedSection 
SET SectionDescription = 'Upon completion of the Programme, students will be able to:'
WHERE MetaBaseSchemaId = 160

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (@mt)
or MetaTemplateId in (
	SELECT MetaTemplateId FROM MetaSelectedSection WHERE MetaBaseSchemaId = 160
)