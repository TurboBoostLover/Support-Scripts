USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16387';
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
DECLARE @CurriculumArchitect TABLE (PId int, dat datetime)
INSERT INTO @CurriculumArchitect
SELECT
    Id,
    ResultDate
FROM (
    SELECT
        p.Id,
        psah.ResultDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id AND pos.Title = ''Curriculum Architect''
    WHERE psah.StepActionResultTypeId = 3
) AS subquery
WHERE rn = 1;

DECLARE @CurriculumArchitect2 TABLE (PId int, dat datetime)
INSERT INTO @CurriculumArchitect2
SELECT
    Id,
    ResultDate
FROM (
    SELECT
        p.Id,
        psah.ResultDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id AND pos.Title = ''Curriculum Architect''
    WHERE psah.StepActionResultTypeId = 3
) AS subquery
WHERE rn = 2;

DECLARE @Registrar TABLE (PId int, dat datetime)
INSERT INTO @Registrar
SELECT
    Id,
    ResultDate
FROM (
    SELECT
        p.Id,
        psah.ResultDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id AND pos.Title = ''Registrar''
    WHERE psah.StepActionResultTypeId = 3
) AS subquery
WHERE rn = 1;

DECLARE @DepartmentChair TABLE (PId int, dat datetime)
INSERT INTO @DepartmentChair
SELECT
    Id,
    ResultDate
FROM (
    SELECT
        p.Id,
        psah.ResultDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id AND pos.Title = ''Department Chair''
    WHERE psah.StepActionResultTypeId = 3
) AS subquery
WHERE rn = 1;

DECLARE @ge TABLE (PId int, dat datetime)
INSERT INTO @ge
SELECT
    Id,
    ResultDate
FROM (
    SELECT
        p.Id,
        psah.ResultDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id AND pos.Title = ''Gen Ed Committee''
    WHERE psah.StepActionResultTypeId = 3
) AS subquery
WHERE rn = 1;

DECLARE @crc TABLE (PId int, dat datetime)
INSERT INTO @crc
SELECT
    Id,
    ResultDate
FROM (
    SELECT
        p.Id,
        psah.ResultDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id AND pos.Title = ''Curriculum Review Committee''
    WHERE psah.StepActionResultTypeId = 3
) AS subquery
WHERE rn = 1;

DECLARE @sd TABLE (PId int, dat datetime)
INSERT INTO @sd
SELECT
    Id,
    ResultDate
FROM (
    SELECT
        p.Id,
        psah.ResultDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id AND pos.Title = ''School Dean''
    WHERE psah.StepActionResultTypeId = 3
) AS subquery
WHERE rn = 1;

DECLARE @pro TABLE (PId int, dat datetime)
INSERT INTO @pro
SELECT
    Id,
    ResultDate
FROM (
    SELECT
        p.Id,
        psah.ResultDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id AND pos.Title = ''Provost''
    WHERE psah.StepActionResultTypeId = 3
) AS subquery
WHERE rn = 1;

DECLARE @avp TABLE (PId int, dat datetime)
INSERT INTO @avp
SELECT
    Id,
    ResultDate
FROM (
    SELECT
        p.Id,
        psah.ResultDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id AND pos.Title = ''AVP Curriculum Development''
    WHERE psah.StepActionResultTypeId = 3
) AS subquery
WHERE rn = 1;

DECLARE @soar TABLE (PId int, dat datetime)
INSERT INTO @soar
SELECT
    Id,
    ResultDate
FROM (
    SELECT
        p.Id,
        psah.ResultDate,
        ROW_NUMBER() OVER (PARTITION BY p.Id ORDER BY psah.ResultDate DESC) AS rn
    FROM Package AS p
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN ProcessLevelActionHistory AS plah ON plah.ProposalId = pr.Id
    INNER JOIN ProcessStepActionHistory AS psah ON psah.ProcessLevelActionHistoryId = plah.Id
    INNER JOIN Step ON psah.StepId = Step.Id
    INNER JOIN Position AS pos ON Step.PositionId = pos.Id AND pos.Title = ''SOAR Development & Implementation''
    WHERE psah.StepActionResultTypeId = 3
) AS subquery
WHERE rn = 1;

SELECT
	sa.Title AS [Status],
	p.Title AS [Proposal Title],
	pt.Title AS [Proposal Type],
	p.CreatedDate AS [Created Date],
	pr.LaunchDate AS [Launch Date],
	ca.dat AS [Curriculum Architect1],
	r.dat AS [Registrar],
	dc.dat AS [Department Chair],
	ge.dat AS [Gen Ed Committee],
	crc.dat AS [Curriculum Review Committee],
	sd.dat AS [School Dean],
	pro.dat AS [Provost],	
	avp.dat AS [AVP Curriculum Development],
	ca2.dat AS [Curriculum Architect2],	
	soar.dat AS [SOAR Development & Implementation],
	pr.ImplementDate AS [Implement Date],
	p.Description AS [Package Description]
FROM Package As p
INNER JOIN StatusAlias AS sa on p.StatusAliasId = sa.Id
INNER JOIN Proposal AS pr on p.ProposalId = pr.Id
INNER JOIN ProposalType As pt on p.ProposalTypeId = pt.Id
LEFT JOIN @CurriculumArchitect AS ca on ca.PId = p.Id
LEFT JOIN @CurriculumArchitect2 AS ca2 on ca2.PId = p.Id
LEFT JOIN @Registrar AS r on r.PId = p.Id
LEFT JOIN @DepartmentChair AS dc on dc.PId = p.Id
LEFT JOIN @ge AS ge on ge.PId = p.Id
LEFT JOIN @crc AS crc on crc.PId = p.Id
LEFT JOIN @sd AS sd on sd.PId = p.ID
LEFT JOIN @pro As pro on pro.PId = p.Id
LEFT JOIN @avp As avp on avp.PId = p.Id
LEFT JOIN @soar AS soar on soar.PId = p.Id
WHERE p.CreatedDate > @date
order by p.Title
'
WHERE Id = 11