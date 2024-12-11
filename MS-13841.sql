USE [sjcc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13841';
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
DECLARE @MAX int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, LookupLoadTimingType)
VALUES
(@MAX, 'Program', 'Id', 'Title', 'SELECT Id AS Value, Title AS Text FROM LimitedAccess WHERE Active = 1', 'Select Id as Value, Title as Text from LimitedAccess where Id = @Id', 1),
(@MAX + 1, 'Course', 'Id', 'Title', 'SELECT Id AS Value, Title AS Text FROM SpecialDesignator WHERE Active = 1', 'Select Id as Value, Title as Text from SpecialDesignator where Id = @Id', 1)

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
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA in (2700, 2996))	--FMA is MetaAvailable Field		--Template Inactive, nothing using it

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 2466
, MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2682)	--FMA is MetaAvailable Field		--Distance Education Template 831 CCCCO Entry Tab

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 2463
, MetaForeignKeyLookupSourceId = @MAX + 1
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2057)	--FMA is MetaAvailable Field		--Times Repeatable Template 768 Course and Program... Tab

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 3102
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2692)	--FMA is MetaAvailable Field		--AA/Non AA Status Template 768 Course and Program... Tab

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 1345
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2693)	--FMA is MetaAvailable Field		--Area Template 768 Course and Program... Tab

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 2460
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2694)	--FMA is MetaAvailable Field		--Delivery Method Template 768 Units/Hours/Content Tab

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 594
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2695)	--FMA is MetaAvailable Field		--Advisory Reading and Writing Template 768 Advisory... Tab

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 3189
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2696)	--FMA is MetaAvailable Field		--Advisory Math Level: Template 768 Advisory... Tab

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 1431
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2697)	--FMA is MetaAvailable Field		--Course Type Template 768 Main Tab

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 3551
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2698)	--FMA is MetaAvailable Field		--Method of Instruction Template 768 Units/Hours/Content Tab

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 2702
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 3002)	--FMA is MetaAvailable Field		--Library Materials Template 768 Library Resources Tab

----------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO LimitedAccess
(Title, Description, ClientId, SortOrder, StartDate)
VALUES
('0%', '0%', 49, 1, GETDATE()),
('1-49%', '1-49%', 49, 2, GETDATE()),
('50-99%', '50-99%', 49, 3, GETDATE()),
('100%', '100%', 49, 4, GETDATE())

UPDATE Program
SET LimitedAccessId =
	CASE 
		WHEN gt.Text50001 = '0%' 
			THEN (SELECT Id FROM LimitedAccess WHERE Title = '0%')
		WHEN gt.Text50001 = '1-49%' 
			THEN (SELECT Id FROM LimitedAccess WHERE Title = '1-49%')
		WHEN gt.Text50001 = '50-99%' 
			THEN (SELECT Id FROM LimitedAccess WHERE Title = '50-99%')
		WHEN gt.Text50001 = '100%' 
			THEN (SELECT Id FROM LimitedAccess WHERE Title = '100%')
		ELSE NULL
	END
FROM Program AS p
INNER JOIN Generic500Text AS gt on gt.ProgramId = p.Id


UPDATE gt
SET Text50001 = NULL
FROM Generic500Text AS gt
INNER JOIN Program AS p on gt.ProgramId = p.Id

---------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CreditType
(Title, SortOrder, ClientId, StartDate)
VALUES
('Stand-Alone', 1, 49, GETDATE()),
('Part of Degree/Certificate', 2, 49, GETDATE())

UPDATE CourseProposal
SET CreditTypeId = 
	CASE
		WHEN gt.Text25506 = 'Stand-Alone' 
			THEN (SELECT Id FROM CreditType WHERE Title = 'Stand-Alone')
		WHEN gt.Text25506 = 'Part of Degree/Certificate' 
			THEN (SELECT Id FROM CreditType WHERE Title = 'Part of Degree/Certificate')
		ELSE NULL
	END
FROM CourseProposal AS cp
INNER JOIN Course AS c on cp.CourseId = c.Id
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id

Update gt
SET Text25506 = NULL
FROM Generic255Text AS gt
INNER JOIN Course AS c on gt.CourseId = c.Id

----------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO CoursePrefix
(Title, ClientId, SortOrder, StartDate)
VALUES
('Face-to-face only', 49, 1, GETDATE()),
('Hybrid only', 49, 2, GETDATE()),
('Online/hybrid', 49, 3, GETDATE())

UPDATE Course
SET CoursePrefixId = 
	CASE
		WHEN gt.Text25503 = 'Face-to-face only' 
			THEN (SELECT Id FROM CoursePrefix WHERE Description = 'Face-to-face only')
		WHEN gt.Text25503 = 'Hybrid only' 
			THEN (SELECT Id FROM CoursePrefix WHERE Description = 'Hybrid only')
		WHEN gt.Text25503 = 'Online/hybrid' 
			THEN (SELECT Id FROM CoursePrefix WHERE Description = 'Online/hybrid')
		ELSE NULL
	END
FROM Course AS c
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id

UPDATE gt
SET Text25503 = NULL
FROM Generic255Text AS gt
INNER JOIN Course AS c on gt.CourseId = c.Id
-----------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO ConsentOption
(Title, SortOrder, StartDate, ClientId)
VALUES
('Lecture', 1, GETDATE(), 49),
('Lecture/Lab', 2, GETDATE(), 49),
('Lab', 3, GETDATE(), 49)

UPDATE Course
SET ConsentOptionId = 
	CASE
		WHEN gt.Text25507 = 'Lecture' 
			THEN (SELECT Id FROM ConsentOption WHERE Title = 'Lecture')
		WHEN gt.Text25507 = 'Lecture/Lab' 
			THEN (SELECT Id FROM ConsentOption WHERE Title = 'Lecture/Lab')
		WHEN gt.Text25507 = 'Lab' 
			THEN (SELECT Id FROM ConsentOption WHERE Title = 'Lab')
		ELSE NULL
	END
FROM Course AS c
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id

UPDATE gt
SET Text25507 = NULL
FROM Generic255Text AS gt
INNER JOIN Course As c ON gt.CourseId = c.Id

----------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO LibraryImpact
(Title, StartDate, SortOrder, ClientId)
VALUES
('New library materials/resources are not required for this course at this time.', GETDATE(), 1, 49),
('I have reviewed the online catalog and library materials/resources for this course are sufficient at this time.', GETDATE(), 2, 49),
('The library needs to purchase additional materials/resources to support this course. (Please note that the library does not purchase textbooks.)', GETDATE(), 3, 49),
('Library materials/resources for this course are sufficient.', GETDATE(), 4, 49),
('Library materials/resources are not required for this course.', GETDATE(), 5, 49),
('I request that the librarian responsible for the subject area of this course contact me.', GETDATE(), 6, 49)

UPDATE EntityLibraryImpact
SET LibraryImpactId = 
	CASE
		WHEN gt.Text25518 = 'New library materials/resources are not required for this course at this time. ' 
			THEN (SELECT Id FROM LibraryImpact WHERE Title = 'New library materials/resources are not required for this course at this time.')
		WHEN gt.Text25518 = 'I have reviewed the online catalog and library materials/resources for this course are sufficient at this time.' 
			THEN (SELECT Id FROM LibraryImpact WHERE Title = 'I have reviewed the online catalog and library materials/resources for this course are sufficient at this time.')
		WHEN gt.Text25518 = 'The library needs to purchase additional materials/resources to support this course. (Please note that the library does not purchase textbooks.) ' 
			THEN (SELECT Id FROM LibraryImpact WHERE Title = 'The library needs to purchase additional materials/resources to support this course. (Please note that the library does not purchase textbooks.)')
		WHEN gt.Text25518 = ' The library needs to purchase additional materials/resources to support this course. (Please note that the library does not purchase textbooks.)' 
			THEN (SELECT Id FROM LibraryImpact WHERE Title = 'The library needs to purchase additional materials/resources to support this course. (Please note that the library does not purchase textbooks.)')
		WHEN gt.Text25518 = 'Library materials/resources for this course are sufficient.' 
			THEN (SELECT Id FROM LibraryImpact WHERE Title = 'Library materials/resources for this course are sufficient.')
		WHEN gt.Text25518 = 'Library materials/resources are not required for this course.' 
			THEN (SELECT Id FROM LibraryImpact WHERE Title = 'Library materials/resources are not required for this course.')
		WHEN gt.Text25518 = 'I request that the librarian responsible for the subject area of this course contact me.' 
			THEN (SELECT Id FROM LibraryImpact WHERE Title = 'I request that the librarian responsible for the subject area of this course contact me.')
		ELSE NULL
	END
FROM EntityLibraryImpact AS eli
INNER JOIN Course AS c on c.Id = eli.CourseId
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id

UPDATE gt
SET Text25518 = NULL
FROM Generic255Text AS gt
INNER JOIN Course AS c on gt.CourseId = c.Id

----------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO MathIntensity
(Title, SortOrder, ClientId, StartDate)
VALUES
('2 = completion of MATH 111 or equivalent', 1, 49, GETDATE()),
('3 = completion of MATH 13 or equivalent', 2, 49, GETDATE()),
('4 = completion of MATH (21 and 22) or 25 or equivalent', 3, 49, GETDATE()),
('5 = completion of MATH 71 (CALC I) or equivalent', 4, 49, GETDATE()),
('6 = completion of MATH 72 (CALC II) or equivalent', 5, 49, GETDATE()),
('7 = completion of MATH 73 (INT CALC) or equivalent', 6, 49, GETDATE())

UPDATE Course
SET MathIntensityId = 
	CASE 
		WHEN gt.Text25505 = '2 = completion of MATH 111 or equivalent'
			THEN (SELECT Id FROM MathIntensity WHERE Title = '2 = completion of MATH 111 or equivalent')
		WHEN gt.Text25505 = '3 = completion of MATH 13 or equivalent'
			THEN (SELECT Id FROM MathIntensity WHERE Title = '3 = completion of MATH 13 or equivalent')
		WHEN gt.Text25505 = '4 = completion of MATH (21 and 22) or 25 or equivalent'
			THEN (SELECT Id FROM MathIntensity WHERE Title = '4 = completion of MATH (21 and 22) or 25 or equivalent')
		WHEN gt.Text25505 = '5 = completion of MATH 71 (CALC I) or equivalent'
			THEN (SELECT Id FROM MathIntensity WHERE Title = '5 = completion of MATH 71 (CALC I) or equivalent')
		WHEN gt.Text25505 = '6 = completion of MATH 72 (CALC II) or equivalent'
			THEN (SELECT Id FROM MathIntensity WHERE Title = '6 = completion of MATH 72 (CALC II) or equivalent')
		WHEN gt.Text25505 = '7 = completion of MATH 73 (INT CALC) or equivalent'
			THEN (SELECT Id FROM MathIntensity WHERE Title = '7 = completion of MATH 73 (INT CALC) or equivalent')
		ELSE NULL
	END
FROM Course AS c
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id

UPDATE gt
SET Text25505 = NULL
FROM Generic255Text AS gt
INNER JOIN Course AS c on gt.CourseId = c.Id
----------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO RevisionType
(Title, SortOrder, ClientId, StartDate)
VALUES
('Read level 1 =  READ 350 (6 units) or ESL 313 or ENGL 321', 1, 49, GETDATE()),
('RW 2 = Completion of READ 301 or ESL 302 or ENGL 322 or equivalent OR Completion of ENGL 335 (4 units) or ENGL 330 or ESL 302 or equivalent', 2, 49, GETDATE()),
('RW 3 = Completion of READ 101 or ESL 091 (6 units) or ENGL 102 or equivalent OR Completion of ENGL 092 or ESL 091 (6 units) or ENGL 104 or equivalent', 3, 49, GETDATE()),
('RW4 = completion of ENGL 1A', 4, 49, GETDATE())

UPDATE CourseProposal
SET RevisionTypeId = 
	CASE
		WHEN gt.Text25504 = 'Read level 1 =  READ 350 (6 units) or ESL 313 or ENGL 321'
			THEN (SELECT Id FROM RevisionType WHERE Title = 'Read level 1 =  READ 350 (6 units) or ESL 313 or ENGL 321')
		WHEN gt.Text25504 = 'RW 2 = Completion of READ 301 or ESL 302 or ENGL 322 or equivalent OR Completion of ENGL 335 (4 units) or ENGL 330 or ESL 302 or equivalent'
			THEN (SELECT Id FROM RevisionType WHERE Title = 'RW 2 = Completion of READ 301 or ESL 302 or ENGL 322 or equivalent OR Completion of ENGL 335 (4 units) or ENGL 330 or ESL 302 or equivalent')
		WHEN gt.Text25504 = 'RW 3 = Completion of READ 101 or ESL 091 (6 units) or ENGL 102 or equivalent OR Completion of ENGL 092 or ESL 091 (6 units) or ENGL 104 or equivalent'
			THEN (SELECT Id FROM RevisionType WHERE Title = 'RW 3 = Completion of READ 101 or ESL 091 (6 units) or ENGL 102 or equivalent OR Completion of ENGL 092 or ESL 091 (6 units) or ENGL 104 or equivalent')
		WHEN gt.Text25504 = 'RW4 = completion of ENGL 1A'
			THEN (SELECT Id FROM RevisionType WHERE Title = 'RW4 = completion of ENGL 1A')
		ELSE NULL
	END
FROM CourseProposal AS cp
INNER JOIN Course AS c on cp.CourseId = c.Id
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id

UPDATE gt
SET Text25504 = NULL
FROM Generic255Text AS gt
INNER JOIN Course AS c on gt.CourseId = c.Id
----------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO GeneralEducationArea
(Title, SortOrder, ClientId, StartDate)
VALUES
('Reading levels below Engl 1A', 1, 49, GETDATE()),
('Writing levels below Engl 1A', 2, 49, GETDATE()),
('Math levels below Math 21/22/23', 3, 49, GETDATE()),
('ESL levels below Engl 1A', 4, 49, GETDATE())

UPDATE Course
SET GeneralEducationAreaId =
	CASE
		WHEN gt.Text25502 = 'Reading levels below Engl 1A'
			THEN (SELECT Id FROM GeneralEducationArea WHERE Title = 'Reading levels below Engl 1A')
		WHEN gt.Text25502 = 'Writing levels below Engl 1A'
			THEN (SELECT Id FROM GeneralEducationArea WHERE Title = 'Writing levels below Engl 1A')
		WHEN gt.Text25502 = 'Math levels below Math 21/22/23'
			THEN (SELECT Id FROM GeneralEducationArea WHERE Title = 'Math levels below Math 21/22/23')
		WHEN gt.Text25502 = 'ESL levels below Engl 1A'
			THEN (SELECT Id FROM GeneralEducationArea WHERE Title = 'ESL levels below Engl 1A')
		ELSE NULL
	END
FROM Course AS c
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id

UPDATE gt
SET Text25502 = NULL
FROM Generic255Text AS gt
INNER JOIN Course As c on gt.CourseId = c.Id
----------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO GeneralEducationIaiCode
(Code, SortOrder, StartDate, ClientId)
VALUES
('AA and AS Applicable (AA)', 1, GETDATE(), 49),
('AS Applicable (AS)', 2, GETDATE(), 49),
('Non AA/AS Applicable (NAA)', 3, GETDATE(), 49),
('Non Credit/0 Unit (NC)', 4, GETDATE(), 49),
('Non Credit (not Comm. Serv.) (NONC)', 5, GETDATE(), 49)

UPDATE Course
SET GeneralEducationIaiCodeId =
	CASE
		WHEN gt.Text25501 = 'AA and AS Applicable (AA)'
			THEN (SELECT Id FROM GeneralEducationIaiCode WHERE Code = 'AA and AS Applicable (AA)')
		WHEN gt.Text25501 = 'AS Applicable (AS)'
			THEN (SELECT Id FROM GeneralEducationIaiCode WHERE Code = 'AS Applicable (AS)')
		WHEN gt.Text25501 = 'Non AA/AS Applicable (NAA)'
			THEN (SELECT Id FROM GeneralEducationIaiCode WHERE Code = 'Non AA/AS Applicable (NAA)')
		WHEN gt.Text25501 = 'Non Credit/0 Unit (NC)'
			THEN (SELECT Id FROM GeneralEducationIaiCode WHERE Code = 'Non Credit/0 Unit (NC)')
		WHEN gt.Text25501 = 'Non Credit (not Comm. Serv.) (NONC)'
			THEN (SELECT Id FROM GeneralEducationIaiCode WHERE Code = 'Non Credit (not Comm. Serv.) (NONC)')
		ELSE NULL
	END
FROM Course AS c
INNER JOIN Generic255Text AS gt on gt.CourseId = c.Id

UPDATE gt
SET Text25501 = NULL
FROM Generic255Text AS gt
INNER JOIN Course As c on gt.CourseId = c.Id
----------------------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO SpecialDesignator
(Title, ClientId, SortOrder, StartDate)
VALUES
('0', 49, 1, GETDATE()),
('1', 49, 2, GETDATE()),
('2', 49, 3, GETDATE()),
('3', 49, 4, GETDATE()),
('4', 49, 5, GETDATE()),
('5', 49, 6, GETDATE()),
('6', 49, 7, GETDATE()),
('7', 49, 8, GETDATE()),
('8', 49, 9, GETDATE()),
('9', 49, 10, GETDATE()),
('11', 49, 11, GETDATE()),
('15', 49, 12, GETDATE()),
('17', 49, 13, GETDATE()),
('19', 49, 14, GETDATE())

UPDATE Course
SET SpecialDesignatorId =
	CASE
		WHEN cp.RepeatText = '0'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '0')
		WHEN cp.RepeatText = '1'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '1')
		WHEN cp.RepeatText = '2'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '2')
		WHEN cp.RepeatText = '3'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '3')
		WHEN cp.RepeatText = '4'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '4')
		WHEN cp.RepeatText = '5'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '5')
		WHEN cp.RepeatText = '6'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '6')
		WHEN cp.RepeatText = '7'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '7')
		WHEN cp.RepeatText = '8'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '8')
		WHEN cp.RepeatText = '9'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '9')
		WHEN cp.RepeatText = '11'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '11')
		WHEN cp.RepeatText = '15'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '15')
		WHEN cp.RepeatText = '17'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '17')
		WHEN cp.RepeatText = '19'
			THEN (SELECT Id FROM SpecialDesignator WHERE Title = '19')
		ELSE NULL
	END
FROM Course AS c
INNER JOIN CourseProposal AS cp on c.Id = cp.CourseId

UPDATE CourseProposal
SET RepeatText = NULL
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