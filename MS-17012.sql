USE [victorvalley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17012';
DECLARE @Comments nvarchar(Max) = 
	'Update Course DE form';
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
SELECT mss.MetaSelectedSectionId FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE Mtt.MetaTemplateTypeId = 11
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate IS NULL
and mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
and mss.SectionName not in ('Basic Course Information', 'Co-Contributor(s)', 'Distance Education')
UNION
SELECT mss2.MetaSelectedSectionId FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE Mtt.MetaTemplateTypeId = 11
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate IS NULL
and mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
and mss.SectionName not in ('Basic Course Information', 'Co-Contributor(s)', 'Distance Education')
UNION
SELECT mss3.MetaSelectedSectionId FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss3 on mss3.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE Mtt.MetaTemplateTypeId = 11
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate IS NULL
and mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
and mss.SectionName not in ('Basic Course Information', 'Co-Contributor(s)', 'Distance Education')
UNION
SELECT mss4.MetaSelectedSectionId FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss3 on mss3.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss4 on mss4.MetaSelectedSection_MetaSelectedSectionId = mss3.MetaSelectedSectionId
WHERE Mtt.MetaTemplateTypeId = 11
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate IS NULL
and mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
and mss.SectionName not in ('Basic Course Information', 'Co-Contributor(s)', 'Distance Education')

DECLARE @Fields INTEGERS
INSERT INTO @Fields
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

DELETE FROM MetaControlAttribute WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

DELETE FROM MetaSelectedSectionSetting WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

UPDATE MetaSelectedSection
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

UPDATE MetaSelectedField
SET ReadOnly = 1, IsRequired = 0
WHERE MetaSelectedFieldId in (
		SELECT Id FROM @Fields
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplateType AS mtt
	INNER JOIN MetaTemplate AS mt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE Mtt.MetaTemplateTypeId = 11
	and mt.Active = 1
	and mt.IsDraft = 0
	and mt.EndDate IS NULL
)