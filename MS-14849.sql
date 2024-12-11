USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14849';
DECLARE @Comments nvarchar(Max) = 
	'Update Group Check list to work on Maverick';
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1
    --AND mtt.EntityTypeId = @entityTypeId
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    --AND mtt.ClientId = @clientId
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
('General Education/Transfer', 'CourseGeneralEducation', 'GeneralEducationId','Update'),
('Outcomes', 'ProgramOutcomeMatching', 'CourseOutcomeId', 'Update2'),
('Outcomes', 'ClientLearningOutcomeProgramOutcome', 'ClientLearningOutcomeId', 'Update3'),
('Program Learning Outcomes', 'ProgramOutcome', 'Outcome', 'Update4'),
('Assessment Methods / Tools', 'ModuleRelatedModule01', 'Lookup05Id', 'Update5'),
('General Education', 'CourseGeneralEducation', 'GeneralEducationElementId', 'Update6'),
('Student Learning Outcomes', 'CourseOutcome', 'OutcomeText', 'Update7'),
('Outcome', 'CourseOutcomeClientLearningOutcome', 'ClientLearningOutcomeId', 'Update8')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action in ('Update', 'Update4', 'Update5','Update6', 'Update7')
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 31
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action in ('Update2', 'Update8')
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 32
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('Update', 'Update2', 'Update3', 'Update5', 'Update6', 'Update8')
)

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('Update', 'Update2', 'Update3', 'Update5', 'Update6', 'Update7', 'Update8')
)

 UPDATE MetaSelectedField
 SET MetaPresentationTypeId = 28
 , DefaultDisplayType = 'DropDown'
 WHERE MetaSelectedFieldId in (
	SELECT FieldId fROM @Fields WHERE Action in ('Update', 'Update2', 'Update3', 'Update5', 'Update6', 'Update8')
 )

  insert into MetaSelectedSectionAttribute
(Name,[Value],MetaSelectedSectionId)
SELECT 'lookuptablename','CourseGeneralEducation',SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'lookupcolumnname','GeneralEducationElementId',SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'columns','1', SectionId FROM @Fields WHERE Action in ('Update', 'Update2', 'Update3')
UNION
SELECT 'grouptablename', 'CourseGeneralEducation', SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'groupcolumnname', 'GeneralEducationId', SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'lookuptablename','ProgramOutcomeMatching',SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'lookupcolumnname','CourseOutcomeId',SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'grouptablename', 'ProgramOutcomeMatching', SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'groupcolumnname', 'ProgramSequenceId', SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'lookuptablename','ClientLearningOutcomeProgramOutcome',SectionId FROM @Fields WHERE Action = 'Update3'
UNION
SELECT 'lookupcolumnname','ClientLearningOutcomeId',SectionId FROM @Fields WHERE Action = 'Update3'
UNION
SELECT 'grouptablename', 'ClientLearningOutcomeProgramOutcome', SectionId FROM @Fields WHERE Action = 'Update3'
UNION
SELECT 'groupcolumnname', 'ClientLearningOutcomeParentId', SectionId FROM @Fields WHERE Action = 'Update3'
UNION
SELECT 'lookuptablename','ModuleRelatedModule01',SectionId FROM @Fields WHERE Action = 'Update5'
UNION
SELECT 'lookupcolumnname','Reference_CourseOutcomeId',SectionId FROM @Fields WHERE Action = 'Update5'
UNION
SELECT 'grouptablename', 'ModuleRelatedModule01', SectionId FROM @Fields WHERE Action = 'Update5'
UNION
SELECT 'groupcolumnname', 'Lookup05Id', SectionId FROM @Fields WHERE Action = 'Update5'
UNION
SELECT 'lookuptablename','CourseGeneralEducation',SectionId FROM @Fields WHERE Action = 'Update6'
UNION
SELECT 'lookupcolumnname','GeneralEducationElementId',SectionId FROM @Fields WHERE Action = 'Update6'
UNION
SELECT 'grouptablename', 'CourseGeneralEducation', SectionId FROM @Fields WHERE Action = 'Update6'
UNION
SELECT 'groupcolumnname', 'GeneralEducationId', SectionId FROM @Fields WHERE Action = 'Update6'
UNION
SELECT 'lookuptablename','CourseOutcomeClientLearningOutcome',SectionId FROM @Fields WHERE Action = 'Update8'
UNION
SELECT 'lookupcolumnname','ClientLearningOutcomeId',SectionId FROM @Fields WHERE Action = 'Update8'
UNION
SELECT 'grouptablename', 'CourseOutcomeClientLearningOutcome', SectionId FROM @Fields WHERE Action = 'Update8'
UNION
SELECT 'groupcolumnname', 'ClientLearningOutcomeParentId', SectionId FROM @Fields WHERE Action = 'Update8'

UPDATE ListItemType
SET ListItemTitleColumn = 'OutcomeText'
WHERE Id = 15

UPDATE CourseOutcome
SET ListItemTypeId = 15
WHERE ListItemTypeId IS NULL

UPDATE ProgramOutcome
SET ListItemTypeId = 23
WHERE ListItemTypeId IS NULL
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback