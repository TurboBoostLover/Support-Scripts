USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16457';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report IS Curriculum Report';
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
		select 
			case
				when c.Id IS NOT NULL
				THEN c.ID
				WHEN p.ID IS NOT NULL
				THEN p.Id
			END AS [Meta Id],
			case
				when c.Id is not null
					then ''Course''
				when p.Id is not null
					then ''Program''
			end as [Type]
			, case
				when c.Id is not null
					then c.EntityTitle
				when p.Id is not null
					then p.EntityTitle
			end as ProposalTitle
			, case
				when c.Id is not null
					then ptC.Title
				when p.Id is not null
					then ptP.Title
			end as [Proposal Type]
			, case
				when c.Id is not null
				and c.CampusId is not null
					then camC.Title
				when p.Id is not null
				and p.CampusId is not null
					then camP.title
			end as [Originating College]
			, case
				when c.Id is not null
					then semC.Title
				when p.Id is not null
					then semP.Title
			end as [Effective Semester]
		from Proposal pr
			left join Course c on pr.Id = c.ProposalId 
			left join ProposalType ptC on c.ProposalTypeId = ptC.Id
			left join Campus camC on c.CampusId = camC.Id
			left join CourseProposal cp on c.Id = cp.CourseId
			left join Semester semC on cp.SemesterId = semC.Id
			left join Program p on pr.Id = p.ProposalId
			left join ProposalType ptP on p.ProposalTypeId = ptP.Id
			left join Campus camP on p.CampusId = camP.Id
			left join ProgramProposal pp on p.Id = pp.ProgramId
			left join Semester semP on pp.SemesterId = semP.Id
			inner join ProcessLevelActionHistory plah on pr.Id = plah.ProposalId
				and plah.LevelActionResultTypeId = 1--Pending
			inner join Step ste on plah.StepLevelId = ste.StepLevelId
			inner join Position pos on ste.PositionId = pos.Id
				and pos.Title like ''%Instructional Services Analyst%''
		where pr.ProposalComplete = 0
		and pr.IsImplemented = 0
		and pr.ImplementDate is null
		and plah.ResultDate is null
		and (p.StatusAliasId not in (11, 2)
		or p.StatusAliasId IS NULL)
		order by [Type], ProposalTitle;
'
WHERE ID = 2