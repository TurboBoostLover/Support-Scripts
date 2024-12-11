USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16309';
DECLARE @Comments nvarchar(Max) = 
	'Add Validation to prevent launching anything';
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
DECLARE @Sections TABLE (
    MetaSelectedSectionId INT
);

WITH LowestRowPosition AS (
    SELECT 
        mss.MetaSelectedSectionId,
        mss.MetaTemplateId,
        mss.RowPosition,
        ROW_NUMBER() OVER (PARTITION BY mss.MetaTemplateId ORDER BY mss.RowPosition ASC) AS rn
    FROM MetaSelectedSection AS mss
    INNER JOIN MetaTemplate AS mt ON mss.MetaTemplateId = mt.MetaTemplateId
    INNER JOIN MetaTemplateType AS mtt ON mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
		WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
)
INSERT INTO @Sections (MetaSelectedSectionId)
SELECT 
    MetaSelectedSectionId 
FROM 
    LowestRowPosition 
WHERE 
    rn = 1;

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('select 0', 1)

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT MetaSelectedSectionId, 'No Launching right now', 6, 'Launching is disabled for the time being per request of Las Positas Team.', @ID FROM @Sections

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MEtaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN @Sections As s on mss.MetaSelectedSectionId = s.MetaSelectedSectionId
)