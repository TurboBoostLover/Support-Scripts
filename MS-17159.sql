USE [aurak];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17159';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Form';
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
('General Information', 'CourseAttribute', 'Related_ProgramId','Update1'),
('General Information', 'CourseAttribute', 'TypeOfCourseId','Update2'),
('General Education', 'CourseYesNo', 'YesNo01Id', 'Ping'),
('General Education', 'CourseProposal', 'RevisionTypeId', 'Ping2'),
('General Education', 'CourseGeneralEducation', 'GeneralEducationId', 'Ping3')

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
UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update1'
)

UPDATE MetaSelectedField
SET RowPosition = RowPosition - 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = 'Update2'
)


insert into MetaSelectedFieldAttribute
(Name,[Value],MetaSelectedFieldId)
SELECT 'FilterSubscriptionTable','CourseAttribute', FieldId FROM @Fields WHERE Action = 'Update1'
UNION
SELECT 'FilterSubscriptionColumn','TypeOfCourseId', FieldId FROM @Fields WHERE Action = 'Update1'
UNION
SELECT 'FilterTargetTable','CourseAttribute', FieldId FROM @Fields WHERE Action = 'Update1'
UNION
SELECT 'FilterTargetColumn','Related_ProgramId', FieldId FROM @Fields WHERE Action = 'Update1'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
select p.Id as Value,
p.Title as Text,
ProgramTypeId AS FilterValue,
ProgramTypeId AS filterValue
from Program p 
inner join StatusAlias sa on p.StatusAliasId = sa.Id 
where sa.StatusBaseId in (1)
and ProgramTypeId IS NOT NULL
UNION
select p.Id as Value,
p.Title as Text,
4 AS FilterValue,
4 AS filterValue
from Program p 
inner join StatusAlias sa on p.StatusAliasId = sa.Id 
where sa.StatusBaseId in (1)
and ProgramTypeId = 1
UNION
select p.Id as Value,
p.Title as Text,
5 AS FilterValue,
5 AS filterValue
from Program p 
inner join StatusAlias sa on p.StatusAliasId = sa.Id 
where sa.StatusBaseId in (1)
and ProgramTypeId = 2
'
, LookupLoadTimingType = 3
WHERE Id = 9

--------------------------------------------------------------
DECLARE @SHOWHIDE TABLE (TempId int, triggerId int, ListenerId int)
INSERT INTO @SHOWHIDE
SELECT DISTINCT f.TemplateId, f.FieldId, f2.SectionId FROM @Fields as F
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
WHERE f.Action = 'Update2'
and f2.Action = 'Ping'


while exists(select top 1 1 from @SHOWHIDE)
begin
	declare @tempId int = (SELECT TOP 1 TempId FROM @SHOWHIDE)
	declare @Trigger int = (SELECT triggerId FROM @SHOWHIDE WHERE TempId = @tempId)
	declare @Sec int = (SELECT ListenerId FROM @SHOWHIDE WHERE TempId = @tempId)

	DECLARE @TriggerselectedFieldId INT = @Trigger;  -----------------------------------------------------------------------------------------------------------------
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

	DECLARE @Operand2Literal NVARCHAR(50) = 2;  
	-- When Show/Hide is true the field is hidden - i.e. if this is a checkbox (Boolean) this should be 'false' to show the section when checked     
	-- Only one of these two should be used at a time in the MetaDisplaySubscriber query below. Delete the other one in that query and replace it with a NULL.    
	-- If possible, use a section instead of a field. The reason for this is that, as of this writing (branch 28, 2014-01-13), show/hide for fields is buggy and may not work properly. 
	-- Hiding an entire section is less prone to these issues due to the differences in the dynamic form DOM structure for sections vs. fields.    

	DECLARE @listenerSelectedFieldId INT = NULL;  

	DECLARE @listenerSelectedSectionId INT = @Sec; ----------------------------------------------------------------------------------------------------------------
	-- The id for the section that will show/hide based on the trigger

	DECLARE @DisplayRuleName NVARCHAR(50) = 'Show/hide GE TAB';    
	DECLARE @SubscriberName NVARCHAR(50) = 'Show/hide GE TAB';    
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
		VALUES 
		(@expressionId, @parentExpressionPartId, 1, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerSelectedFieldId, NULL, @Operand2Literal, NULL, NULL),
		(@expressionId, @parentExpressionPartId, 2, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerSelectedFieldId, NULL, 5, NULL, NULL),
				(@expressionId, @parentExpressionPartId, 2, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerSelectedFieldId, NULL, 3, NULL, NULL)
	

	INSERT INTO MetaDisplaySubscriber (SubscriberName, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleId)    
		OUTPUT inserted.*    
		VALUES (@SubscriberName, @listenerSelectedFieldId, @listenerSelectedSectionId, @displayRuleId)

	DELETE FROM @SHOWHIDE
	WHERE TempId = @tempId

end

DECLARE @Sec2 TABLE (SecId int, TempId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.MetaTemplateId INTO @sec2
SELECT
1, -- [ClientId]
TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
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
FROM @Fields WHERE Action = 'Ping'

DECLARE @Temp TABLE (SecId int, part int)

UPDATE MetaSelectedSection
SET MetaSelectedSection_MetaSelectedSectionId = s.SecId
output inserted.MetaSelectedSectionId, inserted.MetaSelectedSection_MetaSelectedSectionId INTO @Temp
FROM MetaSelectedSection AS mss
INNER JOIN @Fields AS f on mss.MetaSelectedSectionId = f.SectionId
INNER JOIN @Sec2 AS s on f.TemplateId = s.TempId
WHERE f.Action in ('Ping2', 'Ping3')

DECLARE @Temp2 INTEGERS

UPDATE MetaDisplaySubscriber
SET MetaSelectedSectionId = t.part
output inserted.MetaSelectedSectionId INTO @Temp2
FROM MetaDisplaySubscriber AS mds 
INNER JOIN @Temp AS t on mds.MetaSelectedSectionId = t.SecId

;WITH CTE AS (
    SELECT
        MDS.*,
        ROW_NUMBER() OVER (PARTITION BY MetaSelectedSectionId ORDER BY Id DESC) AS rn
    FROM
        MetaDisplaySubscriber MDS
    WHERE
        MetaSelectedSectionId IN (SELECT Id FROM @Temp2)
)
DELETE FROM CTE WHERE rn = 1;

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'triggersectionrefresh', f.TabId, f2.FieldId FROM @Fields AS f
INNER JOIN @Fields AS f2 on f.TemplateId = f2.TemplateId
WHERE f.Action = 'Ping2'
and f2.Action = 'Update2'
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback