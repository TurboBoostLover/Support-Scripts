USE [butte];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14437';
DECLARE @Comments nvarchar(Max) = 
	'Set Required Fields on the new Course MetaTemplate';
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
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (1, 2)		--comment back in if just doing some of the mtt's

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
('New Course Documentation', 'CourseProposal', 'Overlap','Update'),
('New Course Documentation', 'CourseProposal', 'ParallelCoursesCSUC','Update2'),
('New Course Documentation', 'CourseProposal', 'ProposalNeed','Update3'),
('New Course Documentation', 'CourseProposal', 'AdviseResults','Update4'),
('New Course Documentation', 'CourseProposal', 'AffectedPrograms','Update5'),
('New Course Documentation', 'CourseProposal', 'CounselorResults','Update6'),
('New Course Documentation', 'CourseProposal', 'DeanOverlap','Update7'),
('New Course Documentation', 'CourseProposal', 'TimesOfferedRationale','Update8'),
('New Course Documentation', 'CourseProposal', 'ExpPropCourse','Update9'),
('New Course Documentation', 'CourseProposal', 'ExtraordinaryCost','Update10'),
('New Course Documentation', 'CourseYesNo', 'YesNo10Id','Update11')

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
	SELECT FieldId FROM @Fields
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'SubText', 'What student needs does this course address (include transfer prep and enrollment impact)?', FieldId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'SubText', 'What employer or advisory group need does this course address?', FieldId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'SubText', 'Does the department have adequate staffing for this course? If not, please explain.', FieldId FROM @Fields WHERE Action = 'Update7'
UNION
SELECT 'SubText', 'Explain if this course requires any specific facility.', FieldId FROM @Fields WHERE Action = 'Update8'
UNION
SELECT 'SubText', 'What equipment (if any) is needed?', FieldId FROM @Fields WHERE Action = 'Update9'
UNION
SELECT 'SubText', 'What supplies (if any) are needed?', FieldId FROM @Fields WHERE Action = 'Update10'
UNION
SELECT 'SubText', 'Please fill out the materials fee request form located on the curriculum website.', FieldId FROM @Fields WHERE Action = 'Update11'
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = @templateId2, @entityId = null; --badge update

--commit
--rollback