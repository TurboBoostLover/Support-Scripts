USE [sbcc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14656';
DECLARE @Comments nvarchar(Max) = 
	'Add Ceramic Technology to their subjects';
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
INSERT INTO Subject
(SubjectCode, Title, ClientId, SortOrder, StartDate, NonCredit)
VALues
('Crmc', 'Ceramic Technology', 1, 1, GETDATE(), 0)

DECLARE @ID int = SCOPE_IDENTITY()

DECLARE @OE int = 40

INSERT INTO OrganizationSubject
(OrganizationEntityId, SubjectId, StartDate)
VALUES
(@OE, @ID, GETDATE())

update s
set SortOrder = sorted.rownum 
output inserted.*
from Subject s
inner join ( 
select id, ROW_NUMBER() over (order by Title) rownum 
from Subject 
) sorted on s.Id = sorted.Id