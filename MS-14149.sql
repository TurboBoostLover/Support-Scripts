USE [statetechmo];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14149';
DECLARE @Comments nvarchar(Max) = 
	'Update Syllabus';
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
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (4, 16, 18)

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
('Policies', 'GenericMaxText', 'TextMax04','Update'),
('Policies', 'GenericMaxText', 'TextMax03','Update2'),
('Appropriate and Responsible Use of Information Assignment','Course','COURSE_DESC','Delete')

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
UPDATE MetaSelectedFieldAttribute
SET Value = 'Students are expected to attend all classes. It is the responsibility of students to notify their instructors before they will be absent, tardy, or leaving early from class for any reason.<br><br>
<b>Attendance Percentage</b><br>
The final score recorded for attendance will be a percentage of the points possible.Attendance point scoring:<br><ul>
<li> Present (P) = 2 points
<li> Absent (A) = 0 points
<li> Late (L) = 1 point
<li> Excused (E) = 2 points</ul>
<b>Excused absences include:</b><br><ul>
<li>Death in the student’s immediate family (Copy of service program required.) The definition of "immediate family" includes spouse, child, parent (including step-mother or step-father), spouse’s child or parent, sibling, grandparent or grandchild, spouse’s grandparent or grandchild, daughter-in-law, son-in-law, sister-in-law, brother-in-law, aunt, uncle, great-aunt, great-uncle, other members of the student’s household, State Tech employee, fellow student, or anyone for whom the student will serve as a pall bearer.
<li>Approved State Tech functions such as: testing, SkillsUSA, Postsecondary Agricultural Student Organization (PAS), career expo, field trips
<li>Jury Duty (Copy of jury duty summons required.)
<li>Subpoena to Appear in a Court of Law (Copy of subpoena required.)
<li>Military Obligations (Copy of military orders required.)</ul>
'
WHERE Name = 'SubText'
AND MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedFieldAttribute
SET Value = '
		Students are encouraged to assist each other and exchange information in order to master the concepts and skills covered in coursework and to seek tutoring from the Academic Resource Center or if they need additional resources. However, collaboration on any individually graded assignment or exam to the extent that it is not an individual student’s total, personal effort will be considered as a violation of the <a href="https://www.statetechmo.edu/student-code-of-conduct/" target="_blank">Student Code of Conduct.</a><br /><br />
		
		To report an incident related to academic integrity, please use the <a href="https://cm.maxient.com/reportingform.php?StateTechMO&layout_id=30" target="_blank">Academic Integrity Reporting Form.</a><br /><br />
		
		The sanctions for academic integrity violations can be a range of the following:
		<ul>
			<li>Grade of Zero on the paper, assignment, quiz, or test on which the violation occurred.</li>
			<li>A second documented violation can result in a grade of “F” being assigned in the course.</li>
		</ul>
		
		If the Vice President for Student Affairs identifies a pattern of behavior related to violations of the policy, additional sanctions may be applied up to and including separation from the program or the college.<br>
		<br><b>Academic Grievance</b><br>
		The quality of instruction, evaluation of academic performance, and assignment of final grades are the responsibility of the faculty. Academic grievances related to instruction and grading should follow the guidelines provided below.<ol>
		<li>Students with an academic grievance should see the course instructor.
		<li>If still dissatisfied, the student may appeal to the Chair who will investigate and provide a decision to the student.
		<li>If still dissatisfied or if the instructor is also the Chair, the student may appeal to the Academic Dean who will investigate and provide a final decision to the student.</ol>
		<b>Final Grade Appeal</b><br>
		Within six weeks of final grade posting, students have the right to submit a final grade appeal. Guidelines are provided below.<ol>
		<li>Follow Academic Grievance guidelines.
		<li>If still dissatisfied, the student may appeal using the Final Grade Appeal form. It shall be the responsibility of the student to prove that the grade is incorrect or unjustified.
		<li>Final Grade Appeals will be adjudicated by a faculty committee.</ol>
		Concerns alleging Title IX sexual violence, sexual harassment, or other discrimination, should be directed to Student Affairs.

	'
WHERE Name = 'SubText'
AND MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

Delete From CourseSectionSummary
Where CourseId in (
	SELECT Id FROM Course WHERE MetaTemplateId in (		--the backing store the want removed to drop a whole tab
		SELECT * FROM @templateId
	)
)

while exists(select top 1 1 from @templateId)
begin
    declare @TID int = (select top 1 * from @templateId)
		declare @sec int = (select TabId FROM @Fields WHERE TemplateId = @TID AND Action = 'Delete')
EXEC spBuilderSectionDelete @clientId, @sec
    delete @templateId
    where id = @TID
end
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback