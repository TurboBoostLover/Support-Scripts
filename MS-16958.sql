USE [sbcc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16958';
DECLARE @Comments nvarchar(Max) = 
	'Fix Cross Listing configuration';
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
DELETE FROM CrossListingProposalType WHERE CrossListingId not in (
	SELECT CrossListingId FROM CrossListingCourse
)

DELETE FROM CrossListing WHERE Id not in (
	SELECT CrossListingId FROM CrossListingCourse
)

Insert into CrossListingFieldSyncBlackList
(MetaAvailableFieldId,ClientId)
Values
(873,1),    /*Subject*/
(888,1),    /*Course Number*/
(1428,1),   /*Queue for assist*/
(876,1),    /*CB00*/
(2692,1);   /*C-ID*/

UPDATE Course
SET SubjectId = 63
, CourseNumber = 105
WHERE Id = 10555

UPDATE Course
SET SubjectId = 51
WHERE Id = 10556

UPDATE Course
SET SubjectId = 58
WHERE Id = 10557

UPDATE Course
SET CourseNumber = 161
WHERE Id = 10558

DECLARE @ID INTEGERS
INSERT INTO @ID
VALUES
(10555),
(10556),
(10557),
(10558)

while exists(select top 1 1 from @ID)
begin
    declare @TID int = (select top 1 * from @ID)
    EXEC upCreateEntityTitle @EntityId = @TID, @EntityTypeId = 1
    delete @ID
    where id = @TID
end