USE [santamonica];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13687';
DECLARE @Comments nvarchar(Max) = 
	'Update to Admin Report SQL';
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

SELECT 
	CASE
		WHEN cpt2.Title IS NOT NULL AND cpt.Title IS NOT NULL THEN CONCAT('(', cpt2.Title, ')', cpt.Title)
		WHEN cpt2.Title IS NOT NULL AND cpt2.Title IN ('PR', 'RE') THEN (concat('(',cpt2.Title,')'))
		WHEN cpt.Title IS NOT NULL AND cpt.Title IN ('PR', 'RE') THEN cpt.Title
		ELSE NULL
	END AS [-Reference- or (Grouping) or PR or RE]
	,  s.SubjectCode AS [Subject Code]
	, c.CourseNumber AS [Course Number]
	, c.Title AS [Course Title]
	, p.Title AS [Program Title]
	, at.Title AS [Award Type]

FROM Program AS p
	INNER JOIN AwardType AS at On at.Id = p.AwardTypeId
	INNER JOIN CourseOption AS co ON co.ProgramId = p.Id
	INNER JOIN ProgramCourse AS pc ON pc.CourseOptionId = co.Id
	LEFT JOIN CourseTypeProgram AS cpt ON cpt.Id = pc.CourseTypeProgramId
	INNER JOIN Course AS c ON c.Id = pc.CourseId
	INNER JOIN Subject AS s ON s.Id = C.SubjectId
	INNER JOIN StatusAlias AS sa ON sa.StatusBaseId = c.StatusAliasId
	LEFT JOIN ProgramCourse AS pc2 ON pc2.Id = pc.Parent_Id
	LEFT JOIN CourseTypeProgram AS cpt2 ON cpt2.Id = pc2.CourseTypeProgramId
WHERE p.Active = 1
AND p.StatusAliasId = 1
AND (
    pc.CourseTypeProgramId IN (1, 3)
    OR pc2.CourseTypeProgramId IN (1, 3)
    OR (pc.Parent_Id IS NOT NULL AND pc2.CourseTypeProgramId IN (1, 3))
    OR (pc.CourseTypeProgramId IS NULL AND pc2.CourseTypeProgramId IS NOT NULL AND pc2.CourseTypeProgramId IN (1, 3))
)
UNION
SELECT
		CONCAT('-', cpt.Title, '-') AS [-Reference- or (Grouping) or PR or RE]
	,  s.SubjectCode AS [Subject Code]
	, c.CourseNumber AS [Course Number]
	, c.Title AS [Course Title]
	, p.Title AS [Program Title]
	, at.Title AS [Award Type]

FROM Program AS p
	INNER JOIN AwardType AS at On at.Id = p.AwardTypeId
	INNER JOIN CourseOption AS co ON co.ProgramId = p.Id
	INNER JOIN ProgramCourse AS pc ON pc.CourseOptionId = co.Id
	INNER JOIN CourseOption AS co2 on pc.LibraryReferenceId = co2.Id AND pc.CourseTypeProgramId in (1,3)		
	INNER JOIN ProgramCourse AS pc2 on co2.Id = pc2.CourseOptionId
	INNER JOIN Course AS c ON c.Id = pc2.CourseId
	INNER JOIN Subject AS s ON s.Id = C.SubjectId
	INNER JOIN StatusAlias AS sa ON sa.StatusBaseId = c.StatusAliasId
	LEFT JOIN CourseTypeProgram AS cpt ON cpt.Id = pc.CourseTypeProgramId
	WHERE p.Active = 1
ORDER BY 'Program Title'
"

SET QUOTED_IDENTIFIER ON

UPDATE AdminReport
SET ReportSQL = @SQL
WHERE Id = 2