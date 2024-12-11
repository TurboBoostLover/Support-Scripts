USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15708';
DECLARE @Comments nvarchar(Max) = 
	'Add decimals back into report since they requested them out and now they want them back
	CIC Summary Course Admin report
	';
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
UPDATE AdminReport
SET ReportSQL = '
		select c.Id as [Course Id]
			, format(getDate(), ''MM/dd/yyyy'') as [Printed]
			, s.Title as [Subject Title]
			, s.SubjectCode as [Subject Code]
			, concat(
				case
					when c.ProposalTypeId in (
						1--New Credit Course
						, 3--Credit Course Reactivation (Not currently active at any College)
						, 4--Credit Course Deactivation (Not at any College)
						, 10--Credit Course Reactivation (with Integration)
						, 20--Special Topics (Framework)
					)
						then ''* ''
					else null
				end
				, c.CourseNumber
			) as [Course Number]
			, discp.RenderedText [Discipline]
			, c.Title as [Course Title]
			, concat(
				case
					when cyn.YesNo05Id = 1 --yes is override
					and cd.MinContactHoursClinical > 0
						then format(cd.MinContactHoursClinical, ''###.#'')
					else format((cd.ShortTermLabHour * 16), ''###'')
				end
				, case
					when cyn.YesNo05Id = 1 --yes is override
					and cd.MaxContactHoursClinical > 0
					and cd.MaxContactHoursClinical > cd.MinContactHoursClinical
						then concat(
							'' - ''
							, format(cd.MaxContactHoursClinical, ''###.#'')
						)
					when cyn.YesNo14Id = 1 --yes is variable
					and cd.SemesterHour > 0
					and cd.SemesterHour > cd.ShortTermLabHour
						then concat(
							'' - ''
							, format((cd.SemesterHour * 18), ''###'')
						)
					else 
						case 
							when cd.ShortTermLabHour > 0
								then concat(
									'' - ''
									, format((cd.ShortTermLabHour * 18), ''###.#'')
								)
							else null
						end
				end
			) as [Lecture Hours]
			, concat(
				case
					when cyn.YesNo05Id = 1 --yes is override
					and cd.MinContactHoursLecture > 0
						then format(cd.MinContactHoursLecture, ''###.#'')
					else format((cd.MinLabHour * 48), ''###.#'')
				end
				, case
					when cyn.YesNo05Id = 1 --yes is override
					and cd.MaxContactHoursLecture > 0
					and cd.MaxContactHoursLecture > cd.MinContactHoursLecture
						then concat(
							'' - ''
							, format(cd.MaxContactHoursLecture, ''###.#'')
						)
					when cyn.YesNo14Id = 1 --yes is variable
					and cd.MaxLabHour > 0
					and cd.MaxLabHour > cd.MinLabHour
						then concat(
							'' - ''
							, format((cd.MaxLabHour * 54), ''###.#'')
						)
					else 
						case
							when cd.MinLabHour > 0
								then concat(
									'' - ''
									, format((cd.MinLabHour * 54), ''###.#'')
								)
							else null
						end
				end
			) as [Lab Hours]
			, concat(
				case
					when cd.MinOtherHour > 0
						then format(cd.MinOtherHour, ''###.#'')
					else null
				end
				, case
					when cyn.YesNo14Id = 1 --yes is variable
					and cd.MaxOtherHour > 0
					and cd.MaxOtherHour > cd.MinOtherHour
						then concat(
							'' - ''
							, format(cd.MaxOtherHour, ''###.#'')
						)
					else null
				end
			) as [Other Hours]
			, concat(
				case
					when cd.MinCreditHour > 0
						then format(cd.MinCreditHour, ''###.#'')
					else null
				end
				, case
					when cyn.YesNo14Id = 1 --yes is variable
					and cd.MaxCreditHour > 0
					and cd.MaxCreditHour > cd.MinCreditHour
						then concat(
							'' - ''
							, format(cd.MaxCreditHour, ''###.#'')
						)
					else null
				end
			) as [Units]
			, gro.[Description] as [Grade Option]
			, case
				when len(req.[Text]) > 0
					then cast(replace(dbo.RegEx_Replace(req.[Text], ''<[^>]*>'', ''''), ''&emsp;'', '' '') as nvarchar(max))
				else ''NONE''
			end as [Requisites]
			, c.[Description] as [Course Description]
			, case
				when ftr.Title is not null
					then ftr.Title
				else ''NONE''
			end as [Field Trip Requirements]
			, case
				when ccbc.cb04Id is not null
					then concat(
						cb04.Code
						, '' - ''
						, cb04.[Description]
					)
				else null
			end as [CB04]
			, case
				when ccbc.cb05Id is not null
					then concat(
						cb05.Code
						, '' - ''
						, cb05.[Description]
					)
				else null
			end as [CB05]
			, concat(
				case
					when c.Title5 = 1--CSU General Education
						then ''CSU General Education''
					else ''''
				end
				, case
					when c.Title5 = 1--CSU General Education
					and c.GreatBooks = 1--IGETC
						then '', ''
					else ''''
				end
				, case
					when c.GreatBooks = 1--IGETC
						then ''IGETC''
					else ''''
				end
				, case
					when (c.Title5 = 1--CSU General Education
						or c.GreatBooks = 1--IGETC
					)
					and c.HasEnrollmentLimitation = 1--UC Transfer Course
						then '', ''
					else ''''
				end
				, case
					when c.HasEnrollmentLimitation = 1--UC Transfer Course
						then ''UC Transfer Course''
					else ''''
				end
			) as [Transfer Applicability]
			, case
				when pt.ProcessActionTypeId = 1--New
					then ''''
				when pt.ProcessActionTypeId = 2--Modify
					then 
						case
							when offeredCampus.RenderedText is null
								then proposedCampus.RenderedText
							else offeredCampus.RenderedText
						end
				when pt.ProcessActionTypeId = 3--Deactivate
					then proposedCampus.RenderedText
				else ''''
			end as [Offered At]
			, pt.Title as [Action(s) Proposed]
			, proposedCampus.RenderedText as [Proposed for College(s)]
			, origCampus.Title as [Originating Campus]
			, deCampus.RenderedText as [Dist. Ed Proposed For College(s)]
			, sem.Title as [Effective]
			, case
				when pt.ProcessActionTypeId = 1--New 
				and ccfpl.RenderedText like ''%True%''
					then ''Yes''
				else ''No''
			end as [Proposed for: Credit for Prior Learning]
			, g1t.Text100001 as [C-ID]
		from Proposal pr
			inner join Course c on pr.Id = c.ProposalId
			inner join [Subject] s on c.SubjectId = s.Id
			inner join CourseDescription cd on c.Id = cd.CourseId
			left join Generic1000Text g1t on c.Id = g1t.CourseId
			left join GradeOption gro on cd.GradeOptionId = gro.Id
			inner join CourseYesNo cyn on c.Id = cyn.CourseId
			left join MetaForeignKeyCriteriaClient mfkcc on mfkcc.Id = 1
			outer apply dbo.fnBulkResolveCustomSqlQuery(mfkcc.CustomSql, 1, c.Id, c.ClientId, null, null, null) as req
			left join FieldTripRequisite ftr on cd.FieldTripReqsId = ftr.Id
			left join Campus origCampus on c.CampusId = origCampus.Id
			outer apply (
				select dbo.ConcatWithSepOrdered_Agg('' '', discp.SortOrder, discp.RenderedText) as RenderedText
				from (
					select concat(
							mq.Title
							, case
								when mq.MastersRequired = 1
									then '' (Masters Required) ''
								else ''''
							end
							, case
								when cmq.Comments is not null
									then cmq.Comments
								else ''''
							end
							, case
								when cmq.ConditionId is not null
									then concat(
										case
											when cmq.Comments is not null
												then '' ''
											else ''''
										end
										, con.Title
									)
								else ''''
							end
						) as RenderedText
						, row_number() over (order by mq.Title) as SortOrder
						, cmq.ConditionId
					from MinimumQualification mq
						inner join CourseMinimumQualification cmq on mq.Id = cmq.MinimumQualificationId
						left join Condition con on cmq.ConditionId = con.Id
					where c.Id = cmq.CourseId
				) discp
			) discp
			cross apply (
				select dbo.ConcatWithSepOrdered_Agg('', '', offeredCampus.SortOrder, offeredCampus.RenderedText) as RenderedText
				from (
					select cam.Title as RenderedText
						, row_number() over (order by cam.Title) as SortOrder
					from Campus cam
						inner join CourseCampus cc on cam.Id = cc.CampusId
					where c.Id = cc.CourseId
					and cc.CampusId not in (
						select c2.CampusId
						from Course c2
						where c.Id = c2.Id
					)
				) offeredCampus
			) offeredCampus
			cross apply (
				select dbo.ConcatWithSepOrdered_Agg('', '', proposedCampus.SortOrder, proposedCampus.RenderedText) as RenderedText
				from (
					select cam.Title as RenderedText
						, row_number() over (order by cam.Title) as SortOrder
					from Campus cam
						inner join CourseCampus cc on cam.Id = cc.CampusId
					where c.Id = cc.CourseId
				) proposedCampus
			) proposedCampus
			outer apply (
				select dbo.ConcatWithSepOrdered_Agg('', '', deCampus.SortOrder, deCampus.RenderedText) as RenderedText
				from (
					select cam.Title as RenderedText
						, row_number() over (order by cam.Title) as SortOrder
					from Campus cam
						inner join CourseDEAddendum cdea on cam.Id = cdea.CampusId
					where c.Id = cdea.CourseId
				) deCampus
			) deCampus
			inner join ProposalType pt on c.ProposalTypeId = pt.Id
			inner join CourseProposal cp on c.Id = cp.CourseId
			inner join Semester sem on cp.SemesterId = sem.Id
			inner join CourseCBCode ccbc on c.Id = ccbc.CourseId
			left join CB04 cb04 on ccbc.CB04Id = cb04.Id
			left join CB05 cb05 on ccbc.CB05Id = cb05.Id
			outer apply (
				select dbo.Concat_Agg(ccfpl.RenderedText) as RenderedText
				from (
					select 
						case
							when ccfpl.Bit01 = 1
							or ccfpl.Bit02 = 1
							or ccfpl.CampusId is not null
							or ccfpl.IndustryCertificationId is not null
							or ccfpl.MaxText01 is not null
							or ccfpl.MaxText02 is not null
							or ccfpl.MaxText03 is not null
								then ''True''
							else ''False''
						end as RenderedText
					from CourseCreditForPriorLearning ccfpl
					where c.Id = ccfpl.CourseId
				) ccfpl
			) ccfpl
			inner join ProcessLevelActionHistory plah on pr.Id = plah.ProposalId
				and plah.LevelActionResultTypeId = 1--Pending
			inner join Step st on plah.StepLevelId = st.StepLevelId
				and plah.StepLevelId = st.StepLevelId
			inner join Position pos on st.PositionId = pos.Id
				and pos.Title like ''%CIC Chair%''
		where pr.ProposalComplete = 0
		and pr.IsImplemented = 0
		and pr.ImplementDate is null
		and plah.ResultDate is null
		order by s.SubjectCode, dbo.fnCourseNumberToNumeric(c.CourseNumber), c.CourseNumber;
'
WHERE Id = 3