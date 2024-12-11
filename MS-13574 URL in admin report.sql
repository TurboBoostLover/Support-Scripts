USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13574';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin report to show all urls of reports of active program reviews';
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
SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId INT;
DECLARE @sql NVARCHAR(MAX) =
"
SELECT 
	  m.Title AS [Title]
	, CASE
		WHEN mtt.MetaTemplateTypeId = 19 THEN CONCAT('https://fresno.curriqunet.com/DynamicReports/AllFieldsReportByEntity/', m.Id, '?entityType=Module&reportId=433')
		WHEN mtt.MetaTemplateTypeId = 18 THEN CONCAT('https://fresno.curriqunet.com/DynamicReports/AllFieldsReportByEntity/', m.Id, '?entityType=Module&reportId=431')
		WHEN mtt.MetaTemplateTypeId = 17 THEN CONCAT('https://fresno.curriqunet.com/DynamicReports/AllFieldsReportByEntity/', m.Id, '?entityType=Module&reportId=430')
		WHEN mtt.MetaTemplateTypeId = 21 THEN CONCAT('https://fresno.curriqunet.com/DynamicReports/AllFieldsReportByEntity/', m.Id, '?entityType=Module&reportId=432')
		ELSE NULL
	END AS [Link],
	mtt.TemplateName AS [Type]
FROM Module AS m
	INNER JOIN MetaTemplate AS mt ON mt.MetaTemplateId = m.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
	INNER JOIN StatusAlias AS sa ON m.StatusAliasId = sa.Id
	WHERE sa.Title = 'Active'
	and m.Active = 1

";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Program Review Reports URL', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)