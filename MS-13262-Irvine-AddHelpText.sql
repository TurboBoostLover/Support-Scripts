USE [socccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13262';
DECLARE @Comments nvarchar(Max) = 
	'Add Help text to course proposals';
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
DEclare @clientId int =3, -- SELECT Id, Title FROM Client 
		@districtId int = 1, 
		@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

insert into @templateId
select mt.MetaTemplateId
from MetaTemplateType mtt
inner join MetaTemplate mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
where mtt.EntityTypeId = @Entitytypeid
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate is NULL
and mtt.active = 1
and mtt.IsPresentationView = 0
and (mtt.ClientId = @clientId or mtt.ClientId = @districtId)

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
('Cover', 'Course', 'SubjectId','1st'),
('Cover', 'Course', 'CourseNumber','2nd'),
('Cover', 'Course', 'CourseSuffixId','3rd'),
('Cover', 'CourseYesNo', 'YesNo09Id','4th'),
('Cover', 'CourseDetail', 'Tier1_OrganizationEntityId','5th'),
('Cover', 'CourseDetail', 'Tier2_OrganizationEntityId','6th'),
('Cover', 'CourseDetail', 'Tier3_OrganizationEntityId','7th'),
('Cover', 'Course', 'CampusId','8th'),
('Cover', 'Course', 'Title','9th'),
('Cover', 'Course', 'ShortTitle','10th'),
('Cover', 'CourseProposal', 'SemesterId','11th')
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
SET LabelStyleId = 1 --TOP LABEL EVERYTHING NOT CURRENTLY, WAS TOLD BY STEVE TO DO THIS
WHERE MetaSelectedFieldId IN (SELECT FieldId FROM @Fields)

insert into MetaSelectedFieldAttribute
(Name,Value,MetaSelectedFieldId)
SELECT
'SubText',
'Open entry/open exit courses are defined in Title 5, § 58164 as credit or noncredit courses in which students enroll at different times and complete at various times or at varying paces within a defined time period.',
MetaSelectedFieldId
from MetaSelectedField MSF
	inner join MetaSelectedSection MSS 
	on MSF.MetaSelectedSectionId = MSS.MetaSelectedSectionId
	and MetaTemplateid in (SELECT * FROM @templateId)
	where MSF.MetaAvailableFieldId = 3425  -- Added to Open Entry 

/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2


--commit
--rollback