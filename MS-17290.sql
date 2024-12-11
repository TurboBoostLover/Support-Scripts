USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17290';
DECLARE @Comments nvarchar(Max) = 
	'Update COR report for non-credits';
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
set @clientId = (
	select ClientId
	from Course
	where Id = @entityId
);

select c.Id as [Value]
, concat(
	''<table style="width: 100%;">''
		, ''<colgroup>''
		   , ''<col span="1" style="width: 15%;">''
		   , ''<col span="1" style="width: 35%;">''
		   , ''<col span="1" style="width: 15%;">''
		   , ''<col span="1" style="width: 35%;">''
		, ''</colgroup>''
		, ''<tr>''
			, ''<td style="font-weight: bold; vertical-align: top;">''
				, ''Department:''
			, ''</td>''
			, ''<td colspan="3">''
				, oeDep.Title
			, ''</td>''
		, ''</tr>''
		, ''<tr>''
			, ''<td style="font-weight: bold; vertical-align: top;">''
				, ''Originator:''
			, ''</td>''
			, ''<td>''
				, u.FirstName
				, '' ''
				, u.LastName
			, ''</td>''
			, ''<td style="font-weight: bold;">''
				, ''Effective Date:''
			, ''</td>''
			, ''<td>''
				, convert(varchar, sem.TermStartDate, 101)
			, ''</td>''
		, ''</tr>''
		, ''<tr>''
			, ''<td style="font-weight: bold; vertical-align: top;">''
				, ''State Control #:''
			, ''</td>''
			, ''<td>''
				, c.StateId
			, ''</td>''
			, ''<td style="font-weight: bold;" colspan="2">''
				, ''Approval Dates:''
			, ''</td>''
		, ''</tr>''
		, ''<tr>''
			, ''<td style="font-weight: bold;">''
				, ''TOP Code:''
			, ''</td>''
			, ''<td colspan="2">''
				, left(cb03.Code, 4)
				, ''.''
				, right(cb03.Code, 2)
				, '' - ''
				, cb03.[Description]
				, case
					when cb03.Vocational = 1
						then ''*''
					else ''''
				end
			, ''</td>''
			, ''<td>''
				, ''<span style="font-weight: bold;">State: </span>''
				, case
					when cd3.CourseDateTypeId = 3 --3 = State Approval
						then convert(varchar, cd3.CourseDate, 101)
					else ''''
				end
			, ''</td>''
		, ''</tr>''
		, ''<tr>''
			, ''<td style="font-weight: bold;" colspan="3">''
				, '' ''
			, ''</td>''
			, ''<td>''
				, ''<span style="font-weight: bold;">Board of Trustees: </span>''
				, case
					when cd1.CourseDateTypeId = 1 --1 = Board of Trustees
						then convert(varchar, cd1.CourseDate, 101)
					else ''''
				end
			, ''</td>''
		, ''</tr>''
		, ''<tr>''
			, ''<td style="font-weight: bold;">''
				, ''C-ID:''
			, ''</td>''
			, ''<td colspan="2">''
				, c.PatternNumber
			, ''</td>''
			, ''<td>''
				, ''<span style="font-weight: bold;">Curriculum Committee: </span>''
				, case
					when cd6.CourseDateTypeId = 6 --6 = CC Approval
						then convert(varchar, cd6.CourseDate, 101)
					else ''''
				end
			, ''</td>''
		, ''</tr>''
		, ''<tr>''
		, ''<td style="font-weight: bold;" colspan="4">''
				, ''Meets GE/Transfer requirements (specify):''
			, ''</td>''
		, ''</tr>''
		, ''<tr>''
			, ''<td colspan="4">''
				, c.SpecifyTransReq
			, ''</td>''
		, ''</tr>''
		, ''<tr>''
			, ''<td colspan="4">''
				, ''<hr class="seperator hr-darker" />''
			, ''</td>''
		, ''</tr>''
		, ''<tr>''
			, ''<td style="font-weight: bold;" colspan="3">''
				, c.EntityTitle
			, ''</td>''
			, ''<td style="font-weight: bold;">''
				, case
					when cd.MinCredithour > 0
						then 
							cast(
								cast(
									cd.MinCreditHour
								as decimal(16, 3))
							as nvarchar)
					else ''''
				end
				, 
				CASE
					WHEN cd.Variable = 1
						THEN
							case
								when cd.MaxCredithour > 0
								and cd.MaxCreditHour > cd.MinCreditHour
									then
										concat(
											'' - ''
											, cast(
												cd.MaxCreditHour
											as decimal(16, 3))
										)
								else ''''
							end
				END
				, case
					when ccbc.CB04Id = 3--N - Non Credit
						then 
							case
								when cd.MinCreditHour <= 1
								and (cd.MaxCreditHour <= 1
									or cd.MaxCreditHour is null
								)
									then '' Hour''
								else '' Hours''
							end
					else
						case
							when cd.MinCreditHour <= 1
							and (cd.MaxCreditHour <= 1
								or cd.MaxCreditHour is null
							)
								then '' Unit''
							else '' Units''
						end
				end
			, ''</td>''
		, ''</tr>''
	, ''</table>''
	, ''<br />''
	, ''<table style="width: 100%;">''
		, ''<tr>''
			, ''<td colspan="4">''
				, ''<b>Course Description: </b>''
				, c.[Description]
			, ''</td>''
		, ''</tr>''
	, ''</table>''
	, ''<br />''
	, ''<table style="width: 100%; border: 1px solid black; border-collapse: collapse;">''
		, ''<tr style="border: 1px solid black; border-collapse: collapse;">''
			, ''<td style="font-weight: bold; border: 1px solid black; border-collapse: collapse; padding: 3px;">''
				, ''Type''
			, ''</td>''
			, ''<td style="font-weight: bold; border: 1px solid black; border-collapse: collapse; padding: 3px;">''
				, ''Units''
			, ''</td>''
			, ''<td style="font-weight: bold; border: 1px solid black; border-collapse: collapse; padding: 3px;">''
				, ''In-Class Hours''
			, ''</td>''
			, ''<td style="font-weight: bold; border: 1px solid black; border-collapse: collapse; padding: 3px;">''
				, ''Out-of-Class Hours''
			, ''</td>''
			, ''<td style="font-weight: bold; border: 1px solid black; border-collapse: collapse; padding: 3px;">''
				, ''Total Student Learning Hours''
			, ''</td>''
		, ''</tr>''
		, ''<tr style="border: 1px solid black; border-collapse: collapse;">''
			, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px;">''
				, ''Lecture''
			, ''</td>''
			, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
				--Lecture Hours (Min)
				, case
					when cd.MinLectureHour > 0
						then
							cast(
								cast(
									coalesce(cd.MinLectureHour, 0)
								as decimal(16, 3))
							as nvarchar)
				end
				--Lecture Hours (Max)
				, case
					when cd.MaxLectureHour > 0
					and cd.MaxLectureHour > cd.MinLectureHour
					and cd.Variable = 1
						then
							concat(
								'' - ''
								, cast(
									cast(
										coalesce(cd.MaxLectureHour, 0)
									as decimal(16, 3))
								as nvarchar)
							)
				end
			, ''</td>''
			, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
				--Lecture In-Class Hours (Min)
				, CASE
WHEN ccbc.CB04Id = 3 -- N - Non Credit
THEN
    CASE
        WHEN cd.MinClinicalHour IS NOT NULL
        THEN CAST(CAST(cd.MinClinicalHour AS decimal(16,3)) AS nvarchar)
        ELSE CAST(CAST(cd.MinContactHoursLecture AS decimal(16,3)) AS nvarchar)
    END
ELSE
    CASE
        WHEN cd.MinContactHoursLecture > 0 OR cd.MinLectureHour > 0
        THEN
            CAST(
                CAST(
                    COALESCE(cd.MinContactHoursLecture, (COALESCE(cd.MinLectureHour, 0) * 17.5))
                AS decimal(16, 3))
            AS nvarchar)
    END
END
--Lecture In-Class Hours (Max)
, 
				CASE
					WHEN cd.Variable = 1
						THEN
							CASE
								WHEN ccbc.CB04Id = 3 -- N - Non Credit
								THEN
									CASE
										WHEN cd.MaxClinicalHour IS NOT NULL OR cd.MaxContactHoursLecture IS NOT NULL
										THEN CONCAT('' - '',
													CASE
														WHEN cd.MaxClinicalHour IS NOT NULL
														THEN CAST(CAST(cd.MaxClinicalHour AS decimal(16,3)) AS nvarchar)
														ELSE CAST(CAST(cd.MaxContactHoursLecture AS decimal(16,3)) AS nvarchar)
													END
										)
										ELSE ''''
									END
									else
										case
											when (cd.MaxContactHoursLecture > 0
												and cd.MaxContactHoursLecture > cd.MinContactHoursLecture
											)
											or (cd.MaxLectureHour > 0
												and cd.MaxLectureHour > cd.MinLectureHour
											)
												then
													concat(
														'' - ''
														, cast(
															cast(
																coalesce(cd.MaxContactHoursLecture, (coalesce(cd.MaxLectureHour, 0) * 17.5))
															as decimal(16, 3))
														as nvarchar)
													)
										end
								end
						END
						, ''</td>''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
							--Lecture Out-of-Class Hours (Min)
							, case
								when ccbc.CB04Id = 3--N - Non Credit
								and cd.MinOtherHour >= 0
									then
										cast(
											cast(
												coalesce(cd.MinOtherHour, 0)
											as decimal(16, 3))
										as nvarchar)
								else
									case
										when cd.MinContactHoursClinical > 0
										or cd.MinLectureHour > 0
											then
												cast(
													cast(
														coalesce(cd.MinContactHoursClinical, ((coalesce(cd.MinLectureHour, 0) * 17.5) * 2))
													as decimal(16, 3))
												as nvarchar)
									end
							end
							--Lecture Out-of-Class Hours (Max)
							, 
							CASE
								WHEN cd.Variable = 1
									THEN
										case
											when ccbc.CB04Id = 3--N - Non Credit
											and cd.MaxOtherHour IS NOT NULL
												then 
													concat(
														'' - ''
														, cast(
															cast(
																coalesce(cd.MaxOtherHour, 0)
															as decimal(16, 3))
														as nvarchar)
													)
											else
												case
													when (cd.MaxContactHoursClinical > 0
														and cd.MaxContactHoursClinical > cd.MinContactHoursClinical
													)
													or (cd.MaxLectureHour > 0
														and cd.MaxLectureHour > cd.MinLectureHour
													)
														then
															concat(
																'' - ''
																, cast(
																	cast(
																		coalesce(cd.MaxContactHoursClinical, ((coalesce(cd.MaxLectureHour, 0) * 17.5) * 2))
																	as decimal(16, 3))
																as nvarchar)
															)
												end
										end
							END
						, ''</td>''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
							--Lecture Total Student Learning Hours (Min)
							, case
								when ccbc.CB04Id = 3--N - Non Credit
								and cd.MinContactHoursLecture IS NOT NULL
									then
										cast(
											cast(
												coalesce(CASE
												WHEN cd.MinClinicalHour IS NOT NULL
												THEN 
												cd.MinClinicalHour
												ELSE cd.MinContactHoursLecture
												END, 0)
											as decimal(16, 3)
											)
										as nvarchar)
								else
									case
										when cd.MinContactHoursLab > 0
										or cd.MinLectureHour > 0
											then
												cast(
													cast(
														coalesce(cd.MinContactHoursLab, (((coalesce(cd.MinLectureHour, 0) * 17.5) * 2) + (coalesce(cd.MinLectureHour, 0) * 17.5)))
													as decimal(16, 3))
												as nvarchar)
									end
							end
							--Lecture Total Student Learning Hours (Max)
							, 
							CASE 
								WHEN cd.Variable = 1
									THEN
										CASE
										  WHEN ccbc.CB04Id = 3 --N - Non Credit
										  THEN 
											CASE
											  WHEN cd.MaxClinicalHour IS NOT NULL OR cd.MaxContactHoursLecture IS NOT NULL
											  THEN 
												CONCAT('' - '', 
													   CAST(
														 CASE
														   WHEN cd.MaxClinicalHour IS NOT NULL
														   THEN cd.MaxClinicalHour 
														   ELSE cd.MaxContactHoursLecture 
														 END AS decimal(16,3)
													   )
													  ) 
											  ELSE ''''
													END
																		else
																			case
																				when (cd.MaxContactHoursLab > 0
																					and cd.MaxContactHoursLab > cd.MinContactHoursLab
																				)
																				or (cd.MaxLectureHour > 0
																					and cd.MaxLectureHour > cd.MinLectureHour
																				)
																					then
																						concat(
																							'' - ''
																							, cast(
																								cast(
																									coalesce(cd.MaxContactHoursLab, (((coalesce(cd.MaxLectureHour, 0) * 17.5) * 2) + (coalesce(cd.MaxLectureHour, 0) * 17.5)))
																								as decimal(16, 3))
																							as nvarchar)
																						)
																			end
																	end
								END
						, ''</td>''
					, ''</tr>''
					, ''<tr style="border: 1px solid black; border-collapse: collapse;">''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px;">''
							, ''Lab''
						, ''</td>''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
							--Lab/Studio/Activity Hours (Min)
							, case
								when ccbc.CB04Id = 3--N - Non Credit
									then NULL
								else
									case
										when cd.MinLabHour > 0
											then
												cast(
													cast(
														coalesce(cd.MinLabHour, 0)
													as decimal(16, 3))
												as nvarchar)
									end
							end
							--Lab/Studio/Activity Hours (Max)
							, 
							CASE
								WHEN cd.Variable = 1
									THEN
										case
											when ccbc.CB04Id = 3--N - Non Credit
												then
													NULL
											else
												case
													when cd.MaxLabHour > 0
													and cd.MaxLabHour > cd.MinLabHour
														then
															concat(
																'' - ''
																, cast(
																	cast(
																		coalesce(cd.MaxLabHour, 0)
																	as decimal(16, 3))
																as nvarchar)
															)
												end
										end
								END
						, ''</td>''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
							--Lab In-Class Hours (Min)
							, case
								when ccbc.CB04Id = 3--N - Non Credit
								and cd.MinLabLecHour > 0
									then
										cast(
											cast(
												coalesce(cd.MinLabLecHour, 0)
											as decimal(16, 3))
										as nvarchar)
								else
									case
										when cd.MinContactHoursOther > 0
										or cd.MinLabHour > 0
											then
												cast(
													cast(
														coalesce(cd.MinContactHoursOther, (coalesce(cd.MinLabHour, 0) * 17.5))
													as decimal(16, 3))
												as nvarchar)
									end
							end
							--Lab In-Class Hours (Max)
							, 
							CASE
								WHEN cd.Variable = 1
									THEN
										case
											when ccbc.CB04Id = 3--N - Non Credit
											and cd.MaxLabLecHour > 0
											and cd.MaxLabLecHour > cd.MinLabLecHour
												then
													concat(
														'' - ''
														, cast(
															cast(
																coalesce(cd.MaxLabLecHour, 0)
															as decimal(16, 3))
														as nvarchar)
													)
											else
												case
													when (cd.MaxContactHoursOther > 0
														and cd.MaxContactHoursOther > MinContactHoursOther
													)
													or (cd.MaxLabHour > 0
														and cd.MaxLabHour > cd.MinLabHour
													)
														then
															concat(
																'' - ''
																, cast(
																	cast(
																		coalesce(cd.MaxContactHoursOther, (coalesce(cd.MaxLabHour, 0) * 17.5))
																	as decimal(16, 3))
																as nvarchar)
															)
												end
										end
									END
						, ''</td>''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
							, case
								when cd.MinLabHour > 0
								or cd.MinLabLecHour > 0
									then ''0.000''
							end
						, ''</td>''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
							--Lab Total Student Learning Hours (Min)
							, case
								when ccbc.CB04Id = 3--N - Non Credit
								and cd.MinLabLecHour > 0
									then
										cast(
											cast(
												coalesce(cd.MinLabLecHour, 0)
											as decimal(16, 3))
										as nvarchar)
								else
									case
										when cd.MinContHour > 0
										or cd.MinLabHour > 0
											then
												cast(
													cast(
														coalesce(cd.MinContHour, (coalesce(cd.MinLabHour, 0) * 17.5))
													as decimal(16, 3))
												as nvarchar)
									end
							end
							--Lab Total Student Learning Hours (Max)
							, 
							CASE
								WHEN cd.Variable = 1
									THEN
										case
											when ccbc.CB04Id = 3--N - Non Credit
											and cd.MaxLabLecHour > 0
											and cd.MaxLabLecHour > cd.MinLabLecHour
												then
													concat(
														'' - ''
														, cast(
															cast(
																coalesce(cd.MaxLabLecHour, 0)
															as decimal(16, 3))
														as nvarchar)
													)
											else
												case
													when (cd.MaxContHour > 0
														and cd.MaxContHour > cd.MinContHour
													)
													or (cd.MaxLabHour > 0
														and cd.MaxLabHour > cd.MinLabHour
													)
														then
															concat(
																'' - ''
																, cast(
																	cast(
																			coalesce(cd.MaxContHour, (coalesce(cd.MaxLabHour, 0) * 17.5))
																	as decimal(16, 3))
																as nvarchar)
															)
												end
										end
								END
						, ''</td>''
					, ''</tr>''
					, ''<tr style="border: 1px solid black; border-collapse: collapse;">''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px;">''
							, ''Total''
						, ''</td>''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
							--Total/Unit(s)/Hour(s) (Min)
							, case
								when ccbc.CB04Id = 3--N - Non Credit
									then
										null
								else
									cast(
										cast(
											coalesce(cd.MinCreditHour, 0)
										as decimal(16, 3))
									as nvarchar)
							end
							--Total/Unit(s)/Hour(s) (Max)
							, 
							CASE
								WHEN cd.Variable = 1
									THEN
										case
											when ccbc.CB04Id = 3--N - Non Credit
												then
													null
											else
												case
													when cd.MaxCreditHour > 0
													and cd.MaxCreditHour > cd.MinCreditHour
														then
															concat(
																'' - ''
																, cast(
																	cast(
																		coalesce(cd.MaxCreditHour, 0)
																	as decimal(16, 3))
																as nvarchar)
															)
												end
										end
									END
							--Unit(s)/Hour(s)
							, case
								when ccbc.CB04Id = 3--N - Non Credit
									then
										case
											when cd.MinCreditHour > 0
												then
													case
														when cd.MinCreditHour <= 1
														and (cd.MaxCreditHour <= 1
															or cd.MaxCreditHour is null
														)
															then '' Hour''
														else '' Hours''
													end
										end
								else
									case
										when cd.MinCreditHour <= 1
										and (cd.MaxCreditHour <= 1
											or cd.MaxCreditHour is null
										)
											then '' Unit''
										else '' Units''
									end
							end
						, ''</td>''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
							, '' ''
						, ''</td>''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
							, '' ''
						, ''</td>''
						, ''<td style="border: 1px solid black; border-collapse: collapse; padding: 3px; text-align: center;">''
							--Total Student Learning Hours (Min)
							, case
								when ccbc.CB04Id = 3--N - Non Credit
								and (cd.MinContactHoursLecture > 0
									or cd.MinContHour > 0
								)
									then
										cast(
											cast(
												(coalesce(CASE
												WHEN cd.MinClinicalHour IS NOT NULL
												THEN cd.MinClinicalHour
												ELSE cd.MinContactHoursLecture
												END, 0) + coalesce(cd.MinContHour, 0))
											as decimal(16, 3))
										as nvarchar)
								else
									case
										when cd.MinContactHoursLab > 0
										or cd.MinContHour > 0
											then
												cast(
													cast(
														(coalesce(cd.MinContactHoursLab, 0) + coalesce(cd.MinContHour, 0))
													as decimal(16, 3))
												as nvarchar)
										else
											cast(
												cast(
													(((coalesce(cd.MinLectureHour, 0) * 17.5)	* 2) + (coalesce(cd.MinLectureHour, 0) * 17.5) + (coalesce(cd.MinLabHour, 0) * 17.5))
												as decimal(16, 3))
											as nvarchar)
									end
							end
							--Total Student Learning Hours (Max)
							,
							CASE
								WHEN cd.Variable = 1
									THEN
										case
											when ccbc.CB04Id = 3--N - Non Credit
											and (cd.MaxContactHoursLecture > 0
												or cd.MaxLabLecHour > 0
												or cd.MaxClinicalHour > 0
											)
												then
													concat(
														'' - ''
														, cast(
															cast(
																	(coalesce(CASE
																WHEN cd.MaxClinicalHour IS NULL
																THEN cd.MaxContactHoursLecture
																ELSE MaxClinicalHour
																END, 0) + coalesce(cd.MaxLabLecHour, 0))
															as decimal(16, 3))
														as nvarchar)
													)
											else
												case
													when cd.MaxContactHoursLab > 0
													or cd.MaxContHour > 0
														then
															concat(
																'' - ''
																, cast(
																	cast(
																		(coalesce(cd.MaxContactHoursLab, 0) + coalesce(cd.MaxContHour, 0))
																	as decimal(16, 3))
																as nvarchar)
															)
													else
														case
															when cd.MaxLectureHour > cd.MinLectureHour
															or cd.MaxLabHour > cd.MinLabHour
																then
																	concat(
																		'' - ''
																		, cast(
																			cast(
																				(((coalesce(cd.MaxLectureHour, 0) * 17.5) * 2) + (coalesce(cd.MaxLectureHour, 0) * 17.5) + (coalesce(cd.MaxLabHour, 0) * 17.5))
																			as decimal(16, 3))
																		as nvarchar)
																	)
														end
												end
										end
									END
						, ''</td>''
					, ''</tr>''
				, ''</table>''
				, ''<br />''
				, ''<table style="width: 100%;">''
					, ''<tr>''
						, ''<td>''
							, ''<b>Grading Policy: </b>''
							, go.[Description]
						, ''</td>''
					, ''</tr>''
				, ''</table>''
				, ''<br />''
				, ''<table style="width: 100%;">''
					, ''<tr>''
						, ''<td style="font-weight: bold;">''
							, ''Requisites:''
						, ''</td>''
					, ''</tr>''
				, ''</table>''
			) as [Text]
		from Client cl
			inner join Course c on cl.Id = c.ClientId
			inner join [User] u on c.UserId = u .Id
			inner join [Subject] s on c.SubjectId = s.Id
			inner join OrganizationSubject os on s.Id = os.SubjectId
				and os.Active = 1
			inner join OrganizationLink ol on os.OrganizationEntityId = ol.Child_OrganizationEntityId
				and ol.Active = 1
			inner join OrganizationEntity oeDep on ol.Child_OrganizationEntityId = oeDep.Id
				and oeDep.OrganizationTierId = (
					select Id
					from OrganizationTier
					where ClientId = @clientId
					and Title = ''Department''
				)
			inner join OrganizationEntity oeDiv on ol.Parent_OrganizationEntityId = oeDiv.Id
				and oeDiv.OrganizationTierId = (
					select Id
					from OrganizationTier
					where ClientId = @clientId
					and Title = ''Division''
				)
			left join CourseCBCode ccbc on c.Id = ccbc.CourseId
			left join CB03 cb03 on ccbc.CB03Id = cb03.Id
			left join CourseDescription cd on c.Id = cd.CourseId
			left join GradeOption go on cd.GradeOptionId = go.Id
			outer apply (
				select cd1.CourseDateTypeId
					, cd1.CourseDate
				from CourseDate cd1
					inner join CourseDateType cdt1 on cd1.CourseDateTypeId = cdt1.Id
				where cdt1.Id = 1 --1 = Board of Trustees
				and c.Id = cd1.CourseId
			) cd1
			outer apply (
				select cd3.CourseDateTypeId
					, cd3.CourseDate
				from CourseDate cd3
					inner join CourseDateType cdt3 on cd3.CourseDateTypeId = cdt3.Id
				where cdt3.Id = 3 --3 = State Approval
				and c.Id = cd3.CourseId
			) cd3
			outer apply (
				select cd6.CourseDateTypeId
					, cd6.CourseDate
				from CourseDate cd6
					inner join CourseDateType cdt6 on cd6.CourseDateTypeId = cdt6.Id
				where cdt6.Id = 6 --6 = CC Approval
				and c.Id = cd6.CourseId
			) cd6
			inner join CourseProposal cp on c.Id = cp.CourseId
			left join Semester sem on cp.SemesterId = sem.Id
		where c.Id = @entityId;


'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 4034

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 4034
)