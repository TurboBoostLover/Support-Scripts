USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18437';
DECLARE @Comments nvarchar(Max) = 
	'Update PDS Report';
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
UPDATE MetaReport
SET ReportAttributes = '
{"isPublicReport":false,"reportTemplateId":25,"fieldRenderingStrategy":"HideEmptyFields","sectionRenderingStrategy":"HideEmptySections", "cssOverride":"@media print {h3, .h3 {font-size: 1.25rem; margin-top: 0; margin-bottom: 0;} .tg {width: 800 !important; min-width: 0;} th {font-size: 12px !important;} td {font-size: 12px !important;}} .h4, h4{font-size: 1.05rem} .h5, h5{font-size: 0.95rem} label, .h1, .h2, .h3, .h4, .h5, .h6, h1, h2, h3, h4, h5, h6 {font-weight: 600;} .col-md-12{break-inside: avoid;} b{font-weight:600} th{font-weight:500}"}
'
WHERE Id = 452

UPDATE MetaReport
SET ReportAttributes = '
{"isPublicReport":false,"reportTemplateId":25,"fieldRenderingStrategy":"HideEmptyFields","sectionRenderingStrategy":"HideEmptySections", "cssOverride":"@media print {h3, .h3 {font-size: 1.25rem; margin-top: 0; margin-bottom: 0;} .tg {width: 800 !important;  min-width: 0;} th {font-size: 12px !important;} td {font-size: 12px !important;}} .h4, h4{font-size: 1.05rem} .h5, h5{font-size: 0.95rem} label, .h1, .h2, .h3, .h4, .h5, .h6, h1, h2, h3, h4, h5, h6 {font-weight: 600;} .col-md-12{break-inside: avoid;} b{font-weight:600} th{font-weight:500}"}
'
WHERE Id = 462

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
SELECT Id as [Value],
	CASE 
	WHEN ChangeRequest IS NOT NULL THEN CONCAT(''<br>Local applicants'', SamplePrograms)
	END AS [Text]
FROM Program
WHERE Id = @entityId
'
, ResolutionSql = '
SELECT Id as [Value],
	CASE 
	WHEN ChangeRequest IS NOT NULL THEN CONCAT(''<br>Local applicants'', SamplePrograms)
	END AS [Text]
FROM Program
WHERE Id = @entityId
'
WHERE Id = 244

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @title NVARCHAR(MAX) = ''<br><p>Table 2.2 PILOs</p>''
DECLARE @tbody NVARCHAR(MAX) = ''<table style="border-collapse: collapse; width: 100%;"><tbody>''

DECLARE @Outcomes table (Outcome NVARCHAR(MAX), SortOrder INT)

INSERT INTO @Outcomes
SELECT Outcome, ROW_NUMBER() OVER (ORDER BY SortOrder, Id) AS SortOrder
FROM ProgramOutcome 
WHERE ProgramId = @entityId

DECLARE @totalOutcomes INT = (SELECT COUNT(*) FROM @Outcomes)

IF(@totalOutcomes > 0)
BEGIN
    -- Generate the left cell with rowspan and all outcomes in the right cell
    SET @tbody += CONCAT(
        ''<tr>'',
        ''<td style="border: 1px solid black; padding: 5px;" rowspan="'', @totalOutcomes, ''">PILOs</td>'',
        ''<td style="border: 1px solid black; padding: 5px;">''
    )

    -- Concatenate all outcomes into a single cell
    SELECT @tbody += CONCAT(Outcome, ''<br>'')
    FROM @Outcomes

    -- Close the table row
    SET @tbody += ''</td></tr>''

    -- Close the table
    SET @tbody += ''</tbody></table>''

    SELECT 0 AS Value, CONCAT(@title, @tbody, ''<br>'') AS Text
END

'
, ResolutionSql = '
DECLARE @title NVARCHAR(MAX) = ''<br><p>Table 2.2 PILOs</p>''
DECLARE @tbody NVARCHAR(MAX) = ''<table style="border-collapse: collapse; width: 100%;"><tbody>''

DECLARE @Outcomes table (Outcome NVARCHAR(MAX), SortOrder INT)

INSERT INTO @Outcomes
SELECT Outcome, ROW_NUMBER() OVER (ORDER BY SortOrder, Id) AS SortOrder
FROM ProgramOutcome 
WHERE ProgramId = @entityId

DECLARE @totalOutcomes INT = (SELECT COUNT(*) FROM @Outcomes)

IF(@totalOutcomes > 0)
BEGIN
    -- Generate the left cell with rowspan and all outcomes in the right cell
    SET @tbody += CONCAT(
        ''<tr>'',
        ''<td style="border: 1px solid black; padding: 5px;" rowspan="'', @totalOutcomes, ''">PILOs</td>'',
        ''<td style="border: 1px solid black; padding: 5px;">''
    )

    -- Concatenate all outcomes into a single cell
    SELECT @tbody += CONCAT(Outcome, ''<br>'')
    FROM @Outcomes

    -- Close the table row
    SET @tbody += ''</td></tr>''

    -- Close the table
    SET @tbody += ''</tbody></table>''

    SELECT 0 AS Value, CONCAT(@title, @tbody, ''<br>'') AS Text
END

'
WHERE Id = 230

UPDATE MetaSelectedSection
SET SectionDescription = 'Applicants have to fulfil the following minimum admission requirements:'
WHERE MetaSelectedSectionId = 1110

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @title NVARCHAR(MAX) = ''<br><p>Table 2.1 POs</p>''
DECLARE @tbody NVARCHAR(MAX) = ''<table style="border-collapse: collapse; width: 100%;"><tbody>''

DECLARE @Objectives table (Text NVARCHAR(MAX), SortOrder INT)

INSERT INTO @Objectives
SELECT Text, ROW_NUMBER() OVER (ORDER BY SortOrder, Id) AS SortOrder
FROM ProgramObjective 
WHERE ProgramId = @entityId

DECLARE @totalObjectives INT = (SELECT COUNT(*) FROM @Objectives)

IF(@totalObjectives > 0)
BEGIN
    -- Generate the left cell with rowspan and all objectives in the right cell
    SET @tbody += CONCAT(
        ''<tr>'',
        ''<td style="border: 1px solid black; padding: 5px;" rowspan="'', @totalObjectives, ''">Programme Objectives</td>'',
        ''<td style="border: 1px solid black; padding: 5px;">''
    )

    -- Concatenate all objectives into a single cell
    SELECT @tbody += CONCAT(Text, ''<br>'')
    FROM @Objectives

    -- Close the table row
    SET @tbody += ''</td></tr>''

    -- Close the table
    SET @tbody += ''</tbody></table>''

    SELECT 0 AS Value, CONCAT(@title, @tbody, ''<br>'') AS Text
END

'
, ResolutionSql = '
DECLARE @title NVARCHAR(MAX) = ''<br><p>Table 2.1 POs</p>''
DECLARE @tbody NVARCHAR(MAX) = ''<table style="border-collapse: collapse; width: 100%;"><tbody>''

DECLARE @Objectives table (Text NVARCHAR(MAX), SortOrder INT)

INSERT INTO @Objectives
SELECT Text, ROW_NUMBER() OVER (ORDER BY SortOrder, Id) AS SortOrder
FROM ProgramObjective 
WHERE ProgramId = @entityId

DECLARE @totalObjectives INT = (SELECT COUNT(*) FROM @Objectives)

IF(@totalObjectives > 0)
BEGIN
    -- Generate the left cell with rowspan and all objectives in the right cell
    SET @tbody += CONCAT(
        ''<tr>'',
        ''<td style="border: 1px solid black; padding: 5px;" rowspan="'', @totalObjectives, ''">Programme Objectives</td>'',
        ''<td style="border: 1px solid black; padding: 5px;">''
    )

    -- Concatenate all objectives into a single cell
    SELECT @tbody += CONCAT(Text, ''<br>'')
    FROM @Objectives

    -- Close the table row
    SET @tbody += ''</td></tr>''

    -- Close the table
    SET @tbody += ''</tbody></table>''

    SELECT 0 AS Value, CONCAT(@title, @tbody, ''<br>'') AS Text
END

'
WHERE Id = 229

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
-- Step 1: Perform calculations
DECLARE @calculations TABLE (psid INT, ContactHours INT, NotionalLearningHours INT)

INSERT INTO @calculations
SELECT 
    ps.Id,
    CD.MinLectureHour AS ContactHours, 
    CD.MinLabHour AS NotionalLearningHours
FROM ProgramSequence ps		
    LEFT JOIN ProgramSequence child ON ps.Id = child.Parent_Id
    LEFT JOIN Course C ON C.Id = ps.CourseId
    LEFT JOIN CourseDescription CD ON CD.CourseId = C.Id
WHERE ps.ProgramId = @entityId
    AND child.Id IS NULL

DECLARE @GotAll BIT = CASE 
    WHEN EXISTS (
        SELECT * 
        FROM ProgramSequence ps 
        LEFT JOIN @Calculations c ON ps.Id = c.psID 
        WHERE c.psID IS NULL AND ps.ProgramId = @entityId
    ) THEN 0
    ELSE 1
END

WHILE (@GotAll = 0)
BEGIN
    INSERT INTO @calculations
    SELECT 
        ps.Id,
        CASE
            WHEN ps.GroupConditionId IS NULL OR ps.GroupConditionId = 1 THEN SUM(c.ContactHours)
            WHEN ps.GroupConditionId = 2 THEN MAX(c.ContactHours)
            ELSE MAX(c.ContactHours)
        END AS ContactHours,
        CASE
            WHEN ps.GroupConditionId IS NULL OR ps.GroupConditionId = 1 THEN SUM(c.NotionalLearningHours)
            WHEN ps.GroupConditionId = 2 THEN MAX(c.NotionalLearningHours)
            ELSE MAX(c.NotionalLearningHours)
        END AS NotionalLearningHours
    FROM ProgramSequence ps		
        LEFT JOIN ProgramSequence child ON ps.Id = child.Parent_Id
        LEFT JOIN @calculations c ON child.Id = c.psid
    WHERE ps.ProgramId = @entityId
        AND ps.Id NOT IN (SELECT c2.psID FROM @Calculations c2)
        AND NOT EXISTS (
            SELECT * 
            FROM ProgramSequence ps2
            WHERE ps2.Parent_Id = ps.Id
                AND ps2.Id NOT IN (SELECT c2.psID FROM @Calculations c2)
        )
    GROUP BY ps.Id, ps.GroupConditionId

    SET @GotAll = CASE 
        WHEN EXISTS (
            SELECT * 
            FROM ProgramSequence ps 
            LEFT JOIN @Calculations c ON ps.Id = c.psID 
            WHERE c.psID IS NULL AND ps.ProgramId = @entityId
        ) THEN 0
        ELSE 1
    END
END

-- Step 2: Create and populate the MajorsSpecialisationsCourseOptions table
DECLARE @MajorsSpecialisationsCourseOptions TABLE (
    Id INT IDENTITY(1,1),
    MajorId INT,
    MajorTitle NVARCHAR(MAX),
    MajorDescription NVARCHAR(MAX),
    SpecialisationId INT,
    SpecialisationTitle NVARCHAR(MAX),
    SortOrder INT,
    TotalContactHours INT,
    TotalNotionalLearningHours INT
)

INSERT INTO @MajorsSpecialisationsCourseOptions
SELECT 
    major.Id,
    major.Title,
    '''',
    Specialisation.Id,
    Specialisation.Title,
    ROW_NUMBER() OVER (ORDER BY pl.SortOrder),
    MAX(c.ContactHours),
    MAX(c.NotionalLearningHours)
FROM ProgramLookup14 pl
    LEFT JOIN Lookup14 major ON pl.Parent_Lookup14Id = major.Id
    LEFT JOIN Lookup14 Specialisation ON pl.Lookup14Id = Specialisation.Id
    LEFT JOIN ProgramSequence ps ON ps.Lookup14Id = Major.Id
    LEFT JOIN @calculations c ON ps.Id = c.psid
WHERE pl.ProgramId = @entityId
GROUP BY major.Id, major.Title, Specialisation.Id, Specialisation.Title, pl.SortOrder

-- Step 3: Retrieve Medium of Instruction
DECLARE @MediumofInstruction NVARCHAR(MAX) = (
    SELECT PC.Title
    FROM Program P
    INNER JOIN ProgramCode PC ON PC.Id = P.ProgramCodeId
    WHERE P.Id = @entityId
)

-- Step 4: Initialize @tbody as NVARCHAR
DECLARE @tbody NVARCHAR(MAX) = ''<table style="border-collapse: collapse; width: 100%;"><thead>''
SET @tbody += CONCAT(
    ''<tr>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 25%;">Majors</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 25%;">Specialisations</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 15%;">Contact Hours (CH)</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 15%;">Notional Learning Hours (NLH)</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 20%;">Medium of Instruction (MOI)</th>'',
    ''</tr></thead><tbody>''
)

-- Declare rows to store the formatted HTML rows
DECLARE @rows NVARCHAR(MAX) = ''''

-- Add data rows for Majors and Specialisations
SELECT @rows += CONCAT(
    ''<tr>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(MajorTitle, ''&nbsp;''), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(SpecialisationTitle, ''&nbsp;''), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(TotalContactHours, 0), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(TotalNotionalLearningHours, 0), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(@MediumofInstruction, ''&nbsp;''), ''</td>'',
    ''</tr>''
)
FROM @MajorsSpecialisationsCourseOptions

-- Add explanatory rows below the data
SET @rows += CONCAT(
    ''<tr>'',
    ''<td style="border: 1px solid black; padding: 5px;">Ratio of CH to Self-study Hours</td>'',
    ''<td colspan="4" style="border: 1px solid black; padding: 5px;">'',
    ''Please refer to relevant policy concerning Credit Allocation Type (CAT) in the Policy Manual and Operational Guide and CAT Type per course in Appendix 4.1'',
    ''</td>'',
    ''</tr>''
)

-- Combine table structure and rows
SET @tbody += @rows
SET @tbody += ''</tbody></table>''

-- Output the result
SELECT 0 AS Value, CONCAT(@tbody, ''<br>'') AS Text
'
, ResolutionSql = '
-- Step 1: Perform calculations
DECLARE @calculations TABLE (psid INT, ContactHours INT, NotionalLearningHours INT)

INSERT INTO @calculations
SELECT 
    ps.Id,
    CD.MinLectureHour AS ContactHours, 
    CD.MinLabHour AS NotionalLearningHours
FROM ProgramSequence ps		
    LEFT JOIN ProgramSequence child ON ps.Id = child.Parent_Id
    LEFT JOIN Course C ON C.Id = ps.CourseId
    LEFT JOIN CourseDescription CD ON CD.CourseId = C.Id
WHERE ps.ProgramId = @entityId
    AND child.Id IS NULL

DECLARE @GotAll BIT = CASE 
    WHEN EXISTS (
        SELECT * 
        FROM ProgramSequence ps 
        LEFT JOIN @Calculations c ON ps.Id = c.psID 
        WHERE c.psID IS NULL AND ps.ProgramId = @entityId
    ) THEN 0
    ELSE 1
END

WHILE (@GotAll = 0)
BEGIN
    INSERT INTO @calculations
    SELECT 
        ps.Id,
        CASE
            WHEN ps.GroupConditionId IS NULL OR ps.GroupConditionId = 1 THEN SUM(c.ContactHours)
            WHEN ps.GroupConditionId = 2 THEN MAX(c.ContactHours)
            ELSE MAX(c.ContactHours)
        END AS ContactHours,
        CASE
            WHEN ps.GroupConditionId IS NULL OR ps.GroupConditionId = 1 THEN SUM(c.NotionalLearningHours)
            WHEN ps.GroupConditionId = 2 THEN MAX(c.NotionalLearningHours)
            ELSE MAX(c.NotionalLearningHours)
        END AS NotionalLearningHours
    FROM ProgramSequence ps		
        LEFT JOIN ProgramSequence child ON ps.Id = child.Parent_Id
        LEFT JOIN @calculations c ON child.Id = c.psid
    WHERE ps.ProgramId = @entityId
        AND ps.Id NOT IN (SELECT c2.psID FROM @Calculations c2)
        AND NOT EXISTS (
            SELECT * 
            FROM ProgramSequence ps2
            WHERE ps2.Parent_Id = ps.Id
                AND ps2.Id NOT IN (SELECT c2.psID FROM @Calculations c2)
        )
    GROUP BY ps.Id, ps.GroupConditionId

    SET @GotAll = CASE 
        WHEN EXISTS (
            SELECT * 
            FROM ProgramSequence ps 
            LEFT JOIN @Calculations c ON ps.Id = c.psID 
            WHERE c.psID IS NULL AND ps.ProgramId = @entityId
        ) THEN 0
        ELSE 1
    END
END

-- Step 2: Create and populate the MajorsSpecialisationsCourseOptions table
DECLARE @MajorsSpecialisationsCourseOptions TABLE (
    Id INT IDENTITY(1,1),
    MajorId INT,
    MajorTitle NVARCHAR(MAX),
    MajorDescription NVARCHAR(MAX),
    SpecialisationId INT,
    SpecialisationTitle NVARCHAR(MAX),
    SortOrder INT,
    TotalContactHours INT,
    TotalNotionalLearningHours INT
)

INSERT INTO @MajorsSpecialisationsCourseOptions
SELECT 
    major.Id,
    major.Title,
    '''',
    Specialisation.Id,
    Specialisation.Title,
    ROW_NUMBER() OVER (ORDER BY pl.SortOrder),
    MAX(c.ContactHours),
    MAX(c.NotionalLearningHours)
FROM ProgramLookup14 pl
    LEFT JOIN Lookup14 major ON pl.Parent_Lookup14Id = major.Id
    LEFT JOIN Lookup14 Specialisation ON pl.Lookup14Id = Specialisation.Id
    LEFT JOIN ProgramSequence ps ON ps.Lookup14Id = Major.Id
    LEFT JOIN @calculations c ON ps.Id = c.psid
WHERE pl.ProgramId = @entityId
GROUP BY major.Id, major.Title, Specialisation.Id, Specialisation.Title, pl.SortOrder

-- Step 3: Retrieve Medium of Instruction
DECLARE @MediumofInstruction NVARCHAR(MAX) = (
    SELECT PC.Title
    FROM Program P
    INNER JOIN ProgramCode PC ON PC.Id = P.ProgramCodeId
    WHERE P.Id = @entityId
)

-- Step 4: Initialize @tbody as NVARCHAR
DECLARE @tbody NVARCHAR(MAX) = ''<table style="border-collapse: collapse; width: 100%;"><thead>''
SET @tbody += CONCAT(
    ''<tr>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 25%;">Majors</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 25%;">Specialisations</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 15%;">Contact Hours (CH)</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 15%;">Notional Learning Hours (NLH)</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 20%;">Medium of Instruction (MOI)</th>'',
    ''</tr></thead><tbody>''
)

-- Declare rows to store the formatted HTML rows
DECLARE @rows NVARCHAR(MAX) = ''''

-- Add data rows for Majors and Specialisations
SELECT @rows += CONCAT(
    ''<tr>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(MajorTitle, ''&nbsp;''), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(SpecialisationTitle, ''&nbsp;''), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(TotalContactHours, 0), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(TotalNotionalLearningHours, 0), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(@MediumofInstruction, ''&nbsp;''), ''</td>'',
    ''</tr>''
)
FROM @MajorsSpecialisationsCourseOptions

-- Add explanatory rows below the data
SET @rows += CONCAT(
    ''<tr>'',
    ''<td style="border: 1px solid black; padding: 5px;">Ratio of CH to Self-study Hours</td>'',
    ''<td colspan="4" style="border: 1px solid black; padding: 5px;">'',
    ''Please refer to relevant policy concerning Credit Allocation Type (CAT) in the Policy Manual and Operational Guide and CAT Type per course in Appendix 4.1'',
    ''</td>'',
    ''</tr>''
)

-- Combine table structure and rows
SET @tbody += @rows
SET @tbody += ''</tbody></table>''

-- Output the result
SELECT 0 AS Value, CONCAT(@tbody, ''<br>'') AS Text
'
WHERE Id = 234

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '


declare @title NVARCHAR(max)
declare @awardGrantingBody NVARCHAR(max)
declare @primaryAreaStudy NVARCHAR(max)
declare @subAreaStudy NVARCHAR(max)
declare @otherAreaStudy NVARCHAR(max)
declare @programmeLength NVARCHAR(max)
declare @academyCredit NVARCHAR(max)
declare @QFCredit NVARCHAR(max)
declare @QFLevel NVARCHAR(max)
declare @launchYear NVARCHAR(max)
declare @launchMonth NVARCHAR(max)
declare @targetStudents NVARCHAR(max)
declare @studentIntakesPerYear NVARCHAR(max)
declare @studentsPerIntake NVARCHAR(max)

select @title = Title from Program
where Id = @entityId

select @awardGrantingBody = lr.Text	
	from ProgramDetail pd 
		inner join LettersOfRecommendationRequirement lr on pd.LettersOfRecommendationRequirementId = lr.Id
	where pd.ProgramId = @entityId

select @primaryAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.First_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @subAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.Second_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @otherAreaStudy = CareerOption 
from Program
where Id = @entityId

select @programmeLength = cc.Title
from Program p
	inner join CategoryCode cc on p.CategoryCodeId = cc.Id
where p.Id = @entityId

select @academyCredit = Int05 
from GenericInt
where ProgramId = @entityId

select @QFCredit = ICCBCreditHours 
from Program
where Id = @entityId

select @QFLevel = qfl.Title
from Program p
	inner join QFLevel qfl on p.QFLevelId = qfl.Id
where p.Id = @entityId

select @launchYear = StartYear 
from ProgramProposal
where ProgramId = @entityId

select  @launchMonth = m.MonthName
from Program p
	inner join Months m on m.Id = p.StartMonth
where p.Id = @entityId

select @targetStudents = EntranceRequirementsText 
from program
where Id = @entityId

select @studentIntakesPerYear = ClassStaffCount
from Program
where Id = @entityId

select @studentsPerIntake = CertificationStaffCount
from Program
where Id = @entityId

DECLARE @modesOfDelivery NVARCHAR(MAX) = (SELECT dbo.ConcatWithSepOrdered_Agg('''', dm.Id, CONCAT(''<li style ="list-style-type: none;">'',dm.Title,''</li>''))
	FROM ProgramDeliveryMethod pdm
		INNER JOIN DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
	WHERE ProgramId = @entityId )

DECLARE @tbody NVARCHAR(MAX) = (CONCAT(
''<table style="border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; font-size: 14px;">'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Programme Title</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@title, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Award Granting Body</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@awardGrantingBody, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Mode of Delivery</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@modesOfDelivery, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Primary Area of Study / Training</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@primaryAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Sub Area of Study / Training</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@subAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Other Area of Study / Training (if any)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@otherAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Programme Length</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@programmeLength, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Academy Credit</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@academyCredit, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">QF Credits</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QFCredit, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">QF Level</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QFLevel, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Planned Programme Launch Date</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@launchMonth, ''&nbsp;''), '', '', ISNULL(@launchYear, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Target Students</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@targetStudents, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Number of Student Intakes Per Year</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@studentIntakesPerYear, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Number of Students Per Intake</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@studentsPerIntake, ''&nbsp;''), ''</td>'',
    ''</tr>'',
''</table>''
))

SELECT 0 AS [Value], CONCAT(@tbody, ''<br>'') AS [Text]
'
, ResolutionSql = '


declare @title NVARCHAR(max)
declare @awardGrantingBody NVARCHAR(max)
declare @primaryAreaStudy NVARCHAR(max)
declare @subAreaStudy NVARCHAR(max)
declare @otherAreaStudy NVARCHAR(max)
declare @programmeLength NVARCHAR(max)
declare @academyCredit NVARCHAR(max)
declare @QFCredit NVARCHAR(max)
declare @QFLevel NVARCHAR(max)
declare @launchYear NVARCHAR(max)
declare @launchMonth NVARCHAR(max)
declare @targetStudents NVARCHAR(max)
declare @studentIntakesPerYear NVARCHAR(max)
declare @studentsPerIntake NVARCHAR(max)

select @title = Title from Program
where Id = @entityId

select @awardGrantingBody = lr.Text	
	from ProgramDetail pd 
		inner join LettersOfRecommendationRequirement lr on pd.LettersOfRecommendationRequirementId = lr.Id
	where pd.ProgramId = @entityId

select @primaryAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.First_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @subAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.Second_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @otherAreaStudy = CareerOption 
from Program
where Id = @entityId

select @programmeLength = cc.Title
from Program p
	inner join CategoryCode cc on p.CategoryCodeId = cc.Id
where p.Id = @entityId

select @academyCredit = Int05 
from GenericInt
where ProgramId = @entityId

select @QFCredit = ICCBCreditHours 
from Program
where Id = @entityId

select @QFLevel = qfl.Title
from Program p
	inner join QFLevel qfl on p.QFLevelId = qfl.Id
where p.Id = @entityId

select @launchYear = StartYear 
from ProgramProposal
where ProgramId = @entityId

select  @launchMonth = m.MonthName
from Program p
	inner join Months m on m.Id = p.StartMonth
where p.Id = @entityId

select @targetStudents = EntranceRequirementsText 
from program
where Id = @entityId

select @studentIntakesPerYear = ClassStaffCount
from Program
where Id = @entityId

select @studentsPerIntake = CertificationStaffCount
from Program
where Id = @entityId

DECLARE @modesOfDelivery NVARCHAR(MAX) = (SELECT dbo.ConcatWithSepOrdered_Agg('''', dm.Id, CONCAT(''<li style ="list-style-type: none;">'',dm.Title,''</li>''))
	FROM ProgramDeliveryMethod pdm
		INNER JOIN DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
	WHERE ProgramId = @entityId )

DECLARE @tbody NVARCHAR(MAX) = (CONCAT(
''<table style="border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; font-size: 14px;">'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Programme Title</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@title, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Award Granting Body</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@awardGrantingBody, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Mode of Delivery</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@modesOfDelivery, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Primary Area of Study / Training</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@primaryAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Sub Area of Study / Training</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@subAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Other Area of Study / Training (if any)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@otherAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Programme Length</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@programmeLength, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Academy Credit</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@academyCredit, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">QF Credits</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QFCredit, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">QF Level</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QFLevel, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Planned Programme Launch Date</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@launchMonth, ''&nbsp;''), '', '', ISNULL(@launchYear, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Target Students</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@targetStudents, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Number of Student Intakes Per Year</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@studentIntakesPerYear, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Number of Students Per Intake</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@studentsPerIntake, ''&nbsp;''), ''</td>'',
    ''</tr>'',
''</table>''
))

SELECT 0 AS [Value], CONCAT(@tbody, ''<br>'') AS [Text]
'
WHERE Id = 224

UPDATE MetaSelectedField
SET DisplayName = 'Modes of Teaching and Learning'
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSElectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.MetaTemplateId = 25
	and msf.MetaAvailableFieldId = 9147
)

UPDATE MetaSelectedField
SET DisplayName = 'Teaching and Learning Methods'
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSElectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.MetaTemplateId = 25
	and msf.MetaAvailableFieldId = 2237
)

UPDATE MetaSelectedSection
SET SectionName = NULL
WHERE MetaSelectedSectionId in (
		SELECT msf.MetaSelectedSectionId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.MetaTemplateId = 25
	and msf.MetaAvailableFieldId in (2237, 9147)
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
			SELECT mss.MetaTemplateId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.MetaTemplateId = 25
	and msf.MetaAvailableFieldId in (2237, 9147)
)