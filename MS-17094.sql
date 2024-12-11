USE [fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17094';
DECLARE @Comments nvarchar(Max) = 
	'Run Calc proc for programs';
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
DROP TABLE IF EXISTS #calculationResults;

-- Create temporary table
CREATE TABLE #calculationResults
(
    TableName sysname,
    Id int,
    Min decimal(16, 3),
    Max decimal(16, 3),
    IsVariable bit
);

-- Declare a cursor
DECLARE programCursor CURSOR FAST_FORWARD FOR
	SELECT p.Id FROM Program AS p
	INNER JOIN ProposalType AS pt on p.ProposalTypeId = pt.Id
	WHERE p.Active = 1

-- Variable to hold the fetched Id
DECLARE @programId int;

-- Open the cursor
OPEN programCursor;

-- Fetch the first row
FETCH NEXT FROM programCursor
INTO @programId;

-- Loop through all rows fetched by the cursor
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Execute the stored procedure
    EXEC upCalculateNestedCourseBlockEntries @entityId = @programId, @resultTable = '#calculationResults';

    -- Fetch the next row
    FETCH NEXT FROM programCursor
    INTO @programId;
END;

-- Close and deallocate the cursor
CLOSE programCursor;
DEALLOCATE programCursor;