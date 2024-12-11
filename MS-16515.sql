USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16515';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Outline report';
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
DECLARE @combinedString NVARCHAR(MAX) = '''';

WITH InstructionList AS (
    SELECT
        CONCAT(''<li>'', it.Title, 
               CASE 
                   WHEN cit.Rationale IS NOT NULL THEN CONCAT('' - '', cit.Rationale) 
                   ELSE ''</li>'' 
               END) AS Text
    FROM InstructionType it
    INNER JOIN CourseInstructionType cit ON it.Id = cit.InstructionTypeId
    WHERE cit.CourseId = @EntityId
),
ExitSkillList AS (
    SELECT
        CONCAT(''<li>'', ces.Rationale, ''</li>'') AS Text
    FROM CourseExitSkill ces
    INNER JOIN GenericBit gb ON ces.CourseId = gb.CourseId
    WHERE ces.CourseId = @EntityId AND gb.Bit08 = 1
),
CombinedList AS (
    SELECT Text FROM InstructionList
    UNION ALL
    SELECT Text FROM ExitSkillList
)
SELECT @combinedString = @combinedString + Text
FROM CombinedList;

SELECT 0 AS Value, CASE WHEN @combinedString <> '''' THEN ''<ol>'' + @combinedString + ''</ol>'' ELSE '''' END AS Text;
'

DECLARE @SQL2 NVARCHAR(MAX) = '
DECLARE @combinedString NVARCHAR(MAX) = '''';

WITH EvaluationMethods AS (
    SELECT
        CONCAT(''<li>'', CASE WHEN em.Title LIKE ''Other%'' THEN cem.LargeText01 ELSE em.Title END, ''</li>'', CASE WHEN cem.LargeText01 IS NOT NULL THEN CONCAT(N''<div style="margin-left: 20px;">'', cem.LargeText01, N''</div>'')  ELSE '''' END) AS Text
    FROM CourseEvaluationMethod cem
    INNER JOIN EvaluationMethod em ON cem.EvaluationMethodId = em.Id
    WHERE cem.CourseId = @EntityId
)
SELECT @combinedString = @combinedString + Text
FROM EvaluationMethods;

SELECT 0 AS Value, CASE WHEN @combinedString <> '''' THEN ''<ol type="A">'' + @combinedString + ''</ol>'' ELSE '''' END AS Text;
'

DECLARE @SQL3 NVARCHAR(MAX) = '
				declare @table table (
			CId int,
			Credit int,
			MinLectureHours decimal(16, 3),
			MaxLectureHours decimal(16, 3),
			MinLabHours decimal(16, 3),
			MaxLabHours decimal(16, 3),
			MinClinicalHours decimal(16, 3),
			MaxClinicalHours decimal(16, 3),
			MinInsideofClassHours decimal(16, 3),
			MaxInsideofClassHours decimal(16, 3),
			MinOutsideofClassHours decimal(16, 3),
			MaxOutsideofClassHours decimal(16, 3),
			Variable bit,
			IsLecture bit,
			IsLab bit,
			IsWorkExperience bit
		);

		insert into @table
		select c.Id,
			ccb.CB04Id,
			A.MinLectureHours,
			A.MaxLectureHours,
			A.MinLabHours,
			A.MaxLabHours,
			A.MinClinicalHours,
			A.MaxClinicalHours,
			(coalesce(A.MinLectureHours, 0) + coalesce(A.MinLabHours, 0) + coalesce(A.MinClinicalHours, 0)) as MinInsideofClassHours,
			(coalesce(A.MaxLectureHours, 0) + coalesce(A.MaxLabHours, 0) + coalesce(A.MaxClinicalHours, 0) + coalesce(A.MaxUnpaId, 0) + coalesce(A.MaxPaId, 0)) as MaxInsideofClassHours,
			(coalesce(cd.MinUnitHour, 0) * 36) as MinOutsideofClassHours,
			(coalesce(cd.MaxUnitHour, 0) * 36) as MaxOutsideofClassHours,
			case
				when cyn.YesNo02Id = 1
					then 1
				else 0
			end as Variable,
			cd.IsTBALecture as IsLecture,
			cd.IsTBALab as IsLab,
			c.TList as IsWorkExperience
		from CourseDescription cd
			inner join CourseYesNo CYN on cd.CourseId = CYN.CourseId
			inner join Course C on C.Id = cd.CourseId
			inner join CourseCBCode as ccb on ccb.CourseId = c.Id
			inner join GenericBit gb on cd.CourseId = gb.CourseId
			cross apply (
				select
				(coalesce(cd.MinUnitHour, 0) * 18) as MinLectureHours,
				(coalesce(cd.MaxUnitHour, 0) * 18) as MaxLectureHours,
				(coalesce(cd.MinContactHoursLab, 0) * 54) as MinLabHours,
				(coalesce(cd.MaxContactHoursLab, 0) * 54) as MaxLabHours,
				(coalesce(cd.MinStudyHour, 0) * 54) as MinClinicalHours,
				(coalesce(cd.MaxStudyHour, 0) * 54) as MaxClinicalHours,
				(coalesce(cd.MaxStudyHour, 0) * 60) as MaxUnpaid,
				(coalesce(cd.MaxStudyHour, 0) * 75) as MaxPaid
			) A
		where C.Id = @entityId;

		declare @min decimal(16,2) = (
			select sum(coalesce(cd.MinContHour, 0) + coalesce(cd.MinLabHour, 0) + coalesce(cd.MinWorkHour, 0))
			from CourseDescription as cd
			where CourseId = @entityId
		);

		declare @max decimal(16,2) = (
			select sum(coalesce(cd.MaxContHour, 0) + coalesce(cd.MaxLabHour, 0) + coalesce(cd.MaxWorkHour, 0))
			from CourseDescription as cd
			where CourseId = @entityId
		);

		DECLARE @hours nvarchar(max) = (
		select 	case
				when Credit = 3--N - Non Credit
					then 
					concat(@min
									, case 
										when coalesce(@max, 0) = 0
										or @max <= @min
											then ''''
										else concat('' - '', @max)
									end
					)
				else
				concat(
					 case
							when t.IsLecture = 1
								then 
								concat(format(round(t.MinLectureHours / 0.5, 0) * 0.5, ''####'')
											, case
												when t.Variable = 1 
												and t.MaxLectureHours > t.MinLectureHours
													then concat('' - '', format(round(t.MaxLectureHours / 0.5, 0) * 0.5, ''####''))
												else ''''
											end
								)
							else ''''
						end
						, case
							when t.IsLab = 1
								then
								concat(format(round(t.MinLabHours / 0.5, 0) * 0.5, ''####'')
											, case
												when t.Variable = 1 
												and t.MaxLabHours > t.MinLabHours
													then concat('' - '', format(round(t.MaxLabHours / 0.5, 0) * 0.5, ''####''))
												else ''''
											end
								)
							else ''''
						end
						, case
							when t.IsWorkExperience = 1
								then
								concat(format(round(t.MinClinicalHours / 0.5, 0) * 0.5, ''####'')
											, case
												when t.Variable = 1
												and t.MaxClinicalHours > t.MinClinicalHours
													then concat('' - '', format(round(t.MaxClinicalHours / 0.5, 0) * 0.5, ''####''))
												else ''''
											end
								)
							else ''''
						end
						, case
							when t.MinInsideofClassHours > 0
								then
								concat(format(round(t.MinInsideofClassHours / 0.5, 0) * 0.5, ''####''),
											case
												when t.Variable = 1 
												and t.MaxInsideofClassHours > t.MinInsideofClassHours
													then concat('' - '', format(round(t.MaxInsideofClassHours / 0.5, 0) * 0.5, ''####''))
												else ''''
											end
								)
							else ''''
						end
						, case
							when t.MinOutsideofClassHours > 0
								then
								concat(format(round(t.MinOutsideofClassHours / 0.5, 0) * 0.5, ''####''),
											case
												when t.Variable = 1 
												and t.MaxOutsideofClassHours > t.MinOutsideofClassHours
													then concat('' - '', format(round(t.MaxOutsideofClassHours / 0.5, 0) * 0.5, ''####''))
												else ''''
											end
								)
							else ''''
						end
				)
			end as [Text]
		from @table t)



		select
			concat (
				''<div class="row row-no-gutters">
					<div class="Title col-md-9 text-left">
						<h3>'',
							c.EntityTitle,
						''</h3>'',
					''</div>'',
					''<div class="Title col-md-3 text-right">'',
						case
							when ccbc.CB04Id <> 3--N - Non Credit
								then 
								concat(
									''<h3>'',
										coalesce(format(SUM(COALESCE(cd.MinUnitHour, 0) + COALESCE(cd.MinContactHoursLab, 0) + COALESCE(cd.MinStudyHour, 0)), ''N2''), ''0.00'')
										--coalesce(format(cd.MinCreditHour, ''N2''), ''0.00'')
										, case
											when cd.Variable = 1 or cyn.YesNo02Id = 1
											 then coalesce('' - '' + format(SUM(COALESCE(cd.MaxUnitHour, 0) + COALESCE(cd.MaxContactHoursLab, 0) + COALESCE(cd.MaxStudyHour, 0)), ''N2''), '''')
												--then coalesce('' - '' + format(cd.MaxCreditHour, ''N2''), '''')
											else ''''
										end
										, '' Units''
									, ''</h3>''
								)
							else 
							concat(
								''<h3>'',
									@hours
									,'' Hours''
								, ''</h3>''
							)
						end
					, ''</div>''
				, ''</div>''
			) as [Text],
			0 as [Value]
		from Course c
			inner join CourseDescription cd on c.Id = cd.CourseId
			inner join ProposalType pt on c.ProposalTypeId = pt.Id
			inner join CourseCBCode ccbc on c.Id = ccbc.CourseId
			INNER JOIN CourseYesNo AS cyn on cyn.CourseId = c.Id
		where c.Id = @entityId
		group by c.EntityTitle, ccbc.CB04Id, cd.Variable, cyn.YesNo02Id;'

DECLARE @SQL4 NVARCHAR(MAX) = '
	declare @style nvarchar(max) = ''
			<style>
				.credit-calculator th {
					text-align:left;
					background-color:White;
					border-color: Black;
				}
				.credit-calculator .type {
					text-align:center;
				}
				.credit-calculator tr {
					text-align:left;
					border-color: Black;
				}
				td,th {
					padding:3px;
					text-align:right;
				}
				.empty {
					border-top-style:none;
					border-bottom-style:none;
				}
			</style>
		'';

		declare @table table (
			CId int,
			Credit int,
			MinLectureHours decimal(16, 3),
			MaxLectureHours decimal(16, 3),
			MinLabHours decimal(16, 3),
			MaxLabHours decimal(16, 3),
			MinClinicalHours decimal(16, 3),
			MaxClinicalHours decimal(16, 3),
			MinInsideofClassHours decimal(16, 3),
			MaxInsideofClassHours decimal(16, 3),
			MinOutsideofClassHours decimal(16, 3),
			MaxOutsideofClassHours decimal(16, 3),
			Variable bit,
			IsLecture bit,
			IsLab bit,
			IsWorkExperience bit
		);

		insert into @table
		select c.Id,
			ccb.CB04Id,
			A.MinLectureHours,
			A.MaxLectureHours,
			A.MinLabHours,
			A.MaxLabHours,
			A.MinClinicalHours,
			A.MaxClinicalHours,
			(coalesce(A.MinLectureHours, 0) + coalesce(A.MinLabHours, 0) + coalesce(A.MinClinicalHours, 0)) as MinInsideofClassHours,
			(coalesce(A.MaxLectureHours, 0) + coalesce(A.MaxLabHours, 0) + coalesce(A.MaxClinicalHours, 0) + coalesce(A.MaxUnpaId, 0) + coalesce(A.MaxPaId, 0)) as MaxInsideofClassHours,
			(coalesce(cd.MinUnitHour, 0) * 36) as MinOutsideofClassHours,
			(coalesce(cd.MaxUnitHour, 0) * 36) as MaxOutsideofClassHours,
			case
				when cyn.YesNo02Id = 1
					then 1
				else 0
			end as Variable,
			cd.IsTBALecture as IsLecture,
			cd.IsTBALab as IsLab,
			c.TList as IsWorkExperience
		from CourseDescription cd
			inner join CourseYesNo CYN on cd.CourseId = CYN.CourseId
			inner join Course C on C.Id = cd.CourseId
			inner join CourseCBCode as ccb on ccb.CourseId = c.Id
			inner join GenericBit gb on cd.CourseId = gb.CourseId
			cross apply (
				select
				(coalesce(cd.MinUnitHour, 0) * 18) as MinLectureHours,
				(coalesce(cd.MaxUnitHour, 0) * 18) as MaxLectureHours,
				(coalesce(cd.MinContactHoursLab, 0) * 54) as MinLabHours,
				(coalesce(cd.MaxContactHoursLab, 0) * 54) as MaxLabHours,
				(coalesce(cd.MinStudyHour, 0) * 54) as MinClinicalHours,
				(coalesce(cd.MaxStudyHour, 0) * 54) as MaxClinicalHours,
				(coalesce(cd.MaxStudyHour, 0) * 60) as MaxUnpaid,
				(coalesce(cd.MaxStudyHour, 0) * 75) as MaxPaid
			) A
		where C.Id = @entityId;

		declare @min decimal(16,2) = (
			select sum(coalesce(cd.MinContHour, 0) + coalesce(cd.MinLabHour, 0) + coalesce(cd.MinWorkHour, 0))
			from CourseDescription as cd
			where CourseId = @entityId
		);

		declare @max decimal(16,2) = (
			select sum(coalesce(cd.MaxContHour, 0) + coalesce(cd.MaxLabHour, 0) + coalesce(cd.MaxWorkHour, 0))
			from CourseDescription as cd
			where CourseId = @entityId
		);

		select 0 as [Value],
			case
				when Credit = 3--N - Non Credit
					then 
					concat(
						@style
						, ''<table class="credit-calculator" border="1" style="border-collapse:collapse;" cellspacing="1">''
							, ''<tr>''
								, ''<th>Total Noncredit Hours</th>''
								, ''<td>''
									, @min
									, case 
										when coalesce(@max, 0) = 0
										or @max <= @min
											then ''''
										else concat('' - '', @max)
									end
								, ''</td>''
							, ''</tr>''
						, ''</table>''
					)
				else
				concat(
					@style
					, ''<table class="credit-calculator" border="1" style="border-collapse:collapse;" cellspacing="1">''
						, case
							when t.IsLecture = 1
								then 
								concat(
									''<tr>
										<th>Lecture Hours</th>
										<td>''
											, format(round(t.MinLectureHours / 0.5, 0) * 0.5, ''####'')
											, case
												when t.Variable = 1 
												and t.MaxLectureHours > t.MinLectureHours
													then concat('' - '', format(round(t.MaxLectureHours / 0.5, 0) * 0.5, ''####''))
												else ''''
											end
										, ''</td>
									</tr>''
								)
							else ''''
						end
						, case
							when t.IsLab = 1
								then
								concat(
									''<tr>
										<th>Lab Hours</th>
										<td>''
											, format(round(t.MinLabHours / 0.5, 0) * 0.5, ''####'')
											, case
												when t.Variable = 1 
												and t.MaxLabHours > t.MinLabHours
													then concat('' - '', format(round(t.MaxLabHours / 0.5, 0) * 0.5, ''####''))
												else ''''
											end
										, ''</td>
									</tr>''
								)
							else ''''
						end
						, case
							when t.IsWorkExperience = 1
								then
								concat(
									''<tr>
										<th>Work Experience Hours</th>
										<td>''
											, format(round(t.MinClinicalHours / 0.5, 0) * 0.5, ''####'')
											, case
												when t.Variable = 1
												and t.MaxClinicalHours > t.MinClinicalHours
													then concat('' - '', format(round(t.MaxClinicalHours / 0.5, 0) * 0.5, ''####''))
												else ''''
											end
										, ''</td>''
									, ''</tr>''
								)
							else ''''
						end
						, case
							when t.MinInsideofClassHours > 0
								then
								concat(
									''<tr>
										<th>Inside of Class Hours</th>
										<td>'',
											format(round(t.MinInsideofClassHours / 0.5, 0) * 0.5, ''####''),
											case
												when t.Variable = 1 
												and t.MaxInsideofClassHours > t.MinInsideofClassHours
													then concat('' - '', format(round(t.MaxInsideofClassHours / 0.5, 0) * 0.5, ''####''))
												else ''''
											end,
										''</td>''
									, ''</tr>''
								)
							else ''''
						end
						, case
							when t.MinOutsideofClassHours > 0
								then
								concat(
									''<tr>
										<th>Outside of Class Hours</th>
										<td>'',
											format(round(t.MinOutsideofClassHours / 0.5, 0) * 0.5, ''####''),
											case
												when t.Variable = 1 
												and t.MaxOutsideofClassHours > t.MinOutsideofClassHours
													then concat('' - '', format(round(t.MaxOutsideofClassHours / 0.5, 0) * 0.5, ''####''))
												else ''''
											end,
										''</td>''
									, ''</tr>''
								)
							else ''''
						end
					, ''</table>''
				)
			end as [Text]
		from @table t;
	
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 85  --Methods of Instruction

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 90  --Methods of Evaluating

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL3
, ResolutionSql = @SQL3
WHERE Id = 95  --Units/Hours

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL4
, ResolutionSql = @SQL4
WHERE Id = 84  --Units/Hours

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (84, 85, 90, 95)
)