USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16408';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Histoyr';
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
DECLARE @Programs TABLE (oldId int, baseId int, Id int, proposalId int)
INSERT INTO @Programs
SELECT PreviousId, BaseProgramId, p.Id, p2.Id FROM Program AS p
INNER JOIN ProgramProposal AS pp on pp.ProgramId = p.Id
INNER JOIN Proposal As p2 on p.ProposalId = p2.Id
WHERE pp.SemesterId = 138
and p.StatusAliasId = 1

UPDATE Program
SET StatusAliasId = 2
WHERE Id in (
	SELECT Id FROM @Programs
)

UPDATE Proposal
SET ImplementDate = '2024-08-12 00:00:00.000'
, IsImplemented = 0
WHERE Id in (
	SELECT proposalId FROM @Programs
)

UPDATE Program
SET StatusAliasId = 1
WHERE Id in (735,507,392,302, 680)