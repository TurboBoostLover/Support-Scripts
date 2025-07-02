USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18831';
DECLARE @Comments nvarchar(Max) = 
	'Fix Honors course issues';
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
Declare @clientId int =2, -- SELECT Id, Title FROM Client 
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
		AND mtt.MetaTemplateTypeId in (91)		--comment back in if just doing some of the mtt's

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
('Methods of Evaluation', 'CourseEvaluationMethod', 'EvaluationMethodId','1')

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
UPDATE MetaSelectedSection
SET ReadOnly = 0
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '1'
)

UPDATE MetaSelectedField
SET ReadOnly = 0
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '1'
)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @prevCourse INT = (
SELECT PrevCourseId
FROM CourseProposal cp
WHERE cp.CourseId = @entityId)

DECLARE @Dates nvarchar(max) = (
SELECT dbo.concatWithSepOrdered_Agg(''<br>'', cdt.Id,CONCAT(''<b>'', cdt.Title,''</b>: '', FORMAT(cd.CourseDate, ''MM/dd/yyyy'')))
FROM CourseDate cd
	INNER JOIN CourseDateType cdt ON cd.CourseDateTypeId = cdt.Id
WHERE courseId = @prevCourse
and cd.PreviousId IS NULL)

DECLARE @approvalDate nvarchar(max) = (
select max(format(plah.ResultDate,''MM/dd/yyyy'')) as cccActionDate
from ProcessStepActionHistory psah
    left join ActionLevelRoute alr on psah.ActionLevelRouteId = alr.Id
    left join [Action] a on alr.ActionId = a.Active
		and a.Title = ''Approve''
    left join ProcessLevelActionHistory plah on psah.ProcessLevelActionHistoryId = plah.Id
    left join Proposal prop on plah.ProposalId = prop.Id
    left join Step s on plah.StepLevelId = s.StepLevelId
    left join Course c on prop.Id = c.ProposalId
where c.Id = @prevCourse
    and s.Title = ''Curriculum Committee Chair''
)

DECLARE @fco nvarchar(max) = (
SELECT CONCAT(''<ul>'',dbo.ConcatWithSepOrdered_Agg('''', l.SortOrder, CONCAT(''<li>'', l.Title, ''</li>'')),''</ul>'')
FROM CourseLookup14 cl
	INNER JOIN Lookup14 l ON l.Id = cl.Lookup14Id
WHERE cl.CourseId = @prevCourse)


SELECT CONCAT(''<h4>Base Course: Codes and Dates</h4>''
			,''<h5>Dates</h5>'', @Dates, ''<br><br>''
			, ''<b>Course Origination Date</b>: '', FORMAT(c.CreatedOn, ''MM/dd/yyyy'')
			, ''<br><b>Course Originator</b>: '', u.LastName, '', '', u.FirstName
			, ''<br><b>Effective Date</b>: '', FORMAT(p.ImplementDate, ''MM/dd/yyyy'')
			, ''<br><b>Effective Term</b>: '', s.Title
			, ''<br><b>Curriculum Committee Approval Date</b>: '', @approvalDate
			, ''<br><br><b>CB03: TOP Code</b>: '', cb3.Description
			, ''<br><b>CB04: Credit Status</b>: '', cb4.Description
			, ''<br><b>CB05: Transfer Status</b>: '', cb5.Description
			, ''<br><b>CB08: Basic Skills Status</b>: '', cb8.Description
			, ''<br><b>CB09: SAM Code</b>: '', cb9.Description
			, ''<br><b>CB10: Cooperative Work Experience</b>: '', cb10.Description
			, ''<br><b>CB11: Course Classification Status</b>: '', cb11.Description
			, ''<br><b>CB13: Special Class Status</b>: '', cb13.Description
			, ''<br><b>CB21: Course Prior to Transfer Level</b>: '', cb21.Description
			, ''<br><b>CB23: Funding Agency Category</b>: '', cb23.Description
			, ''<br><b>CB24: Program Status</b>: '', cb24.Description
			, ''<br><b>CB25: Course General Education Status</b>: '', cb25.Description
			, ''<br><b>CB26: Course Support Course Status</b>: '', cb26.Description
			, ''<br><b>CB27: Course Upper Division Status</b>: '', cb26.Description
			, ''<h5>Future Course Offering</h5>'', @fco
			, ''<h5>Enrollment</h5>''
			, ''<b>Minimum Enrollment</b>: '', cp.MinEnrollment
			, ''<br><b>Maximum Enrollment</b>: '', cp.MaxEnrollment) AS Text, 0 AS Value
FROM Course c
	INNER JOIN CourseProposal cp ON cp.CourseId = c.Id
	INNER JOIN CourseCBCode ccbc ON ccbc.CourseId = c.Id
	LEFT JOIN [User] u ON u.Id = c.UserId
	LEFT JOIN Proposal p ON p.Id = c.ProposalId
	LEFT JOIN Semester s ON s.Id = cp.SemesterId
	LEFT JOIN CB03 cb3 ON cb3.Id = ccbc.cb03Id
	LEFT JOIN CB04 cb4 ON cb4.Id = ccbc.cb04Id
	LEFT JOIN CB05 cb5 ON cb5.Id = ccbc.cb05Id
	LEFT JOIN CB08 cb8 ON cb8.Id = ccbc.cb08Id
	LEFT JOIN CB09 cb9 ON cb9.Id = ccbc.cb09Id
	LEFT JOIN CB10 cb10 ON cb10.Id = ccbc.cb10Id
	LEFT JOIN CB11 cb11 ON cb11.Id = ccbc.cb11Id
	LEFT JOIN CB13 cb13 ON cb13.Id = ccbc.cb13Id
	LEFT JOIN CB21 cb21 ON cb21.Id = ccbc.cb21Id
	LEFT JOIN CB23 cb23 ON cb23.Id = ccbc.cb23Id
	LEFT JOIN CB24 cb24 ON cb24.Id = ccbc.cb24Id
	LEFT JOIN CB25 cb25 ON cb25.Id = ccbc.cb25Id
	LEFT JOIN CB26 cb26 ON cb26.Id = ccbc.cb26Id
	LEFT JOIN CB27 cb27 ON cb27.Id = ccbc.cb27Id
WHERE c.Id = @prevCourse
'
, ResolutionSql = '
DECLARE @prevCourse INT = (
SELECT PrevCourseId
FROM CourseProposal cp
WHERE cp.CourseId = @entityId)

DECLARE @Dates nvarchar(max) = (
SELECT dbo.concatWithSepOrdered_Agg(''<br>'', cdt.Id,CONCAT(''<b>'', cdt.Title,''</b>: '', FORMAT(cd.CourseDate, ''MM/dd/yyyy'')))
FROM CourseDate cd
	INNER JOIN CourseDateType cdt ON cd.CourseDateTypeId = cdt.Id
WHERE courseId = @prevCourse
and cd.PreviousId IS NULL)

DECLARE @approvalDate nvarchar(max) = (
select max(format(plah.ResultDate,''MM/dd/yyyy'')) as cccActionDate
from ProcessStepActionHistory psah
    left join ActionLevelRoute alr on psah.ActionLevelRouteId = alr.Id
    left join [Action] a on alr.ActionId = a.Active
		and a.Title = ''Approve''
    left join ProcessLevelActionHistory plah on psah.ProcessLevelActionHistoryId = plah.Id
    left join Proposal prop on plah.ProposalId = prop.Id
    left join Step s on plah.StepLevelId = s.StepLevelId
    left join Course c on prop.Id = c.ProposalId
where c.Id = @prevCourse
    and s.Title = ''Curriculum Committee Chair''
)

DECLARE @fco nvarchar(max) = (
SELECT CONCAT(''<ul>'',dbo.ConcatWithSepOrdered_Agg('''', l.SortOrder, CONCAT(''<li>'', l.Title, ''</li>'')),''</ul>'')
FROM CourseLookup14 cl
	INNER JOIN Lookup14 l ON l.Id = cl.Lookup14Id
WHERE cl.CourseId = @prevCourse)


SELECT CONCAT(''<h4>Base Course: Codes and Dates</h4>''
			,''<h5>Dates</h5>'', @Dates, ''<br><br>''
			, ''<b>Course Origination Date</b>: '', FORMAT(c.CreatedOn, ''MM/dd/yyyy'')
			, ''<br><b>Course Originator</b>: '', u.LastName, '', '', u.FirstName
			, ''<br><b>Effective Date</b>: '', FORMAT(p.ImplementDate, ''MM/dd/yyyy'')
			, ''<br><b>Effective Term</b>: '', s.Title
			, ''<br><b>Curriculum Committee Approval Date</b>: '', @approvalDate
			, ''<br><br><b>CB03: TOP Code</b>: '', cb3.Description
			, ''<br><b>CB04: Credit Status</b>: '', cb4.Description
			, ''<br><b>CB05: Transfer Status</b>: '', cb5.Description
			, ''<br><b>CB08: Basic Skills Status</b>: '', cb8.Description
			, ''<br><b>CB09: SAM Code</b>: '', cb9.Description
			, ''<br><b>CB10: Cooperative Work Experience</b>: '', cb10.Description
			, ''<br><b>CB11: Course Classification Status</b>: '', cb11.Description
			, ''<br><b>CB13: Special Class Status</b>: '', cb13.Description
			, ''<br><b>CB21: Course Prior to Transfer Level</b>: '', cb21.Description
			, ''<br><b>CB23: Funding Agency Category</b>: '', cb23.Description
			, ''<br><b>CB24: Program Status</b>: '', cb24.Description
			, ''<br><b>CB25: Course General Education Status</b>: '', cb25.Description
			, ''<br><b>CB26: Course Support Course Status</b>: '', cb26.Description
			, ''<br><b>CB27: Course Upper Division Status</b>: '', cb26.Description
			, ''<h5>Future Course Offering</h5>'', @fco
			, ''<h5>Enrollment</h5>''
			, ''<b>Minimum Enrollment</b>: '', cp.MinEnrollment
			, ''<br><b>Maximum Enrollment</b>: '', cp.MaxEnrollment) AS Text, 0 AS Value
FROM Course c
	INNER JOIN CourseProposal cp ON cp.CourseId = c.Id
	INNER JOIN CourseCBCode ccbc ON ccbc.CourseId = c.Id
	LEFT JOIN [User] u ON u.Id = c.UserId
	LEFT JOIN Proposal p ON p.Id = c.ProposalId
	LEFT JOIN Semester s ON s.Id = cp.SemesterId
	LEFT JOIN CB03 cb3 ON cb3.Id = ccbc.cb03Id
	LEFT JOIN CB04 cb4 ON cb4.Id = ccbc.cb04Id
	LEFT JOIN CB05 cb5 ON cb5.Id = ccbc.cb05Id
	LEFT JOIN CB08 cb8 ON cb8.Id = ccbc.cb08Id
	LEFT JOIN CB09 cb9 ON cb9.Id = ccbc.cb09Id
	LEFT JOIN CB10 cb10 ON cb10.Id = ccbc.cb10Id
	LEFT JOIN CB11 cb11 ON cb11.Id = ccbc.cb11Id
	LEFT JOIN CB13 cb13 ON cb13.Id = ccbc.cb13Id
	LEFT JOIN CB21 cb21 ON cb21.Id = ccbc.cb21Id
	LEFT JOIN CB23 cb23 ON cb23.Id = ccbc.cb23Id
	LEFT JOIN CB24 cb24 ON cb24.Id = ccbc.cb24Id
	LEFT JOIN CB25 cb25 ON cb25.Id = ccbc.cb25Id
	LEFT JOIN CB26 cb26 ON cb26.Id = ccbc.cb26Id
	LEFT JOIN CB27 cb27 ON cb27.Id = ccbc.cb27Id
WHERE c.Id = @prevCourse
'
WHERE Id = 5976

DECLARE @reportId int = 480
DECLARE @reportTitle NVARCHAR(MAX) = 'Honors Course Outline - PDF'
DECLARE @newMT int = 123
DECLARE @entityId int = 1	--1-Courses, 2-Programs, 6-Modules
DECLARE @reportType int = 4		--2-CourseCompare, 4-CourseAllFields, 6-Program/ModuleCompare, 13-Program/ModuleAllFields

DECLARE @reportAttribute NVARCHAR(MAX) = '{"isPublicReport":true,"reportTemplateId":123,"fieldRenderingStrategy":"HideEmptyFields","sectionRenderingStrategy":"HideEmptySections","cssOverride":".college-logo{padding-bottom:25px}"}'

INSERT INTO MetaReport
(Id,Title,MetaReportTypeId,OutputFormatId,ReportAttributes)
VALUES
(@reportId, @reportTitle, @reportType, 4, @reportAttribute)


INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
SELECT
	@reportId,
	mtt.MetaTemplateTypeId,
	GETDATE()
FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = @entityId
AND mt.Active = 1
AND mt.IsDraft = 0
AND mtt.Active = 1
AND mtt.IsPresentationView = 0
and mtt.MetaTemplateTypeId in (
84,
91,
109
)

DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaReportActionType', 'Id', 3;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)
DECLARE @MAX2 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 2)
DECLARE @MAX3 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 3)

INSERT INTO MetaReportActionType
(Id, MetaReportId, ProcessActionTypeId)
VALUES
(@MAX,@reportId,1),
(@MAX2,@reportId,2),
(@MAX3,@reportId,3)

DECLARE @Field int = (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId = 85
	and msf.MetaAvailableFieldId = 8934
)

DECLARE @NewIds2 TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds2
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 1;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX1 int = (SELECT MissingValue FROM @NewIds2 WHERE Sort = 1)		--Create more Variables here using Sort if needed

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
DECLARE @TEXT TABLE (Id INT IDENTITY(1,1) PRIMARY KEY, Text NVARCHAR(MAX), sort int, CourseId int)
DROP TABLE IF EXISTS #OL;

CREATE TABLE #OL 
	(
      [Text] NVARCHAR(MAX)
    , Id INT
    , Parent INT
    , Sort INT
    , ListItemType INT
	)
	;

INSERT INTO #OL
SELECT 
    CASE 
        WHEN lit.ListItemTypeOrdinal = 1 AND co.EvaluationText IS NULL
        THEN CONCAT
			(
			em.Title
			, ' ('
			, co.EvaluationPercent
			, '-'
			, co.Int01
			, '%)'
			, CASE
                WHEN co.LargeText02 IS NULL 
				THEN NULL 
				ELSE CONCAT
					(
					  '<ul><li><b>Comment: </b>'
					, co.LargeText02
					, '</ul>'
					)
              END
            )
        WHEN lit.ListItemTypeOrdinal = 1 AND co.EvaluationText IS NOT NULL
        THEN CONCAT
			(
			  em.Title
			, ': '
			, co.EvaluationText
			, ' ('
			, co.EvaluationPercent
			, '-'
			, co.Int01
			, '%)'
			, CASE
				WHEN co.LargeText02 IS NULL
                THEN NULL
                ELSE CONCAT
					(
					  '<ul><li><b>Comment: </b>'
					, co.LargeText02
					, '</ul>'
					)
              END
            )
        ELSE co.LargeText01
    END AS [Text]
    , co.Id
    , co.Parent_Id AS Parent
    , co.SortOrder AS Sort
    , co.ListItemTypeId AS ListItemType
FROM CourseEvaluationMethod co
    INNER JOIN ListItemType lit ON co.ListItemTypeId = lit.Id
    LEFT JOIN EvaluationMethod em ON co.EvaluationMethodId = em.Id
WHERE co.CourseId = @entityId;

IF ((SELECT COUNT(*) FROM #OL) > 0)
    BEGIN
        DECLARE @renderQuery NVARCHAR(MAX);
        DECLARE @renderIds INTEGERS;

        DROP TABLE IF EXISTS #renderedOutcomes;
        CREATE TABLE #renderedOutcomes 
			(
              Id INT PRIMARY KEY
			, Parent_Id INT INDEX ixRenderedOutcomes_Parent_Id
			, RenderedText NVARCHAR(MAX)
			, SortOrder INT INDEX ixRenderedOutcomes_SortOrder
			, ListItemTypeId INT
			);
        
        SET @renderQuery =
        '
		DECLARE @childIds INTEGERS;

        INSERT INTO @childIds 
			(Id)
        SELECT 
			co2.Id
        FROM #OL co
			INNER JOIN @renderIds ri ON co.Id = ri.Id
			INNER JOIN #OL co2 ON co.Id = co2.Parent
		;

        IF ((SELECT COUNT(*) FROM @childIds) > 0)
        BEGIN;
            EXEC sp_executesql 
				  @renderQuery
				, N''@renderIds INTEGERS READONLY, @renderQuery NVARCHAR(MAX)''
				, @childIds
				, @renderQuery
				;
        END;

        INSERT INTO #renderedOutcomes 
			(Id, Parent_Id, RenderedText, SortOrder, ListItemTypeId)
        SELECT 
			co.Id, co.Parent, ro.RenderedOutcome, co.Sort, co.ListItemType
        FROM #OL co
			INNER JOIN @renderIds ri ON co.Id = ri.Id
			OUTER APPLY 
				(
				SELECT 
					dbo.ConcatWithSepOrdered_Agg 
						(NULL, ro.SortOrder, ro.RenderedText) 
					AS RenderedChildren
				FROM #renderedOutcomes ro
				WHERE ro.Parent_Id = co.Id
				) rc
			OUTER APPLY 
				(
				SELECT
					CONCAT
						(
						  dbo.fnHtmlOpenTag
							(
							  ''ol''
							, CASE 
								WHEN co.ListItemType = 5 AND co.Parent IS NOT NULL 
								THEN ''style=""list-style-type:lower-roman""'' 
								ELSE ''style=""list-style-type:lower-alpha""'' 
							  END
							)
						, rc.RenderedChildren
						, dbo.fnHtmlCloseTag(''ol'')
						) RenderedChildrenWithListWrapper
				WHERE rc.RenderedChildren IS NOT NULL 
				AND LEN(rc.RenderedChildren ) > 0
				) rcw
			CROSS APPLY 
				(
				SELECT
					CONCAT
						(
						  dbo.fnHtmlOpenTag(''li'', NULL)
						, dbo.fnHtmlOpenTag(''div'', NULL)
						, coalesce(co.Text,'''')
						, dbo.fnHtmlCloseTag(''div'')
						, rcw.RenderedChildrenWithListWrapper
						, dbo.fnHtmlCloseTag(''li'')
						) AS RenderedOutcome
				) ro;
		'
		;

		DECLARE @childIds INTEGERS;
			INSERT INTO @childIds 
				(Id)
			SELECT Id FROM #OL WHERE Parent IS NULL;
			EXEC sp_executesql 
				  @renderQuery
				, N'@renderIds INTEGERS READONLY, @renderQuery NVARCHAR(MAX)'
				, @childIds
				, @renderQuery
			;

		;WITH NumberedRows AS 
			(
			SELECT 
				  ro.*
				, DENSE_RANK() OVER (ORDER BY ro.SortOrder) AS DenseRank
				, ROW_NUMBER() OVER (PARTITION BY ro.SortOrder ORDER BY (SELECT NULL)) AS RowNum
				, MAX(ro.SortOrder) OVER () AS MaxSortOrder
			FROM #renderedOutcomes ro
			WHERE ro.Parent_Id IS NULL
			)
			INSERT INTO @TEXT
		SELECT 
			CONCAT
				('<h4>New Methods of Evaluation</h4>',
				  dbo.fnHtmlOpenTag('ol', NULL)
				, dbo.ConcatWithSepOrdered_Agg
					(
					  NULL
					, CASE WHEN RowNum > 1 THEN MaxSortOrder + RowNum - 1 ELSE SortOrder END
					, RenderedText
					)
				, dbo.fnHtmlCloseTag('ol')
				) AS [Text], 2, @EntityId
		FROM NumberedRows
	END
ELSE
	BEGIN
		INSERT INTO @TEXT
		SELECT SpecifyDegree AS [Text], 2, @EntityId
		FROM Course WHERE Id = @entityId;
	END

DROP TABLE IF EXISTS #renderedOutcomes;
DROP TABLE IF EXISTS #OL;

Drop table if EXISTS #OL2
create table #OL2 ( Text nvarchar(max), Id int, parent int, sort int, listitemtype int)
Insert into #OL2
SELECt 
    Case 
        WHEn cem.ListItemTypeId = 9
            then concat(
				em.Title,
                '<br>',
                '<b>Evaluation Min Percent: </b>',
                cem.EvaluationPercent,
                '<br>',
                '<b>Evaluation Max Percent: </b>',
				cem.Int01
				,'<br><b>Comments</b>: '
				, cem.LargeText02
				,                
                Case 
					WHEN em.Title = 'Other' then 
						CONCAT(
							'<br> <b>If you selected ""Other"", please provide details.</b> ',
							cem.EvaluationText)
                    Else ''
                End
				
            )
            ELSE cem.LargeText01
           
        End As Text, cem.id As ID, cem.Parent_Id as Parent, cem.SortOrder as sort, cem.ListItemTypeId as Listitemtype
FROM 
	CourseEvaluationMethod CEM
    LEFT JOIN EvaluationMethod em on cem.EvaluationMethodId = em.id
	INNER JOIN CourseProposal CP2 ON cem.CourseId = CP2.PrevCourseId
	INNER JOIN Course AS c on CP2.CourseId = c.Id
WHERE CP2.CourseId = @entityId
and c.ProposalTypeId not in (149, 152)

declare @renderQuery2 nvarchar(max);
declare @renderIds2 integers;

DROP TABLE IF EXISTS #renderedOutcomes2;
create table #renderedOutcomes2 (
	Id int primary key,
	Parent_Id int index ixRenderedOutcomes_Parent_Id,
	RenderedText nvarchar(max),
	SortOrder int index ixRenderedOutcomes_SortOrder,
	ListItemTypeId int
);
--====================
SET @renderQuery2 =
'declare @childIds2 integers;

insert into @childIds2 (Id)
select co2.Id
from #OL2 co
inner join @renderIds2 ri on co.Id = ri.Id
inner join #OL2 co2 on co.Id = co2.Parent;

if ((select count(*) from @childIds2) > 0)
begin;
	exec sp_executesql @renderQuery2, N''@renderIds2 integers readonly, @renderQuery2 nvarchar(max)'', @childIds2, @renderQuery2;
end;

insert into #renderedOutcomes2 (Id, Parent_Id, RenderedText, SortOrder,ListItemTypeId)
select
	co.Id, co.Parent, ro.RenderedOutcome, co.Sort,co.ListItemType
from #OL2 co
inner join @renderIds2 ri on co.Id = ri.Id
outer apply (
	select dbo.ConcatWithSepOrdered_Agg(null, ro.SortOrder, ro.RenderedText) as RenderedChildren
	from #renderedOutcomes2 ro
	where ro.Parent_Id = co.Id
) rc
outer apply (
	select
		concat(
			dbo.fnHtmlOpenTag(''ol'', case when co.ListItemType = 5 and co.Parent is not null then ''style=""list-style-type:lower-roman""'' else ''style=""list-style-type:lower-alpha""''end), rc.RenderedChildren, dbo.fnHtmlCloseTag(''ol'')
		) RenderedChildrenWithListWrapper
	where rc.RenderedChildren is not null and len(rc.RenderedChildren ) > 0
) rcw
cross apply (
	select
		concat(
			dbo.fnHtmlOpenTag(''li'', null),
				dbo.fnHtmlOpenTag(''div'', null), coalesce(co.text,''''),dbo.fnHtmlCloseTag(''div''),
				rcw.RenderedChildrenWithListWrapper,
			dbo.fnHtmlCloseTag(''li'')
		) as RenderedOutcome
) ro;'
declare @childIds2 integers

INSERT INTO @childIds2
(Id)
	SELECT
		Id
	FROM #OL2
	WHERE Parent IS NULL;

EXEC sp_executesql @renderQuery2
				  ,N'@renderIds2 integers readonly, @renderQuery2 nvarchar(max)'
				  ,@childIds2
				  ,@renderQuery2;

INSERT INTO @TEXT
SELECT
CONCAT('<h4>Base Course: Methods of Evaluation</h4>',
	dbo.fnHtmlOpenTag('ol', null),
	dbo.ConcatWithSepOrdered_Agg(NULL, ro.SortOrder, ro.RenderedText),
	dbo.fnHtmlCloseTag('ol')
	) AS [Text], 1, @EntityId
FROM #renderedOutcomes2 ro
WHERE ro.Parent_Id IS NULL;

DROP TABLE IF EXISTS #renderedOutcomes2;
DROP TABLE IF EXISTS #OL2;

IF EXISTS (SELECT 1 FROM Course WHERE Id = @EntityId AND ProposalTypeId NOT IN (149, 152))
BEGIN
    SELECT 0 AS Value, 
           dbo.ConcatWithSepOrdered_Agg('<br>', sort, Text) AS Text 
    FROM @TEXT AS t
    INNER JOIN Course AS c ON t.CourseId = c.Id
    WHERE Text IS NOT NULL
END
ELSE
BEGIN
    SELECT 0 AS Value, 
           Text 
    FROM @TEXT AS t
    INNER JOIN Course AS c ON t.CourseId = c.Id
    WHERE Text IS NOT NULL
      AND sort = 2
END
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX1, 'CourseEvaluationMethod', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'Base Course with new items', 2)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX1
WHERE MetaSelectedFieldId = @Field

INSERT INTO MetaReportTemplateType
(MetaReportId , MetaTemplateTypeId, StartDate)
VALUES
(319, 109, GETDATE())
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (
select templateId FROM @Fields
UNION
SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @MAX1
)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback