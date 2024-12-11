USE [nukz];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17735';
DECLARE @Comments nvarchar(Max) = 
	'Update course form and make things required';
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
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
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
('General Course Information', 'GenericBit', 'Bit05','delete'),
('General Course Information', 'CourseChangeType', 'ChangeTypeId', 'check'),
('General Course Information', 'CourseDescription', 'TransferAppsId', '1'),
('General Course Information', 'CourseYesNo', 'YesNo02Id', '1'),
('General Course Information', 'GenericMaxText', 'TextMax07', '2')

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
UPDATE MetaSelectedField
SET IsRequired = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = '1' and mtt <> 26 --don't set it required on deactivations
)

DECLARE @Adios TABLE (SecId int, FieldId int)
INSERT INTO @Adios
SELECT SectionId, FieldId FROM @Fields WHERE Action = 'delete'

while exists(select top 1 1 from @Adios)
begin
    declare @Sec int = (SELECT Top 1 SecId FROM @Adios)
		declare @field int = (SELECT FieldId FROM @Adios WHERE SecId = @Sec)
		EXEC spBuilderSelectedFieldDelete @clientId, @sec, @field
    delete @Adios
    where FieldId = @field and SecId = @Sec
end

DELETE FROM MetaSelectedField WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'delete'
)

UPDATE MetaSelectedSection
SET SectionDescription = 'Please tick at least one checkbox.'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'check'
)

INSERT INTO ChangeType
(Text, ClientId, StartDate, SortOrder)
VALUES
('Other', 1, GETDATE(), 9)

DECLARE @Id int = SCOPE_IDENTITY()

INSERT INTO CourseChangeType
(CourseId, ChangeTypeId, CreatedDate)
SELECT CourseId, @Id, GETDATE() FROM GenericBit WHERE Bit05 = 1 and CourseId IS NOT NULL

UPDATE GenericBit
SET Bit05 = NULL
WHERE Id in (
	SELECT Id FROM GenericBit WHERE Bit05 IS NOT NULL and CourseId IS NOT NULL
)

UPDATE MetaSelectedField
SET IsRequired = 0
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '2'
)

INSERT INTO MEtaSelectedSectionSetting
(MetaSelectedSectionId, MinElem, IsRequired)
SELECT SectionId, 1, 1 FROM @Fields WHERE Action = 'check' and mtt <> 26
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback