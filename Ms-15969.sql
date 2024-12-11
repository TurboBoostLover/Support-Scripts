USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15969';
DECLARE @Comments nvarchar(Max) = 
	'Delete bad data';
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
DECLARE @FIELDS INTEGERS
INSERT INTO @FIELDS
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId IS NULL
AND DisplayName like '%&nbsp%'

DELETE FROM MetaSelectedFieldRolePermission
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @FIELDS
)

DELETE FROM MetaSelectedFieldPositionPermission
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @FIELDS
)

DELETE FROM MetaSelectedField WHERE MetaSelectedFieldId in (
	SELECT Id FROM @FIELDS
)

UPDATE co
SET co.Header = cod.Maxtext01
FROM CourseOption as co
INNER JOIN CourseOptionDetail As cod on cod.CourseOptionId = co.Id
WHERE cod.Maxtext01 IS NOT NULL

UPDATE CourseOptionDetail
SET Maxtext01 = NULL
WHERE Maxtext01 IS NOT NULL

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 471
WHERE MetaAvailableFieldId = 3490

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection As mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN @FIELDS As f on msf.MetaSelectedFieldId = f.Id
	UNION
	SELECT mss.MEtaTemplateId FROM MetaSelectedSection As mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaAvailableFieldId = 471
)