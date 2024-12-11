USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18000';
DECLARE @Comments nvarchar(Max) = 
	'Adding Ge Elements';
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
INSERT INTO GeneralEducationElement
(GeneralEducationId, Title, SortOrder ,StartDate, ClientId)
VALUES
(4, 'US-1. Historical development of American institutions and ideals', 13, GETDATE(), 1),
(4, 'US-2. United States Constitution and government', 14, GETDATE(), 1),
(4, 'US-3. California state and local government', 15, GETDATE(), 1)

INSERT INTO CanCode
(Description, SortOrder, ClientId, StartDate)
VALUES
('Plan 2: US-1. Historical development of American institutions and ideals', 22, 1, GETDATE()),
('Plan 2: US-2. United States Constitution and government', 23, 1, GETDATE()),
('Plan 2: US-3. California state and local government', 24, 1, GETDATE())

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	WHERE mss.MetaBaseSchemaId in (
		131, 83
	)
)