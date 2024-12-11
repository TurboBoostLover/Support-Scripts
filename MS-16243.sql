USE [compton];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16243';
DECLARE @Comments nvarchar(Max) = 
	'Update Look up Data';
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
INSERT INTO MinimumQualification
(Title, MastersRequired, SortOrder, ClientId, StartDate,Active_Old)
VALUES
('African American Studies', 0, 1, 1, GETDATE(), 1),
('Asian American Studies', 0, 1, 1, GETDATE(), 1),
('Classics', 0, 1, 1, GETDATE(), 1),
('Community College Counselor of Students with Disabilities', 0, 1, 1, GETDATE(), 1),
('Digital Fabrication Technician', 0, 1, 1, GETDATE(), 1),
('Disabled Student Programs and Services (DSPS)', 0, 1, 1, GETDATE(), 1),
('English as a Second Language (ESL): Credit', 0, 1, 1, GETDATE(), 1),
('Homeland Security', 0, 1, 1, GETDATE(), 1),
('Learning Disabilities: Specialist', 0, 1, 1, GETDATE(), 1),
('Military Studies', 0, 1, 1, GETDATE(), 1),
('Nanotechnology', 0, 1, 1, GETDATE(), 1),
('Native American/American Indian Studies', 0, 1, 1, GETDATE(), 1),
('Registered Behavior Technician', 0, 1, 1, GETDATE(), 1),
('Supply Chain Technology', 0, 1, 1, GETDATE(), 1)

UPDATE MinimumQualification
SET EndDate = GETDATE()
, Active_Old = 0
WHERE Id in (
87, 24, 39, 61
)

UPDATE MinimumQualification
SET Title = 'Dietetics/Nutritional Science'
WHERE Id = 15

update mq 
set SortOrder = sorted.rownum 
output inserted.*
from MinimumQualification mq
inner join ( 
select id, ROW_NUMBER() over (order by Title) rownum 
from MinimumQualification 
WHERE Active = 1
) sorted on mq.Id = sorted.Id