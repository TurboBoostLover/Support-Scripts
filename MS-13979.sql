USE [palomar];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13979';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Forms';
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
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId


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
('Codes', 'CourseCBCode', 'CB05Id','Update'),
('Main', 'CourseCBCode', 'CB05Id','Update'),
('Units/Hours', 'CourseDescription', 'GradeOptionId', 'Update2'),
('Codes', 'CourseProposal', 'IsMultiple', 'Move'),
('Codes', 'CourseProposal', 'IsDeanOverlap', 'Move2'),
('Repeatability', 'CourseProposal', 'RepeatabilityId', 'Target')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	TempType int,
	mfk int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder,TempType, mfk)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mtt.MetaTemplateTypeId, msf.MetaForeignKeyLookupSourceId
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaTemplateType mtt
	on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
DECLARE @MAX int = (SELECT Max(Id) FROM MetaForeignKeyCriteriaClient) + 1

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
Declare @EntityClientId int = (
	SELECT
		ClientId
	FROM Course
	WHERE Id = @EntityId
)
;
WITH ClientOverride
AS
(
	SELECT
		CB05Id
	   ,Code
	   ,Description
	   ,Active
	FROM CB05ClientOverride
	WHERE ClientId = @EntityClientId
)
SELECT
	cb.[Id] AS Value
   ,COALESCE(COALESCE(co.Code, cb.Code) + ' - ' + COALESCE(co.Description, cb.Description), co.Description, co.Code, cb.Description, cb.Code) AS Text
   ,cb.SortOrder
FROM [CB05] cb
	LEFT JOIN [ClientOverride] co ON co.CB05Id = cb.Id
WHERE COALESCE(co.Active, cb.Active) = 1
AND cb.Code <> 'A'
UNION
SELECT
	cb.Id AS Value
   ,CONCAT(cb.Code, ' - ', cb.Description) AS Text
   ,cb.SortOrder
FROM CourseCBCode ccb
	INNER JOIN CB05 cb ON cb.id = ccb.CB05Id
WHERE ccb.CourseId = @entityid
AND cb.Code <> 'A'
ORDER BY cb.SortOrder
"

DECLARE @SQL2 NVARCHAR(MAX) = "
select 
	cb.[Id] as Value 
	,Coalesce(cb.Code + ' - ' + cb.Description,cb.Description,cb.Code) as Text 
	from [CB05] cb
	where cb.Id = @Id
"

SET QUOTED_IDENTIFIER ON


INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseCBCode', 'CB05Id', 'Title', @SQL, @SQL2, 'Order By SortOrder', 'No A on New Courses', 2)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update' AND TempType in (1, 21)
	)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
select g.Id as Value,
		g.Description as Text
from GradeOption g
where g.Active = 1
and g.StartDate <= current_timestamp
and (g.EndDate is null or g.EndDate >= current_timestamp)
order by g.SortOrder
'
WHERE Id = (SELECT DISTINCT mfk FROM @Fields WHERE Action = 'Update2')

UPDATE MetaSelectedField
SET RowPosition = RowPosition - 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Move2'
)

UPDATE msf
SET MetaSelectedSectionId = f.SectionId
, RowPosition = 3
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Fields AS f ON mss.MetaTemplateId = f.TemplateId AND Action = 'Target'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Move'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback