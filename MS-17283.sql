USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17283';
DECLARE @Comments nvarchar(Max) = 
	'Update more Reviews for the 10th time';
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
	@Entitytypeid int =6; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

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
		AND mtt.MetaTemplateTypeId in (21, 36)		--comment back in if just doing some of the mtt's

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
('IV. Summary, Recommendations, And Long-term Goals', 'ModuleExtension02', 'TextMax01','Ping'),
('I. Unit Overview', 'Module', 'Description', 'Ping2'),
('II. Service Unit Data And Service Unit Outcomes (SUOs)', 'ModuleExtension01', 'TextMax02', 'Ping3'),
('III. Service Unit Resources', 'ModuleExtension01', 'TextMax05', 'Ping4'),
('III. Service Unit Resources', 'ModuleExtension01', 'LongText10', 'Ping5'),
('III. Service Unit Resources', 'ModuleExtension02', 'LongText02', 'Ping6'),
('III. Service Unit Resources', 'ModuleExtension02', 'TextMax14', 'Ping7'),
('III. Service Unit Resources', 'ModuleExtension02', 'TextMax09', 'Ping8'),
('IV. Summary, Recommendations, And Long-term Goals', 'ModuleExtension02', 'TextMax02', 'Ping9'),
('V. IPR Addendum', 'ModuleExtension02', 'TextMax07', 'Ping10'),
('V. IPR Addendum', 'ModuleExtension02', 'TextMax10', 'Ping10'),
('V. IPR Addendum', 'ModuleExtension02', 'TextMax15', 'Ping10'),
('Students and Student Success', 'ModuleCRN', 'TextMax10', 'Ping11'),
('V. IPR Addendum', 'ModuleYesNo', 'YesNo08Id', 'Ping12'),
('V. IPR Addendum', 'ModuleCRN', 'TextMax06', 'Ping13'),
('V. IPR Addendum', 'ModuleCRN', 'TextMax07', 'Ping14'),
('Students and Student Success', 'ModuleExtension01', 'TextMax01', 'Ping15'),
('IV. Summary, Recommendations, And Long-term Goals', 'ModuleExtension02', 'TextMax03', 'Ping16'),
('IV. Summary, Recommendations, And Long-term Goals', 'GenericOrderedList02', 'Text100001', 'Ping17')

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedSection
SET SectionDescription = NULL
, DisplaySectionDescription = 0
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = 'Ping'
)

UPDATE GenericOrderedList02
SET ListItemTypeId = 30
WHERE ListItemTypeId = 50

UPDATE ModuleGoal
SET ListItemTypeId = 33
WHERE ListItemTypeId = 51

UPDATE GoalStatus
SET EndDate = GETDATE()
WHERE Id = 1

DELETE FROM ListItemType WHERE Id in (50, 51)

UPDATE MetaSelectedFieldAttribute
SET Value = 'Concisely provide a clear and complete description of the purpose. Describe the population served (students, college personnel, community, etc.) and include any relevant legislative mandates or restrictive requirements. Ensure all parts of the prompt are addressed.
<br><br>
FCC Mission Statement: As California''s first community college, Fresno City College provides access to equity- centered, quality, innovative educational programs and support services. Committed to a culture of anti-racism, we create dynamic communities of respect and inquiry which encourage student success and lifelong learning while fostering the sustainable economic, social, and cultural development of our students and region.
<br><br>
Once you have addressed the FCC Mission Statement, check ONE OR MORE of the six Strategic Plan Goals below.
'
WHERE Name = 'helptext'
and MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping2'
)

UPDATE MetaSelectedFieldAttribute
SET Value = '
<ul>
<li>Provide an analysis of trends, any equity gaps, anticipated changes, and recommendations for improvement.</li>
<li>Please include a PDF of the data discussed here in Appendix B.</li>
<li>If all SUOs have not been assessed since the last comprehensive review, specify which have not been assessed and provide an explanation. If part of your SUO data is a satisfaction survey, be sure to include population surveyed, time frame, and modality.</li>
</ul>
If you need assistance with SUOs or responding to the prompt above, please reach out to the SLO/Outcomes Coordinator.
'
WHERE Name = 'helptext'
and MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping3'
)

UPDATE MetaSelectedFieldAttribute
SET Value = '
<ul>
<li>Indicate the hours of operation and provide examples of how the hours support the needs of the population served.</li>
<li>If an adjustment to the hours of operation is needed, provide a rationale, and indicate the impact to the population served. Indicate the costs associated with the change.</li>
</ul>
'
WHERE Name = 'helptext'
and MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping4'
)

UPDATE MetaSelectedFieldAttribute
SET Value = '
<ul>
<li>Describe any changes in the service unit''s budget and/or how budget increases or reductions have impacted service unit goals. If applicable, seek input from your direct manager or accountant to complete this section.</li>
<li>If the service unit does not have a budget, explain how that impacts the overall performance of the service unit.</li>
</ul>
'
WHERE Name = 'helptext'
and MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping5'
)

UPDATE MetaSelectedField
SET DisplayName = 'D. After reviewing the last four-year budget (in Appendix C), provide a brief summary and describe any trends.'
, DefaultDisplayType = 'CKEditor'
, MetaPresentationTypeId = 25
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping5'
)

UPDATE MetaSelectedField
SET  DefaultDisplayType = 'CKEditor'
, MetaPresentationTypeId = 25
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping6'
)

UPDATE MetaSelectedField
SET  DefaultDisplayType = 'CKEditor'
, MetaPresentationTypeId = 25
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping7'
)

UPDATE MetaSelectedFieldAttribute
SET Value = '
<ul>
<li>Describe the current facility and equipment utilized by the service unit levels in relation to its purpose.</li>
<li>If current facility and equipment levels are inadequate, explain the need for additional equipment or facilities.</li>
<li>Consider including this as a goal in Section IV and update needed resources.</li>
</ul>
'
WHERE Name = 'helptext'
and MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping7'
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Comments', -- [DisplayName]
1204, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
FROM @Fields WHERE Action = 'Ping8' and mtt = 36
 UNION
SELECT
'Comments', -- [DisplayName]
1205, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'CKEditor', -- [DefaultDisplayType]
25, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
FROM @Fields WHERE Action = 'Ping8' and mtt = 36

UPDATE MetaSelectedField
SET  DefaultDisplayType = 'CKEditor'
, MetaPresentationTypeId = 25
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping9'
)

DELETE FROM MetaSelectedFieldRolePermission
WHERE MetaSelectedFieldId in (
	SELECT fieldId FROM @Fields WHERE Action = 'Ping10'
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT fieldId FROM @Fields WHERE Action = 'Ping10'
)

UPDATE MetaSelectedSection
SET SectionDescription = '
Section Information: Describes program enrollment and identifies any trends (over an extended [8-year] period) which may have implications for the program.  Provides analysis of success and retention rates. Summarizes strategies to address institutionally recognized equity gaps and/or areas of disproportional impact.
<br><br>
IRPE Program Review Data is attached as Appendix A. The order of the data included in Appendix A are as follows:
<ol>
<li>Degrees and Certificates</li>
<li>Enrollment, Headcount, Sections, Average Class Size</li>
<li>Enrollment Breakdown - 8 Year Trend</li>
<li>GPA, Retention, and Success</li>
<li>FTEF, FTES, WSCH, and FT:PT LHE Ratio</li>
</ol>
Please describe the overall program data before considering subgroups. Analysis and discussion of additional disaggregated data, relevant to the program (e.g. age, course delivery method [F2F vs. on-line], student status [FT vs. PT]) may be included. Please state clearly, and justify, if particular data are excluded from the analysis (e.g. summer sections excluded).
'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action = 'Ping11'
)

UPDATE MetaSelectedFieldAttribute
SET Value = '
A ''stand-alone'' course is one which is NOT<ul>
<li>part of a GE pattern		NOR is it</li>
<li>part of an AA/AS degree	NOR is it</li>
<li>part of a State Chancellor-approved Certificate</li></ul>
Since ''stand-alone'' courses are not part of any GE pattern or degree, their inclusion and continued offering (particularly if a program has a significant number of them) should be explained and/or justified.
'
WHERE Name = 'helptext'
and MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping12'
)

UPDATE MetaSelectedFieldAttribute
SET Value = '
''Significant'' changes would include adding, modifying or deleting degrees, certificates or courses.  For courses, changes to requisites, substantial content, unit or delivery method should be included.  If no significant changes have been made, please state.<br />
This prompt relates to changes that have been submitted to the Curriculum Committee during the PR data collection period (even if implementation date is outside this period).  Planned changes (i.e. anything that has not been submitted to the Curriculum Committee) should be described in D. below.<br />
Unavoidable changes in course delivery (e.g. move to 100% online instruction during COVID-19 restrictions) may be included in this section if these had a significant impact on the program.
'
WHERE Name = 'helptext'
and MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping13'
)

UPDATE MetaSelectedField
SET DisplayName = 'B. List any significant changes in the program''s curricula during this PR period.  Explain the rationale for, and impact of these changes on your program.'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping13'
)

UPDATE MetaSelectedFieldAttribute
SET Value = '
This prompt relates to any planned changes, i.e. those that have not yet been submitted to the 
Curriculum Committee.  Plans for ''significant'' change would include adding, modifying or deleting degrees, 
certificates or courses.  Additionally, changes to requisites, substantial content, unit or delivery changes 
should be included.
'
WHERE Name = 'helptext'
and MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping14'
)

UPDATE MetaSelectedField
SET DisplayName = 'E. If applicable, describe any plans for significant changes to the program''s curricula. Explain the rationale, expected implementation date and anticipated impact on the program as a whole.'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping14'
)

UPDATE MetaSelectedFieldAttribute
SET Value = '
Describe overall program enrollment and identify any trends which may have implications for the program.<br>
Provide context (changes in number of faculty, new teaching rooms, categorical funding, expansion of online education etc.) to explain any significant fluctuations.  If you have significant numbers of dual enrollment students, or identified trends in dual enrollment, please describe in this section (''Dual Enrollment'' filter is available on IRPE dashboard - see red text at start of section for link).  If significant increases in enrollment are noted, explain how the increasing numbers of students are being accommodated, and how the quality of their educational experience is being maintained.<br>
If significant decreases in enrollment are noted (> 10% year-on-year drop for all 4 years of the PR period, or overall > 40% drop) defend the viability of the program, explaining how this trend may be reversed or otherwise managed.  Number of sections and/or average class size data may be discussed if relevant.  Any proposed links between average class size and student success data should be considered in C below.
'
WHERE Name = 'helptext'
and MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping11'
)

UPDATE MetaSelectedField
SET DisplayName = 'A. Examine your program''s data.  Provide context as necessary and identify any trends.  Discuss the implications of this analysis and, if applicable, describe plans to address any issues identified.'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping11'
)

UPDATE MetaSelectedField
SET DisplayName = 'B. Examine your program''s data.  Identify any under- or over-represented* groups within the program. If applicable, describe any plans to address under- or over-representation.'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping15'
)

DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping16' and mtt = 36
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Ping16' and mtt = 36
)

DELETE FROM MetaSelectedFieldRolePermission
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN @Fields as f on msf.MetaSelectedSectionId = f.SectionId WHERE Action = 'Ping17' and mtt = 36
)

DELETE FROM MetaSelectedField
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Ping17' and mtt = 36
)

UPDATE MetaSelectedSection
SET SectionName = 'C. List the service unit''s top 3-5 goals for the next four years, including details of how and when they will be evaluated.'
, SectionDescription = '
<ul>
  <li>Click on "Add" for each new programmatic goal.</li>
  <li>Complete boxes related to goal.</li>
  <li>If resource needed to meet goal, indicate "yes"</li>
  <li>Indicate the type of resource needed in the "Resource or Support" text box (e.g. full-time faculty, equipment, etc.).</li>
</ul>
Provide additional explanation in the "Explanation/Context/Additional Information" text box.

'
, DisplaySectionDescription = 1
, MetaBaseSchemaId = 1722
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Ping17' and mtt = 36
)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Goal #', -- [DisplayName]
977, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
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
FROM @Fields WHERE Action = 'Ping17' and mtt = 36
UNION
SELECT
'Goal', -- [DisplayName]
978, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textarea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
100, -- [Height]
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
FROM @Fields WHERE Action = 'Ping17' and mtt = 36
UNION
SELECT
'Resource or Support', -- [DisplayName]
945, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikCombo', -- [DefaultDisplayType]
33, -- [MetaPresentationTypeId]
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
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
115, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = 'Ping17' and mtt = 36
UNION
SELECT
'Explanation/Context/Additional Information', -- [DisplayName]
976, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textarea', -- [DefaultDisplayType]
17, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
500, -- [Height]
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
FROM @Fields WHERE Action = 'Ping17' and mtt = 36
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback