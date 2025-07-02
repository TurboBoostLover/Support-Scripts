USE [hkapa];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18963';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Form for requirements and update PSD report for MOI and move MOI';
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int = 2; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		--AND mtt.MetaTemplateTypeId in ()		--comment back in if just doing some of the mtt's

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('General Programme Information', 'ProgramAwardType', 'AwardTypeAliasId','1'),
('General Programme Information', 'Program', 'AwardTypeId','2'),
('Mode of Delivery', 'ProgramDeliveryMethod', 'DeliveryMethodId', '3'),
('General Programme Information', 'Program', 'First_AdmissionRequirementId', '4'),
('General Programme Information', 'ProgramLookup14', 'ShortText01', '5'),
('General Programme Information', 'ProgramLookup14', 'Int01', '6'),
('General Programme Information', 'ProgramLookup14', 'Int02', '7'),
('General Programme Information', 'ProgramLookup14', 'ShortText02', '8'),
('General Programme Information', 'Program', 'ProgramCodeId', '9')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int,
	nam NVARCHAR(MAX)
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt, nam)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId, mss2.SectionName
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
INSERT INTO MetaSelectedSectionSetting
(MetaSelectedSectionId, IsRequired, MinElem)
SELECT SectionId, 1, 1 FROM @Fields WHERE Action = '1'

UPDATE MetaSelectedField
SET IsRequired = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId fROM @Fields WHERE Action in (
	'2', '4', '6', '7', '8'
)
)

UPDATE DeliveryMethod
SET EndDate = GETDATE()
WHERE Id in (
	10, 15, 20
)

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('SELECT CASE WHEN EXISTS (
	SELECT TOP 1 1 
	FROM Program AS p
	INNER JOIN ProgramDeliveryMethod AS pdm on pdm.ProgramId = p.Id
	INNER JOIN DeliveryMethod AS dm on pdm.DeliveryMethodId = dm.Id
	WHERE p.Id = @EntityId
	and dm.Active = 1
	and dm.ParentId <> 5) THEN 1
	ELSE 0
	END AS IsValid', 1)

DECLARE @Id int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT TabId,'At least one mode of delivery', 6, 'At least 1 option must be selected from either the Full-Time or Part-Time Section', @Id FROM @Fields WHERE Action = '1'

UPDATE MetaSelectedSection
SET SectionDescription = 'At least 1 option must be selected from either the Full-Time or Part-Time Section'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = '3' and nam = 'Part-Time'
)

UPDATE MetaSelectedSection
SET SectionName = 'Full-Time'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '3' and nam = 'Full Time'
)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 17
, DefaultDisplayType = 'Textarea'
WHERE MetaSelectedFieldId IN (
	SELECT FieldId FROM @Fields WHERE Action = '5'
)

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('DECLARE @Count int = (
	SELECT COUNT(Id) FROM ProgramLookup14 WHERE ProgramId = @EntityId
)

DECLARE @Valid int = (
	SELECT COUNT(Id) FROM ProgramLookup14 WHERE ProgramId = @EntityId
	and Int01 IS NOT NULL
	and Int02 IS NOT NULL
	and ShortText02 IS NOT NULL
	and ItemTypeId IS NOT NULL
)

SELECT CASE WHEN @Count = @Valid THEN 1
ELSE 0
END AS IsValid', 1)

DECLARE @Id2 int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT SectionId,'Require them to fill out fields', 6, 'The following fields are required for each item: Medium of Instruction, Total Contact Hours, Total Notional Learning Hours, Ratio of Total Contact Hours to Total Self-Study Hours', @Id2 FROM @Fields WHERE Action = '8'

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '9'
)

UPDATE MetaSelectedSection
SET SortOrder = SortOrder + 1
, RowPosition = RowPosition + 1
WHERE MetaSelectedSectionId in (
	SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN @Fields AS f on mss.MetaSelectedSection_MetaSelectedSectionId = f.SectionId
	WHERE f.Action = '8'
)

INSERT INTO ItemType
(Title, ItemTableName, SortOrder, StartDate, ClientId)
VALUES
('English', 'ProgramLookup14', 0, GETDATE(), 1),
('Chinese', 'ProgramLookup14', 1, GETDATE(), 1),
('English/Chinese', 'ProgramLookup14', 2, GETDATE(), 1)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Medium of Instruction', -- [DisplayName]
692, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
5, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
150, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = '8'

DECLARE @Id3 int = 234

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
    TotalNotionalLearningHours INT,
		MOI NVARCHAR(MAX)
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
    MAX(c.NotionalLearningHours),
		it.Title
FROM ProgramLookup14 pl
    LEFT JOIN Lookup14 major ON pl.Parent_Lookup14Id = major.Id
    LEFT JOIN Lookup14 Specialisation ON pl.Lookup14Id = Specialisation.Id
    LEFT JOIN ProgramSequence ps ON ps.Lookup14Id = Major.Id
    LEFT JOIN @calculations c ON ps.Id = c.psid
		LEFT JOIN ItemType AS it on pl.ItemTypeId = it.Id
WHERE pl.ProgramId = @entityId
GROUP BY major.Id, major.Title, Specialisation.Id, Specialisation.Title, pl.SortOrder, it.Title

-- Step 3: Initialize @tbody as NVARCHAR
DECLARE @tbody NVARCHAR(MAX) = ''<table style="border-collapse: collapse; width: 100%;"><thead>''
SET @tbody += CONCAT(
    ''<tr>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 20%;">Majors</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 20%;">Specialisations</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 15%;">Contact Hours (CH)</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 15%;">Notional Learning Hours (NLH)</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 15%;">Medium of Instruction (MOI)</th>'',
    ''<th style="border: 1px solid black; text-align: left; padding: 5px; width: 15%;">Ratio of CH to Self-study Hours</th>'',
    ''</tr></thead><tbody>''
)

-- Declare rows to store the formatted HTML rows
DECLARE @rows NVARCHAR(MAX) = ''''
DECLARE @RowCount INT = (SELECT COUNT(*) FROM @MajorsSpecialisationsCourseOptions);

-- Construct table rows
SELECT @rows += CONCAT(
    ''<tr>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(MajorTitle, ''&nbsp;''), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(SpecialisationTitle, ''&nbsp;''), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(TotalContactHours, 0), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(TotalNotionalLearningHours, 0), ''</td>'',
    ''<td style="border: 1px solid black; padding: 5px;">'', ISNULL(MOI, ''&nbsp;''), ''</td>'',
    CASE 
        WHEN id = 1 THEN CONCAT(
            ''<td style="border: 1px solid black; padding: 5px; vertical-align: top;" rowspan="'', @RowCount, ''">'',
            ''Please refer to relevant policy concerning Credit Allocation Type (CAT) in the Policy Manual and Operational Guide and CAT Type per course in Appendix 4.1'',
            ''</td>''
        ) 
        ELSE '''' 
    END,
    ''</tr>''
)
FROM @MajorsSpecialisationsCourseOptions

-- Add rows and close table
SET @tbody += @rows;
SET @tbody += ''</tbody></table>'';

-- Output the result
SELECT 0 AS Value, CONCAT(@tbody, ''<br>'') AS Text;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id3

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id3
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback