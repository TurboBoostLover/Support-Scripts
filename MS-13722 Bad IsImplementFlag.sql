USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13722';
DECLARE @Comments nvarchar(Max) = 
	'Update some bad data on isImplemented flag';
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
DECLARE @Table Table (Id int)
INSERT INTO @Table

SELECT p.Id FROM Proposal AS p
LEFT JOIN Course AS c ON p.Id = c.ProposalId
LEFT JOIN Program AS pr ON pr.ProposalId = p.Id
LEFT JOIN Module AS m ON m.ProposalId = p.Id
WHERE p.IsImplemented = 0
AND (
c.StatusAliasId in (1, 5)
or pr.StatusAliasId in (1, 5)
or m.StatusAliasId in (1, 5)
)

UPDATE Proposal
SET IsImplemented = 1
WHERE Id in (SELECT * FROM @Table)