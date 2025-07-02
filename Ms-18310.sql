USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18310';
DECLARE @Comments nvarchar(Max) = 
	'Make All AUO Assessments that are launched to Active';
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
DECLARE @Modules TABLE (ModuleId int, BaseModuleId int, ProposalId int, Prev int)

UPDATE m
SET StatusAliasId = 1
output inserted.Id, inserted.BaseModuleId, inserted.ProposalId, inserted.PreviousId INTO @Modules
FROM Module m WHERE ProposalTypeId = 68 and Active = 1 and StatusAliasId = 6 and ClientId = 2

SELECT * FROM @Modules

UPDATE bm
SET ActiveModuleId = m.ModuleId
FROM BaseModule AS bm
INNER JOIN @Modules AS m on bm.Id = m.BaseModuleId

UPDATE p
SET IsImplemented = 1
, ProposalComplete = 1
FROM Proposal p 
INNER JOIN @Modules AS m on m.ProposalId = p.Id

UPDATE m
SET StatusAliasId = 2
FROM Module m
INNER JOIN @Modules AS mm on mm.Prev = m.Id