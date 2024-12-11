USE [zu];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13848';
DECLARE @Comments nvarchar(Max) = 
	'Update Literal DropDowns';
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
DECLARE @Templates TABLE (TId int, FId int, FMA int)
INSERT INTO @Templates (TId, FId, FMA)
SELECT mt.MetaTemplateId, Msf.MetaSelectedFieldId, msf.MetaAvailableFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE msf.MetaPresentationTypeId = 101

DELETE FROM MetaLiteralList
WHERE MetaSelectedFieldId in (Select FId FROM @Templates)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA in (2147))	--FMA is MetaAvailable Field		--Template Inactive, nothing using it

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 2459
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 3003)	--FMA is MetaAvailable Field

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 2463
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 3004)	--FMA is MetaAvailable Field
--------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO DisciplineType
(Title, ClientId, SortOrder, StartDate)
VALUES
('Undergraduate', 57, 1, GETDATE()),
('Graduate', 57, 2, GETDATE()),
('Pre-Baccalaureate', 57, 3, GETDATE())

UPDATE Course
SET DisciplineTypeId = 
	CASE
		WHEN gt.Text25519 = 'Undergraduate'
			THEN (SELECT Id FROM DisciplineType WHERE Title = 'Undergraduate')
		WHEN gt.Text25519 = 'Graduate'
			THEN (SELECT Id FROM DisciplineType WHERE Title = 'Undergraduate')
		WHEN gt.Text25519 = 'Pre-Baccalaureate'
			THEN (SELECT Id FROM DisciplineType WHERE Title = 'Pre-Baccalaureate')
		ELSE NULL
	END
FROM Course AS C
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id
---------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO SpecialDesignator
(Title, ClientId, SortOrder, StartDate)
VALUES
('Term', 57, 1, GETDATE()),
('Full Semester', 57, 2, GETDATE()),
('Either', 57, 3, GETDATE()),
('Other', 57, 4, GETDATE())

UPDATE Course
SET SpecialDesignatorId = 
	CASE
		WHEN gt.Text25520 = 'Term'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = 'Term')
		WHEN gt.Text25520 = 'Full Semester'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = 'Full Semester')
		WHEN gt.Text25520 = 'Either'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = 'Either')
		WHEN gt.Text25520 = 'Other'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = 'Other')
		ELSE NULL
	END
FROM Course AS C
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id
---------------------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE gt
SET Text25519 = NULL
, Text25520 = NULL
FROM Generic255Text As gt
INNER JOIN Course As c on gt.CourseId = c.Id
---------------------------------------------------------------------------------------------------------------------------------------------------------------
DELETE FROM MetaLiteralList
WHERE MetaSelectedFieldId NOT IN (
	SELECT MetaSelectedFieldId FROM MetaSelectedField AS msf		--Just to ensure everything that is not type 101 has no literal list record
		WHERE MetaPresentationTypeId = 101
)
----------------------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT TId FROM @Templates
)

--commit