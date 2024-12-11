USE [nukz];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16812';
DECLARE @Comments nvarchar(Max) = 
	'Update Requirements on modification and deactivation forms';
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
DECLARE @CourseFields TABLE (id int, SecId int, TemplateId int)
INSERT INTO @CourseFields
SELECT MetaSelectedFieldId, mss.MetaSelectedSectionId, mt.MetaTemplateId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType As mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE MetaAvailableFieldId in (871, 1776)
and MetaPresentationTypeId = 25 
and mtt.MetaTemplateTypeId in (21, 22, 26)
and DisplayName IS NULL
and mt.Active = 1

UPDATE MetaSelectedField 
SET IsRequired = 1
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @CourseFields
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
		SELECT TemplateId FROM @CourseFields
)

DECLARE @ProgramFields TABLE (Id int, SecId int, TemplateId int)
INSERT INTO @ProgramFields
SELECT MetaSelectedFieldId, msf.MetaSelectedSectionId, mt.MetaTemplateId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType As mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE MetaAvailableFieldId in (2225, 2231)
and MetaPresentationTypeId = 25
and mtt.MetaTemplateTypeId in (23, 24, 25)
and mt.Active = 1

UPDATE MetaSelectedField 
SET IsRequired = 1
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @ProgramFields
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT TemplateId FROM @ProgramFields
)
