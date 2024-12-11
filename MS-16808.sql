USE [imperial];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16808';
DECLARE @Comments nvarchar(Max) = 
	'bold field labels';
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
UPDATE MetaReport
SET ReportAttributes = '
{
  "isPublicReport": true,
  "suppressEntityTitleDisplay": true,
  "reportTemplateId": 22,
  "fieldRenderingStrategy": "Standard",
  "sectionRenderingStrategy": "HideEmptySections",
  "subheading": "Course Outline of Record",
  "heading": "IMPERIAL COMMUNITY COLLEGE DISTRICT \n IMPERIAL VALLEY COLLEGE",
  "cssOverride": ".field-label {font-weight: bold;}.college-logo-wrapper {max-width: 100%;} .college-logo {max-width: 50%; width: 50%;}.report-title.h1 {white-space: break-spaces; margin-right: 0; margin-left: auto;} .report-title, .report-subtitle {max-width: 100%; font-size: 14px; text-align: center; font-weight: bold; margin-right: 25%; margin-left: 25%;} .body-content > .container {padding-bottom: 0;} .field-label {margin-top: 10px;}ul, ol, .col-md-12.meta-renderable.meta-field.bottom-margin-extra-small,.querytext-result-row.display-block p, .bottom-margin-normal {margin-bottom: 0;}.querytext-result-row.display-block:first-of-type p {margin-top: 0;}.querytext-result-row.display-block p {margin-top: 10px;}.meta-renderable.meta-field.bottom-margin-extra-small:empty,.col-md-12:has(.row > .meta-renderable.meta-field.bottom-margin-extra-small:empty)"
}
'
WHERE Id = 369