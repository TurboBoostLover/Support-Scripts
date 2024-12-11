USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17801';
DECLARE @Comments nvarchar(Max) = 
	'Update Drop down to be in alpha order on annual unit plan';
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
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (17)		--comment back in if just doing some of the mtt's

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
('Goals', 'ModuleStrategicGoal', 'StrategicGoal','1')

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
DELETE FROM MetaControlAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields
)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @Subjects TABLE (Id int, txt NVARCHAR(MAX))
INSERT INTO @Subjects
exec spSubjectLookupByUserPermission @clientId, @userId, @entityId,6 /*Module*/

SELECT s.Id AS Value, s.txt AS Text, os.OrganizationEntityId AS FilterValue, os.OrganizationEntityId AS filterValue FROM @Subjects AS s
INNER JOIN OrganizationSubject AS os on os.SubjectId = s.Id
order by s.txt
'
WHERE id = 210

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
SELECT 
	oe.Id as Value, 
	oe.Title As Text, 
	ol.Parent_OrganizationEntityId As FilterValue
FROM  OrganizationLink ol 
	INNER JOIN OrganizationEntity oe ON oe.Id = ol.Child_OrganizationEntityId
WHERE oe.active = 1
ORDER BY oe.Title
'
WHERE id = 121

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('
DECLARE @ValidNew int = (
	SELECT Count(msg.Id) FROM ModuleStrategicGoal AS msg
	WHERE msg.ModuleId = @EntityId
	and StrategicGoal IS NOT NULL
	and StrategicGoalId IS NOT NULL
	and MaxText01 IS NOT NULL
	and SemesterId IS NOT NULL
	and MaxText02 IS NOT NULL
	and ItemTypeId IS NOT NULL
	and ListItemTypeId = 47
)

DECLARE @ValidOld int = (
	SELECT Count(msg.Id) FROM ModuleStrategicGoal AS msg
	WHERE msg.ModuleId = @EntityId
	and MaxText04 IS NOT NULL
	and StrategicGoalId IS NOT NULL
	and MaxText01 IS NOT NULL
	and SemesterId IS NOT NULL
	and MaxText03 IS NOT NULL
	and ListItemTypeId = 49
	and YesNoId_01 IS NOT NULL
)

DECLARE @Count int = (
	SELECT Count(msg.Id) FROM ModuleStrategicGoal AS msg
	WHERE msg.ModuleId = @EntityId
)

SELECT CASE
	WHEN @Count < 3 THEN 0
	WHEN @Count >= 3 and SUM(@ValidNew + @ValidOld) = @Count THEN 1
	ELSE 0
END AS ISValid
', 1)

DECLARE @Id int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'Goals', 'Require 3 goals to be entered', 6, 'A minimum of 3 goals must be added and all goals need to be completely filled out.', @Id FROM @Fields
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select Distinct templateId FROM @Fields
UNION
SELECT mss.MetaTemplateId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 210
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback