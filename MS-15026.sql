USE [evc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15026';
DECLARE @Comments nvarchar(Max) = 
	'Update Query Text to include faculty cost';
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
Please do not alter the script above this comment� except to set
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
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @TABLE TABLE (id int, Text NVARCHAR(MAX))
INSERT INTO @TABLE
SELECT 1 AS Value ,
(CONCAT(''<u>'',lu.Title,''</u><br>'', ''Total Amount Requested:'', Coalesce( SUM(Int02), 0),''<br>Ongoing Cost: '', Coalesce(SUM(Int01), 0),''<br>'')) AS Text
FROM GenericOrderedList03 gol
	INNER JOIN Lookup14 lu ON lu.Id = gol.Lookup14Id
WHERE ModuleId = @entityId
Group BY Title
UNION
SELECT 0 AS Value,
CONCAT(''<u>'', it.title, ''</u><br>'', ''Total Amount Requested:'',  Coalesce( SUM(mra.Int01), 0)) AS Text
FROM ModuleResourceAllocation AS mra
INNER JOIN ItemType AS it on mra.ItemTypeId = it.Id
WHERE mra.ModuleId = @entityId
Group BY it.Title

SELECT 0 AS Value,
dbo.ConcatWithSep_Agg(''<br>'', text) AS Text
FROM @TABLE
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 78

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MEtaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mt.MetaTemplateId = mss.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 78
)