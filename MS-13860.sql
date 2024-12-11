USE [chabot];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13860';
DECLARE @Comments nvarchar(Max) = 
	'Update admin report';
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
SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
select 
--p.Id as ProposalId
--, e.EntityId
pres.*
from Proposal p
	-- an entity must be returned
	cross apply (
		select c.Id as EntityId
		, pt.Title as PropType
		, pt.Active as PropTypeActive
		, pt.ProcessActionTypeId as PropTypePAT
		, pt.EntityTypeId
		, null as AwardType
		, oe.Title as Division
		, c.EntityTitle
		, s.SubjectCode
		, dbo.fnNaturalizeString(dbo.fnTrimWhitespace(c.CourseNumber)) as naturalizedCourseNumber
		, c.Title
		from Course c
			inner join ProposalType pt on c.ProposalTypeId = pt.Id
			-- it needs to have an active hierarchy line to a division
			inner join [Subject] s on c.SubjectId = s.Id
											and s.Active = 1
			inner join OrganizationSubject os on s.Id = os.SubjectId
											and os.Active = 1
			inner join OrganizationLink ol on os.OrganizationEntityId = ol.Child_OrganizationEntityId
											and ol.Active = 1
			inner join OrganizationEntity oe on ol.Parent_OrganizationEntityId = oe.Id
											and oe.Active = 1
		where p.Id = c.ProposalId
		union 
		select pr.Id as EntityId
		, pt.Title as PropType
		, pt.Active as PropTypeActive
		, pt.ProcessActionTypeId as PropTypePAT
		, pt.EntityTypeId
		, awt.Title as AwardType
		, oe.Title as Division
		, pr.EntityTitle
		, null as SubjectCode
		, null as NumericCourseNumber
		, pr.Title as Title
		from Program pr
			inner join ProposalType pt on pr.ProposalTypeId = pt.Id
			left join AwardType awt on pr.AwardTypeId = awt.Id
			-- it needs to haev an active division
			inner join OrganizationEntity oe on pr.Tier1_OrganizationEntityId = oe.Id
								and oe.Active = 1
		where p.Id = pr.ProposalId
	) e
		
	-- outer to still return proposal if there is no results returned
	outer apply (
		select count(*) as NumberOfReviewers
		, dbo.ConcatWithSepOrdered_Agg(
			char(13),
			fn.RowId,
			case
				when len(ltrim(rtrim(fn.Comments))) > 0
					then concat(char(149), ' ', fn.FirstName, ' ', fn.LastName, ': ', fn.Comments)
				end
		) as Comments
		from (
			select row_number() over (order by psah.ResultDate) as RowId
			, u.FirstName
			, u.LastName
			, psah.Comments
			from ProcessLevelActionHistory plah
				inner join ProcessStepActionHistory psah on plah.Id = psah.ProcessLevelActionHistoryId
				inner join Step s on psah.StepId = s.Id
				inner join Position pos on s.PositionId = pos.Id
				-- it has taken an action
				inner join ActionLevelRoute alr on psah.ActionLevelRouteId = alr.Id
				inner join [Action] a on alr.ActionId = a.Id
				inner join [User] u on psah.UserId = u.Id
				outer apply (
					select row_number() over (order by psah.ResultDate) as RowId
				) r
			where p.Id = plah.ProposalId
			-- ""Curriculum Committee Member Voting""
			and pos.Id = 2
		) fn
	) rv

	-- presentation
	outer apply (
		select 
			e.Division as 'Division',
			case e.EntityTypeId when 1 then 'Course' else 'Program' end as 'Course/Program',
			coalesce(e.EntityTitle, '') as 'Title',
			coalesce(e.AwardType, '') as 'Award Type',
			coalesce(
				case
					when e.PropTypePAT = 2 then ''
					else e.PropType
				end
			, '') as 'Status If Other Than Modified',
			rv.NumberOfReviewers as '# Of Reviewers',
			coalesce(rv.Comments, '') as 'Public Comment'
	) pres
where 
1 = 1
-- the proposal is in a level that is pending and the ""Curriculum Committee Member Voting"" position is found
and exists (
	select 1
	from ProcessLevelActionHistory plah
		inner join StepLevel sl on plah.StepLevelId = sl.Id
		inner join Step s on sl.Id = s.StepLevelId
		inner join Position pos on s.PositionId = pos.Id
	where p.Id = plah.ProposalId
	-- ""Pending""
	and plah.LevelActionResultTypeId = 1
	-- ""Curriculum Committee Member Voting""
	and pos.Id = 2 
)
and p.Id not in (
	SELECT p.Id
	From Proposal AS p
	INNER JOIN ProcessLevelActionHistory AS plah on plah.ProposalId = p.Id
	INNER JOIN ProcessStepActionHistory AS psah on psah.ProcessLevelActionHistoryId = plah.Id
	INNER JOIN Step AS s on psah.StepId = s.Id
	INNER JOIN Position AS pos on s.PositionId = pos.Id
	INNER JOIN StepActionResultType AS sart on sart.Id = psah.StepActionResultTypeId
	WHERE pos.Id = 1
	AND Sart.Id = 1
	AND Pos.PositionTypeId = 1
	AND psah.ResultDate IS NULL
)
order by e.Division
, e.EntityTypeId -- course will come first
, e.SubjectCode
, e.naturalizedCourseNumber
, e.Title
"

UPDATE AdminReport
SET ReportSQL = @SQL
WHERE Id = 16