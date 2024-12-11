USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15746';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Requisites tab to new forms';
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
('Requisites', 'CourseRequisite', 'RequisiteTypeId','Update'),
('Course Requisites', 'CourseRequisite', 'Requisite_CourseId', 'Update2'),
('Requisites', 'CourseQueryText', 'QueryTextId_10', 'Update3')

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
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 31
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update'
)

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update'
)

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update2'
)

DELETE FROM MetaSelectedSectionAttribute
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update2'
)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 1
, FieldTypeId = 5
, MetaAvailableFieldId = 8949
, ReadOnly = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update3'
)

UPDATE CourseRequisite
SET ListItemTypeId = 14
WHERE ListItemTypeId IS NULL

insert into MetaSelectedFieldAttribute
(Name,[Value],MetaSelectedFieldId)
SELECT 'FilterSubscriptionTable','CourseRequisite', FieldId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'FilterSubscriptionColumn','SubjectId', FieldId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'FilterTargetTable','CourseRequisite', FieldId FROM @Fields WHERE Action = 'Update2'
UNION
SELECT 'FilterTargetColumn','Requisite_CourseId', FieldId FROM @Fields WHERE Action = 'Update2'

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
select c.Id as Value,
s.SubjectCode + ' ' + c.CourseNumber + ' - ' + c.Title + ' (' + sa.Title + ')' as Text,
c.SubjectId AS FilterValue,
c.SubjectId AS filterValue
from Course c 
inner join [Subject] s on s.Id = c.SubjectId
inner join StatusAlias sa on sa.Id = c.StatusAliasId 
where c.Active = 1
and sa.StatusBaseId in(1, 2, 4, 6)
order by Text
"

DECLARE @RSQL NVARCHAR(MAX) = "
select s.SubjectCode + ' ' + c.CourseNumber + ' - ' + c.Title + ' (' + sa.Title + ')' as Text
from Course c
inner join [Subject] s on s.Id = c.SubjectId 
inner join StatusAlias sa on sa.Id = c.StatusAliasId
where c.Id = @id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseRequisite', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Course Look up based off subject', 3)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

DECLARE @mssa TABLE (Id INT, mssId INT, text nvarchar(max));
DECLARE @msfa TABLE (Id INT, msfId INT, text nvarchar(max));

INSERT INTO @msfa
SELECT Min(Id), MetaSelectedFieldId, name
FROM MetaSelectedFieldAttribute
GROUP BY MetaSelectedFieldId, Name, Value
HAVING COUNT(*) > 1

INSERT INTO @mssa
Select Min(Id), MetaSelectedSectionId, Name
FROM MetaSelectedSectionAttribute
GROUP BY MetaSelectedSectionId, Name, Value
HAVING COUNT(*) > 1

DELETE MetaSelectedSectionAttribute
WHERE Id IN (Select mssa.Id 
FROM MetaSelectedSectionAttribute mssa
	INNER JOIN @mssa msa ON mssa.Name = msa.text AND mssa.MetaSelectedSectionId = msa.mssId
WHERE mssa.Id != msa.Id)

DELETE MetaSelectedFieldAttribute
WHERE Id IN (Select msfa.Id 
FROM MetaSelectedFieldAttribute msfa
	INNER JOIN @msfa mfa ON msfa.Name = mfa.text AND msfa.MetaSelectedFieldId = mfa.msfId
WHERE msfa.Id != mfa.Id)

UPDATE MetaTemplate 
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId IN (
	SELECT mss.MetaTemplateId 
	FROM MetaTemplate mt 
		INNER JOIN MetaSelectedSection mss ON mss.MetaTemplateId = mt.MetaTemplateId
		INNER JOIN MetaSelectedField msf ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE (mss.MetaSelectedSectionId IN (
		SELECT mssId FROM @mssa
	))
	OR (MetaSelectedFieldId IN (
		SELECT msfId FROM @msfa
	))
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback