USE [nocccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-16068';
DECLARE @Comments nvarchar(Max) = 
	'Clean up configuration on CMC';
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

DELETE FROM [User]
WHERE (
Id not in (
	SELECT DISTINCT UserId FROM Course WHERE Active = 1
	)
and Id not in (
	SELECT DISTINCT UserId FROM Program WHERE Active = 1
	)
and Id not in (
	SELECT DISTINCT UserId FROM Package WHERE Active = 1
	)
and Id not in (
	SELECT DISTINCT UserId FROM Module WHERE Active = 1
	)
and Id not in (
	SELECT DISTINCT UserId FROM MetaTemplate WHERE Active = 1
)
)
AND Active = 0		--there are only 16 active users and I would assume we use all of them

DECLARE @SEC INTEGERS
INSERT INTO @SEC
SELECT MetaSelectedSectionId FROM MetaSelectedSection WHERE MetaSelectedSection_MetaSelectedSectionId IS NULL
AND SectionName like '%Cross%'


while exists(select top 1 1 from @SEC)
begin
    declare @TID int = (select top 1 * from @SEC)
		declare @clientId int = (
			SELECT mt.ClientId FROM MetaTemplate As mt
			INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
			WHERE mss.MetaSelectedSectionId = @TID
		)
		EXEC spBuilderSectionDelete @clientId, @TID
    delete @SEC
    where id = @TID
end

UPDATE MetaSelectedField
 SET MetaPresentationTypeId = 28
 , DefaultDisplayType = 'DropDown'
 WHERE MetaSelectedFieldId in (
	SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId in (1371, 3766, 3594, 3779)
 )

  insert into MetaSelectedSectionAttribute
(Name,[Value],MetaSelectedSectionId)
SELECT 'lookuptablename','CourseGeneralEducation',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 131
UNION
SELECT 'lookupcolumnname','GeneralEducationElementId',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 131
UNION
SELECT 'columns','1', MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 131
UNION
SELECT 'grouptablename', 'CourseGeneralEducation',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 131
UNION
SELECT 'groupcolumnname', 'GeneralEducationId', MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 131
UNION
SELECT 'lookuptablename','CourseOutcomeClientLearningOutcome',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 939
UNION
SELECT 'lookupcolumnname','ClientLearningOutcomeId',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 939
UNION
SELECT 'columns','1', MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 939
UNION
SELECT 'grouptablename', 'CourseOutcomeClientLearningOutcome',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 939
UNION
SELECT 'groupcolumnname', 'ClientLearningOutcomeParentId', MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 939
UNION
------------------
SELECT 'lookuptablename','ClientLearningOutcomeProgramOutcome',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 203
UNION
SELECT 'lookupcolumnname','ClientLearningOutcomeId',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 203
UNION
SELECT 'columns','1', MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 203
UNION
SELECT 'grouptablename', 'ClientLearningOutcomeProgramOutcome',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 203
UNION
SELECT 'groupcolumnname', 'ClientLearningOutcomeParentId', MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 203
UNION
SELECT 'lookuptablename','ProgramOutcomeMatching',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 204
UNION
SELECT 'lookupcolumnname','CourseOutcomeId',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 204
UNION
SELECT 'columns','1', MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 204
UNION
SELECT 'grouptablename', 'ProgramOutcomeMatching',MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 204
UNION
SELECT 'groupcolumnname', 'ProgramCourseId', MetaSelectedSectionId fROM MetaSelectedSection WHERE MetaBaseSchemaId = 204

DECLARE @TABLE INTEGERS
INSERT INTO @TABLE
SELECT DISTINCT m1.Id
FROM MetaSelectedFieldAttribute m1
INNER JOIN (
    SELECT name, value, metaselectedfieldId
    FROM MetaSelectedFieldAttribute
    GROUP BY name, value, metaselectedfieldId
    HAVING COUNT(*) > 1
) m2 ON m1.name = m2.name AND m1.value = m2.value AND m1.metaselectedfieldId = m2.metaselectedfieldId;

DELETE FROM MetaSelectedFieldAttribute
WHERE Id in (
	SELECT * FROM @TABLE
)

UPDATE MetaSelectedField 
SET IsRequired = 0
WHERE 
(MetaPresentationTypeId = 5
or 
(MetaPresentationTypeId = 1 and FieldTypeId = 5)
or MetaPresentationTypeId = 103)
AND IsRequired = 1

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()