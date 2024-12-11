USE [cinc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16621';
DECLARE @Comments nvarchar(Max) = 
	'Update course data';
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
UPDATE Course
SET Active = 0 
WHERE Id in (
109, 207, 30, 232, 113, 114, 32, 33, 199, 196, 117, 35, 218, 219, 36, 37, 220, 221, 38, 39, 222, 40, 223, 224, 41, 132, 225, 42, 133, 134, 226, 43, 135, 227, 44, 45, 228, 229, 46, 47, 230, 231, 48, 166, 173, 177, 180, 181, 182, 183, 185
)

UPDATE Course
SET StatusAliasId = 1
WHERE Id in (234, 235, 236, 237, 238, 239)

UPDATE BaseCourse
SET ActiveCourseId = 
CASE 
	WHEN Id = 111 THEN 234
	WHEN Id = 112 THEN 235
	WHEN Id = 129 THEN 236
	WHEN Id = 130 THEN 237
	WHEN Id = 131 THEN 238
	WHEN Id = 132 THEN 239
ELSE ActiveCourseId
END
WHERE Id in (111, 112, 129, 130, 131, 132)