USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15836';
DECLARE @Comments nvarchar(Max) = 
	'Update back schema';
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
UPDATE MetaSelectedField
SET MetaAvailableFieldId = 3573
WHERE MetaAvailableFieldId = 107

UPDATE MetaForeignKeyCriteriaClient 
SET LookupLoadTimingType = 2
WHERE Id = 3

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('DECLARE @entryCount integers 
INSERT INTO @entryCount
    SELECT Id
    FROM CourseRequisite
    WHERE CourseId = @entityId
		and Requisite_CourseId IS NOT NULL
		and RequisiteTypeId in (1, 2, 3)

DELETE FROM @entryCount
WHERE Id in (
	SELECT CourseRequisiteId
	FROM CourseContentReview
	WHERE CourseId = @EntityId
)

SELECT CAST(CASE WHEN (SELECT * FROM @entryCount) IS NULL THEN 1 ELSE 0 END AS bit) AS IsValidCount;', 1)

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT mss.MetaSelectedSectionId, 'Content Review', 'every course that is a pre or coreq', 6, 'Must select each course that is listed as a pre or corequisite on the Requisites tab.', @ID
FROM MetaSelectedSection AS mss
WHERE mss.MetaBaseSchemaId = 86
and mss.SectionName = 'Content Review'

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaAvailableFieldId = 3573
	UNION
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 3
	UNION
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	WHERE mss.MetaBaseSchemaId = 86
and mss.SectionName = 'Content Review'
)