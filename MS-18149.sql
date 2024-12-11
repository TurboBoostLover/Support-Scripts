use sbccd 

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18149';
DECLARE @Comments nvarchar(Max) = 'Nulled out the previousId for deleted draft programs. This was preventing items on the Active versions from being deleted. This is a temporary fix. DST-5772 should address the long term concerns';
DECLARE @Developer nvarchar(50) = 'Nate W.';
DECLARE @ScriptTypeId int = 1; 
/*  
Default for @ScriptTypeId on this script 
is 1 for  Support,  
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

/*
--------------------------------------------------------------------
Please do not alter the script above this comment�except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing something 
		 that is against meta best practices, but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the 
		 word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql
-----------------Script details go below this line------------------
*/
UPDATE CourseOption
SET PreviousId = NULL
WHERE ProgramId = 951

UPDATE ProgramCourse
SET PreviousId = NULL
WHERE CourseOptionId in (
	SELECT Id FROM CourseOption WHERE ProgramId = 951
)

UPDATE ProgramSequence
SET PreviousId = NULL
WHERE ProgramId = 951

DECLARE @test INTEGERS
INSERT INTO @test
SELECT Id FROM ProgramCourse
WHERE CourseOptionId in (
	SELECT Id FROM CourseOption WHERE ProgramId = 951
)

UPDATE ProgramCourse
SET PreviousId = NULL
WHERE PreviousId in (
	SELECT Id FROM @test
)