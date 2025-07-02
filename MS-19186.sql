USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19186';
DECLARE @Comments nvarchar(Max) = 
	'Fix Look up';
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
INSERT INTO ItemType
(Title, ItemTableName, SortOrder, StartDate, ClientId)
VALUES
('New certification', 'ProgramLookup01', 12, GETDATE(), 1),
('Title change', 'ProgramLookup01', 12, GETDATE(), 1),
('Articulation(s)', 'ProgramLookup01', 12, GETDATE(), 1)

DECLARE @New int = (SELECT Id FROM ItemType WHERE Title = 'New certification' and ItemTableName = 'ProgramLookup01' and Description IS NULL)
DECLARE @Title int = (SELECT Id FROM ItemType WHERE Title = 'Title change' and ItemTableName = 'ProgramLookup01' and Description IS NULL)
DECLARE @Art int = (SELECT Id FROM ItemType WHERE Title = 'Articulation(s)' and ItemTableName = 'ProgramLookup01' and Description IS NULL)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
select Id as Value, Title as Text from ItemType
where Active = 1 
AND ItemTableName = ''ProgramLookup01''
and (Description <> ''Industry'' or Description IS NULL)
Order By SortOrder
'
WHERE Id = 132

UPDATE ProgramLookup01
SET ItemTypeId = 
CASE
	WHEN Id = 13 THEN @New
	WHEN Id = 14 THEN @Title
	WHEN Id = 15 THEN 2
	WHEN Id = 16 THEN 7
	WHEN Id = 17 THEN @Art
	WHEN Id = 18 THEN 9
	ELSE ItemTypeId
END
WHERE ProgramId not in (
	SELECT Id FROM Program AS p
	INNER JOIN MetaTemplate AS mt on p.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = 30
)
and ItemTypeId in (
	13,
	14,
	15,
	16,
	17,
	18
)

update it 
set SortOrder = sorted.rownum 
from ItemType it
inner join ( 
select id, ROW_NUMBER() over (order by Title) rownum 
from ItemType
WHERE ItemTableName = 'ProgramLookup01'
and Title <> 'Other'
) sorted on it.Id = sorted.Id

UPDATE ItemType
SET SortOrder = 18
WHERE Id = 9

UPDATE ItemType
SET SortOrder = 19
WHERE Id = 18

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 132