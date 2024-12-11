USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17228';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report';
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
			format(getDate(), ''MM/dd/yyyy'') as [Printed]
			, pc.Title as [Program Area]
			, concat(''('', s.SubjectCode, '') '', s.Title) as [Subject Area]
			, p.Title as [Program Title]
			, p.Id as [Program Id]
			, awt.Title as [Award Type]
			, pt.Title as [Proposal Type]
			, origCampus.Title as [Campus]
			, sem.Title as [Effective]
		from Proposal pr
			inner join Program p on pr.Id = p.ProposalId
			inner join Campus origCampus on p.CampusId = origCampus.Id
			inner join ProgramCode pc on p.ProgramCodeId = pc.Id
			inner join ProgramProposal pp on p.Id = pp.ProgramId
			inner join Semester sem on pp.SemesterId = sem.Id
			LEFT join [Subject] s on p.SubjectId = s.Id
			inner join ProposalType pt on p.ProposalTypeId = pt.Id
			inner join AwardType awt on p.AwardTypeId = awt.Id
			inner join ProcessLevelActionHistory plah on pr.Id = plah.ProposalId
			cross apply (
				select psah.ProcessLevelActionHistoryId, psah.StepId, psah.ResultDate
				from ProcessStepActionHistory psah
				where plah.Id = psah.ProcessLevelActionHistoryId
				and psah.StepActionResultTypeId = 1--Pending
				group by psah.ProcessLevelActionHistoryId, psah.StepId, psah.ResultDate
			) psah
			inner join Step st on psah.StepId = st.Id
				and plah.StepLevelId = st.StepLevelId
			inner join Position pos on st.PositionId = pos.Id
				and pos.Title = ''CIC''
		where pr.ProposalComplete = 0
		and pr.IsImplemented = 0
		and psah.ResultDate is null
		order by pc.Title, p.Title;
		'
WHERE Id = 1