USE [socccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14830';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Reviews';
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
Declare @clientId int =2, -- SELECT Id, Title FROM Client 
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
		AND mtt.MetaTemplateTypeId in (41, 42)		--comment back in if just doing some of the mtt's

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
('Section I - Program Objectives', 'ModuleStrategicGoal', 'MaxText01','Update'),
('Section I - Program Objectives', 'ModuleStrategicGoal', 'StrategicGoalId','Update'),
('Section I - Program Objectives', 'ModuleStrategicGoal', 'MaxText02','Update2'),
('Section II - Action Steps', 'ModuleModuleObjective', 'ModuleStrategicGoalId','two'),
('Section II - Action Steps', 'ModuleModuleObjective', 'MaxText01','two'),
('Section II - Action Steps', 'ModuleModuleObjective', 'MaxText02','two')

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
Update MetaSelectedField
SET IsRequired = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId fROM @Fields
)

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('declare @entryCount int = (
    select count(*)
    from ModuleModuleObjective GOL
    where GOL.moduleId = @entityId
);
declare @ValidCount int = (
    select count(*)
    from ModuleStrategicGoal GOL
    where GOL.moduleId = @entityId
);

 
select cast(case when @entryCount <> @ValidCount then 0 else 1 end as bit) as IsValidCount;', 1)

DECLARE @SQL INT = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, MetaAttributeComparisonTypeId, CustomMessage, MetaSqlStatementId)
SELECT DISTINCT SectionId, 'Required steps', 'All things from section 1 need to be in section II', 6 ,6, 'Please match the amount to Section I.', @SQL FROM @Fields WHERE Action = 'two'

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 11094
, DefaultDisplayType = 'TelerikCombo'
, MetaPresentationTypeId = 33
, Width = 150
, WidthUnit = 1
, Height = 24
, ReadOnly = 0
, DisplayName = 'Objective'
, LabelVisible = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE action = 'Update2'
)

INSERT INTO ItemType
(Title, Description, ItemTableName, SortOrder, StartDate, ClientId)
VALUES
('Objective 1.1: Reduce and eliminate the achievement gap among underrepresented students', 1, 'ModuleStrategicGoal', 1, GETDATE(), 2),
('Objective 1.2: Reduce and eliminate the achievement gap for completion rates in transfer-level math and English', 1, 'ModuleStrategicGoal', 2, GETDATE(), 2),
('Objective 1.3: Reduce and eliminate the achievement gap between online and traditional classroom classes', 1, 'ModuleStrategicGoal', 3, GETDATE(), 2),
('Objective 1.4: Increase equity of access into college', 1, 'ModuleStrategicGoal', 4, GETDATE(), 2),
('Objective 1.5: Reduce and eliminate student Fall to Spring and Fall to Fall retention equity gapsO', 1, 'ModuleStrategicGoal', 5, GETDATE(), 2),
('Objective 1.6: Cultivate culturally responsive and inclusive learning and working environment free from explicit/implicit bias', 1, 'ModuleStrategicGoal', 6, GETDATE(), 2),
('Objective 1.7: Cultivate a culturally responsive and inclusive learning and working environment free from institutional bias', 1, 'ModuleStrategicGoal', 7, GETDATE(), 2),
('Objective 2.1: Increase the number of students annually who earn associate degrees, certificates, or 9 units in a CTE program that prepare them for an in-demand job', 2, 'ModuleStrategicGoal', 1, GETDATE(), 2),
('Objective 2.2: Increase the number of students transferring annually', 2, 'ModuleStrategicGoal', 2, GETDATE(), 2),
('Objective 2.3: Increase completion rates in transfer-level math and English', 2, 'ModuleStrategicGoal', 3, GETDATE(), 2),
('Objective 2.4: Increase course success in online and traditional classroom classes', 2, 'ModuleStrategicGoal', 4, GETDATE(), 2),
('Objective 2.5:Increase spring to spring and fall to fall retention', 2, 'ModuleStrategicGoal', 5, GETDATE(), 2),
('Objective 2.6: Increase the percent of exiting CTE students who report being employed in their field of study', 2, 'ModuleStrategicGoal', 6, GETDATE(), 2),
('Objective 2.7: Reduce average units accumulated by students who complete degrees', 2, 'ModuleStrategicGoal', 7, GETDATE(), 2),
('Objective 2.8: Implement educational programs and student services to Indicator non-traditional students', 2, 'ModuleStrategicGoal', 8, GETDATE(), 2),
('Objective 2.9: Increase and support the number of outside classroom learning opportunities available for students in each division (and participation in those opportunities)', 2, 'ModuleStrategicGoal', 9, GETDATE(), 2),
('Objective 2.10: Create and support inter-disciplinary learning opportunities both within and across the colleges', 2, 'ModuleStrategicGoal', 10, GETDATE(), 2),
('Objective 2.11: Increase the number of professional development opportunities for faculty and staff', 2, 'ModuleStrategicGoal', 11, GETDATE(), 2),
('Objective 3.1: Strengthen and expand industry engagement to support student learning, program development, and regional economic development', 3, 'ModuleStrategicGoal', 1, GETDATE(), 2),
('Objective 3.2: Increase the number of students who reporting obtaining a job closely related to their field of study that strongly support the regional economy', 3, 'ModuleStrategicGoal', 2, GETDATE(), 2),
('Objective 3.3: Increase participation in extended learning (community and adult education programs, and emeritus institutes)', 3, 'ModuleStrategicGoal', 3, GETDATE(), 2),
('Objective 3.4: Increase the number of students who earn college credits while still in high school', 3, 'ModuleStrategicGoal', 4, GETDATE(), 2),
('Objective 3.5: Increase partnerships with higher education institutions', 3, 'ModuleStrategicGoal', 5, GETDATE(), 2),
('Objective 3.6: Increase community participation in civic, athletic, and cultural events', 3, 'ModuleStrategicGoal', 6, GETDATE(), 2),
('Objective 4.1: Identify and streamline all institutional policies, practices, and processes pertaining to facilities and technology', 4, 'ModuleStrategicGoal', 1, GETDATE(), 2),
('Objective 4.2:Develop an organizational culture of collaboration across the district', 4, 'ModuleStrategicGoal', 2, GETDATE(), 2),
('Objective 4.3: Create a sustainable and robust participatory governance evaluation process', 4, 'ModuleStrategicGoal', 3, GETDATE(), 2),
('Objective 4.4: Provide enhanced student support with a student-centered design', 4, 'ModuleStrategicGoal', 4, GETDATE(), 2),
('Objective 4.5: Develop and build out the ATEP vision for the colleges including public-private partnerships', 4, 'ModuleStrategicGoal', 5, GETDATE(), 2)

INSERT INTO MetaSelectedFieldAttribute
(Name,[Value],MetaSelectedFieldId)
SELECT 'FilterSubscriptionTable','ModuleStrategicGoal', FieldId fROM @Fields WHERE action = 'Update2'
UNION
SELECT 'FilterSubscriptionColumn','StrategicGoalId', FieldId fROM @Fields WHERE action = 'Update2'
UNION
SELECT 'FilterTargetTable','ModuleStrategicGoal', FieldId fROM @Fields WHERE action = 'Update2'
UNION
SELECT 'FilterTargetColumn','ItemTypeId', FieldId fROM @Fields WHERE action = 'Update2'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'SELECT Id AS Value, Title AS Text, CAST(Description AS INT) AS FilterValue FROM ItemType WHERE ItemTableName = ''ModuleStrategicGoal'' '
, ResolutionSql = 'SELECT Id AS Value, Title AS Text FROM ItemType WHERE Id = @Id'
WHERE Id = 19
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback