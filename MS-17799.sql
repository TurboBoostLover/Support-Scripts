USE [hkapa];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17799';
DECLARE @Comments nvarchar(Max) = 
	'Update Assessent outcomes tab';
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
('Assessment Outcomes, Criteria and Methods', 'CourseEvaluationMethod', 'AssignmentTypeId','1'),
('Assessment Outcomes, Criteria and Methods', 'CourseEvaluationMethod', 'LargeText02','2'),
('Assessment Outcomes, Criteria and Methods', 'CourseEvaluationMethod', 'Int01','3'),
('Assessment Outcomes, Criteria and Methods', 'CourseEvaluationMethod', 'Related_ModuleId','4'),
('Assessment Methods and Weighting', 'CourseEvaluationMethodCourseOutcome', 'CourseOutcomeId','5')

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
SELECT 0 AS Value,
CASE 
	WHEN ISNULL(cem.AssignmentTypeId, 0) = 7
	THEN LargeText02
	ELSE at.Title
END AS Text
FROM CourseEvaluationMethod AS cem
INNER JOIN AssignmentType AS at on cem.AssignmentTypeId = at.Id
WHERE cem.Id = @pkIdValue
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseEvaluationMethod', 'Id', 'Title', @CSQL, @CSQL, 'Order By SortOrder', 'Title field for Assessment Methods', 3)

DECLARE @SQL NVARCHAR(MAX) = '
declare @count int = (select count(id)
from [CourseOutcome] 
where CourseId = @EntityId)

declare @CLIOs NVARCHAR(MAX) =(
select dbo.ConcatWithSepOrdered_Agg(Char(13),num,Concat(''<td style="text-align: left;">'',coalesce(OutcomeText,OtherText),''</td>''))
from (select*,ROW_NUMBER() OVER (order by sortorder) as num from [CourseOutcome] ) CO
where CourseId = @EntityId
)

declare @CLIOstable table (Text NVARCHAR(MAX),CEMid int) 
insert into @CLIOstable
select dbo.ConcatWithSepOrdered_Agg(Char(13),num,concat(''<td>'',case when CourseOutcomeId is null then ''&#x2610;'' else ''&#x2611;'' end,''</td>'')),CEMID
from (
select  CO.id,Co.OutcomeText,CO.sortorder,Cem.id as CEMID,Cem.sortorder as CEMsortorder,CEMCO.CourseOutcomeId,ROW_NUMBER() OVER (order by Cem.sortorder,CO.sortorder) as num
from [CourseOutcome] CO
	left join (
		select *
		from CourseEvaluationMethod
		where courseid = @EntityId
	) CEM on 1 = 1
	outer apply (
		select CourseOutcomeId
		from CourseEvaluationMethodCourseOutcome CEMCO1
		where CEMCO1.CourseEvaluationMethodId = CEM.id
			and CourseOutcomeId = Co.id
			and id not in(
			SELECT 
    Id
FROM 
    CourseEvaluationMethodCourseOutcome
WHERE 
    CourseEvaluationMethodId IN (
        SELECT 
            CourseEvaluationMethodId
        FROM 
            CourseEvaluationMethodCourseOutcome
        GROUP BY 
            CourseEvaluationMethodId, CourseOutcomeId
        HAVING 
            COUNT(*) > 1
    )
    AND CourseOutcomeId IN (
        SELECT 
            CourseOutcomeId
        FROM 
            CourseEvaluationMethodCourseOutcome
        GROUP BY 
            CourseEvaluationMethodId, CourseOutcomeId
        HAVING 
            COUNT(*) > 1
    )
			)
	) CEMCO 
where CO.CourseId = @EntityId
) A
group by CEMID

declare @AM table (Text NVARCHAR(MAX),sortorder int) 
insert into @AM
select 
	Concat(''<tr>
	<td>'',coalesce(AT1.title,''&nbsp;''),''</td>
	<td style="padding-left: 5px; padding-right: 5px;">'',coalesce(CEM.Int01,0),''%</td>
	<td style="padding-left: 5px; padding-right: 5px;">'',coalesce(m.Title + '' ('' + sa.Title +'')'',''&nbsp;''),''</td>''
	,Char(13),CLIOT.text
	,Char(13),''</tr>''
	) as text
	,ROW_NUMBER() OVER (order by CEM.sortorder) as sortorder
from CourseEvaluationMethod CEM
	left join AssignmentType AT1 on AT1.id = CEM.AssignmentTypeId
	left join Module M on M.id = CEM.Related_ModuleId
	left join StatusAlias sa on sa.Id = m.StatusAliasId
	left join @CLIOstable CLIOT on CLIOT.cemid = CEM.id	
where courseid = @EntityId


select 0 as Value,
concat(''<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
  text-align: center;
}
</style><table>
  <tr>
    <th colspan="1" rowspan="2" style="padding-left: 5px; padding-right: 5px;">Assessment Task</th>
	<th colspan="1" rowspan="2" style="padding-left: 5px; padding-right: 5px;">Percentage</th>
    <th colspan="1" rowspan="2" style="padding-left: 5px; padding-right: 5px;">Rubric</th>
    <th colspan="'',@count,''" rowspan="1">Course Intended Learning Outcomes (CILOs)<br><span style="font-weight: normal; padding-left: 5px; padding-right: 5px;">If the assessment method contributes to a CILO, please tick the checkbox in the respective cell.</span></th>
  </tr>
  <tr>
    '',@CLIOs,''
  </tr>  
  '',dbo.ConcatWithSepOrdered_Agg(Char(13),A.sortorder,A.text),''
</table>'')as Text
from @AM A
'

DECLARE @SQL2 NVARCHAR(MAX) = '
declare @count int = (select count(id)
from [CourseOutcome] 
where CourseId = @EntityId)

declare @CLIOs NVARCHAR(MAX) =(
select dbo.ConcatWithSepOrdered_Agg(Char(13),num,Concat(''<td style="text-align: left;">'',coalesce(OutcomeText,OtherText),''</td>''))
from (select*,ROW_NUMBER() OVER (order by sortorder) as num from [CourseOutcome] ) CO
where CourseId = @EntityId
)

declare @CLIOstable table (Text NVARCHAR(MAX),CEMid int) 
insert into @CLIOstable
select dbo.ConcatWithSepOrdered_Agg(Char(13),num,concat(''<td>'',case when CourseOutcomeId is null then ''&#x2610;'' else ''&#x2611;'' end,''</td>'')),CEMID
from (
select  CO.id,Co.OutcomeText,CO.sortorder,Cem.id as CEMID,Cem.sortorder as CEMsortorder,CEMCO.CourseOutcomeId,ROW_NUMBER() OVER (order by Cem.sortorder,CO.sortorder) as num
from [CourseOutcome] CO
	left join (
		select *
		from CourseEvaluationMethod
		where courseid = @EntityId
	) CEM on 1 = 1
	outer apply (
		select CourseOutcomeId
		from CourseEvaluationMethodCourseOutcome CEMCO1
		where CEMCO1.CourseEvaluationMethodId = CEM.id
			and CourseOutcomeId = Co.id
			and id not in(
			SELECT 
    Id
FROM 
    CourseEvaluationMethodCourseOutcome
WHERE 
    CourseEvaluationMethodId IN (
        SELECT 
            CourseEvaluationMethodId
        FROM 
            CourseEvaluationMethodCourseOutcome
        GROUP BY 
            CourseEvaluationMethodId, CourseOutcomeId
        HAVING 
            COUNT(*) > 1
    )
    AND CourseOutcomeId IN (
        SELECT 
            CourseOutcomeId
        FROM 
            CourseEvaluationMethodCourseOutcome
        GROUP BY 
            CourseEvaluationMethodId, CourseOutcomeId
        HAVING 
            COUNT(*) > 1
    )
			)
	) CEMCO 
where CO.CourseId = @EntityId
) A
group by CEMID

declare @AM table (Text NVARCHAR(MAX),sortorder int) 
insert into @AM
select 
	Concat(''<tr>
	<td style="padding-left: 5px; padding-right: 5px;">'',coalesce(AT1.title,''&nbsp;''),''</td>
	<td style="padding-left: 5px; padding-right: 5px;">'',coalesce(CEM.Int01,0),''%</td>
	<td style="padding-left: 5px; padding-right: 5px;">'',coalesce(m.Title + '' ('' + sa.Title +'')'',''&nbsp;''),''</td>''
	,Char(13),CLIOT.text
	,Char(13),''<td style="padding-left: 5px; padding-right: 5px;">'',coalesce(dbo.stripHtml(CEM.Rationale),''''),''</td>''
	,Char(13),''<td style="padding-left: 5px; padding-right: 5px;">'',coalesce(dbo.stripHtml(CEM.EvaluationText),''''),''</td>''
	,Char(13),''</tr>''
	) as text
	,ROW_NUMBER() OVER (order by CEM.sortorder) as sortorder
from CourseEvaluationMethod CEM
	left join AssignmentType AT1 on AT1.id = CEM.AssignmentTypeId
	left join Module M on M.id = CEM.Related_ModuleId
	left join StatusAlias sa on sa.Id = m.StatusAliasId
	left join @CLIOstable CLIOT on CLIOT.cemid = CEM.id	
where courseid = @EntityId


select 0 as Value,
concat(''<style>
table, th, td {
  border: 1px solid black;
  border-collapse: collapse;
  text-align: center;
}
</style><table>
  <tr>
    <th colspan="1" rowspan="2" style="padding-left: 5px; padding-right: 5px;">Assessment Task</th>
	<th colspan="1" rowspan="2" style="padding-left: 5px; padding-right: 5px;">Percentage</th>
    <th colspan="1" rowspan="2" style="padding-left: 5px; padding-right: 5px;">Rubric</th>
    <th colspan="'',@count,''" rowspan="1">Course Intended Learning Outcomes (CILOs)<br><span style="font-weight: normal; padding-left: 5px; padding-right: 5px;">If the assessment method contributes to a CILO, please tick the checkbox in the respective cell.</span></th>
	<th colspan="1" rowspan="2" style="padding-left: 5px; padding-right: 5px;">Category of Assessment</th>
	<th colspan="1" rowspan="2" style="padding-left: 5px; padding-right: 5px;">Assessment Details</th>
  </tr>
  <tr>
    '',@CLIOs,''
  </tr>  
  '',dbo.ConcatWithSepOrdered_Agg(Char(13),A.sortorder,A.text),''
</table>'')as Text
from @AM A
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 36

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 64

UPDATE MetaSelectedField
SET IsRequired = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldID FROM @Fields WHERE Action in ('1', '2', '3', '4')
)

INSERT INTO MetaSelectedSectionSetting
(MetaSelectedSectionId, IsRequired, MinElem)
SELECT SectionId, 1, 1 FROM @Fields WHERE Action = '5'

UPDATE MetaSelectedSection
SET SortOrder = SortOrder + 1
, RowPosition = RowPosition + 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '5'
)

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('DECLARE @CILO bit = (
    SELECT CASE 
        WHEN EXISTS(SELECT 1 FROM CourseOutcome WHERE CourseId = @EntityId) 
        THEN 1 
        ELSE 0 
    END
)

DECLARE @Count int = (SELECT Count(Id) FROM CourseEvaluationMethod WHERE CourseId = @EntityId and ISNULL(AssignmentTypeId,0) <> 7)
DECLARE @Other int = (SELECT Count(Id) FROM CourseEvaluationMethod WHERE CourseId = @EntityId and AssignmentTypeId = 7)
DECLARE @ValidCount int = (SELECT Count(Id) FROM CourseEvaluationMethod WHERE CourseId = @EntityId and AssignmentTypeId <> 7 and AssignmentTypeId IS NOT NULL and Int01 IS NOT NULL and Related_ModuleId IS NOT NULL)
DECLARE @ValidOther int = (SELECT Count(Id) FROM CourseEvaluationMethod WHERE CourseId = @EntityId and AssignmentTypeId = 7  and Int01 IS NOT NULL and Related_ModuleId IS NOT NULL and LargeText02 IS NOT NULL)

DECLARE @Maps int = (SELECT Count(Id) FROM CourseEvaluationMethod WHERE Id in (SELECT CourseEvaluationMethodId FROM CourseEvaluationMethodCourseOutcome) and CourseId = @EntityId)

SELECT CASE
	WHEN @CILO <> 1 and @Count = @ValidCount and @Other = @ValidOther
	THEN 1
	WHEN @CILO = 1 and @Count = @ValidCount and @ValidOther = @Other and @Maps = (SUM(@Count + @Other))
	THEN 1
	ELSE 0
END AS IsValid', 1)

DECLARE @Id int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT TabId, 'Assessment form', 'All required fields need data', 6, 'All required fields need filled out.', @Id FROM @Fields WHERE Action = '2'

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN @Fields AS f on msf.MetaSelectedSectionId = f.SectionId WHERE f.Action = '2'
)

DECLARE @Fields2 TABLE (Fieldid int)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId INTO @Fields2
SELECT
'Title Field', -- [DisplayName]
14504, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
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
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
 FROM @Fields WHERE Action = '2'

insert into MetaSelectedFieldAttribute
(Name,Value,MetaSelectedFieldId)
SELECT 'UpdateSubscriptionTable1','CourseEvaluationMethod',FieldId FROM @Fields2
UNION
SELECT 'UpdateSubscriptionColumn1','AssignmentTypeId', FieldId FROM @Fields2
UNION
SELECT 'UpdateSubscriptionTable2','CourseEvaluationMethod',FieldId FROM @Fields2
UNION
SELECT 'UpdateSubscriptionColumn2','LargeText02', FieldId FROM @Fields2

UPDATE ListItemType
SET ListItemTitleColumn = 'MaxText01'
WHERE Id = 15

UPDATE cem
SET MaxText01 = CASE 
    WHEN ISNULL(cem.AssignmentTypeId, 0) = 7 THEN cem.LargeText02
    ELSE at.Title
END
FROM CourseEvaluationMethod AS cem
LEFT JOIN AssignmentType AS at ON cem.AssignmentTypeId = at.Id;
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select Distinct templateId FROM @Fields
UNION
SELECT mss.MetaTemplateID FROM MetaSelectedSection As mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (36, 64))

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback