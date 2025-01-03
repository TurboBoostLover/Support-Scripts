USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17524';
DECLARE @Comments nvarchar(Max) = 
	'Update these tabs on the Non-Instructional Program Review to match the Instructional
	Urgent Budget Augmentation Requests
Funding For Repair/Replacement Requests
Funding Request for Professional Develpment
	';
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
		AND mtt.MetaTemplateTypeId in (37)		--comment back in if just doing some of the mtt's

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
('Funding Request for Professional Develpment', 'ModuleYesNo', 'YesNo07Id','1'),
('Funding For Repair/Replacement Requests', 'ModuleYesNo', 'YesNo11Id', '2'),
('Urgent Budget Augmentation Requests', 'ModuleYesNo', 'YesNo06Id','tab'),
(NULL, 'GenericOrderedList02Lookup14', 'Rationale','sec'),
('Urgent Budget Augmentation Requests', 'ModuleYesNo', 'YesNo09Id', '3'),
('Funding For Repair/Replacement Requests', 'GenericOrderedList04', 'MaxText01', '4'),
('Funding For Repair/Replacement Requests', 'GenericOrderedList04', 'MaxText02', '5')

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
UPDATE MetaSelectedSection
SET SectionName = 'Funding Request for Professional Development'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '1'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId =229
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '2'
)

UPDATE MetaSelectedSection
SET SectionName = 'Budget Augmentation Requests'
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = 'tab'
)

UPDATE MetaSelectedSection
SET SectionName = 'NEED CRITERIA. Check all that apply.'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'sec'
)

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
select [Id] as [Value], (ShortText) as [Text] 
from [Lookup01] 
where Active = 1 
	and Lookup01ParentId = 14
and id not in (15, 16)
Order By SortOrder
"

DECLARE @RSQL NVARCHAR(MAX) = "
select (ShortText) as [Text]       
from [Lookup01]  
where Id = @Id
"

DECLARE @CSQL2 NVARCHAR(MAX) = "
select Id as Value, Title as Text from YesNo where Id not in (2, 3)
"

DECLARE @RSQL2 NVARCHAR(MAX) = "
Select Title as Text from YesNo Where id = @id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Lookup01', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Found a hack and we cant take it away currently', 1),
(@MAX2, 'YesNO', 'Id', 'Title', @CSQL2, @RSQL2, 'Order By SortOrder', 'Only Show yes', 1)

UPDATE MetaSelectedField
sET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (
	SELECT msf.MEtaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN @Fields AS f on msf.MetaSelectedSectionId = f.SectionId
	WHERE f.Action = 'sec'
	and msf.DisplayName like '%Item%'
)

UPDATE MetaSelectedField
sET MetaForeignKeyLookupSourceId = @MAX2
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '3'
)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 25
, DefaultDisplayType = 'CKEditor'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '4'
)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 1
, DefaultDisplayType = 'Textbox'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '5'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback