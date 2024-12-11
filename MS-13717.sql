USE [idoe]

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13717';
DECLARE @Comments nvarchar(Max) = 
	'Add admin report active program review dates';
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
DECLARE @adminReportId INT;

UPDATE Config.ClientSetting
SET AllowActiveProgramReviewDatesReport = 0
WHERE Id = 4

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
DECLARE @ClientId int = 4

set ansi_defaults on;
set implicit_transactions off;
set nocount on;
set quoted_identifier on;
set xact_abort on;

--======================================================================
-- Debug or testing values
------------------------------------------------------------------------
/*

declare
	@clientId int
;

set @clientId = 4; -- Hawkeye (HCC)

declare
	@startTime datetime2 = sysdatetime(),
	@endTime datetime2
;

--*/
--======================================================================

with ActivePrograms as (
	select p.*
	from Program as p
	inner join ProposalType as ppt on ppt.Id = p.ProposalTypeId
	inner join StatusAlias as sa on sa.Id = p.StatusAliasId
	where
		p.ClientId = @clientId
		and p.Active = 1 -- not deleted
		and (
			sa.StatusBaseId != 5 -- Historical (from v2: program_status_id != 2)
			or ppt.ProcessActionTypeId = 3 -- Deactivate (from v2: prop_types_id IN (51,38,39,50,26))
		)
), ProgramIsDeactivated as (
	select
		p.Id as ProgramId,
		cast((case when ppt.ProcessActionTypeId = 3
			then 1
			else 0 
			end) as bit) as IsDeactivated
	from ActivePrograms as p
	inner join ProposalType as ppt on ppt.Id = p.ProposalTypeId
), PrevStartYears as (
	select
		p.Id as Active_ProgramId,
		p.BaseProgramId,
		--/* Enable this block (and disable other) for ALL values
		versioned.ProgramId as Versioned_ProgramId,
		versioned.RankNum,
		versioned.StartYear
		--*/
		/* Enable this block (and disable other) for DISTINCT values
		numbered_distinct_start_years.RankNum,
		numbered_distinct_start_years.StartYear
		--*/
	from ActivePrograms as p
	--/* Enable this block (and disable other) for ALL values
	cross apply (
		select
			prev_p.Id as ProgramId,
			row_number() over (
				partition by prev_p.BaseProgramId
				order by prev_p.Id asc
			) as RankNum,
			prev_pp.StartYear
		from Program as prev_p
		inner join ProgramProposal as prev_pp on prev_pp.ProgramId = prev_p.Id
		where
			prev_p.Active = 1
			and prev_p.BaseProgramId = p.BaseProgramId
			and prev_p.Id <= p.Id
			and prev_pp.StartYear is not null
	) as versioned
	--*/
	/* Enable this block (and disable other) for DISTINCT values
	cross apply (
		select
			row_number() over (
				order by distinct_start_years.StartYear asc
			) as RankNum,
			distinct_start_years.StartYear
		from (
			select prev_pp.StartYear
			from Program as prev_p
			inner join ProgramProposal as prev_pp on prev_pp.ProgramId = prev_p.Id
			where
				prev_p.Active = 1
				and prev_p.BaseProgramId = p.BaseProgramId
				and prev_p.Id <= p.Id
				and prev_pp.StartYear is not null
			group by prev_pp.StartYear
		) as distinct_start_years
	) as numbered_distinct_start_years
	--*/
), CombiningStartYears as (
	select
		pp.Active_ProgramId,
		pp.RankNum,
		cast(pp.StartYear as nvarchar(max)) as CombinedStartYear
	from PrevStartYears as pp
	where pp.RankNum = 1

	union all select
		pp.Active_ProgramId,
		pp.RankNum,
		concat(base.CombinedStartYear, '; ', pp.StartYear) as CombinedStartYear
	from PrevStartYears as pp
	inner join CombiningStartYears as base
		on base.Active_ProgramId = pp.Active_ProgramId
		and base.RankNum + 1 = pp.RankNum
), CombinedStartYears as (
	select
		csy.Active_ProgramId,
		csy.CombinedStartYear
	from CombiningStartYears as csy
	inner join (
		select
			psy.Active_ProgramId,
			max(psy.RankNum) as MaxRankNum
		from PrevStartYears as psy
		group by psy.Active_ProgramId
	) as final_csy
		on final_csy.Active_ProgramId = csy.Active_ProgramId
		and final_csy.MaxRankNum = csy.RankNum
), ProposalSteps as (
	select
		prop.Id as ProposalId,
		psah.ProcessLevelActionHistoryId,
		psah.Id as ProcessStepActionHistoryId,
		psah.StepId,
		s.PositionId
		,psah.ActionLevelRouteId
		,alr.ActionId
		,alr.CompletesProposal
		,psah.ResultDate
		,psah.UserId
	from Proposal as prop
	inner join ProcessLevelActionHistory as plah on plah.ProposalId = prop.Id
	inner join ProcessStepActionHistory as psah on psah.ProcessLevelActionHistoryId = plah.Id
	left join Step as s on s.Id = psah.StepId
	left join ActionLevelRoute as alr on alr.Id = psah.ActionLevelRouteId
	where
		psah.ResultDate is not null
		and s.PositionId is not null
), FirstCurriculumCommitteeProposalSteps as (
	select
		ps.ProposalId,
		min(ps.ResultDate) as FirstResultDate
	from ProposalSteps as ps
	inner join Position as pos on pos.Id = ps.PositionId
	where
		pos.Title like '%Curriculum Committee Chair' collate SQL_Latin1_General_CP1_CI_AS -- force case insensitive
		or pos.Title like '%Curriculum Committee Member (Voting)' collate SQL_Latin1_General_CP1_CI_AS -- force case insensitive
	group by ps.ProposalId
), ProgramFirstCurriculumCommitteeProposalSteps as (
	select
		p.Id as ProgramId,
		coalesce(fccps.FirstResultDate, pack_fccps.FirstResultDate) as FirstResultDate
	from ActivePrograms as p
	left join FirstCurriculumCommitteeProposalSteps as fccps
		on fccps.ProposalId = p.ProposalId
	outer apply (
		select min(fccps_pack.FirstResultDate) as FirstResultDate
		from PackageProgram as ppack
		left join Package as pack on pack.Id = ppack.PackageId
		left join FirstCurriculumCommitteeProposalSteps as fccps_pack
			on fccps_pack.ProposalId = pack.ProposalId
		where ppack.ProgramId = p.Id
	) as pack_fccps
)
select
	--p.Id as ProgramId,
	concat(p.Title, ' (', p.Id, ')') as ""Program Title""
	,csy.CombinedStartYear as ""AS-28 Current & Operational through AY/FYs""
	,convert(nvarchar(max), pfccps.FirstResultDate, 101) as ""Most Recent Revision""
	,(case when pid.IsDeactivated = 1
		then N'NA'
		else cast(pprop.StartYear as nvarchar(max))
		end) as ""New AS-28 Implemented AY/FY""
	,(case when pid.IsDeactivated = 1
		then N'NA'
		else cast(isnull((pprop.StartYear + 5), 2011) as nvarchar(max))
		end) as ""Needs Reviewed prior to AY/FY""
	,(case when pid.IsDeactivated = 1
		then cast(pprop.StartYear as nvarchar(max))
		else cast(null as nvarchar(max))
		end) as ""Program Inactivated at end of AY/FY""
from ActivePrograms as p
left join ProgramProposal as pprop on pprop.ProgramId = p.Id
left join ProgramIsDeactivated as pid on pid.ProgramId = p.Id
left join CombinedStartYears as csy on csy.Active_ProgramId = p.Id
left join ProgramFirstCurriculumCommitteeProposalSteps as pfccps on pfccps.ProgramId = p.Id
order by p.Title, p.Id
;

--======================================================================

--======================================================================
-- Debug performance report
------------------------------------------------------------------------
/*

set @endTime = sysdatetime();

select
	@startTime as ""Start Time""
	,@endTime as ""End Time""
	,(0.000001 * cast(datediff_big(microsecond, @startTime, @endTime) as decimal(38,6))) as ""Seconds""
;

--*/
--======================================================================

--return 0;

"

SET QUOTED_IDENTIFIER ON

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Active Program Review Dates', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 4)