USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17696';
DECLARE @Comments nvarchar(Max) = 
	'Create Modify SLO Course Template, and set fields to read only';
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
------------------------------------------------------------------------
DECLARE @UserId int = (
SELECT Id FROM [User]
WHERE FirstName = 'Curriqunet'							--get user id
AND Username = 'SupportAdmin@CurriQunet.com'
)

EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 18, @Templatename = 'SLO Modification' --copy new Program and Create Program Modification

DECLARE @Templateid2 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new program modification
DECLARE @Templatetypeid int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of program modifcation

EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Templateid2 , @metaTemplateTypeId = @Templatetypeid -- activates the new template
------------------------------------------------------------------------
declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = 1
		AND mtt.MetaTemplateTypeId = 39


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
('Course Learning Outcomes', 'CourseOutcome', 'OutcomeText','1')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
SELECT * FROM @Fields

INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
select MetaReportId, @Templatetypeid, GETDATE()					--Insert Reports
from MetaReportTemplateType 
where MetaTemplateTypeId = 18

INSERT INTO ProposalType
(ClientId, Title, EntityTypeId, ProcessActionTypeId, MetaTemplateTypeId, Active, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, CloneRequired, AllowDistrictClone, AllowCloning, HideProposalRequirementFields, AllowNonAdminReactivation)
VALUES
(1, 'SLO Modification', 1, 2, @Templatetypeid, 1, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0)

DECLARE @Id int = SCOPE_IDENTITY()

INSERT INTO ProcessProposalType
(ProposalTypeId, ProcessId)
VALUES
(@Id, 38)

UPDATE MetaSelectedField
SET ReadOnly = 1
, IsRequired = 0
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = @Templatetypeid
)
	and MetaSelectedFieldId not in (
		SELECT FieldId FROM @Fields WHERE Action = '1'
	)

UPDATE MetaSelectedSection
SET ReadOnly = 1
WHERE MetaSelectedSectionId in (
		SELECT mss.MetaSelectedSectionId FROM  MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = @Templatetypeid
)
	and MetaSelectedSectionId not in (
		SELECT SectionId FROM @Fields WHERE Action = '1'
	)

DELETE FROM MetaSelectedSectionSetting
WHERE MetaSelectedSectionId in (
		SELECT mss.MetaSelectedSectionId FROM  MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = @Templatetypeid
)
	and MetaSelectedSectionId not in (
		SELECT SectionId FROM @Fields WHERE Action = '1'
	)

DELETE FROM MEtaControlAttribute
WHERE MetaSelectedSectionId in (
		SELECT mss.MetaSelectedSectionId FROM  MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = @Templatetypeid
)
	and MetaSelectedSectionId not in (
		SELECT SectionId FROM @Fields WHERE Action = '1'
	)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)	

--commit
--rollback