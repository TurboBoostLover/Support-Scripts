USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18509';
DECLARE @Comments nvarchar(Max) = 
	'Update Programs Status';
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
UPDATE Program
SET StatusAliasId = 1
WHERE ID in (2494, 2497, 2708, 2707)

UPDATE Program
SET StatusAliasId = 5
WHERE Id in (1913, 2297)

UPDATE BaseProgram
SET ActiveProgramId = CASE
	WHEN Id = 940 THEN 2494
	WHEN Id = 688 THEN 2497
	WHEN Id = 332 THEN 2707
	WHEN Id = 333 THEN 2708
	ELSE ActiveProgramId
	END
WHERE Id in (940, 688, 332, 333)

UPDATE Proposal
SET ProposalComplete = 1
, IsImplemented = 1
, ImplementDate = '2023-08-07 00:00:00.000'
WHERE Id in (4996, 4998, 6028, 6027)