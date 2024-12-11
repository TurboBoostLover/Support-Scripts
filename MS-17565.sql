USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17565';
DECLARE @Comments nvarchar(Max) = 
	'Update Annual Unit Plan';
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
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
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
('Main', 'ModuleDetail', 'SubjectId','1'),
('Main', 'Module', 'SemesterId','2'),
('Goals', 'ModuleStrategicGoal', 'SemesterId', '3')

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
insert into MetaSelectedFieldAttribute
(Name,[Value],MetaSelectedFieldId)
SELECT 'FilterSubscriptionTable','ModuleDetail', FieldId FROM @Fields WHERE Action = '1'
UNION
SELECT 'FilterSubscriptionColumn','Tier2_OrganizationEntityId', FieldId FROM @Fields WHERE Action = '1'

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
DECLARE @Subjects TABLE (Id int, txt NVARCHAR(MAX))
INSERT INTO @Subjects
exec spSubjectLookupByUserPermission @clientId, @userId, @entityId,6 /*Module*/

SELECT s.Id AS Value, s.txt AS Text, os.OrganizationEntityId AS FilterValue, os.OrganizationEntityId AS filterValue FROM @Subjects AS s
INNER JOIN OrganizationSubject AS os on os.SubjectId = s.Id
"

DECLARE @RSQL NVARCHAR(MAX) = "
SELECT Id AS Value, CONCAT('(',SubjectCode,') ', Title) FROM Subject WHERE Id = @Id
"

DECLARE @Sq NVARCHAR(MAX) = "
select [Id] as [Value], (Title) as [Text]
from [Semester] 
where Active = 1 
and ([ClientId] = 1) 
and TermEndDate > GETDATE()
Order By SortOrder
"

DECLARE @Sq2 NVARCHAR(MAX) = "
select (Title) as [Text] 
from [Semester] 
where [Id] = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Subject', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'FilteredSubject', 3),
(@MAX2, 'Semester', 'Id', 'Title', @Sq, @Sq2, 'Order By SortOrder', 'FilteredSubject', 2)

UPDATE MetaSelectedField
sET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '1'
)

UPDATE MetaForeignKeyCriteriaClient
sET CustomSql = 'declare @selectedSemesterId int = (
	select SemesterId
	from Module 
	where Id = @entityId
);

with ActiveList as 
(
	select s.Id
	, CONCAT(CASE WHEN s.Title LIKE ''%Fall%'' THEN ''FA'' WHEN s.Title LIKE ''%Spring%'' THEN ''SP'' END, '' '', SUBSTRING(s.Title, 3, 2)) AS Title
	, s.Active
	, s.SortOrder
	, case
		
		when AcademicYearStart >= year(current_timestamp) - 6 and AcademicYearStart < year(current_timestamp) + 1  then 1
		-- show the rest
		--when AcademicYearStart < year(current_timestamp) - 2 then 2
		else null
		end as CategorySortOrder
	, s.AcademicYearStart
	, s.AcademicYearEnd
	from Semester s
	where s.Active = 1
	and s.Title not like ''%Summer%''
)
, Source as (
	select *
	from ActiveList
	where CategorySortOrder is not null

	union


	select s.Id
	, CONCAT(CASE WHEN s.Title LIKE ''%Fall%'' THEN ''FA'' WHEN s.Title LIKE ''%Spring%'' THEN ''SP'' END, '' '', SUBSTRING(s.Title, 3, 2), '' (Inactive)'') AS Title
	, s.Active
	, s.SortOrder
	,  case
		-- 3 years ago and 7 years ago from now
		when AcademicYearStart >= year(current_timestamp) - 6 and AcademicYearStart < year(current_timestamp) - 1 then 1
		-- show the rest
		--when AcademicYearStart < year(current_timestamp) - 2 then 2
		else null
		end as CategorySortOrder
	, s.AcademicYearStart
	, s.AcademicYearEnd
	from Semester s
	where s.Id = @selectedSemesterId
	and s.Active = 0
	and s.Title not like ''%Summer%''
	and not exists (
		select 1
		from ActiveList al
		where s.Id = al.Id
	)
)

	select s.Id as [Value]
	, s.Title as [Text]
	, s.SortOrder
	, s.CategorySortOrder
	--, s.AcademicYearStart
	--, s.AcademicYearEnd
	from Source s
	union
	SELECT 1, ''NONE'', 1, 1
	order by CategorySortOrder, s.SortOrder'
	, ResolutionSql = 'select 
    s.Id as [Value]
    , CASE WHEN s.Id = 1 THEN ''NONE'' ELSE s.Title END as [Text]
from [Semester] s
where s.Id = @Id'
WHERE Id = 158

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX2
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '3'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields
UNION
SELECT mss.MEtaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE Msf.MetaForeignKeyLookupSourceId in (158))

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback