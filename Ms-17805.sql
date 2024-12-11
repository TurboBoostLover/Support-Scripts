USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17805';
DECLARE @Comments nvarchar(Max) = 
	'UPDATE CSD report';
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
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @txt NVARCHAR(MAX) = (
	SELECT dbo.ConcatWithSep_Agg('', '', CONCAT(c.CourseNumber, '' '', c.Title)) AS Text
	FROM CourseRequisite cr
		INNER JOIN Course c ON c.Id = cr.Requisite_CourseId 
	WHERE cr.CourseId = @entityId AND cr.RequisiteTypeId = 1
	);

DECLARE @txt2 NVARCHAR(MAX) = (
	SELECT dbo.ConcatWithSep_Agg('', '', CONCAT(c.CourseNumber, '' '', c.Title)) AS Text
	FROM CourseRequisite cr
		INNER JOIN Course c ON c.Id = cr.Requisite_CourseId 
	WHERE cr.CourseId = @entityId AND cr.RequisiteTypeId = 2
	);

DECLARE @replace INT = (
	SELECT bc.ActiveCourseId 
	FROM Course c
		INNER JOIN BaseCourse bc ON bc.Id = c.BaseCourseId
	WHERE c.Id = @entityId AND bc.ActiveCourseId != c.Id
	);

DECLARE @course NVARCHAR(MAX) = (
	SELECT CONCAT(CourseNumber, '' '', Title) AS Text
	FROM Course
	WHERE Id = @replace
	);

DECLARE @sem NVARCHAR(MAX) = (
	SELECT dbo.ConcatWithSepOrdered_Agg(
		'' '', 
		a.SortOrder, 
		a.Title + COALESCE('' '' + LOWER(a.Condition), '','')
		) AS Text 
	FROM (
		SELECT s.Title, it.Title AS Condition, ROW_NUMBER() OVER (ORDER BY cs.SortOrder) AS SortOrder
		FROM CourseSemester cs
			INNER JOIN Semester s on cs.SemesterId = s.Id
			LEFT JOIN ItemType it on cs.ItemTypeId = it.Id
		WHERE CourseId = @entityId
		) a
	);

DECLARE @text2 NVARCHAR(MAX) = 
''<table border="2" style="margin: auto; align: center; width: 100%;">
	<tr>
		<th style="text-align: center;">Approval / Endorsing Body</th>
		<th style="text-align: center;">Date</th>
	</tr>'';

SET @text2 += (
	SELECT dbo.ConcatWithSep_Agg(
	'' '', 
	CONCAT
		(
		''<tr><td>'', cdt.Title, ''</td><td>'', 
		FORMAT(cd.CourseDate, ''yyyy/MM/dd''), 
		''</td></tr>''
		))
	FROM CourseDate cd
		INNER JOIN CourseDateType cdt ON cd.CourseDateTypeId = cdt.Id
	WHERE CourseId = @entityId
	);

SET @text2 += ''</table>''

SELECT 0 AS Value,
CONCAT(
    ''
	<table border="2" class="course-report-table">
	<thead class="thead-invisible">
		<tr>
			<th class="th-half">&nbsp;</th>
			<th class="th-half">&nbsp;</th>
		</tr>
	</thead>
    <tr>
		<td class="td-label"><b>Duration:</b></td>
		<td>'', d.Title, ''</td>
	</tr>'',
    ''<tr>
		<td class="td-label"><b>Academy Credit:</b></td>
		<td>'', CASE WHEN cd.MaxFieldHour IS NULL OR cd.MaxFieldHour <= cd.MinFieldHour 
				    THEN CAST(cd.MinContHour AS NVARCHAR(MAX)) 
					ELSE CONCAT(cd.MinFieldHour, '' - '', cd.MaxFieldHour)
				END, 
		''</td>
	</tr>
    <tr>
		<td class="td-label"><b>Contact Hours (A):</b></td>
		<td>'', CASE WHEN cd.MaxLectureHour IS NULL OR cd.MaxLectureHour <= cd.MinLectureHour 
					THEN CAST(cd.MinLectureHour AS NVARCHAR(MAX)) 
					ELSE CONCAT(cd.MinLectureHour, '' - '', cd.MaxLectureHour) 
				END, 
		''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Student Work Hours (B):</b></td>
		<td>'', CASE WHEN cd.MaxContHour IS NULL OR cd.MaxContHour <= cd.MinContHour 
					THEN CAST(cd.MinContHour AS NVARCHAR(MAX)) 
					ELSE CONCAT(cd.MinContHour, '' - '', cd.MaxContHour) 
				END, 
		''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Notional Learning Hours = (A) + (B):</b></td>
		<td>'', CASE WHEN cd.MaxLabHour IS NULL OR cd.MaxLabHour < cd.MinLabHour 
					THEN CAST(cd.MinLabHour AS NVARCHAR(MAX)) 
					ELSE CONCAT(cd.MinLabHour, '' - '', cd.MaxLabHour)	
				END, 
		''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Ratio of Contact Hours to Student Work Hours (A:B):</b></td>
		<td>'', CASE WHEN cd.MaxFieldHour IS NULL OR cd.MaxFieldHour <= cd.MinFieldHour 
					THEN CAST(cd.MinFieldHour AS NVARCHAR(MAX)) 
					ELSE CONCAT(cd.MinFieldHour, '' - '', cd.MaxFieldHour) 
				END, 
		''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Credit Allocation Type:</b></td>
		<td>'', rt.Title, ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Course code(s) and title(s) of prerequisite(s):</b></td>
		<td>'', @txt, ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Course code(s) and title(s) of co-requisite(s):</b></td>
		<td>'', @txt2, ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>QF Level:</b></td>
		<td>'', qf.Code, ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>QF Credits:</b></td>
		<td>'', CASE WHEN cd.ClockHours IS NULL OR cd.ClockHours <= cd.CreditTotalHour 
					THEN CAST(cd.CreditTotalHour AS NVARCHAR(MAX)) 
					ELSE CONCAT(cd.CreditTotalHour, '' - '', cd.ClockHours) 
				END, 
		''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Grading System:</b></td>
		<td>'', gro.Description, ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Medium of Instruction:</b></td>
		<td>'', CASE WHEN cp.AdminChange IS NOT NULL and ps.Title IS NOT NULL THEN CONCAT(ps.Title,'' - '', cp.AdminChange)  WHEN cp.AdminChange IS NULL and ps.Title IS NOT NULL THEN ps.Title  WHEN cp.AdminChange IS NOT NULL and ps.Title IS NULL THEN cp.AdminChange ELSE '''' END, ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Maximum Class Size:</b></td>
		<td>'', c.CourseLevel, ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Semester Delivery Structure:</b></td>
		<td>'', ct.Title, ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Title and Code of course being replaced (if applicable):</b></td>
		<td>'', @course, ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Effective Semester and Academic Year:</b></td>
		<td>'', @sem, ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Course Coordinator:</b></td>
		<td>'', CONCAT(u.FirstName, '' '', u.LastName), ''</td>
	</tr>
	<tr>
		<td class="td-label"><b>Approval Authority and Date of Approval:</b></td>
		<td>'', @text2, ''</td>
	</tr>
    </table>''
	) AS Text
FROM Course c
	INNER JOIN CourseAttribute	 AS ca  ON ca.CourseId		 = c.Id
	INNER JOIN CourseDescription AS cd  ON cd.CourseId		 = c.Id
	INNER JOIN CourseProposal	 AS cp  ON cp.CourseId		 = c.Id
	INNER JOIN [User]			 AS u   ON c.UserId			 = u.Id
	LEFT JOIN Designation		 AS d   ON ca.DesignationId  = d.Id
	LEFT JOIN RevisionType		 AS rt  ON cp.RevisionTypeId = rt.Id
	LEFT JOIN QFLevel			 AS qf  ON qf.Id			 = ca.QFLevelId
	LEFT JOIN GradeOption		 AS gro ON gro.Id			 = cd.GradeOptionId
	LEFT JOIN AcademicGroup		 AS ag  ON ag.Id			 = cp.AcademicGroupId
	LEFT JOIN ComparableType	 AS ct  ON ct.Id			 = cp.ComparableTypeId
	LEFT JOIN PriorSkill As ps on ca.PriorSkillId = ps.Id
WHERE c.Id = @entityId;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 293

UPDATE CourseOutcome
SET OutcomeText = REPLACE(OutcomeText, '1. ', '')
WHERE OutcomeText like '%1. %'

UPDATE CourseOutcome
SET OutcomeText = REPLACE(OutcomeText, '2. ', '')
WHERE OutcomeText like '%2. %'

UPDATE CourseOutcome
SET OutcomeText = REPLACE(OutcomeText, '3. ', '')
WHERE OutcomeText like '%3. %'

UPDATE CourseOutcome
SET OutcomeText = REPLACE(OutcomeText, '4. ', '')
WHERE OutcomeText like '%4. %'

UPDATE CourseObjective
SET Text = REPLACE(Text, '1. ', '')
WHERE Text like '%1. %'

UPDATE CourseObjective
SET Text = REPLACE(Text, '2. ', '')
WHERE Text like '%2. %'

UPDATE CourseObjective
SET Text = REPLACE(Text, '3. ', '')
WHERE Text like '%3. %'

UPDATE CourseObjective
SET Text = REPLACE(Text, '4. ', '')
WHERE Text like '%4. %'

UPDATE CourseObjective
SET Text = REPLACE(Text, '5. ', '')
WHERE Text like '%5. %'

UPDATE CourseObjective
SET Text = REPLACE(Text, '6. ', '')
WHERE Text like '%6. %'

DECLARE @SQL2 NVARCHAR(MAX) = '
DECLARE @count int = 
(SELECT Count(Id) FROM CourseObjective
WHERE COURSEId = @entityId)

DECLARE @ILC TABLE (Title nvarchar(max))

DECLARE @text NVARCHAR(MAX) = 
CONCAT (''<table border="2" style="width:100%; table-layout: fixed; margin: auto;">
	<tr>
		<th rowspan="2" style="text-align: center;">Course Intended Learning Outcomes (CILOs)</th>
		<th colspan="'',@count,''" style="text-align: center;">Indicative Learning Contents</th>
	</tr>
	<tr>'')	


INSERT INTO @ILC
SELECT CONCAT(''<td style="text-align: left;">'',co.Text, ''</td>'')
FROM CourseObjective co
WHERE co.CourseId = @entityId
ORDER BY co.Text

SET @text += 
(SELECT dbo.ConcatWithSep_Agg(NULL,Title)
FROM @ILC)

SET @text += ''</tr>''

DECLARE @cos TABLE(coId INT, cobj INT)
INSERT INTO @cos(coId, cobj)
SELECT co.Id, cobj.Id 
FROM CourseObjective cobj
	Left JOIN CourseOutcome co ON co.CourseId = cobj.CourseId 
WHERE co.CourseId = @entityId

DECLARE @temp Table(Id INT, value NVARCHAR(MAX))
INSERT INTO @temp
SELECT coId, CONCAT(	''<td style="text-align:center">'', 
				CASE
				WHEN coId IN (SELECT CourseOutcomeId FROM CourseOutcomeCourseObjective WHERE CourseObjectiveId = co.cobj)
					THEN ''&#10003''
				ELSE '' ''
				END,
				''</td>'')
FROM @cos co

DECLARE @checks Table(Id Int, checks NVARCHAR(Max))
INSERT INTO @checks (Id, checks)
SELECT Id, dbo.ConcatWithSep_Agg('' '', value)
FROM @temp
GROUP BY Id

SET @text += 
(SELECT Distinct dbo.ConcatWithSep_Agg(	'' '',Concat(''<tr><td style="text-align: left;">'',
										co.OutcomeText,	
										ck.checks,
										''</tr>''))
FROM CourseOutcome co
	Inner JOIN @checks ck ON ck.Id = co.Id
WHERE co.CourseId = @entityId)

SET @text += ''</table>''



SELECT  @text AS Text, 0 AS Value
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 266

UPDATE MetaSelectedSection
SET SectionDescription = '<br>a. Facilities and equipment (including classroom, laboratory, library, IT and other teaching and 
learning facilities) required for the course:<br>'
WHERE MetaSelectedSectionId in (
SELECT mss.MetaSelectedSectionId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
		INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 1	--comment out if doing reports and forms
		AND mss.SectionName = 'Teaching and Learning Resources'
)

UPDATE MetaSelectedField
SET DisplayName = '<p style="font-weight: 400; margin-top: 0; margin-bottom: 0; margin-left: 15px;">Met within the School</p>'
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE msf.MetaAvailableFieldId = 3419
	and mtt.IsPresentationView = 1
)

UPDATE MetaSelectedField
SET DisplayName = '<p style="font-weight: 400; margin-top: 0; margin-bottom: 0; margin-left: 15px;">New resources required as follows:</p>'
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE msf.MetaAvailableFieldId = 3420
	and mtt.IsPresentationView = 1
)

UPDATE GenericMaxText
SET TextMax02 = '<p>Alleague, L., Jones, S., Kershaw, B. &amp; Piccini, A. (eds.). (2009). Practice-as-Research in&nbsp;<br />
Performance and screen. Palgrave Macmillan.&nbsp;</p>

<p>Barrett, E. &amp; Bolt, B. (eds.). (2007). Practice as research: Approaches to creative arts enquiry.&nbsp;<br />
I.B. Tauris.&nbsp;</p>

<p>Bell, J. (2014). Doing your research project. Open University Press.&nbsp;</p>

<p>Cahnmann-Taylor, M. &amp; Siegesmund, R. (eds.). (2008). Arts-based research in education:&nbsp;<br />
Foundations for practice. Routledge.&nbsp;</p>

<p>Clough, P. &amp; Nutbrown, C. (2007). A student&rsquo;s guide to Methodology.Sage.&nbsp;</p>

<p>Flick, U. (2007). Designing qualitative research. SAGE.&nbsp;</p>

<p>Frayling, C. (1993). Research in art and design. Royal College of Art: Research Papers.&nbsp;<br />
Available online at&nbsp;<br />
http://researchonline.rca.ac.uk/384/3/frayling_research_in_art_and_design_1993.pdf</p>

<p>Kershaw, B. &amp; Nicholson, H. (2011). Research methods in theatre and performance.&nbsp;<br />
Edinburgh University Press.&nbsp;</p>

<p>Leavy, P. (2009). Method meets art: Arts-based research practice. Guildford Press.&nbsp;</p>

<p>Maykut, R. &amp; Morehouse, R. (1994). Beginning qualitative research: A philosophical and&nbsp;<br />
practical guide. RoutledgeFalmer.&nbsp;</p>

<p>McNiff, S. (1998). Arts-based research. Jessica Kingsley.&nbsp;</p>

<p>Nelson, R. (ed.). (2013). Practice as research in the arts: Principles, protocols, pedagogies,&nbsp;<br />
resistances. Palgrave.&nbsp;</p>

<p>O&rsquo;Toole, J. (2006). Doing drama research: Stepping into enquiry in drama, theatre and&nbsp;<br />
education. Drama Australia.&nbsp;</p>

<p>Riley, S. R. &amp; Hunter,L. (eds.). (2009). Mapping landscapes for performance as research:&nbsp;<br />
Scholarly Acts and creative cartographies. Palgrave Mcmillan.&nbsp;</p>

<p>Smith, H. &amp; Dean, R. T. (eds.). (2009). Practice-led research, research-led practice in the&nbsp;<br />
creative arts. Edinburgh University Press.<br />
<br />
Spatz, B. (2015). What a body can do. Routledge.</p>

<p>Spatz, B. (2017). Embodied research: A methodology. Liminalities, 13(2)</p>
'
WHERE CourseId = 1310

UPDATE MetaSelectedSection
SET SectionDescription = '<br>Assessment methods mapped against CILOs. '
WHERE MetaSelectedSectionId in (
SELECT mss.MetaSelectedSectionId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
		INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 1	--comment out if doing reports and forms
		AND mss.SectionName = 'Assessment Outcomes, Criteria and Methods'
)

DECLARE @SQL3 NVARCHAR(MAX) = '
DECLARE @count INT = (SELECT COUNT(Id) FROM CourseOutcome WHERE CourseId = @entityId)

DECLARE @text NVARCHAR(MAX) = (SELECT CONCAT(
''<table border="2" style="width:100%; table-layout: fixed; margin: auto;">
	<tr>
		<th rowspan="2" colspan="2" style="text-align: center">Assessment Methods</th>
		<th rowspan="2" style="text-align: center">Weighting</th>
		<th rowspan="2" style="text-align: center">Rubric</th>
		<th colspan="'', @count,''"rowspan="1" style="text-align: center">Course Intended Learning Outcomes (CILOs)</th>
	</tr>
	<tr>''))

DECLARE @cos Table (Id INT, coId INT)
INSERT INTO @cos   (Id, CoId)
	SELECT Distinct cem.Id, co.Id
	FROM CourseEvaluationMethod cem
		INNER JOIN CourseOutcome co ON co.CourseId = cem.CourseId
	WHERE cem.CourseId = @entityId

SET @text += (
	SELECT dbo.ConcatWithSepOrdered_Agg('''', SortOrder, concat(''<td style="text-align:left">'', OutcomeText, ''</td>'')) 
	FROM CourseOutcome WHERE CourseId = @entityId)

SET @text += ''</tr>''

DECLARE @checks TABLE (Id INT, Value NVARCHAR(MAX))
INSERT INTO @checks   (Id, Value)
	SELECT Id, CONCAT(	
		''<td style="text-align: center">'',
		CASE WHEN coId IN (
			SELECT CourseOutcomeId FROM CourseEvaluationMethodCourseOutcome 
			WHERE CourseEvaluationMethodId = co.Id)
		THEN ''&#10003'' ELSE '' '' END, ''</td>''
		)
	FROM @cos co

DECLARE @temp TABLE(Id INT IDENTITY PRIMARY KEY, Text NVARCHAR(MAX))

--SET @text += 

DECLARE @rows TABLE (Row NVARCHAR(Max))

INSERT INTO @rows
SELECT CONCAT(	
	''<tr>
		<td colspan="2">'', ast.Title, ''</td>
		<td style="text-align:center;">'', cem.Int01, ''%</td>
		<td style="text-align:left;">'', m.Title,   ''</td>'',
		dbo.ConcatWithSep_Agg('' '', ck.Value),
	''</tr>'')
FROM CourseEvaluationMethod cem
	INNER JOIN AssignmentType ast ON cem.AssignmentTypeId = ast.Id
	LEFT JOIN  Module m ON m.Id = cem.Related_ModuleId
	LEFT JOIN  @checks ck ON ck.Id = cem.Id
WHERE cem.CourseId = @entityId
GROUP BY cem.Id, ast.Title,cem.Int01, m.Title

SET @text += (SELECT dbo.ConcatWithSep_Agg('' '', Row) FROM @rows)

SET @text += ''</table>''

SELECT @text AS Text, 0 AS Value
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL3
,ResolutionSql = @SQL3
WHERE Id = 269

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT
1, -- [ClientId]
mss.MetaSelectedSectionId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Rubrics<br><br>', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
3, -- [RowPosition]
3, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
mss.MetaTemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM MEtaSelectedSection AS mss
INNER JOIN MetaTemplate As mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 1	--comment out if doing reports and forms
		AND mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
		and mss.RowPosition = 3

DECLARE @Section Int = SCOPE_IDENTITY()

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
declare @query NVARCHAR(max) = (
    select CustomSql
    from MetaForeignKeyCriteriaClient
    where Title = 'Rubric Graph output'
)

declare @admin int = (select id from [User] where Email = 'supportadmin@curriqunet.com')

DECLARE @TABLE TABLE (val nvarchar(max))
INSERT INTO @TABLE
select distinct
 ca.Text 
from Course PS
    inner join CourseEvaluationMethod cem on cem.CourseId = PS.Id
    inner join [Module] m on m.Id = cem.Related_ModuleId
    cross apply dbo.fnBulkResolveCustomSqlQuery(@query,0,m.Id,1,@admin,1,null) ca
where PS.Id = @EntityId

SELECT 0 AS Value,
dbo.ConcatWithSep_Agg('<br>', t.val) AS Text
FROM @TABLE AS t
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseRubric', 'Id', 'Title', @CSQL, @CSQL, 'Order By SortOrder', 'Rubic Display for Report', 2)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
NULL, -- [DisplayName]
8907, -- [MetaAvailableFieldId]
@Section, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
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
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateID FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (
		293, 266, 269
	)
)