USE [fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18214';
DECLARE @Comments nvarchar(Max) = 
	'Create New Proposal Titles';
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
UPDATE MetaTemplate
SET EntityTitleTemplateString = '[0]-[1]-[2]-[3]'
, PublicEntityTitleTemplateString = '[0]-[1]-[2]-[3]'
WHERE MetaTemplateId = 16

DELETE FROM MetaTitleFields WHERE MetaTemplateId = 16

INSERT INTO MetaTitleFields
(MetaTemplateId, MetaSelectedFieldId, Ordinal)
SELECT mss.MEtaTemplateId, msf.MetaSelectedFieldId, 0 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mss.MetaTemplateId = 16
and msf.MetaAvailableFieldId = 4122
UNION
SELECT mss.MEtaTemplateId, msf.MetaSelectedFieldId, 1 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mss.MetaTemplateId = 16
and msf.MetaAvailableFieldId = 4123
UNION
SELECT mss.MEtaTemplateId, msf.MetaSelectedFieldId, 2 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mss.MetaTemplateId = 16
and msf.MetaAvailableFieldId = 4117
UNION
SELECT mss.MEtaTemplateId, msf.MetaSelectedFieldId, 3 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mss.MetaTemplateId = 16
and msf.MetaAvailableFieldId = 6812

DECLARE @Courses TABLE (Id int, TempId int)
INSERT INTO @Courses
SELECT Id, MetaTemplateId FROM Module WHERE MetaTemplateId in (16) and Active = 1

UPDATE MetaForeignKeyCriteriaClient
SET ResolutionSql = '
SELECT Id AS Value, CONCAT(''('',SubjectCode,'') '', Title) AS Text FROM Subject WHERE Id = @Id
'
WHERE Id = 210

UPDATE MetaForeignKeyCriteriaClient
sET ResolutionSql = 'SELECT DISTINCT oe.Id as Value, oe.Title As Text 
FROM ModuleDetail md
	INNER JOIN OrganizationLink ol ON ol.Parent_OrganizationEntityId = md.Tier1_OrganizationEntityId
	INNER JOIN OrganizationEntity oe ON oe.Id = ol.Child_OrganizationEntityId
WHERE oe.Id = 21'
WHERE Id = 121

while exists(select top 1 Id from @Courses)
begin
    declare @TID int = (select top 1 Id from @Courses)
		declare @Temp int = (SELECT TempId FROM @Courses WHERE Id = @TID)
    exec upCreateEntityTitle @EntityTypeId = 6, @EntityId = @TID, @MetaTemplateId = @Temp
    delete @Courses
    where id = @TID
end