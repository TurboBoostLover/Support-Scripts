USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18798';
DECLARE @Comments nvarchar(Max) = 
	'Update text on Comprehensive PSR';
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
	@Entitytypeid int =6; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (40)		--comment back in if just doing some of the mtt's

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
('VISIONARY IMPROVEMENT PLANS', 'GenericMaxText', 'TextMax05','1'),
('VISIONARY IMPROVEMENT PLANS', 'GenericMaxText', 'TextMax11','2'),
('VISIONARY IMPROVEMENT PLANS', 'ModuleYesNo', 'YesNo01Id','3'),
('VISIONARY IMPROVEMENT PLANS', 'ModuleLookup01', 'Lookup01Id','4'),
('VISIONARY IMPROVEMENT PLANS', 'ModuleLookup09', 'Lookup09Id','5'),
('VISIONARY IMPROVEMENT PLANS', 'GenericMaxText', 'TextMax22','r'),
('VISIONARY IMPROVEMENT PLANS', 'GenericMaxText', 'TextMax29','r')


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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedSection
SET SectionName = 'DATA COLLECTION AND STRATEGIC PLANNING (Required)'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '1'
)

UPDATE MetaSelectedSection
SET DisplaySectionName = 0
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '2'
)

UPDATE MetaSelectedSection
SET SectionName = 'STUDENT SUPPORT OUTCOMES AND ASSESSMENT VISIONARY IMPROVEMENT PLAN (Required)'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '3'
)

UPDATE MetaSelectedSection
SET SectionName = 'SUCCESS, RETENTION, AND EQUITY VISIONARY IMPROVEMENT PLAN (Optional)'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '4'
)

UPDATE MetaSelectedSection
SET SectionName = 'OPTIMIZATION AND EFFICIENCY VISIONARY IMPROVEMENT PLAN (Optional)'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '5'
)

UPDATE MetaSelectedField
SET IsRequired = 0
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaselectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN @Fields AS f on msf.MetaSelectedSectionId = f.SectionId
	WHERE f.Action = 'r'
)

UPDATE MetaSelectedSection
SET RowPosition = RowPosition + 1
, SortOrder = SortOrder + 1
WHERE MetaSelectedSectionId in (
	SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN @Fields AS f on mss.MetaTemplateId = f.TemplateId
	WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
	and mss.RowPosition > 2
)

UPDATE MetaSelectedSection
SET RowPosition = 3
, SortOrder = 3
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = 'r'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback