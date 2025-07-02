USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18954';
DECLARE @Comments nvarchar(Max) = 
	'Fix test data';
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
UPDATE Program
SET Title = 'test title'
WHERE Active = 1
and Title IS NULL

DECLARE @Templates INTEGERS
INSERT INTO @Templates
SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = 2
and EntityTitleTemplateString IS NULL

UPDATE MetaTemplate
SET EntityTitleTemplateString = '[0]'
WHERE MetaTemplateId in (
	SELECT Id FROM @Templates
)

INSERT INTO MetaTitleFields
(MetaTemplateId, MetaSelectedFieldId, Ordinal)
SELECT Id, MetaSelectedFieldId, 0 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Templates AS t on mss.MetaTemplateId = t.Id
WHERE msf.MetaAvailableFieldId = 1225

DECLARE @Updates TABLE (TempId int, EntityId int)
INSERT INTO @Updates
SELECT MetaTemplateId, Id FROM Program WHERE Active = 1 and EntityTitle IS NULL

while exists(select top 1 1 from @Updates)
begin
    declare @Entity int = (SELECT TOP 1 EntityId FROM @Updates)
		declare @Temp int = (select TempId from @Updates WHERE EntityId = @Entity)
    exec upCreateEntityTitle @EntityTypeId = 2, @MetaTemplateId = @Temp, @EntityId = @Entity
    delete @Updates
    where EntityId = @Entity
end