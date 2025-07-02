USE [clovis];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18616';
DECLARE @Comments nvarchar(Max) = 
	'Add Service Areaa';
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
INSERT INTO OrganizationEntity
(OrganizationTierId, Title, ClientId, Code, StartDate)
VALUES

(3, 'Counseling - BAASE', 1, NULL, GETDATE()),
(3, 'Veteran Resource Center (CRC)', 1, NULL, GETDATE())

DECLARE @Student int = (SELECT Id FROM OrganizationEntity WHERE Active = 1 and Title = 'Student Services')
DECLARE @C int = (SELECT Id FROM OrganizationEntity WHERE Active = 1 and Title = 'Counseling - BAASE')
DECLARE @V int = (SELECT Id FROM OrganizationEntity WHERE Active = 1 and Title = 'Veteran Resource Center (CRC)')

INSERT INTO OrganizationLink
(StartDate, Child_OrganizationEntityId, Parent_OrganizationEntityId, ClientId)
VALUES
(GETDATE(), @C, @Student, 1),
(GETDATE(), @V, @Student, 1)