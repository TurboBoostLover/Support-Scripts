USE [mdc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17213';
DECLARE @Comments nvarchar(Max) = 
	'Dlete PickList fields';
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
DECLARE @Fields INTEGERS
INSERT INTO @Fields
SELECT mss.MetaTemplateId fROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
wHERE msf.MetaAvailableFieldId in (2916, 2917, 2941)

DELETE FROM MetaDisplaySubscriber WHERE MetaSelectedFieldId in (
	SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId in (
		2916, 2917, 2941
	)
)

DELETE FROM MetaDisplaySubscriber WHERE MetaDisplayRuleId in (
	SELECT Id FROM MetaDisplayRule WHERE MetaSelectedFieldId in (
		SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId in (
		2916, 2917, 2941
	)
	)
)

DELETE FROM ExpressionPart WHERE Operand1_MetaSelectedFieldId in (
		SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId in (
		2916, 2917, 2941
	)
)	

DELETE FROM MetaDisplayRule
WHERE MetaSelectedFieldId in (
	SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId in (
		2916, 2917, 2941
	)
)


DELETE FROM MetaSelectedField WHERE MetaAvailableFieldId in (2916, 2917, 2941)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Id FROM @Fields
)

