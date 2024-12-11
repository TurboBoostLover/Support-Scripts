USE [fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15109';
DECLARE @Comments nvarchar(Max) = 
	'UPdate Annual Unit Plan';
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
INSERT INTO ClientEntityType
(ClientId, EntityTypeId, SortOrder, Title, OrganizationConnectionStrategyId, ProposalInterlockStrategyId, Active, PluralTitle, PublicSearchVisible)
VALUES
(1, 6, 6, 'Annual Unit Plan', 2, 1, 1, 'Annual Unit Plans', 0)

DECLARE @ID int = SCOPE_IDENTITY()

UPDATE ProposalType
SET ClientEntitySubTypeId = NULL
, ClientEntityTypeId = @ID
WHERE Id in (
11, 18
)

UPDATE ClientEntityType
SET SortOrder = 7
WHERE Id = 7