USE [delta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13854';
DECLARE @Comments nvarchar(Max) = 
	'Add fields to Instructional and non program review';
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
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
	AND mtt.MetaTemplateTypeId in (38, 45)
	--55, 64 SELECT * FROM MetaTemplate WHERe metatemplateid in (55, 64)

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
('Goal', 'ModuleGoal', 'PlanToAchieveGoal','Update'),
('Goal', 'ModuleGoal', 'GoalStatusId', 'Mark')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition
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
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
DECLARE @SecId TABLE (SecId int, Id int IDENTITY)

DECLARE @SectionId Table (SecId int, TempId int)
INSERT INTO @SectionId (SecId, TempId)
SELECT TabId, TemplateId FROM @Fields WHERE Action = 'Update'

DECLARE @TriggerFieldId table (id int)
INSERT INTO @TriggerFieldId (id)
SELECT FieldId FROM @Fields WHERE Action = 'Mark'

while exists(select top 1 1 from @SectionId)
	BEGIN

	DECLARE @Id int = (SELECT Top 1 SecId FROM @SectionId)
	DECLARE @TId int = (SELECT Top 1 TempId FROM @SectionId)
	DECLARE @TRID int = (SELECT Top 1 id FROM @TriggerFieldId)

		insert into [MetaSelectedSection]
		([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
		OUTPUT inserted.MetaSelectedSectionId INTO @SecId (SecId)
		values
		(
		1, -- [ClientId]
		@Id, -- [MetaSelectedSection_MetaSelectedSectionId]		
		NULL, -- [SectionName]
		1, -- [DisplaySectionName]
		NULL, -- [SectionDescription]
		0, -- [DisplaySectionDescription]
		NULL, -- [ColumnPosition]
		3, -- [RowPosition]
		3, -- [SortOrder]
		1, -- [SectionDisplayId]
		11, -- [MetaSectionTypeId]
		@TId, -- [MetaTemplateId]
		NULL, -- [DisplayFieldId]
		NULL, -- [HeaderFieldId]
		NULL, -- [FooterFieldId]
		0, -- [OriginatorOnly]
		3207, -- [MetaBaseSchemaId]
		NULL, -- [MetadataAttributeMapId]
		NULL, -- [EntityListLibraryTypeId]
		NULL, -- [EditMapId]
		1, -- [AllowCopy]
		0, -- [ReadOnly]
		NULL-- [Config]
		)
	DECLARE @NEWSECID int = (SELECT SecId FROM @SecId WHERE Id = (SELECT MAX(id) FROM @SecId))

		insert into [MetaSelectedField]
		([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
		values
		(
		'Briefly explain why this goal has been abandoned.', -- [DisplayName]
		5985, -- [MetaAvailableFieldId]
		@NEWSECID, -- [MetaSelectedSectionId]
		1, -- [IsRequired]
		NULL, -- [MinCharacters]
		NULL, -- [MaxCharacters]
		0, -- [RowPosition]
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
		)

DECLARE @FieldId int = SCOPE_IDENTITY()

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
VALUES
('listitemtype',3,@FieldId)

DECLARE @TriggerselectedFieldId INT = @TRID;     
-- The id for the field that triggers the show/hide 

DECLARE @TriggerselectedSectionId INT = NULL; 

DECLARE @displayRuleTypeId INT = 2;              
-- DisplayRuleType 1 = FieldValidation, 2 = FieldDisplay, 3 = FieldCalculation, 4 = SectionDisplay   
-- Always set to 2

DECLARE @ExpressionOperatorTypeId INT = 16;       
-- SELECT * FROM ExpressionOperatorType 
-- ExpressionOperatorType 16 = NotEqual - Operand 1 must not be the same value as Operand 2
-- Note: EOT 16 will throw an error if ComparisonDataType is 1

DECLARE @ComparisonDataTypeId INT = 3;           
-- ComparisonDataType 1 = Decimal, 2 = DateTime, 3 = String, 4 = Boolean    

DECLARE @Operand2Literal NVARCHAR(50) = 4;  
-- When Show/Hide is true the field is hidden - i.e. if this is a checkbox (Boolean) this should be 'false' to show the section when checked  
-- Only one of these two should be used at a time in the MetaDisplaySubscriber query below. Delete the other one in that query and replace it with a NULL.    
-- If possible, use a section instead of a field. The reason for this is that, as of this writing (branch 28, 2014-01-13), show/hide for fields is buggy and may not work properly. 
-- Hiding an entire section is less prone to these issues due to the differences in the dynamic form DOM structure for sections vs. fields.    

DECLARE @listenerSelectedFieldId INT = NULL;  

DECLARE @listenerSelectedSectionId INT = @NEWSECID; 
-- The id for the section that will show/hide based on the trigger

DECLARE @DisplayRuleName NVARCHAR(50) = 'Show/hide Abandond text';
DECLARE @SubscriberName NVARCHAR(50) = 'Show/hide Abandond text';    
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

	DELETE @SectionId
	WHERE SecId = @Id

	DELETE @TriggerFieldId
	WHERE id = @TRID
END

/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback