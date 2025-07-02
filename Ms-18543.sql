USE [sjcc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18543';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Form and COR report';
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
Declare @clientId int =49, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		--AND mtt.MetaTemplateTypeId in ()		--comment back in if just doing some of the mtt's

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
('Units/Hours/Content', 'CourseDescription', 'MinCreditHour','1'),
('Student Learning Outcomes and Objectives', 'CourseOutcome', 'OutcomeText','2'),
('Grading/Method of Evaluation', 'CourseProposal', 'TimesOfferedRationale', '3'),
('Homework', 'Course', 'Rationale', '4'),
('Advisory/Recommended Prep', 'GenericBit', 'Bit01', '5'),
('Course and Program Status', 'GenericBit', 'Bit06', '6'),
('Course and Program Status', 'GenericBit', 'Bit07', '6')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedSection
SET SectionName = 'Units, Hours, and Content'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '1'
)

DELETE FROM MetaSelectedField 
WHERE MetaSelectedFieldId in (
	SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId IS NULL and DisplayName = 'For each SLO, add new item'
)

UPDATE MetaSelectedSection
SET SectionName = 'Student Learning Outcomes and Course Objectives'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '2'
)

UPDATE MetaSelectedSection
SET SectionName = 'Grading, Method of Evaluation, and Critical Thinking #1'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '3'
)

UPDATE MetaSelectedField
SET DisplayName = 'List types of assignments that will be required outside of the classroom'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '3'
)

UPDATE MetaSelectedSection
SET SectionName = 'Homework and Critical Thinking Example #2'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '4'
)

INSERT INTO MetaSelectedFieldAttribute
(Name ,Value, MetaSelectedFieldId)
SELECT 'helptext', '(e.g. examples of reading and writing assignments)', FieldId FROM @Fields WHERE Action = '4'

UPDATE MetaSelectedSection
SET SectionName = 'Advisory and Recommended Prep'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '5'
)

UPDATE RevisionType
SET Title = 'RW 1 = Completion of READ 350 (6 units) or ESL 313 or ENGL 321'
WHERE Id = 1

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '6'
)

DELETE FROM MetaSelectedSection
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '6'
)

UPDATE RequisiteType
SET Title = 'Prerequiste'
WHERE Id = 378

UPDATE MetaSelectedField
SET DisplayName = 'Course Objectives:'
WHERE DisplayName = 'Common Course Numbering (CCN) Objectives.'

UPDATE MetaSelectedField
SET DisplayName = 'Course Lecture Content:'
WHERE DisplayName = 'Course Lecture Content'
and MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = 499
)

DECLARE @SQL NVARCHAR(MAX) = '

DECLARE @pre INT = 378, -- RequisiteTypeId
		@co  INT = 379;

DECLARE @preReqs NVARCHAR(MAX) = NULL, 
		@coReqs  NVARCHAR(MAX) = NULL;

DECLARE @preReqTable TABLE (Prerequisites NVARCHAR(MAX), SortOrder INT);
DECLARE @coReqTable  TABLE (Corequisites  NVARCHAR(MAX), SortOrder INT);

INSERT INTO @preReqTable
SELECT COALESCE(@preReqs, '''') + CONCAT(
	s.SubjectCode, '' '', c.CourseNumber, '' '', 
	cr.CourseRequisiteComment, '' '', con.Title
	) AS Prerequisites, cr.SortOrder
FROM CourseRequisite cr
    LEFT JOIN Subject   s   ON s.Id   = cr.SubjectId
    LEFT JOIN Course    c   ON c.Id   = cr.Requisite_CourseId
    LEFT JOIN Condition con ON con.Id = cr.ConditionId
WHERE cr.CourseId = @entityId AND cr.RequisiteTypeId = @pre
ORDER BY cr.SortOrder

SELECT @preReqs = COALESCE(@preReqs, '''') + CONCAT(Prerequisites, '' '') 
FROM @preReqTable ORDER BY SortOrder

INSERT INTO @coReqTable
SELECT COALESCE(@coReqs, '''') + CONCAT(
	s.SubjectCode, '' '', c.CourseNumber, '' '', 
	cr.CourseRequisiteComment, '' '', con.Title
	) AS Corequisites, cr.SortOrder
FROM CourseRequisite cr
    LEFT JOIN Subject   s   ON s.Id   = cr.SubjectId
    LEFT JOIN Course    c   ON c.Id   = cr.Requisite_CourseId
    LEFT JOIN Condition con ON con.Id = cr.ConditionId
WHERE cr.CourseId = @entityId AND cr.RequisiteTypeId = @co
ORDER BY cr.SortOrder

SELECT @coReqs = COALESCE(@coReqs, '''') + CONCAT(Corequisites, '' '') 
FROM @coReqTable ORDER BY SortOrder
                        
SELECT
    0 AS Value,
   CONCAT(
   ''<label>Course Prerequisite:</label><br>'', COALESCE(@preReqs, '' None''), ''<br>'',
   ''<label>Course Corequisite:</label><br>''  , COALESCE(@coReqs,  '' None''), ''<br>''
    ) AS Text

'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 178
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select Distinct templateId FROM @Fields
UNION
SELECT mss.MetaTemplateID fROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId in (2559, 499)
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback