USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16341';
DECLARE @Comments nvarchar(Max) = 
	'Update Typical Assignments and map over data';
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
DELETE FROM CourseAssignment
WHERE AssignmentText IS NULL
and AssignmentTypeId IS NULL

DECLARE @TABLE TABLE (NewId int, Tex nvarchar(max))
INSERT INTO @TABLE
SELECT c2.Id, ca.ASSIGNMENT_TEXT FROM LasPositas_v2.dbo.COURSE_ASSIGNMENTS AS ca
INNER JOIN LasPositas_v2.dbo.COURSES AS c on ca.COURSES_ID = c.COURSES_ID
INNER JOIN laspositas.dbo.vKeyTranslation AS vkey on vkey.OldId = c.COURSES_ID and vkey.DestinationTable = 'Course'
INNER JOIN laspositas.dbo.Course AS c2 on vkey.NewId = c2.Id

INSERT INTO laspositas.dbo.CourseAssignment
(CourseId, SortOrder, CreatedDate, ListItemTypeId, AssignmentText)
SELECT NewId, 1, GETDATE(), 11, Tex FROM @TABLE