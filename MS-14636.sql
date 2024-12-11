use ucdavis;

declare @requisiteResolutionSql nvarchar(max) =
(
	select ResolutionSql
	from MetaForeignKeyCriteriaClient mfkcc
	where mfkcc.Id = 2
);

declare @requisiteResolutionResults table
(
	[Text] nvarchar(max),
	Value int,
	ResultId int identity(1,1)
);

declare @requisiteCatalogView table
(
	CourseId int,
	RequisiteText nvarchar(max)
)
;
declare @entityId int = 12130;

declare courseCursor cursor for
select Id
from Course c
where Active = 1;

open courseCursor;

fetch next from courseCursor into @entityId;

while @@fetch_status = 0
begin
	insert into @requisiteResolutionResults
	exec sys.sp_executesql @stmt = @requisiteResolutionSql, @params = N'@entityId int', @entityId = @entityId;

	insert into @requisiteCatalogView
	select @entityId, [Text] as RequisiteText
	from @requisiteResolutionResults;

	delete from @requisiteResolutionResults;

	fetch next from courseCursor into @entityId;
end;

close courseCursor;
deallocate courseCursor;

--Start of main query
with courseHist (Id, BaseCourseId, CreatedOn, rn, rnk, courseCount)
as
(
SELECT *
FROM (
    SELECT c.Id, c.BaseCourseId, c.CreatedOn,
           ROW_NUMBER() OVER (PARTITION BY BaseCourseId ORDER BY CreatedOn DESC) AS rn,
           RANK() OVER (PARTITION BY BaseCourseId ORDER BY CreatedOn DESC) AS rnk,
           COUNT(*) OVER (PARTITION BY BaseCourseId) AS courseCount
    FROM Course c																																								
    WHERE c.Active = 1
) AS t
WHERE t.rn = 2 OR (t.rnk = 1 AND courseCount = 1)

),
award (title, courseId)
as
(
	select case
				when cp.CourseFeeObjective is not null then cp.CourseFeeObjective
				else al.Name
		   end, c.Id
	from Course c
		inner join CourseProposal cp on c.Id = cp.CourseId
		inner join ProposalType pt on c.ProposalTypeId = pt.Id
		left join AwardLevel al on pt.AwardLevelId = al.Id
),
proccessLevel (plahId, proposalId, rn)
as
(
	select plah.Id, plah.ProposalId, row_number() over(partition by plah.ProposalId order by plah.ResultDate desc)
	from ProcessLevelActionHistory plah
),
actionInformation (proposalId, userName, stepTitle, actionTitle, actionId, actionDate, actionComment)
as
(
	select pl.proposalid, u.FirstName + ' ' + u.LastName, s.Title, coalesce(a.Title, 'Skipped'), a.Id, psah.ResultDate, psah.Comments
	from ProcessStepActionHistory psah
		inner join proccessLevel pl on psah.ProcessLevelActionHistoryId = pl.plahId
		inner join [User] u on psah.UserId = u.Id
		inner join Step s on psah.StepId = s.Id
		left join ActionLevelRoute alr on psah.ActionLevelRouteId = alr.Id
		left join Action a on alr.ActionId = a.Id
	where psah.StepActionResultTypeId = 3
	--where psah.StepActionResultTypeId in (3,5) --Commented out since they do not want to have skipped steps
	--and pl.rn = 1 --Comment this out if all actions should be returned
),
everDeclined (proposalId, declinedCount)
as
(
	select pl.proposalid, count(a.Id) as countNum
	from ProcessStepActionHistory psah
		inner join proccessLevel pl on psah.ProcessLevelActionHistoryId = pl.plahId
		inner join [User] u on psah.UserId = u.Id
		inner join Step s on psah.StepId = s.Id
		left join ActionLevelRoute alr on psah.ActionLevelRouteId = alr.Id
		left join Action a on alr.ActionId = a.Id
	where psah.StepActionResultTypeId in (3,5)
	and a.Id = 6
	group by pl.proposalId
),
currentLevel (plahId, proposalId, SortOrder, positionTitle)
as
(
	select plah.Id, plah.ProposalId, sl.SortOrder, p.Title
	from ProcessLevelActionHistory plah
		inner join StepLevel sl on plah.StepLevelId = sl.Id
		inner join Step s on sl.Id = s.StepLevelId
		inner join Position p on s.PositionId = p.Id
	where plah.ResultDate is null
),
origChange (proposalId)
as
(
	select plah.ProposalId
	from ProcessStepActionHistory psah
		inner join ProcessLevelActionHistory plah on psah.ProcessLevelActionHistoryId = plah.Id
	where psah.StepActionResultTypeId = 1
	and psah.ResultDate is not null
	union
	select plah.ProposalId
	from ProcessStepActionHistory psah
		inner join ProcessLevelActionHistory plah on psah.ProcessLevelActionHistoryId = plah.Id
	where psah.StepActionResultTypeId = 1
	and psah.Source_ProcessStepActionHistoryId is not null
)

select *
from (
select	c.Id as [Entity Id],
		c.BaseCourseId as [Base Entity Id],
		pro.Title as [Workflow Title],
		cl.positionTitle as [Current Workflow Position],
		cl.SortOrder as [Current Workflow Level],
		pt.Title as [Proposal Type/Name],
		s.SubjectCode as [Course Subject],
		c.CourseNumber as [Course Number],
		replace(replace(replace(c.Title, char(13), ' '), char(10), ' ' ), char(9), ' ') as [Entity Title],
		oe2.Title as [College/School],
		oe.Title as Department,
		sem.Title as [Effective Term],
		sem.Code AS [Effective Term Code],
		a.Title as [Academic Level],
		ch.Id as PreviousVersion, 
		sa.Title as WorkflowStatus,
		ai.stepTitle as LastActWkflowStage,
		ai.actionTitle as LastAction,
CONVERT(VARCHAR(10), ai.actionDate, 101) AS LastActDate,
		ai.userName as ActionTakenBy, 
	    replace(replace(replace(ai.actionComment, char(13), ' '), char(10), ' ' ), char(9), ' ') as [Last Action Workflow Comments],
		case
			when ed.declinedCount > 0 then 'Yes'
			else 'No'
		end as [Ever Declined? (yes/no)],
		case
			when ochan.proposalId is not null then 'Yes'
			else 'No'
		end as [Is Pending Changes],
CONVERT(VARCHAR(10),p.LaunchDate, 101) as [Original Launch Date],
		replace(replace(replace(c.EntityTitle, char(13), ' '), char(10), ' ' ), char(9), ' ') as [Full Course Title],
		c.ShortTitle as [Abbreviated Title],
		cd.MinCreditHour as Units,
		cd.MaxCreditHour as [Variable to Units],
		case
			when len(cp.AdviseResults) > 0 then 'Yes'
			else 'No'
		end as [Cross Listing (yes/no)],
		case
			when len(cp.AdviseResults) > 0 then replace(replace(replace(c.Justification, char(13), ' '), char(10), ' '), char(9), ' ')
			else null
		end as [Cross Listing Justification],

		--Start GE section
		--GE 2
		gb.Bit01 as GE2ArtsHumanities, case when gb.Bit01 = 1 then 'Arts & Humanities' end as GE2_ArtHum, 
		gb.Bit02 as GE2ScienceEngineering, case when gb.Bit02 = 1 then 'Science & Engineering' end as GE2_SciEng,
		gb.Bit03 as GE2SocialSciences, case when gb.Bit03 = 1 then 'Social Sciences' end as GE2_SocSci, 
		gb.Bit04 as [Social_Cultural_Diversity], case when gb.Bit04 = 1 then 'Social-Cultural Diversity' end as GE2_Div,
		gb.Bit05 as GE2WritingExperience, case when gb.Bit05 = 1 then 'Writing Experience' end as GE2_Wrt, 
		replace(replace(replace(gmt.TextMax50, char(13), ' '), char(10), ' ' ), char(9), ' ') as GE2_Justification,

		--GE 3
		gb.Bit06 as GE3ArtsHumanities, case when gb.Bit06 = 1 then 'Arts & Humanities' end as GE3_ArtHum,
		gb.Bit07 as GE3ScienceEngineering, case when gb.Bit07 = 1 then 'Science & Engineering' end as GE3_SciEng,
		gb.Bit08 as GE3SocialSciences, case when gb.Bit08 = 1 then 'Social Sciences' end as GE3_SocSci,
		gb.Bit09 as [AmericanCulturesGovernanceandHistoryLiteracy], case when gb.Bit09 = 1 then 'American Cultures, Governance, and History' end as GE3_AmrL,
		replace(replace(replace(gmt.TextMax49, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_AMRL_Q1],
		replace(replace(replace(gmt.TextMax48, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_AMRL_Q2],
		replace(replace(replace(gmt.TextMax08, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_AMRL_Justification],
		gb.Bit10 as [Domestic_Diversity_Literacy], case when gb.Bit10 = 1 then 'Domestic Diversity' end as GE3_DivL,
		replace(replace(replace(gmt.TextMax47, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_DIVL_Q1],
		replace(replace(replace(gmt.TextMax46, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_DIVL_Q2],
		replace(replace(replace(gmt.TextMax45, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_DIVL_Q3],
		replace(replace(replace(gmt.TextMax09, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_DIVL_Justification],
		gb.Bit11 as [Oral_Literacy], case when gb.Bit11 = 1 then 'Oral Skills' end as GE2_OrlL,
		replace(replace(replace(gmt.TextMax44, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_ORLL_Q1],
		replace(replace(replace(gmt.TextMax43, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_ORLL_Q2],
		replace(replace(replace(gmt.TextMax42, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_ORLL_Q3],
		replace(replace(replace(gmt.TextMax10, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_ORLL_Justification],
		gb.Bit12 as [Quantitative_Literacy], case when gb.Bit12 = 1 then 'Quantitative Literacy' end as GE3_QntL,
		replace(replace(replace(gmt.TextMax41, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_QNTL_Q1],
		replace(replace(replace(gmt.TextMax40, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_QNTL_Q2],
		replace(replace(replace(gmt.TextMax39, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_QNTL_Q3],
		replace(replace(replace(gmt.TextMax11, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_QNTL_Justification],
		gb.Bit13 as [Scientific_Literacy], case when gb.Bit13 = 1 then 'Scientific Literacy' end as GE3_SciL,
		replace(replace(replace(gmt.TextMax38, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_SCIL_Q1],
		replace(replace(replace(gmt.TextMax37, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_SCIL_Q2],
		replace(replace(replace(gmt.TextMax36, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_SCIL_Q3],
		replace(replace(replace(gmt.TextMax12, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE3_SCIL_Justification],
		gb.Bit14 as [Visual_Literacy], case when gb.Bit14 = 1 then 'Visual Literacy' end as GE3_VisL,
		replace(replace(replace(gmt.TextMax35, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_VISL_Q1],
		replace(replace(replace(gmt.TextMax34, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_VISL_Q2],
		replace(replace(replace(gmt.TextMax33, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_VSIL_Q3],
		replace(replace(replace(gmt.TextMax13, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_VSIL_Justification],
		gb.Bit15 as [World_Cultures_Literacy], case when gb.Bit15 = 1 then 'World Cultures' end as GE3_WrlL,
		replace(replace(replace(gmt.TextMax32, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_WRLL_Q1],
		replace(replace(replace(gmt.TextMax06, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_WRLL_Q2],
		replace(replace(replace(gmt.TextMax14, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_WRLL_Justification],
		gb.Bit16 as [Writing_Experience], case when gb.Bit16 = 1 then 'Writing Experience' end as GE3_WrtL,
		replace(replace(replace(gmt.TextMax29, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_WRTL_Q1],
		replace(replace(replace(gmt.TextMax28, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_WRTL_Q2],
		replace(replace(replace(gmt.TextMax27, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_WRTL_Q3],
		replace(replace(replace(gmt.TextMax26, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_WRTL_Q4],
		replace(replace(replace(gmt.TextMax15, char(13), ' '), char(10), ' ' ), char(9), ' ') as [GE_WRTL_Justification],
		replace(replace(replace(gmt.TextMax03, char(13), ' '), char(10), ' ' ), char(9), ' ') as [LEGACY_GE_JUSTIFICATION],
		--End GE section

		replace(replace(replace(rcv.RequisiteText, char(13), ' '), char(10), ' ' ), char(9), ' ') as [Prerequisite Catalog View],
		replace(replace(replace(c2t.text200010, char(13), ' '), char(10), ' ' ), char(9), ' ') as [Enrollment Restrictions],
		replace(replace(replace(c.LimitationText, char(13), ' '), char(10), ' ' ), char(9), ' ') as [Credit Limitations],
		replace(replace(replace(gmt.TextMax01, char(13), ' '), char(10), ' ' ), char(9), ' ') as [Registrar Office Remarks],
		row_number() over(order by s.SubjectCode, c.CourseNumber, cl.positionTitle) as rn
from Proposal p
	inner join Course c on p.Id = c.ProposalId
	left join Subject s on c.SubjectId = s.Id
	left join OrganizationSubject os on s.Id = os.SubjectId
	left join OrganizationEntity oe on os.OrganizationEntityId = oe.Id
	left join OrganizationLink ol on oe.Id = ol.Child_OrganizationEntityId
	left join OrganizationEntity oe2 on ol.Parent_OrganizationEntityId = oe2.Id
	left join CourseDescription cd on c.Id = cd.CourseId
	left join ProposalType pt on c.ProposalTypeId = pt.Id
	left join courseHist ch on c.BaseCourseId = ch.BaseCourseId
	inner join StatusAlias sa on c.StatusAliasId = sa.Id
	left join award a on c.Id = a.courseId
	left join GenericBit gb on c.Id = gb.CourseId
	left join GenericMaxText gmt on c.Id = gmt.CourseId
	left join Generic2000Text c2t on c.Id = c2t.CourseId
	left join actionInformation ai on p.Id = ai.proposalId
	left join everDeclined ed on p.Id = ed.proposalId
	left join currentLevel cl on p.Id = cl.proposalId
	left join CourseProposal cp on c.Id = cp.CourseId
	left join Semester sem on cp.SemesterId = sem.Id
	left join ProcessVersion pv on p.ProcessVersionId = pv.Id
	left join Process pro on pv.ProcessId = pro.Id
	left join @requisiteCatalogView rcv on c.Id = rcv.CourseId
	left join origChange ochan on p.Id = ochan.proposalId
where c.Active = 1
--and c.StatusAliasId = 6
and (c.StatusAliasId = 6 or (c.StatusAliasId in (1, 2, 5, 9) and p.ImplementDate >= '2016-07-01'))) t
--Use the where condition below if the number of rows retruned exceed what can be copied and pasted into excel.
--It is just the row numbers you want retruned.
--Example is rows 1 through 5000 would be where t.rn > 0 and t.rn < 5001
--where t.rn > 85000 and t.rn < 90001
order by t.rn;