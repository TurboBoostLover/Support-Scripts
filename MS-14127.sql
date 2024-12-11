USE [cuesta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14127';
DECLARE @Comments nvarchar(Max) = 
	'Update course forms';
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
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId <> 6

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
('Distance Education', 'GenericBit', 'Bit07','Update'),
('Credits and Hours', 'CourseQueryText', 'QueryText_05','Update2'),	--QueryText
('Credits and Hours', 'CourseAttribute', 'DistrictCourseTypeId','Update3'), --Course Type
('Credits and Hours', 'CourseDescription', 'MinLectureHour','Update4'), --Hours
('Credits and Hours', 'CourseDescription', 'MaxLectureHour','Update5') --Max Hours

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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
DECLARE @TABLE TABLE (Id int)
INSERT INTO @TABLE (Id)
SELECT cc.Id FROM Course AS c
INNER JOIN CourseContributor AS cc on cc.CourseId = c.Id
INNER JOIN [User] AS u on cc.UserId = u.Id
WHERE c.UserId = u.Id

UPDATE CourseContributor
SET PreviousId = NULL
WHERE PreviousId in (
	SELECT Id FROM @TABLE
)

DELETE FROM CourseContributor
WHERE Id in (
	SELECT Id FROM @TABLE
)

UPDATE GeneralEducationElement
SET Title = '7 - Ethnic Studies'
WHERE Id = 150

UPDATE MetaSelectedSection
SET SectionDescription = 'View the student authentication PowerPoint presentation:
<a href=http://www.3cmediasolutions.org/privid/9183?key=c8edd9a986ea954be6cf0ea456f3e99bc977737a>http://www.3cmediasolutions.org/privid/9183?key=c8edd9a986ea954be6cf0ea456f3e99bc977737a</a> Select the method(s) used to authenticate students in this course'
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = 'Update'
)

INSERT INTO GeneralEducationRubric
(Title, GeneralEducationElementId, ClientId, StartDate)
VALUES
('After successfully completing courses in this category, students will understand the scientific method and its role in research, analyze problems in a structured way, and develop and employ strategies for solutions using scientific principles. Students will understand the empirical bases for current scientific theories, how those theories develop and change, and how they explain the natural world. Students also will appreciate the influence of scientific knowledge on the development of civilization.', 136, 1, GETDATE()),
('After successfully completing courses in this category, students will understand the theories and be able to employ and evaluate the methods of social science inquiry. Students will be able to analyze and critically assess ideas about the individual, social groups, institutions and society, as well as their interrelationships, structure, and function. Students will be able to use this knowledge to develop a capacity for self-understanding and to understand contemporary issues, conflicts, problems, and their origins.', 137, 1, GETDATE()),
('After successfully completing courses in this category, students will recognize the value of the great works of the human imagination in a broad context and understand their contribution to human culture. They will be able to analyze and appraise cultural/artistic achievements in verbal and/or non-verbal forms. Since language acquisition is a door to understanding the arts and humanities of other cultures, students who acquire second language skills also fulfill the Category C requirement.', 138, 1, GETDATE()),
('After successfully completing courses in this category, students will write or orally deliver effective expository and argumentative discourse with a focus on inquiry as well as persuasion. Students will be able to read and listen critically in order to comprehend and communicate their understanding of the central ideas and rhetorical techniques in the assigned texts. They also will be able to demonstrate an ethical use of various rhetorical techniques in their written and/or spoken work.', 139, 1, GETDATE()),
('After successfully completing courses in this category, students will be able to construct and analyze statements in a formal symbolic system, and understand the relationship between the symbolic system and its various applications in the real world. Students will also appreciate the strengths and limitations of the system, its logical structure, and its derivation.', 140, 1, GETDATE()),
('After successfully completing courses in this category, students will understand the impact of social, political, and economic forces in the historical development of the U.S. Students will be able to employ interpretative skills to analyze historical causes and effects. Students will have an enhanced understanding of the interrelationship among the branches of our government over time. Students will also develop an understanding of U.S. cultural and social diversity, and ethnic, gender, and class conflict.', 141, 1, GETDATE()),
('
<ol>
<li>Describe and discuss content of the major chronic diseases in the United States.</li>
<li>Evaluate individual risk factors for chronic diseases from a genetic, environmental, and lifestyle perspective.</li>
<li>Describe and discuss content about communicable diseases/infections (e.g., STI''s, Hepatitis C), including symptoms and prevention.</li>
<li>Analyze the influence of environmental and nutritional concepts on food choices.</li>
<li>Relate diet, exercise, and stress management to prevention of diseases and psychological well being.</li>
<li>Develop an appropriate physical fitness program that includes cardiovascular conditioning, muscle strength and endurance training, and flexibility.</li>
<li>Examine the relationship between values and beliefs and mental health. Utilize this relationship to create effective interpersonal communication in relationships, coping, prevention of addictive behaviors and personal safety.</li>
<li>Analyze and apply spiritual concepts to improve health and wellness.</li>
</ol>
', 142, 1, GETDATE()),
('After successfully completing the requirement, students will be able to identify, assess, and challenge biased assumptions and behaviors of individuals and societal institutions; analyze inter-group relations within categories of identity, such as race, ethnicity, gender, religion, sexual orientation, class, ability, nationality, or age; and examine struggles of non-dominant groups for power, justice, and access to resources.', 143, 1, GETDATE())

DECLARE @SORT int = (SELECT DISTINCT SortOrder FROM @Fields WHERE Action = 'Update2')

UPDATE MetaSelectedSection
SET RowPosition = RowPosition + 2
, SortOrder = SortOrder + 2
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
		INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
		INNER JOIN @Fields AS f on mss2.MetaSelectedSectionId = f.TabId
)
AND SortOrder > @SORT

--DECLARE @Template1 int = (SELECT TemplateId FROM @Fields WHERE Action = 'Update2' AND mtt = 1)		--New
--DECLARE @Template2 int = (SELECT TemplateId FROM @Fields WHERE Action = 'Update2' AND mtt = 12)		--Modify
--DECLARE @Template3 int = (SELECT TemplateId FROM @Fields WHERE Action = 'Update2' AND mtt = 9)		--Deactivate
--DECLARE @TAB1 int = (SELECT TabId FROM @Fields WHERE Action = 'Update2' AND TemplateId = @Template1)		--New
--DECLARE @TAB2 int = (SELECT TabId FROM @Fields WHERE Action = 'Update2' AND TemplateId = @Template2)		--Modify
--DECLARE @TAB3 int = (SELECT TabId FROM @Fields WHERE Action = 'Update2' AND TemplateId = @Template3)		--Deactivate

--DECLARE @TABLE2 TABLE (Id int, Template int, Sort int)

--insert into [MetaSelectedSection]
--([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
--output inserted.MetaSelectedSectionId, inserted.MetaTemplateId, inserted.SortOrder into @TABLE2 (Id, Template, Sort)
--values
--(
--1, -- [ClientId]
--@TAB1, -- [MetaSelectedSection_MetaSelectedSectionId]
--'Units', -- [SectionName]
--1, -- [DisplaySectionName]
--NULL, -- [SectionDescription]
--0, -- [DisplaySectionDescription]
--NULL, -- [ColumnPosition]
--4, -- [RowPosition]
--4, -- [SortOrder]
--1, -- [SectionDisplayId]
--1, -- [MetaSectionTypeId]
--@Template1, -- [MetaTemplateId]
--NULL, -- [DisplayFieldId]
--NULL, -- [HeaderFieldId]
--NULL, -- [FooterFieldId]
--0, -- [OriginatorOnly]
--NULL, -- [MetaBaseSchemaId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EntityListLibraryTypeId]
--NULL, -- [EditMapId]
--1, -- [AllowCopy]
--0, -- [ReadOnly]
--NULL-- [Config]
--)
--,
--(
--1, -- [ClientId]
--@TAB1, -- [MetaSelectedSection_MetaSelectedSectionId]
--'Max Units', -- [SectionName]
--1, -- [DisplaySectionName]
--NULL, -- [SectionDescription]
--0, -- [DisplaySectionDescription]
--NULL, -- [ColumnPosition]
--5, -- [RowPosition]
--5, -- [SortOrder]
--1, -- [SectionDisplayId]
--1, -- [MetaSectionTypeId]
--@Template1, -- [MetaTemplateId]
--NULL, -- [DisplayFieldId]
--NULL, -- [HeaderFieldId]
--NULL, -- [FooterFieldId]
--0, -- [OriginatorOnly]
--NULL, -- [MetaBaseSchemaId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EntityListLibraryTypeId]
--NULL, -- [EditMapId]
--1, -- [AllowCopy]
--0, -- [ReadOnly]
--NULL-- [Config]
--)
--,
--(
--1, -- [ClientId]
--@TAB2, -- [MetaSelectedSection_MetaSelectedSectionId]
--'Units', -- [SectionName]
--1, -- [DisplaySectionName]
--NULL, -- [SectionDescription]
--0, -- [DisplaySectionDescription]
--NULL, -- [ColumnPosition]
--4, -- [RowPosition]
--4, -- [SortOrder]
--1, -- [SectionDisplayId]
--1, -- [MetaSectionTypeId]
--@Template2, -- [MetaTemplateId]
--NULL, -- [DisplayFieldId]
--NULL, -- [HeaderFieldId]
--NULL, -- [FooterFieldId]
--0, -- [OriginatorOnly]
--NULL, -- [MetaBaseSchemaId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EntityListLibraryTypeId]
--NULL, -- [EditMapId]
--1, -- [AllowCopy]
--0, -- [ReadOnly]
--NULL-- [Config]
--)
--,
--(
--1, -- [ClientId]
--@TAB2, -- [MetaSelectedSection_MetaSelectedSectionId]
--'Max Units', -- [SectionName]
--1, -- [DisplaySectionName]
--NULL, -- [SectionDescription]
--0, -- [DisplaySectionDescription]
--NULL, -- [ColumnPosition]
--5, -- [RowPosition]
--5, -- [SortOrder]
--1, -- [SectionDisplayId]
--1, -- [MetaSectionTypeId]
--@Template2, -- [MetaTemplateId]
--NULL, -- [DisplayFieldId]
--NULL, -- [HeaderFieldId]
--NULL, -- [FooterFieldId]
--0, -- [OriginatorOnly]
--NULL, -- [MetaBaseSchemaId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EntityListLibraryTypeId]
--NULL, -- [EditMapId]
--1, -- [AllowCopy]
--0, -- [ReadOnly]
--NULL-- [Config]
--)
--,
--(
--1, -- [ClientId]
--@TAB3, -- [MetaSelectedSection_MetaSelectedSectionId]
--'Units', -- [SectionName]
--1, -- [DisplaySectionName]
--NULL, -- [SectionDescription]
--0, -- [DisplaySectionDescription]
--NULL, -- [ColumnPosition]
--4, -- [RowPosition]
--4, -- [SortOrder]
--1, -- [SectionDisplayId]
--1, -- [MetaSectionTypeId]
--@Template3, -- [MetaTemplateId]
--NULL, -- [DisplayFieldId]
--NULL, -- [HeaderFieldId]
--NULL, -- [FooterFieldId]
--0, -- [OriginatorOnly]
--NULL, -- [MetaBaseSchemaId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EntityListLibraryTypeId]
--NULL, -- [EditMapId]
--1, -- [AllowCopy]
--0, -- [ReadOnly]
--NULL-- [Config]
--)
--,
--(
--1, -- [ClientId]
--@TAB3, -- [MetaSelectedSection_MetaSelectedSectionId]
--'Max Units', -- [SectionName]
--1, -- [DisplaySectionName]
--NULL, -- [SectionDescription]
--0, -- [DisplaySectionDescription]
--NULL, -- [ColumnPosition]
--5, -- [RowPosition]
--5, -- [SortOrder]
--1, -- [SectionDisplayId]
--1, -- [MetaSectionTypeId]
--@Template3, -- [MetaTemplateId]
--NULL, -- [DisplayFieldId]
--NULL, -- [HeaderFieldId]
--NULL, -- [FooterFieldId]
--0, -- [OriginatorOnly]
--NULL, -- [MetaBaseSchemaId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EntityListLibraryTypeId]
--NULL, -- [EditMapId]
--1, -- [AllowCopy]
--0, -- [ReadOnly]
--NULL-- [Config]
--)

--DECLARE @SEC1Temp1 int = (SELECT Id FROM @TABLE2 WHERE Template = @Template1 AND Sort = 4)
--DECLARE @SEC2Temp1 int = (SELECT Id FROM @TABLE2 WHERE Template = @Template1 AND Sort = 5)
--DECLARE @SEC1Temp2 int = (SELECT Id FROM @TABLE2 WHERE Template = @Template2 AND Sort = 4)
--DECLARE @SEC2Temp2 int = (SELECT Id FROM @TABLE2 WHERE Template = @Template2 AND Sort = 5)
--DECLARE @SEC1Temp3 int = (SELECT Id FROM @TABLE2 WHERE Template = @Template3 AND Sort = 4)
--DECLARE @SEC2Temp3 int = (SELECT Id FROM @TABLE2 WHERE Template = @Template3 AND Sort = 5)

--DECLARE @NewFields TABLE (Id int, Section int)

--insert into [MetaSelectedField]
--([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
--output inserted.MetaSelectedFieldId, inserted.MetaSelectedSectionId INTO @NewFields (Id, Section)
--values
--(
--'Min Unit Hours', -- [DisplayName]
--186, -- [MetaAvailableFieldId]
--@SEC1Temp1, -- [MetaSelectedSectionId]
--0, -- [IsRequired]
--NULL, -- [MinCharacters]
--NULL, -- [MaxCharacters]
--0, -- [RowPosition]
--0, -- [ColPosition]
--1, -- [ColSpan]
--'Textbox', -- [DefaultDisplayType]
--1, -- [MetaPresentationTypeId]
--300, -- [Width]
--1, -- [WidthUnit]
--24, -- [Height]
--1, -- [HeightUnit]
--1, -- [AllowLabelWrap]
--0, -- [LabelHAlign]
--1, -- [LabelVAlign]
--NULL, -- [LabelStyleId]
--1, -- [LabelVisible]
--0, -- [FieldStyle]
--NULL, -- [EditDisplayOnly]
--NULL, -- [GroupName]
--NULL, -- [GroupNameDisplay]
--1, -- [FieldTypeId]
--NULL, -- [ValidationRuleId]
--NULL, -- [LiteralValue]
--0, -- [ReadOnly]
--1, -- [AllowCopy]
--NULL, -- [Precision]
--NULL, -- [MetaForeignKeyLookupSourceId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EditMapId]
--NULL, -- [NumericDataLength]
--NULL-- [Config]
--)
--,
--(
--'Min Unit Hours', -- [DisplayName]
--186, -- [MetaAvailableFieldId]
--@SEC1Temp2, -- [MetaSelectedSectionId]
--0, -- [IsRequired]
--NULL, -- [MinCharacters]
--NULL, -- [MaxCharacters]
--0, -- [RowPosition]
--0, -- [ColPosition]
--1, -- [ColSpan]
--'Textbox', -- [DefaultDisplayType]
--1, -- [MetaPresentationTypeId]
--300, -- [Width]
--1, -- [WidthUnit]
--24, -- [Height]
--1, -- [HeightUnit]
--1, -- [AllowLabelWrap]
--0, -- [LabelHAlign]
--1, -- [LabelVAlign]
--NULL, -- [LabelStyleId]
--1, -- [LabelVisible]
--0, -- [FieldStyle]
--NULL, -- [EditDisplayOnly]
--NULL, -- [GroupName]
--NULL, -- [GroupNameDisplay]
--1, -- [FieldTypeId]
--NULL, -- [ValidationRuleId]
--NULL, -- [LiteralValue]
--0, -- [ReadOnly]
--1, -- [AllowCopy]
--NULL, -- [Precision]
--NULL, -- [MetaForeignKeyLookupSourceId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EditMapId]
--NULL, -- [NumericDataLength]
--NULL-- [Config]
--)
--,
--(
--'Min Unit Hours', -- [DisplayName]
--186, -- [MetaAvailableFieldId]
--@SEC1Temp3, -- [MetaSelectedSectionId]
--0, -- [IsRequired]
--NULL, -- [MinCharacters]
--NULL, -- [MaxCharacters]
--0, -- [RowPosition]
--0, -- [ColPosition]
--1, -- [ColSpan]
--'Textbox', -- [DefaultDisplayType]
--1, -- [MetaPresentationTypeId]
--300, -- [Width]
--1, -- [WidthUnit]
--24, -- [Height]
--1, -- [HeightUnit]
--1, -- [AllowLabelWrap]
--0, -- [LabelHAlign]
--1, -- [LabelVAlign]
--NULL, -- [LabelStyleId]
--1, -- [LabelVisible]
--0, -- [FieldStyle]
--NULL, -- [EditDisplayOnly]
--NULL, -- [GroupName]
--NULL, -- [GroupNameDisplay]
--1, -- [FieldTypeId]
--NULL, -- [ValidationRuleId]
--NULL, -- [LiteralValue]
--0, -- [ReadOnly]
--1, -- [AllowCopy]
--NULL, -- [Precision]
--NULL, -- [MetaForeignKeyLookupSourceId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EditMapId]
--NULL, -- [NumericDataLength]
--NULL-- [Config]
--)
--,
--(
--'Max Unit Hours', -- [DisplayName]
--176, -- [MetaAvailableFieldId]
--@SEC2Temp1, -- [MetaSelectedSectionId]
--0, -- [IsRequired]
--NULL, -- [MinCharacters]
--NULL, -- [MaxCharacters]
--0, -- [RowPosition]
--0, -- [ColPosition]
--1, -- [ColSpan]
--'Textbox', -- [DefaultDisplayType]
--1, -- [MetaPresentationTypeId]
--300, -- [Width]
--1, -- [WidthUnit]
--24, -- [Height]
--1, -- [HeightUnit]
--1, -- [AllowLabelWrap]
--0, -- [LabelHAlign]
--1, -- [LabelVAlign]
--NULL, -- [LabelStyleId]
--1, -- [LabelVisible]
--0, -- [FieldStyle]
--NULL, -- [EditDisplayOnly]
--NULL, -- [GroupName]
--NULL, -- [GroupNameDisplay]
--1, -- [FieldTypeId]
--NULL, -- [ValidationRuleId]
--NULL, -- [LiteralValue]
--0, -- [ReadOnly]
--1, -- [AllowCopy]
--NULL, -- [Precision]
--NULL, -- [MetaForeignKeyLookupSourceId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EditMapId]
--NULL, -- [NumericDataLength]
--NULL-- [Config]
--)
--,
--(
--'Max Unit Hours', -- [DisplayName]
--176, -- [MetaAvailableFieldId]
--@SEC2Temp2, -- [MetaSelectedSectionId]
--0, -- [IsRequired]
--NULL, -- [MinCharacters]
--NULL, -- [MaxCharacters]
--0, -- [RowPosition]
--0, -- [ColPosition]
--1, -- [ColSpan]
--'Textbox', -- [DefaultDisplayType]
--1, -- [MetaPresentationTypeId]
--300, -- [Width]
--1, -- [WidthUnit]
--24, -- [Height]
--1, -- [HeightUnit]
--1, -- [AllowLabelWrap]
--0, -- [LabelHAlign]
--1, -- [LabelVAlign]
--NULL, -- [LabelStyleId]
--1, -- [LabelVisible]
--0, -- [FieldStyle]
--NULL, -- [EditDisplayOnly]
--NULL, -- [GroupName]
--NULL, -- [GroupNameDisplay]
--1, -- [FieldTypeId]
--NULL, -- [ValidationRuleId]
--NULL, -- [LiteralValue]
--0, -- [ReadOnly]
--1, -- [AllowCopy]
--NULL, -- [Precision]
--NULL, -- [MetaForeignKeyLookupSourceId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EditMapId]
--NULL, -- [NumericDataLength]
--NULL-- [Config]
--)
--,
--(
--'Max Unit Hours', -- [DisplayName]
--176, -- [MetaAvailableFieldId]
--@SEC2Temp3, -- [MetaSelectedSectionId]
--0, -- [IsRequired]
--NULL, -- [MinCharacters]
--NULL, -- [MaxCharacters]
--0, -- [RowPosition]
--0, -- [ColPosition]
--1, -- [ColSpan]
--'Textbox', -- [DefaultDisplayType]
--1, -- [MetaPresentationTypeId]
--300, -- [Width]
--1, -- [WidthUnit]
--24, -- [Height]
--1, -- [HeightUnit]
--1, -- [AllowLabelWrap]
--0, -- [LabelHAlign]
--1, -- [LabelVAlign]
--NULL, -- [LabelStyleId]
--1, -- [LabelVisible]
--0, -- [FieldStyle]
--NULL, -- [EditDisplayOnly]
--NULL, -- [GroupName]
--NULL, -- [GroupNameDisplay]
--1, -- [FieldTypeId]
--NULL, -- [ValidationRuleId]
--NULL, -- [LiteralValue]
--0, -- [ReadOnly]
--1, -- [AllowCopy]
--NULL, -- [Precision]
--NULL, -- [MetaForeignKeyLookupSourceId]
--NULL, -- [MetadataAttributeMapId]
--NULL, -- [EditMapId]
--NULL, -- [NumericDataLength]
--NULL-- [Config]
--)

--DECLARE @MinU1 int = (SELECT Id FROM @NewFields WHERE Section = @SEC1Temp1)
--DECLARE @MaxU1 int = (SELECT Id FROM @NewFields WHERE Section = @SEC2Temp1)
--DECLARE @MinU2 int = (SELECT Id FROM @NewFields WHERE Section = @SEC1Temp2)
--DECLARE @MaxU2 int = (SELECT Id FROM @NewFields WHERE Section = @SEC2Temp2)
--DECLARE @MinU3 int = (SELECT Id FROM @NewFields WHERE Section = @SEC1Temp3)
--DECLARE @MaxU3 int = (SELECT Id FROM @NewFields WHERE Section = @SEC2Temp3)

--DECLARE @Trigger1 int = (SELECT FieldId FROM @Fields WHERE mtt = 1 AND Action = 'Update3')
--DECLARE @Trigger2 int = (SELECT FieldId FROM @Fields WHERE mtt = 12 AND Action = 'Update3')
--DECLARE @Trigger3 int = (SELECT FieldId FROM @Fields WHERE mtt = 9 AND Action = 'Update3')

--DECLARE @SHOWHIDE TABLE (Trig int, sec int, template int, id int identity)
--INSERT INTO @SHOWHIDE
--SELECT @Trigger1, @SEC1Temp1, @Template1
--UNION
--SELECT @Trigger1, @SEC2Temp1, @Template1
--UNION
--SELECT @Trigger2, @SEC1Temp2, @Template2
--UNION
--SELECT @Trigger2, @SEC2Temp2, @Template2
--UNION
--SELECT @Trigger3, @SEC1Temp3, @Template3
--UNION
--SELECT @Trigger3, @SEC2Temp3, @Template3

--while exists(select top 1 id from @SHOWHIDE)
--begin
--		declare @EX int = (SELECT TOP 1 id FROM @SHOWHIDE)
--    declare @TID int = (select template from @SHOWHIDE WHERE id = @EX)
--		declare @Boom int = (SELECT Trig FROM @SHOWHIDE WHERE id = @EX)
--		declare @AWWWW int = (SELECT sec FROM @SHOWHIDE WHERE id = @EX)

--DECLARE @TriggerselectedFieldId INT = @Boom;     
---- The id for the field that triggers the show/hide 

--DECLARE @TriggerselectedSectionId INT = NULL; 

--DECLARE @displayRuleTypeId INT = 2;              
---- DisplayRuleType 1 = FieldValidation, 2 = FieldDisplay, 3 = FieldCalculation, 4 = SectionDisplay   
---- Always set to 2

--DECLARE @ExpressionOperatorTypeId INT = 16;       
---- SELECT * FROM ExpressionOperatorType 
---- ExpressionOperatorType 16 = NotEqual - Operand 1 must not be the same value as Operand 2
---- Note: EOT 16 will throw an error if ComparisonDataType is 1

--DECLARE @ComparisonDataTypeId INT = 3;           
---- ComparisonDataType 1 = Decimal, 2 = DateTime, 3 = String, 4 = Boolean    

--DECLARE @Operand2Literal NVARCHAR(50) = 4;  
---- When Show/Hide is true the field is hidden - i.e. if this is a checkbox (Boolean) this should be 'false' to show the section when checked     
---- Only one of these two should be used at a time in the MetaDisplaySubscriber query below. Delete the other one in that query and replace it with a NULL.    
---- If possible, use a section instead of a field. The reason for this is that, as of this writing (branch 28, 2014-01-13), show/hide for fields is buggy and may not work properly. 
---- Hiding an entire section is less prone to these issues due to the differences in the dynamic form DOM structure for sections vs. fields.    

--DECLARE @listenerSelectedFieldId INT = NULL;  

--DECLARE @listenerSelectedSectionId INT = @AWWWW; 
---- The id for the section that will show/hide based on the trigger

--DECLARE @DisplayRuleName NVARCHAR(50) = 'Show/hide Work exp';    
--DECLARE @SubscriberName NVARCHAR(50) = 'Show/hide Work exp';    
---- Inserts a new Expression Id into the Expression table 
---- This syntax is needed since the auto-incremented Id is the only field in the Expression table 

--INSERT INTO Expression
--    OUTPUT inserted.*    
--	DEFAULT VALUES    
---- The new Expression Id you just inserted above    
	
--DECLARE @expressionId INT;    
--SET @expressionId = SCOPE_IDENTITY();    
---- Inserts a new ExpressionPart Id into the ExpressionPart table

--INSERT INTO MetaDisplayRule (DisplayRuleName, DisplayRuleValue, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleTypeId, ExpressionId)    
--	OUTPUT inserted.*    
--	VALUES (@DisplayRuleName, NULL, @TriggerselectedFieldId, @TriggerselectedSectionId, @displayRuleTypeId, @expressionId)    
---- Inserts a new MetaDisplayRule into the MetaDisplayRule table based on the variable values chosen above
	
--DECLARE @displayRuleId INT;    
--	SET @displayRuleId = SCOPE_IDENTITY();
---- Creates a new Id for the MetaDisplayRule inserted above

--INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)   
--	OUTPUT inserted.*    
--	VALUES (@expressionId, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL)    
---- The new ExpressionPart Id you just inserted above 
	
--DECLARE @parentExpressionPartId INT;    
--SET @parentExpressionPartId = SCOPE_IDENTITY();
---- Keep in mind that if this condition is true, it will hide the field or section  
---- Inserts a new ExpressionPart Id into the ExpressionPart table and makes the previous ExpressionPart Id the Parent_ExpressionPartId for this one


--INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)    
--	OUTPUT inserted.*    
--	VALUES (@expressionId, @parentExpressionPartId, 1, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerSelectedFieldId, NULL, @Operand2Literal, NULL, NULL)  
	

--INSERT INTO MetaDisplaySubscriber (SubscriberName, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleId)    
--	OUTPUT inserted.*    
--	VALUES (@SubscriberName, @listenerSelectedFieldId, @listenerSelectedSectionId, @displayRuleId)

--	delete @SHOWHIDE
--	WHERE id = @EX
--end

--DECLARE @Sec1T1 int = (SELECT SectionId FROM @Fields WHERE TemplateId = @Template1 AND Action = 'Update4')
--DECLARE @Sec2T1 int = (SELECT SectionId FROM @Fields WHERE TemplateId = @Template1 AND Action = 'Update5')
--DECLARE @Sec1T2 int = (SELECT SectionId FROM @Fields WHERE TemplateId = @Template2 AND Action = 'Update4')
--DECLARE @Sec2T2 int = (SELECT SectionId FROM @Fields WHERE TemplateId = @Template2 AND Action = 'Update5')
--DECLARE @Sec1T3 int = (SELECT SectionId FROM @Fields WHERE TemplateId = @Template3 AND Action = 'Update4')
--DECLARE @Sec2T3 int = (SELECT SectionId FROM @Fields WHERE TemplateId = @Template3 AND Action = 'Update5')

--DECLARE @SHOWHIDE2 TABLE (Trig int, sec int, template int, id int identity)
--INSERT INTO @SHOWHIDE2
--SELECT @Trigger1, @Sec1T1, @Template1
--UNION
--SELECT @Trigger1, @Sec2T1, @Template1
--UNION
--SELECT @Trigger2, @Sec1T2, @Template2
--UNION
--SELECT @Trigger2, @Sec2T2, @Template2
--UNION
--SELECT @Trigger3, @Sec1T3, @Template3
--UNION
--SELECT @Trigger3, @Sec2T3, @Template3


--while exists(select top 1 id from @SHOWHIDE2)
--begin
--		declare @EX2 int = (SELECT TOP 1 id FROM @SHOWHIDE2)
--    declare @TID2 int = (select template from @SHOWHIDE2 WHERE id = @EX2)
--		declare @Boom2 int = (SELECT Trig FROM @SHOWHIDE2 WHERE id = @EX2)
--		declare @AWWWW2 int = (SELECT sec FROM @SHOWHIDE2 WHERE id = @EX2)

--DECLARE @TriggerselectedFieldId2 INT = @Boom2;     
---- The id for the field that triggers the show/hide 

--DECLARE @TriggerselectedSectionId2 INT = NULL; 

--DECLARE @displayRuleTypeId2 INT = 2;              
---- DisplayRuleType 1 = FieldValidation, 2 = FieldDisplay, 3 = FieldCalculation, 4 = SectionDisplay   
---- Always set to 2

--DECLARE @ExpressionOperatorTypeId2 INT = 3;       
---- SELECT * FROM ExpressionOperatorType 
---- ExpressionOperatorType 16 = NotEqual - Operand 1 must not be the same value as Operand 2
---- Note: EOT 16 will throw an error if ComparisonDataType is 1

--DECLARE @ComparisonDataTypeId2 INT = 3;           
---- ComparisonDataType 1 = Decimal, 2 = DateTime, 3 = String, 4 = Boolean    

--DECLARE @Operand2Literal2 NVARCHAR(50) = 4;  
---- When Show/Hide is true the field is hidden - i.e. if this is a checkbox (Boolean) this should be 'false' to show the section when checked     
---- Only one of these two should be used at a time in the MetaDisplaySubscriber query below. Delete the other one in that query and replace it with a NULL.    
---- If possible, use a section instead of a field. The reason for this is that, as of this writing (branch 28, 2014-01-13), show/hide for fields is buggy and may not work properly. 
---- Hiding an entire section is less prone to these issues due to the differences in the dynamic form DOM structure for sections vs. fields.    

--DECLARE @listenerSelectedFieldId2 INT = NULL;  

--DECLARE @listenerSelectedSectionId2 INT = @AWWWW2; 
---- The id for the section that will show/hide based on the trigger

--DECLARE @DisplayRuleName2 NVARCHAR(50) = 'Show/hide Work exp';    
--DECLARE @SubscriberName2 NVARCHAR(50) = 'Show/hide Work exp';    
---- Inserts a new Expression Id into the Expression table 
---- This syntax is needed since the auto-incremented Id is the only field in the Expression table 

--INSERT INTO Expression
--    OUTPUT inserted.*    
--	DEFAULT VALUES    
---- The new Expression Id you just inserted above    
	
--DECLARE @expressionId2 INT;    
--SET @expressionId2 = SCOPE_IDENTITY();    
---- Inserts a new ExpressionPart Id into the ExpressionPart table

--INSERT INTO MetaDisplayRule (DisplayRuleName, DisplayRuleValue, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleTypeId, ExpressionId)    
--	OUTPUT inserted.*    
--	VALUES (@DisplayRuleName2, NULL, @TriggerselectedFieldId2, @TriggerselectedSectionId2, @displayRuleTypeId2, @expressionId2)    
---- Inserts a new MetaDisplayRule into the MetaDisplayRule table based on the variable values chosen above
	
--DECLARE @displayRuleId2 INT;    
--	SET @displayRuleId2 = SCOPE_IDENTITY();
---- Creates a new Id for the MetaDisplayRule inserted above

--INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)   
--	OUTPUT inserted.*    
--	VALUES (@expressionId2, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL)    
---- The new ExpressionPart Id you just inserted above 
	
--DECLARE @parentExpressionPartId2 INT;    
--SET @parentExpressionPartId2 = SCOPE_IDENTITY();
---- Keep in mind that if this condition is true, it will hide the field or section  
---- Inserts a new ExpressionPart Id into the ExpressionPart table and makes the previous ExpressionPart Id the Parent_ExpressionPartId for this one


--INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)    
--	OUTPUT inserted.*    
--	VALUES (@expressionId2, @parentExpressionPartId2, 1, @ExpressionOperatorTypeId2, @ComparisonDataTypeId2, @TriggerSelectedFieldId2, NULL, @Operand2Literal2, NULL, NULL)  
	

--INSERT INTO MetaDisplaySubscriber (SubscriberName, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleId)    
--	OUTPUT inserted.*    
--	VALUES (@SubscriberName2, @listenerSelectedFieldId2, @listenerSelectedSectionId2, @displayRuleId2)

--	delete @SHOWHIDE2
--	WHERE id = @EX2
--end
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback

--fix query text 
-- hide hours on work exp