USE [sdccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15295';
DECLARE @Comments nvarchar(Max) = 
	'Fix Cb custom SQL on Tech Review Tab';
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
('Tech Review and Dean View', 'CourseCBCode', 'CB10Id','10'),
('Tech Review and Dean View', 'CourseCBCode', 'CB11Id','11'),
('Tech Review and Dean View', 'CourseCBCode', 'CB13Id','13'),
('Tech Review and Dean View', 'CourseCBCode', 'CB21Id','21'),
('Tech Review and Dean View', 'CourseCBCode', 'CB23Id','23'),
('Tech Review and Dean View', 'CourseCBCode', 'CB25Id','25'),
('Tech Review and Dean View', 'CourseCBCode', 'CB26Id','26'),
('Tech Review and Dean View', 'CourseCBCode', 'CB27Id','27')

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
SET MetaForeignKeyLookupSourceId = 49
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = '10'
)


UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = 13
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = '11'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = 52
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = '13'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = 14
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = '21'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = 61
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = '23'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = 71
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = '25'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = 72
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = '26'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = 2813
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = '27'
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'subscription', f2.FieldId, f.FieldId FROM @Fields AS F
INNER JOIN @Fields AS f2 on f.TabId = f2.TabId
WHERE f.Action = '25'
and f2.Action = '21'

/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback