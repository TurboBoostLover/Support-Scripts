USE [madera];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19717';
DECLARE @Comments nvarchar(Max) = 
	'Update COR report formatting and new request';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
    AND mtt.IsPresentationView = 1	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (7)		--comment back in if just doing some of the mtt's

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
('Distance Education Addenda', 'GenericBit', 'Bit07','1'),

('Units and Hours', 'CourseQueryText', 'QueryText_40', 'max'),


('Specifications', 'CourseQueryText', 'QueryText_02', 'newhelp'),

('Units and Hours', 'CourseDescription', 'MinCreditHour', '1'),
('Units and Hours', 'CourseDescription', 'MaxCreditHour', '2'),
('Units and Hours', 'CourseDescription', 'MinContactHoursLecture', '3'),
('Units and Hours', 'CourseDescription', 'MaxContactHoursLecture', '4'),
('Units and Hours', 'CourseDescription', 'MinOtherHour', '5'),
('Units and Hours', 'CourseDescription', 'MaxOtherHour', '6'),
('Units and Hours', 'CourseDescription', 'MinLectureHour', '7'),
('Units and Hours', 'CourseDescription', 'MaxLectureHour', '8'),
('Units and Hours', 'CourseDescription', 'MinLabHour', '9'),
('Units and Hours', 'CourseDescription', 'MaxLabHour', '10'),
('Units and Hours', 'CourseDescription', 'MinClinicalHour', '11'),
('Units and Hours', 'CourseDescription', 'MaxClinicalHour', '12'),

('General Information', 'Course', 'ModifyRationale', 'General'),

('Learning Outcomes and Objectives', 'CourseOutcome', 'OutcomeText', 'CSLO'),

('Transferability and General Education Options', 'Course', 'ComparableCsuUc', 'csu'),
('Transferability and General Education Options', 'Course', 'UCTransfer', 'uc'),

('Equipment', 'CourseTextbook', 'CalendarYear', 'year'),
('Equipment', 'CourseTextbook', 'Rational', 'just'),

('Transferability and General Education Options', 'CourseQueryText', 'QueryText_45', 'madcc'),

('Transferability and General Education Options', 'CourseQueryText', 'QueryText_44', 'down'),
('Transferability and General Education Options', 'CourseQueryText', 'QueryText_43', 'down'),
('Transferability and General Education Options', 'CourseQueryText', 'QueryText_42', 'down'),

('Transferability and General Education Options', 'GenericBit', 'Bit09', 'cid')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId
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
UPDATE MetaSelectedSection
SET SectionDescription = 'Accessibility federal and state regulations require that all online course materials must be made available in accessible electronic format.
<ul>
	<li>
		The district, the college, the Office of Instruction, the DSPS office, and the instructor(s) are aware the course must comply with requirements regarding EIT (Electronic and Information Technology) pursuant to Section 508 of the Rehabilitation Act and provisions of California Government Code Section 11135.
	</li>
	<li>
		The district, the college, the Office of Instruction, the DSPS office, and the instructor(s) agree to provide course content in an accessible electronic format.
	</li>
</ul>
All efforts will be made to select and create fully accessible course materials, which includes homeworking systems. If a fully accessible system cannot be found, the faculty (in working with all stakeholders mentioned above) will create substantially equivalent and usable alternatives.<br><br>
Requested mode of delivery and how it will be scheduled (separate approval is required for each distance education mode of delivery option).
<ul>
	<li>100% Online Asynchronous - online learning that allows students to view instructional materials each week at any time they choose and does not include a live scheduled video lecture component.</li>
	<li>100% Online Synchronous - online learning that allows students to engage in learning at the scheduled day(s) and time(s) using some sort of technology i.e. live Zoom sessions.</li>
	<li>Hybrid - online learning that includes a combination of asynchronous instruction with scheduled on-campus face to face meetings as identified in the schedule. Faculty can specify the online percentage in the Additional Notes text box below.</li>
	<li>2-way Live Interactive - online synchronous meeting at multiple locations using technology to facilitate the course at various locations including scheduled on-campus face to face meetings as identified in the schedule.</li>
</ul>'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '1'
)

UPDATE MetaReport
SET ReportAttributes = '{"fieldRenderingStrategy":"HideEmptyFields","sectionRenderingStrategy":"HideEmptySections","suppressEntityTitleDisplay":"true","heading":"Course Outline of Record","isPublicReport":false,"reportTemplateId":7,"cssOverride":".report-body .container.meta-section:nth-child(1) .seperator {visibility: hidden;} .iq-panel-title{font-size: 1.3rem;} div[data-available-field-id=\"8986\"] .querytext-result-row.display-inline-block,div[data-available-field-id=\"8987\"] .querytext-result-row.display-inline-block,div[data-available-field-id=\"8996\"] .querytext-result-row.display-inline-block{display: contents;} div[data-section-id=\"324\"]{page-break-before: always;} .field-label{display: inline;} .section-description{font-weight:500; font-size: 1rem;};}"}'
WHERE Id = 504

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'ShouldDisplayCheckQuery', '
SELECT 
	CASE WHEN Variable = 1 
	THEN 1
	ELSE 0
END AS ShouldDisplay
, null as JsonAttributes
FROM CourseDescription
WHERE CourseId = @EntityId
', FieldId FROM @Fields WHERE Action in (
	'12', '10', '8', '6', '4', '2', 'max'
)

UPDATE MetaSelectedSection
SET SectionDescription = 'These figures are provided to identify areas that instructors may use to evaluate student performance and is in no way intended to limit faculty academic freedom as provided under California Education Code (sec. 70902), the California Code of Regulations (5 CCR 51023), SCCCD policies and regulations, and ACCJC accreditation standards.'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SEctionId FROM @Fields WHERE Action = 'newhelp'
)

DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 13;

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		
DECLARE @MAX2 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 2)	
DECLARE @MAX3 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 3)	
DECLARE @MAX4 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 4)	
DECLARE @MAX5 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 5)	
DECLARE @MAX6 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 6)	
DECLARE @MAX7 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 7)	
DECLARE @MAX8 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 8)	
DECLARE @MAX9 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 9)	
DECLARE @MAX10 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 10)	
DECLARE @MAX11 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 11)	
DECLARE @MAX12 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 12)	
DECLARE @MAX13 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 13)	

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
SELECT 
CASE WHEN MinCreditHour = 0 THEN NULL
ELSE
FORMAT(MinCreditHour, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL2 NVARCHAR(MAX) = "
SELECT
CASE WHEN MaxCreditHour = 0 THEN NULL
ELSE
FORMAT(MaxCreditHour, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL3 NVARCHAR(MAX) = "
SELECT
CASE WHEN MinContactHoursLecture = 0 THEN NULL
ELSE
FORMAT(MinContactHoursLecture, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL4 NVARCHAR(MAX) = "
SELECT
CASE WHEN MaxContactHoursLecture = 0 THEN NULL
ELSE
FORMAT(MaxContactHoursLecture, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL5 NVARCHAR(MAX) = "
SELECT
CASE WHEN MinOtherHour = 0 THEN NULL
ELSE
FORMAT(MinOtherHour, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL6 NVARCHAR(MAX) = "
SELECT
CASE WHEN MaxOtherHour = 0 THEN NULL
ELSE
FORMAT(MaxOtherHour, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL7 NVARCHAR(MAX) = "
SELECT
CASE WHEN MinLectureHour = 0 THEN NULL
ELSE
FORMAT(MinLectureHour, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL8 NVARCHAR(MAX) = "
SELECT
CASE WHEN MaxLectureHour = 0 THEN NULL
ELSE
FORMAT(MaxLectureHour, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL9 NVARCHAR(MAX) = "
SELECT
CASE WHEN MinLabHour = 0 THEN NULL
ELSE
FORMAT(MinLabHour, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL10 NVARCHAR(MAX) = "
SELECT
CASE WHEN MaxLabHour = 0 THEN NULL
ELSE
FORMAT(MaxLabHour, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL11 NVARCHAR(MAX) = "
SELECT
CASE WHEN MinClinicalHour = 0 THEN NULL
ELSE
FORMAT(MinClinicalHour, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL12 NVARCHAR(MAX) = "
SELECT
CASE WHEN MaxClinicalHour = 0 THEN NULL
ELSE
FORMAT(MaxClinicalHour, '##0.###')
END
AS Text,
0 AS Value
FROM CourseDescription
WHERE CourseId = @EntityId
"

DECLARE @SQL14 NVARCHAR(MAX) = "
SELECT 
    0 AS Value,
    '<ul>' + 
    STRING_AGG(
        '<li>' + ge.Title + '</li>' + A.txt, ''
    ) WITHIN GROUP (ORDER BY GE.SortOrder, GE.Id) 
    + '</ul>' AS Text
FROM (
    SELECT 
        GE.SortOrder,
        GE.Id,
        '<ul>' + 
        STRING_AGG(
            '<li>' + GEE.Title + '</li>', ''
        ) WITHIN GROUP (ORDER BY GEE.SortOrder, GEE.Id) 
        + '</ul>' AS txt
    FROM CourseGeneralEducation CGE
        INNER JOIN GeneralEducationElement GEE 
            ON CGE.GeneralEducationElementId = GEE.Id
            AND GEE.GeneralEducationId BETWEEN 32 AND 38
        INNER JOIN GeneralEducation GE 
            ON GEE.GeneralEducationId = GE.Id
    WHERE CGE.CourseId = @EntityId
    GROUP BY GE.SortOrder, GE.Id, GE.Title
) A
INNER JOIN GeneralEducation GE 
    ON GE.SortOrder = A.SortOrder AND GE.Id = A.Id
"


SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseDescription', 'Id', 'Title', @SQL, @SQL, 'Order By SortOrder', 'MinCreditHour', 2),
(@MAX2, 'CourseDescription', 'Id', 'Title', @SQL2, @SQL2, 'Order By SortOrder', 'MaxCreditHour', 2),
(@MAX3, 'CourseDescription', 'Id', 'Title', @SQL3, @SQL3, 'Order By SortOrder', 'MinContactHoursLecture', 2),
(@MAX4, 'CourseDescription', 'Id', 'Title', @SQL4, @SQL4, 'Order By SortOrder', 'MaxContactHoursLecture', 2),
(@MAX5, 'CourseDescription', 'Id', 'Title', @SQL5, @SQL5, 'Order By SortOrder', 'MinOtherHour', 2),
(@MAX6, 'CourseDescription', 'Id', 'Title', @SQL6, @SQL6, 'Order By SortOrder', 'MaxOtherHour', 2),
(@MAX7, 'CourseDescription', 'Id', 'Title', @SQL7, @SQL7, 'Order By SortOrder', 'MinLectureHour', 2),
(@MAX8, 'CourseDescription', 'Id', 'Title', @SQL8, @SQL8, 'Order By SortOrder', 'MaxLectureHour', 2),
(@MAX9, 'CourseDescription', 'Id', 'Title', @SQL9, @SQL9, 'Order By SortOrder', 'MinLabHour', 2),
(@MAX10, 'CourseDescription', 'Id', 'Title', @SQL10, @SQL10, 'Order By SortOrder', 'MaxLabHour', 2),
(@MAX11, 'CourseDescription', 'Id', 'Title', @SQL11, @SQL11, 'Order By SortOrder', 'MinClinicalHour', 2),
(@MAX12, 'CourseDescription', 'Id', 'Title', @SQL12, @SQL12, 'Order By SortOrder', 'MaxClinicalHour', 2),
(@MAX13, 'CourseGeneralEducation', 'Id', 'Title', @SQL14, @SQL14, 'Order By SortOrder', 'Current Local GE items', 2)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 
	CASE
	WHEN Action = '1' THEN 8904
	WHEN Action = '2' THEN 8905
	WHEN Action = '3' THEN 8906
	WHEN Action = '4' THEN 8907
	WHEN Action = '5' THEN 8908
	WHEN Action = '6' THEN 8909
	WHEN Action = '7' THEN 8910
	WHEN Action = '8' THEN 8911
	WHEN Action = '9' THEN 8912
	WHEN Action = '10' THEN 8913
	WHEN Action = '11' THEN 8914
	WHEN Action = '12' THEN 8916
	ELSE MetaAvailableFieldId
	END
, MetaForeignKeyLookupSourceId = 
	CASE
	WHEN Action = '1' THEN @MAX
	WHEN Action = '2' THEN @MAX2
	WHEN Action = '3' THEN @MAX3
	WHEN Action = '4' THEN @MAX4
	WHEN Action = '5' THEN @MAX5
	WHEN Action = '6' THEN @MAX6
	WHEN Action = '7' THEN @MAX7
	WHEN Action = '8' THEN @MAX8
	WHEN Action = '9' THEN @MAX9
	WHEN Action = '10' THEN @MAX10
	WHEN Action = '11' THEN @MAX11
	WHEN Action = '12' THEN @MAX12
	ELSE MetaForeignKeyLookupSourceId
	END
, DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
, ReadOnly = 1
, FieldTypeId = 5
FROM MetaSelectedField AS msf
INNER JOIN @Fields AS f on msf.MetaSelectedFieldId = f.FieldId
WHERE f.Action in (
'1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'
)

UPDATE msf
SET LabelStyleId = 1
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN @templateId AS t on mss.MetaTemplateId = t.Id
WHERE mss2.SectionName = 'Units and Hours'

UPDATE MetaSelectedField
SET DisplayName = 'Maximum Credit Units (CB07)'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '2'
)

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 3
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'General'
)

DECLARE @GeneralFields TABLE (FieldId int, nam NVARCHAR(MAX))

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId, inserted.DisplayName INTO @GeneralFields
SELECT
'Minimum Credit Units (CB07)', -- [DisplayName]
8967, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
0, -- [MinCharacters]
100, -- [MaxCharacters]
11, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
80, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = 'General'
UNION
SELECT
'Credit Units (CB07)', -- [DisplayName]
8968, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
0, -- [MinCharacters]
100, -- [MaxCharacters]
12, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
80, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = 'General'
UNION
SELECT
'Maximum Credit Units (CB07)', -- [DisplayName]
8969, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
0, -- [MinCharacters]
100, -- [MaxCharacters]
13, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
80, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX2, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = 'General'

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'ShouldDisplayCheckQuery', 'select
	case
		when variable = 1 then 1
		else 0
	end as ShouldDisplay, null as JsonAttributes
from CourseDescription CD
where Cd.CourseId = @entityId;', FieldId FROM @GeneralFields WHERE nam = 'Minimum Credit Units (CB07)'
UNION
SELECT 'ShouldDisplayCheckQuery', 'select
	case
		when variable = 1 then 0
		else 1
	end as ShouldDisplay, null as JsonAttributes
from CourseDescription CD
where Cd.CourseId = @entityId;', FieldId FROM @GeneralFields WHERE nam = 'Credit Units (CB07)'
UNION
SELECT 'ShouldDisplayCheckQuery', '
SELECT 
	CASE WHEN Variable = 1 
	THEN 1
	ELSE 0
END AS ShouldDisplay
, null as JsonAttributes
FROM CourseDescription
WHERE CourseId = @EntityId
', FieldId FROM @GeneralFields WHERE nam = 'Maximum Credit Units (CB07)'

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Expected SLO Performance (1-99)', -- [DisplayName]
11671, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
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
1, -- [FieldTypeId]
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
FROM @Fields WHERE Action = 'CSLO'

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in ('csu', 'year', 'just')
)

UPDATE MetaSelectedField
SET RowPosition = RowPosition - 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'uc'
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'URL', -- [DisplayName]
659, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
4, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
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
1, -- [FieldTypeId]
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
FROM @Fields WHERE Action = 'just'

UPDATE GeneralEducation
SET Title = CASE
	WHEN Id = 8 THEN 'CSU GE Area A: Communication in the English Language and Critical Thinking'
	WHEN Id = 9 THEN 'CSU GE Area B: Scientific Inquiry and Quantitative Reasoning'
	WHEN Id = 10 THEN 'CSU GE Area C: Arts and Humanities'
	WHEN Id = 11 THEN 'CSU GE Area D: Social Sciences'
	WHEN Id = 12 THEN 'CSU GE Area E: Lifelong Learning and Self-Development'
	WHEN Id = 13 THEN 'CSU GE Area F: Ethnic Studies'
	WHEN Id = 18 THEN 'IGETC Area 5: Physical and Biological Sciences'
	ELSE Title
END
WHERE Id in (
	8, 9, 10, 11, 12, 13, 18
)

DECLARE @SQL13 NVARCHAR(MAX) = '
SELECT 
    0 AS Value,
    ''<ul>'' + 
    STRING_AGG(
        ''<li>'' + ge.Title + ''</li>'' + A.txt, ''''
    ) WITHIN GROUP (ORDER BY GE.SortOrder, GE.Id) 
    + ''</ul>'' AS Text
FROM (
    SELECT 
        GE.SortOrder,
        GE.Id,
        ''<ul>'' + 
        STRING_AGG(
            ''<li>'' + GEE.Title + ''</li>'', ''''
        ) WITHIN GROUP (ORDER BY GEE.SortOrder, GEE.Id) 
        + ''</ul>'' AS txt
    FROM CourseGeneralEducation CGE
        INNER JOIN GeneralEducationElement GEE 
            ON CGE.GeneralEducationElementId = GEE.Id
            AND GEE.GeneralEducationId BETWEEN 14 AND 20
        INNER JOIN GeneralEducation GE 
            ON GEE.GeneralEducationId = GE.Id
    WHERE CGE.CourseId = @EntityId
    GROUP BY GE.SortOrder, GE.Id, GE.Title
) A
INNER JOIN GeneralEducation GE 
    ON GE.SortOrder = A.SortOrder AND GE.Id = A.Id
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL13
, ResolutionSql = @SQL13
WHERE Id = 103

UPDATE MetaSelectedSection
SET SectionName = 'Madera CC GE (before Fall 2025)'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'madcc'
)

UPDATE MetaSelectedSection
SET SortOrder = SortOrder + 1
, RowPosition = RowPosition + 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action in ('down', 'cid')
)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT DISTINCT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Madera CC GE', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
2, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
TemplateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @Fields WHERE Action = 'down'

DECLARE @NewSec int = SCOPE_IDENTITY()

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'', -- [DisplayName]
8993, -- [MetaAvailableFieldId]
@NewSec, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Querytext', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
1, -- [LabelStyleId]
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
@MAX13, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT 
'C-ID Number', -- [DisplayName]
2692, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
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
1, -- [FieldTypeId]
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
FROM @Fields WHERE Action = 'cid'
UNION
SELECT
'C-ID Number', -- [DisplayName]
2693, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
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
1, -- [FieldTypeId]
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
FROM @Fields WHERE Action = 'cid'
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback