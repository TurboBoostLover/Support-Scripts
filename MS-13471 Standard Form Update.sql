USE [siue];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13471';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Forms';
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
DEclare @clientId int =1, -- SELECT Id, Title FROM Client 
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
and mtt.ClientId = @clientId

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
('Corequisite and Prerequisite Catalog View', 'CourseRequisiteLimit', 'ReqLimitText','Width'),
('Senior Assignment and Graduate Assessment Plan', 'CourseProposal', 'ExplainChange', 'Move'),
('Online/Blended/Hybrid-Schedule Details', 'CourseDistanceEducationOffering', 'AdaptedSampleAssignment', 'End'),
('Online/Blended/Hybrid-Schedule Details', 'CourseDistanceEducationOffering', 'AdaptedEvaluationText', 'Start'),
('Online/Blended/Hybrid-Schedule Details', 'CourseDistanceEducationOffering', 'AdditionalResource', 'Comma'),
('Codes and Dates', 'CourseSeededlookup', 'CipCode_SeededId', 'Wider') 

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
Set Width = Width - 50
WHERE MetaSelectedFieldId in (SELECT FieldId from @Fields WHERE Action = 'Width')

UPDATE MetaSelectedField
Set DisplayName = 'End Time (specify a.m. or p.m.)'
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'End')

UPDATE MetaSelectedField
Set DisplayName = 'Start Time (specify a.m. or p.m.)'
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Start')

UPDATE MetaSelectedField
Set DisplayName = 'Assigned Building and Room'
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Comma')

UPDATE MetaSelectedField
Set Width = Width + 500
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Wider')

UPDATE MetaSelectedField
SET RowPosition = 0
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Move')

/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback