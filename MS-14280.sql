USE [delta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14280';
DECLARE @Comments nvarchar(Max) = 
	'Add Custom Validation to the Instructional Program Review';
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
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (38)		--comment back in if just doing some of the mtt's

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
('Strategic Goals', 'ModuleGoal', 'Goal','Update')

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
INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('declare @PreviousCount int = (
    select count(*)
    from ModuleGoal MG
    where MG.moduleId = @entityId
		and mg.ListItemTypeId = 2
);

declare @NewCount int = (
    select count(*)
    from ModuleGoal MG
    where MG.moduleId = @entityId
		and mg.ListItemTypeId = 1
);

DECLARE @ValidPreviousCount int = (
		SELECT count(*)
		FROM ModuleGoal MG
		WHERE MG.ModuleId = @EntityId
		AND ListItemTypeId = 2
		AND Related_ModuleGoalId IS NOT NULL
		AND GoalStatusId IS NOT NULL
		AND GoalStatusId = 5
)

DECLARE @ValidPreviousCount2 int = (
		SELECT count(*)
		FROM ModuleGoal MG
		WHERE MG.ModuleId = @EntityId
		AND ListItemTypeId = 2
		AND Related_ModuleGoalId IS NOT NULL
		AND GoalStatusId IS NOT NULL
		AND GoalStatusId = 4
		AND LEN(MaxText01) > 1
)

DECLARE @ValidPreviousCount3 int = (
		SELECT count(*)
		FROM ModuleGoal MG
		WHERE MG.ModuleId = @EntityId
		AND ListItemTypeId = 2
		AND Related_ModuleGoalId IS NOT NULL
		AND GoalStatusId IS NOT NULL
		AND GoalStatusId = 2
		AND LEN(PlanToAchieveGoal) > 1
)

DECLARE @ValidNewCount int = (
		SELECT count(*)
		FROM ModuleGoal MG
		WHERE MG.ModuleId = @EntityId
		AND ListItemTypeId = 1
		AND LEN(Goal) > 1
		AND LEN(PlanToAchieveGoal) > 1
)

DECLARE @ValidPreviousCount4 int = (
	SUM(COALESCE(@ValidPreviousCount, 0) + COALESCE(@ValidPreviousCount2, 0) + COALESCE(@ValidPreviousCount3, 0))
)
 
select cast(case when @PreviousCount = @ValidPreviousCount4 and @NewCount = @ValidNewCount then 1 else 0 end as bit) as IsValidCount;', 1)

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId, 'All Fields Required', 6, 'All Required Fields Must Be Filled Out', @ID FROM @Fields


/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback