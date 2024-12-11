USE [gavilan];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13884';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report SLO to PLO Mapping Report';
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
UPDATE AdminReport
SET ReportSQL = "
DECLARE @ClientId INT = (SELECT TOP 1 Id FROM Client WHERE Active = 1);

SELECT
	s.SubjectCode AS [Course Subject],
	c.CourseNumber AS [Course Number],
	c.Title AS [Course Title],
	co.OutcomeText AS [Course Outcomes],
	sa.Title AS [Status],
	CONVERT(NVARCHAR(MAX), pr.ImplementDate, 101) AS [Date of Implementation],
	CASE WHEN co.Id = md.Reference_CourseOutcomeId THEN 'Yes' ELSE 'No' END AS [Outcomes Assessed],
	CASE WHEN pom.Id IS NULL THEN 'Not Mapped to Program' ELSE p.EntityTitle END AS [SLO mapped to a program],
	CASE WHEN clo.Id IS NULL THEN 'Not Mapped to ILO' ELSE 
	CASE WHEN clo.Title IS NULL THEN 'Deactivated Mapping' ELSE
	clo.Title 
	END 
	END AS [SLO to ILO Mapping]
FROM
	COURSE AS c
	INNER JOIN CourseOutcome AS co ON co.CourseId = c.Id
	INNER JOIN StatusAlias AS sa ON c.StatusAliasId = sa.Id
	INNER JOIN Subject AS s ON c.SubjectId = s.Id
	INNER JOIN Proposal AS pr ON c.ProposalId = pr.Id
	LEFT JOIN ProgramOutcomeMatching AS pom ON co.Id = pom.CourseOutcomeId
	LEFT JOIN ProgramOutcome AS po ON pom.ProgramOutcomeId = po.Id
	LEFT JOIN Program AS p ON po.ProgramId = p.Id
	LEFT JOIN ModuleDetail AS md ON md.Reference_CourseOutcomeId = co.Id
	LEFT JOIN CourseOutcomeClientLearningOutcome AS coclo ON coclo.CourseOutcomeId = co.Id
	LEFT JOIN ClientLearningOutcome AS clo ON coclo.ClientLearningOutcomeParentId = clo.Id
	WHERE c.Active = 1
	AND c.ClientId = @ClientId
	AND c.StatusAliasId = 655
	AND co.Active = 1
	ORDER BY s.Title, c.Title
"
WHERE Id = 3
SET QUOTED_IDENTIFIER ON