USE [tacoma];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-15260';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Proposals to new forms';
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
	AND mtt.MetaTemplateTypeId <> 6


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
('Basic Award
 Information', 'Program', 'Title','Update'),
 ('Articulation', 'GenericMaxText', 'TextMax03', 'Update2'),
 ('Award Details', 'AwardOption', 'AwardTypeId', 'Update3'),
 ('Catalog Description', 'Program', 'Description', 'Update4'),
 ('Curriculum', 'ProgramSequence', 'SubjectId', 'Update5'),
 ('Pathway Sequence', 'GenericMaxText', 'TextMax01', 'Update6'),
 ('Program Learning Outcomes', 'ProgramOutcome', 'OutcomeText', 'Update7'),
 ('Program Learning Outcomes', 'ProgramOutcome', 'Text', 'Update8'),
 ('Program Learning Outcomes', 'ProgramOutcomeMatching', 'CourseOutcomeId', 'Update9'),
 ('Program Learning Outcomes', 'ClientLearningOutcomeProgramOutcome', 'ClientLearningOutcomeParentId', 'Update10'),
 ('Program Learning Outcomes', 'ProgramOutcomeMatching', 'ProgramSequenceId', 'Update11'),
 ('Program Learning Outcomes', 'ProgramYesNo', 'YesNo26Id', 'Update12')
 

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mfk int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mfk)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, msf.MetaForeignKeyLookupSourceId
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
DECLARE @Table TABLE (Id int identity, id2 int) 

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId in (SELECT TabId FROM @Fields) 

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId in (SELECT SectionId FROM @Fields WHERE Action = 'Update8')

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 31
WHERE MetaSelectedSectionId in (SELECT SectionId FROM @Fields WHERE Action in ('Update3', 'Update7'))

UPDATE MetaSelectedSection
Set MetaSectionTypeId = 32
WHERE MetaSelectedSectionId in (SELECT SectionId FROM @Fields WHERE Action in ('Update9', 'Update10')) 

INSERT INTO ListItemType
(Title, Description, ListItemTypeOrdinal, ListItemTableName, ListItemTitleColumn, SortOrder, StartDate, ClientId)
OUTPUT inserted.Id INTO @Table (id2)
VALUES
('Award', NULL, 1, 'AwardOption', 'AwardTypeId', 0, GETDATE(), @clientId),
('New Outcome', NULL, 1, 'ProgramOutcome', 'OutcomeText', 0, GETDATE(), @clientId)

DECLARE @Id int = (SELECT id2 FROM @Table WHERE Id = 1)
DECLARE @Id2 int = (SELECT id2 FROM @Table WHERE Id = 2)

UPDATE AwardOption
SET ListItemTypeId = @Id

UPDATE ProgramOutcome
SET ListItemTypeId = @Id2

DELETE FROM MetaSelectedSectionAttribute WHERE MetaSelectedSectionId in (SELECT SectionId FROM @Fields WHERE Action in ('Update7', 'Update8', 'Update9', 'Update10'))

INSERT INTO MetaSelectedSectionAttribute
(GroupId, AttributeTypeId, Name, Value, MetaSelectedSectionId)
SELECT 1, 1, 'columns', 1, SectionId FROM @Fields WHERE Action in('Update9', 'Update10')

INSERT INTO MetaSelectedSectionAttribute
(GroupId, AttributeTypeId, Name, Value, MetaSelectedSectionId)
SELECT 1, 1, 'lookupcolumnname', 'CourseOutcomeId', SectionId FROM @Fields WHERE Action = 'Update9'
UNION
SELECT 1, 1, 'lookuptablename', 'ProgramOutcomeMatching', SectionId FROM @Fields WHERE Action = 'Update9'
UNION
SELECT 1, 1, 'lookupcolumnname', 'ClientLearningOutcomeParentId', SectionId FROM @Fields WHERE Action = 'Update10'
UNION
SELECT 1, 1, 'lookuptablename', 'ClientLearningOutcomeProgramOutcome', SectionId FROM @Fields WHERE Action = 'Update10'
UNION
SELECT 1, 1, 'grouptablename', 'ProgramOutcomeMatching', SectionId FROM @Fields WHERE Action = 'Update11'
UNION
SELECT 1, 1, 'groupcolumnname', 'ProgramSequenceId', SectionId FROM @Fields WHERE Action = 'Update11'

DECLARE @MAXID int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) ="
DECLARE @Outcome TABLE (ProgramId INT, Id INT, CloTitle NVARCHAR(500), OutcomeText NVARCHAR(MAX), SortOrder INT, IterationOrder INT);

INSERT INTO @Outcome (ProgramId, Id, CloTitle, OutcomeText, SortOrder, IterationOrder)
	SELECT
		po.ProgramId
		,olo.Id
		,COALESCE(clo.Title, '') AS CloTitle
		,CAST(olo.OutcomeText AS NVARCHAR(MAX)) AS OutcomeText
		,olo.SortOrder
		,ROW_NUMBER() OVER (PARTITION BY olo.Id ORDER BY clo.SortOrder, clo.Id) AS IterationOrder
	FROM ClientLearningOutcome clo
	INNER JOIN OrganizationLevelOutcomeClientLearningOutcome oloclo
		ON clo.Id = oloclo.ClientLearningOutcomeId
	INNER JOIN OrganizationLevelOutcome olo
		ON oloclo.OrganizationLevelOutcomeId = olo.Id
	INNER JOIN ProgramOutcome po
		ON oloclo.OrganizationLevelOutcomeId = po.OrganizationLevelOutcomeId
	WHERE po.ProgramId = @EntityId;

;WITH CombinedOutcomes
AS
(SELECT
		ot.ProgramId
	   ,ot.Id
	   ,ot.IterationOrder
	   ,ot.SortOrder
	   ,'<strong>' + ot.OutcomeText + '</strong><br /><div>' + ot.CloTitle + '</div>' AS CombinedText
	   ,CASE
			WHEN NOT EXISTS (SELECT
						1
					FROM @Outcome ot_inner
					WHERE ot_inner.IterationOrder = (ot.IterationOrder + 1)
					AND ot_inner.Id = ot.Id) THEN 1
			ELSE 0
		END AS FinalRow
	FROM @Outcome ot
	WHERE ot.IterationOrder = 1 UNION ALL SELECT
		ot.ProgramId
	   ,ot.Id
	   ,ot.IterationOrder
	   ,ot.SortOrder
	   ,co.CombinedText +
		CASE
			WHEN co.Id <> co.Id THEN '</div><br /><div><div>' + ot.OutcomeText + '</div>'
			ELSE ''
		END + '<div>' + ot.CloTitle + '</div>' AS CombinedText
	   ,CASE
			WHEN NOT EXISTS (SELECT
						1
					FROM @Outcome ot_inner
					WHERE ot_inner.IterationOrder = (ot.IterationOrder + 1)
					AND ot_inner.Id = ot.Id) THEN 1
			ELSE 0
		END AS FinalRow
	FROM CombinedOutcomes co
	INNER JOIN @Outcome ot
		ON ((co.IterationOrder + 1) = ot.IterationOrder
		AND co.Id = ot.Id))
SELECT
	0 AS Value
   ,'<div>' + CombinedText + '</div>' AS Text
FROM CombinedOutcomes
WHERE FinalRow = 1
ORDER BY SortOrder;
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAXID, 'ProgramQueryText', 'Id', 'Title', @SQL, @SQL, NULL, 'PLO Query Text', 2)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 1
, FieldTypeId = 5
, ReadOnly = 1
, DefaultDisplayType = 'QueryText'
, MetaForeignKeyLookupSourceId = @MAXID
, MetaAvailableFieldId = 9165
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Update12')
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

exec EntityExpand

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

commit
--rollback