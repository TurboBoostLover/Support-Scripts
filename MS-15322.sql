USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15322';
DECLARE @Comments nvarchar(Max) = 
	'Give some policies their own base so they are not versioning other ones for catalog';
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
DECLARE @TABLE TABLE (id int, act int)

INSERT INTO BaseModule
(ActiveModuleId, ClientId)
output inserted.Id, inserted. ActiveModuleId INTO @TABLE
VALUES
(396, 51),
(398, 51),
(399, 51),
(400, 51),
(401, 51),
(402, 51)

DECLARE @Id1 int = (SELECT Id FROM @TABLE WHERE act = 396)
DECLARE @Id2 int = (SELECT Id FROM @TABLE WHERE act = 398)
DECLARE @Id3 int = (SELECT Id FROM @TABLE WHERE act = 399)
DECLARE @Id4 int = (SELECT Id FROM @TABLE WHERE act = 400)
DECLARE @Id5 int = (SELECT Id FROM @TABLE WHERE act = 401)
DECLARE @Id6 int = (SELECT Id FROM @TABLE WHERE act = 402)

UPDATE Module
SET BaseModuleId = @Id1
WHERE Id = 396

UPDATE Module
SET BaseModuleId = @Id2
WHERE Id = 398

UPDATE Module
SET BaseModuleId = @Id3
WHERE Id = 399

UPDATE Module
SET BaseModuleId = @Id4
WHERE Id = 400

UPDATE Module
SET BaseModuleId = @Id5
WHERE Id = 401

UPDATE Module
SET BaseModuleId = @Id6
WHERE Id = 402