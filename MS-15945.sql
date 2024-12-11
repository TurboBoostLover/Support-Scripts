USE [evc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15945';
DECLARE @Comments nvarchar(Max) = 
	'Add new tab to course forms';
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
Declare @clientId int = 22, -- SELECT Id, Title FROM Client 
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
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
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
('Student Learning Outcomes', 'CourseOutcome', 'OutcomeText','Tab'),
('Methods of Evaluation and Examination', 'CourseEvaluationMethod', 'EvaluationMethodId','Tab'),
('Textbooks/Learning Materials', 'CourseTextbook', 'Author','Tab'),
('Prerequisite/Corequisite', 'CourseRequisite', 'RequisiteTypeId','Tab'),
('Prerequisite/Corequisite Validation', 'CourseTransferInfo', 'CourseNumber','Tab'),
('Prerequisite/Corequisite Removal', 'GenericBit', 'Bit29','Tab'),
('Advisory/Recommended Preparation', 'CourseWorkOut', 'Lookup14Id_Tier1','Tab'),
('Homework', 'GenericDecimal', 'Decimal01','Tab'),
('Method of Instruction', 'CourseInstructionType', 'InstructionTypeId','Tab'),
('Status', 'Course', 'SpecialDesignatorId','Tab'),
('Program Status', 'GenericBit', 'Bit19','Tab'),
('General Education Status', 'CourseGeneralEducation', 'GeneralEducationElementId','Tab'),
('Completed by Dean', 'CourseHour', 'MinimumLecture','Tab'),
('Material Fees', 'CourseDescription', 'HasFee','Tab'),
('Codes and Dates', 'Course', 'CourseOriginationDate','Tab'),
('DE Addendum', 'CourseDistanceEducationQuestion', 'DistanceEducationQuestionId','Tab'),
('ASSIST', 'Course', 'ComparableCsuUc','Tab'),
('ASSIST Preview', 'Course', 'SubjectId','Tab')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedSection
SET RowPosition = RowPosition + 1
, SortOrder = SortOrder + 1
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields AS f 
	INNER JOIN MEtaSelectedSection AS mss on f.TAbId = mss.MetaSelectedSectionId
	WHERE f.Action = 'Tab'
	and mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
)

DECLARE @TabIds TABLE (secId int, templateId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @TabIds
SELECT DISTINCT
22, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Objective', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
4, -- [RowPosition]
4, -- [SortOrder]
1, -- [SectionDisplayId]
30, -- [MetaSectionTypeId]
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
FROM @Fields WHERE Action = 'Tab'

DECLARE @SectionIds TABLE (SecId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId INTO @SectionIds
SELECT DISTINCT
22, -- [ClientId]
secId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Objectives', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
31, -- [MetaSectionTypeId]
templateId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
104, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @TabIds

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT DISTINCT
'Objective Text', -- [DisplayName]
379, -- [MetaAvailableFieldId]
secId, -- [MetaSelectedSectionId]
1, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textarea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
300, -- [Width]
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
FROM @SectionIds

INSERT INTO ListItemType
(Title, ListItemTypeOrdinal, ListItemTableName, ListItemTitleColumn, SortOrder, StartDate, ClientId)
VALUES
('Objective', 1, 'CourseObjective', 'Text', 1, GETDATE(), 22)

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('		select 
			case 
				when count(*) > 0
					then 1
				else 0
			end as EntryValid
		from CourseObjective
		where CourseId = @entityId
		and Text IS NOT NULL;', 1)

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO MetaControlAttribute
(MetaSelectedSectionId, Name, Description, MetaControlAttributeTypeId, CustomMessage, MetaSqlStatementId)
SELECT DISTINCT secId, 'CourseObjective', 'This must have 1 item', 6, 'Launch Requirement: This list requires a minimum of 1 item', @ID FROM @SectionIds
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update
-------------------------------------------------------------------------------------------------------------------------------------------------------------------
DELETE FROM MetaReportTemplateType WHERE MetaReportId = 41
DELETE FROM MetaReportActionType WHERE MetaReportId = 41
DELETE FROM MetaReport WHERE Id = 41

DECLARE @reportId int = 495
DECLARE @reportTitle NVARCHAR(MAX) = 'Course Outline'
DECLARE @newMT int = 903
DECLARE @entityId int = 1	--1-Courses, 2-Programs, 6-Modules
DECLARE @reportType int = 4		--2-CourseCompare, 4-CourseAllFields, 6-Program/ModuleCompare, 13-Program/ModuleAllFields

DECLARE @reportAttribute NVARCHAR(MAX) = concat('{"reportTemplateId":', @newMt,'}')

INSERT INTO MetaReport
(Id,Title,MetaReportTypeId,OutputFormatId,ReportAttributes)
VALUES
(@reportId, @reportTitle, @reportType, 5, @reportAttribute)


INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
SELECT
	@reportId,
	mtt.MetaTemplateTypeId,
	GETDATE()
FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = @entityId
AND mt.Active = 1
AND mt.IsDraft = 0
AND mtt.Active = 1
AND mtt.IsPresentationView = 0

DECLARE @MAXr INT = (SELECT MAX(ID) FROM MetaReportActionType) + 1

INSERT INTO MetaReportActionType
(Id, MetaReportId, ProcessActionTypeId)
VALUES
(@MAXr,@reportId,1),
(@MAXr + 1,@reportId,2),
(@MAXr + 2,@reportId,3)


UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId = @newMT
----------------------------------------------------------------------------------------

declare @templateId2 integers

INSERT INTO @templateId2
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 1		--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (520)		--comment back in if just doing some of the mtt's

declare @FieldCriteria2 table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria2 (TabName, TableName, ColumnName,Action)
values
('New Section', 'CourseQueryText', 'QueryTextId_01','Update1'),
('New Section', 'CourseQueryText', 'QueryTextId_02','Update2'),
('New Section', 'CourseQueryText', 'QueryTextId_03','Update3'),
('New Section', 'CourseQueryText', 'QueryTextId_04','Update4'),
('New Section', 'CourseQueryText', 'QueryTextId_05','Update5'),
('New Section', 'CourseQueryText', 'QueryTextId_06','Update6'),
('New Section', 'CourseQueryText', 'QueryTextId_07','Update7'),
('New Section', 'CourseQueryText', 'QueryTextId_08','Update8'),
('New Section', 'CourseQueryText', 'QueryTextId_12','Update9'),
('New Section', 'CourseQueryText', 'QueryTextId_09','Update10'),
('New Section', 'CourseQueryText', 'QueryTextId_10','Update11'),
('New Section', 'CourseQueryText', 'QueryTextId_11','Update12')

declare @Fields2 table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int
);

insert into @Fields2 (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt)
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
inner join @FieldCriteria2 rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId2)

/********************** Changes go HERE **************************************************/
Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)
DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)
DECLARE @MAX3 int = (SELECT Id FROM #SeedIds WHERE row_num = 3)
DECLARE @MAX4 int = (SELECT Id FROM #SeedIds WHERE row_num = 4)
DECLARE @MAX5 int = (SELECT Id FROM #SeedIds WHERE row_num = 5)
DECLARE @MAX6 int = (SELECT Id FROM #SeedIds WHERE row_num = 6)
DECLARE @MAX7 int = (SELECT Id FROM #SeedIds WHERE row_num = 7)
DECLARE @MAX8 int = (SELECT Id FROM #SeedIds WHERE row_num = 8)
DECLARE @MAX9 int = (SELECT Id FROM #SeedIds WHERE row_num = 9)
DECLARE @MAX10 int = (SELECT Id FROM #SeedIds WHERE row_num = 10)
DECLARE @MAX11 int = (SELECT Id FROM #SeedIds WHERE row_num = 11)
DECLARE @MAX12 int = (SELECT Id FROM #SeedIds WHERE row_num = 12)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL1 NVARCHAR(MAX) = "
DECLARE @Bod nvarchar(max) = (
	SELECT CourseDate FROM CourseDate WHERE CourseId = @EntityId and CourseDateTypeId = 289
)

DECLARE @rev nvarchar(max) = (
	SELECT CourseDate FROM CourseDate WHERE CourseId = @EntityId and CourseDateTypeId = 291
)

DECLARE @et nvarchar(max) = (
	SELECT CONCAT(s.Title, ', ', cp.StartYear) FROM CourseProposal AS cp
	INNER JOIN Semester As s on cp.SemesterId = s.Id
	WHERE cp.CourseId = @EntityId
)

SELECT 0 AS Value,
CONCAT(
'Board Approval Date: ', @Bod, '<br />',
'Revision Date: ', @rev, '<br />',
'Effective Term: ', @et
) AS Text
"

DECLARE @SQL2 NVARCHAR(MAX) = "
SELECT CONCAT(s.SubjectCode, ' ', c.CourseNumber) AS Text, 0 AS Value
FROM Course As c
INNER JOIN Subject As s on c.SubjectId = s.Id
WHERE c.Id = @EntityId
"

DECLARE @SQL3 NVARCHAR(MAX) = "
DECLARE @units nvarchar(max) = (
	SELECT CASE
	WHEN cd.MaxCreditHour IS NULL or cd.MaxCreditHour < cd.MinCreditHour
	THEN cd.MinCreditHour
	ELSE CONCAT(cd.MinCreditHour, ' - ', cd.MaxCreditHour)
	END
	FROM CourseDescription AS cd WHERE CourseId = @EntityId
)

DECLARE @Lec nvarchar(max) = (
	SELECT CASE
	WHEN cd.MaxLectureHour IS NULL or cd.MaxLectureHour < cd.MinLectureHour
	THEN cd.MinLectureHour
	ELSE CONCAT(cd.MinLectureHour, ' - ', cd.MaxLectureHour)
	END
	FROM CourseDescription AS cd WHERE CourseId = @EntityId
)

DECLARE @Lab nvarchar(max) = (
	SELECT CASE
	WHEN cd.MaxLabHour IS NULL or cd.MaxLabHour < cd.MinLabHour
	THEN cd.MinLabHour
	ELSE CONCAT(cd.MinLabHour, ' - ', cd.MaxLabHour)
	END
	FROM CourseDescription AS cd WHERE CourseId = @EntityId
)

SELECT 0 AS Value,
CONCAT(
'Units: ', @units, '<br />',
'Lecture Units: ', @Lec, '<br />',
'Lab Units: ', @Lab
) AS Text
"

DECLARE @SQL4 NVARCHAR(MAX) = "
SELECT 0 AS Value,
CONCAT(
'<ol><li>', dbo.ConcatWithSep_Agg('<li>', it.Title), '</ol>'
) AS Text
FROM CourseInstructionType AS cit 
INNER JOIN InstructionType AS it on cit.InstructionTypeId = it.Id
WHERE cit.CourseId = @EntityId
"

DECLARE @SQL5 NVARCHAR(MAX) = "
DECLARE @units nvarchar(max) = (
	SELECT CASE
	WHEN cd.MaxContactHoursLecture IS NULL or cd.MaxContactHoursLecture < cd.MinContactHoursLecture
	THEN cd.MinContactHoursLecture
	ELSE CONCAT(cd.MinContactHoursLecture, ' - ', cd.MaxContactHoursLecture)
	END
	FROM CourseDescription AS cd WHERE CourseId = @EntityId
)

DECLARE @Lec nvarchar(max) = (
	SELECT CASE
	WHEN cd.MaxContactHoursLab IS NULL or cd.MaxContactHoursLab < cd.MinContactHoursLab
	THEN cd.MinContactHoursLab
	ELSE CONCAT(cd.MinContactHoursLab, ' - ', cd.MaxContactHoursLab)
	END
	FROM CourseDescription AS cd WHERE CourseId = @EntityId
)

DECLARE @min nvarchar(max) = (
	SELECT SUM(COALESCE(cd.MinContactHoursLecture, 0)+ COALESCE(cd.MinContactHoursLab, 0)) * 18
	FROM CourseDescription AS cd WHERE CourseId = @EntityId
)

DECLARE @max nvarchar(max) = (
	SELECT SUM(COALESCE(cd.MaxContactHoursLecture, 0)+ COALESCE(cd.MaxContactHoursLab, 0)) * 18
	FROM CourseDescription AS cd WHERE CourseId = @EntityId
)

SELECT 0 AS Value,
CONCAT(
'Lecture Horus: ', @units, '<br />',
'Lab Hours: ', @Lec, '<br />',
'Total Contact Hours: ',
CASE 
	WHEN @max > @min
	THEN
	CONCAT(@min, ' - ', @max)
	ELSE @min
	END
) AS Text
"

DECLARE @SQL6 NVARCHAR(MAX) = "
SELECT 0 AS Value,
Decimal01 AS Text
FROM GenericDecimal WHERE CourseId = @EntityId
"

DECLARE @SQL7 NVARCHAR(MAX) = "
DECLARE @TABLE TABLE (txt nvarchar(max), sort int)
INSERT INTO @TABLE
SELECT CONCAT(s.SubjectCode, ' ', c.CourseNumber, ' ', c.Title, ' ', con.Title), cr.SortOrder FROM CourseRequisite AS cr 
INNER JOIN Course AS c on c.Id = cr.Requisite_CourseId
INNER JOIN Subject AS s on s.Id = c.SubjectId
LEFT JOIN Condition AS con on cr.ConditionId = con.ID
WHERE cr.CourseId = @EntityId
and cr.RequisiteTypeId = 381
order by cr.SortOrder

DECLARE @TABLE2 TABLE (txt nvarchar(max), sort int)
INSERT INTO @TABLE2
SELECT CONCAT(s.SubjectCode, ' ', c.CourseNumber, ' ', c.Title, ' ', con.Title), cr.SortOrder FROM CourseRequisite AS cr 
INNER JOIN Course AS c on c.Id = cr.Requisite_CourseId
INNER JOIN Subject AS s on s.Id = c.SubjectId
LEFT JOIN Condition AS con on cr.ConditionId = con.ID
WHERE cr.CourseId = @EntityId
and cr.RequisiteTypeId = 208
order by cr.SortOrder

DECLARE @TABLE3 TABLE (txt nvarchar(max), sort int)
INSERT INTO @TABLE3
SELECT CONCAT(s.SubjectCode, ' ', c.CourseNumber, ' ', c.Title, ' ', con.Title), cr.SortOrder FROM CourseRequisite AS cr 
INNER JOIN Course AS c on c.Id = cr.Requisite_CourseId
INNER JOIN Subject AS s on s.Id = c.SubjectId
LEFT JOIN Condition AS con on cr.ConditionId = con.ID
WHERE cr.CourseId = @EntityId
and cr.RequisiteTypeId = 209
order by cr.SortOrder

DECLARE @NONE NVARCHAR(MAX) = (
	SELECT dbo.ConcatWithSepOrdered_Agg('', t.sort, t.txt)
	FROM @TABLE AS t
)

DECLARE @Pre NVARCHAR(MAX) = (
	SELECT dbo.ConcatWithSepOrdered_Agg('', t.sort, t.txt)
	FROM @TABLE2 AS t
)

DECLARE @Co NVARCHAR(MAX) = (
	SELECT dbo.ConcatWithSepOrdered_Agg('', t.sort, t.txt)
	FROM @TABLE3 AS t
)

SELECT 0 AS Value,
CONCAT(
'Course None: ', @None, '<br />',
'Course Prerequisite: ', @Pre, '<br />',
'Course Corequisite: ', @Co
) AS Text
"

DECLARE @SQL8 NVARCHAR(MAX) = "
SELECT 0 AS Value,
CONCAT(
'<ol><li>', dbo.ConcatWithSepOrdered_Agg('<li>', co.SortOrder, co.OutcomeText), '</ol>') AS Text
FROM CourseOutcome as co
WHERE CourseId = @EntityId
"

DECLARE @SQL9 NVARCHAR(MAX) = "
SELECT 0 AS Value,
CONCAT(
'<ol><li>', dbo.ConcatWithSepOrdered_Agg('<li>', co.SortOrder, co.Text), '</ol>') AS Text
FROM CourseObjective as co
WHERE CourseId = @EntityId
"

DECLARE @SQL10 NVARCHAR(MAX) = "
SELECT 0 AS Value,
CONCAT(
'<ol><li>', dbo.ConcatWithSep_Agg('<li>', em.title), '</ol><br /><b>Critical thinking example(s):</b><br />',
cm.OtherMethods) AS Text
FROM Course as c
LEFT JOIN CourseEvaluationMethod as co on co.CourseId = c.Id
LEFT JOIN EvaluationMethod AS em on co.EvaluationMethodId = em.Id
LEFT JOIN CourseMethodOfEvaluation AS cm on cm.CourseId = c.Id
WHERE c.Id = @EntityId
group by cm.OtherMethods
"

DECLARE @SQL11 NVARCHAR(MAX) = "
SELECT 0 AS Value, 'Test' as Text
"

DECLARE @SQL12 NVARCHAR(MAX) = "
SELECT 0 AS Value,
TextMax03 AS Text
FROM GenericMaxText WHERE CourseId = @EntityId
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseQueryText', 'Id', 'Title', @SQL1, @SQL1, 'Order By SortOrder', 'Approval Dates', 2),
(@MAX2, 'CourseQueryText', 'Id', 'Title', @SQL2, @SQL2, 'Order By SortOrder', 'Course Discipline and Number:', 2),
(@MAX3, 'CourseQueryText', 'Id', 'Title', @SQL3, @SQL3, 'Order By SortOrder', 'Units', 2),
(@MAX4, 'CourseQueryText', 'Id', 'Title', @SQL4, @SQL4, 'Order By SortOrder', 'Instruction Methodology:', 2),
(@MAX5, 'CourseQueryText', 'Id', 'Title', @SQL5, @SQL5, 'Order By SortOrder', 'Hours', 2),
(@MAX6, 'CourseQueryText', 'Id', 'Title', @SQL6, @SQL6, 'Order By SortOrder', 'Homework Hours:', 2),
(@MAX7, 'CourseQueryText', 'Id', 'Title', @SQL7, @SQL7, 'Order By SortOrder', 'Requisites', 2),
(@MAX8, 'CourseQueryText', 'Id', 'Title', @SQL8, @SQL8, 'Order By SortOrder', 'Learning Outcomes', 2),
(@MAX9, 'CourseQueryText', 'Id', 'Title', @SQL9, @SQL9, 'Order By SortOrder', 'Objectives', 2),
(@MAX10, 'CourseQueryText', 'Id', 'Title', @SQL10, @SQL10, 'Order By SortOrder', 'Methods of Evaluation', 2),
(@MAX11, 'CourseQueryText', 'Id', 'Title', @SQL11, @SQL11, 'Order By SortOrder', 'Textbooks', 2),
(@MAX12, 'CourseQueryText', 'Id', 'Title', @SQL12, @SQL12, 'Order By SortOrder', 'Assignments', 2)

UPDATE MetaSelectedField
SET DefaultDisplayType = 'QueryText'
, MetaPresentationTypeId = 103
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
, LabelVisible = 0
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update1'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX2
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update2'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX3
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update3'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX4
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update4'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX5
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update5'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX6
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update6'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX7
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update7'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX8
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update8'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX9
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update9'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX10
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update10'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX11
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update11'
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX12
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields2 WHERE Action = 'Update12'
)

UPDATE MetaSelectedSection
SET DisplaySectionName = 0
, MetaSectionTypeId = 15
WHERE MetaSelectedSectionId in (
	SELECT DISTINCT TabId FROM @Fields2 WHERE Action = 'Update1'
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields2)

commit
--rollback