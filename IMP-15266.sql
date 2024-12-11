USE [sfu];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-15266';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Forms to new forms';
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
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
	AND mtt.MetaTemplateTypeId <> 9


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
('Codes/Dates', 'ProgramProposal', 'SemesterId','Update'),
('Admission', 'ProgramDetail', 'AdditionalAdmissionsRequirements', 'Update2'),
('Learning Methodologies', 'ProgramLearningMethod', 'LearningMethodId', 'Update3'),
('Graduate Information', 'Generic1000Text', 'Text100004', 'Update4'),
('Description', 'ProgramDescription', 'AnticipatedTime', 'Update5'),
('Executive Summary', 'Program', 'Emphasis', 'Update6')

declare @Fields table (
	FieldId int,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	id int identity
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
INSERT INTO @Fields
(FieldId, SectionId, Action, TabId, TemplateId, sortorder)
	SELECT NULL, mss.MetaSelectedSectionId, 'Delete', mss2.MetaSelectedSectionId, mt.MetaTemplateId, mss2.RowPosition FROM MetaSelectedSection as mss
	INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt ON mss2.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateId in (SELECT * FROM @templateId)
	AND mss2.SortOrder = -3
	AND mss2.RowPosition = -3

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId in (SELECT TabId FROM @Fields WHERE Action in ('Update', 'Update2', 'Update3', 'Update4', 'Update5', 'Update6'))

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 32
WHERE MetaSelectedSectionId in (SELECT SectionId FROM @Fields WHERE Action in ('Update3'))

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (SELECT SectionId FROM @Fields WHERE Action in ('Update3'))

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'lookuptablename', 'ProgramLearningMethod', SectionId FROM @Fields WHERE Action = 'Update3'
UNION
SELECT 'lookupcolumnname', 'LearningMethodId', SectionId FROM @Fields WHERE Action = 'Update3'
UNION
SELECT 'columns', '1', SectionId FROM @Fields WHERE Action = 'Update3'

DECLARE @GarbageTab int = (SELECT TabId FROM @Fields WHERE Action = 'Delete' And Id = 12)
DECLARE @GarbageTab2 int = (SELECT TabId FROM @Fields WHERE Action = 'Delete' And Id = 13)	
DECLARE @GarbageTab3 int = (SELECT TabId FROM @Fields WHERE Action = 'Delete' And Id = 14)	

DELETE FROM ProgramSectionSummary WHERE MetaSelectedSectionId in (@GarbageTab, @GarbageTab2, @GarbageTab3)

EXEC spBuilderSectionDelete @clientId, @GarbageTab
EXEC spBuilderSectionDelete @clientId, @GarbageTab2
EXEC spBuilderSectionDelete @clientId, @GarbageTab3
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback