USE [hkapa];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18387';
DECLARE @Comments nvarchar(Max) = 
	'update Filtering of nesting Major';
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
('School(s)', 'CourseSchoolMajor', 'Lookup14Id','1'),
('Major(s)', 'CourseSchoolMajor', 'MaxText01','2')

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
DELETE FROM MetaDisplaySubscriber WHERE MetaDisplayRuleId in (
	SELECT Id FROM MetaDisplayRule
WHERE ExpressionId in (
	SELECT ExpressionId FROM ExpressionPart WHERE Operand1_MetaSelectedFieldId in (
		SELECT FieldID FROM @Fields WHERE Action = '2'
)
)
)

DELETE FROM MetaDisplayRule
WHERE ExpressionId in (
	SELECT ExpressionId FROM ExpressionPart WHERE Operand1_MetaSelectedFieldId in (
		SELECT FieldID FROM @Fields WHERE Action = '2'
)
)

DELETE FROM ExpressionPart WHERE Operand1_MetaSelectedFieldId in (
		SELECT FieldID FROM @Fields WHERE Action = '2'
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = '2'
)

DELETE FROM MetaSelectedSection
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '2'
)

DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1'
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'FilterSubscriptionTable', 'CourseSchool', FieldId fROM @Fields WHERE Action = '1'
UNION
SELECT 'FilterSubscriptionColumn', 'DisciplineTypeId', FieldId fROM @Fields WHERE Action = '1'
UNION
SELECT 'FilterTargetTable', 'CourseSchoolMajor', FieldId fROM @Fields WHERE Action = '1'
UNION
SELECT 'FilterTargetColumn', 'Lookup14Id', FieldId fROM @Fields WHERE Action = '1'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
select
    LU14.Id as Value
    ,LU14.Title as Text
	,cs.DisciplineTypeId as FilterValue 
from CourseSchool CS
	inner join OrganizationEntityDisciplineTypeLookup14Map map on CS.OrganizationEntityID = map.OrganizationEntityID
		and Cs.DisciplineTypeId = map.DisciplineTypeId
	inner join Lookup14 LU14 on LU14.Id = map.lookUp14id
	inner join CourseSchoolMajor CSM on CSM.id = @pkIdValue
		and CSM.CourseSchoolid = CS.id
order by LU14.Title
'
, LookupLoadTimingType = 3
WHERE Id = 102
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback