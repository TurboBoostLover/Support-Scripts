USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16900';
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
use nu 

UPDATE AdminReport
SET ReportName = 'Governance Approval Timestamps'
, ReportSQL = '
;WITH LatestResults AS (
    SELECT
        p.Id,
        psah.ResultDate,
        pos.Title,
        ROW_NUMBER() OVER (PARTITION BY p.Id, pos.Title ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id
    WHERE psah.StepActionResultTypeId = 3

    UNION ALL

    SELECT
        c.Id,
        csah.ResultDate,
        pos.Title,
        ROW_NUMBER() OVER (PARTITION BY c.Id, pos.Title ORDER BY csah.ResultDate DESC) AS rn
    FROM Course AS c
    INNER JOIN Proposal AS pr ON c.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS clah ON clah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS csah ON csah.ProcessLevelActionHistoryId = clah.Id
    INNER JOIN Step ON csah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id
    WHERE csah.StepActionResultTypeId = 3
		and c.Id not in (
			SELECT CourseId FROM PackageCourse AS pc
			INNER JOIN Package AS p on pc.PackageId = p.Id
			WHERE p.StatusAliasId in (628, 633, 632, 629)
		)

    UNION ALL

    SELECT
        prg.Id,
        prsah.ResultDate,
        pos.Title,
        ROW_NUMBER() OVER (PARTITION BY prg.Id, pos.Title ORDER BY prsah.ResultDate DESC) AS rn
    FROM Program AS prg
    INNER JOIN Proposal AS pr ON prg.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS prlah ON prlah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS prsah ON prsah.ProcessLevelActionHistoryId = prlah.Id
    INNER JOIN Step ON prsah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id
    WHERE prsah.StepActionResultTypeId = 3
		and prg.Id not in (
			SELECT ProgramId FROM PackageProgram AS pc
			INNER JOIN Package AS p on pc.PackageId = p.Id
			WHERE p.StatusAliasId in (628, 633, 632, 629)
		)

    UNION ALL

    SELECT
        m.Id,
        msah.ResultDate,
        pos.Title,
        ROW_NUMBER() OVER (PARTITION BY m.Id, pos.Title ORDER BY msah.ResultDate DESC) AS rn
    FROM Module AS m
    INNER JOIN Proposal AS pr ON m.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS mlah ON mlah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS msah ON msah.ProcessLevelActionHistoryId = mlah.Id
    INNER JOIN Step ON msah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id
    WHERE msah.StepActionResultTypeId = 3
)

-- CTEs for each position and entity
, CurriculumArchitect1 AS (
    SELECT Id, ResultDate FROM LatestResults WHERE Title = ''Curriculum Architect'' AND rn = 1
)

, CurriculumArchitect2 AS (
    SELECT Id, ResultDate FROM LatestResults WHERE Title = ''Curriculum Architect'' AND rn = 2
)

, Registrar AS (
    SELECT Id, ResultDate FROM LatestResults WHERE Title = ''Registrar'' AND rn = 1
)

, DepartmentChair AS (
    SELECT Id, ResultDate FROM LatestResults WHERE Title = ''Department Chair'' AND rn = 1
)

, GenEdCommittee AS (
    SELECT Id, ResultDate FROM LatestResults WHERE Title = ''Gen Ed Committee'' AND rn = 1
)

, CurriculumReviewCommittee AS (
    SELECT Id, ResultDate FROM LatestResults WHERE Title = ''Curriculum Review Committee'' AND rn = 1
)

, SchoolDean AS (
    SELECT Id, ResultDate FROM LatestResults WHERE Title = ''School Dean'' AND rn = 1
)

, Provost AS (
    SELECT Id, ResultDate FROM LatestResults WHERE Title = ''Provost'' AND rn = 1
)

, AVPCurriculumDevelopment AS (
    SELECT Id, ResultDate FROM LatestResults WHERE Title = ''AVP Curriculum Development'' AND rn = 1
)

, SOARDevelopmentImplementation AS (
    SELECT Id, ResultDate FROM LatestResults WHERE Title = ''SOAR Development & Implementation'' AND rn = 1
)

-- Final select for Package, Course, Program, and Module
SELECT
    sa.Title AS [Status],
    entity.Title AS [Entity Title],
    pt.Title AS [Proposal Type],
    entity.CreatedDate AS [Created Date],
    pr.LaunchDate AS [Launch Date],
    ca1.ResultDate AS [Curriculum Architect1],
    r.ResultDate AS [Registrar],
    dc.ResultDate AS [Department Chair],
    ge.ResultDate AS [Gen Ed Committee],
    crc.ResultDate AS [Curriculum Review Committee],
    sd.ResultDate AS [School Dean],
    pro.ResultDate AS [Provost],
    avp.ResultDate AS [AVP Curriculum Development],
    ca2.ResultDate AS [Curriculum Architect2],
    soar.ResultDate AS [SOAR Development & Implementation],
    pr.ImplementDate AS [Implement Date]
FROM (
    SELECT p.Id, p.Title, p.CreatedDate, p.StatusAliasId, p.ProposalId, p.ProposalTypeId, ''Package'' AS EntityType FROM Package AS p
    UNION ALL
    SELECT c.Id, c.Title, c.CreatedDate, c.StatusAliasId, c.ProposalId, c.ProposalTypeId, ''Course'' AS EntityType FROM Course AS c
    UNION ALL
    SELECT prg.Id, prg.Title, prg.CreatedDate, prg.StatusAliasId, prg.ProposalId, prg.ProposalTypeId, ''Program'' AS EntityType FROM Program AS prg
    UNION ALL
    SELECT m.Id, m.Title, m.CreatedDate, m.StatusAliasId, m.ProposalId, m.ProposalTypeId, ''Module'' AS EntityType FROM Module AS m
) AS entity
INNER JOIN StatusAlias AS sa ON entity.StatusAliasId = sa.Id
INNER JOIN Proposal AS pr ON entity.ProposalId = pr.Id
INNER JOIN ProposalType AS pt ON entity.ProposalTypeId = pt.Id
LEFT JOIN CurriculumArchitect1 AS ca1 ON ca1.Id = entity.Id
LEFT JOIN CurriculumArchitect2 AS ca2 ON ca2.Id = entity.Id
LEFT JOIN Registrar AS r ON r.Id = entity.Id
LEFT JOIN DepartmentChair AS dc ON dc.Id = entity.Id
LEFT JOIN GenEdCommittee AS ge ON ge.Id = entity.Id
LEFT JOIN CurriculumReviewCommittee AS crc ON crc.Id = entity.Id
LEFT JOIN SchoolDean AS sd ON sd.Id = entity.Id
LEFT JOIN Provost AS pro ON pro.Id = entity.Id
LEFT JOIN AVPCurriculumDevelopment AS avp ON avp.Id = entity.Id
LEFT JOIN SOARDevelopmentImplementation AS soar ON soar.Id = entity.Id
WHERE entity.CreatedDate > @DATE
and entity.StatusAliasId in (628, 633, 632, 629)
ORDER BY entity.Title;
'
WHERE Id = 11