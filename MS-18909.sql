USE [gavilan];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18909';
DECLARE @Comments nvarchar(Max) = 
	'Fix orginization data since they messed around on live';
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
UPDATE OrganizationEntity
SET EndDate = NULL
WHERE Id in (
4987, 4988
)

UPDATE OrganizationEntity
SET EndDate = GETDATE()
WHERE Id in (
5149, 5150
)

UPDATE Program
SET Tier1_OrganizationEntityId = 4987
WHERE Tier1_OrganizationEntityId = 5149

UPDATE Program
SET Tier2_OrganizationEntityId = 4988
WHERE Tier2_OrganizationEntityId = 5150

INSERT INTO UserOriginationOrganizationEntityPermission
(UserId, OrganizationEntityId, StartDate)
VALUES
(38763, 4987, GETDATE()),
(38763, 4988, GETDATE())

UPDATE UserOriginationOrganizationEntityPermission
SET EndDate = NULL
WHERE OrganizationEntityId IN (4987, 4988)
AND CONVERT(DATE, EndDate) = '2025-02-11';