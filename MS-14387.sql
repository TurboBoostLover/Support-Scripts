USE [clovis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14387';
DECLARE @Comments nvarchar(Max) = 
	'Update Static Text';
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
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (14, 15)		--comment back in if just doing some of the mtt's

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
('Cover', 'Program', 'Title','Update')

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
UPDATE MetaSelectedSection
SET SectionDescription = '<p>This form must be completed by initiating full-time discipline faculty and submitted to the Curriculum Committee for review prior to program development.</p><p>

Please note: if the proposed program is Career Technical Education (CTE), Labor Market Information (LMI) from the Centers of Excellence must be submitted with this Intent to Propose form when circulating for signatures. Open the link below for the online LMI request form and choose the Central/Mother Lode Region.</p>

<p><a href="https://coeccc.co1.qualtrics.com/jfe/form/SV_brb3ibflTxmTj7v"target="_blank">Centers of Excellence (COE) LMI Request Form</a></p>
'
, DisplaySectionDescription	 = 1
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = 'Update' and mtt = 14
)

UPDATE MetaSelectedSection
SET SectionDescription = '<p>This form must be completed by initiating full-time discipline faculty and submitted to the Curriculum Committee for review prior to program development.</p><p>

Please note: if the proposed program is Career Technical Education (CTE), Labor Market Information (LMI) from the Centers of Excellence must be submitted with this Intent to Propose form when circulating for signatures. Open the link below for the online LMI request form and choose the Central/Mother Lode Region.</p>

<p><a href="https://coeccc.co1.qualtrics.com/jfe/form/SV_brb3ibflTxmTj7v"target="_blank">Centers of Excellence (COE) LMI Request Form</a></p>
<p>Noncredit and Career Development and College Preparation Programs and required courses classified as  noncredit Career Development and College Preparation (CDCP) prepare students for employment or to
be successful in college level-credit coursework. In accordance with title 5, section 55151 colleges may  offer an approved sequence of noncredit courses that culminate in one of the following awards: 
Certificate of Competency, Certificate of Completion, or Adult High School Diploma.<mark>Source: PCAH, 8th edition, pg. 140</mark</P>  <p>As with all noncredit programs, the courses must first be approved before the college can submit a  proposal 
for a new CDCP program. CDCP funding for courses that are part of a CDCP program cannot  be received until the program is approved. <mark>Source: PCAH, 8th edition, pg. 140</mark></p>  
<p><b>Noncredit Program Development Criteria</b><br>  There are five criteria used by the Chancellor’s Office to approve credit and noncredit programs and  courses that are subject to Chancellor’s Office review.
They were derived from statute, regulation,  intersegmental agreements, guidelines provided by transfer institutions and industry, recommendations  of accrediting institutions, and the standards of good practice
established in the field of curriculum  design. These criteria have been endorsed by the community college system as an integral part of the  best practice for curriculum development. The five criteria are as follows.
Please attach a justification  for each criteria. <mark>Source: PCAH, 8th edition, pg. 140</mark></p>
'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = 'Update' and mtt = 15
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback