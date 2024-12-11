USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16691';
DECLARE @Comments nvarchar(Max) = 
	'Remove Condtion drop down from course blocks, Hide Active Participartory on the course form when noncredit';
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
DECLARE @RULES TABLE (tempId int, ruleId int)
INSERT INTO @RULES
SELECT mss.MetaTemplateId ,MetaDisplayRuleId FROM MetaDisplaySubscriber as mds
INNER JOIN MetaSelectedSection AS mss on mds.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mss.MetaSelectedSectionId in(
	SELECT mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE Msf.MetaAvailableFieldId = 213
)

DELETE FROM MetaSelectedFieldAttribute WHERE MetaSelectedFieldId in (
	SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId = 1122
)

DELETE FROM MetaSelectedField WHERE MetaAvailableFieldId = 1122

INSERT INTO MetaDisplaySubscriber
(SubscriberName, MetaSelectedSectionId, MetaDisplayRuleId)
SELECT 'Hide on non-credit', mss.MetaSelectedSectionId, r.ruleId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @RULES AS r on r.tempId = mss.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 1748
UNION
SELECT 'Hide on non-credit', mss.MetaSelectedSectionId, r.ruleId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @RULES AS r on r.tempId = mss.MetaTemplateId
WHERE msf.MetaAvailableFieldId = 3427

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT tempId FROM @RULES
	UNIOn
	SELECT MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.EntityTypeId = 2
)