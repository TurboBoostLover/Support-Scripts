USE [reedley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13808';
DECLARE @Comments nvarchar(Max) = 
	'Update Public View on reports';
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
UPDATE Config.ClientSetting
SET AllowAnonymousAllFieldsReport = 1

UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":true,"reportTemplateId":3,"fieldRenderingStrategy":"HideEmptyFields ","showImplementDate":true,"cssOverride":".report-title{font-size: 32px; max-width: 50%}\r\n.bottom-margin-small::before{display: none !important} \r\n.report-header{margin-bottom: 0; padding-bottom: 0 !important}\r\n.report-entity-title{padding-top: 1vh; font-weight: bold}\r\n.report-implementdate{display: none}"}'
WHERE Id = 362

UPDATE MetaReport
SET ReportAttributes ='{"isPublicReport":true,"showImplementDate":true}'
WHERE Id = 3

UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":true,"reportTemplateId":12,"sectionRenderingStrategy":"HideEmptySections","showImplementDate":true,"cssOverride":"--.section-name{font-size: 14px}\r\n.report-title{font-size: 32px; max-width: 50%}\r\n.bottom-margin-small::before{display: none !important} \r\n.report-header{margin-bottom: 0; padding-bottom: 0 !important}\r\n.report-entity-title{padding-top: 1vh}"}'
WHERE Id = 385

UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":true,"reportTemplateId":4,"fieldRenderingStrategy":"HideEmptyFields ","showImplementDate":true}'
WHERE Id = 363

UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":true,"reportTemplateId":10,"sectionRenderingStrategy":"HideEmptySections","showImplementDate":true}'
WHERE Id = 383

INSERT INTO Config.PublicSearchStatusAlias
(PublicSearchId, StatusAliasId)
VALUES
(1, 1),
(1, 4),
(1, 5),
(1, 6),
(1, 7), 
(1, 9)