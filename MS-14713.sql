USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14713';
DECLARE @Comments nvarchar(Max) = 
	'Update Validtion on section';
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
UPDATE MetaSqlStatement
SET SqlStatement = '
DECLARE @validCount INT = 0;
DECLARE @totalCount INT = 0;

SELECT
    @validCount = SUM(
        CASE
            WHEN mrm.Reference_CourseOutcomeId IS NOT NULL THEN 1
            ELSE 0
        END
    ),
    @totalCount = COUNT(*)
FROM ModuleRelatedModule02 mrm
WHERE mrm.ModuleId = @entityId;

--SELECT @validCount AS validCount, @totalCount AS totalCount;

SELECT
    CASE
        WHEN @totalCount > 0 AND @validCount = @totalCount THEN 1
        ELSE 0
    END;
'
WHERE Id = 11

UPDATE MetaSqlStatement
SET SqlStatement = '
DECLARE @validCount INT = 0;
DECLARE @totalCount INT = 0;

SELECT
    @validCount = SUM(CASE WHEN mrm.Reference_CourseOutcomeId IS NOT NULL THEN 1 ELSE 0 END),
    @totalCount = COUNT(*)
FROM ModuleRelatedModule02 mrm
WHERE mrm.ModuleId = @entityId;

SELECT CASE
    WHEN @totalCount > 0 AND @validCount = @totalCount THEN 1
    ELSE 0
END;

'
WHERE Id = 5