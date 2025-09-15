USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19993';
DECLARE @Comments nvarchar(Max) = 
	'Make every field required on Unit/Hours tab on New Course';
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
;WITH SectionHierarchy AS (
    -- Anchor: start with all sections named "Units/Hours"
    SELECT 
        mss.MetaSelectedSectionId,
        mss.MetaSelectedSection_MetaSelectedSectionId,
        mss.SectionName,
        mss.MetaTemplateId
    FROM MetaSelectedSection mss
    WHERE mss.SectionName = 'Units/Hours'

    UNION ALL

    -- Recursive: pull children of those sections
    SELECT 
        child.MetaSelectedSectionId,
        child.MetaSelectedSection_MetaSelectedSectionId,
        child.SectionName,
        child.MetaTemplateId
    FROM MetaSelectedSection child
    INNER JOIN SectionHierarchy parent
        ON child.MetaSelectedSection_MetaSelectedSectionId = parent.MetaSelectedSectionId
)
UPDATE msf
SET msf.IsRequired = 1
FROM MetaSelectedField msf
INNER JOIN SectionHierarchy sh 
    ON msf.MetaSelectedSectionId = sh.MetaSelectedSectionId
INNER JOIN MetaTemplate mt 
    ON sh.MetaTemplateId = mt.MetaTemplateId
WHERE mt.Active = 1
  AND mt.EndDate IS NULL
  AND mt.MetaTemplateTypeId in (1, 25)
	AND msf.MetaAvailableFieldId IS NOT NULL
	AND msf.MetaPresentationTypeId <> 5
	AND msf.ReadOnly <> 1
	AND msf.MetaSelectedFieldId not in (
		SELECT MetaSelectedFieldId FROM MetaFieldFormula
	);

-- Touch the MetaTemplate's LastUpdatedDate
UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateTypeId in (1, 25)
  AND Active = 1
  AND EndDate IS NULL;
