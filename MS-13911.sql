USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13911';
DECLARE @Comments nvarchar(Max) = 
	'Update Fresno New Service Program Review Tab I.';
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
	@Entitytypeid int =6; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
	AND mtt.MetaTemplateTypeId = 21

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
('I. Unit Overview', 'ModuleExtension01', 'LongText03','Update'),
('I. Unit Overview', 'ModuleExtension01', 'LongText04','Update2'),
('I. Unit Overview', 'ModuleExtension02', 'TextMax06','Update3')

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
DECLARE @Sec int = (SELECT SectionId FROM @Fields WHERE Action = 'Update')

DECLARE @Update4 int = (
	SELECT MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	WHERE mss.MetaSelectedSectionId = @Sec
	AND msf.RowPosition = 0
)

DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId = @Update4

DELETE MetaSelectedField 
WHERE MetaSelectedFieldId = @Update4

UPDATE MetaSelectedSection
SET SectionName = 'E. If applicable, complete the fields below identifying internal and/or external factors since the last comprehensive review that have impacted the service unit.'
, MetaBaseSchemaId = 571
, MetaSectionTypeId = 500
WHERE MetaSelectedSectionId = @Sec

insert into [MetaSelectedSectionAttribute]
([GroupId], [AttributeTypeId], [Name], [Value], [MetaSelectedSectionId])
VALUES
(1, 1, 'EmptyListText', ' Consider federal and state laws, changing demographics, characteristics of the population served by the service unit, changes in staffing, etc.', @Sec),
(1, 1, 'TitleTable', 'GenericOrderedList03', @Sec),
(1, 1, 'TitleColumn', 'ItemTypeId', @Sec),
(1, 1, 'SortOrderTable', 'GenericOrderedList03', @Sec),
(1, 1, 'SortOrderColumn', 'SortOrder', @Sec)

INSERT INTO [MetaSelectedFieldAttribute]
(Name, Value, MetaSelectedFieldId)
VALUES
('autoGrowMinHeight','200',(SELECT FieldId FROM @Fields WHERE Action = 'Update2')),
('autoGrowMinHeight','200',(SELECT FieldId FROM @Fields WHERE Action = 'Update3'))

INSERT INTO ItemType
(Title, Description, ItemTableName, SortOrder, StartDate, ClientId)
VALUES
('Internal', NULL, 'GenericOrderedList03', 0, GETDATE(), 1),
('External', NULL, 'GenericOrderedList03', 1, GETDATE(), 1)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 7056
, RowPosition = 0
, DefaultDisplayType = 'TelerikCombo'
, MetaPresentationTypeId = 33
, Width = 150
, FieldTypeId = 5
, DisplayName = 'Factor'
WHERE MetaSelectedFieldId = (SELECT FieldId FROM @Fields WHERE Action = 'Update')

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 416
, RowPosition = 1
, Height = 150
WHERE MetaSelectedFieldId = (SELECT FieldId FROM @Fields WHERE Action = 'Update2')

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 417
, RowPosition = 2
, Height = 150
WHERE MetaSelectedFieldId = (SELECT FieldId FROM @Fields WHERE Action = 'Update3')
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback