USE [clovis];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16739';
DECLARE @Comments nvarchar(Max) = 
	'Add user to Clovis';
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
INSERT INTO [User]
(FirstName, LastName, Email, EmailVerified, Active, Password, ClientId, CreationTime, UserTypeId)
VALUES
('Adam', 'Chin', 'adam.chin@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1),
('Diana', 'Chandara', 'diana.chandara@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1),
('Hugo', 'Lopez Chavolla', 'hugo.lopez-chavolla@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1),
('Clayton', 'Plake', 'clayton.plake@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1),
('Lauren', 'Schiebelhut', 'lauren.schiebelhut@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1),
('Amanda', 'Rea', 'amanda.rea@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1),
('Jay', 'McDaniel', 'jay.mcdaniel@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1),
('Kwan', 'Seow', 'kwan.seow@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1),
('Eric ', 'Mendoza', 'eric.mendoza@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1),
('Kevin', 'Easley', 'kevin.easley@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1),
('Benjamin', 'Smith', 'benjamin.smith@cloviscollege.edu', 1, 1, hashbytes('sha1', 'ChangeMe01'), 1, GETDATE(), 1)