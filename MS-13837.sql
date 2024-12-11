USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13837';
DECLARE @Comments nvarchar(Max) = 
	'Update Literal DropDowns';
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
DECLARE @Templates TABLE (TId int, FId int, FMA int)
INSERT INTO @Templates (TId, FId, FMA)
SELECT mt.MetaTemplateId, Msf.MetaSelectedFieldId, msf.MetaAvailableFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE msf.MetaPresentationTypeId = 101

DECLARE @MAXID int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, LookupLoadTimingType)
VALUES
(@MAXID, 'CourseRequisite', 'Id', 'Title', 'SELECT Id AS Value, Code AS Text FROM SpecialCharacter WHERE Code = ''(''', 'select Id as Value, Code as Text from SpecialCharacter Where id = @id', 1),
(@MAXID + 1, 'CourseRequisite', 'Id', 'Title', 'SELECT Id AS Value, Code AS Text FROM SpecialCharacter WHERE Code = '')''', 'select Id as Value, Code as Text from SpecialCharacter Where id = @id', 1)	

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 7700
,MetaForeignKeyLookupSourceId = @MAXID
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2088)	--FMA is MetaAvailable Field

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 7701
, MetaForeignKeyLookupSourceId = @MAXID + 1
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2751)	--FMA is MetaAvailable Field

DECLARE @TABLE TABLE (Id int, dropdown int)
INSERT INTO @TABLE
SELECT Id, 
	CASE 
		WHEN HealthText = '(' THEN 11
		ELSE NULL
	END
FROM CourseRequisite
WHERE HealthText IS NOT NULL

DECLARE @TABLE2 TABLE (Id int, dropdown2 int)
INSERT INTO @TABLE2
SELECT Id, 
	CASE 
		WHEN Parenthesis = ')' THEN 12
		ELSE NULL
	END
FROM CourseRequisite
WHERE Parenthesis IS NOT NULL

UPDATE CourseRequisite
SET OpenParen_SpecialCharacterId = t.dropdown
FROM @TABLE AS t
WHERE CourseRequisite.Id = t.Id

UPDATE CourseRequisite
SET CloseParen_SpecialCharacterId = t.dropdown2
FROM @TABLE2 AS t
WHERE CourseRequisite.Id = t.Id

DELETE FROM MetaLiteralList
WHERE MetaSelectedFieldId in (Select FId FROM @Templates)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT TId FROM @Templates
)