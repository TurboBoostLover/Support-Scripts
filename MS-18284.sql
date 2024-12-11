USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18284';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Default search for all users';
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
UPDATE Search.SavedSearches 
SET Config = '{"rules":{"condition":"OR","rules":[{"id":"field-status-1","field":"field-status-1","type":"integer","input":"select","operator":"equal","value":1},{"id":"field-status-1","field":"field-status-1","type":"integer","input":"select","operator":"equal","value":4},{"id":"field-status-1","field":"field-status-1","type":"integer","input":"select","operator":"equal","value":5},{"id":"field-status-1","field":"field-status-1","type":"integer","input":"select","operator":"equal","value":6}],"valid":true},"displayColumns":[{"id":"field-check-field-ProposalType-1","location":"1"},{"id":"field-check-field-1225-38367","location":"1"},{"id":"field-check-field-1100-38369","location":"1"},{"id":"field-check-field-status-1","location":"1"}],"filterByUser":false,"keyword":"","searchName":"","userId":391,"clientEntityTypeId":2,"clientEntitySubTypeId":null,"clientIds":[1],"entityId":2,"sortOptions":[],"sortAscendingFlag":"1","isDefaultSearchForClientEntityType":true,"isPublicSearchForClientEntityType":false,"publicSearchClientId":1,"campusIds":[],"mode":"basic"}'
WHERE (JSON_VALUE(Config, '$.entityId') = 2) and (JSON_VALUE(Config, '$.isDefaultSearchForClientEntityType') = 'true')