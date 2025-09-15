USE [palomar];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19876';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report Active Course SLO Unique Identifier to break out identifiers by coursefamily and not just clonesourseId';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
DECLARE @FirstSLO TABLE (SLOid INT, FirstSLOid INT);

;WITH FamilyCourses AS (
    SELECT C.Id AS CourseId, C.BaseCourseId
    FROM Course C
),
RecursiveOutcomes AS (
    -- Anchor: every outcome starts by pointing to itself
    SELECT 
        CO.Id AS SLOid,
        CO.Id AS FirstSLOid,
        C.BaseCourseId
    FROM CourseOutcome CO
    INNER JOIN FamilyCourses C ON CO.CourseId = C.CourseId

    UNION ALL

    -- Recursive: follow PreviousId, but only inside the same BaseCourseId
    SELECT 
        R.SLOid,
        CO.PreviousId AS FirstSLOid,
        C.BaseCourseId
    FROM RecursiveOutcomes R
    INNER JOIN CourseOutcome CO ON R.FirstSLOid = CO.Id
    INNER JOIN FamilyCourses C ON CO.CourseId = C.CourseId
    WHERE CO.PreviousId IS NOT NULL
      AND C.BaseCourseId = R.BaseCourseId
)
INSERT INTO @FirstSLO (SLOid, FirstSLOid)
SELECT R.SLOid, R.FirstSLOid
FROM RecursiveOutcomes R
INNER JOIN CourseOutcome Root ON R.FirstSLOid = Root.Id
WHERE Root.PreviousId IS NULL  -- only keep the root of each chain
  AND R.FirstSLOid IS NOT NULL;

SELECT 
    S.Title AS [Subject Title],
    S.SubjectCode AS [Subject Code],
    C.CourseNumber AS [Course Number],
    C.Title AS [Course Title],
    CASE WHEN CLC.IsSource = 1 THEN ''1''
         WHEN CLC.IsSource = 0 THEN ''2''
         ELSE '''' END AS [CrossListing],
    CO.OptionalText AS [Outcome Name],
    CO.OutcomeText  AS [Outcome],
    FORMAT(P.ImplementDate, ''d'', ''us'') AS [Implementation Date],
    FSLO.FirstSLOid AS [Identifier]
FROM Course C
INNER JOIN Subject S ON C.SubjectId = S.Id
LEFT JOIN CourseOutcome CO
    INNER JOIN @FirstSLO FSLO ON CO.Id = FSLO.SLOid
    ON C.Id = CO.CourseId
LEFT JOIN CrossListingCourse CLC
    ON CLC.CourseId = C.Id AND CLC.Active = 1
	inner join StatusAlias SA on C.StatusAliasId = SA.id
	left join Proposal P on C.ProposalId = P.id
where C.active = 1
	and C.StatusAliasid = 1
order by SA.Title,S.SubjectCode,C.CourseNumber,C.Title,CO.SortOrder
'
WHERE Id = 1008