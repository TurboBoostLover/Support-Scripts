USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16974';
DECLARE @Comments nvarchar(Max) = 
	'Clean up admin reports';
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
DELETE FROM AdminReportClient WHERE 1 = 1
DELETE FROM AdminReportFilter WHERE AdminReportId in (
18, 19, 23, 24, 25, 31, 32, 37, 45, 46
)

DELETE FROM AdminReport
WHERE Id in (
18, 19, 23, 24, 25, 31, 32, 37, 45, 46
)

UPDATE AdminReport
SET ShowOnMenu = 0 
WHERE Id = 50

DECLARE @Reports TABLE (Name nvarchar(max), sqln nvarchar(max), Outpu bit, menu bit, css nvarchar(max))
INSERT INTO @Reports
SELECT ReportName, ReportSQL, OutputFormatId, ShowOnMenu, CustomCSS FROM AdminReport

DECLARE @Filter TABLE (AdminReportId int, filter int, FilterSql nvarchar(max), att nvarchar(max), nam nvarchar(max), labe nvarchar(max), req bit,  reportname nvarchar(max))
INSERT INTO @Filter
SELECT AdminReportId, AdminReportFilterTypeId, FilterSQL, FilterAttributes, VariableName, FilterLabel, FilterRequired, ReportName FROM AdminReportFilter AS ar
INNER JOIN AdminReport AS ar2 on ar.AdminReportId = ar2.Id

DELETE FROM AdminReportFilter WHERE 1 =1

DELETE FROM AdminReport WHERE 1 = 1

INSERT INTO AdminReport
(ReportName, ReportSQL, OutputFormatId, ShowOnMenu, CustomCSS)
SELECT Name, sqln, outpu, menu, css FROM @Reports ORDER BY Name

INSERT INTO AdminReportFilter
(AdminReportId, AdminReportFilterTypeId, FilterSQL, FilterAttributes, VariableName, FilterLabel, FilterRequired)
SELECT ar.Id, filter, FilterSql, att, nam, labe, req FROM @Filter AS f
INNER JOIN AdminReport AS ar on f.reportname = ar.ReportName

INSERT INTO AdminReportClient
(AdminReportId, ClientId)
SELECT Id, 1 FROM AdminReport