USE [nukz];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16769';
DECLARE @Comments nvarchar(Max) = 
	'Add Requiremnets to new course form';
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
		AND mtt.MetaTemplateTypeId in (1)		--comment back in if just doing some of the mtt's

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
('Course Outline', 'CourseObjective', 'Text','Update1'),
('Assessment Methods', 'CourseEvaluationMethod', 'EvaluationText', 'Update2'),
('Learning and Teaching Methods', 'CourseOutcome', 'OutcomeText', 'Update3'),
('Grading', 'CourseProposal', 'CreditTypeId', 'Update4'),
('Academic Integrity Statement', 'GenericMaxText', 'TextMax06', 'Update5'),
('Course Expectations', 'GenericMaxText', 'TextMax50', 'Update6')

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
	SELECT FieldId FROM @Fields WHERE Action in ('Update1', 'Update4', 'Update5', 'Update6')
)

DECLARE @SQL NVARCHAR(MAX) = '
declare @entryCount int = (
    select count(*)
    from CourseObjective CO
    where CourseId = @entityId
);
declare @ValidCount int = (
    select count(*)
    from CourseObjective CO
    where CourseId = @entityId
		and Text IS NOT NULL
);

select cast(case when @entryCount = @ValidCount then 1 else 0 end as bit) as IsValidCount;'

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
(@SQL, 1)

DECLARE @Id int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'Course Outline', 'Theme is Required', 6, 'Launch Requirement: All required fields must be filled out.', @Id FROM @Fields WHERE Action = 'Update1'

DECLARE @SQL2 NVARCHAR(MAX) = '
declare @entryCount int = (
    select count(*)
    from CourseEvaluationMethod CO
    where CourseId = @entityId
);
declare @ValidCount int = (
    select count(*)
    from CourseEvaluationMethod CO
		INNER JOIN CourseEvaluationMethodCourseOutcome AS cem on cem.CourseEvaluationMethodId = co.Id
    where CourseId = @entityId
		and EvaluationText IS NOT NULL
);

 
select cast(case when @entryCount = @ValidCount then 1 else 0 end as bit) as IsValidCount;
'

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
(@SQL2, 1)

DECLARE @Id2 int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'Assessment Methods', 'Required Fields need filled out', 6, 'Launch Requirement: All required fields must be filled out.', @Id2 FROM @Fields WHERE Action = 'Update2'

DECLARE @SQL3 NVARCHAR(MAX) = '
declare @entryCount int = (
    select count(*)
    from CourseOutcome CO
    where CourseId = @entityId
);
declare @ValidCount int = (
    select count(*)
    from CourseOutcome CO
		INNER JOIN CourseOutcomeInstructionType AS cem on cem.CourseOutcomeId = co.Id
		INNER JOIN InstructionType AS it on cem.InstructionTypeId = it.Id
    where CourseId = @entityId
		and It.Active = 1
);
declare @other int = (
	SELECT Count(*) FROM CourseOutcome
	WHERE OptionalText IS NOT NULL
	and CourseId = @EntityId
)

 
select cast(case when @entryCount = (ISNULL(@ValidCount, 0) + ISNULL(@other, 0)) then 1 else 0 end as bit) as IsValidCount;
'

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
(@SQL3, 1)

DECLARE @Id3 int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'Learning Methods', 'Required Fields need filled out', 6, 'Launch Requirement: All required fields must be filled out.', @Id3 FROM @Fields WHERE Action = 'Update3'
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback