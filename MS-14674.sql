USE [sac];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14674';
DECLARE @Comments nvarchar(Max) = 
	'Convert some fomula fields to query text to be more consitent across versions';
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
    --AND mtt.IsPresentationView = 0		--comment out if doing reports and forms					doing reports too
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
('Units and Hours', 'CourseDescription', 'MinContactHoursOther','min'),
('Units and Hours', 'CourseDescription', 'MaxContactHoursOther','max'),
('Catalog Entry', 'CourseYesNo', 'YesNo01Id', 'ping')

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
DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)

SET QUOTED_IDENTIFIER OFF

DECLARE @ASQL NVARCHAR(MAX) = "
SELECT 0 AS Value, SUM(cd.OutClassHour + cd.MinimumOutsideLab) AS Text
FROM CourseDescription AS cd where cd.CourseId = @EntityID
"

DECLARE @BSQL NVARCHAR(MAX) = "
SELECT 0 AS Value, SUM(cd.MaximumLHEHours + cd.MaximumOutsideLab) AS Text
FROM CourseDescription AS cd where cd.CourseId = @EntityID
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', @ASQL, @ASQL, 'Order By SortOrder', 'min total student learning hours', 2),
(@MAX2, 'Course', 'Id', 'Title', @BSQL, @BSQL, 'Order By SortOrder', 'max total student learning hours', 2)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, FieldTypeId = 5
, MetaForeignKeyLookupSourceId = @MAX
, DefaultDisplayType = 'QueryText'
, MetaAvailableFieldId = 8898
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'min'
)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, FieldTypeId = 5
, MetaForeignKeyLookupSourceId = @MAX2
, DefaultDisplayType = 'QueryText'
, MetaAvailableFieldId = 8899
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'max'
)

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @MIN NVARCHAR(MAX) = (SELECT SUM(cd.OutClassHour + cd.MinimumOutsideLab) 
FROM CourseDescription AS cd where cd.CourseId = @EntityID)

DECLARE @MAX NVARCHAR(MAX) = (SELECT SUM(cd.MaximumLHEHours + cd.MaximumOutsideLab)
FROM CourseDescription AS cd where cd.CourseId = @EntityID)

select 0 as [Value]
		   ,case
				when ccb.CB04Id = 3 then concat(
					''<b>Total hours of instructions required to achieve course objectives: </b>''
					,case
						when cd.IsIndividual = 1 then concat(coalesce(cd.TeachingUnitsLecture, 0), '' - '', coalesce(cd.TeachingUnitsWork,0))
						else concat(coalesce(cd.TeachingUnitsLecture, 0), '''')
					end,''<br />''
					,case
						when cd.IsAudit = 1 and cd.IsIndividual = 1 then concat(''<b>Credits: </b>'', cd.MinimumArrangeHours, '' - '', cd.MaximumArrangeHours)
						else concat(''<b>Min Credit: </b>'', coalesce(cd.MinimumArrangeHours, 0))
					end,''<br />''
				)
			else
			   concat(
					''<b>Units: </b>''
					,case
						when cd.Variable = 1 then concat(cd.MinCreditHour, '' - '', cd.MaxCreditHour)
						else concat(cd.MinCreditHour, '''')
					end
					,''<br />''
					,''<b>Lecture Hours: </b>''
					, case
						when cd.Variable = 1 then concat(cd.MinLectureHour, '' - '', cd.MaxLectureHour)
						else concat(cd.MinLectureHour, '''')
					end
					,''<br />''
					,''<b>Scheduled Laboratory Hours: </b>''
					,case
						when cd.Variable = 1 then concat(cd.MinLabHour, '' - '', cd.MaxLabHour)
						else concat(cd.MinLabHour, '''')
					end
					,''<br />''
					,''<b>TBA: </b>''
					,case
						when cd.Variable = 1 and cd.IsTBALab = 1 then concat(cd.MinOtherHour, '' - '', cd.MaxOtherHour)
						when cd.Variable = 0 and cd.IsTBALab = 1 then concat(cd.MinOtherHour, '''')
						when cd.Variable = 0 and cd.IsTBALab = 0 then ''''
					end
					,''<br />''
					,''<b>Total Contact Hours: </b>''
					,case
						when cd.Variable = 1 then concat(cd.MinimumOutsideLab, '' - '', cd.MaximumOutsideLab)
						else concat(cd.MinimumOutsideLab, '''')
					end
					,''<br />''
					,''<b>Additional Outside-of-Class Hours: </b>''
					,case
						when cd.Variable = 1 then concat(cd.InClassHour, '''')
						else concat(cd.InClassHour, '''')
					end
					,''<br />''
					,''<b>Total Outside Class Hours: </b>''
					,case
						when cd.Variable = 1 then concat(cd.OutClassHour, '' - '', cd.MaximumLHEHours)
						else concat(cd.OutClassHour, '''')
					end
					,''<br />''
					,''<b>Total Student Learning Hours: </b>''
					,case
						when cd.Variable = 1 then concat(@MIN, '' - '', @MAX)
						else concat(@MIN, '''')
					end
					,''<br />''
				)
			end as [Text]
		from CourseDescription cd
			left join CourseCBCode ccb on ccb.CourseId = cd.CourseId
		where cd.CourseId = @entityId;
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 105
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

exec EntityExpand 

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback