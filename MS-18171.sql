USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18171';
DECLARE @Comments nvarchar(Max) = 
	'Update show hide on Program Review Form';
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
INSERT INTO ExpressionPart
(ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId)
VALUES
(4808, 10695, 1, 2)

DECLARE @Id int = SCOPE_IDENTITY()

UPDATE ExpressionPart
SET Parent_ExpressionPartId = @Id
, ExpressionOperatorTypeId = 3
, Operand2Literal = 22
WHERE Id = 10696

DECLARE @Field int = (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 95
	and msf.MetaAvailableFieldId = 4391
)

INSERT INTO ExpressionPart
(ExpressionId, Parent_ExpressionPartId, SortOrder, ExpressionOperatorTypeId, ComparisonDataTypeId, Operand1_MetaSelectedFieldId, Operand2Literal)
VALUES
(4808, @Id, 2, 3, 3, @Field, 23),
(4808, @Id, 3, 3, 3, @Field, 26)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 95
	and msf.MetaAvailableFieldId = 4391
)