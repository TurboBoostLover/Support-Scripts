USE evc;

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14596';
DECLARE @Comments nvarchar(Max) = 
	'fix or remove nested checklist for Maverick';
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
DECLARE @TID TABLE (Id int)
INSERT INTO @TID
SELECT MetaTemplateId fROM MetaSelectedSection
WHERE MetaSectionTypeId = 19

DECLARE @TABLE TABLE (Id int)
INSERT INTO @TABLE
SELECT MetaSelectedSectionId FROM MetaSelectedSection
WHERE MetaSectionTypeId = 19
AND MetaBaseSchemaId = 939
AND MetaSelectedSectionId not in (
	SELECT mssa.MetaSelectedSectionId FROM MetaSelectedSectionAttribute AS mssa
	INNER JOIN MetaSelectedSection AS mss on mssa.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.MetaBaseSchemaId = 939
)

update MetaSelectedSection set MetaSectionTypeId = 3 where MetaSectionTypeId = 19

UPDATE MetaSelectedField 
SET RowPosition = 2
WHERE MetaAvailableFieldId = 528
AND EXISTS (
    SELECT 1
    FROM MetaSelectedField AS msf2
    INNER JOIN MetaSelectedSection AS mss ON msf2.MetaSelectedSectionId = mss.MetaSelectedSectionId				--this is to clean up bad data where fields are sharing the same rows
    WHERE msf2.MetaAvailableFieldId = 528
      AND msf2.RowPosition = MetaSelectedField.RowPosition
);

INSERT INTO MetaSelectedSectionAttribute 
(GroupId, AttributeTypeId, Name, Value, MetaSelectedSectionId)
SELECT 1, 1, 'ParentTable', 'CourseOutcome', Id FROM @TABLE
UNION
SELECT 1, 1, 'ForeignKeyToParent', 'CourseOutcomeId', Id FROM @TABLE			--CheckList needs attributes
UNION
SELECT 1, 1, 'LookupTable', 'ClientLearningOutcome', Id FROM @TABLE
UNION
SELECT 1, 1, 'ForeignKeyToLookup', 'ClientLearningOutcomeId', Id FROM @TABLE

UPDATE MetaTemplate
SET LastUpdatedDate = gETDATE()
WHERE MetaTemplateId in (
	SELECT Id fROM @TID
)

--SELECT * FROM Course WHERE MetaTemplateId in (
--811, 812, 813, 814, 815, 817
--)

--SELECT mss.SectionName, mss2.SectionName, mss3.SectionName, mss.MetaTemplateId, mssa.* fROM MetaSelectedSection as mss
--INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
--INNER JOIN MetaSelectedSection AS mss3 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss3.MetaSelectedSectionId
--INNER JOIN MetaSelectedSectionAttribute AS mssa ON mss2.MetaSelectedSectionId = mssa.MetaSelectedSectionId
--WHERE mss.MetaSectionTypeId = 19
--AND mss.MetaTemplateId = 812

--SELECT mss.SectionName, mss2.SectionName, mss3.SectionName, mss.MetaTemplateId, mssa.* fROM MetaSelectedSection as mss
--INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
--INNER JOIN MetaSelectedSection AS mss3 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss3.MetaSelectedSectionId
--INNER JOIN MetaSelectedSectionAttribute AS mssa ON mss2.MetaSelectedSectionId = mssa.MetaSelectedSectionId
--WHERE mss.MetaSectionTypeId = 3
--AND mss.MetaTemplateId = 822

--UPDATE MetaSelectedField
--SET RowPosition = 2
--WHERE MetaAvailableFieldId = 528
--AND MetaSelectedFieldId in (
--	SELECT msf.MEtaSelectedFieldId FROM MetaSelectedField AS msf
--	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
--	INNER JOIN MetaSelectedField AS msf2 on msf2.MetaSelectedSectionId = mss.MetaSelectedSectionId
--	WHERE msf.MetaAvailableFieldId = 528
--)