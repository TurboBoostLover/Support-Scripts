USE [nukz];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17597';
DECLARE @Comments nvarchar(Max) = 
	'Update PRogram Default Search';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 2; /*  Default 1 is Support,  
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
DECLARE @Users INTEGERS
INSERT INTO @Users
SELECT Id FROM [User] WHERE Active = 1

DECLARE @Saved TABLE (usId int, searchId int)

INSERT INTO search.SavedSearches
(Name, Config)
SELECT 'Program', CONCAT('{"rules":null,"displayColumns":[{"id":"field-check-field-2536-166","location":"1"},{"id":"field-check-field-1100-167","location":"1"},{"id":"field-check-field-1225-165","location":"1"},{"id":"field-check-field-ProposalType-1","location":"1"},{"id":"field-check-field-status-1","location":"1"}],"filterByUser":false,"keyword":"","searchName":"","userId":',u.Id,',"clientEntityTypeId":2,"clientEntitySubTypeId":null,"clientIds":[1],"entityId":2,"sortOptions":[],"sortAscendingFlag":"1","isDefaultSearchForClientEntityType":true,"isPublicSearchForClientEntityType":false,"publicSearchClientId":1,"campusIds":[],"mode":"basic"}')
FROM @Users AS u

INSERT INTO @Saved (usId, searchId)
SELECT u.Id, s.Id
FROM @Users AS u
JOIN search.SavedSearches AS s ON u.Id = JSON_VALUE(s.Config, '$.userId') and s.Name = 'Program'

INSERT INTO search.UserSavedSearches
(UserId, SavedSearchesId)
SELECT usId, searchId FROM @Saved
--COMMIT