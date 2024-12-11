USE [victorvalley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14341';
DECLARE @Comments nvarchar(Max) = 
	'Add a lot into their organization';
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
INSERT INTO OrganizationEntity
(OrganizationTierId, Title, ClientId, StartDate)
VALUES
(2, 'Work Experience Education', 1, GETDATE())

DECLARE @Id int = SCOPE_IDENTITY()

DECLARE @SubjectIds TABLE (Id int)
INSERT INTO @SubjectIds
SELECT SubjectId FROM OrganizationSubject
WHERE Active = 1
AND OrganizationEntityId = 47

DECLARE @TABLE TABLE (Id int)

INSERT INTO Subject
(SubjectCode, Title, ClientId, SortOrder, StartDate, PublicVisible, NonCredit)
output inserted.Id into @TABLE
SELECT REPLACE(SubjectCode, 'COOP', 'WEE'), REPLACE(Title, 'COOP', 'WEE'), ClientId, SortOrder, StartDate, PublicVisible, NonCredit FROM Subject
WHERE Id in (SELECT Id FROM @SubjectIds)

INSERT INTO OrganizationSubject
(OrganizationEntityId, SubjectId, StartDate)
SELECT @Id, Id, GETDATE() FROM @TABLE