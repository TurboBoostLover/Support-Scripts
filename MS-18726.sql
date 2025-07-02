USE [fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18726';
DECLARE @Comments nvarchar(Max) = 
	'Clean up show hide for speed';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
DECLARE @TriggerField TABLE (FieldId int, TempId int, ExpressionId int, expressionPartId int, ruleId int)
INSERT INTO @TriggerField
SELECT msf.MetaSelectedFieldId, mss.MetaTemplateId, ep.ExpressionId, ep.Id, mdr.Id
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN ExpressionPart AS ep on ep.Operand1_MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaDisplayRule AS mdr on mdr.ExpressionId = ep.ExpressionId
WHERE msf.MetaAvailableFieldId = 3430
ORDER by MetaTemplateId;

DECLARE @Keep TABLE (FieldId int, TempId int, ExpressionId int, expressionPartId int, ruleId int); 

WITH RankedRows AS (
    SELECT 
        msf.MetaSelectedFieldId, 
        mss.MetaTemplateId, 
        ep.ExpressionId, 
        ep.Id,
				mdr.Id AS [MdrId], 
        ROW_NUMBER() OVER (PARTITION BY mss.MetaTemplateId ORDER BY ep.Id) AS RowNum
    FROM MetaSelectedField AS msf
    INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
    INNER JOIN ExpressionPart AS ep ON ep.Operand1_MetaSelectedFieldId = msf.MetaSelectedFieldId
		INNER JOIN MetaDisplayRule AS mdr on mdr.ExpressionId = ep.ExpressionId
    WHERE msf.MetaAvailableFieldId = 3430
)
INSERT INTO @Keep
SELECT MetaSelectedFieldId, MetaTemplateId, ExpressionId, Id, mdrId
FROM RankedRows
WHERE RowNum = 1;

UPDATE MetaDisplaySubscriber
SET MetaDisplayRuleId = 
	CASE
		WHEN MetaDisplayRuleId = 294 THEN 291
		WHEN MetaDisplayRuleId = 295 THEN 292
		WHEN MetaDisplayRuleId = 296 THEN 293
		WHEN MetaDisplayRuleId = 297 THEN 291
		WHEN MetaDisplayRuleId = 298 THEN 292
		WHEN MetaDisplayRuleId = 299 THEN 293
		WHEN MetaDisplayRuleId = 300 THEN 291
		WHEN MetaDisplayRuleId = 301 THEN 292
		WHEN MetaDisplayRuleId = 302 THEN 293
	ELSE MetaDisplayRuleId
	END
WHERE MetaDisplayRuleId in (
	SELECT RuleId FROM @TriggerField
)


DELETE FROM MetaDisplayRule
WHERE ExpressionId in (
	SELECT expressionId FROM @TriggerField
)
AND 
ExpressionId not in (
	SELECT ExpressionId FROM @Keep
)

DELETE FROM ExpressionPart 
WHERE ExpressionId in (
	SELECT expressionId FROM @TriggerField
)
AND 
ExpressionId not in (
	SELECT expressionId FROM @Keep
)

DELETE FROM Expression 
WHERE Id in (
	SELECT expressionId FROM @TriggerField
)
AND 
Id not in (
	SELECT ExpressionId FROM @Keep
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 3430
)