USE [clovis];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15550';
DECLARE @Comments nvarchar(Max) = 
	'Update Sort order fro Course Objectives';
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
UPDATE CourseObjective
SET SortOrder = 14
WHERE Id = 4514

UPDATE CourseObjective
SET SortOrder = 13
WHERE Id = 4515

UPDATE CourseObjective
SET SortOrder = 12
WHERE Id = 4516

UPDATE CourseObjective
SET SortOrder = 11
WHERE Id = 4517

UPDATE CourseObjective
SET SortOrder = 7
WHERE Id = 4518

UPDATE CourseObjective
SET SortOrder = 10
WHERE Id = 4519

UPDATE CourseObjective
SET SortOrder = 3
WHERE Id = 4520

UPDATE CourseObjective
SET SortOrder = 9
WHERE Id = 4521

UPDATE CourseObjective
SET SortOrder = 8
WHERE Id = 4522

UPDATE CourseObjective
SET SortOrder = 5
WHERE Id = 4523

UPDATE CourseObjective
SET SortOrder = 6
WHERE Id = 4524

UPDATE CourseObjective
SET SortOrder = 4
WHERE Id = 4525

UPDATE CourseObjective
SET SortOrder = 1
WHERE Id = 4526

UPDATE CourseObjective
SET SortOrder = 2
WHERE Id = 4527

UPDATE CourseObjective
SET SortOrder = 9
WHERE Id = 5484

UPDATE CourseObjective
SET SortOrder = 13
WHERE Id = 5487

UPDATE CourseObjective
SET SortOrder = 7
WHERE Id = 5488

UPDATE CourseObjective
SET SortOrder = 12
WHERE Id = 5489

UPDATE CourseObjective
SET SortOrder = 3
WHERE Id = 5490

UPDATE CourseObjective
SET SortOrder = 5
WHERE Id = 5493

UPDATE CourseObjective
SET SortOrder = 6
WHERE Id = 5494

UPDATE CourseObjective
SET SortOrder = 4
WHERE Id = 5495

UPDATE CourseObjective
SET SortOrder = 1
WHERE Id = 5496

UPDATE CourseObjective
SET SortOrder = 2
WHERE Id = 5497

UPDATE CourseObjective
SET SortOrder = 8
WHERE Id = 5498

UPDATE CourseObjective
SET SortOrder = 10
WHERE Id = 5499

UPDATE CourseObjective
SET SortOrder = 11
WHERE Id = 5500