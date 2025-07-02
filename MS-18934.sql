USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18934';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text is PDS report table 1.2';
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
DECLARE @Id int = 234

DECLARE @SQL NVARCHAR(MAX) = '
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


--Hack to get the overide from the Majors OL on the General Info tab to override all the auto Calculations
UPDATE msco
SET TotalContactHours = CASE WHEN pl.Int01 IS NOT NULL THEN pl.Int01 ELSE TotalContactHours END
, TotalNotionalLearningHours = CASE WHEN pl.Int02 IS NOT NULL THEN pl.Int02 ELSE TotalNotionalLearningHours END
FROM @MajorsSpecialisationsCourseOptions AS msco
INNER JOIN Lookup14 AS l14 on msco.MajorId = l14.Id
INNER JOIN Lookup14 AS l142 on msco.SpecialisationId = l142.Id
INNER JOIN ProgramLookup14 AS pl on pl.Parent_Lookup14Id = l14.Id

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

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id