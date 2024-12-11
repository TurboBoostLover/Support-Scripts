USE [idoe];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13827';
DECLARE @Comments nvarchar(Max) = 
	'Update Literal DropDowns';
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
DECLARE @Templates TABLE (TId int, FId int, FMA int)
INSERT INTO @Templates (TId, FId, FMA)
SELECT mt.MetaTemplateId, Msf.MetaSelectedFieldId, msf.MetaAvailableFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE msf.MetaPresentationTypeId = 101

DELETE FROM MetaLiteralList
WHERE MetaSelectedFieldId in (Select FId FROM @Templates)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA in (2751, 2088))	--FMA is MetaAvailable Field		Templates are not active and no data and no course/Program/Module is using the inactive templates

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 6440
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 286)	--FMA is MetaAvailable Field

INSERT INTO MinimumGrade
(Code, SortOrder, ClientId,StartDate)
VALUES
('A', 1, 1, CURRENT_TIMESTAMP),
('A-', 2, 1, CURRENT_TIMESTAMP),
('B+', 3, 1, CURRENT_TIMESTAMP),
('B', 4, 1, CURRENT_TIMESTAMP),
('B-', 5, 1, CURRENT_TIMESTAMP),
('C+', 6, 1, CURRENT_TIMESTAMP),
('C', 7, 1, CURRENT_TIMESTAMP),
('C-', 8, 1, CURRENT_TIMESTAMP),
('D+', 9, 1, CURRENT_TIMESTAMP),
('D', 10, 1, CURRENT_TIMESTAMP),
('D-', 11, 1, CURRENT_TIMESTAMP),
('P/F', 12, 1, CURRENT_TIMESTAMP)

UPDATE cr
SET MinimumGradeId = mg.Id
FROM CourseRequisite cr
	INNER JOIN MinimumGrade mg ON cr.MinimumGrade = mg.Code
WHERE cr.MinimumGrade IS NOT NULL;

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "

declare @numberedReqs table (   CourseRequisiteId int,   PreCoReqTypesId int,   MinimumGrade nvarchar(6),   ReqType nvarchar(500),   RequisiteTitle nvarchar(max),   OtherReqTitle nvarchar(500),   ConditionTitle nvarchar(100),   Comments nvarchar(4000),   IterationOrder int,   ReqCount int  );

IF EXISTS (SELECT
		1
	FROM CourseRequisite cr
	LEFT OUTER JOIN PreCoRequisiteType pcrt
		ON cr.PreCoReqTypesId = pcrt.Id
	LEFT OUTER JOIN EligibilityCriteria ec
		ON cr.EligibilityCriteriaId = ec.Id
	LEFT OUTER JOIN Condition con
		ON cr.ConditionId = con.Id
	LEFT OUTER JOIN Course c
	INNER JOIN [Subject] s
		ON c.SubjectId = s.Id
		ON cr.Requisite_CourseId = c.Id
	WHERE cr.CourseId = @entityId)
BEGIN
INSERT INTO @numberedReqs (CourseRequisiteId, PreCoReqTypesId, MinimumGrade, ReqType, RequisiteTitle, OtherReqTitle, ConditionTitle, Comments, IterationOrder, ReqCount)
	SELECT
		cr.Id AS CourseRequisiteId
	   ,cr.PreCoReqTypesId
	   ,mg.Code
	   ,COALESCE(pcrt.Title + ' - ' + pcrt.[Description], pcrt.[Description]) AS ReqType
	   ,s.SubjectCode + ' ' + c.CourseNumber + ' ' + COALESCE(RTRIM(c.Title), '') AS RequisiteTitle
	   ,ec.Title AS OtherReqTitle
	   ,con.Title AS ConditionTitle
	   ,cr.CommText AS Comments
	   ,ROW_NUMBER() OVER (ORDER BY cr.SortOrder) AS IterationOrder
	   ,COUNT(*) OVER () AS ReqCount
	FROM CourseRequisite cr
	LEFT OUTER JOIN PreCoRequisiteType pcrt
		ON cr.PreCoReqTypesId = pcrt.Id
	LEFT OUTER JOIN EligibilityCriteria ec
		ON cr.EligibilityCriteriaId = ec.Id
	LEFT JOIN MinimumGrade AS mg
		ON cr.MinimumGradeId = mg.Id
	LEFT OUTER JOIN Condition con
		ON cr.ConditionId = con.Id
	LEFT OUTER JOIN Course c
	INNER JOIN [Subject] s
		ON c.SubjectId = s.Id
		ON cr.Requisite_CourseId = c.Id
	WHERE cr.CourseId = @entityId;
WITH ComposedRequisites
AS
(SELECT
		COALESCE(' ' + nr.RequisiteTitle, '') + COALESCE(' Minimum Grade (' +
		CASE
			WHEN nr.MinimumGrade = '-1' THEN NULL
			ELSE nr.MinimumGrade
		END + ') ', '') + COALESCE(' ' + nr.OtherReqTitle, ' ') + COALESCE(' ' + nr.Comments, ' ') +
		CASE
			WHEN nr.IterationOrder < nr.ReqCount THEN ', '
			ELSE ''
		END + COALESCE(nr.ConditionTitle, ' ') AS ComposedText
	   ,nr.CourseRequisiteId
	   ,nr.PreCoReqTypesId
	   ,nr.ReqType
	   ,nr.IterationOrder
	   ,nr.ReqCount
	FROM @numberedReqs nr),
CombinedRequisites
AS
(SELECT
		cr.CourseRequisiteId
	   ,cr.PreCoReqTypesId
	   ,cr.ReqType
	   ,cr.IterationOrder
	   ,cr.ReqCount
	   ,CAST(COALESCE('<div class=""requisite-type-title"">' + cr.ReqType + '</div> ', '') + COALESCE('<div class=""requisite-text"">' + cr.ComposedText + '</div> ', '') AS NVARCHAR(MAX)) AS CombinedText
	   ,CASE
			WHEN cr.IterationOrder = cr.ReqCount THEN 1
			ELSE 0
		END AS FinalRow
	FROM ComposedRequisites cr
	WHERE cr.IterationOrder = 1 UNION ALL SELECT
		cr.CourseRequisiteId
	   ,cr.PreCoReqTypesId
	   ,cr.ReqType
	   ,cr.IterationOrder
	   ,cr.ReqCount
	   ,combo.CombinedText + CAST(CASE
			WHEN cr.PreCoReqTypesId <> combo.PreCoReqTypesId THEN COALESCE('<div class=""requisite-type-title"">' + cr.ReqType + '</div> ', '')
			ELSE ''
		END + COALESCE('<div class=""requisite-text"">' + cr.ComposedText + '</div> ', '') AS NVARCHAR(MAX)) AS CombinedText
	   ,CASE
			WHEN cr.IterationOrder = cr.ReqCount THEN 1
			ELSE 0
		END AS FinalRow
	FROM ComposedRequisites cr
	INNER JOIN CombinedRequisites combo
		ON cr.IterationOrder = (combo.IterationOrder + 1))
SELECT
	0 AS Value
   ,CombinedText AS [Text]
FROM CombinedRequisites combo
WHERE combo.FinalRow = 1
END;
ELSE
BEGIN;
SELECT
	0 AS Value
   ,'<div style=""padding: 10px;"">None</div>' AS Text
END;
"

UPDATE AdminReport 
SET ReportSQL = "

declare @includeInReview bit = 1;
declare @courseIds table (CourseId int, ImpDate datetime);

with activecoursefamilies as 
(
	select distinct BaseCourseId from course c
		INNER JOIN CourseProposal p ON c.Id = p.CourseId
		left join Semester s on s.Id = p.SemesterId
	where c.ClientId = 4 
		AND (
			StatusAliasId IN (1,2) 
				OR 
				(
					StatusAliasId IN (7,9,10) 
					AND 
					(
						(cast(p.StartYear as int) = @year ) AND (s.TermStartDate > (select top 1 TermEndDate from Semester where Title = @semester AND ClientId = 1))
					)
					OR (cast(p.StartYear as int) > @year)
				)
		)

) 
,courses as (
	SELECT max(c.Id) as Id
	FROM Course c
		INNER JOIN CourseProposal p ON c.Id = p.CourseId
		INNER JOIN activecoursefamilies acf on acf.BaseCourseId = c.BaseCourseId
		left join Semester s on s.Id = p.SemesterId
	WHERE c.ClientId = 4 AND c.Active = 1
	AND StatusAliasId NOT IN (4,12) -- Draft and In Review should never show.
	AND (cast(p.StartYear as int) < @year 
		OR (p.StartYear IS NULL AND StatusAliasId IN (1,2))
		OR (cast(p.StartYear as int) = @year 
			AND (s.TermStartDate < (select top 1 TermEndDate from Semester where Title = @semester AND ClientId = 1) OR (s.Id IS NULL AND StatusAliasId IN (1,2)))
		)
	)
	GROUP BY c.BaseCourseId
)
INSERT INTO @courseIds(CourseId)
SELECT c.Id 
from courses cs 
join course c on c.Id = cs.Id
	where ProposalTypeId NOT IN (81,82,83,92,93) --deactivations, these should never appear in the report even at 'Approved' status
;

IF(@includeInReview = 1)
BEGIN 
	insert into @courseIds (CourseId)
	select c.Id from course c 
	join CourseProposal p on p.CourseId = c.Id
	join ProposalType pt on pt.Id = c.ProposalTypeId
	join Semester s on s.Id = p.SemesterId
	where pt.ProcessActionTypeId = 1
	AND c.StatusAliasId = 12
	AND c.Active = 1
	AND c.ClientId = 4
	AND (cast(p.StartYear as int) < @year 
		OR (p.StartYear IS NULL)
		OR (cast(p.StartYear as int) = @year 
			AND (s.TermStartDate < (select top 1 TermEndDate from Semester where Title = @semester AND ClientId = 1) OR (s.Id IS NULL))
		)
	)
END


declare @nest1 table (CourseId int, Outcome varchar(max), Parent_Id int);
declare @nest2 table (CourseId int, Outcome varchar(max), Parent_Id int);
declare @nest3 table (CourseId int, Outcome varchar(max), Parent_Id int);
declare @nest4 table (CourseId int, Outcome varchar(max), Parent_Id int);
declare @nest5 table (CourseId int, Outcome varchar(max), Parent_Id int);
declare @nest6 table (CourseId int, Outcome varchar(max), Parent_Id int);


declare @Goals table (CourseId int, CourseOutcomeId int, CourseGoal varchar(max),GoalNumber int);
declare @temp table (CourseId int, Outcomes varchar(max), Goals varchar(max));

insert into @Goals (CourseId, CourseOutcomeId, CourseGoal, GoalNumber)
select c.CourseId as CourseId, co.Id as CourseOutcomeId, co.Text as CourseGoal, row_number() OVER(partition by c.CourseId order by co.SortOrder) as GoalNumber  --20
from courseobjective co
join @courseIds c on co.CourseId = c.CourseId

insert into @nest1 (CourseId,Outcome,Parent_Id)
	select co.CourseId, concat('<ol>',dbo.ConcatOrdered_Agg(isnull(SortOrder,0),'<li>' + replace(replace(dbo.fnTrimWhitespace(OutcomeText), char(147),'""'), char(148), '""') + '</li>',1),'</ol>') as Outcome, co.Parent_Id
	from CourseOutcome co 
	join @courseIds c on co.CourseId = c.CourseId 
	group by co.CourseId, co.Parent_Id;

insert into @nest2 (CourseId,Outcome,Parent_Id)
	select co.CourseId, 
	concat('<ol>',dbo.ConcatOrdered_Agg(isnull(SortOrder,0),'<li>' + replace(replace(dbo.fnTrimWhitespace(concat(OutcomeText,n.Outcome)), char(147),'""'), char(148), '""') + '</li>',1),'</ol>') as Outcome,
	co.Parent_Id
	from CourseOutcome co
	join @courseIds c on co.CourseId = c.CourseId
	left join @nest1 n on n.Parent_Id = co.Id
	group by co.CourseId, co.Parent_Id;


insert into @nest3 (CourseId,Outcome,Parent_Id)
	select co.CourseId, 
	concat('<ol>',dbo.ConcatOrdered_Agg(isnull(SortOrder,0),'<li>' + replace(replace(dbo.fnTrimWhitespace(concat(OutcomeText,n.Outcome)), char(147),'""'), char(148), '""') + '</li>',1),'</ol>') as Outcome,
	co.Parent_Id
	from CourseOutcome co
	join @courseIds c on co.CourseId = c.CourseId
	left join @nest2 n on n.Parent_Id = co.Id
	group by co.CourseId, co.Parent_Id;


insert into @nest4 (CourseId,Outcome,Parent_Id)
	select co.CourseId, 
	concat('<ol>',dbo.ConcatOrdered_Agg(isnull(SortOrder,0),'<li>' + replace(replace(dbo.fnTrimWhitespace(concat(OutcomeText,n.Outcome)), char(147),'""'), char(148), '""') + '</li>',1),'</ol>') as Outcome,
	co.Parent_Id
	from CourseOutcome co
	join @courseIds c on co.CourseId = c.CourseId
	left join @nest3 n on n.Parent_Id = co.Id
	group by co.CourseId, co.Parent_Id


insert into @nest5 (CourseId,Outcome,Parent_Id)
	select co.CourseId, 
	concat('<ol>',dbo.ConcatOrdered_Agg(isnull(SortOrder,0),'<li>' + replace(replace(dbo.fnTrimWhitespace(concat(OutcomeText,n.Outcome)), char(147),'""'), char(148), '""') + '</li>',1),'</ol>') as Outcome,
	co.Parent_Id
	from CourseOutcome co
	join @courseIds c on co.CourseId = c.CourseId
	left join @nest4 n on n.Parent_Id = co.Id
	group by co.CourseId, co.Parent_Id


insert into @nest6 (CourseId,Outcome,Parent_Id)
	select co.CourseId, 
	concat('<ol>',dbo.ConcatOrdered_Agg(isnull(SortOrder,0),'<li>' + replace(replace(dbo.fnTrimWhitespace(concat(OutcomeText,n.Outcome)), char(147),'""'), char(148), '""') + '</li>',1),'</ol>') as Outcome,
	co.Parent_Id
	from CourseOutcome co
	join @courseIds c on co.CourseId = c.CourseId
	left join @nest5 n on n.Parent_Id = co.Id
	group by co.CourseId, co.Parent_Id


insert into @temp (CourseId,Outcomes)
select CourseId,Outcome
from @nest6
where Parent_Id is null


merge into @temp t
using (select CourseId, '<ol>' + dbo.ConcatOrdered_Agg(GoalNumber,'<li>' + replace(replace(dbo.fnTrimWhitespace(CourseGoal), char(147),'""'), char(148), '""') + '</li>',1) + '</ol>' as Goal from @Goals group by CourseId) s 
on t.CourseId = s.CourseId
when matched then update set Goals = s.Goal 
when not matched then insert (CourseId,Goals)
values (s.CourseId,s.Goal);


SELECT	[Subject], [Course Number], 
		--[Title], 
		[Term], [Status], 
		--[Credits], [Description], [Prerequisites and/or Corequisites], 
		[Course Goals], 
		[SLOs], 
		[Institutional Outcomes] 
		--[Course Material], [Student Resources], [Grading Criteria], [Participation/Attendance Policy], 
		--[Course Expectations], [Academic Freedom Statement], [Academic Integrity And Conduct Policy],[Plagiarism], [Cheating], [Email Policy], 
		--[Class Cancellation Policy], [Student Accessibility Statement], [Nondiscrimination Statement], [Disclaimer], [Course Calendar]
FROM
(
	SELECT pvt.SubjectCode AS Subject, pvt.CourseNumber AS 'Course Number', pvt.[Course Title] AS Title, /*Term*/cast(@semester as varchar) + ' ' + cast(@year as varchar) as 'Term', /*pvt.Status*/'Active' as Status, CAST(pvt.MinCreditHour AS NVARCHAR(MAX)) + COALESCE(' - ' + CAST(pvt.MaxCreditHour AS NVARCHAR(MAX)), '') AS Credits, replace(replace(pvt.Description, char(147),'""'), char(148), '""') as Description,
		COALESCE(STUFF((SELECT
				'   (' + COALESCE(pcrt.Title + ' - ', '') + COALESCE(pcrt.Description, '') + ') ' + COALESCE(cor.EntityTitle, '') + COALESCE(' Minimum Grade (' + mg.Code + ')', '') + COALESCE(' ' + cr.CommText, '') + ', ' + COALESCE(c.Title, '')
			FROM CourseRequisite cr
				LEFT JOIN Condition c ON cr.ConditionId = c.Id AND cr.CourseId <> 8427
				LEFT JOIN Course cor ON cr.Requisite_CourseId = cor.Id
				INNER JOIN PreCoRequisiteType pcrt ON cr.PreCoReqTypesId = pcrt.Id
				LEFT JOIN MinimumGrade mg ON cr.MinimumGradeId = mg.Id
			WHERE cr.CourseId = pvt.Id
			FOR XML PATH (''), TYPE)
		.value ('(./text())[1]', 'NVARCHAR(MAX)'), 1, 3, ''), 'No Requisites') AS 'Prerequisites and/or Corequisites',
		case when ltrim(pvt.Goals) = '' OR pvt.Goals IS NULL then 'No Goals' else pvt.Goals end as [Course Goals],
		case when ltrim(pvt.Outcomes) = '' OR pvt.Outcomes IS NULL then 'No SLOs' else pvt.Outcomes end as [SLOs],
		COALESCE('<ol>' + STUFF((SELECT DISTINCT
				'
		', '<li>' + clo.Title + '</li>'
			FROM CourseOutcome co
				INNER JOIN CourseOutcomeClientLearningOutcome coclo ON co.Id = coclo.CourseOutcomeId
				INNER JOIN ClientLearningOutcome clo ON coclo.ClientLearningOutcomeId = clo.Id
			WHERE co.CourseId = pvt.Id
			FOR XML PATH (''), TYPE)
		.value ('(./text())[1]', 'NVARCHAR(MAX)') + '</ol>', 1, 3, ''), 'No ILOs') AS 'Institutional Outcomes',
		'Textbook title, author, publisher, date of publication and ISBN number (If a text is not used, please note as none required. Include other resources from the publisher/specifics about text, for example, e-book.) Required and/or optional materials (This could include a computer and access to the internet, books on reserve in the library, a calculator, uniform, lab equipment, etc.)' AS 'Course Material',
		dbo.RegEx_Replace(pvt.[*Student Resources *], '<.+?>', '') AS 'Student Resources',
		dbo.RegEx_Replace(pvt.[Grading Criteria], '<.+?>', '') AS 'Grading Criteria',
		dbo.RegEx_Replace(pvt.[Participation/Attendance Policy], '<.+?>', '') AS 'Participation/Attendance Policy',
		dbo.RegEx_Replace(pvt.[Course Expectations], '<.+?>', '') AS 'Course Expectations',
		dbo.RegEx_Replace(pvt.[*Academic Freedom Statement *], '<.+?>', '') AS 'Academic Freedom Statement',
		dbo.RegEx_Replace(pvt.[Academic Integrity And Conduct Policy], '<.+?>', '') AS 'Academic Integrity And Conduct Policy',
		dbo.RegEx_Replace(pvt.[*Plagiarism *], '<.+?>', '') AS 'Plagiarism',
		dbo.RegEx_Replace(pvt.[*Cheating *], '<.+?>', '') AS 'Cheating',
		dbo.RegEx_Replace(pvt.[*Email Policy *], '<.+?>', '') AS 'Email Policy',
		dbo.RegEx_Replace(pvt.[Class Cancellation Policy], '<.+?>', '') AS 'Class Cancellation Policy',
		dbo.RegEx_Replace(pvt.[Student Accessibility Statement], '<.+?>', '') AS 'Student Accessibility Statement',
		dbo.RegEx_Replace(pvt.[Nondiscrimination Statement], '<.+?>', '') AS 'Nondiscrimination Statement',
		dbo.RegEx_Replace(pvt.Disclaimer, '<.+?>', '') AS 'Disclaimer',
		dbo.RegEx_Replace(pvt.[Course Calendar], '<.+?>', '') AS 'Course Calendar'
	FROM
	(SELECT c.Id, s.SubjectCode, c.CourseNumber, c.Title AS 'Course Title', c.Description, c.ClientId, ii.Title, ii.MaxText, cd.MinCreditHour, cd.MaxCreditHour, t.*, sa.Title as Status,sem.Title + ' ' + cast(cp.StartYear as varchar(20))  as Term
	FROM Course c
		INNER JOIN Subject s ON s.Id = c.SubjectId
		INNER JOIN InstitutionalInformation ii ON ii.ClientId = c.ClientId
		INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
		INNER JOIN CourseDescription cd ON c.Id = cd.CourseId
		INNER JOIN CourseProposal cp ON c.Id = cp.CourseId
		INNER JOIN @courseIds ci ON c.Id = ci.CourseId
		LEFT JOIN Semester sem ON cp.SemesterId = sem.Id
		LEFT JOIN @temp t on c.Id = t.CourseId
		) p
	PIVOT
	(
	MAX (p.MaxText)
	FOR p.Title IN
	([*Student Resources *], [Grading Criteria], [Participation/Attendance Policy], [Course Expectations], [*Academic Freedom Statement *], [Academic Integrity And Conduct Policy], [*Plagiarism *], [*Cheating *], [*Email Policy *], [Class Cancellation Policy], [Student Accessibility Statement], [Nondiscrimination Statement], [Disclaimer], [Course Calendar])
	) AS pvt
) as q
where [Course NUmber] ! = 'XXX'
order by Subject, [Course Number];
"
WHERE Id = 1

SET QUOTED_IDENTIFIER ON

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 381

UPDATE cr
SET MinimumGrade = NULL
FROM CourseRequisite AS cr
INNER JOIN Course AS c on cr.CourseId = c.Id


UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT TId FROM @Templates
)