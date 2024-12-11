USE [butte];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17120';
DECLARE @Comments nvarchar(Max) = 
	'Update Requirements on course forms';
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
SELECT DISTINCT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
INNER JOIN MetaSelectedSectionSetting AS msss on mss.MetaSelectedSectionId = msss.MetaSelectedSectionId
WHERE mss.ReadOnly = 1
and msf.ReadOnly = 1
and MinElem = 1
and msss.IsRequired = 1

DELETE FROM MetaSelectedSectionSetting WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN @Sections AS s on mss.MetaSelectedSectionId = s.Id
)

DECLARE @templateId INTEGERS
INSERT INTO @templateId
SELECT DISTINCT mss.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN @Sections AS s on mss.MetaSelectedSectionId = s.Id

while exists(select top 1 1 from @templateId)
begin
    declare @TID int = (select top 1 * from @templateId)
    exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = @TID, @entityId = null; --badge update
    delete @templateId
    where id = @TID
end