USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16692';
DECLARE @Comments nvarchar(Max) = 
	'Clean Up Course Form';
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
('Course Standards', 'CourseFeeDesignator', 'FeeDesignatorId','label1'),
('Course Standards', 'CourseProposal', 'RepeatabilityId','label2'),
('Course Standards', 'Course', 'IsReadingExempt','label3'),
('Course Standards', 'CourseCBCode', 'CB21Id','label4'),
('Course Standards', 'CourseProposal', 'IsRequired3','label5'),
('Requisite Approval Form', 'Course', 'MinimumQualification', 'Explain'),
('Requisite Approval Form', 'Course', 'LearningAssessment', 'Explain'),
('Requisite Approval Form', 'CourseTransferInfo', 'CatalogStatement', 'Explain'),
('Requisite Approval Form', 'CourseHourType', 'Text4000_01', 'Explain'),
('Requisite Approval Form', 'CourseProposal', 'Safety', 'Explain'),
('Requisite Approval Form', 'CourseAdditionalResource', 'ResourceText', 'Explain')

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
DECLARE @ProposalResources INTEGERS
INSERT INTO @ProposalResources
SELECT MetaSelectedSectionId FROM MetaSelectedSection
WHERE SectionName = 'Proposal Resources'

while exists(select top 1 1 from @ProposalResources)
begin
    declare @TID int = (select top 1 * from @ProposalResources)
    EXEC spBuilderSectionDelete @clientId, @TID
    delete @ProposalResources
    where id = @TID
end

DECLARE @BadStaticText INTEGERS
INSERT INTO @BadStaticText
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE DisplayName like '%&nbsp%' and MetaAvailableFieldId IS NULL
UNION
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE DisplayName = '<span style="font-weight:600; font-size:small">Does this course meet any of the following characteristics? Select all that apply:</span>' and MetaAvailableFieldId IS NULL
UNION
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE DisplayName = '<span style="font-weight:bold;">Repeatability</span>' and MetaAvailableFieldId IS NULL
UNION
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE DisplayName = '<span style="font-weight:bold;">Approved Special Class</span>' and MetaAvailableFieldId IS NULL
UNION
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE DisplayName = '<span style="font-weight:bold;">Levels Below Transfer</span>' and MetaAvailableFieldId IS NULL
UNION
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE DisplayName = '<span style="font-weight:bold;">CTE</span>' and MetaAvailableFieldId IS NULL
UNION
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE DisplayName IS NULL and MetaAvailableFieldId IS NULL

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @BadStaticText
)

DECLARE @EmptySections INTEGERS
INSERT INTO @EmptySections
SELECT MetaSelectedSectionId FROM MetaSelectedSection
WHERE MetaSelectedSectionId not in (
	SELECT MetaSelectedSectionId FROM MetaSelectedField
	UNION
	SELECT MetaSelectedSection_MetaSelectedSectionId FROM MetaSelectedSection WHERE MetaSelectedSection_MetaSelectedSectionId IS NOT NULL
)

while exists(select top 1 1 from @EmptySections)
begin
    declare @TID2 int = (select top 1 * from @EmptySections)
    EXEC spBuilderSectionDelete @clientId, @TID2
    delete @EmptySections
    where id = @TID2
end

UPDATE MetaSelectedSection
SET SectionName = 'Does this course meet any of the following characteristics?'
,DisplaySectionName = 1
, SectionDescription ='Select all that apply:'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'label1'
)

UPDATE MetaSelectedSection
SET SectionName = 'Repeatability'
,DisplaySectionName = 1
, SectionDescription = NULL
, DisplaySectionDescription = 0
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'label2'
)

UPDATE MetaSelectedSection
SET SectionName = 'Approved Special Class'
,DisplaySectionName = 1
, SectionDescription = NULL
, DisplaySectionDescription = 0
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'label3'
)

UPDATE MetaSelectedSection
SET SectionName = 'Levels Below Transfer'
,DisplaySectionName = 1
, SectionDescription = NULL
, DisplaySectionDescription = 0
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'label4'
)

UPDATE MetaSelectedSection
SET SectionName = 'CTE'
,DisplaySectionName = 1
, SectionDescription = NULL
, DisplaySectionDescription = 0
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'label5'
)

UPDATE MetaSelectedField
SET DisplayName = 'Explain'
, LabelVisible = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Explain'
)

DECLARE @UnitsCB INTEGERS
INSERT INTO @UnitsCB
SELECT MetaSelectedFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE (mss2.SectionName like '%Units and%' or mss2.SectionName like '%Codes%' or mss2.SectionName like '%Course Standard%')
and msf.MetaAvailableFieldId =1002

DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @UnitsCB
)
and Name in ('triggersectionrefresh', 'enableBrowserBoundsDetection', 'dropDownWidth')

DECLARE @Sections2 INTEGERS
INSERT INTO @Sections2
SELECT MetaSelectedSectionId FROM MetaSelectedSection
WHERE SectionName like '%Course Standards%'
or SectionName like '%Conditions of Enrollment%'
or SectionName like '%Codes/Dates%'

DELETE FROM MetaSelectedFieldAttribute
WHERE Name = 'triggersectionrefresh'
and Value in (
	SELECT Id FROM @Sections2
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
WHERE 1= 1 --updating all templates since its going through and removing all empty sections and can affect multiple templates

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback