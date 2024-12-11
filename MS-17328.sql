USE aurak;

-- Commit
							
							
				
				-- Rollback


DECLARE @JiraTicketNumber NVARCHAR(20) = 'MS-17328';
DECLARE @Comments NVARCHAR(MAX) = 'update Modify workflow , made new workflow(Major Course Modification) and made 2 new propsal types(Minor Course Modification,Major Course Modification)';
DECLARE @Developer NVARCHAR(50) = 'Nate W.';
DECLARE @ScriptTypeId INT = 1; 

/*  
Default for @ScriptTypeId on this script is 1 for Support.

For a complete list run the following query:
SELECT * FROM History.ScriptType
*/

SELECT
  @@servername AS 'Server Name', 
  DB_NAME() AS 'Database Name', 
  @JiraTicketNumber AS 'Jira Ticket Number'
;

SET XACT_ABORT ON
BEGIN TRAN

IF EXISTS
	(
	SELECT TOP 1 1 
	FROM History.ScriptsRunOnDatabase 
	WHERE TicketNumber = @JiraTicketNumber 
	AND Developer = @Developer 
	AND Comments = @Comments
	)
THROW 51000, 'This Script has already been run', 1;

INSERT INTO History.ScriptsRunOnDatabase
	(TicketNumber, Developer, Comments, ScriptTypeId)
VALUES
	(@JiraTicketNumber, @Developer, @Comments, @ScriptTypeId)
; 

/*
--------------------------------------------------------------------
Please do not alter the script above this comment except to set
the USE statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing something 
		 that is against Meta best practices, but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences.

	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention: 
		 Release Number_Ticket Number_either the word Predeploy or 
		 PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql

-----------------Script details go below this line------------------
*/
update ProposalType
set Title = 'Minor Course Changes'
, AllowReactivation = 0
, ReactivationRequired = 0
where Id = 2

--Exec spActivateWorkflow
--    @ProcessID = 2,
--    @ProcessVersionID = 17

--Exec spActivateWorkflow
--    @ProcessID = 9,
--    @ProcessVersionID = 18

--insert into ProposalType(ClientId,Title,EntityTypeId,ProcessActionTypeId, MetaTemplateTypeId,ClientEntityTypeId)
--values(1,'Major Course Modification',1,2, 1,1)

--declare @processt_id int = SCOPE_IDENTITY()

--insert into ProcessProposalType(ProposalTypeId,ProcessId)
--values(@processt_id,9) 