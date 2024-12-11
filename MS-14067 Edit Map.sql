USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14067';
DECLARE @Comments nvarchar(Max) = 
	'Add edit map to fields ';
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
    --AND mt.EndDate IS NULL target historical ones as well
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId

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
('Cover', 'Course', 'SubjectId','Update'),
('Cover', 'Course', 'CourseNumber','Update'),
('Cover', 'Course', 'Title','Update'),
('Cover', 'Course', 'Description','Update'),
('Cover', 'Course', 'Justification','Update'),
('Cover', 'CourseProposal', 'HasCatalogChanges','Update'),
('Cover', 'CourseProposal', 'Modular','Update'),
('Cover', 'Course', 'OpenEntry','Update'),
('Cover', 'CourseProposal', 'HasExam','Update'),
('Cover', 'CourseProposal', 'HasGlobalCheck','Update'),
('Cover', 'CourseProposal', 'HasLimit','Update'),
('Cover', 'CourseCBCode', 'CB23Id','Update'),
('Cover', 'Course', 'ReadingExemptText','Update'),
('Cover', 'Course', 'ValueOutside','Update'),
('General Education', 'Course', 'PatternNumber','Update'),
('General Education', 'Course', 'AdvancedPro_ContinuingWorkforceEducationStudyCodeId','Update'),
('General Education', 'Course', 'TangibleProperty','Update'),
('General Education', 'Course', 'CourseOriginationDate','Update'),
('General Education', 'CourseGeneralEducation', 'GeneralEducationElementId','Update'),
('General Education', 'CourseGeneralEducation', 'GeneralEducationId','Update'),
('Codes/Dates', 'CourseDate', 'CourseDateTypeId','Update'),
('Codes/Dates', 'CourseDate', 'CourseDate','Update'),
('Codes/Dates', 'CourseYearTerm', 'UcApprovalSemesterId','Update'),
('Codes/Dates', 'CourseYearTerm', 'CsuApprovalSemesterId','Update'),
('Codes/Dates', 'CourseYearTerm', 'IgetcSemesterId','Update'),
('Codes/Dates', 'CourseYearTerm', 'CsuGeApprovalSemesterId','Update'),
('Codes/Dates', 'CourseProposal', 'SemesterId','Update'),
('Codes/Dates', 'Course', 'UserId','Update'),
('Codes/Dates', 'Course', 'CreatedDate','Update'),
('Codes/Dates', 'Course', 'StateId','Update'),
('Codes/Dates', 'CourseProposal', 'ImplementDate','Update'),
('Codes/Dates', 'CourseCBCode', 'CB05Id','Update'),
('Codes/Dates', 'CourseCBCode', 'CB10Id','Update'),
('Codes/Dates', 'CourseCBCode', 'CB11Id','Update'),
('Codes/Dates', 'CourseCBCode', 'CB13Id','Update'),
('Codes/Dates', 'CourseCBCode', 'CB22Id','Update'),
('Codes/Dates', 'CourseCBCode', 'CB26Id','Update'),
('Codes/Dates', 'CourseCBCode', 'CB27Id','Update'),
('Codes/Dates', 'CourseYearTerm', 'IsComment','Update'),
('Codes/Dates', 'Course', 'History','Update'),
('Codes/Dates', 'CourseYearTerm', 'UcApprovalYear','Update'),
('Codes/Dates', 'CourseYearTerm', 'CsuApprovalYear','Update'),
('Codes/Dates', 'CourseYearTerm', 'IgetcYear','Update'),
('Codes/Dates', 'CourseYearTerm', 'CsuGeApprovalYear','Update')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedField
SET EditMapId = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback