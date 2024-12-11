USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15212';
DECLARE @Comments nvarchar(Max) = 
	'Add IGETC Area 7';
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
('General Ed', 'CourseGeneralEducation', 'Date01','Ping')

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
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
SELECT gee.Id AS Value
, gee.Title AS Text
FROM GeneralEducation ge
	INNER JOIN GeneralEducationElement gee ON ge.Id = gee.GeneralEducationId
WHERE ge.Active = 1
AND ge.Title IN ('IGETC Area 7: Ethnic Studies')
AND gee.Active = 1
ORDER BY ge.SortOrder
"

DECLARE @RSQL NVARCHAR(MAX) = "
SELECT Title AS [Text]
FROM GeneralEducationElement
WHERE Id = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'GeneralEducationElement', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Igetc 7', 3)

DECLARE @BOTTOM TABLE (ID int, mt int)
INSERT INTO @BOTTOM
SELECT mss.MEtaSelectedSectionId, mss.MetaTemplateId FROM MEtaSElectedSection AS mss
INNER JOIN @Fields AS f on mss.MetaSelectedSection_MetaSelectedSectionId = f.TabId
WHERE mss.RowPosition = 46
AND mss.SortOrder = 42

DELETE FROM MetaSelectedField
WHERE MetaSelectedSectionId in (
SELECT Id FROM @BOTTOM
)

UPDATE MetaSelectedSection
SET SectionName = 'IGETC Area 7: Ethnic Studies'
, DisplaySectionName = 0
, MetaSectionTypeId = 23
, MetaBaseSchemaId = 131
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @BOTTOM
)

INSERT INTO MetaSelectedSectionAttribute
(GroupId, AttributeTypeId, Name, Value, MetaSelectedSectionId)
SELECT 1, 1, 'ParentTable', 'Course', b.Id FROM @BOTTOM AS b
UNION
SELECT 1, 1, 'ForeignKeyToParent', 'CourseId', b.Id FROM @BOTTOM AS b
UNION
SELECT 1, 1, 'LookupTable', 'GeneralEducationElement', b.Id FROM @BOTTOM AS b
UNION
SELECT 1, 1, 'ForeignKeyToLookup', 'GeneralEducationElementId', b.Id FROM @BOTTOM AS b
UNION
SELECT 1, 1, 'ColumnCount', '2', b.Id FROM @BOTTOM AS b

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Proposed For', -- [DisplayName]
1371, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
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
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @BOTTOM
UNION
SELECT
'Comments', -- [DisplayName]
349, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
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
FROM @BOTTOM
UNION
SELECT
'Approval Term', -- [DisplayName]
53, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
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
92, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @BOTTOM
UNION
SELECT
'Approval Date', -- [DisplayName]
4672, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'TelerikDate', -- [DefaultDisplayType]
27, -- [MetaPresentationTypeId]
150, -- [Width]
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
FROM @BOTTOM

DECLARE @NEW TABLE (id int, mtt int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @NEW
SELECT DISTINCT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
45, -- [RowPosition]
41, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
TemplateID, -- [MetaTemplateId]
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

DECLARE @TABLE TABLE (msf int, mss int)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId, inserted.MetaSelectedSectionId INTO @TABLE
SELECT DISTINCT
'<b>IGETC Area 7: Ethnic Studies</b>', -- [DisplayName]
2654, -- [MetaAvailableFieldId]
Id, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
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
NULL, -- [LabelStyleId]
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
FROM @NEW


--------------------------------------------------------------
DECLARE @SHOWHIDE TABLE (TId int, field int, sec int)
INSERT INTO @SHOWHIDE
SELECT DISTINCT b.mt, t.msf, b.Id 
FROM @BOTTOM AS b
INNER JOIN @NEW AS n on n.mtt = b.mt
INNER JOIN @TABLE AS t on t.mss = n.id

while exists(select top 1 1 from @SHOWHIDE)
begin
	declare @Temp int = (SELECT TOP 1 TId FROM @SHOWHIDE WHERE TId IS NOT NULL)
	declare @Trigger int = (SELECT field FROM @SHOWHIDE WHERE field IS NOT NULL AND TId = @Temp)
	declare @Sec int = (SELECT sec FROM @SHOWHIDE WHERE sec IS NOT NULL AND TId = @Temp)

	DECLARE @TriggerselectedFieldId INT = @Trigger;  -----------------------------------------------------------------------------------------------------------------
	-- The id for the field that triggers the show/hide 

	DECLARE @TriggerselectedSectionId INT = NULL; 

	DECLARE @displayRuleTypeId INT = 2;              
	-- DisplayRuleType 1 = FieldValidation, 2 = FieldDisplay, 3 = FieldCalculation, 4 = SectionDisplay   
	-- Always set to 2

	DECLARE @ExpressionOperatorTypeId INT = 3;       
	-- SELECT * FROM ExpressionOperatorType 
	-- ExpressionOperatorType 16 = NotEqual - Operand 1 must not be the same value as Operand 2
	-- Note: EOT 16 will throw an error if ComparisonDataType is 1

	DECLARE @ComparisonDataTypeId INT = 3;           
	-- ComparisonDataType 1 = Decimal, 2 = DateTime, 3 = String, 4 = Boolean    

	DECLARE @Operand2Literal NVARCHAR(50) = 'false';  
	-- When Show/Hide is true the field is hidden - i.e. if this is a checkbox (Boolean) this should be 'false' to show the section when checked     
	-- Only one of these two should be used at a time in the MetaDisplaySubscriber query below. Delete the other one in that query and replace it with a NULL.    
	-- If possible, use a section instead of a field. The reason for this is that, as of this writing (branch 28, 2014-01-13), show/hide for fields is buggy and may not work properly. 
	-- Hiding an entire section is less prone to these issues due to the differences in the dynamic form DOM structure for sections vs. fields.    

	DECLARE @listenerSelectedFieldId INT = NULL;  

	DECLARE @listenerSelectedSectionId INT = @Sec; ----------------------------------------------------------------------------------------------------------------
	-- The id for the section that will show/hide based on the trigger

	DECLARE @DisplayRuleName NVARCHAR(50) = 'Show/hide IGETC Area 7';    
	DECLARE @SubscriberName NVARCHAR(50) = 'Show/hide IGETC Area 7';    
	-- Inserts a new Expression Id into the Expression table 
	-- This syntax is needed since the auto-incremented Id is the only field in the Expression table 

	INSERT INTO Expression
		OUTPUT inserted.*    
		DEFAULT VALUES    
	-- The new Expression Id you just inserted above    
	
	DECLARE @expressionId INT;    
	SET @expressionId = SCOPE_IDENTITY();    
	-- Inserts a new ExpressionPart Id into the ExpressionPart table

	INSERT INTO MetaDisplayRule (DisplayRuleName, DisplayRuleValue, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleTypeId, ExpressionId)    
		OUTPUT inserted.*    
		VALUES (@DisplayRuleName, NULL, @TriggerselectedFieldId, @TriggerselectedSectionId, @displayRuleTypeId, @expressionId)    
	-- Inserts a new MetaDisplayRule into the MetaDisplayRule table based on the variable values chosen above
	
	DECLARE @displayRuleId INT;    
		SET @displayRuleId = SCOPE_IDENTITY();
	-- Creates a new Id for the MetaDisplayRule inserted above

	INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)   
		OUTPUT inserted.*    
		VALUES (@expressionId, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL)    
	-- The new ExpressionPart Id you just inserted above 
	
	DECLARE @parentExpressionPartId INT;    
	SET @parentExpressionPartId = SCOPE_IDENTITY();
	-- Keep in mind that if this condition is true, it will hide the field or section  
	-- Inserts a new ExpressionPart Id into the ExpressionPart table and makes the previous ExpressionPart Id the Parent_ExpressionPartId for this one


	INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)    
		OUTPUT inserted.*    
		VALUES (@expressionId, @parentExpressionPartId, 1, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerSelectedFieldId, NULL, @Operand2Literal, NULL, NULL)  
	

	INSERT INTO MetaDisplaySubscriber (SubscriberName, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleId)    
		OUTPUT inserted.*    
		VALUES (@SubscriberName, @listenerSelectedFieldId, @listenerSelectedSectionId, @displayRuleId)

	DELETE FROM @SHOWHIDE
	WHERE TId = @Temp

end
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback