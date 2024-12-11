USE [laspositas];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17907';
DECLARE @Comments nvarchar(Max) = 
	'Update COR and Admin COR Report';
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
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
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
('Methods of Evaluation', 'GenericMaxText', 'TextMax12','1')

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
UPDATE EvaluationMethod
SET EndDate = GETDATE()
WHERE Id = 25

DECLARE @Ids INTEGERS

UPDATE gmt
SET TextMax20 = cem.LargeText01
output inserted.CourseId INTO @Ids
FROM GenericMaxText AS gmt
INNER JOIN CourseEvaluationMethod AS cem on gmt.CourseId = cem.CourseId
WHERE cem.EvaluationMethodId = 25
and cem.LargeText01 IS NOT NULL
and gmt.TextMax20 IS NULL

DELETE FROM CourseEvaluationMethod WHERE EvaluationMethodId = 25 and LargeText01 IS NOT NULL and CourseId in (
	SELECT Id FROM @Ids
)

UPDATE GenericBit
SET Bit11 = 1
WHERE CourseId in (
	SELECT CourseId FROM GenericMaxText WHERE TextMax20 IS NOT NULL
)

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @combinedString NVARCHAR(MAX) = '''';

WITH EvaluationMethods AS (
    SELECT
        CONCAT(''<li>'', em.Title, ''</li>'', CASE WHEN cem.LargeText01 IS NOT NULL THEN CONCAT(N''<div style="margin-left: 20px;">1. '', cem.LargeText01, N''</div>'')  ELSE '''' END) AS Text
    FROM CourseEvaluationMethod cem 
    INNER JOIN EvaluationMethod em ON cem.EvaluationMethodId = em.Id
    WHERE cem.CourseId = @EntityId
)
SELECT @combinedString = @combinedString + Text
FROM EvaluationMethods;

SET @combinedString =+ @combinedString + (SELECT CASE WHEN gb.Bit11 = 1 and gmt.TextMax20 IS NOT NULL THEN CONCAT(''<li>'', gmt.TextMax20, ''</li>'') ELSE '''' END FROM Course as c LEFT JOIN GenericBit AS gb on gb.CourseId = c.Id LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id WHERE c.Id = @EntityId)

SELECT 0 AS Value, CASE WHEN @combinedString <> '''' THEN ''<ol type="A">'' + @combinedString + ''</ol>'' ELSE '''' END AS Text;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 90

DECLARE @SQL2 NVARCHAR(MAX) = '
declare @outputText nvarchar(max);

select @outputText = dbo.ConcatOrdered_Agg(rt.rowOrder, rt.RenderedText, 0)
from (
	select concat(
			dbo.fnHtmlOpenTag(''li'', dbo.fnHtmlAttribute(''style'', ''list-style-type: upper-alpha;''))
					, ast.Title
				, '':''
				, ca.AssignmentText
			, dbo.fnHtmlCloseTag(''li'')
		) as RenderedText
		, row_number() over (order by ca.SortOrder, ca.Id) as rowOrder
	from CourseAssignment ca
		left join AssignmentType ast on coalesce(ca.AssignmentTypeId,3) = ast.Id
	where ca.CourseId = @entityId
) rt;

select 0 as [Value]
	, concat(
		''<ol>''
			, @outputText
		, ''</ol>''
	) as [Text]
;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 88

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields
UNION
SELECT mss.MetaTemplateID FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (88, 90))

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback