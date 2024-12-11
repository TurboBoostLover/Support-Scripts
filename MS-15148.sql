USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15148';
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
	CONVERT(varchar, po.LaunchDate, 10) AS [Launch Date],
	sub.SubjectCode AS [Subject Code],
	CONCAT(u.FirstName, '' '', u.LastName) AS [Originator],
		pt.Title AS [Type of proposal],
		c.Title AS [Title],
		COUNT(prc.CourseId) AS [# of associated proposals],
		step.Title AS [Review Process step],
		gt.Text100001 AS [Catalog Publication Sequence],
		es.Title AS [Modality]
FROM 
	ProposalType AS pt
INNER JOIN Course AS c on c.ProposalTypeId = pt.Id
INNER JOIN Subject AS sub on c.SubjectId = sub.Id
INNER JOIN Proposal AS po on c.ProposalId = po.Id
INNER JOIN [User] AS u on c.UserId = u.Id
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
INNER JOIN ProcessLevelActionHistory AS plah on po.Id = plah.ProposalId AND plah.LevelActionResultTypeId = 1
INNER JOIN StepLevel AS sl on plah.StepLevelId = sl.Id
INNER JOIN Step AS step on step.StepLevelId = sl.Id
LEFT JOIN ProgramCourse AS prc on prc.CourseId = c.Id
LEFT JOIN Generic1000Text AS gt on gt.CourseId = c.Id
LEFT JOIN CourseEntrySkill AS ces on ces.CourseId = c.Id
LEFT JOIN EntrySkill AS es on ces.EntrySkillId = es.Id
WHERE c.Active = 1
AND po.LaunchDate IS NOT NULL
AND sa.Id = 633
AND po.LaunchDate < @date
AND po.LaunchDate > @date2
group by po.LaunchDate, u.FirstName, u.LastName, pt.Title, c.Title, step.Title, sub.SubjectCode, gt.Text100001, es.Title
UNION

SELECT 
	CONVERT(varchar, po.LaunchDate, 10) AS [Launch Date],
	sub.SubjectCode AS [Subject Code],
	CONCAT(u.FirstName, '' '', u.LastName) AS [Originator],
	pt.Title AS [Type of proposal],
	c.Title AS [Title],
	COUNT(prc.CourseId) AS [# of associated proposals],
	''Complete'' AS [Review Process step],
	gt.Text100001 AS [Catalog Publication Sequence],
	es.Title AS [Modality]
FROM 
	ProposalType AS pt
INNER JOIN Course AS c on c.ProposalTypeId = pt.Id
INNER JOIN Subject AS sub on c.SubjectId = sub.Id
INNER JOIN Proposal AS po on c.ProposalId = po.Id
INNER JOIN [User] AS u on c.UserId = u.Id
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
LEFT JOIN ProgramCourse AS prc on prc.CourseId = c.Id
LEFT JOIN Generic1000Text AS gt on gt.CourseId = c.Id
LEFT JOIN CourseEntrySkill AS ces on ces.CourseId = c.Id
LEFT JOIN EntrySkill AS es on ces.EntrySkillId = es.Id
WHERE c.Active = 1
AND po.LaunchDate IS NOT NULL
AND sa.Id in (628, 629)
AND po.LaunchDate < @date
AND po.LaunchDate > @date2
group by po.LaunchDate, u.FirstName, u.LastName, pt.Title, c.Title, sub.SubjectCode, gt.Text100001, es.Title
UNION

SELECT 
	CONVERT(varchar, po.LaunchDate, 10) AS [Launch Date],
	''Program'' AS [Subject Code],
	CONCAT(u.FirstName, '' '', u.LastName) AS [Originator],
		pt.Title AS [Type of proposal],
		p.Title AS [Title],
		COUNT(prc.CourseId) AS [# of associated proposals],
		step.Title AS [Review Process step],
		gt.Text100001 AS [Catalog Publication Sequence],
		an.Text AS [Modality]
FROM 
	ProposalType AS pt
INNER JOIN Program AS p on p.ProposalTypeId = pt.Id
INNER JOIN Proposal AS po on p.ProposalId = po.Id
INNER JOIN [User] AS u on p.UserId = u.Id
INNER JOIN StatusAlias AS sa on p.StatusAliasId = sa.Id
INNER JOIN ProcessLevelActionHistory AS plah on po.Id = plah.ProposalId AND plah.LevelActionResultTypeId = 1
INNER JOIN StepLevel AS sl on plah.StepLevelId = sl.Id
INNER JOIN Step AS step on step.StepLevelId = sl.Id
LEFT JOIN CourseOption As co on co.ProgramId = p.Id
LEFT JOIN ProgramCourse AS prc on prc.CourseOptionId = co.Id
LEFT JOIN Generic1000Text AS gt on gt.ProgramId = p.Id
LEFT JOIN ProgramAwardNote AS pan on pan.ProgramId = p.Id
LEFT JOIN AwardNote AS an on pan.AwardNoteId = an.Id
WHERE p.Active = 1
AND po.LaunchDate IS NOT NULL
AND sa.Id = 633
AND po.LaunchDate < @date
AND po.LaunchDate > @date2
group by po.LaunchDate, u.FirstName, u.LastName, pt.Title, p.Title, step.Title, gt.Text100001, an.Text
UNION

SELECT 
	CONVERT(varchar, po.LaunchDate, 10) AS [Launch Date],
	''Program'' AS [Subject Code],
	CONCAT(u.FirstName, '' '', u.LastName) AS [Originator],
		pt.Title AS [Type of proposal],
		p.Title AS [Title],
		COUNT(prc.CourseId) AS [# of associated proposals],
		''Complete'' AS [Review Process step],
		gt.Text100001 AS [Catalog Publication Sequence],
		an.Text AS [Modality]
FROM 
	ProposalType AS pt
INNER JOIN Program AS p on p.ProposalTypeId = pt.Id
INNER JOIN Proposal AS po on p.ProposalId = po.Id
INNER JOIN [User] AS u on p.UserId = u.Id
INNER JOIN StatusAlias AS sa on p.StatusAliasId = sa.Id
LEFT JOIN CourseOption As co on co.ProgramId = p.Id
LEFT JOIN ProgramCourse AS prc on prc.CourseOptionId = co.Id
LEFT JOIN Generic1000Text AS gt on gt.ProgramId = p.Id
LEFT JOIN ProgramAwardNote AS pan on pan.ProgramId = p.Id
LEFT JOIN AwardNote AS an on pan.AwardNoteId = an.Id
WHERE p.Active = 1
AND po.LaunchDate IS NOT NULL
AND sa.Id in (628, 629)
AND po.LaunchDate < @date
AND po.LaunchDate > @date2
group by po.LaunchDate, u.FirstName, u.LastName, pt.Title, p.Title, gt.Text100001, an.Text
UNION

SELECT 
	CONVERT(varchar, po.LaunchDate, 10) AS [Launch Date],
	''Module'' AS [Subject Code],
	CONCAT(u.FirstName, '' '', u.LastName) AS [Originator],
		pt.Title AS [Type of proposal],
		m.Title AS [Title],
		''0'' AS [# of associated proposals],
		''Complete'' AS [Review Process step],
		m.Notes AS [Catalog Publication Sequence],
		'''' AS [Modality]
FROM 
	ProposalType AS pt
INNER JOIN Module AS m on m.ProposalTypeId = pt.Id
INNER JOIN Proposal AS po on m.ProposalId = po.Id
INNER JOIN [User] AS u on m.UserId = u.Id
INNER JOIN StatusAlias AS sa on m.StatusAliasId = sa.Id
WHERE m.Active = 1
AND po.LaunchDate IS NOT NULL
AND sa.Id in (628, 629)
AND po.LaunchDate < @date
AND po.LaunchDate > @date2
group by po.LaunchDate, u.FirstName, u.LastName, pt.Title, m.Title, m.Notes	
UNION

SELECT 
	CONVERT(varchar, po.LaunchDate, 10) AS [Launch Date],
	''Module'' AS [Subject Code],
	CONCAT(u.FirstName, '' '', u.LastName) AS [Originator],
		pt.Title AS [Type of proposal],
		m.Title AS [Title],
		''0'' AS [# of associated proposals],
		step.Title AS [Review Process step],
		m.Notes AS [Catalog Publication Sequence],
		'''' AS [Modality]
FROM 
	ProposalType AS pt
INNER JOIN Module AS m on m.ProposalTypeId = pt.Id
INNER JOIN Proposal AS po on m.ProposalId = po.Id
INNER JOIN [User] AS u on m.UserId = u.Id
INNER JOIN StatusAlias AS sa on m.StatusAliasId = sa.Id
INNER JOIN ProcessLevelActionHistory AS plah on po.Id = plah.ProposalId AND plah.LevelActionResultTypeId = 1
INNER JOIN StepLevel AS sl on plah.StepLevelId = sl.Id
INNER JOIN Step AS step on step.StepLevelId = sl.Id
WHERE m.Active = 1
AND po.LaunchDate IS NOT NULL
AND sa.Id = 633
AND po.LaunchDate < @date
AND po.LaunchDate > @date2
group by po.LaunchDate, u.FirstName, u.LastName, pt.Title, m.Title, step.Title, m.Notes
UNION

SELECT 
	CONVERT(varchar, po.LaunchDate, 10) AS [Launch Date],
	sub.SubjectCode AS [Subject Code],
	CONCAT(u.FirstName, '' '', u.LastName) AS [Originator],
		pt.Title AS [Type of proposal],
		pack.Title AS [Title],
		COUNT(pgc.CourseId + pgp.ProgramId) AS [# of associated proposals],
		''Complete'' AS [Review Process step],
		'''' AS [Catalog Publication Sequence],
		'''' AS [Modality]
FROM 
	ProposalType AS pt
INNER JOIN Package AS pack on pack.ProposalTypeId = pt.Id
INNER JOIN Subject AS sub on pack.SubjectId = sub.Id
INNER JOIN Proposal AS po on pack.ProposalId = po.Id
INNER JOIN [User] AS u on pack.UserId = u.Id
INNER JOIN StatusAlias AS sa on pack.StatusAliasId = sa.Id
LEFT JOIN PackageCourse AS pgc on pgc.PackageId = pack.Id
LEFT JOIN PackageProgram AS pgp on pgp.PackageId = pack.Id
WHERE pack.Active = 1
AND po.LaunchDate IS NOT NULL
AND sa.Id in (628, 629)
AND po.LaunchDate < @date
AND po.LaunchDate > @date2
group by po.LaunchDate, u.FirstName, u.LastName, pt.Title, pack.Title, sub.SubjectCode
UNION

SELECT 
	CONVERT(varchar, po.LaunchDate, 10) AS [Launch Date],
	sub.SubjectCode AS [Subject Code],
	CONCAT(u.FirstName, '' '', u.LastName) AS [Originator],
		pt.Title AS [Type of proposal],
		pack.Title AS [Title],
		COUNT(pgc.CourseId + pgp.ProgramId) AS [# of associated proposals],
		step.Title AS [Review Process step],
		'''' AS [Catalog Publication Sequence],
		'''' AS [Modality]
FROM 
	ProposalType AS pt
INNER JOIN Package AS pack on pack.ProposalTypeId = pt.Id
INNER JOIN Subject AS sub on pack.SubjectId = sub.Id
INNER JOIN Proposal AS po on pack.ProposalId = po.Id
INNER JOIN [User] AS u on pack.UserId = u.Id
INNER JOIN StatusAlias AS sa on pack.StatusAliasId = sa.Id
INNER JOIN ProcessLevelActionHistory AS plah on po.Id = plah.ProposalId AND plah.LevelActionResultTypeId = 1
INNER JOIN StepLevel AS sl on plah.StepLevelId = sl.Id
INNER JOIN Step AS step on step.StepLevelId = sl.Id
LEFT JOIN PackageCourse AS pgc on pgc.PackageId = pack.Id
LEFT JOIN PackageProgram AS pgp on pgp.PackageId = pack.Id
WHERE pack.Active = 1
AND po.LaunchDate IS NOT NULL
AND sa.Id = 633
AND po.LaunchDate < @date
AND po.LaunchDate > @date2
group by po.LaunchDate, u.FirstName, u.LastName, pt.Title, pack.Title, step.Title, sub.SubjectCode
'
WHERE Id = 7