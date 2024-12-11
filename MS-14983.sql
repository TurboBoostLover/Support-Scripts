USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14983';
DECLARE @Comments nvarchar(Max) = 
	'Remove Static Text';
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
DECLARE @entityTypeId int = 1
DECLARE @clientId int =1 -- SELECT Id, Title FROM Client 

DECLARE @Sections TABLE (Sec int, mt int, field int)
INSERT INTO @Sections
SELECT mss.MetaSelectedSectionId, mss.MetaTemplateId, msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType As mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE MetaAvailableFieldId IS NULL
AND DisplayName like '%Does this course meet any of the following characteristics?%'
AND DefaultDisplayType = 'StaticText'
AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId


DELETE FROM MetaSelectedField WHERE MetaSelectedFieldId in (
	SELECT Field FROM @Sections
)

DELETE FROM MetaSelectedSection WHERE MetaSelectedSectionId in (
	SELECT Sec FROM @Sections
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt FROM @Sections
)