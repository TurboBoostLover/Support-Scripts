USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16365';
DECLARE @Comments nvarchar(Max) = 
	'Updating GE tab';
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
Please do not alter the script above this comment� except to set
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
('General Education Proposal', 'CourseYesNo', 'YesNo08Id','1'),
('General Education Proposal', 'CourseGeneralEducation', 'GeneralEducationElementId', '2'),
('General Education Proposal', 'CourseYesNo', 'YesNo10Id', '3')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int,
	secorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt, secorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId, mss2.SortOrder
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
SET ReadOnly = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1'
)

UPDATE MetaSelectedSection
SET ReadOnly= 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '2' and secorder = 4
)

UPDATE MetaSelectedField
SET DisplayName = 'Plan 2 Cal-GETC (CSU and UC transfer)'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '3'
)

UPDATE MetaSelectedSection
SET SectionName = 'Plan 2 Cal-GETC (CSU and UC transfer):'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '2' and secorder = 8
)

UPDATE GeneralEducation
SET Title = 'Plan 2 Cal-GETC (CSU and UC transfer):'
WHERE Id = 4

UPDATE GeneralEducationElement 
SET Title = '1B. Critical Thinking Composition'
WHERE Id = 39

UPDATE GeneralEducationElement 
SET Title = '1C. Oral Communication'
WHERE Id = 40

UPDATE GeneralEducationElement 
SET Title = '2. Mathematical Concepts and Quantitative Reasoning'
WHERE Id = 41

UPDATE GeneralEducationElement 
SET Title = '4. Social Behavioral Sciences'
WHERE Id = 44

UPDATE GeneralEducationElement 
SET Title = '5C. Laboratory'
WHERE Id = 47

UPDATE GeneralEducationElement 
SET EndDate = GETDATE()
WHERE Id in (48, 49)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'declare @now datetime = getdate(); 
select gee.Id as Value, gee.Title as Text, ge.Id as filterValue, IsNull(gee.SortOrder, gee.Id) as SortOrder, IsNull(ge.SortOrder, ge.Id) as FilterSortOrder 
from  [GeneralEducation] ge 
inner join [GeneralEducationElement] gee on gee.GeneralEducationId = ge.Id 
where @now between gee.StartDate and IsNull(gee.EndDate, @now) and gee.Active = 1 AND ge.Title = ''Plan 2 Cal-GETC (CSU and UC transfer):''
Order By filterValue, SortOrder'
WHERE Id = 41

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'declare @now datetime = getdate(); 
select [Id] as Value, Title as Text 
from [GeneralEducation] 
where @now between StartDate and IsNull(EndDate, @now) and Title = ''Plan 2 Cal-GETC (CSU and UC transfer):''
Order By SortOrder'
WHERE Id = 40
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback