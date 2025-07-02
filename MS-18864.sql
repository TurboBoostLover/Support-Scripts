USE [madera];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18864';
DECLARE @Comments nvarchar(Max) = 
	'Course Form Updates';
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
DECLARE @Trigger1 int = (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE msf.MetaAvailableFieldId = 182
	and mt.MetaTemplateTypeId = 1
)

DECLARE @List1 int = (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE msf.MetaAvailableFieldId = 1704
	and mt.MetaTemplateTypeId = 1
)

DECLARE @Trigger2 int = (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE msf.MetaAvailableFieldId = 182
	and mt.MetaTemplateTypeId = 14
)

DECLARE @List2 int = (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE msf.MetaAvailableFieldId = 1704
	and mt.MetaTemplateTypeId = 14
)

/* ----------------- Proc for Show/Hide ----------------- */
EXEC upAddShowHideRule 
	@TriggerselectedFieldId =  @Trigger1,
		-- The id for the field that triggers the show/hide
	@TriggerselectedSectionId = NULL,
		-- Pointless
	@displayRuleTypeId = 2,
		-- DisplayRuleType 1 = FieldValidation, 2 = FieldDisplay, 3 = FieldCalculation, 4 = SectionDisplay   
		-- Always set to 2
	@ExpressionOperatorTypeId = 17,
		-- SELECT * FROM ExpressionOperatorType 
		-- ExpressionOperatorType 16 = NotEqual - Operand 1 must not be the same value as Operand 2
		-- Note: EOT 16 will throw an error if ComparisonDataType is 1
	@ComparisonDataTypeId = 3,
		-- ComparisonDataType 1 = Decimal, 2 = DateTime, 3 = String, 4 = Boolean
	@Operand2Literal = -1,
		-- When Show/Hide is true the field is hidden - i.e. if this is a checkbox (Boolean) this should be 'false' to show the section when checked     
		-- Only one of these two should be used at a time in the MetaDisplaySubscriber query below. Delete the other one in that query and replace it with a NULL.    
		-- If possible, use a section instead of a field. The reason for this is that, as of this writing (branch 28, 2014-01-13), show/hide for fields is buggy and may not work properly. 
		-- Hiding an entire section is less prone to these issues due to the differences in the dynamic form DOM structure for sections vs. fields.
		--Maverick fields work fine though
	@Operand3Literal = NULL,
	@listenerSelectedFieldId = @List1,
		-- The id for the Field that will show/hide based on the trigger
	@listenerSelectedSectionId = NULL,
		-- The id for the section that will show/hide based on the trigger
	@DisplayRuleName = '',
		--Get Put on MetaDisplayRule Table
	@SubscriberName = ''
		--Get Put on MetaDisplaySubscriber Table

----------------------------------------------------------------------------------
EXEC upAddShowHideRule 
	@TriggerselectedFieldId =  @Trigger2,
		-- The id for the field that triggers the show/hide
	@TriggerselectedSectionId = NULL,
		-- Pointless
	@displayRuleTypeId = 2,
		-- DisplayRuleType 1 = FieldValidation, 2 = FieldDisplay, 3 = FieldCalculation, 4 = SectionDisplay   
		-- Always set to 2
	@ExpressionOperatorTypeId = 17,
		-- SELECT * FROM ExpressionOperatorType 
		-- ExpressionOperatorType 16 = NotEqual - Operand 1 must not be the same value as Operand 2
		-- Note: EOT 16 will throw an error if ComparisonDataType is 1
	@ComparisonDataTypeId = 3,
		-- ComparisonDataType 1 = Decimal, 2 = DateTime, 3 = String, 4 = Boolean
	@Operand2Literal = -1,
		-- When Show/Hide is true the field is hidden - i.e. if this is a checkbox (Boolean) this should be 'false' to show the section when checked     
		-- Only one of these two should be used at a time in the MetaDisplaySubscriber query below. Delete the other one in that query and replace it with a NULL.    
		-- If possible, use a section instead of a field. The reason for this is that, as of this writing (branch 28, 2014-01-13), show/hide for fields is buggy and may not work properly. 
		-- Hiding an entire section is less prone to these issues due to the differences in the dynamic form DOM structure for sections vs. fields.
		--Maverick fields work fine though
	@Operand3Literal = NULL,
	@listenerSelectedFieldId = @List2,
		-- The id for the Field that will show/hide based on the trigger
	@listenerSelectedSectionId = NULL,
		-- The id for the section that will show/hide based on the trigger
	@DisplayRuleName = '',
		--Get Put on MetaDisplayRule Table
	@SubscriberName = ''
		--Get Put on MetaDisplaySubscriber Table
----------------------------------------------------------------------------------

INSERT INTO InstructionType
(Title, SortOrder, ClientId, StartDate)
VALUES
('Guided Practice', 7, 1, GETDATE())

update it 
set SortOrder = sorted.rownum 
from InstructionType it
inner join ( 
select id, ROW_NUMBER() over (order by Title) rownum 
from InstructionType 
) sorted on it.Id = sorted.Id

UPDATE MetaSelectedField
SET DefaultDisplayType = 'CKEditor'
, MetaPresentationTypeId = 25
WHERE MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId in (1, 14)
	and msf.MetaAvailableFieldId in (2555, 12013)
)

INSERT INTO EvaluationMethod
(Title, SortOrder, ClientId, StartDate)
VALUES
('Final Exam', 11, 1, GETDATE()),
('Computational Problem Solving', 12, 1, GETDATE())

update em 
set SortOrder = sorted.rownum 
from EvaluationMethod em
inner join ( 
select id, ROW_NUMBER() over (order by Title) rownum 
from EvaluationMethod 
) sorted on em.Id = sorted.Id

UPDATE MetaSelectedSection
SET SectionName = 'MCC General Education (before Fall 2025)'
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId in (1, 14)
	and msf.MetaAvailableFieldId in (2629)
)

UPDATE MetaSelectedSection
SET SectionName = 'MCC General Education'
WHERE MetaSelectedSectionId in (
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	WHERE mt.MetaTemplateTypeId in (1, 14)
	and msf.MetaAvailableFieldId in (2641)
)

UPDATE MetaSelectedField
SET DisplayName = 'Course Subject and Number (i.e. ENGL C1000)'
WHERE MetaAvailableFieldId = 2962

UPDATE MetaSelectedField
SET DisplayName = 'Course Title'
WHERE MetaAvailableFieldId = 2963

UPDATE GenericMaxText
SET TextMax18 = CONCAT(TextMax18, ' ', TextMax19)
WHERE CourseId IS NOT NULL
and (TextMax18 IS NOT NULL or TextMax19 IS NOT NULL)

UPDATE GenericMaxText
SET TextMax19 = TextMax20
WHERE CourseId IS NOT NULL
and TextMax20 IS NOT NULL

DELETE FROM MetaSelectedField
WHERE MetaAvailableFieldId = 2964

UPDATE GenericMaxText
SET TextMax20 = NULL
WHERE CourseId IS NOT NULL
and TextMax20 IS NOT NULL

UPDATE MetaSelectedField
SET DisplayName = 'Course Subject and Number (i.e. ENGL C1000)'
WHERE MetaAvailableFieldId = 2966

UPDATE MetaSelectedField
SET DisplayName = 'Course Title'
WHERE MetaAvailableFieldId = 2967

UPDATE GenericMaxText
SET TextMax22 = CONCAT(TextMax22, ' ', TextMax23)
WHERE CourseId IS NOT NULL
and (TextMax23 IS NOT NULL or TextMax22 IS NOT NULL)

UPDATE GenericMaxText
SET TextMax23 = TextMax24
WHERE CourseId IS NOT NULL
and TextMax24 IS NOT NULL

DELETE FROM MetaSelectedField
WHERE MetaAvailableFieldId = 2968

UPDATE GenericMaxText
SET TextMax24 = NULL
WHERE CourseId IS NOT NULL
and TextMax24 IS NOT NULL

UPDATE MetaSelectedField
SET DisplayName = 'Course Subject and Number (i.e. ENGL C1000)'
WHERE MetaAvailableFieldId = 2970

UPDATE MetaSelectedField
SET DisplayName = 'Course Title'
WHERE MetaAvailableFieldId = 2971

UPDATE GenericMaxText
SET TextMax22 = CONCAT(TextMax26, ' ', TextMax27)
WHERE CourseId IS NOT NULL
and (TextMax27 IS NOT NULL or TextMax26 IS NOT NULL)

UPDATE GenericMaxText
SET TextMax27 = TextMax28
WHERE CourseId IS NOT NULL
and TextMax28 IS NOT NULL

DELETE FROM MetaSelectedField
WHERE MetaAvailableFieldId = 2972

UPDATE GenericMaxText
SET TextMax28 = NULL
WHERE CourseId IS NOT NULL
and TextMax28 IS NOT NULL

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = 1
and mt.Active = 1