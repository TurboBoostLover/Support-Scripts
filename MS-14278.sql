USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14278';
DECLARE @Comments nvarchar(Max) = 
	'Updated CSS Override to not change css only if children exists';
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
UPDATE MetaReport
SET ReportAttributes = '
  {
	"isPublicReport": true,
  "reportTemplateId": 132,
  "cssOverride": "Div.h3 {text-align: center;} Span.field-value {float: right;} \r\n.Program-Summary-Details\r\n{\r\n\tborder-bottom-style: dotted;\r\n\tborder-bottom-width: 1px; \r\n\tmargin-left: 0px !important; \r\n\tborder-bottom-color: lightgray;\r\n}\r\n.course-block-standard .parent-wrapper[data-has-children=\"true\"]>.non-course-row-core-wrapper>.non-course-row-core \r\n{\r\n\tbackground-color: #d9E2FC !important;\r\n\tfont-weight: bold;\r\n}\r\n.header-subject, .header-title, .header-units\r\n{\r\n\tbackground-color: #2E74B5 !important;\r\n\tfont-weight: bold;\r\n\tcolor: white;\r\n}\r\n.summary-header{\r\n\tmargin-left: 0px !important;\r\n}\r\n.course-block-standard .parent-wrapper[data-has-children=\"false\"]>.non-course-row-core-wrapper>.non-course-row-core \r\n{\r\n\tbackground-color: #d9E2FC !important;\r\n\tfont-weight: bold;\r\n}"
	}
'
WHERE Id = 405