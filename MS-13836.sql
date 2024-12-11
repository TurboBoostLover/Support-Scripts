USE [riohondo];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13836';
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

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 1345
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2701)	--FMA is MetaAvailable Field		--transfer apps on metatemplate 812 on course cover sheet

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 3103
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2693)	--FMA is MetaAvailable Field		--demo of neeed metatemplate 820 on course cover sheet

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 3103
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2692)	--FMA is MetaAvailable Field		--demo of need metatemplate 822 on course cover sheet

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2109)	--FMA is MetaAvailable Field		--catalog year metatemplate NONE and inactive

INSERT INTO IaiCode
(Code, SortOrder, StartDate, ClientId)
VALUES
('Manpower needs projections from the California Occupational Information', 1, GETDATE(), 6),
('System (COTS) or the Employment Development Department', 2, GETDATE(), 6),
('Survey of community and/or student needs or interest', 3, GETDATE(), 6),
('Administrative Judgement', 4, GETDATE(), 6),
('Student or community petition or demand for program/course', 5, GETDATE(), 6),
('State licensing and/or certification and mandation', 6, GETDATE(), 6)

UPDATE Course
SET IaiCodeId = 
	CASE 
		WHEN gt.Text25501 = 'Manpower needs projections from the California Occupational Information' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'Manpower needs projections from the California Occupational Information')
		WHEN gt.Text25501 = 'System (COTS) or the Employment Development Department' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'System (COTS) or the Employment Development Department')
		WHEN gt.Text25501 = 'Survey of community and/or student needs or interest' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'Survey of community and/or student needs or interest')
		WHEN gt.Text25501 = 'Administrative Judgement' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'Administrative Judgement')
		WHEN gt.Text25501 = 'Student or community petition or demand for program/course' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'Student or community petition or demand for program/course')
		WHEN gt.Text25501 = 'State licensing and/or certification and mandation'
			THEN (SELECT Id FROM IaiCode WHERE Code = 'State licensing and/or certification and mandation')
		ELSE NULL
	END
FROM Course AS c
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id
INNER JOIN MetaTemplate AS mt on c.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2693

UPDATE Course
SET IaiCodeId = 
	CASE 
		WHEN gt.Text25502 = 'Manpower needs projections from the California Occupational Information' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'Manpower needs projections from the California Occupational Information')
		WHEN gt.Text25502 = 'System (COTS) or the Employment Development Department' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'System (COTS) or the Employment Development Department')
		WHEN gt.Text25502 = 'Survey of community and/or student needs or interest' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'Survey of community and/or student needs or interest')
		WHEN gt.Text25502 = 'Administrative Judgement' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'Administrative Judgement')
		WHEN gt.Text25502 = 'Student or community petition or demand for program/course' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'Student or community petition or demand for program/course')
		WHEN gt.Text25502 = 'State licensing and/or certification and mandation' 
			THEN (SELECT Id FROM IaiCode WHERE Code = 'State licensing and/or certification and mandation')
		ELSE NULL
	END
FROM Course AS c
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id
INNER JOIN MetaTemplate AS mt on c.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2692

INSERT INTO GeneralEducationArea
(Title, SortOrder, ClientId, StartDate)
VALUES
('CSU', 1, 6, GETDATE()),
('UC', 2, 6, GETDATE()),
('UC/CSU', 3, 6, GETDATE()),
('Restricted', 4, 6, GETDATE())

UPDATE Course
SET GeneralEducationAreaId = 
	CASE
		WHEN gt.Text25510 = 'CSU' THEN (SELECT Id FROM GeneralEducationArea WHERE Title = 'CSU')
		WHEN gt.Text25510 = 'UC' THEN (SELECT Id FROM GeneralEducationArea WHERE Title = 'UC')
		WHEN gt.Text25510 = 'UC/CSU' THEN (SELECT Id FROM GeneralEducationArea WHERE Title = 'UC/CSU')
		WHEN gt.Text25510 = 'Restricted' THEN (SELECT Id FROM GeneralEducationArea WHERE Title = 'Restricted')
		ELSE NULL
	END
FROM Course AS c
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT TId FROM @Templates
)