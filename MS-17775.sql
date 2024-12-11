USE [chabot];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17775';
DECLARE @Comments nvarchar(Max) = 
	'CB03 clean up from other tickets';
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
UPDATE CourseCBCode
SET CB03Id = 749
WHERE CB03Id = 512

UPDATE ProgramCBCode
SET CB03Id = 749
WHERE CB03Id = 512

UPDATE CB03ClientOverride
SET EndDate = GETDATE()
WHERE Id = 1

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
SELECT ccs. id as Value, CONCAT(ccs.code, '' - '', ccs.Title) As Text,map.CB03Id as FilterValue 
FROM CipCode_Seeded ccs
	INNER JOIN CipCode_SeededCB03Map map on ccs.id = map.CipCode_SeededId
WHERE map.CB03Id is not null
	and ccs.Active = 1
UNION
SELECT ccs. id as Value, CONCAT(ccs.code, '' - '', ccs.Title) as text,map.CB03Id as FilterValue 
FROM CipCode_Seeded ccs
	INNEr JOIN CourseSeededlookup csl on ccs.id = csl.CipCode_SeededId
		and csl.CourseId = @entityId
	INNER JOIN CipCode_SeededCB03Map map on ccs.id = map.CipCode_SeededId
UNION
SELECT ccs. id as Value, CONCAT(ccs.code, '' - '', ccs.Title) as text, 512 AS filterValue
FROM CipCode_Seeded ccs
	WHERE ccs.Id = 7127
ORDER BY Text
'
WHERE ID = 1057

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 1057
)