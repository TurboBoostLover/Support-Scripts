USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19989';
DECLARE @Comments nvarchar(Max) = 
	'Fix show/hide on the content tab';
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
DECLARE @Expressions TABLE (ExpressionId int, ParentId int, TemplateId int)
INSERT INTO @Expressions
SELECT ep.ExpressionId, ep.Parent_ExpressionPartId, mss.MetaTemplateId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaDisplaySubscriber AS mds on mds.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaDisplayRule AS mdr on mds.MetaDisplayRuleId = mdr.Id
INNER JOIN ExpressionPart AS ep on mdr.ExpressionId = ep.ExpressionId
WHERE msf.MetaAvailableFieldId = 3455
and ep.ExpressionOperatorTypeId = 2

DECLARE @Other TABLE (FieldId int, TemplateId int)
INSERT INTO @Other
SELECT msf.MetaSelectedFieldId, mss.MetaTemplateId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 1422

INSERT INTO ExpressionPart
(ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2Literal)
SELECT DISTINCT ExpressionId, ParentId, 1, 2, NULL, NULL, NULL FROM @Expressions AS e INNER JOIN @Other AS o on e.TemplateId = o.TemplateId

DECLARE @Expressions2 TABLE (ExpressionId int, ParentId int, TemplateId int)
INSERT INTO @Expressions2
SELECT DISTINCT ep.ExpressionId, ep.Id, mss.MetaTemplateId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaDisplaySubscriber AS mds on mds.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaDisplayRule AS mdr on mds.MetaDisplayRuleId = mdr.Id
INNER JOIN ExpressionPart AS ep on mdr.ExpressionId = ep.ExpressionId
WHERE msf.MetaAvailableFieldId = 3455
and ep.ExpressionOperatorTypeId = 2
and ep.Id not in (
	SELECT Parent_ExpressionPartId FROM ExpressionPart WHERE Parent_ExpressionPartId IS NOT NULL
)

INSERT INTO ExpressionPart
(ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2Literal)
SELECT ExpressionId, ParentId, 1, 3, 1, FieldId, 0 FROM @Expressions2 AS e INNER JOIN @Other AS o on e.TemplateId = o.TemplateId
UNION
SELECT ExpressionId, ParentId, 1, 17, 3, FieldId, -1 FROM @Expressions2 AS e INNER JOIN @Other AS o on e.TemplateId = o.TemplateId

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN @Other AS o on o.TemplateId = mt.MetaTemplateId
INNER JOIN @Expressions As e on e.TemplateId = mt.MetaTemplateId