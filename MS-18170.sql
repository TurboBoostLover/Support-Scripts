USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18170';
DECLARE @Comments nvarchar(Max) = 
	'Add reports to Program Review';
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
INSERT INTO MetaReportTemplateType
(MetaTemplateTypeId, MetaReportId)
VALUES
(42, 57),
(40, 57)

INSERT INTO MetaReport
(Id, Title, MetaReportTypeId, OutputFormatId, ReportAttributes)
VALUES
(480,'All Fields PDF', 13, 4, '{"isPublicReport":false}')

DECLARE @MAX int = (SELECT Max(Id) + 1 FROM MetaReportActionType)

INSERT INTO MetaReportActionType
(Id, MetaReportId, ProcessActionTypeId)
VALUES
(@MAX, 480, 1),
(@MAX + 1, 480, 2), 
(@MAX + 2, 480, 3)

INSERT INTO MetaReportTemplateType
(MetaTemplateTypeId, MetaReportId)
VALUES
(36, 480),
(37, 480),
(41, 480),
(42, 480),
(40, 480)