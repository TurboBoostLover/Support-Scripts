USE [sbcc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18561';
DECLARE @Comments nvarchar(Max) = 
	'Update DEIA text on questions';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
('Diversity, Equity, Inclusion and Accessibility', 'GenericMaxText', 'TextMax10','1'),
('Diversity, Equity, Inclusion and Accessibility', 'GenericMaxText', 'TextMax11','2'),
('Diversity, Equity, Inclusion and Accessibility', 'GenericMaxText', 'TextMax12','3'),
('Diversity, Equity, Inclusion and Accessibility', 'GenericMaxText', 'TextMax13','4')

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
SET DisplayName = '(1). Making a course <b>culturally relevant</b> involves intentionally designing the curriculum, teaching methods, and assessment practices to reflect and honor the diverse backgrounds and experiences of students. This approach aims to not only educate, but also resonate deeply with students by making the course relatable and applicable to their personal, educational, and career goals. Deeper learning occurs when students understand the importance of a subject and how it relates to them, making culturally relevant approaches a key teaching and learning tool.<br><br>
Looking <u>at least one element</u> of the course outline (such as <b>course objectives, student learning outcomes, or course content</b>) provided in this proposal, how does the design of the course curriculum create a rich and relatable learning experience for all?'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1'
)

UPDATE MetaSelectedField
SET DisplayName = '(2). In the classroom, a blend of both intrusive and proactive communication methods can have a profound effect on student success. "Intrusive" and "proactive" communication in teaching essentially refer to the same concept, meaning an instructor actively reaches out to students to anticipate potential issues and provide support before problems arise, rather than waiting for students to come to them with concerns. These communication methods lead to student success because they help instructors take the initiative to build strong relationships with students as well as monitoring student progress closely, ensuring student success by creating opportunities for students to take ownership and engagement in their learning.<br><br>
Looking at the <b>methods of evaluation</b> provided in this proposal, what intrusive and proactive communication methods do instructors plan to employ to ensure students remain engaged and on track?'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '2'
)

UPDATE MetaSelectedField
SET DisplayName = '(3). Many students, particularly those from low-income backgrounds, struggle to afford the high cost of textbooks, software, lab materials, and other required resources. This financial burden can lead to students delaying purchasing course materials or choosing to not buy the materials at all. When students don''t have access to required course materials, they are at a disadvantage compared to their peers who can afford them. This creates a situation where financial barriers directly affect academic performance and can lead to lower grades, missed learning opportunities, and increased risk of failure.<br><br>
Looking at the <b>textbooks and required course fees</b> provided in this proposal, how will instructors ensure equitable and affordable access to all course materials and tools?'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '3'
)

UPDATE MetaSelectedField
SET DisplayName = '(4). Classroom accessibility involves instructional design elements, teaching strategies, technological aids, and communications. If the methods of instruction are to be aligned with accessibility standards, it''s important to ensure that all students, including those with disabilities or other barriers to learning, have equitable access to the course content and can successfully engage with the material. This includes understanding the American Disabilities Act (ADA) and how Section 508 of the Rehabilitation Act of 1973 ensures electronic and information technology is accessible to people with disabilities. Inclusive classrooms provide all students with equal opportunities and the tools they need to succeed. As you design your class, always keep accessibility and equity in mind. A class activity or resources is only effective if all students can access it.<br><br>
Looking at the <b>methods of instruction</b> provided in this proposal, describe how they meet accessibility standards and/or how will instructors create alternatives to serve students?'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '4'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback