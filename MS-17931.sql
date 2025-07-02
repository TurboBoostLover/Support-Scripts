USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17931';
DECLARE @Comments nvarchar(Max) = 
	'Update Field and Section names and descriptions';
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
DECLARE @Fields INTEGERS

UPDATE MetaSelectedField 
SET DisplayName = REPLACE (DisplayName, 'Specializations', 'Specialisations')
output inserted.MetaSelectedFieldId INTO @Fields
WHERE LabelVisible = 1 and DisplayName like '%Specializations%'

UPDATE MetaSelectedField 
SET DisplayName = REPLACE (DisplayName, 'Specialization', 'Specialisation')
output inserted.MetaSelectedFieldId INTO @Fields
WHERE LabelVisible = 1 and DisplayName like '%Specialization%'

UPDATE MetaSelectedSection
SET SectionName = REPLACE (SectionName, 'Specialization', 'Specialisation')
WHERE SectionName like '%Specialization%'

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Fields AS f on msf.MetaSelectedFieldId = f.Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mss.MetaBaseSchemaId in (3684, 7134)