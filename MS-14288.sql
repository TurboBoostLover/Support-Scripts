USE [compton];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14288';
DECLARE @Comments nvarchar(Max) = 
	'Set Status from approved to active';
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
UPDATE Course
SET StatusAliasId = 1
WHERE Id in (
1804, 1889, 1890, 1891, 1892, 1893, 1894, 1952, 1955, 1954
)

UPDATE Proposal
SET LaunchDate = GETDATE()
, IsImplemented = 1
WHERE Id in (
	SELECT ProposalId FROM Course WHERE Id in (
	1804, 1889, 1890, 1891, 1892, 1893, 1894, 1952, 1955, 1954
	)
)

UPDATE BaseCourse
SET ActiveCourseId = 1804
WHERE Id = 889

UPDATE BaseCourse
SET ActiveCourseId = 1889
WHERE Id = 897

UPDATE BaseCourse
SET ActiveCourseId = 1890
WHERE Id = 898

UPDATE BaseCourse
SET ActiveCourseId = 1891
WHERE Id = 899

UPDATE BaseCourse
SET ActiveCourseId = 1892
WHERE Id = 900

UPDATE BaseCourse
SET ActiveCourseId = 1893
WHERE Id = 901

UPDATE BaseCourse
SET ActiveCourseId = 1894
WHERE Id = 902

UPDATE BaseCourse
SET ActiveCourseId = 1952
WHERE Id = 927

UPDATE BaseCourse
SET ActiveCourseId = 1954
WHERE Id = 928

UPDATE BaseCourse
SET ActiveCourseId = 1955
WHERE Id = 928