USE [gavilan];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18031';
DECLARE @Comments nvarchar(Max) = 
	'Add query text to Learning and Area Outcome';
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
Declare @clientId int =57, -- SELECT Id, Title FROM Client 
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
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (535)		--comment back in if just doing some of the mtt's

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
('VI. Learning and Area Outcome', 'ModuleYesNo', 'YesNo01Id','1'),
('VI. Learning and Area Outcome', 'ModuleYesNo', 'YesNo02Id','2'),
('VI. Learning and Area Outcome', 'ModuleYesNo', 'YesNo03Id','3'),
('VI. Learning and Area Outcome', 'ModuleYesNo', 'YesNo04Id','4'),
('VI. Learning and Area Outcome', 'ModuleExtension02', 'LongText01','5')

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
DELETE FROM MetaDisplaySubscriber
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in ('1', '2', '3', '4', '5')
)

DELETE FROM MetaDisplayRule WHERE Id in (
	SELECT Id FROM MetaDisplayRule WHERE ExpressionId in (
		SELECT ExpressionId FROM ExpressionPart WHERE Operand1_MetaSelectedFieldId in (
			SELECT fieldId FROM @Fields WHERE Action in ('1', '2', '3', '4', '5')
		)
	)
)

DELETE FROM ExpressionPart WHERE Id in (
	SELECT Id FROM ExpressionPart WHERE Operand1_MetaSelectedFieldId in (
			SELECT fieldId FROM @Fields WHERE Action in ('1', '2', '3', '4', '5')
		)
)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT
57, -- [ClientId]
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
FROM @Fields WHERE Action = '1'

DECLARE @Sec int = SCOPE_IDENTITY()

UPDATE MetaSelectedField
sET MetaSelectedSectionId = @Sec
, RowPosition = 0
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '5'
)

/* ----------------- Script for Show/Hide ----------------- */

DECLARE @TriggerselectedFieldId INT = (SELECT FieldId FROM @Fields WHERE Action = '1');     -----SET TRIGGER
DECLARE @TriggerselectedFieldId2 INT = (SELECT FieldId FROM @Fields WHERE Action = '2');     -----SET TRIGGER
DECLARE @TriggerselectedFieldId3 INT = (SELECT FieldId FROM @Fields WHERE Action = '3');     -----SET TRIGGER
DECLARE @TriggerselectedFieldId4 INT = (SELECT FieldId FROM @Fields WHERE Action = '4');     -----SET TRIGGER
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

DECLARE @Operand2Literal NVARCHAR(50) = 1;  ---------SET VALUE
-- When Show/Hide is true the field is hidden - i.e. if this is a checkbox (Boolean) this should be 'false' to show the section when checked     
-- Only one of these two should be used at a time in the MetaDisplaySubscriber query below. Delete the other one in that query and replace it with a NULL.    
-- If possible, use a section instead of a field. The reason for this is that, as of this writing (branch 28, 2014-01-13), show/hide for fields is buggy and may not work properly. 
-- Hiding an entire section is less prone to these issues due to the differences in the dynamic form DOM structure for sections vs. fields.    

DECLARE @listenerSelectedFieldId INT = NULL;			------SET LISTENER

DECLARE @listenerSelectedSectionId INT = @Sec;		------SET LISTENER
-- The id for the section that will show/hide based on the trigger

DECLARE @DisplayRuleName NVARCHAR(50) = 'Show/hide only if something is selected as no';    
DECLARE @SubscriberName NVARCHAR(50) = 'Show/hide only if something is selected as no';    
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
	VALUES (@expressionId, NULL, 1, 1, NULL, NULL, NULL, NULL, NULL, NULL)   ----If need more parents for an or add here and adjust below accordingly 
-- The new ExpressionPart Id you just inserted above 
	
DECLARE @parentExpressionPartId INT;    
SET @parentExpressionPartId = SCOPE_IDENTITY();
-- Keep in mind that if this condition is true, it will hide the field or section  
-- Inserts a new ExpressionPart Id into the ExpressionPart table and makes the previous ExpressionPart Id the Parent_ExpressionPartId for this one

INSERT INTO ExpressionPart (ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2_MetaSelectedFieldId, Operand2Literal, Operand3_MetaSelectedFieldId, Operand3Literal)    
	OUTPUT inserted.*    
	VALUES 
	(@expressionId, @parentExpressionPartId, 1, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerSelectedFieldId, NULL, @Operand2Literal, NULL, NULL),
	(@expressionId, @parentExpressionPartId, 1, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerSelectedFieldId2, NULL, @Operand2Literal, NULL, NULL),
	(@expressionId, @parentExpressionPartId, 1, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerselectedFieldId3, NULL, @Operand2Literal, NULL, NULL),
	(@expressionId, @parentExpressionPartId, 1, @ExpressionOperatorTypeId, @ComparisonDataTypeId, @TriggerselectedFieldId4, NULL, @Operand2Literal, NULL, NULL)
	
	--- share rule
INSERT INTO MetaDisplaySubscriber (SubscriberName, MetaSelectedFieldId, MetaSelectedSectionId, MetaDisplayRuleId)    
	OUTPUT inserted.*    
	VALUES (@SubscriberName, @listenerSelectedFieldId, @listenerSelectedSectionId, @displayRuleId)


UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
wHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action in ('1', '2', '3', '4', '5')
)

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
DECLARE @Department INT = (SELECT Tier2_OrganizationEntityId FROM ModuleDetail WHERE ModuleId = @EntityId);

DECLARE @Programs TABLE (ProgramId INT);
INSERT INTO @Programs
SELECT p.Id 
FROM Program AS p
WHERE p.Tier2_OrganizationEntityId = @Department
AND p.StatusAliasId = 655;

DECLARE @ProgramOutcomes TABLE (OutcomeId int)
INSERT INTO @ProgramOutcomes
SELECT po.Id FROM ProgramOutcome As po
INNER JOIN Program AS p on po.ProgramId = p.Id
INNER JOIN @Programs AS p2 on p2.ProgramId = p.Id

DECLARE @SLO TABLE (text nvarchar(max), OutcomeId int)
INSERT INTO @SLO
SELECT  dbo.ConcatWithSep_Agg ('; ',co.OutcomeText), ProgramOutcomeId FROM ProgramOutcomeMatching AS pom
INNER JOIN @ProgramOutcomes AS po on pom.ProgramOutcomeId = po.OutcomeId
INNER JOIN CourseOutcome As co on pom.CourseOutcomeId = co.Id
group by ProgramOutcomeId

DECLARE @ILO TABLE (text nvarchar(max), OutcomeId int)
INSERT INTO @ILO
SELECT dbo.ConcatWithSep_Agg ('; ',clo.Description), ProgramOutcomeId FROM ClientLearningOutcomeProgramOutcome AS clop
INNER JOIN @ProgramOutcomes AS po on clop.ProgramOutcomeId = po.OutcomeId
INNER JOIN ClientLearningOutcome As clo on clop.ClientLearningOutcomeId = clo.Id
group by ProgramOutcomeId

DECLARE @txt TABLE (ProgramId int, txt NVARCHAR(MAX))
INSERT INTO @txt
SELECT p2.Id, dbo.ConcatWithSep_Agg (
            '',
            CONCAT(
                '<tr>',
                '<td style=""border:1px solid black; padding:8px;"">', po.Outcome, '</td>',
                '<td style=""border:1px solid black; padding:8px;"">', slo.text, '</td>',
                '<td style=""border:1px solid black; padding:8px;"">', ilo.text, '</td>',
                '</tr>'
            ))
FROM @Programs AS p
INNER JOIN Program AS p2 ON p.ProgramId = p2.Id
INNER JOIN ProgramOutcome AS po ON po.ProgramId = p2.Id
LEFT JOIN @SLO AS slo on slo.OutcomeId = po.Id
LEFT JOIN @ILO AS ilo on ilo.OutcomeId = po.Id
group by p2.Id

SELECT DISTINCT dbo.ConcatWithSep_Agg('<br>', 
    CONCAT(
				p2.EntityTitle,
        '<table style=""width:100%; border:1px solid black; border-collapse:collapse;"">',
        '<tr>',
        '<th style=""border:1px solid black; padding:8px;"">Outcome</th>',
        '<th style=""border:1px solid black; padding:8px;"">SLO</th>',
        '<th style=""border:1px solid black; padding:8px;"">ILO</th>',
        '</tr>',
        txt.txt
        ,
        '</table>'
    )) AS Text
FROM Program AS p2 
INNER JOIN ProgramOutcome AS po ON po.ProgramId = p2.Id
INNER JOIN @txt as txt on txt.ProgramId = p2.Id
LEFT JOIN @SLO AS slo on slo.OutcomeId = po.Id
LEFT JOIN @ILO AS ilo on ilo.OutcomeId = po.Id
WHERE p2.Id in (SELECT ProgramId FROM @Programs)
GROUP BY p2.EntityTitle, po.Outcome;
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'ProgramOutcome', 'Id', 'Title', @CSQL, @CSQL, 'Order By SortOrder', 'Programs in a Program Review', 2)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Report', -- [DisplayName]
9218, -- [MetaAvailableFieldId]
SectionId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
100, -- [Width]
2, -- [WidthUnit]
200, -- [Height]
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
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Fields WHERE Action = '1'
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

exec EntityExpand @clientId =@clientId , @entityTypeId =@Entitytypeid

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback