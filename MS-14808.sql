USE [socccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14808';
DECLARE @Comments nvarchar(Max) = 
	'Add Objectives as text under the goals on PR''s';
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
		AND mtt.MetaTemplateTypeId in (42, 41)		--comment back in if just doing some of the mtt's

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
('Section I: Unit Objectives', 'ModuleStrategicGoal', 'MaxText01','Ping'),
('Section I: Unit Objectives', 'ModuleStrategicGoal', 'StrategicGoalId','Ping2')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)	
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
SELECT 0 AS Value, 
CASE
	WHEN msg.StrategicGoalId = 1
	THEN
'
Objective 1.1: Reduce and eliminate the achievement gap among underrepresented students<br>
Objective 1.2: Reduce and eliminate the achievement gap for completion rates in transfer-level math and English<br>
Objective 1.3: Reduce and eliminate the achievement gap between online and traditional classroom classes<br>
Objective 1.4: Increase equity of access into college<br>
Objective 1.5: Reduce and eliminate student Fall to Spring and Fall to Fall retention equity gaps<br>
Objective 1.6: Cultivate culturally responsive and inclusive learning and working environment free from explicit/implicit bias<br>
Objective 1.7: Cultivate a culturally responsive and inclusive learning and working environment free from institutional bias
'
	WHEN msg.StrategicGoalId = 2
	THEN
'
Objective 2.1: Increase the number of students annually who earn associate degrees, certificates, or 9 units in a CTE program that prepare them for an in-demand job<br>
Objective 2.2: Increase the number of students transferring annually<br>
Objective 2.3: Increase completion rates in transfer-level math and English<br>
Objective 2.4: Increase course success in online and traditional classroom classes<br>
Objective 2.5:Increase spring to spring and fall to fall retention<br>
Objective 2.6: Increase the percent of exiting CTE students who report being employed in their field of study<br>
Objective 2.7: Reduce average units accumulated by students who complete degrees<br>
Objective 2.8: Implement educational programs and student services to Indicator non-traditional students<br>
Objective 2.9: Increase and support the number of outside classroom learning opportunities available for students in each division (and participation in those opportunities)<br>
Objective 2.10: Create and support inter-disciplinary learning opportunities both within and across the colleges<br>
Objective 2.11: Increase the number of professional development opportunities for faculty and staff<br>
'
	WHEN msg.StrategicGoalId = 3
	THEN
'
Objective 3.1: Strengthen and expand industry engagement to support student learning, program development, and regional economic development<br>
Objective 3.2: Increase the number of students who reporting obtaining a job closely related to their field of study that strongly support the regional economy<br>
Objective 3.3: Increase participation in extended learning (community and adult education programs, and emeritus institutes)<br>
Objective 3.4: Increase the number of students who earn college credits while still in high school<br>
Objective 3.5: Increase partnerships with higher education institutions<br>
Objective 3.6: Increase community participation in civic, athletic, and cultural events<br>
'
		WHEN msg.StrategicGoalId = 4
	THEN
'
Objective 4.1: Identify and streamline all institutional policies, practices, and processes pertaining to facilities and technology<br>
Objective 4.2:Develop an organizational culture of collaboration across the district<br>
Objective 4.3: Create a sustainable and robust participatory governance evaluation process<br>
Objective 4.4: Provide enhanced student support with a student-centered design<br>
Objective 4.5: Develop and build out the ATEP vision for the colleges including public-private partnerships<br>
'
END
AS Text
FROM ModuleStrategicGoal AS msg
WHERE ModuleId = @EntityId
AND msg.Id = @ContextId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'ModuleStrategicGoal', 'Id', 'Title', @CSQL, @CSQL, 'Order By SortOrder', 'Objectives to map', 3)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Test', -- [DisplayName]
11068, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
150, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = 'Ping'

DECLARE @TEST INT = SCOPE_IDENTITY()

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId fROM @Fields WHERE Action = 'Ping'
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 31
WHERE MetaSelectedSectionId in (
	SELECT SectionId fROM @Fields WHERE Action = 'Ping'
)

INSERT INTO ListItemType
(Title, ListItemTypeOrdinal, ListItemTableName, ListItemTitleColumn, SortOrder, StartDate, ClientId)
VALUES
('Objective', 1, 'ModuleStrategicGoal', 'MaxText01', 1, GETDATE(), 1)

DECLARE @Id int = SCOPE_IDENTITY()

UPDATE ModuleStrategicGoal
SET ListItemTypeId = @Id
WHERE ListItemTypeId IS NULL

UPDATE MetaSelectedField
SET RowPosition = 1
, LabelStyleId = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId fROM @Fields WHERE Action = 'Ping2'
)

UPDATE MetaSelectedField
SET RowPosition = 0
WHERE MetaSelectedFieldId in (
	SELECT FieldId fROM @Fields WHERE Action = 'Ping'
)

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, MetaAttributeComparisonTypeId, TotalCount, CustomMessage)
SELECT SectionId, 'Program Review Section 1', 'This list requires at least one entry', 5, 6, 1, 'One objective required' FROM @Fields WHERE Action = 'Ping'

insert into MetaSelectedFieldAttribute ([Name], [Value], MetaSelectedFieldId)
values
('UpdateSubscriptionMetaBaseSchemaId', 6301, @TEST)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback