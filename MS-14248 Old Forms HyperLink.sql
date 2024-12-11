USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14248';
DECLARE @Comments nvarchar(Max) = 
	'Update Hyper Link';
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
UPDATE MetaSelectedFieldAttribute 
SET Value = 'https://peralta4-my.sharepoint.com/:b:/g/personal/hsisneros_peralta_edu/EU5dBY0OEF9Bt1ZONa4Ry74B2kAQvJ76PLEu0oidEotgVw?e=qIkU5G'
WHERE Value = 'https://laney.edu/institutionaleffectiveness/wp-content/uploads/sites/227/2019/11/Resource-Request-Ranking-Rubric-2019-20-FINAL.docx.pdf'

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedSection AS mss2 on mss2.MetaSelectedSection_MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss2.MetaSelectedSectionId
	INNER JOIN MetaSelectedFieldAttribute AS msfa on msfa.MetaSelectedFieldId = msf.MetaSelectedFieldId
	WHERE Value = 'https://peralta4-my.sharepoint.com/:b:/g/personal/hsisneros_peralta_edu/EU5dBY0OEF9Bt1ZONa4Ry74B2kAQvJ76PLEu0oidEotgVw?e=qIkU5G'
)