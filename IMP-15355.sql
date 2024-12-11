USE [cscc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-15355';
DECLARE @Comments nvarchar(Max) = 
	'Update tab to new forms';
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
  --  AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId

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
('Block Definitions', 'CourseOption', 'CourseOptionNote','Update'),
('Course Block Definitions', 'ProgramCourse', 'Header','Update2'),
('Course Block Definitions', 'ProgramCourse', 'SubjectId','Update3'),
('Course Block Definitions', 'ProgramCourse', 'Bit01','Update4'),
('Course Block Definitions', 'ProgramCourse', 'IsCourseRequired','Update5'),
('Course Block Definitions', 'ProgramCourse', 'NumberMin','Update6'),
('Course Block Definitions', 'ProgramCourse', 'ExceptionIdentifier','Update7'),
('Course Block Definitions', 'ProgramCourse', 'CourseId','Update8')

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
UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 31
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('Update', 'Update2')
)

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('Update', 'Update2')
)

INSERT INTO ListItemType
(Title, ListItemTypeOrdinal, ListItemTableName, ListItemTitleColumn, SortOrder, StartDate, ClientId)
VALUES
('Course Requirement', 1, 'ProgramCourse', 'CourseId', 1, GETDATE(), 1),
('Group', 2, 'ProgramCourse', 'ProgramCourseRule', 2, GETDATE(), 1),
('Non-Course Requirement', 3, 'ProgramCourse', 'MaxText02', 3, GETDATE(), 1),
('Program Requirement', 1, 'CourseOption', 'CourseOptionNote', 1, GETDATE(), 1)

UPDATE CourseOption SET ListItemTypeId = (SELECT Id FROM ListItemType WHERE ListItemTableName = 'CourseOption')

UPDATE ProgramCourse SET ListItemTypeId = (SELECT Id FROM ListItemType WHERE ListItemTableName = 'ProgramCourse' AND Title = 'Course Requirement')
WHERE CourseId IS NOT NULL

UPDATE ProgramCourse SET ListItemTypeId = (SELECT Id FROM ListItemType WHERE ListItemTableName = 'ProgramCourse' AND Title = 'Non-Course Requiremen')
WHERE CourseId IS NULL

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('Update3', 'Update4', 'Update5', 'Update6', 'Update7')
)

DECLARE @MAX int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', '
select 
    c.Id as Value    
    ,EntityTitle + '' - '' + sa.Title  as Text         
    ,s.Id as FilterValue
from Course c
    inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join Subject s on s.id = c.SubjectId
where c.Active = 1
AND sa.StatusBaseId != 5
UNION
select 
    c.Id as Value    
    ,EntityTitle + '' - '' + sa.Title  as Text         
    ,s.Id as FilterValue
from Course c
	inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join Subject s on s.id = c.SubjectId
	INNER JOIN ProgramCourse pc on pc.CourseId = c.id
	INNER JOIN CourseOption AS co on pc.CourseOptionId = co.Id AND co.ProgramId = @entityId
order by Text', 
'Select 
	CONCAT(c.EntityTitle, '' *'', sa.Title,''*'') as Text
	from Course AS c 
	inner join StatusAlias AS sa on c.StatusAliasId = sa.Id
	where c.Id = @Id',
'Order by SortOrder', 'ProgramCourse dropdown', 2)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update8'
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'FilterSubscriptionTable', 'ProgramCourse', FieldId FROM @Fields WHERE Action = 'Update8'
UNION
SELECT 'FilterSubscriptionColumn', 'SubjectId', FieldId FROM @Fields WHERE Action = 'Update8'
UNION
SELECT 'FilterTargetTable', 'ProgramCourse', FieldId FROM @Fields WHERE Action = 'Update8'
UNION
SELECT 'FilterTargetColumn', 'CourseId', FieldId FROM @Fields WHERE Action = 'Update8'

INSERT INTO MetaSelectedSectionAttribute
(GroupId, AttributeTypeId, Name, Value, MetaSelectedSectionId)
SELECT 1, 1, 'ListItemType1TitleTable', 'CourseOption', SectionId FROM @Fields
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback