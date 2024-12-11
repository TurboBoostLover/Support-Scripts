USE [victorvalley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17975';
DECLARE @Comments nvarchar(Max) = 
	'Fix Distance Education Report';
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
UPDATE MetaTemplate
sET EndDate = NULL
, DeletedDate = NULL		--Dont know why it was deactived forever ago but its still being used and no other version exists
, DeletedByUserId = NULL
WHERE MetaTemplateId = 16

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
		AND mtt.MetaTemplateTypeId in (16)		--comment back in if just doing some of the mtt's

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
('Distance Education', 'Course', 'IsDistanceEd','1')

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
insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT
1, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Distance Education', -- [SectionName]
1, -- [DisplaySectionName]
'<p style="color:green;"><i><b>DEIA Opportunity:</b></p><p> Offer courses in <b>different distance education modalities</b> to maximize flexibility for students.</i><br /><br /><p><span style="font-size:1em"> Distance Education is instruction in which the instructor and student are separated by distance and interact through the assistance of communication technology (§ 55200)</span></p></p>', -- [SectionDescription]
1, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
2, -- [RowPosition]
2, -- [SortOrder]
1, -- [SectionDisplayId]
15, -- [MetaSectionTypeId]
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
FROM @Fields

DECLARE @Tab int = SCOPE_IDENTITY()

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT
1, -- [ClientId]
@Tab, -- [MetaSelectedSection_MetaSelectedSectionId]
'*Delivery Method(s) - Check all that apply *', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
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
FROM @Fields

DECLARE @Checklist int = SCOPE_IDENTITY()

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT
1, -- [ClientId]
@Tab, -- [MetaSelectedSection_MetaSelectedSectionId]
'General Information', -- [SectionName]
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
FROM @Fields

DECLARE @Sec int = SCOPE_IDENTITY()

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'
		<div>
			<div>
				*<b>Instructors must ensure</b> that any portion of a course conducted through distance education includes regular and substantive interaction between the instructor(s) and students, either synchronously or asynchronously, through group or individual meetings, orientation and review sessions, supplemental seminar or study sessions, field trips, library workshops, telephone contact, voice mail, e-mail, or other activities including but not limited to the following (5 CCR § 55204):
				<ul>
					<li><b>Threaded Discussion Forums</b> - with appropriate instructor initiated participation.</li>
					<li><b>Announcements</b> - posted in the Course Management System at least once each week.</li>
					<li><b>Feedback on Student Work</b> - Completed in a timely manner.</li>
					<li><b>E-Lectures</b> - Original and course-related instructional content prepared by the instructor of a class and made available to students within the district course management system. E-lectures may be delivered in a variety of formats, including text-only content pages, posted documents, transcripted audio recordings with or without synchronized slides, and captioned video recordings.</li>
				</ul>
			</div>
			<div>
				*<b>Substantive interaction</b> means engaging students in teaching, learning, and assessment, consistent with the content under discussion, and includes at least two of the following:
				<ol>
					<li>Providing direct instruction;</li>
					<li>Assessing or providing feedback on a student''s coursework;</li>
					<li>Providing information or responding to questions about the content of a course or competency;</li>
					<li>Facilitating a group discussion regarding the content of a course or competency; or</li>
					<li>Other instructional activities approved by the institution''s or program''s accrediting agency (5 CCR § 55204).</li>
				</ol>
			</div>
			<div>
				*<b>Regular interaction</b> between a student and instructor(s) is ensured by, prior to the student''s completion of a course or competency:
				<ol>
					<li>Providing the opportunity for substantive interactions with the student on a predictable and scheduled basis commensurate with the length of time and the amount of content in the course or competency; and</li>
					<li>Monitoring the student''s academic engagement and success and ensuring that an instructor is responsible for promptly and proactively engaging in substantive interaction with the student when needed on the basis of such monitoring, or upon request by the student (5 CCR § 55204).</li>
				</ol>
			</div>
		</div>
	', -- [DisplayName]
NULL, -- [MetaAvailableFieldId]
@Sec, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'StaticText', -- [DefaultDisplayType]
35, -- [MetaPresentationTypeId]
NULL, -- [Width]
0, -- [WidthUnit]
NULL, -- [Height]
0, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
NULL, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
2, -- [FieldTypeId]
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
)
,
(
'FULLY ONLINE (FO) (also known as "100% online") – Instruction that uses one or more of the technologies listed below to deliver instruction to students who are separated from the instructor(s) and to support regular and substantive interaction between the students and instructor(s) either synchronously or asynchronously. All approved instructional contact hours are delivered through online interactions. Fully online classes do not require in-person assessments or activities. If synchronous online activities are required, the schedule of classes indicates dates and times.

(1) The Internet;

(2) One-way and two-way transmissions through open broadcast, closed circuit, cable, microwave, broadband lines, fiber optics, satellite, or wireless communications devices;

(3) Audio conference; or

(4) Other media used in a course in conjunction with any of the technologies listed in 1-3 of this subdivision.

(b) The definition of “distance education” does not include correspondence courses.', -- [DisplayName]
1750, -- [MetaAvailableFieldId]
@Checklist, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Checkbox', -- [DefaultDisplayType]
5, -- [MetaPresentationTypeId]
60, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
0, -- [LabelVisible]
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
)
,
(
'PARTIALLY ONLINE (PO) (also known as "hybrid") – Instruction that uses one or more of the technologies listed below to deliver instruction to students who are separated from the instructor(s) for any portion of the approved contact hours and to support regular and substantive interaction between the students and instructor(s) either synchronously or asynchronously. Any portion of a class that is delivered online must follow a separate approval process. The approved online portion must meet the regular and effective contact regulations. The schedule of classes indicates dates, times, and locations of the required in-person components.', -- [DisplayName]
1751, -- [MetaAvailableFieldId]
@Checklist, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Checkbox', -- [DefaultDisplayType]
5, -- [MetaPresentationTypeId]
60, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
0, -- [LabelVisible]
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
)
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback