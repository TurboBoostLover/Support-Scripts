USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15302';
DECLARE @Comments nvarchar(Max) = 
	'Fix Show hide';
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
DELETE FROM MetaDisplaySubscriber WHERE MetaDisplayRuleId in (
11, 51, 35
)

DELETE FROM MetaDisplayRule WHERE Id in (11, 51, 35)

DELETE FROM ExpressionPart WHERE ExpressionId in (
23, 51, 43
)

DELETE FROM Expression WHERE Id in (23, 51, 43)

DECLARE @Trigger TABLE (mt int, msf int, dname nvarchar(max))
INSERT INTO @Trigger
SELECT mt.MetaTemplateId, msf.MetaSelectedFieldId, msf.DisplayName FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate As mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 2832


DECLARE @Listener TABLE (mt int, mss int, dname NVARCHAR(MAX))
INSERT INTO @Listener
SELECT mt.MetaTemplateId, mss.MEtaSelectedSectionId, mss.SectionName FROM MetaSelectedSection AS mss
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mss.MetaBaseSchemaId in (
86, 1305
)