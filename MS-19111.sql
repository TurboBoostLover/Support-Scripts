USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19111';
DECLARE @Comments nvarchar(Max) = 
	'Delete Bad Duplicated data';
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
WITH RankedContributors AS (
    SELECT 
        Id,  -- Assuming there's a unique identifier column like Id
        UserId,
        CourseId,
        ROW_NUMBER() OVER (PARTITION BY UserId, CourseId ORDER BY Id) AS RowNum
    FROM CourseContributor
		WHERE Active = 1
)
DELETE FROM CourseContributor
WHERE Id IN (
    SELECT Id FROM RankedContributors WHERE RowNum > 1
);

WITH RankedContributors AS (
    SELECT 
        Id,  -- Assuming there's a unique identifier column like Id
        UserId,
        ProgramId,
        ROW_NUMBER() OVER (PARTITION BY UserId, ProgramId ORDER BY Id) AS RowNum
    FROM ProgramContributor
		WHERE Active = 1
)
DELETE FROM ProgramContributor
WHERE Id IN (
    SELECT Id FROM RankedContributors WHERE RowNum > 1
);

WITH RankedContributors AS (
    SELECT 
        Id,  -- Assuming there's a unique identifier column like Id
        UserId,
        ModuleId,
        ROW_NUMBER() OVER (PARTITION BY UserId, ModuleId ORDER BY Id) AS RowNum
    FROM ModuleContributor
		WHERE Active = 1
)
DELETE FROM ModuleContributor
WHERE Id IN (
    SELECT Id FROM RankedContributors WHERE RowNum > 1
);