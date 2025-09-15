USE [madera];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19844';
DECLARE @Comments nvarchar(Max) = 
	'Update EntityTitle for Courses';
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
DECLARE @Templates INTEGERS
INSERT INTO @Templates
SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = 1

UPDATE MetaTemplate
SET EntityTitleTemplateString = '[0] [1] - [2]'
, PublicEntityTitleTemplateString = '[0] [1] - [2]'
WHERE MetaTemplateId in (
	SELECT Id FROM @Templates
)

DELETE FROM MetaTitleFields
WHERE MetaTemplateId in (
	SELECT Id FROM @Templates
)

INSERT INTO MetaTitleFields
(MetaTemplateId, MetaSelectedFieldId, Ordinal)
SELECT t.Id, msf.MetaSelectedFieldId, 0 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Templates AS t on mss.MetaTemplateId = t.Id
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 873
and mss2.SectionName = 'General Information'
UNION
SELECT t.Id, msf.MetaSelectedFieldId, 1 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN @Templates AS t on mss.MetaTemplateId = t.Id
WHERE msf.MetaAvailableFieldId = 888
and mss2.SectionName = 'General Information'
UNION
SELECT t.Id, msf.MetaSelectedFieldId, 2 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN @Templates AS t on mss.MetaTemplateId = t.Id
WHERE msf.MetaAvailableFieldId = 872
and mss2.SectionName = 'General Information'

DECLARE @Courses TABLE (Id int, TempId int)
INSERT INTO @Courses
SELECT Id, MetaTemplateId FROM Course
WHERE MetaTemplateId in (
	SELECT Id FROM @Templates
)

while exists(select top 1 1 from @Courses)
begin
		declare @Course int = (SELECT top 1 Id FROM @Courses)
    declare @TID int = (select TempId from @Courses WHERE Id = @Course)
    EXEC upCreateEntityTitle @entityTypeId = 1, @EntityId = @Course, @metaTemplateId = @TID
    delete @Courses
    where id = @Course
end