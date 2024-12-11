USE stpetersburg
/*
	Commit					
					Rollback
*/

DECLARE @JiraTicketNumber NVARCHAR(20) = 'MS-13632';
DECLARE @Comments NVARCHAR(MAX) = 'Fixing semester data/backing store issue';
DECLARE @Developer NVARCHAR(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId INT = 1; 

/*  
Default for @ScriptTypeId on this script is 1 for Support.

For a complete list run the following query:
SELECT * FROM history.ScriptType
*/

SELECT
  @@servername AS 'Server Name' 
, DB_NAME() AS 'Database Name'
, @JiraTicketNumber AS 'Jira Ticket Number'
;

SET XACT_ABORT ON
BEGIN TRAN

INSERT INTO History.ScriptsRunOnDatabase
(TicketNumber,Developer,Comments,ScriptTypeId)
VALUES
(@JiraTicketNumber, @Developer, @Comments, @ScriptTypeId)
; 

/*
--------------------------------------------------------------------
Please do not alter the script above this comment except to set
the USE statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing something 
		 that is against Meta best practices, but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences.

	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention: 
		 Release Number_Ticket Number_either the word Predeploy or 
		 PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql

-----------------Script details go below this line------------------
*/

/* --------------------------------------------------------------
					Temp tables for ids
-------------------------------------------------------------- */
DECLARE @templateIds Integers;
DECLARE @tempSemester TABLE 
	(CourseId INT, ActualBegin_SemesterId INT, SemesterId INT);

-- @templateIds values
INSERT INTO @templateIds (Id)
SELECT MetaTemplateId 
FROM MetaTemplate mt
	INNER JOIN MetaTemplateType mtt ON mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE EntityTypeId = 1
AND mtt.IsPresentationView = 0 -- Excludes reports

-- @tempSemester values
INSERT INTO @tempSemester
SELECT  
	  CourseId
	, ActualBegin_SemesterId
	, SemesterId
FROM CourseProposal cp
	
/* --------------------------------------------------------------
  Switch the values for ActualBegin_SemesterId and SemesterId 
-------------------------------------------------------------- */
UPDATE cp
SET 
	  ActualBegin_SemesterId = ts.SemesterId 
	, SemesterId = ts.ActualBegin_SemesterId
FROM CourseProposal cp
JOIN @tempSemester ts ON ts.CourseId = cp.CourseId 
-- Temp table variable needs an alias

/* --------------------------------------------------------------
    Change the backing store for Effective Term dropdown
-------------------------------------------------------------- */
UPDATE MetaSelectedField
SET MetaAvailableFieldId = 586    -- MAFId for CourseProposal.SemesterId
WHERE MetaAvailableFieldId = 610  -- MAFId for CourseProposal.ActualBegin_SemesterId
--AND DisplayName = 'Effective Term'

/* --------------------------------------------------------------
                  Update course templates
-------------------------------------------------------------- */
UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId IN (SELECT MetaTemplateId FROM @templateIds)