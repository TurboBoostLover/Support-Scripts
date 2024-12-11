USE [uaeu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18246';
DECLARE @Comments nvarchar(Max) = 
	'Make all the last courses in a course family a eliminate a course proposal type so they can be reactived correctly';
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
DECLARE @Historical int = (SELECT Id fROM StatusAlias WHERE Title = 'Historical')
DECLARE @ProposalType int = (SELECT Id FROM ProposalType WHERE ProcessActionTypeId = 3 and Active = 1 and EntityTypeId = 1)

UPDATE ProposalType
SET AllowReactivation = 1
WHERE ID in (
	SELECT Id FROM ProposalType WHERE ProcessActionTypeId = 3 and EntityTypeId = 1
)

DROP TABLE IF EXISTS #RecentCourses;

CREATE TABLE #RecentCourses (
    CourseId INT,
    BaseCourseId INT,
    CourseName NVARCHAR(255), -- Add other necessary columns
    CreatedOn DATETIME
);

INSERT INTO #RecentCourses (CourseId, BaseCourseId, CourseName, CreatedOn)
SELECT 
    c.Id,
    c.BaseCourseId,
    c.Title,
    c.CreatedOn
FROM 
    Course c
INNER JOIN (
    SELECT 
        BaseCourseId, 
        MAX(CreatedOn) AS LatestCreatedOn
    FROM 
        Course
    WHERE 
        Active = 1
        AND BaseCourseId NOT IN (
            SELECT BaseCourseId
            FROM Course
            WHERE Active = 1 AND StatusAliasId <> @Historical
            GROUP BY BaseCourseId
        )
    GROUP BY 
        BaseCourseId
) latest
ON 
    c.BaseCourseId = latest.BaseCourseId
    AND c.CreatedOn = latest.LatestCreatedOn
WHERE 
    c.Active = 1
    AND c.StatusAliasId = @Historical;


DELETE FROM #RecentCourses
WHERE CourseId in (
	SELECT c.Id FROM Course AS c
	INNER JOIN ProposalType As pt on c.ProposalTypeId = pt.Id and pt.ProcessActionTypeId = 3
)

--SELECT * FROM #RecentCourses;

UPDATE Course
SET ProposalTypeId = @ProposalType
WHERE Id in (
	SELECT CourseId FROM #RecentCourses
)

DROP TABLE IF EXISTS #RecentCourses;