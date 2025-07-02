USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18830';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text for Noncredit hours';
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
DECLARE @Id int = 84

DECLARE @SQL NVARCHAR(MAX) = '
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
		select c.Id
			,ccb.CB04Id
			,A.MinLectureHours
			,A.MaxLectureHours
			,A.MinLabHours
			,A.MaxLabHours
			,A.MinClinicalHours
			,A.MaxClinicalHours
			,(coalesce(A.MinLectureHours, 0) + coalesce(A.MinLabHours, 0)) as MinInsideofClassHours
			,(coalesce(A.MaxLectureHours, 0) + coalesce(A.MaxLabHours, 0) + coalesce(A.MaxUnpaId, 0) + coalesce(A.MaxPaId, 0)) as MaxInsideofClassHours
			,(coalesce(cd.MinUnitHour, 0) * 36) as MinOutsideofClassHours
			,(coalesce(cd.MaxUnitHour, 0) * 36) as MaxOutsideofClassHours
			,case
				when cyn.YesNo02Id = 1 then 1
				else 0
			end as Variable
			,cd.IsTBALecture as IsLecture
			,case 
				when cd.IsTBALab = 1 or gb.Bit29 = 1 then 1
			END as IsLab
			,c.TList as IsWorkExperience
		from CourseDescription cd
			inner join CourseYesNo CYN on cd.CourseId = CYN.CourseId
			inner join Course c on c.Id = cd.CourseId
			inner join CourseCBCode as ccb on ccb.CourseId = c.Id
			inner join GenericBit gb on cd.CourseId = gb.CourseId
			cross apply (
				select (coalesce(cd.MinUnitHour, 0) * 18) as MinLectureHours
					,(coalesce(cd.MaxUnitHour, 0) * 18) as MaxLectureHours
					,(coalesce(cd.MinContactHoursLab, 0) * 54) +
						Case
							when gb.Bit29 = 1 then 18
							else 0
						END as MinLabHours
					,(coalesce(cd.MaxContactHoursLab, 0) * 54) +
						Case
							when gb.Bit29 = 1 then 18
							else 0
						END as MaxLabHours
					,(coalesce(cd.MinStudyHour, 0) * 54) as MinClinicalHours
					,(coalesce(cd.MaxStudyHour, 0) * 54) as MaxClinicalHours
					,(coalesce(cd.MaxStudyHour, 0) * 60) as MaxUnpaid
					,(coalesce(cd.MaxStudyHour, 0) * 75) as MaxPaid
			) A
		where c.Id = @entityId;

		declare @min int = (
			select coalesce(cd.MinContHour, 0) + coalesce(cd.MinLabHour, 0) + coalesce(cd.MinWorkHour, 0) +
						Case
							when gb.Bit29 = 1 then 18
							else 0
						END 
			from CourseDescription as cd
				inner join GenericBit gb on cd.CourseId = gb.CourseId
			where cd.CourseId = @entityId
		);

		declare @max int = (
			select coalesce(cd.MaxContHour, 0) + coalesce(cd.MaxLabHour, 0) + coalesce(cd.MaxWorkHour, 0) +
						Case
							when gb.Bit29 = 1 then 18
							else 0
						END 
			from CourseDescription as cd
				inner join GenericBit gb on cd.CourseId = gb.CourseId
			where cd.CourseId = @entityId
		);

		DECLARE @noncreditLec NVARCHAR(MAX) = (
			SELECT CASE WHEN cyn.YesNo02Id = 1 and cd.MaxContHour > cd.MinContHour THEN CONCAT(cd.MinContHour, '' - '', cd.MaxContHour)
			ELSE cd.MinContHour
			END
			FROM Course AS c
			INNER JOIN CourseYesNo AS cyn on cyn.CourseId = c.Id
			INNER JOIN CourseDescription AS cd on cd.CourseId = c.Id
			WHERE c.Id = @entityId
		)

			DECLARE @noncreditLab NVARCHAR(MAX) = (
			SELECT CASE WHEN cyn.YesNo02Id = 1 and cd.MaxLabHour > cd.MinLabHour THEN CONCAT(cd.MinLabHour, '' - '', cd.MaxLabHour)
			ELSE cd.MinLabHour
			END
			FROM Course AS c
			INNER JOIN CourseYesNo AS cyn on cyn.CourseId = c.Id
			INNER JOIN CourseDescription AS cd on cd.CourseId = c.Id
			WHERE c.Id = @entityId
		)

			DECLARE @noncreditInsidemin decimal(16,2) = (
				SELECT SUM(COALESCE(cd.MinContHour,0) + COALESCE(cd.MinLabHour,0))
				FROM Course AS c
			INNER JOIN CourseYesNo AS cyn on cyn.CourseId = c.Id
			INNER JOIN CourseDescription AS cd on cd.CourseId = c.Id
			WHERE c.Id = @entityId
		)

			DECLARE @noncreditInsidemax decimal(16,2) = (
				SELECT SUM(COALESCE(cd.MaxContHour,0) + COALESCE(cd.MaxLabHour,0))
				FROM Course AS c
			INNER JOIN CourseYesNo AS cyn on cyn.CourseId = c.Id
			INNER JOIN CourseDescription AS cd on cd.CourseId = c.Id
			WHERE c.Id = @entityId
		)

			DECLARE @noncreditOutsidemin decimal(16,2) = (
			SELECT COALESCE(cd.MinContHour,0) * 2
			FROM Course AS c
			INNER JOIN CourseYesNo AS cyn on cyn.CourseId = c.Id
			INNER JOIN CourseDescription AS cd on cd.CourseId = c.Id
			WHERE c.Id = @entityId
		)

			DECLARE @noncreditOutsidemax decimal(16,2) = (
			SELECT COALESCE(cd.MaxContHour,0) * 2
			FROM Course AS c
			INNER JOIN CourseYesNo AS cyn on cyn.CourseId = c.Id
			INNER JOIN CourseDescription AS cd on cd.CourseId = c.Id
			WHERE c.Id = @entityId
		)

		DECLARE @noncreditTotalMin decimal(16,2) = (
			SUM(COALESCE(@noncreditInsidemin,0) + COALESCE(@noncreditOutsidemin,0))
		)

		DECLARE @noncreditTotalMax decimal(16,2) = (
			SUM(COALESCE(@noncreditInsidemax,0) + COALESCE(@noncreditOutsidemax,0))
		)

		select
			0 as [Value]
		   ,case
				when Credit = 3--N - Non Credit
				then concat(
					@style
					, ''<table class="credit-calculator" border="1" style="border-collapse:collapse;" cellspacing="1">''
					,CASE WHEN @noncreditLec IS NOT NULL THEN  CONCAT(''<tr><th>Total Lecture Hourse</th><td>'', @noncreditLec, ''</td></tr>'') ELSE '''' END
					,CASE WHEN @noncreditLab IS NOT NULL THEN CONCAT(''<tr><th>Total Lab Hourse</th><td>'', @noncreditLab, ''</td></tr>'') ELSE '''' END
					, ''<tr><th>Total Inside of Class Hours</th><td>'', CASE WHEN @noncreditInsidemax > @noncreditInsidemin THEN CONCAT(@noncreditInsideMin, '' - '', @noncreditInsideMax) ELSE @noncreditInsidemin END, ''</td></tr>''
					, ''<tr><th>Total Outside of Class Hours</th><td>'', CASE WHEN @noncreditOutsidemax > @noncreditOutsidemin THEN CONCAT(@noncreditOutsideMin, '' - '', @noncreditOutsideMax) ELSE @noncreditOutsidemin END, ''</td></tr>''
					, ''<tr><th>Total Noncredit Hours</th><td>'', CASE WHEN @noncreditTotalMax > @noncreditTotalMin THEN CONCAT(@noncreditTotalMin, '' - '', @noncreditTotalMax) ELSE @noncreditTotalMin END, ''</td></tr></table>''
					)
				else concat(
					@style
					, ''<table class="credit-calculator" border="1" style="border-collapse:collapse;" cellspacing="1">''
					, case
						when t.IsLecture = 1 then concat(
							''<tr>
												<th>Lecture Hours</th>
												<td>''
							, format(round(t.MinLectureHours / 0.5, 0) * 0.5, ''####'')
							, case
								when t.Variable = 1 and
									t.MaxLectureHours > t.MinLectureHours then concat('' - '', format(round(t.MaxLectureHours / 0.5, 0) * 0.5, ''####''))
								else ''''
							end
							, ''</td>
											</tr>''
							)
						else ''''
					end
					, case
						when t.IsLab = 1 then concat(
							''<tr>
												<th>Lab Hours</th>
												<td>''
							, format(round(t.MinLabHours / 0.5, 0) * 0.5, ''####'')
							, case
								when t.Variable = 1 and
									t.MaxLabHours > t.MinLabHours then concat('' - '', format(round(t.MaxLabHours / 0.5, 0) * 0.5, ''####''))
								else ''''
							end
							, ''</td>
											</tr>''
							)
						else ''''
					end
					, case
						when t.IsWorkExperience = 1 then concat(
							''<tr>
												<th>Work Experience Hours</th>
												<td>''
							, format(round(t.MinClinicalHours / 0.5, 0) * 0.5, ''####'')
							, case
								when t.Variable = 1 and
									t.MaxClinicalHours > t.MinClinicalHours then concat('' - '', format(round(t.MaxClinicalHours / 0.5, 0) * 0.5, ''####''))
								else ''''
							end
							, ''</td>''
							, ''</tr>''
							)
						else ''''
					end
					, case
						when t.MinInsideofClassHours > 0 then concat(
							''<tr>
												<th>Inside of Class Hours</th>
												<td>'',
							format(round(t.MinInsideofClassHours / 0.5, 0) * 0.5, ''####''),
							case
								when t.Variable = 1 and
									t.MaxInsideofClassHours > t.MinInsideofClassHours then concat('' - '', format(round(t.MaxInsideofClassHours / 0.5, 0) * 0.5, ''####''))
								else ''''
							end,
							''</td>''
							, ''</tr>''
							)
						else ''''
					end
					, case
						when t.MinOutsideofClassHours > 0 then concat(
							''<tr>
												<th>Outside of Class Hours</th>
												<td>'',
							format(round(t.MinOutsideofClassHours / 0.5, 0) * 0.5, ''####''),
							case
								when t.Variable = 1 and
									t.MaxOutsideofClassHours > t.MinOutsideofClassHours then concat('' - '', format(round(t.MaxOutsideofClassHours / 0.5, 0) * 0.5, ''####''))
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
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id