USE [nukz];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17381';
DECLARE @Comments nvarchar(Max) = 
	'Update Requirements on Program Forms';
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (2)		--comment back in if just doing some of the mtt's

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('General Information', 'Program', 'UserId','field'),
('General Information', 'ProgramDetail', 'NumeralId','field'),
('General Information', 'Program', 'ProgramCodeId','field'),
('General Information', 'ProgramQueryText', 'QueryText_01','field'),
('General Information', 'Program', 'BudgetId','field'),
('General Information', 'GenericMaxText', 'TextMax17','field'),
('General Information', 'ProgramLearningMethod', 'LearningMethodId','sec'),
('General Information', 'GenericMaxText', 'TextMax01','field'),
('Program Aims and Strategic Goals', 'GenericMaxText', 'TextMax02', 'field'),
('Program Aims and Strategic Goals', 'GenericMaxText', 'TextMax03', 'field'),
('Program Aims and Strategic Goals', 'ProgramObjective', 'Text', 'ol1'),
('Program Learning Outcomes', 'ProgramOutcome', 'Outcome', 'ol2'),
('Learning and Teaching Methods', 'ProgramOutcome', 'Outcome', 'ol3'),
('Student Support', 'GenericMaxText', 'TextMax14', 'field'),
('Student Support', 'GenericMaxText', 'TextMax04', 'field'),
('Student Support', 'GenericMaxText', 'TextMax05', 'field'),
('Quality Assurance and Enhancement', 'GenericMaxText', 'TextMax06', 'field'),
('Quality Assurance and Enhancement', 'GenericMaxText', 'TextMax07', 'field'),
('Program Progression and Completion', 'GenericMaxText', 'TextMax10', 'field'),
('Program Progression and Completion', 'GenericMaxText', 'TextMax11', 'field'),
('Attachments', 'ProgramAttachedFile', 'Title', 'tab'),
('Faculty Resources', 'ProgramPersonnel', 'LastName', 'ol4'),
('Faculty Resources', 'ProgramPersonnel', 'FirstName', 'field'),
('Faculty Resources', 'ProgramPersonnel', 'PersonnelTitleId', 'field'),
('Faculty Requirements', 'ProgramPersonnel', 'MaxText01', 'field'),
('Faculty Requirements', 'ProgramPersonnel', 'Degree', 'field'),
('Faculty Requirements', 'ProgramPersonnel', 'YearObtained', 'field'),
('Faculty Requirements', 'ProgramPersonnel', 'University', 'field'),
('Faculty Requirements', 'ProgramPersonnel', 'AreaOfExpertise', 'field'),
('Faculty Requirements', 'ProgramPersonnel', 'SupervisionExperience', 'field'),
('Faculty Requirements', 'ProgramPersonnel', 'RecentPublications', 'field'),
('Assessment Strategies', 'GenericMaxText', 'TextMax16', 'field'),
('Assessment Strategies', 'GenericMaxText', 'TextMax13', 'field'),
('Outcomes', 'ProgramOutcomeAssessment', 'EvaluationMethodId', 'sec10'),
('Assessment Strategies', 'ProgramOutcome', 'Outcome', 'ol10')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedField
SET IsRequired = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in ('field', 'ol1', 'ol4')
)

INSERT INTO MetaSelectedSectionSetting
(IsRequired, MinElem, MetaSelectedSectionId)
SELECT 1, 1, SectionId FROM @Fields WHERE Action = 'sec'

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('DECLARE @count int = (
	SELECT Count(Id) FROM ProgramObjective
	WHERE ProgramId = @EntityId
)

DECLARE @Valid int = (
	SELECT Count(Id) FROM ProgramObjective
	WHERE ProgramId = @EntityId
	and Text IS NOT NULL
)

SELECT CASE
WHEN @Valid = @count THEN 1 else 0 END AS IsValid', 1)

DECLARE @Id int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'Objectives', 'Needs to be filled out if added', 6, 'Launch Requirement: All required fields must be filled out.', @ID FROM @Fields WHERE Action = 'ol1'

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('DECLARE @count int = (
	SELECT Count(Id) FROM ProgramOutcome
	WHERE ProgramId = @EntityId
)

DECLARE @Valid TABLE (Id INT);

-- Insert distinct valid program outcomes into table variable
INSERT INTO @Valid (Id)
SELECT DISTINCT po.Id 
FROM ProgramOutcome AS po
INNER JOIN ProgramOutcomeMajorLearningOutcome AS pom 
    ON pom.ProgramOutcomeId = po.Id
WHERE po.ProgramId = @EntityId
and Outcome IS NOT NULL;

SELECT 
    CASE
        WHEN (SELECT COUNT(Id) FROM @Valid)  = @count 
        THEN 1 
        ELSE 0 
    END AS IsValid;', 1)

DECLARE @Id2 int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'Outcomes', 'Needs to be filled out if added', 6, 'Launch Requirement: All required fields must be filled out.', @ID2 FROM @Fields WHERE Action = 'ol2'

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('DECLARE @count INT = (
    SELECT COUNT(Id) 
    FROM ProgramOutcome
    WHERE ProgramId = @EntityId
);

-- Declare table variable to store valid IDs
DECLARE @Valid TABLE (Id INT);

-- Insert distinct valid program outcomes into table variable
INSERT INTO @Valid (Id)
SELECT DISTINCT po.Id 
FROM ProgramOutcome AS po
INNER JOIN ProgramOutcomeQfeStand AS pom 
    ON pom.ProgramOutcomeId = po.Id
WHERE po.ProgramId = @EntityId
and ISNULL(IsHeader,0) <> 1;

-- Calculate other outcomes
DECLARE @Other INT = (
    SELECT COUNT(po.Id) 
    FROM ProgramOutcome AS po
    WHERE ProgramId = @EntityId
      AND IsHeader = 1
      AND OutcomeText IS NOT NULL
);

-- Validate result
SELECT 
    CASE
        WHEN (SELECT COUNT(Id) FROM @Valid) + ISNULL(@Other, 0) = @count 
        THEN 1 
        ELSE 0 
    END AS IsValid;', 1)

DECLARE @Id3 int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'Outcomes', 'Needs to be filled out if added', 6, 'Launch Requirement: All required fields must be filled out.', @ID3 FROM @Fields WHERE Action = 'ol3'

--INSERT INTO MetaSqlStatement
--(SqlStatement, SqlStatementTypeId)
--VALUES
--('DECLARE @count int = (1)

--DECLARE @Valid int = (
--	SELECT Count(Id) FROM ProgramAttachedFile
--	WHERE ProgramId = @EntityId
--)

--SELECT CASE
--WHEN @Valid >= @count THEN 1 ELSE 0 END AS IsValid', 1)

--DECLARE @Id4 int = SCOPE_IDENTITY()

--INSERT INTO MetaControlAttribute
--(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
--SELECT TabId, 'Attachements', 'Needs 1', 6, 'Launch Requirement: Need 1 Attachment.', @ID4 FROM @Fields WHERE Action = 'tab'

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('DECLARE @count int = (
	SELECT Count(Id) FROM ProgramPersonnel
	WHERE ProgramId = @EntityId
)

DECLARE @Valid int = (
	SELECT Count(Id) FROM ProgramPersonnel
	WHERE ProgramId = @EntityId
	and LastName IS NOT NULL
	and FirstName IS NOT NULL
	and PersonnelTitleId IS NOT NULL
	and Degree IS NOT NULL
	and YearObtained IS NOT NULL
	and University IS NOT NULL
	and AreaOfExpertise IS NOT NULL
	and SupervisionExperience IS NOT NULL
	and RecentPublications IS NOT NULL
	and PersonnelTitleId <> 11
)

DECLARE @other int = (
	SELECT Count(Id) FROM ProgramPersonnel
	WHERE ProgramId = @EntityId
	and LastName IS NOT NULL
	and FirstName IS NOT NULL
	and PersonnelTitleId IS NOT NULL
	and Degree IS NOT NULL
	and YearObtained IS NOT NULL
	and University IS NOT NULL
	and AreaOfExpertise IS NOT NULL
	and SupervisionExperience IS NOT NULL
	and RecentPublications IS NOT NULL
	and PersonnelTitleId = 11
	and MaxText01 IS NOT NULL
)

SELECT CASE
WHEN sUM(ISNULL(@Valid, 0) + ISNULL(@other, 0)) = @count THEN 1 ELSE 0 END AS IsValid', 1)

DECLARE @Id5 int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'Faculty', 'Needs 1', 6, 'Launch Requirement: All required fields must be filled out.', @ID5 FROM @Fields WHERE Action = 'ol4'

INSERT INTO MetaSelectedSectionSetting
(IsRequired, MinElem, MetaSelectedSectionId)
SELECT 1, 1, SectionId FROM @Fields WHERE Action = 'sec10'

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('DECLARE @count int = (
	SELECT Count(Id) FROM ProgramOutcome
	WHERE ProgramId = @EntityId
)

DECLARE @Valid TABLE (Id INT);

-- Insert distinct valid program outcomes into table variable
INSERT INTO @Valid (Id)
SELECT DISTINCT po.Id 
FROM ProgramOutcome AS po
INNER JOIN ProgramOutcomeAssessment AS pom 
    ON pom.ProgramOutcomeId = po.Id
WHERE po.ProgramId = @EntityId
and OptText IS NULL
and AssessmentText IS NULL


DECLARE @other int = (
		SELECT Count(Id) FROM ProgramOutcome
	WHERE ProgramId = @EntityId
	and OptText IS NOT NULL
	and AssessmentText IS NOT NULL
)

-- Validate result
SELECT 
    CASE
        WHEN (SELECT COUNT(Id) FROM @Valid) + ISNULL(@Other, 0) = @count 
        THEN 1 
        ELSE 0 
    END AS IsValid;', 1)

DECLARE @Id6 int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'Assessment strats', 'Needs 1', 6, 'Launch Requirement: All required fields must be filled out.', @ID6 FROM @Fields WHERE Action = 'ol10'
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback