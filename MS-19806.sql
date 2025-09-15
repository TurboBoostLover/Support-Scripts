USE [hbmsu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19806';
DECLARE @Comments nvarchar(Max) = 
	'Delete bad duplicate co-contirubor data';
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
DECLARE @Ids TABLE (Id int, RowNum int)

;WITH RankedContributors AS (
    SELECT 
        Id,
        UserId,
        CourseId,
        ROW_NUMBER() OVER (PARTITION BY UserId, CourseId ORDER BY Id) AS RowNum
    FROM CourseContributor
		WHERE Active = 1
)
INSERT INTO @Ids
SELECT Id, RowNum FROM RankedContributors

DELETE FROM CourseContributorMetaSelectedSection
WHERE CourseContributorId in (
	SELECT Id FROM @Ids WHERE RowNum > 1
)

DELETE FROM CourseContributor
WHERE Id IN (
    SELECT Id FROM @Ids WHERE RowNum > 1
);

DELETE FROM @Ids
WHERE 1 = 1; --Empty it out

WITH RankedContributors AS (
    SELECT 
        Id,
        UserId,
        ProgramId,
        ROW_NUMBER() OVER (PARTITION BY UserId, ProgramId ORDER BY Id) AS RowNum
    FROM ProgramContributor
		WHERE Active = 1
)
INSERT INTO @Ids
SELECT Id, RowNum FROM RankedContributors

DELETE FROM ProgramContributorMetaSelectedSection
WHERE ProgramContributorId in (
	SELECT Id FROM @Ids WHERE RowNum > 1
)

DELETE FROM ProgramContributor
WHERE Id IN (
    SELECT Id FROM @Ids WHERE RowNum > 1
);

DELETE FROM @Ids
WHERE 1 = 1; --Empty it out

WITH RankedContributors AS (
    SELECT 
        Id,
        UserId,
        ModuleId,
        ROW_NUMBER() OVER (PARTITION BY UserId, ModuleId ORDER BY Id) AS RowNum
    FROM ModuleContributor
		WHERE Active = 1
)
INSERT INTO @Ids
SELECT Id, RowNum FROM RankedContributors

DELETE FROM ModuleContributorMetaSelectedSection
WHERE ModuleContributorId in (
	SELECT Id FROM @Ids WHERE RowNum > 1
)

DELETE FROM ModuleContributor
WHERE Id IN (
    SELECT Id FROM @Ids WHERE RowNum > 1
);

UPDATE CourseContributorMetaSelectedSection
SET PreviousId = NULL
WHERE 1= 1

DELETE FROM CourseContributorMetaSelectedSection
WHERE CourseContributorId in (
	SELECT Id FROM CourseContributor
	WHERE Id in (
		SELECT cc.Id FROM CourseContributor AS cc
		INNER JOIN Course AS C on cc.CourseId = C.Id
		WHERE cc.UserId = C.UserId
	)
)

UPDATE CourseContributor
SET PreviousId = NULL
WHERE 1= 1

DELETE FROM CourseContributor
WHERE Id in (
	SELECT cc.Id FROM CourseContributor AS cc
	INNER JOIN Course AS C on cc.CourseId = C.Id
	WHERE cc.UserId = C.UserId
)

DELETE FROM ProgramContributorMetaSelectedSection
WHERE ProgramContributorId in (
	SELECT Id FROM ProgramContributor
	WHERE Id in (
		SELECT cc.Id FROM ProgramContributor AS cc
		INNER JOIN Program AS C on cc.ProgramId = C.Id
		WHERE cc.UserId = C.UserId
	)
)

UPDATE ProgramContributor
SET PreviousId = NULL
WHERE 1 = 1

DELETE FROM ProgramContributor
WHERE Id in (
	SELECT cc.Id FROM ProgramContributor AS cc
	INNER JOIN Program AS C on cc.ProgramId = C.Id
	WHERE cc.UserId = C.UserId
)

DELETE FROM ModuleContributorMetaSelectedSection
WHERE ModuleContributorId in (
	SELECT Id FROM ModuleContributor
	WHERE Id in (
		SELECT cc.Id FROM ModuleContributor AS cc
		INNER JOIN Module AS C on cc.ModuleId = C.Id
		WHERE cc.UserId = C.UserId
	)
)

DELETE FROM ModuleContributor
WHERE Id in (
	SELECT cc.Id FROM ModuleContributor AS cc
	INNER JOIN Module AS C on cc.ModuleId = C.Id
	WHERE cc.UserId = C.UserId
)