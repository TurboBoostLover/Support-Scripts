USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14442';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Outcome tab to be configured correctly';
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
    --AND mtt.IsPresentationView = 0		--need to do all program forms where this exist and reports as they are all configured the same
    AND mtt.ClientId = @clientId
		--AND mtt.MetaTemplateTypeId in ()		

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
('Outcomes', 'ProgramOutcomeMatching', 'ProgramSequenceId','Update'),
('Outcomes', 'ProgramOutcomeMatching', 'CourseOutcomeId', 'Update2')

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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '		SELECT DISTINCT
		pc.Id AS Value,
		c.EntityTitle AS Text
		FROM CourseOption AS co
		INNER JOIN ProgramCourse AS pc on pc.CourseOptionId = co.Id
		INNER JOIN Course As c on pc.CourseId = c.Id
		INNER JOIN CourseOutcome AS co2 on co2.CourseId = c.Id
		where co.ProgramId = @EntityId
		AND pc.IsCourseRequired = 1
		'
, ResolutionSql = '
Select c.EntityTitle as Text
		from CourseOption co
		inner join ProgramCourse pc on pc.CourseOptionId = co.Id
		inner join Course c on c.Id = pc.CourseId
		where c.id = @Id
'
WHERE Id = 149

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
SELECT 
    co.Id as Value
    ,pc.Id as filterValue
    ,co.SortOrder
    ,Coalesce(co.OutcomeText,co.OtherText) as Text 
FROM [CourseOutcome] co 
    INNER JOIN ProgramCourse pc ON co.CourseId = pc.CourseId 
		INNER JOIN CourseOption AS co2 on pc.CourseOptionId = co2.Id
    inner join ListItemType lit on lit.Id = co.ListItemTypeId and lit.ListItemTableName = ''CourseOutcome'' and lit.ListItemTitleColumn = ''OutcomeText''
WHERE co2.ProgramId = @entityId
ORDER BY co.SortOrder
'
WHERE Id = 91

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2729
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update'
)


UPDATE MetaSelectedFieldAttribute
SET Value = 'ProgramCourse'
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Update2')
AND Name = 'ParentLookupTable'

UPDATE MetaSelectedFieldAttribute
SET Value = 'ProgramCourseId'
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Update2')
AND Name = 'ParentLookupForeignKey'

DELETE FROM ProgramOutcomeMatching --Asked Client if I could wipe out there test data as they onlu have 3 mapping and got the go ahead so it doesn't need updating
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback