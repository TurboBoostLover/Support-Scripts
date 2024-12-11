USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13849';
DECLARE @Comments nvarchar(Max) = 
	'Delete Literal Drop Downs';
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
DECLARE @Templates TABLE (TId int, FId int)
INSERT INTO @Templates (TId, FId)
SELECT mt.MetaTemplateId, msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE msf.MetaPresentationTypeId = 101

--SELECT * FROM Course WHERE MetaTemplateId in (1, 65)
--SELECT * FROM Program WHERE MetaTemplateId in (1, 65)
--SELECT * FROM Module WHERE MetaTemplateId in (1, 65)

--SELECT * FROM MetaTemplate WHERE MetaTemplateId in (1,65)
--SELECT * FROM MetaTemplateType WHERE MetaTemplateTypeId in (1,68)

DELETE FROM MetaLiteralList WHERE MetaSelectedFieldId in (SELECT FId FROM @Templates)

DELETE FROM MetaSelectedField 
OUTPUT deleted.MetaSelectedFieldId
WHERE MetaSelectedFieldId in (SELECT FId FROM @Templates)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (SELECT DISTINCT TId FROM @Templates)