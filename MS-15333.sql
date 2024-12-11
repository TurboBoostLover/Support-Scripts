USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-';
DECLARE @Comments nvarchar(Max) = 
	'Update Old group checklist as it got missed when we did the rest';
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
('Learning Outcomes', 'ClientLearningOutcomeProgramOutcome', 'ClientLearningOutcomeId','Update'),
('Learning Outcomes', 'ProgramOutcomeMatching', 'CourseOutcomeId','Update2')

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
UPDATE MetaSelectedSection
SET MetaSectionTypeId = 32
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields
)

UPDATE MetaSelectedField
SET DefaultDisplayType = 'Checkbox'
, MetaPresentationTypeId = 5
WHERE MetaSelectedFieldId in (
	SELECT FieldId fROM @Fields
)

DELETE FROM MetaSelectedSectionAttribute 
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields
)

INSERT INTO MetaSelectedSectionAttribute
(Name,[Value],MetaSelectedSectionId)
SELECT 'lookuptablename','ClientLearningOutcomeProgramOutcome',SectionId FROM @Fields
UNION
SELECT 'lookupcolumnname','ClientLearningOutcomeId',SectionId FROM @Fields
UNION
SELECT 'columns','1',SectionId FROM @Fields
UNION
SELECT 'grouptablename', 'ClientLearningOutcomeProgramOutcome',SectionId FROM @Fields
UNION
SELECT 'groupcolumnname', 'ClientLearningOutcomeParentId',SectionId FROM @Fields

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
DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
DECLARE @now DATETIME = getdate();

select clo.Id as Value,
'<b>' +  Coalesce(clo.Title, '') + '</b> ' + Coalesce(clo.Description,'') + '<br />'  as Text,
clo.Parentid as filterValue,
clo.Parentid AS FilterValue,
IsNull(clo.SortOrder, clo.Id) as SortOrder,
IsNull(clop.SortOrder, clop.Id) as FilterSortOrder
From ClientLearningOutcome clop 
inner Join ClientLearningOutcome clo on clo.Parentid = clop.Id
WHERE @now between clo.StartDate
and IsNull(clo.EndDate, @now)
AND Clo.ParentId is NOT Null 
AND clo.ClientId = @ClientId  
Order By filterValue, SortOrder
"

DECLARE @RSQL NVARCHAR(MAX) = "
select '<b>' +  Coalesce(clo.Title,'') + '</b> ' + Coalesce(clo.Description,'')  as Text,
clo.Parentid as filterValue, 
clo.Parentid AS FilterValue,
IsNull(clo.SortOrder, clo.Id) as sortOrder, 
IsNull(clop.SortOrder, clop.Id) as filterSortOrder
From ClientLearningOutcome clop
inner Join ClientLearningOutcome clo on clo.Parentid = clop.Id
where clo.Id = @Id
"

DECLARE @CSQL2 NVARCHAR(MAX) = "
SELECT co.Id as Value,
pc.Id as filterValue,
pc.Id as FilterValue,
co.SortOrder,
Coalesce(co.OutcomeText,co.OtherText) as Text
FROM [CourseOutcome] co
INNER JOIN ProgramCourse pc ON co.CourseId = pc.CourseId 
INNER JOIN [CourseOption] cop ON pc.CourseOptionId = cop.Id
WHERE cop.ProgramId = @entityId 
ORDER BY co.SortOrder
"

DECLARE @RSQL2 NVARCHAR(MAX) = "
SELECT Coalesce(co.OutcomeText,co.OtherText) as Text FROM [CourseOutcome] co WHERE co.id = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'ClientLearningOutcome', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Group CheckList for Client Learning Outcome', 3),
(@MAX2, 'CourseOutcome', 'Id', 'Title', @CSQL2, @RSQL2, 'Order By SortOrder', 'Group CheckList for Course outomce', 3)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @Max
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = 'Update2'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @Max2
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action = 'Update'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback