USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14140';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Review Forms';
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
Declare @clientId int =4, -- SELECT Id, Title FROM Client 
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
		AND mtt.MetaTemplateTypeId in (42, 43)

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
('Resource Request', 'ModuleResourceRequest', 'ShortText02','Update'),
('Resource Request', 'ModuleResourceRequest', 'ShortText03','Update2'),
('Resource Request', 'ModuleResourceRequest', 'ShortText04','Update3'),
('Resource Request', 'ModuleResourceRequest', 'ShortText05','Update4'),
('Resource Request', 'ModuleResourceRequest', 'ShortText06','Update5'),
('Resource Request', 'ModuleResourceRequest', 'ShortText07','Update6')

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
DECLARE @MAX int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

DECLARE @SQL NVARCHAR(MAX) = '
SELECT 
	0 AS Value, 
	Int01 AS Text 
FROM Module AS m
LEFT JOIN ModuleFormQuestion AS mfq ON mfq.ModuleId = m.Id
LEFT JOIN FormQuestion AS fq ON mfq.FormQuestionId = fq.Id
WHERE m.Id = @entityId
AND fq.Id = 1
'

DECLARE @SQL2 NVARCHAR(MAX) = '
SELECT 
	0 AS Value, 
	Int01 AS Text 
FROM Module AS m
LEFT JOIN ModuleFormQuestion AS mfq ON mfq.ModuleId = m.Id
LEFT JOIN FormQuestion AS fq ON mfq.FormQuestionId = fq.Id
WHERE m.Id = @entityId
AND fq.Id = 2
'

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, Title, LookupLoadTimingType)
VALUES
(@MAX, 'ModuleQueryText', 'Id', 'Title', @SQL, @SQL, 'Full Time Faculty', 2),
(@MAX + 1, 'ModuleQueryText', 'Id', 'Title', @SQL2, @SQL2, 'Part Time Faculty', 2)

UPDATE MetaSelectedField
SET DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, FieldTypeId = 5
, MetaForeignKeyLookupSourceId = @MAX
, MetaAvailableFieldId = 6373
, ReadOnly = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedField
SET DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, FieldTypeId = 5
, MetaForeignKeyLookupSourceId = @MAX + 1
, MetaAvailableFieldId = 6374
, ReadOnly = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

UPDATE MetaSelectedField
SET DisplayName = '4.6.3 Planned retirements'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update3'
)

UPDATE MetaSelectedField
SET DisplayName = '4.6.4 Extenuating Circumstances'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update4'
)

UPDATE MetaSelectedField
SET DisplayName = '4.6.5 Year of last Full-time hire'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update5'
)

UPDATE MetaSelectedField
SET DisplayName = '4.6.6 Faculty Specialization'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update6'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

exec EntityExpand @clientId = 4

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback