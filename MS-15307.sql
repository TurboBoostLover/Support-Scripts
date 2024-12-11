USE [evc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15307';
DECLARE @Comments nvarchar(Max) = 
	'Version template and relabel some fields';
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
UPDATE MetaTemplate
SET EndDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 2
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = 22
)

DECLARE @UserId int = (
SELECT Id FROM [User]
WHERE FirstName = 'Curriqunet'							--get user id
AND Username = 'SupportAdmin@CurriQunet.com'
)

EXEC spBuilderTemplateCopy @clientId = 22, @userId = @UserId,  @templateId = 842

DECLARE @Templateid2 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new program
DECLARE @Templatetypeid int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of new program

EXEC spBuilderTemplateActivate @clientId = 22, @metaTemplateId = @Templateid2 , @metaTemplateTypeId = @Templatetypeid -- activates the new template

----------------------------------------------------------------------------------------------------------------------------------
EXEC spBuilderTemplateCopy @clientId = 22, @userId = @UserId,  @templateId = 845

DECLARE @Templateid3 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new program
DECLARE @Templatetypeid2 int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of new program

EXEC spBuilderTemplateActivate @clientId = 22, @metaTemplateId = @Templateid3 , @metaTemplateTypeId = @Templatetypeid2 -- activates the new template

--------------------------------------------------------------------------------------------------------------------------------------
EXEC spBuilderTemplateCopy @clientId = 22, @userId = @UserId,  @templateId = 841

DECLARE @Templateid4 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new program
DECLARE @Templatetypeid3 int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of new program

EXEC spBuilderTemplateActivate @clientId = 22, @metaTemplateId = @Templateid4 , @metaTemplateTypeId = @Templatetypeid3 -- activates the new template
/**************************************************************************************************************************************/

Declare @clientId int =22, -- SELECT Id, Title FROM Client 
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
('Completed by Dean', 'GenericBit', 'Bit09','Update'),
('Completed by Dean', 'GenericBit', 'Bit10','Update2'),
('Completed by Dean', 'GenericBit', 'Bit05','Update3'),
('Completed by Dean', 'GenericBit', 'Bit04','Update4'),
('Completed by Dean', 'GenericBit', 'Bit06','Update5'),
('Completed by Dean', 'GenericBit', 'Bit03','Update6')

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
SET DisplayName= 'M - Certificate of Achievement (requiring 8 to less than 16 or 12 to less than 24 quarter semester units)'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedField
SET DisplayName= 'N - Certificate of Achievement (requiring 16 to less than 30 or 24 to less than 45 quarter semester units)'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

UPDATE MetaSelectedField
SET DisplayName= 'T - Certificate of Achievement (requiring 30 to less than 60 or 45 to less than 90 quarter semester units)'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update3'
)

UPDATE MetaSelectedField
SET DisplayName= 'F - Certificate of Achievement (requiring 8 to less than 16 or 12 to less than 24 quarter semester units)'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update4'
)

UPDATE MetaSelectedField
SET DisplayName= 'C - Certificate of Achievement (requiring 60 or more semester units or 90 or more quarter units) Noncredit Program (NIL)'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update5'
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update6'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback