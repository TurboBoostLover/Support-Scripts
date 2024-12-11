USE [delta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14839';
DECLARE @Comments nvarchar(Max) = 
	'Update Group Check list to work on Maverick';
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
    --AND mtt.EntityTypeId = @entityTypeId
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
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
('Course Outcomes', 'CourseOutcomeClientLearningOutcome', 'ClientLearningOutcomeId','Update'),
('Program Outcomes', 'ClientLearningOutcomeProgramOutcome', 'ClientLearningOutcomeId','Update2'),
('Outcomes', 'CourseOutcome', 'OtherText', 'Update3'),
('Course Outcomes', 'CourseOutcomeGeneralEducationOutcome', 'GeneralEducationElementOutcomeId', 'Update4'),
('Outcomes', 'CourseQuestion', 'ProgramsAffect', 'Update5'),
('Program Learning Outcomes with PLO to ILO Mapping', 'ProgramOutcome', 'Outcome', 'Update6'),
('Program Outcomes', 'ProgramOutcomeMatching', 'CourseOutcomeId', 'Update7'),
('Program Learning Outcomes with PLO to ILO Mapping', 'ProgramYesNo', 'YesNo02Id', 'Update8')

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
DECLARE @T TABLE (mss int, msf int)
INSERT INTO @T
SELECT mss.MetaSelectedSectionId, msf.MetaSelectedFieldId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Fields AS f on mss.MetaSelectedSection_MetaSelectedSectionId = f.TabId
WHERE f.Action = 'Update'
AND msf.MetaAvailableFieldId IS NULL

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT msf from @T
)

DELETE FROM MetaSelectedSection
WHERE MetaSelectedSectionId in (
	SELECT mss from @T
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action in ('Update3', 'Update6')
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 31
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('Update3', 'Update6')
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 32
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('Update', 'Update2', 'Update4', 'Update7')
)

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('Update3', 'Update', 'Update2', 'Update4', 'Update6', 'Update7')
)
AND Name <> 'Recursive'

UPDATE MetaSelectedSectionAttribute
SET Value = 'TRUE'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('Update3', 'Update', 'Update2', 'Update4', 'Update6', 'Update7')
	)
AND Name = 'Recursive'

 UPDATE MetaSelectedField
 SET MetaPresentationTypeId = 28
 , DefaultDisplayType = 'DropDown'
 WHERE MetaSelectedFieldId in (
	SELECT FieldId fROM @Fields WHERE Action in ('Update', 'Update2')
 )

  insert into MetaSelectedSectionAttribute
(Name,[Value],MetaSelectedSectionId)
SELECT 'lookuptablename','CourseOutcomeClientLearningOutcome',SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'lookupcolumnname','ClientLearningOutcomeId',SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'columns','1', SectionId FROM @Fields WHERE Action in ('Update', 'Update2', 'Update4', 'Update7')
UNION
SELECT 'grouptablename', 'CourseOutcomeClientLearningOutcome', SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'groupcolumnname', 'ClientLearningOutcomeParentId', SectionId FROM @Fields WHERE Action = 'Update'
UNION
SELECT 'grouptablename', 'ClientLearningOutcomeProgramOutcome', SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'groupcolumnname', 'ClientLearningOutcomeParentId', SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'lookuptablename','ClientLearningOutcomeProgramOutcome',SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'lookupcolumnname','ClientLearningOutcomeId',SectionId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'lookuptablename','CourseOutcomeGeneralEducationOutcome',SectionId FROM @Fields WHERE Action = 'Update4'
UNION
SELECT 'lookupcolumnname','GeneralEducationElementOutcomeId',SectionId FROM @Fields WHERE Action = 'Update4'
UNION
SELECT 'lookuptablename','ProgramOutcomeMatching',SectionId FROM @Fields WHERE Action = 'Update7'
UNION
SELECT 'lookupcolumnname','CourseOutcomeId',SectionId FROM @Fields WHERE Action = 'Update7'

DECLARE @SQL NVARCHAR(MAX) = '
DROP TABLE IF EXISTS #Group

;WITH concatText (Id, courseOutcome, programTitle, awardTitle, programOutcome)
AS
(SELECT
		p.Id
	   ,co.OutcomeText
	   ,p.Title
	   ,at.Title
	   ,po.Outcome
	FROM CourseOutcome co
	INNER JOIN ProgramOutcomeMatching pom
		ON co.id = pom.courseoutcomeid
		AND co.CourseId = @entityId
	INNER JOIN ProgramOutcome po
		ON po.id = pom.ProgramOutcomeId
	INNER JOIN program p
		ON po.ProgramId = p.Id
	INNER JOIN AwardType at
		ON at.Id = p.AwardTypeId)
SELECT
	Id AS Value
   ,''<div><h4 style="color:black;">'' + programTitle + '' ('' + CAST(Id AS NVARCHAR) + '')/'' + awardTitle + '': '' + ISNULL(programOutcome, ''N/A'') + ''</h4><ul><li>'' + courseOutcome + ''</li></ul></div>'' AS Text
	 INTO #Group
FROM concatText

SELECT 0 AS Value,
dbo.ConcatWithSep_Agg('''', Text) AS Text FROM #Group

DROP TABLE #Group
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE ID = 171

DECLARE @SQL2 NVARCHAR(MAX) = '
DECLARE @TABLE TABLE (val int, txt2 nvarchar(max), txt nvarchar(max))
INSERT INTO @TABLE
select distinct
    0 as Value,
	c.entityTitle,
    ''<label style="color:red">'' + c.EntityTitle + '' - '' + sa.title + ''</label>'' as Text
from CourseOption co
    inner join ProgramCourse pc on pc.CourseOptionId = co.Id
    inner join course c on c.id = pc.CourseId
	inner join statusalias sa on sa.id = c.statusaliasid
where co.ProgramId = @entityId
and c.id not in (
    select distinct c.Id
    from ProgramOutcome po 
        inner join ProgramOutcomeMatching pom on pom.ProgramOutcomeId = po.Id
        inner join CourseOutcome co on co.id = pom.CourseOutcomeId
        inner join course c on c.id = co.CourseId
    where po.ProgramId = @entityId
)
order by c.EntityTitle

SELECT 0 AS Value,
dbo.ConcatWithSep_Agg('' '', txt) AS Text FROM @TABLE
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE ID = 247

UPDATE CourseOutcome
SET ListItemTypeId = 10
WHERE ListItemTypeId IS NULL

UPDATE ProgramOutcome
SET ListItemTypeId = 21
WHERE ListItemTypeId IS NULL

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 8953
, MetaPresentationTypeId = 1
, FieldTypeId = 5
, ReadOnly = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE action = 'Update5'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 9165
, MetaPresentationTypeId = 1
, FieldTypeId = 5
, ReadOnly = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE action = 'Update8'
)

UPDATE MetaSelectedSection
SET SectionName = 'General Education Learning Outcomes'
, DisplaySectionName = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update4'
)

DECLARE @sql3 nvarchar(max)=
'DECLARE @now DATETIME = getdate();
SELECT
	clo.Id AS Value
   ,''<b>'' + COALESCE(clo.Title, '''') + ''</b> '' + COALESCE(clo.Description, '''') + ''<br />'' AS Text
   ,clo.Parentid AS filterValue
   ,ISNULL(clo.SortOrder, clo.Id) AS SortOrder
   ,ISNULL(clop.SortOrder, clop.Id) AS FilterSortOrder,
   COALESCE(clo2.SortOrder, clop.SortOrder)
FROM ClientLearningOutcome clop
INNER JOIN ClientLearningOutcome clo
	ON clo.Parentid = clop.Id
Left Join ClientLearningOutcome clo2
	on clop.ParentId = clo2.Id
WHERE @now BETWEEN clo.StartDate AND ISNULL(clo.EndDate, @now)
AND Clo.ParentId IS NOT NULL
and (clop.id in (6,9,11,36,13) or clo2.id in (6,9,11,36,13))
ORDER BY COALESCE(clo2.SortOrder, clop.SortOrder), SortOrder',
	@resolution nvarchar(max)=
'select ''<b>'' +  Coalesce(clo.Title,'''') + ''</b> '' + Coalesce(clo.Description,'''')  as Text, clo.Parentid as filterValue, IsNull(clo.SortOrder, clo.Id) as sortOrder, IsNull(clop.SortOrder, clop.Id) as filterSortOrder From ClientLearningOutcome clop inner Join ClientLearningOutcome clo on clo.Parentid = clop.Id where clo.Id = @Id',
	@maxid int = (select max(id) from MetaForeignKeyCriteriaClient),
	@title nvarchar(100) = 'ILO group checklist childrends',
	@table nvarchar(100) = 'ClientLearningOutcome',
	@Timing int = 2;

Insert into MetaForeignKeyCriteriaClient(id, TableName, DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,Title,LookupLoadTimingType)
VALUES(@maxid+1,@table, 'id', 'title', @sql3, @resolution,@title,@Timing)

update MetaSelectedField
set MetaForeignKeyLookupSourceId = @maxid+1
WHERE MetaSelectedFieldid in (
	SELECT FieldId FROM @Fields WHERE Action in ('Update', 'Update2')
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

exec EntityExpand

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback