USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18208';
DECLARE @Comments nvarchar(Max) = 
	'Fix Program Recviews';
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
UPDATE MetaSelectedSection 
SET MetaBaseSchemaId = 1384
WHERE MetaSectionTypeId = 14 
and MetaBaseSchemaId IS NULL


UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'SELECt lu6.id as Value, lu6.ShortText As Text 
FROM Lookup06 lu6
WHERE lu6.Lookup06ParentId = (select id from Lookup06 where ShortText =''Validation PR Laney'')
	and lu6.ShortText in (''Assessment'', ''Curriculum'', ''Program Overview'', ''Mission Statement/Strategic Goals'')
Order by SortOrder
'
WHERE Id = 969

UPDATE MetaSelectedSection
SET AllowCopy = 0
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 42
	and mss.MetaBaseSchemaId = 1898
)

DELETE FROM ModuleLookup06 WHERE Lookup06Id IS NULL and PreviousId IS NOT NULL and ModuleId in (
	SELECT Id FROM Module WHERE MetaTemplateId = (SELECT mt.MEtaTemplateID fROM MetaTemplate AS mt WHERE mt.MetaTemplateTypeId = 42 and ACtive = 1 and EndDate IS NULL)
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MEtaTemplateId FROM MetaSelectedSection as mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 969
)