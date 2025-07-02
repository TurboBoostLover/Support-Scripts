USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19322';
DECLARE @Comments nvarchar(Max) = 
	'Update Course and Program form to never have these fields copy over
	- Proposed Start Term
	- Catalog Publication Sequence
	-Publication Status
	-Change Reason
	';
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
UPDATE MetaSelectedField
SET AllowCopy = 0
WHERE MetaAvailableFieldId in (
1658,
2672,
3885,
4103,
7291,
8515,
8516,
12856,
2959,
586,
3882,
1259,
1260,
1198
)

DECLARE @FieldsToBlackList TABLE (FieldId int, Id int Identity)
INSERT INTO @FieldsToBlackList
SELECT MetaSelectedFieldId
FROM MetaSelectedField
WHERE MetaAvailableFieldId in (
1658,
2672,
3885,
4103,
7291,
8515,
8516,
12856,
2959,
586,
3882,
1259,
1260,
1198
)

DECLARE @Counting TABLE (Id int, FieldId int, Counting int Identity)
INSERT INTO @Counting
SELECT Id, FieldId FROM @FieldsToBlackList
--UNION
--SELECT Id FROM @SectionsToBlacklist

while exists(select top 1 Id from @Counting)
begin
    declare @TID int = (select top 1 Id from @Counting)
		declare @Field int = (SELECT FieldId FROM @Counting WHERE Id = @TID)
    
		INSERT INTO MetadataAttributeMap
		DEFAULT VALUES

		DECLARE @Id int = SCOPE_IDENTITY()

		INSERT INTO MetadataAttribute
		(Description, ValueText, MetadataAttributeTypeId, MetadataAttributeMapId, DataType)
		VALUES
		('Clone Blacklist', 'BlacklistDoNotClone', 20, @Id, 'Text')

		UPDATE MetaSelectedField
		SET MetadataAttributeMapId = @Id
		WHERE MetaSelectedFieldId = @Field

    delete @Counting
    where id = @TID
end

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId in (
1658,
2672,
3885,
4103,
7291,
8515,
8516,
12856,
2959,
586,
3882,
1259,
1260,
1198
)