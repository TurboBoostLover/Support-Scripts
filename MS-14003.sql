USE [chabot];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14003';
DECLARE @Comments nvarchar(Max) = 
	'Add options to the Course Block Title Drop Down in the Program Mapper Tab';
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
UPDATE CourseOptionType
SET SortOrder = SortOrder + 4
WHERE SortOrder > 9

UPDATE CourseOptionType
SET SortOrder = SortOrder + 1
WHERE SortOrder > 20

INSERT INTO CourseOptionType
(ClientId, Title, SortOrder, StartDate)
VALUES
(1, 'Semester 9', 10, GETDATE()),
(1, 'Semester 10', 11, GETDATE()),
(1, 'Semester 11', 12, GETDATE()),
(1, 'Semester 12', 13, GETDATE()),
(1, 'General Education Requirements', 21, GETDATE())

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId
	FROM MetaTemplateType mtt
		INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId		--Update All program Forms 
	WHERE mt.Active = 1 
		AND mtt.EntityTypeId = 2
		AND mt.IsDraft = 0
		AND mt.EndDate IS NULL
		AND mtt.Active = 1
		AND mtt.IsPresentationView = 0
		AND mtt.ClientId = 1
)