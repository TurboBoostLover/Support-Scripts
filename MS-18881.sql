USE [hkapa];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18881';
DECLARE @Comments nvarchar(Max) = 
	'Add condition to Major ol';
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
('Target Students', 'GenericOrderedList01', 'Lookup14Id','1'),
('School(s)', 'CourseSchoolMajor', 'Lookup14Id', '2')

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
DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 10;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		--Create more Variables here using Sort if needed

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
select c.Id as Value, c.Title as Text from Condition c order by c.Id
"

DECLARE @RSQL NVARCHAR(MAX) = "
Select Title as Text from Condition Where Id = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Condition', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Condition look up', 1)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Condition', -- [DisplayName]
6524, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
9, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = '1'
UNION
SELECT
'Condition', -- [DisplayName]
12799, -- [MetaAvailableFieldId]
2343, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = '2'

DECLARE @Id int = 252

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @text NVARCHAR(MAX) = 
''<br><div class="h4 section-name">Target Students:</div>
<table border ="2" style="margin: auto; width: 100%;">
<tr style="background:lightgray;">
	<th>Programme</th>
	<th>Curriculum</th>
	<th>Major(s)</th>
	<th>Specialisation(s)</th>
	<th>Course Type</th>
	<th>Course Code</th>
	<th>Semester, Year to be offered</th>
</tr>''

DECLARE @semesters NVARCHAR(MAX) = 
(SELECT dbo.ConcatWithSepOrdered_Agg(''<br>'',cs.SortOrder,CONCAT(s.Title, '' '', It.Title))
FROM CourseSemester cs
	inner JOIN Semester s ON s.Id = cs.SemesterId
	LEFT JOIN ItemType AS it on cs.ItemTypeId = it.Id
WHERE cs.CourseId = @entityId)

DECLARE @majors NVARCHAR(MAX) =
(SELECT dbo.ConcatWithSepOrdered_Agg('', '', gol.SortOrder, CONCAT(l14.Title, CASE WHEN c.Id IS NULL THEN '''' ELSE CONCAT('' '',c.Title) END)) 
FROM GenericOrderedList01 gol
	INNER JOIN lookup14 l14 ON gol.Lookup14Id = l14.Id 
	LEFT JOIN Condition AS c on gol.ConditionId = c.Id
WHERE gol.CourseId = @entityId)

DECLARE @Specialization NVARCHAR(MAX) = 
(SELECT dbo.ConcatWithSep_Agg('',<br>'',l14.Title) 
FROM GenericOrderedList01Lookup14 gol14
	INNER JOIN lookup14 l14 ON gol14.Lookup14Id = l14.Id
	INNER JOIN GenericOrderedList01 gol ON gol14.GenericOrderedList01Id = gol.Id
WHERE gol.CourseId = @entityId)

DECLARE @TABLE TABLE (CourseId int, ecId int)
INSERT INTO @TABLE
SELECT DISTINCT CourseId, EligibilityCriteriaId FROM CourseEligibility
WHERE CourseId = @EntityId

SET @text += (
SELECT dbo.ConcatWithSep_Agg('''',Concat(''<tr>'',''<td>'', ec.Title, ''</td><td>'', case when dt.Code = ''C'' then ''C'' else ''N/A'' end, ''</td><td>'', @majors, ''</td><td>'', @Specialization, ''</td><td>'',ct.Title, ''</td><td>'', c.CourseNumber, ''</td><td>'', @semesters, ''</td></tr>''))
FROM Course c
	INNER JOIN @TABLE t ON c.Id = t.CourseId
	INNER JOIN CourseProposal cp ON cp.CourseId = c.Id
	LEFT JOIN EligibilityCriteria ec ON t.ecID = ec.Id
	LEFT JOIN DisciplineType dt ON c.DisciplineTypeId = dt.Id
	Left JOIN CreditType ct ON cp.CreditTypeId = ct.Id
WHERE c.Id = @entityId)

DECLARE @aggregatedTable NVARCHAR(MAX);

-- Step 1: Pre-aggregate dependent fields
WITH SpecializationAggregated AS (
    -- Aggregate DISTINCT specializations per CourseSchoolId
    SELECT 
        csms.CourseSchoolMajorId, 
        dbo.ConcatWithSep_Agg(''<br>'', l142.Title) AS SpecializationTitles
    FROM CourseSchoolMajorSpecialization AS csms
    INNER JOIN lookup14 l142 ON csms.Lookup14Id = l142.Id
    GROUP BY csms.CourseSchoolMajorId
),
MajorAggregated AS (
    -- Aggregate DISTINCT majors per CourseSchoolId
    SELECT 
        csm.CourseSchoolId, 
        dbo.ConcatWithSepOrdered_Agg('',<br>'', csm.SortOrder, CONCAT(l14.Title, '' '',c.Title)) AS MajorTitles
    FROM CourseSchoolMajor AS csm
    INNER JOIN lookup14 l14 ON csm.Lookup14Id = l14.Id 
		LEFT JOIN Condition AS c on csm.YesNoId_01 = c.Id
    GROUP BY csm.CourseSchoolId
),
AggregatedData AS (
    SELECT 
        cs.Id AS CourseSchoolId,  
        c.Id AS CourseId,
        ec.Title AS EligibilityTitle,
        CASE WHEN dt.Code = ''C'' THEN ''C'' ELSE ''N/A'' END AS DisciplineCode,
        -- Join the pre-aggregated majors
        (SELECT MajorTitles FROM MajorAggregated ma WHERE ma.CourseSchoolId = cs.Id) AS MajorTitles,
        ct.Title AS CreditType,
        c.CourseNumber,
        dbo.ConcatWithSep_Agg(''<br>'', CONCAT(s.Title, '' '', item.Title)) AS SemesterTitles,
        -- Join the pre-aggregated specializations
        (SELECT dbo.ConcatWithSep_Agg(''<br>'', SpecializationTitles)
         FROM SpecializationAggregated sa
         WHERE sa.CourseSchoolMajorId IN 
               (SELECT csm.Id FROM CourseSchoolMajor AS csm WHERE csm.CourseSchoolId = cs.Id)
        ) AS SpecializationTitles
    FROM Course c
    INNER JOIN CourseProposal cp ON cp.CourseId = c.Id
    INNER JOIN CourseSchool AS cs ON cs.CourseId = c.Id  
    LEFT JOIN CourseSchoolEligibility AS cse ON cse.CourseSchoolId = cs.Id    
    LEFT JOIN CourseSchoolMajor AS csm ON csm.CourseSchoolId = cs.Id
    LEFT JOIN CourseSchoolMajorSemester AS csmt ON csmt.CourseSchoolMajorId = csm.Id
    LEFT JOIN Semester AS s ON csmt.SemesterId = s.Id
	LEFT JOIN ItemType AS item ON csmt.ItemTypeId = item.Id
    LEFT JOIN DisciplineType dt ON c.DisciplineTypeId = dt.Id
    LEFT JOIN CreditType ct ON cp.CreditTypeId = ct.Id
    LEFT JOIN EligibilityCriteria AS ec ON ec.Id = cse.EligibilityCriteriaId
    WHERE c.Id = @entityId
    GROUP BY cs.Id, c.Id, ec.Title, dt.Code, ct.Title, c.CourseNumber
)
-- Step 2: Format the output as HTML
SELECT @aggregatedTable = dbo.ConcatWithSep_Agg('''', 
    CONCAT(
        ''<tr>'',
        ''<td>'', EligibilityTitle, ''</td>'',
        ''<td>'', DisciplineCode, ''</td>'',
        ''<td>'', MajorTitles, ''</td>'',   -- Now correctly aggregated
        ''<td>'', SpecializationTitles, ''</td>'',  -- Now correctly aggregated
        ''<td>'', CreditType, ''</td>'',
        ''<td>'', CourseNumber, ''</td>'',
        ''<td>'', SemesterTitles, ''</td>'',
        ''</tr>''
    )
)
FROM AggregatedData;

-- Step 3: Append to @text
SET @text += @aggregatedTable;

SET @text += ''</table><br><br>''

SELECT @text AS Text, 0 AS Value
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback