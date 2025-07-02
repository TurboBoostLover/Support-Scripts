USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19068';
DECLARE @Comments nvarchar(Max) = 
	'Fix Field and Section Order';
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
DECLARE @FieldId INT, @SectionId INT, @RowPos INT;

-- Cursor to iterate over fields that have ColPosition = 1
DECLARE FieldCursor CURSOR FOR
SELECT MetaSelectedFieldId, MetaSelectedSectionId, RowPosition
FROM MetaSelectedField
WHERE ColPosition = 1
ORDER BY RowPosition;  -- Ensures proper processing order

OPEN FieldCursor;
FETCH NEXT FROM FieldCursor INTO @FieldId, @SectionId, @RowPos;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Step 1: Update the specific field's ColPosition to 0 and RowPosition +1
    UPDATE MetaSelectedField
    SET ColPosition = 0, RowPosition = @RowPos + 1
    WHERE MetaSelectedFieldId = @FieldId;

    -- Step 2: Update all other fields in the same section with RowPosition >= @RowPos
    UPDATE MetaSelectedField
    SET RowPosition = RowPosition + 1
    WHERE MetaSelectedSectionId = @SectionId 
      AND MetaSelectedFieldId <> @FieldId
      AND RowPosition > @RowPos;

		UPDATE MetaSelectedSection
		SET RowPosition = RowPosition + 1
		, SortOrder = SortOrder + 1
		WHERE MetaSelectedSection_MetaSelectedSectionId = @SectionId
		AND RowPosition > @RowPos

    -- Fetch the next field
    FETCH NEXT FROM FieldCursor INTO @FieldId, @SectionId, @RowPos;
END

-- Clean up
CLOSE FieldCursor;
DEALLOCATE FieldCursor;

DECLARE @SectionswithFields TABLE (MaxSort INT, SecId INT);
INSERT INTO @SectionswithFields
SELECT MAX(RowPosition) AS MaxSort, MetaSelectedSectionId AS SecId
FROM MetaSelectedField
GROUP BY MetaSelectedSectionId;

WITH OrderedSubsections AS (
    SELECT 
        mss.MetaSelectedSectionId,
        ROW_NUMBER() OVER (PARTITION BY s.SecId ORDER BY mss.SortOrder) AS NewOrder,
        s.MaxSort
    FROM 
        MetaSelectedSection AS mss
    INNER JOIN 
        @SectionswithFields AS s 
    ON 
        mss.MetaSelectedSection_MetaSelectedSectionId = s.SecId
)
UPDATE mss
SET 
    SortOrder = oss.MaxSort + oss.NewOrder,
    RowPosition = oss.MaxSort + oss.NewOrder
FROM 
    MetaSelectedSection AS mss
INNER JOIN 
    OrderedSubsections AS oss
ON 
    mss.MetaSelectedSectionId = oss.MetaSelectedSectionId;

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE 1 = 1
--This fixes all ordering when they went to Maverick that was not handeled at the time as there was no Generic Maverick Script I had written at that time