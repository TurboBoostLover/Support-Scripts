USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17574';
DECLARE @Comments nvarchar(Max) = 
	'Update old Program Reviews to not be in clusters anymore';
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
UPDATE ModuleDetail
SET Tier2_OrganizationEntityId = CASE
WHEN md.Tier2_OrganizationEntityId = 42 THEN 469
WHEN md.Tier2_OrganizationEntityId = 44 THEN 474
WHEN md.Tier2_OrganizationEntityId = 64 THEN 479
WHEN md.Tier2_OrganizationEntityId = 67 THEN 484
WHEN md.Tier2_OrganizationEntityId = 68 THEN 65
WHEN md.Tier2_OrganizationEntityId = 131 THEN 491
WHEN md.Tier2_OrganizationEntityId = 141 THEN 496
ELSE md.Tier2_OrganizationEntityId
END
output inserted.ModuleId
FROM ModuleDetail AS md
INNER JOIN Module AS m on md.ModuleId = m.Id
WHERE m.Active = 1
and m.ClientId = 4
and md.Tier2_OrganizationEntityId in (
42,
44,
64,
67,
68,
131,
141
)

UPDATE OrganizationEntity
SET EndDate = GETDATE()
WHERE Id in (
42,
44,
64,
67,
68,
131,
141
)