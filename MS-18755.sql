USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18755';
DECLARE @Comments nvarchar(Max) = 
	'Configure the abridged Comparision report for all proposal types';
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
DECLARE @Reports TABLE (Id int, type int)

INSERT INTO MetaReport
(Id, Title, MetaReportTypeId, OutputFormatId, ReportAttributes)
output inserted.Id, inserted.MetaReportTypeId into @Reports
VALUES
(518, 'Abridged Comparison', 2, 5, '{"showDifferencesOnly":true,"isPublicReport":false}'),
(519, 'Abridged Comparison', 6, 5, '{"showDifferencesOnly":true,"isPublicReport":false}')

DECLARE @Max int = (SELECT MAX(ID) + 1 FROM MetaReportActionType)

INSERT MetaReportActionType
(Id, MetaReportId, ProcessActionTypeId)
SELECT @Max, Id, 2 FROM @Reports WHERE type = 2
UNION
SELECT @Max + 1, Id, 3 FROM @Reports  WHERE type = 2
UNION
SELECT @MAX + 2, Id, 2 FROM @Reports  WHERE type = 6
UNION
SELECT @MAX + 3, Id, 3 FROM @Reports  WHERE type = 6

DECLARE @MetaTemplateType TABLE (type int, id int)
INSERT INTO @MetaTemplateType
SELECT 2, MetaTemplateTypeId FROM MetaTemplateType WHERE IsPresentationView = 0 and Active = 1 and EntityTypeId = 1
UNION
SELECT 6, MetaTemplateTypeId FROM MetaTemplateType WHERE IsPresentationView = 0 and Active = 1 and EntityTypeId = 2

INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
SELECT r.Id, mtt.id, GETDATE() FROM @Reports as r
INNER JOIN @MetaTemplateType AS mtt on mtt.type = r.type
WHERE r.type = 2
UNION
SELECT r.Id, mtt.Id, GETDATE() FROM @Reports as r 
INNER JOIN @MetaTemplateType AS mtt on mtt.type = r.type
WHERE r.type = 6