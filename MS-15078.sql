USE [sbccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15078';
DECLARE @Comments nvarchar(Max) = 
	'Add comparison reports for crafton programs';
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
DECLARE @reportId int = 44
DECLARE @reportTitle NVARCHAR(MAX) = 'Comparison'
DECLARE @entityId int = 2	--1-Courses, 2-Programs, 6-Modules
DECLARE @reportType int = 6		--2-CourseCompare, 4-CourseAllFields, 6-Program/ModuleCompare, 13-Program/ModuleAllFields

INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
SELECT
	@reportId,
	mtt.MetaTemplateTypeId,
	GETDATE()
FROM MetaTemplateType AS mtt
INNER JOIN MetaTemplate AS mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = @entityId
AND mt.Active = 1
AND mt.IsDraft = 0
AND mtt.Active = 1
AND mtt.IsPresentationView = 0
AND mtt.ClientId = 2

DECLARE @MAX INT = (SELECT MAX(ID) FROM MetaReportActionType) + 1

INSERT INTO MetaReportActionType
(Id, MetaReportId, ProcessActionTypeId)
VALUES
(@MAX,@reportId,2),
(@MAX + 1,@reportId,3)