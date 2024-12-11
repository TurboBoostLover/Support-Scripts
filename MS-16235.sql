USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16235';
DECLARE @Comments nvarchar(Max) = 
	'Fix their catalog as requested';
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
DECLARE @Sections TABLE (Id int)
INSERT INTO @Sections
SELECT Id FROM CatalogSection WHERE ModuleId = 17 and Title like '%Vocational%' and Title not like '%(%'

DECLARE @Sections2 TABLE (Id int)
INSERT INTO @Sections2
SELECT Id FROM CatalogSection WHERE ParentId in (
SELECT Id FROM @Sections
)

UPDATE CatalogSection
SET ParentId = 27869
WHERE Id in (
	SELECT Id FROM CatalogSection WHERE ParentId In (
		SELECT Id FROM @Sections2
	)
)

DELETE FROM CatalogSection
WHERE Id in (
	SELECT Id FROM @Sections2
)

DELETE FROM CatalogSection
WHERE Id in (
	SELECT Id FROM @Sections
)

update cs
set SortOrder = sorted.rownum 
output inserted.*
from CatalogSection cs
inner join ( 
select id, ROW_NUMBER() over (order by Title) rownum 
from CatalogSection WHERE ParentId = 27869
) sorted on cs.Id = sorted.Id
wHERE ParentId = 27869

DELETE FROM CatalogSection WHERE Id = 27870