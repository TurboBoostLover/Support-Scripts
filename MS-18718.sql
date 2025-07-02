USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18718';
DECLARE @Comments nvarchar(Max) = 
	'Update Non-credit programs';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (19)		--comment back in if just doing some of the mtt's

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
('Program Requirements', 'CourseOption', 'CourseOptionNote','1'),
('Program Requirements', 'ProgramCourse', 'CourseId', '2')
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE ProgramCourse
SET ListItemTypeId = 11
WHERE CourseId IS NOT NULL
and ListItemTypeId IS NULL

UPDATE ProgramCourse
SET ListItemTypeId = 12
WHERE ProgramCourseRule IS NOT NULL
and ListItemTypeId IS NULL

UPDATE ProgramCourse
SET ListItemTypeId = 13
WHERE MaxText01 IS NOT NULL
and ListItemTypeId IS NULL

UPDATE CourseOption
SET ListItemTypeId = 14
WHERE ListItemTypeId IS NULL

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'CalcMinLabel', 'Min Hours:', SectionId FROM @Fields WHERE Action = 1
UNION
SELECT 'CalcMaxLabel', 'Max Hours:', SectionId FROM @Fields WHERE Action = 1
UNION
SELECT 'CalcMinLabel', 'Min Hours:', SectionId FROM @Fields WHERE Action = 2
UNION
SELECT 'CalcMaxLabel', 'Max Hours:', SectionId FROM @Fields WHERE Action = 2

DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 1;

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
select 
      c.Id as Value    
    , EntityTitle + ' - ' + sa.Title  as Text         
    , s.Id as FilterValue
	, SUM(COALESCE(cd.MinClinicalHour, 0) + COALESCE(cd.MinLabLecHour, 0) + COALESCE(cd.MinLectureHour,0)) as [Min]
	, SUM(COALESCE(cd.MaxClinicalHour, 0) + COALESCE(cd.MaxLabLecHour, 0) + COALESCE(cd.MaxLectureHour, 0)) as [Max]
	, 1 as [IsVariable]
from Course c
	inner join CourseDescription cd on c.Id = cd.CourseId
    inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join [Subject] s on s.id = c.SubjectId
where c.ClientId = @clientId
and (
	(
		sa.StatusBaseId in (1, 2, 4, 6)
		and c.Active = 1
	)
	or exists
	(
		select 1
		from ProgramSequence pc
		where pc.CourseId = c.Id
		and pc.ProgramId = @entityId
	)
)
group by c.Id, c.EntityTitle, sa.Title, s.Id
Order by c.EntityTitle
"

DECLARE @RSQL NVARCHAR(MAX) = "
select 
      c.Id as Value    
    , EntityTitle + ' - ' + sa.Title  as Text         
    , s.Id as FilterValue
	, SUM(COALESCE(cd.MinClinicalHour, 0) + COALESCE(cd.MinLabLecHour, 0) + COALESCE(cd.MinLectureHour,0)) as [Min]
	, SUM(COALESCE(cd.MaxClinicalHour, 0) + COALESCE(cd.MaxLabLecHour, 0) + COALESCE(cd.MaxLectureHour, 0)) as [Max]
	, 1 as [IsVariable]
from Course c
	inner join CourseDescription cd on c.Id = cd.CourseId
	inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join [Subject] s on s.id = c.SubjectId
where c.id = @Id
group by c.Id, c.EntityTitle, sa.Title, s.Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Program Course tab course dropdown', 3)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '2'
)

DECLARE @programId INT;
 
DROP Table IF Exists #calculationResults

create table #calculationResults
(
    TableName sysname,
    Id int,
    Min decimal(16, 3),
    Max decimal(16, 3),
    IsVariable bit
);

declare programCursor cursor fast_forward for
    select p.Id
from Program p
 INNER JOIN @templateId AS t on p.MetaTemplateId = t.Id

open programCursor;
fetch next from programCursor
    into @programId;
while @@fetch_status = 0
    begin;
    exec upCalculateNestedCourseBlockEntries @entityId = @programId, @resultTable = '#calculationResults';
    fetch next from programCursor
        into @programId;
end;
close programCursor;
deallocate programCursor;

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @NonCredit bit = (SELECT CASE WHEN EXISTS ( SELECT 1 FROM PRogram AS p INNER JOIN ProposalType AS pt on pt.Id = p.ProposalTypeId
WHERE p.Id = @EntityId and pt.Title like ''%Non%'') THEN 1 ELSE 0 END 
)

select 0 as Value, ''<div style="float:right;"><strong>Total '' + CASE WHEN @NonCredit =0 THEN ''Units:'' ELSE ''Hours:'' end+ '' </strong>'' + case
                    when sum(CalcMin) is not null and sum(CalcMax) is not null
                        and sum(CalcMin) <> sum(CalcMax)
                        then format(sum(CalcMin), ''F1'')
                        + ''-'' + format(sum(CalcMax), ''F1'')
                    when sum(CalcMin) is not null
                        then format(sum(CalcMin), ''F1'')
                    when sum(CalcMax) is not null
                        then format(sum(CalcMax), ''F1'')
                    else ''0''
                end + ''</div>'' as Text
from CourseOption
where ProgramId = @entityId
AND (
    (Calculate = 0 AND DoNotCalculate = 0)
    OR
    (Calculate = 1 AND DoNotCalculate = 0)
    OR
    (Calculate = 1 AND DoNotCalculate = 1)
)
group by ProgramId
'
, ResolutionSql = '
DECLARE @NonCredit bit = (SELECT CASE WHEN EXISTS ( SELECT 1 FROM PRogram AS p INNER JOIN ProposalType AS pt on pt.Id = p.ProposalTypeId
WHERE p.Id = @EntityId and pt.Title like ''%Non%'') THEN 1 ELSE 0 END 
)

select 0 as Value, ''<div style="float:right;"><strong>Total '' + CASE WHEN @NonCredit =0 THEN ''Units:'' ELSE ''Hours:'' end+ '' </strong>'' + case
                    when sum(CalcMin) is not null and sum(CalcMax) is not null
                        and sum(CalcMin) <> sum(CalcMax)
                        then format(sum(CalcMin), ''F1'')
                        + ''-'' + format(sum(CalcMax), ''F1'')
                    when sum(CalcMin) is not null
                        then format(sum(CalcMin), ''F1'')
                    when sum(CalcMax) is not null
                        then format(sum(CalcMax), ''F1'')
                    else ''0''
                end + ''</div>'' as Text
from CourseOption
where ProgramId = @entityId
AND (
    (Calculate = 0 AND DoNotCalculate = 0)
    OR
    (Calculate = 1 AND DoNotCalculate = 0)
    OR
    (Calculate = 1 AND DoNotCalculate = 1)
)
group by ProgramId
'
WHERE Id = 75
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback