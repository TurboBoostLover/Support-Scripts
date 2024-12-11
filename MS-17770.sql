USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17770';
DECLARE @Comments nvarchar(Max) = 
	'Update DE Revision form to only edit DE tab for users';
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
		AND mtt.MetaTemplateTypeId in (8)		--comment back in if just doing some of the mtt's

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
('Cover', 'Course', 'CourseNumber','1'),
('Cover', 'CourseProposal', 'CourseRationale','2'),
('Units and Hours', 'CourseCBCode', 'CB04Id', '1'),
('Units and Hours', 'Course', 'OpenEntry', '1'),
('Course Standards', 'GenericInt', 'Int01', '1'),
('Course Standards', 'GenericInt', 'Int03', '1'),
('Course Standards', 'GenericInt', 'Int02', '1'),
('Course Standards', 'CourseDetail', 'Lookup02Id_01', '1'),
('Course Standards', 'CourseAttachedFile', 'Title', '3'),
('Course Standards', 'CourseCBCode', 'CB05Id', '1'),
('Course Standards', 'CourseCBCode', 'CB08Id', '1'),
('Course Standards', 'CourseCBCode', 'CB10Id', '1'),
('Course Standards', 'CourseCBCode', 'CB11Id', '1'),
('Course Standards', 'CourseCBCode', 'CB13Id', '1'),
('Course Standards', 'CourseCBCode', 'CB23Id', '1'),
('Course Standards', 'CourseCBCode', 'CB24Id', '1'),
('Course Standards', 'CourseCBCode', 'CB25Id', '1'),
('Course Standards', 'CourseCBCode', 'CB26Id', '1'),
('Course Standards', 'CourseCBCode', 'CB27Id', '1'),
('Limitations of Enrollment', 'Course', 'SpecifyDegree', '1'),
('Course Objectives', 'CourseObjective', 'Text', '4'),
('Assignments', 'GenericMaxText', 'TextMax03', '2'),
('Assignments', 'GenericMaxText', 'TextMax04', '2'),
('Methods of Evaluation', 'GenericMaxText', 'TextMax20', '1'),
('Methods of Evaluation', 'GenericMaxText', 'TextMax22', '1'),
('Methods of Evaluation', 'GenericMaxText', 'TextMax23', '1'),
('Attached Files', 'CourseYesNo', 'YesNo25Id', '1'),
('Methods of Evaluation', 'Course', 'TranslatedDescription', '2'),
('General Education Proposal', 'CourseQueryText', 'QueryText_02', '8'),
('Course Purpose/Needs', 'GenericBit', 'Bit11', '1'),
('Course Purpose/Needs', 'GenericMaxText', 'TextMax21', '1')

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
UPDATE MetaSelectedField
SET IsRequired = 0
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in ('1', '2')
)

INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, RoleId, AccessRestrictionType)
SELECT FieldId, 4, 1 FROM @Fields WHERE Action = '1'
UNION
SELECT FieldId, 1, 2 FROM @Fields WHERE Action = '1'

DELETE FROM MetaSelectedSectionPositionPermission
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss 
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = 8
)
and PositionId = 70

INSERT INTO MetaSelectedSectionRolePermission
(MetaSelectedSectionId, RoleId, AccessRestrictionType)
SELECT SectionId, 4, 1 FROM @Fields WHERE Action in ('3', '4')
UNION
SELECT SectionId, 1, 2 FROM @Fields WHERE Action in ('3', '4')

DELETE FROM MetaControlAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('4')
)

DELETE FROM MetaControlAttribute
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '8'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback