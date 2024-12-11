USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17758';
DECLARE @Comments nvarchar(Max) = 
	'Update Public Reports';
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
SET ReportAttributes = '{"isPublicReport":true,"reportTemplateId":7,"cssOverride":".col-xs-2.col-sm-2.col-md-2.right-column.text-right{text-align: right;} @media print {.row{display: flex;}}"}'
WHERE Id = 475

UPDATE MetaReport
SET ReportAttributes = '{"suppressEntityTitleDisplay":"true","heading":"","isPublicReport":false,"reportTemplateId":20,"fieldRenderingStrategy":"HideEmptyFields","sectionRenderingStrategy":"HideEmptySections"}'
WHERE Id = 517

UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":false,"reportTemplateId":8}'
WHERE Id = 477

UPDATE MetaReport
SET ReportAttributes = '{"reportTemplateId":9}'
WHERE Id = 476

UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":false,"reportTemplateId":6,"cssOverride":".program-blocks-report {background-color: #981E32; display: flex; justify-content: center; margin-top: 5px; margin-bottom: -10px; width: 100%;} .pb-columns {padding-top: 5px; padding-bottom: 5px; color: white; font-weight: bold;}.pb-columns.pb-left {text-align: left; width: 50%;} .pb-columns.pb-right {text-align: right; width: 50%;} #pb-left-col {padding-left: 20px; padding-right: 0px; width: 35%;} #pb-left-mid-col {padding-left: 20px; padding-right: 20px; width: 65%;} #pb-right-mid-col {padding-left: 20px; padding-right: 10px; width: 85%;} #pb-right-col {padding-left: 20px; padding-right: 20px; width: 15%;} @media screen and (min-width: 1300px) {.program-blocks-report {width: 100.7%;}}@media screen and (max-width: 1299px) {.program-blocks-report {width: 101%;}}@media screen and (max-width: 1050px) {.program-blocks-report {width: 101.5%;}}@media screen and (max-width: 850px) {.program-blocks-report {width: 101.75%;}}@media screen and (max-width: 740px) {.program-blocks-report {width: 102%;}}@media screen and (max-width: 500px) {.program-blocks-report {width: 103%;}}.block-entry .non-course-row-core .two-column.left-column.text-left {width: 80%;}.block-entry .non-course-row-core .two-column.right-column.text-right {width: 11.25%;}.block-entry .course-row-core .three-column.middle-column.text-left {width: 48%;}.block-entry .course-row-core .three-column.right-column.text-right {width: 35.33%;}.pb-term {text-align: right !important; padding-right: 20px;}.course-blocks-total-credits .col-md-12 {width: 91.75%;}"}'
WHERE Id = 474

INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
VALUES
(347, 13, GETDATE()),
(512, 13, GETDATE()),
(347, 12, GETDATE()),
(512, 12, GETDATE()),
(347, 14, GETDATE()),
(512, 14, GETDATE()),
(347, 17, GETDATE()),
(512, 17, GETDATE()),
(347, 22, GETDATE()),
(512, 22, GETDATE()),
(475, 23, GETDATE()),
(74, 23, GETDATE())