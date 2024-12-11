USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13615';
DECLARE @Comments nvarchar(Max) = 
	'Create Modify Program Template, and set field to read only for users';
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
    AND mt.EndDate IS NULL
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
('Basic Program Information', 'Program', 'ProgramCode','Update')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	process int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, process)
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/

DECLARE @UserId int = (
SELECT Id FROM [User]
WHERE FirstName = 'Curriqunet'							--get user id
AND Username = 'SupportAdmin@CurriQunet.com'
)

EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 2, @Templatename = 'Program Modification' --copy new Program and Create Program Modification

DECLARE @Templateid2 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new program modification
DECLARE @Templatetypeid int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of program modifcation

EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Templateid2 , @metaTemplateTypeId = @Templatetypeid -- activates the new template

DECLARE @OldTT int = (
SELECT MetaTemplateTypeId 
FROM ProposalType
WHERE Title = 'Program Modification'		------Gets TemplateType currently being used and stores it for later
AND Active = 1
)

UPDATE ProposalType
SET MetaTemplateTypeId = @Templatetypeid
	WHERE Title = 'Program Modification'		------Sets program modification to be used now in the correct spot
	AND Active = 1

DECLARE @FieldId int = (
SELECT msf.MetaSelectedFieldId
FROM MetaSelectedField msf
    INNER JOIN MetaSelectedSection mss ON mss.MetaSelectedSectionId = msf.MetaSelectedSectionId				--gets the field id from the new template
	WHERE msf.MetaAvailableFieldId = 1659
    AND mss.MetaTemplateId = @Templateid2
)

DECLARE @AllFieldId integers
INSERT INTO @AllFieldId			--insert to have all fieldIds
SELECT FieldId FROM @Fields
UNION
SELECT @FieldId

UPDATE MetaSelectedField
SET IsRequired = 1
, AllowCopy = 1
WHERE MetaSelectedFieldId in (SELECT * FROM @AllFieldId)		--set required and copy on all forms to never lose data

DECLARE @FieldIdDel int = (SELECT FieldId FROM @Fields WHERE process = 14) --get field id of delete form for role permissions 

INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, RoleId, AccessRestrictionType)
VALUES
(@FieldId, 4, 1),													--customers requested changes
(@FieldId, 1, 2),
(@FieldIdDel, 1, 2),
(@FieldIdDel, 4, 1)

INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
select MetaReportId, @Templatetypeid, GETDATE()					--Insert Reports
from MetaReportTemplateType 
where MetaTemplateTypeId = @OldTT

/****************************** update templates ******************************************/
INSERT INTO @templateId
VALUES							--insert new templateid into table to keep updates below same
(@templateId2)

update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)					--update metareports

while exists(select top 1 1 from @templateId)
begin
    declare @TID int = (select top 1 * from @templateId)
    exec upUpdateEntitySectionSummary @entitytypeid = 6,@templateid = @TID		--badge update
    delete @templateId
    where id = @TID
end



--commit
--rollback