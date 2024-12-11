USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14946';
DECLARE @Comments nvarchar(Max) = 
	'Activate Courses';
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
UPDATE bc 
SET bc.ActiveCourseId = C.Id
FROM Course AS c
INNER JOIN BaseCourse AS bc on c.BaseCourseId = bc.Id
WHERE c.Id in (
8904, 8882, 8939, 8896, 8897, 8807
)
AND c.BaseCourseId = bc.Id

UPDATE Course
SET StatusAliasId = 1
WHERE Id in (
8904, 8882, 8939, 8896, 8897, 8807
)

UPDATE Course
SET StatusAliasId = 6
WHERE Id in (
9029,
9028,
9007,
7835,
7665,
7979
)

UPDATE Proposal 
SET IsImplemented = 1
, ProposalComplete = 1
, ImplementDate = GETDATE()
WHERE Id in (
6125,
6864,
6871,
6872,
6868,
6824
)