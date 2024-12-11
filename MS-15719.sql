USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15719';
DECLARE @Comments nvarchar(Max) = 
	'Add program Reactivations';
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
DECLARE @TABLE TABLE (Id int, title nvarchar(max))

INSERT INTO ProposalType(ClientId, Title, EntityTypeId, ProcessActionTypeId, MetaTemplateTypeId, Active, AllowReactivation, AllowNonAdminReactivation,ClientEntityTypeId, ReactivationRequired)
OUTPUT INSERTED.Id, INSERTED.Title INTO @TABLE
SELECT 51, 'Program Reactivation', 2, 2, 480, 1, 1, 1, 142, 1
UNION
SELECT 51, 'NCU - Program Reactivation', 2, 2, 502, 1, 1, 1, 148,1

INSERT INTO ProcessProposalType
(ProposalTypeId, ProcessId)
SELECT Id, 419 FROM @TABLE WHERE title = 'Program Reactivation'
UNION
SELECT Id, 507 FROM @TABLE WHERE title = 'NCU - Program Reactivation'