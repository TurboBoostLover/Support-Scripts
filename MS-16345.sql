USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16345';
DECLARE @Comments nvarchar(Max) = 
	'Map over Data from V2';
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
DECLARE @TABLE TABLE (NewId int, Goals nvarchar(max), Opp nvarchar(max), planning nvarchar(max), Projections nvarchar(max), place nvarchar(max))
INSERT INTO @TABLE
SELECT p2.Id, po.OUTCOME, p.CAREER_OPTIONS, po.MASTER_PLANNING, po.ENROLLMENT_COMPLETER, po.SIMILAR_PROGRAMS FROM LasPositas_v2.dbo.PROGRAM_OUTCOMES AS po
INNER JOIN LasPositas_v2.dbo.PROGRAMS AS p on po.PROGRAMS_ID = p.PROGRAMS_ID
INNER JOIN laspositas.dbo.vKeyTranslation AS vkey on vkey.OldId = p.PROGRAMS_ID and vkey.DestinationTable = 'Program'
INNER JOIN laspositas.dbo.Program AS p2 on vkey.NewId = p2.Id

UPDATE p
SET p.NeedsAssess = t.Goals
, p.EmployerSurvey = t.planning
, p.ChangeRequest = t.place
FROM laspositas.dbo.Program AS p
INNER JOIN @TABLE As t on p.Id = t.NewId

UPDATE pd
SET pd.SimilarPrograms = t.Opp
, pd.MasterPlanning = Projections
FROM laspositas.dbo.ProgramDetail AS pd
INNER JOIN @TABLE AS t on pd.ProgramId = t.NewId

DECLARE @Triggers TABLE (msfId int)
INSERT INTO @Triggers
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId = 1202

DECLARE @Subscrbers TABLE (msfId int)
INSERT INTO @Subscrbers
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId = 568

DECLARE @Rules TABLE (Id int)
INSERT INTO @Rules
SELECT Id FROM MetaDisplayRule WHERE Id in (
	SELECT MetaDisplayRuleId FROM MetaDisplaySubscriber WHERE MetaSelectedFieldId in (
		SELECT msfId FROM @Subscrbers
	)
)

DECLARE @Expressions TABLE (Id int)
INSERT INTO @Expressions
SELECT ExpressionId FROM MetaDisplayRule WHERE Id in (
	SELECT Id FROM @Rules
)

DELETE FROM MetaDisplaySubscriber
WHERE MetaSelectedFieldId in (
	SELECT msfId FROM @Subscrbers
)

DELETE FROM MetaDisplayRule
WHERE Id in (
	SELECT Id FROM @Rules
)

DELETE FROM ExpressionPart WHERE ExpressionId in (
	SELECT Id FROM @Expressions
)

DELETE FROM Expression WHERE Id in (
	SELECT Id FROM @Expressions
)
----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
DECLARE @Tr TABLE (TId int, trigg int)
INSERT INTO @Tr
SELECT DISTINCT mt.MetaTemplateId, msf.MetaSelectedFieldId FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 1202

DECLARE @List TABLE (TId int, list int)
INSERT INTO @List
SELECT DISTINCT mt.MetaTemplateId, msf2.MetaSelectedFieldId FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf2 on msf2.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf2.MetaAvailableFieldId = 568

DECLARE @SHOWHIDE TABLE (TId int, trigg int, list int)
INSERT INTO @SHOWHIDE
SELECT DISTINCT tr.TId, tr.trigg, list.list FROM @Tr AS tr
INNER JOIN @List AS list on list.TId = tr.TId

while exists(select top 1 1 from @SHOWHIDE)
begin
	declare @TemplateId int = (SELECT Top 1 TID FROM @SHOWHIDE)
	declare @Trigger int = (SELECT trigg FROM @SHOWHIDE WHERE TId = @TemplateId)
	declare @Sec int = (SELECT list FROM @SHOWHIDE WHERE TId = @TemplateId)

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

	DECLARE @listenerSelectedFieldId INT = @Sec;  

	DECLARE @listenerSelectedSectionId INT = NULL; ----------------------------------------------------------------------------------------------------------------
	-- The id for the section that will show/hide based on the trigger

	DECLARE @DisplayRuleName NVARCHAR(50) = 'Show/hide Career Op';    
	DECLARE @SubscriberName NVARCHAR(50) = 'Show/hide Career Op';    
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
WHERE TId = @TemplateId

end

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaTemplateType As mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.EntityTypeId = 1
)