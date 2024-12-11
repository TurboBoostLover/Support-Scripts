USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-17024';
DECLARE @Comments nvarchar(Max) = 
	'Update Effective Term drop down look up data';
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
--To look at data for code review
/*******************************************
SELECT DisplayName, MetaForeignKeyLookupSourceId FROM MetaSelectedField WHERE MetaSelectedFieldId = 3212
SELECT * FROM MetaForeignKeyCriteriaClient WHERE Id = 51

select
    Id as Value,
    Title as Text
from Semester
where Active = 1
and Code = 2

********************************************/

UPDATE Semester
SET Title = 'Semester 1, AY 2024/25'
WHERE Id = 58

UPDATE Semester
SET Title = 'Semester 2, AY 2024/25'
WHERE Id = 59

UPDATE Semester
SET Title = 'Semester 1, AY 2025/26'
WHERE Id = 60

UPDATE Semester
SET Title = 'Semester 2, AY 2025/26'
WHERE Id = 61

UPDATE Semester
SET Title = 'Semester 1, AY 2026/27'
WHERE Id = 62

UPDATE Semester
SET Title = 'Semester 2, AY 2026/27'
WHERE Id = 63

UPDATE Semester
SET Title = 'Semester 1, AY 2027/28'
WHERE Id = 64

UPDATE Semester
SET Title = 'Semester 2, AY 2027/28'
WHERE Id = 65

INSERT INTO Semester
(Title, ClientId, SortOrder, Code, StartDate)
VALUES
('Semester 1, AY 2028/29', 1, 9, 2, GETDATE()),
('Semester 2, AY 2028/29', 1, 10, 2, GETDATE())

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()