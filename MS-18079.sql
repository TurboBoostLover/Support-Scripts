USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18079';
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
SELECT
	prp.LaunchDate AS [Launch Date],
	sa.Title AS [Proposal Status], 
	div.Code AS [School Code],
	CONCAT(u.FirstName, '' '', u.LastName) AS [Originator],	
	et.Title AS [Entity Type],
	pt.Title AS [Proposal Type],
	COALESCE(c.EntityTitle, p.EntityTitle, pk.EntityTitle, m.Title) AS [Proposal Title],
	ISNULL(rps.Title, ''Complete'') AS [Review Process Step],
	CASE
		WHEN sb.Id = 2 THEN ''N/A''
		ELSE CONCAT (''Level '', rps.Level) 
	END AS [Step Level],
	CASE 
		WHEN rps.ResultDate IS NOT NULL 
		THEN ''Yes'' ELSE ''No''
	END AS [Pending Changes?], 
	rps.ResultDate AS [Hold for Change Date], 
	CASE WHEN gt.Text100001 IS NOT NULL THEN gt.Text100001
		WHEN m.Notes IS NOT NULL THEN m.Notes
		WHEN mcrn.LongText01 IS NOT NULL THEN mcrn.LongText01
		ELSE NULL
		END AS [Catalog Publication Sequence], 
	CASE 
		WHEN et.Id = 1 THEN es.Title 
		WHEN et.Id = 2 THEN an.Text 
		ELSE '''' 
	END AS [Modality],
	case 
		when C.id is not null then CONCAT(''https://nu.curriqunet.com/Form/Course/Index/'', C.Id)
		when P.id is not null then CONCAT(''https://nu.curriqunet.com/Form/Program/Index/'', p.Id)
		when PK.id is not null then CONCAT(''https://nu.curriqunet.com/Form/Package/Index/'', PK.Id)
		when M.id is not null then CONCAT(''https://nu.curriqunet.com/Form/Module/Index/'', M.Id)
	end AS [CNET Link],
	case
		when pk.Description IS NOT NULL THEN dbo.Format_RemoveAccents(dbo.stripHtml(pk.Description))
		when pn.ProgramNeedText IS NOT NULL THEN dbo.Format_RemoveAccents(dbo.stripHtml(pn.ProgramNeedText))
		when c.Rationale IS NOT NULL THEN dbo.Format_RemoveAccents(dbo.stripHtml(c.Rationale))
		when mcrn.LongText02 IS NOT NULL THEN dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.LongText02))
		when me01.TextMax04 IS NOT NULL THEN dbo.Format_RemoveAccents(dbo.stripHtml(me01.TextMax04))
		ELSE NULL
	END AS [Rationale]
FROM Proposal prp 
	INNER JOIN [User] u ON prp.UserId = u.Id
	LEFT JOIN Course c
		LEFT JOIN CourseEntrySkill ces ON ces.CourseId = c.Id
		LEFT JOIN EntrySkill es ON ces.EntrySkillId = es.Id
	ON c.ProposalId = prp.Id
	LEFT JOIN Program p 
		LEFT JOIN ProgramNeed AS pn on pn.ProgramId = p.Id
		LEFT JOIN ProgramAwardNote pan ON pan.ProgramId = p.Id
		LEFT JOIN AwardNote an ON pan.AwardNoteId = an.Id
	ON p.ProposalId = prp.Id
	LEFT JOIN Package pk ON pk.ProposalId = prp.Id
	LEFT JOIN Module m 
		LEFT JOIN ModuleExtension01 AS me01 on m.Id = me01.ModuleId
		INNER JOIN ModuleDetail md ON md.ModuleId = m.Id
			LEFT JOIN ModuleCRN AS mcrn on mcrn.ModuleId = m.Id
	ON m.ProposalId = prp.Id
	INNER JOIN ProposalType pt 
		ON COALESCE
			(
			c.ProposalTypeId, p.ProposalTypeId, 
			pk.ProposalTypeId, m.ProposalTypeId
			) = pt.Id 
	INNER JOIN EntityType et ON pt.EntityTypeId = et.Id
	INNER JOIN StatusAlias sa 
		ON COALESCE
			(
			c.StatusAliasId, p.StatusAliasId, 
			pk.StatusAliasId, m.StatusAliasId
			) = sa.Id
	LEFT JOIN Subject s 
		INNER JOIN OrganizationSubject os 
			ON os.SubjectId = s.Id 
			AND os.Active = 1		
	ON COALESCE(c.SubjectId, pk.SubjectId) = s.Id
	LEFT JOIN OrganizationLink ol 
		ON COALESCE 
			(
			os.OrganizationEntityId, 
			p.Tier2_OrganizationEntityId, 
			md.Tier2_OrganizationEntityId 
			) = ol.Child_OrganizationEntityId 
		AND ol.Active = 1	
	LEFT JOIN OrganizationEntity div 
		ON ol.Parent_OrganizationEntityId = div.Id
	LEFT JOIN OrganizationEntity dpt
		ON COALESCE
			(
			ol.Child_OrganizationEntityId,	-- Department for Course or Package
			p.Tier2_OrganizationEntityId,	-- Department for Program
			md.Tier2_OrganizationEntityId	-- Department for Module
			) = dpt.Id 
		AND dpt.Active = 1
	INNER JOIN StatusBase sb ON sa.StatusBaseId = sb.Id 
	OUTER APPLY 
		(
		SELECT Title, MAX(ResultDate) AS ResultDate, Level
		FROM 
			(
			SELECT 
				COALESCE(pg.Title, st.Title) AS [Title], 
				psah.ResultDate, 
				slv.SortOrder AS [Level]
			FROM ProcessStepActionHistory psah
				INNER JOIN ProcessLevelActionHistory plah ON psah.ProcessLevelActionHistoryId = plah.Id
				INNER JOIN StepLevel slv ON plah.StepLevelId = slv.Id
				INNER JOIN Step st ON st.Id = psah.StepId 
				LEFT JOIN PositionGroupMember pgm ON st.PositionId = pgm.PositionId
				LEFT JOIN PositionGroup pg ON pgm.PositionGroupId = pg.Id
			WHERE psah.ProcessLevelActionHistoryId = plah.Id 
				AND psah.StepActionResultTypeId = 1	-- Pending steps					
				AND st.Title NOT IN (''Originator'', ''Preparation for Implementation'')
				AND plah.ProposalId = prp.Id
			) sq
			-- ^^ If position is part of a PositionGroup, show PositionGroup title. 
			-- ^^ If not, show Step title.
		GROUP BY sq.Title, sq.Level
		) rps
	LEFT JOIN Generic1000Text gt 
		ON COALESCE (gt.CourseId, gt.ProgramId, gt.PackageId) 
		= COALESCE (c.Id, p.Id, pk.Id) 
WHERE sb.Id IN (2, 6)			-- Approved or In Review proposals only 
	AND pt.Id NOT IN (570, 571)	-- Exclude: New PPM Policy, PPM Policy Modification
	AND prp.LaunchDate > ''2020'' -- Excludes proposals with a launch date before 2020, which will by default exclude bad data Approved packages that came over from V2
ORDER BY sa.Title, div.Code, et.Id, pt.Title, [Proposal Title]
'
WHERE Id = 9