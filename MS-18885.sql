USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18885';
DECLARE @Comments nvarchar(Max) = 
	'Format on OL on CSD report';
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
SET ReportAttributes = '{"isPublicReport":false,"reportTemplateId":14,"fieldRenderingStrategy":"HideEmptyFields","SectionRenderingStrategy":"HideEmptySections","sectionRenderingStrategy":"HideEmptySections","cssOverride":"ol {padding-left: 1rem;} .field-value ol:not([type]){padding-left: 0rem !important;} .report-header.container {display:flex; flex-direction:column; align-items:center;} .report-title {float: none; text-align: center; max-width: 100%; padding-bottom: 25px; color:purple;} .h4.section-name {font-size: 1.05rem; color: purple; font-weight: bold;} .section-description {font-size: 15px; font-weight: 400;} .field-label {font-weight: bold;} table {border-collapse: collapse; border: none;} th, td {padding: 0.25rem 0.5rem 0.25rem; border: 1px solid #000000;} .course-report-table {width: 100%;} .thead-invisible thead, .thead-invisible tr, .thead-invisible th {border: none !important; line-height: 0 !important;} .th-half {width: 50%;} .td-label {color: purple;}.tla-table th, .tla-table td {text-align: center;}"}'
WHERE Id = 306