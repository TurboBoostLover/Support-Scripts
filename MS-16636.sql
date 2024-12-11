USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16636';
DECLARE @Comments nvarchar(Max) = 
	'Update General Education Tab';
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
('General Education Proposal', 'CourseYesNo', 'YesNo08Id','Update1'),
('General Education Proposal', 'CourseYesNo', 'YesNo10Id','Update2')

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
INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('declare @validCount int = 1;
declare @totalCount int = 0;
declare @totalCount2 int = 0;

set @totalCount = (select count(id)
from CourseGE
where courseid = @entityid)

set @totalCount2 = (select count(id)
from CourseGeneralEducation
where courseid = @entityid)


select case
	when @totalCount >= @validCount
	then 1
	when @totalCount2 >= @validCount
	then 1
	else 0
end;', 1)

DECLARE @Id int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT DISTINCT TabId, 'Must have data', 6, 'Something must be selected if "Yes" is selected on top of tab."', @Id FROM @Fields WHERE Action = 'Update2'

UPDATE MetaSelectedSection
SET DisplaySectionName = 1
WHERE SectionName = 'Plan 2: California General Education Transfer Curriculum, Cal-GETC (AA/AS/ADT)'

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 12605
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update1'
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 12606
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)

exec EntityExpand 

INSERT INTO Lookup01
(ClientId, Title, SortOrder, StartDate)
VALUES
(1, 'GE item parent', 0, GETDATE())
DECLARE @ParentId int = SCOPE_IDENTITY()

INSERT INTO Lookup01
(Lookup01ParentId, ClientId, Title, SortOrder, StartDate)
VALUES
(@ParentId, 1, 'Addition', 0, GETDATE()),
(@ParentId, 1, 'Deletion', 1, GETDATE()),
(@ParentId, 1, 'Revision', 2, GETDATE()),
(@ParentId, 1, 'Exsisting', 3, GETDATE())

UPDATE cd
SET Lookup01Id_01 = cyn.YesNo08Id + 1
, Lookup01Id_02 = cyn.YesNo10Id + 1
FROM CourseDetail AS cd
INNER JOIN CourseYesNo AS cyn on cyn.CourseId = cd.CourseId

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
SELECT id AS Value,
Title AS Text FROM
Lookup01 WHERE Lookup01ParentId = (SELECT Id FROM Lookup01 WHERE Title = 'GE item parent')
"

DECLARE @RSQL NVARCHAR(MAX) = "
SELECT Title AS Text FROM Lookup01 WHERE Id = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Lookup01', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Lookup01 for Ge tab', 1)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in(
	SELECT FieldId FROM @Fields
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback