USE [hancockcollege];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15667';
DECLARE @Comments nvarchar(Max) = 
	'Add help text to course and program forms';
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
('Cover Screen', 'Course', 'Title','Course Title'),
('Cover Screen', 'Course', 'ShortTitle', 'Banner Course Title'),
('Cover Screen', 'CourseRelatedCourse', 'RelatedCourseId', 'Cross-Listed Course'),
('Basic Proposal Information', 'CourseContributor', 'UserId', 'Co-Contributor'),
('Proposal Information', 'CourseProposal', 'ExplainChange', 'Summary of Changes'),
('Proposal Information', 'Course', 'CourseNeed', 'Justification of Need'),
('Proposal Information', 'Course', 'AppropriateToMission', 'Mission Appropriateness'),
('Proposal Information', 'GenericMaxText', 'TextMax01', 'Program or Institutional Learning Outcomes'),
('Proposal Information', 'Course', 'Feasibility', 'Demand & Enrollment Projections'),
('Proposal Information', 'CourseYesNo', 'YesNo08Id', 'Curriculum Duplication'),
('Proposal Information', 'GenericMaxText', 'TextMax04', 'Institutional Support'),
('Course Details', 'Course', 'Description', 'Catalog Description'),
('Course Details', 'CourseDescription', 'MinLectureHour', 'Lecture Hours (Min)'),
('Course of Record', 'CourseDescription', 'MinLabHour', 'Lab Hours (Min)'),
('Course of Record', 'CourseDescription', 'InClassHour', 'Out-of-Class Hours (Min)'),
('Course Details', 'CourseYesNo', 'YesNo07Id', 'Requisites, Entrance Skills, and Advisories'),
('NULL', 'GenericMaxText', 'TextMax08', 'Strategies to Make Course Accessible to Disabled Students'),
('NULL', 'GenericMaxText', 'TextMax11', 'ADA Compliance'),
('NULL', 'CourseDistanceEducationAdaptation', 'CommunicationText', 'Inform Students'),
('NULL', 'GenericMaxText', 'TextMax12', 'Training'),
('Chancellor''s Office Requirements', 'CourseCBCode', 'CB03Id', 'CB03 TOP Code'),
('Chancellor''s Office Requirements', 'CourseAttribute', 'StateTransferTypeId', 'CB05 Course Transfer Status'),
('Chancellor''s Office Requirements', 'CourseSamCode', 'SamCodeId', 'CB09 SAM Code'),
('Chancellor''s Office Requirements', 'CourseAttribute', 'ClassificationCodeId', 'CB11 California Classification'),
('Chancellor''s Office Requirements', 'CourseAttribute', 'SpecialClassCodeId', 'CB13 Special Class Status'),
('Chancellor''s Office Requirements', 'CourseAttribute', 'PriorSkillId', 'CB21 Prior Transfer Level'),
('Chancellor''s Office Requirements', 'CourseAttribute', 'NonCreditCodeId', 'CB22 Non Credit Course Category'),
('Chancellor''s Office Requirements', 'CourseAttribute', 'FundCategoryId', 'CB23 Funding Agency Category'),
('Chancellor''s Office Requirements', 'CourseAttribute', 'CourseProgramStatusId', 'CB24 Program Course Status'),
('Chancellor''s Office Requirements', 'CourseCBCode', 'CB26Id', 'CB26 - Course Support Course Status'),
('Chancellor''s Office Requirements', 'GenericDate', 'Date05', 'Date Originally Approved by Board of Trustees'),
('Chancellor''s Office Requirements', 'GenericDate', 'Date07', 'Date of Next Review (Month and Year)')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)	
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
INSERT INTO MetaSelectedFieldAttribute
(Name,Value, MetaSelectedFieldId)
SELECT 'helptext', 'This is the full title as it will appear in the catalog', FieldId FROM @Fields WHERE Action = 'Course Title'
UNION
SELECT 'helptext', 'Banner has a 30 character limit for course titles, including spaces. This is what will show up on a transcript.', FieldId FROM @Fields WHERE Action = 'Banner Course Title'
UNION
SELECT 'helptext', 'Include a complete list of all changes made (e.g., Textbook update, DL request, new representative assignments, etc.).', FieldId FROM @Fields WHERE Action = 'Summary of Changes'
UNION
SELECT 'helptext', 'Provide a brief statement to describe 1) <b>Why</b> this program change or program addition is being made. In other words, what was the catalyst? (Example: survey data, advisory committee recommendation, program review data, etc.) and 2) <b>How</b> this course addition or modification will meet student, employer, or community needs. Upload supporting documents in the Attachments tab.', FieldId FROM @Fields WHERE Action = 'Justification of Need'
UNION
SELECT 'helptext', 'How is this course, as proposed or modified here, aligned to Hancock''s mission: Allan Hancock College fosters an educational culture that values equity and diversity and engages students in an inclusive learning environment. We offer pathways that encourage our student population to achieve personal, career, and academic goals through coursework leading to skills building, certificates, associate degrees, and transfer.', FieldId FROM @Fields WHERE Action = 'Mission Appropriateness'
UNION
SELECT 'helptext', 'If this course is a required or recommended component of a program, describe how this course supports the acheivement of Program Learning Outcomes. If not, describe how it supports Institutional Learning Outcomes.', FieldId FROM @Fields WHERE Action = 'Program or Institutional Learning Outcomes'
UNION
SELECT 'helptext', 'What evidence of demand do you have for this course, and what are your enrollment projections? Upload supporting documents in the Attachments tab.', FieldId FROM @Fields WHERE Action = 'Demand & Enrollment Projections'
UNION
SELECT 'helptext', 'Is this or similar course content offered elsewhere in the college or at a nearby institution of learning? If so, please explain.', FieldId FROM @Fields WHERE Action = 'Curriculum Duplication'
UNION
SELECT 'helptext', 'What evidence of institutional support do you have for this course? For example, have other faculty shared enthusiasm for how this will serve our students?  ', FieldId FROM @Fields WHERE Action = 'Institutional Support'
UNION
SELECT 'helptext', 'This description is exactly what will appear in the catalog. If cross-listed with another course, it <b><u>must</u></b> be indicated here.', FieldId FROM @Fields WHERE Action = 'Catalog Description'
UNION
SELECT 'helptext', 'Weekly hours. Min and max are often the same.', FieldId FROM @Fields WHERE Action = 'Lecture Hours (Min)'
UNION
SELECT 'helptext', 'Weekly hours. Min and max are often the same.', FieldId FROM @Fields WHERE Action = 'Lab Hours (Min)'
UNION
SELECT 'helptext', 'Weekly hours. Min and max are often the same. this is usually twice the number of weekly lecture hours (regardless of lab hours). For example, 3 hours of lecture and 1 hour of lab, typically means 6 hours of out-of-class work.', FieldId FROM @Fields WHERE Action = 'Out-of-Class Hours (Min)'
UNION
SELECT 'helptext', 'Does this course have any pre-requisites, co-requisites, required entrance skills, or advisories? If yes, please provide justification.', FieldId FROM @Fields WHERE Action = 'Requisites, Entrance Skills, and Advisories'
UNION
SELECT 'helptext', 'The Americans with Disabilities Act of 1990, section 508 of the Rehabilitation Act of 1973, and California Government Code section 11135 all require that accessibility for persons with disabilities be provided. Title 5, section 55200 explicitly makes these requirements applicable to all distance learning offerings. All DL courses and resources must be designed to afford students with disabilities maximum opportunity to access distance learning resources without the need for outside assistance (i.e. sign language interpreters, aides, etc.). Distance learning courses and resources must generally be designed to provide “built-in” accommodation (i.e. closed or open captioning, “alt tags”) which are accessible to “industry standard” assistive computer technology in common use by persons with disabilities. All courses must meet the WCAG 2.0 level AA standards including but not limited to the items listed below', FieldId FROM @Fields WHERE Action = 'Strategies to Make Course Accessible to Disabled Students'
UNION
SELECT 'helptext', 'Indicate the nature of the technical assistance that will be required to offer this course and make it ADA compliant', FieldId FROM @Fields WHERE Action = 'ADA Compliance'
UNION
SELECT 'helptext', 'Describe below how you will inform students about on-line services for students.', FieldId FROM @Fields WHERE Action = 'Inform Students'
UNION
SELECT 'helptext', 'What DL training and/or expertise does the initiator have in order to teach this course? Please be aware that such training must also be in place for any other instructor teaching the course besides the course initiator. (State here any training obtained prior to designing proposed DL Request.)', FieldId FROM @Fields WHERE Action = 'Training'
UNION
SELECT 'helptext', 'If the course is CTE, this must be a CTE TOP code indicated by an asterisk. If it is not a CTE program, it must not be a CTE TOP code.', FieldId FROM @Fields WHERE Action = 'CB03 TOP Code'
UNION
SELECT 'helptext', 'Non-transferable or CSU only, unless the Articulation Officer has confirmed otherwise.', FieldId FROM @Fields WHERE Action = 'CB05 Course Transfer Status'
UNION
SELECT 'helptext', 'For CTE courses (TOP code has an asterisk), this must be Apprenticeship, Advanced Occupational, Clearly Occupational, or Possibly Occupational. For non-CTE, it must be Non-Occupational.', FieldId FROM @Fields WHERE Action = 'CB09 SAM Code'
UNION
SELECT 'helptext', 'If this is a credit course, choose Y. If it is a non-credit course, please work with the appropriate dean to determine funding source.', FieldId FROM @Fields WHERE Action = 'CB11 California Classification'
UNION
SELECT 'helptext', 'Is this course an approved special class for students with disabilities, according to Title 5 section 56028?', FieldId FROM @Fields WHERE Action = 'CB13 Special Class Status'
UNION
SELECT 'helptext', 'If this course is transfer level, choose Y. Otherwise choose how many years prior to transfer level.', FieldId FROM @Fields WHERE Action = 'CB21 Prior Transfer Level'
UNION
SELECT 'helptext', 'If this is a credit course, choose Y. If it is a non-credit course, please work with the appropriate dean to determine category.', FieldId FROM @Fields WHERE Action = 'CB22 Non Credit Course Category'
UNION
SELECT 'helptext', 'If no Economic Development funds were used to develop this course, choose Y. Otherwise, please work with the appropriate dean to determine percentage of funding.', FieldId FROM @Fields WHERE Action = 'CB23 Funding Agency Category'
UNION
SELECT 'helptext', 'Is this course part of a sequence of courses leading to the completion of a program, such as a certificate or degree?', FieldId FROM @Fields WHERE Action = 'CB24 Program Course Status'
UNION
SELECT 'helptext', 'Is this course designed to support another course that is degree-applicable?', FieldId FROM @Fields WHERE Action = 'CB26 - Course Support Course Status'
UNION
SELECT 'helptext', 'If this is a new course, you will not have this information. If this is a modification, this date will appear on the COR.', FieldId FROM @Fields WHERE Action = 'Date Originally Approved by Board of Trustees'
UNION
SELECT 'helptext', 'For CTE courses, this is two years from the launch date of this proposal. For all other courses, this is 6 years from the launch date of this proposal. ', FieldId FROM @Fields WHERE Action = 'Date of Next Review (Month and Year)'

UPDATE MetaSelectedSection
SET SectionDescription = 'If this is cross-listed with another course, it must be noted in the catalog description.'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Cross-Listed Course'
)

UPDATE MetaSelectedSection
SET SectionDescription = 'If you would like someone to have equal permissions to make changes on this proposal, indicate that person here. For cross-listed courses, it is highly recommended to include the discipline related faculty as a Co-Contributor. If you are unable to do so, they may not have the right department or subject permissions. In that case, please contact your Curriculum Specialist. Note: Only originators can launch a proposal.'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Co-Contributor'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------
Declare	@Entitytypeid2 int =2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
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
('Program Information', 'Program', 'Title','T'),
('Program Information', 'Program', 'TitleAlias', 'Abbreviated Program Title'),
('Program Information', 'ProgramYesNo', 'YesNo11Id', 'CTE'),
('Program Mapper', 'CourseOption', 'CourseOptionNote', 'Map'),
('Proposal Information', 'ProgramProposal', 'Justification', 'Justification of Need'),
('Proposal Information', 'GenericMaxText', 'TextMax01', 'Mission Appropriateness'),
('Proposal Information', 'Program', 'CertificationApproximateCost', 'Master Planning: Narrative Item 4'),
('Proposal Information', 'GenericInt', 'Int05', 'Enrollment and Completer Projections: Narrative Item 5'),
('Proposal Information', 'GenericMaxText', 'TextMax06', 'Data to Support Demand'),
('Proposal Information', 'Program', 'Appropriateness', 'Place of Program in Existing Curriculum: Narrative Item 6'),
('Proposal Information', 'Program', 'EmployerRelationshipDescription', 'Similar Programs in the Service Area: Narrative Item 7'),
('Proposal Information', 'GenericMaxText', 'TextMax07', 'Transfer Preparation: Narrative Item 8'),
('Institutional Requirements', 'GenericMaxText', 'TextMax08', 'Faculty Need'),
('Needs', 'GenericMaxText', 'TextMax09', 'Faculty Need (Conditional)'),
('Needs', 'GenericMaxText', 'TextMax10', 'Support Staff'),
('Needs', 'GenericMaxText', 'TextMax11', 'Support Staff (Conditional)'),
('Needs', 'GenericMaxText', 'TextMax12', 'Necessary Resources'),
('Needs', 'GenericMaxText', 'TextMax13', 'Necessary Resources (Conditional)'),
('Needs', 'GenericMaxText', 'TextMax14', 'Equipment Needs'),
('Needs', 'GenericMaxText', 'TextMax15', 'Equipment Needs (Conditional)'),
('Needs', 'GenericMaxText', 'TextMax16', 'Library Material Needs'),
('Needs', 'GenericMaxText', 'TextMax17', 'Library Material Needs (Conditional)'),
('Needs', 'GenericMaxText', 'TextMax18', 'Other Costs'),
('Needs', 'GenericMaxText', 'TextMax19', 'Other Costs (Conditional)'),
('Needs', 'GenericMaxText', 'TextMax20', 'Total Costs'),
('Needs', 'GenericMaxText', 'TextMax21', 'Total Costs (Conditional)'),
('Institutional Requirements', 'ProgramDetail', 'Lookup01Id_01', 'Feasibility Analysis'),
('Institutional Requirements', 'Program', 'EnrollmentEffect', 'Funding Source(s)'),
('Chancellor''s Office Requirements', 'Program', 'AreaEmphasisUnits', 'Articulation Officer''s Page'),
('Chancellor''s Office Requirements', 'Program', 'ProgramTypeId', 'Program Goal'),
('Chancellor''s Office Requirements', 'ProgramCBCode', 'CB03Id', 'TOP Code'),
('Chancellor''s Office Requirements', 'Program', 'CipCodeId', 'CIP Code'),
('Chancellor''s Office Requirements', 'Program', 'CredentialId', 'Distance Education Percentage'),
('Chancellor''s Office Requirements', 'GenericDate', 'Date09', 'Board of Trustees Approval Date'),
('Chancellor''s Office Requirements', 'GenericDate', 'Date01', 'Next Program Review Date')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)	
where mt.MetaTemplateId  in (select * from @templateId2)

/********************** Changes go HERE **************************************************/
INSERT INTO MetaSelectedFieldAttribute
(Name,Value, MetaSelectedFieldId)
SELECT 'helptext', 'This is what will appear in the catalog.', FieldId FROM @Fields2 WHERE Action = 'T'
UNION
SELECT 'helptext', 'Banner has a 9 character limit for program titles. This is what will appear on transcripts.', FieldId FROM @Fields2 WHERE Action = 'Abbreviated Program Title'
UNION
SELECT 'helptext', 'For a program to be designated CTE, it must have a CTE TOP Code, indicated by an asterisk. For a current copy of the Taxonomy of Prorams (TOP) code manual, please reach out to your Curriculum Specialist.', FieldId FROM @Fields2 WHERE Action = 'CTE'
UNION
SELECT 'helptext', 'Provide a brief statement to describe why this course change or addition is being made. In other words, what was the catalyst? (Example: survey data, advisory committee recommendation, program review data, etc). Upload supporting documents in the Attachments tab.', FieldId FROM @Fields2 WHERE Action = 'Justification of Need'
UNION
SELECT 'helptext', 'How is this program, as proposed or modified here, aligned to Hancock''s mission: Allan Hancock College fosters an educational culture that values equity and diversity and engages students in an inclusive learning environment. We offer pathways that encourage our student population to achieve personal, career, and academic goals through coursework leading to skills building, certificates, associate degrees, and transfer.', FieldId FROM @Fields2 WHERE Action = 'Mission Appropriateness'
UNION
SELECT 'helptext', 'Vision for Success Link:  <a href="https://www.cccco.edu/About-Us/Vision-for-Success">https://www.cccco.edu/About-Us/Vision-for-Success</a> Work with Dean to identify how the Program fits into AHC and the State How does it align with the mission, curriculum, and master planning of the college and higher education in California. Does it provide a valid transfer, basic skills, or skilled workforce need? Refer to Institutional Planning & Shared Governance.', FieldId FROM @Fields2 WHERE Action = 'Master Planning: Narrative Item 4'
UNION
SELECT 'helptext', '<b>Either A)</b> final enrollment data for each included course or historical data for similar courese. Include Year 1 annual # of sections, Year 1 annual enrollment total, Year 2 annual # of sections, Year 2 annual enrollment total <b>OR B)</b> survey data, including the questionnaire, description of the surveyed population, and survey results. If the program is CTE, the survey results must be compared with net market labor demand.', FieldId FROM @Fields2 WHERE Action = 'Enrollment and Completer Projections: Narrative Item 5'
UNION
SELECT 'helptext', 'What evidence of demand do you have for this program? Upload supporting documents in the Attachments tab.', FieldId FROM @Fields2 WHERE Action = 'Data to Support Demand'
UNION
SELECT 'helptext', 'Are there similar or related programs already offered at the college? Is there any overlap, cross-listing, or duplication in other departments? Will this replace another program? What existing courses will be included? What new courses will be included?', FieldId FROM @Fields2 WHERE Action = 'Place of Program in Existing Curriculum: Narrative Item 6'
UNION
SELECT 'helptext', 'Are there similar or related programs already offered in the area?', FieldId FROM @Fields2 WHERE Action = 'Similar Programs in the Service Area: Narrative Item 7'
UNION
SELECT 'helptext', 'If transfer is one of the goals of this program, whether or not this is a "transfer" degree, explain how this program prepares students for transfer.', FieldId FROM @Fields2 WHERE Action = 'Transfer Preparation: Narrative Item 8'
UNION
SELECT 'helptext', 'How many full- and part-time faculty are necessary to successfully run this program? Do we currently have enough qualified faculty?', FieldId FROM @Fields2 WHERE Action = 'Faculty Need'
UNION
SELECT 'helptext', 'How will additional resources needs be met?', FieldId FROM @Fields2 WHERE Action = 'Faculty Need (Conditional)'
UNION
SELECT 'helptext', 'How many support staff people are necessary to successfully run this program? Do we currently have enough qualified staff?', FieldId FROM @Fields2 WHERE Action = 'Support Staff'
UNION
SELECT 'helptext', 'How will additional resources needs be met?', FieldId FROM @Fields2 WHERE Action = 'Support Staff (Conditional)'
UNION
SELECT 'helptext', 'What other resources (including classroom and lab spaces) are necessary to successfully run this program? Are current resources are adequate?', FieldId FROM @Fields2 WHERE Action = 'Necessary Resources'
UNION
SELECT 'helptext', 'How will additional resources needs be met?', FieldId FROM @Fields2 WHERE Action = 'Necessary Resources (Conditional)'
UNION
SELECT 'helptext', 'What equiptment necessary to successfully run this program? Are current resources are adequate?', FieldId FROM @Fields2 WHERE Action = 'Equipment Needs'
UNION
SELECT 'helptext', 'How will additional resources needs be met?', FieldId FROM @Fields2 WHERE Action = 'Equipment Needs (Conditional)'
UNION
SELECT 'helptext', 'What library resources are necessary to successfully run this program? Are current resources are adequate?', FieldId FROM @Fields2 WHERE Action = 'Library Material Needs'
UNION
SELECT 'helptext', 'How will additional resources needs be met?', FieldId FROM @Fields2 WHERE Action = 'Library Material Needs (Conditional)'
UNION
SELECT 'helptext', 'What other costs do you anticipate needing to successfully run this program? Are current resources are adequate?', FieldId FROM @Fields2 WHERE Action = 'Other Costs'
UNION
SELECT 'helptext', 'How will additional resources needs be met?', FieldId FROM @Fields2 WHERE Action = 'Other Costs (Conditional)'
UNION
SELECT 'helptext', 'What is the total cost of this program? Are current resources are adequate?', FieldId FROM @Fields2 WHERE Action = 'Total Costs'
UNION
SELECT 'helptext', 'How will additional resources needs be met?', FieldId FROM @Fields2 WHERE Action = 'Total Costs (Conditional)'
UNION
SELECT 'helptext', 'The Dean for this department…', FieldId FROM @Fields2 WHERE Action = 'Feasibility Analysis'
UNION
SELECT 'helptext', 'If specific funding sources are being used, name them here. This is typically for CTE. Otherwise, type N/A.', FieldId FROM @Fields2 WHERE Action = 'Funding Source(s)'
UNION
SELECT 'helptext', '(C) CTE: Limited to programs in CTE TOP codes, other than ADTs, (T) Transfer: All ADTs and Certificates of Acheivement for CSU GE Beadth, IGETC, or CalGETC, (O) Local: All other AA, AS, BA, BS, or Certificates not in a CTE TOP code', FieldId FROM @Fields2 WHERE Action = 'Program Goal'
UNION
SELECT 'helptext', 'If the program is CTE, this must be a CTE TOP code indicated by an asterisk. If it is not a CTE program, it must not be a CTE TOP code. If you are unsure of the TOP code, please consult your dean', FieldId FROM @Fields2 WHERE Action = 'TOP Code'
UNION
SELECT 'helptext', 'If you are unsure of the TOP code, please consult your dean', FieldId FROM @Fields2 WHERE Action = 'CIP Code'
UNION
SELECT 'helptext', 'Percentage of required units available through a distance education option.', FieldId FROM @Fields2 WHERE Action = 'Distance Education Percentage'
UNION
SELECT 'helptext', 'Curriculum Specialist Completes', FieldId FROM @Fields2 WHERE Action = 'Board of Trustees Approval Date'
UNION
SELECT 'helptext', 'For CTE programs, this is two years from the launch date of this proposal. For all other programs, this is 6 years from the launch date of this proposal. ', FieldId FROM @Fields2 WHERE Action = 'Next Program Review Date'

UPDATE MetaSelectedSection
SET SectionDescription = 'Work with your Articulation Officer to complete'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields2 WHERE Action = 'Map'
)

UPDATE MetaSelectedSection
SET SectionDescription = 'Curriculum Specialist Completes'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields2 WHERE Action = 'Articulation Officer''s Page'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields2)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback