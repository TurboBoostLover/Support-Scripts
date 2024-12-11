USE [ccsf];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16826';
DECLARE @Comments nvarchar(Max) = 
	'Insert Users';
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
DECLARE @TABLE TABLE (Id int)

INSERT INTO [User]
(FirstName, LastName, Username, Email, EmailVerified, Active, ClientId, CreationTime, UserTypeId)
output inserted.Id into @TABLE
VALUES
('Ymilul', 'Bates', 'ykbates@ccsf.edu', 'ykbates@ccsf.edu', 1, 1, 57, GETDATE(), 1),
('Michelle', 'Day', 'mday@ccsf.edu', 'mday@ccsf.edu', 1, 1, 57, GETDATE(), 1),
('Lisa', 'Guay', 'lguay@ccsf.edu', 'lguay@ccsf.edu', 1, 1, 57, GETDATE(), 1),
('Krystle', 'Guzman', 'kguzman@ccsf.edu', 'kguzman@ccsf.edu', 1, 1, 57, GETDATE(), 1),
('Danielle', 'Joo', 'djoo@ccsf.edu', 'djoo@ccsf.edu', 1, 1, 57, GETDATE(), 1),
('Kevyn', 'Lorenzana', 'klorenzana@ccsf.edu', 'klorenzana@ccsf.edu', 1, 1, 57, GETDATE(), 1),
('Jason', 'Nava', 'jnava@ccsf.edu', 'jnava@ccsf.edu', 1, 1, 57, GETDATE(), 1),
('Jessica', 'Parisi', 'jparisi@ccsf.edu', 'jparisi@ccsf.edu', 1, 1, 57, GETDATE(), 1),
('Kanak', 'Somani', 'ksomani@ccsf.edu', 'ksomani@ccsf.edu', 1, 1, 57, GETDATE(), 1),
('Edgar', 'Waingortin', 'ewaingortin@ccsf.edu', 'ewaingortin@ccsf.edu', 1, 1, 57, GETDATE(), 1)

INSERT INTO UserRole
(UserId, RoleId, Active, ClientId)
SELECT Id, 4, 1, 57 FROM @TABLE