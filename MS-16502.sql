USE [victorvalley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16502';
DECLARE @Comments nvarchar(Max) = 
	'Map over old assignment data';
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
DECLARE @Reading TABLE (Txt nvarchar(max), id int)
INSERT INTO @Reading
SELECT dbo.ConcatWithSep_Agg(';', AssignmentText), CourseId FROM CourseAssignment WHERE AssignmentTypeId = 4 group by CourseId

DECLARE @Writing TABLE (Txt nvarchar(max), id int)
INSERT INTO @Writing
SELECT  dbo.ConcatWithSep_Agg(';', AssignmentText), CourseId FROM CourseAssignment WHERE AssignmentTypeId = 5 group by CourseId

DECLARE @Out TABLE (Txt nvarchar(max), id int)
INSERT INTO @Out 
SELECT  dbo.ConcatWithSep_Agg(';', AssignmentText), CourseId FROM CourseAssignment WHERE AssignmentTypeId = 6 group by CourseId

UPDATE gm
SET TextMax48 = CASE WHEN r.txt IS NOT NULL then r.txt else TextMax48 end
, TextMax49 = CASE WHEN w.txt IS NOT NULL then w.txt else TextMax49 end
, TextMax50 = CASE WHEN o.txt IS NOT NULL then o.txt else TextMax50 end
FROM GenericMaxText AS gm
INNER JOIN Course AS c on gm.CourseId = c.Id
LEFT JOIN @Reading aS r on r.id = c.Id
LEFT JOIN @Writing AS w on w.id = c.Id
LEFT JOIN @Out AS o on o.id = c.Id