USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17772';
DECLARE @Comments nvarchar(Max) = 
	'Update Materials Revision form to only edit Materials tab for users';
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
		AND mtt.MetaTemplateTypeId in (5)		--comment back in if just doing some of the mtt's

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
('Cover', 'Course', 'CourseNumber','1'),
('General Education Proposal', 'CourseQueryText', 'QueryText_02','2')

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
DELETE FROM MetaSelectedSectionPositionPermission
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss 
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = 5
)
and PositionId = 70


INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, RoleId, AccessRestrictionType)
SELECT msf.MetaSElectedFieldID, 4, 1 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection as mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Fields AS f on mss.MetaTemplateId = f.TemplateId
WHERE msf.MetaSelectedFieldId not in (
	SELECT MetaSelectedFieldId FROM MetaSelectedFieldRolePermission
)
and msf.MetaAvailableFieldId not in (
	SELECT 3434
	UNION 
	SELECT 1698
	UNION
	SELECT MetaAvailableFieldId FROM MetaAvailableField WHERE TableName in ('CourseSoftware', 'CourseManual', 'CourseTextOther', 'CourseTextbook')
)
UNION
SELECT msf.MetaSElectedFieldID, 1, 2 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection as mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Fields AS f on mss.MetaTemplateId = f.TemplateId
WHERE msf.MetaSelectedFieldId not in (
	SELECT MetaSelectedFieldId FROM MetaSelectedFieldRolePermission
)
and msf.MetaAvailableFieldId not in (
	SELECT 3434
	UNION 
	SELECT 1698
	UNION
	SELECT MetaAvailableFieldId FROM MetaAvailableField WHERE TableName in ('CourseSoftware', 'CourseManual', 'CourseTextOther', 'CourseTextbook')
)

INSERT INTO MetaSelectedSectionRolePermission
(MetaSelectedSectionId, RoleId, AccessRestrictionType)
SELECT msf.MetaSelectedSectionId, 4, 1 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection as mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Fields AS f on mss.MetaTemplateId = f.TemplateId
WHERE  msf.MetaSelectedSectionId not in (
	SELECT MetaSelectedSectionId FROM MetaSelectedSection WHERE MetaBaseSchemaId in (116, 111, 102,118) and MetaBaseSchemaId IS NOT NULL
	UNION
	SELECT msf.MetaSelectedSectionId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN @Fields AS f on mss.MetaTemplateId = f.TemplateId
	WHERE msf.MetaAvailableFieldId in (
		1698, 3434
	)
)
UNION
SELECT msf.MetaSelectedSectionId, 1, 2 FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection as mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Fields AS f on mss.MetaTemplateId = f.TemplateId
WHERE msf.MetaSelectedSectionId not in (
	SELECT MetaSelectedSectionId FROM MetaSelectedSection WHERE MetaBaseSchemaId in (116, 111, 102,118) and MetaBaseSchemaId IS NOT NULL
		UNION
	SELECT msf.MetaSelectedSectionId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN @Fields AS f on mss.MetaTemplateId = f.TemplateId
	WHERE msf.MetaAvailableFieldId in (
		1698, 3434
	)
)

DELETE FROM MetaControlAttribute
WHERE MetaSelectedSectionId in (
	SELECT msf.MetaSelectedSectionId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection as mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN @Fields AS f on mss.MetaTemplateId = f.TemplateId
	WHERE msf.MetaSelectedSectionId not in (
		SELECT MetaSelectedSectionId FROM MetaSelectedSection WHERE MetaBaseSchemaId in (116, 111, 102,118) and MetaBaseSchemaId IS NOT NULL
)
)

UPDATE MetaSelectedField
SET IsRequired = 0
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSElectedFieldID FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection as mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN @Fields AS f on mss.MetaTemplateId = f.TemplateId
	WHERE msf.MetaAvailableFieldId not in (
		SELECT 3434
		UNION 
		SELECT 1698
		UNION
		SELECT MetaAvailableFieldId FROM MetaAvailableField WHERE TableName in ('CourseSoftware', 'CourseManual', 'CourseTextOther', 'CourseTextbook')
	)
)
and IsRequired = 1

DELETE FROM MetaControlAttribute WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '2'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback