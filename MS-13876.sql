USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13876';
DECLARE @Comments nvarchar(Max) = 
	'Update MFKCC for query to not break tab''s';
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
DECLARE @Table Table (TemplateId int, FieldId int)
INSERT INTO @Table (TemplateId, FieldId)
	SELECT mt.MetaTemplateId, msf.MetaSelectedFieldId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaAvailableField AS maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
	WHERE msf.MetaForeignKeyLookupSourceId = 138
	AND Msf.MetaPresentationTypeId = 1
	AND maf.MetaAvailableFieldTypeId = 1
	AND mt.ClientId = 3

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = 1
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Table
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT TemplateId FROM @Table
)