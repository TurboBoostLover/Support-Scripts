USE [palomar];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18521';
DECLARE @Comments nvarchar(Max) = 
	'Update Course SLO Tab';
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
('SLO', 'GenericBit', 'Bit09','1'),
('SLO', 'CourseYesNo', 'YesNo02Id','2')

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
UPDATE MetaSelectedField
SET DisplayName = 'I acknowledge that the outcomes in the Course Outline of Record are the official course learning outcomes.  They will be uploaded to the learning outcomes management platform (Nuventive - See Single Sign On). Once the CLOs are active, it is the faculty''s responsibility to complete the following:'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1'
)

UPDATE MetaSelectedField
SET DisplayName = '<ul>
<li>Updating assessment methods and plans</li>
<li>Mapping of courses to a program</li>
<li>Mapping of the course/programs to the ILO (Institutional Learning Outcomes</li>
<li>Reflection of assessment results</li>
<li>Actions/follow-up taken in response to assessment results</li>
<li>Plans for future assessment</li>
</ul>'
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	INNER JOIN @Fields AS f on mss.MetaSelectedSectionId = f.SectionId
	WHERE f.Action = '1'
	and msf.MetaAvailableFieldId IS NULL
)

UPDATE MetaSelectedField
SET DisplayName = 'I affirm that there are two or more course learning outcomes listed above and all of the course learning outcomes meet the curriculum standards.'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '2'
)

UPDATE MetaSelectedSection
SET SectionName = 'Course SLOs'
, SectionDescription = '<b>Course learning outcomes (CLOs) are the observable knowledge, skills, and abilities that faculty will assess to determine that students have achieved the most important learning in their course.  Objectives are the skills, concepts, and experiences throughout the course that will prepare students to achieve the course learning outcomes. The course must have at least two observable course learning outcomes.  Review the <a target="_blank" href="https://nam02.safelinks.protection.outlook.com/?url=https%3A%2F%2Fwww.palomar.edu%2Fteachingexcellence%2Fstudent-learning-outcomes-for-curriculum%2F&data=05%7C02%7CCkearse%40palomar.edu%7C8eb9e67c458a44d3cb1808dd19575dff%7Cdfa178eb10ca40c09667f4732f3381fe%7C0%7C0%7C638694585258446475%7CUnknown%7CTWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D%7C0%7C%7C%7C&sdata=6jXVcfHp8icmvPDDDlCzHl%2BHIygzaYuS737GrvnvNrE%3D&reserved=0">curriculum standards that learning outcomes must meet.</a> Outcomes will be reviewed and returned for revision if they do not meet the curriculum standards listed. You will use these outcomes in the DE Addendum in this proposal.</b><br><br><label style="font-size:14px;"><span style="color:green;">DEI Opportunity:</span> Understand the purpose and importance of equitable and inclusive education when designing or adjusting your outcomes. All outcomes can have elements of equity and diversity or consider adding a course SLO with a specific focus on DE or anti-racism. More information may be found at this website <a target="_blank" href="https://nam02.safelinks.protection.outlook.com/?url=https%3A%2F%2Fwww.learningoutcomesassessment.org%2Fequity%2F&data=05%7C02%7CCkearse%40palomar.edu%7C8eb9e67c458a44d3cb1808dd19575dff%7Cdfa178eb10ca40c09667f4732f3381fe%7C0%7C0%7C638694585258469496%7CUnknown%7CTWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D%7C0%7C%7C%7C&sdata=YKOe9QwimKL%2FVkoezKW5TRnk5aEYnAoQ63pOso%2FOgfU%3D&reserved=0"> Equity in Assessment</a></label>'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '1'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

Declare @clientId2 int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid2 int =2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId2 integers

INSERT INTO @templateId2
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId2
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId2
		--AND mtt.MetaTemplateTypeId in ()		--comment back in if just doing some of the mtt's

declare @FieldCriteria2 table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria2 (TabName, TableName, ColumnName,Action)
values
('Program SLO', 'ProgramYesNo', 'YesNo01Id','1'),
('Program SLO', 'Program', 'HasRequirements','2')

declare @Fields2 table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

insert into @Fields2 (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt)
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
inner join @FieldCriteria2 rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId2)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedField
SET DisplayName = 'I acknowledge that the outcomes in the Program Outcomes Report are the official program learning outcomes. They will be uploaded to the learning outcomes management platform (Nuventive - See Single Sign On). Once the PLOs are active, it is the faculty''s responsibility to complete the following:'
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields2 WHERE Action = '2'
)

UPDATE MetaSelectedSection
SET SectionDescription = '<b>Program learning outcomes (CLOs) are the observable knowledge, skills, and abilities that faculty will assess to determine that students have achieved the most important learning in the program. Objectives are the skills, concepts, and experiences throughout the course that will prepare students to achieve the course learning outcomes. The course must have at least two observable course learning outcomes. Review the <a target="_blank" href="https://nam02.safelinks.protection.outlook.com/?url=https%3A%2F%2Fwww.palomar.edu%2Fteachingexcellence%2Fstudent-learning-outcomes-for-curriculum%2F&data=05%7C02%7CCkearse%40palomar.edu%7C8eb9e67c458a44d3cb1808dd19575dff%7Cdfa178eb10ca40c09667f4732f3381fe%7C0%7C0%7C638694585258446475%7CUnknown%7CTWFpbGZsb3d8eyJFbXB0eU1hcGkiOnRydWUsIlYiOiIwLjAuMDAwMCIsIlAiOiJXaW4zMiIsIkFOIjoiTWFpbCIsIldUIjoyfQ%3D%3D%7C0%7C%7C%7C&sdata=6jXVcfHp8icmvPDDDlCzHl%2BHIygzaYuS737GrvnvNrE%3D&reserved=0">curriculum standards that learning outcomes must meet</a>. Outcomes will be reviewed and returned for revision if they do not meet the curriculum standards listed.</b>'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields2 WHERE Action = '1'
)

UPDATE MetaSelectedField
SET DisplayName = '<ul>
<li>Updating assessment methods and plans</li>
<li>Mapping of the course/programs to the ILO (Institutional Learning Outcomes) </li>
<li>Reflection of assessment results</li>
<li>Actions/follow-up taken in response to assessment results</li>
<li>Plans for future assessment</li>
</ul>'
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	INNER JOIN @Fields2 AS f on mss.MetaSelectedSectionId = f.SectionId
	WHERE f.Action = '1'
	and msf.MetaAvailableFieldId IS NULL
)

DECLARE @NewSec TABLE (SecId int, TempId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @NewSec
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
6, -- [RowPosition]
6, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Fields2 WHERE Action = '1'

UPDATE msf
SET MetaSelectedSectionId = ns.SecId
, DisplayName = 'I affirm that there are two or more program learning outcomes listed above and all of the program learning outcomes meet the curriculum standards.'
FROM MetaSelectedField AS msf
INNER JOIN @Fields2 AS f2 on msf.MetaSelectedFieldId = f2.FieldId
INNER JOIN @NewSec AS ns on ns.TempId = f2.TemplateId
WHERE f2.Action = '1'
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields2)