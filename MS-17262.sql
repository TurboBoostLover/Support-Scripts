USE [socccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17262';
DECLARE @Comments nvarchar(Max) = 
	'Custom Admin Report';
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
DECLARE @useAll bit = 
CASE 
    WHEN @status < (select min(Id) from StatusAlias)
        THEN  1
    ELSE
        0
END

SELECT 
c.Id AS [Course Proposal ID (META)],
oe.Code AS [Course Schools/Divisions Code],
oe.Title AS [Course Schools/Divisions],
oe2.Code AS [Course Departments Code],
oe2.Title AS [Course Departments],
s.SubjectCode AS [Course Prefix],
c.CourseNumber AS [Course Number],
cs.Code AS [Course Suffix],
gd.Decimal11 AS [Course Catalog ID],
c.Title aS [Course Title],
dbo.Format_RemoveAccents(dbo.stripHtml(c.Description)) AS [Course Catalog Description],
dbo.Format_RemoveAccents(dbo.stripHtml(c.LectureOutline)) AS [Course Lecture Content],
dbo.Format_RemoveAccents(dbo.stripHtml(c.LabOutline)) AS [Course Lab/Learning Center Content],
dbo.ConcatWithSep_Agg(' | ', dbo.Format_RemoveAccents(dbo.stripHtml(co.Text))) AS [Course Learning Objectives]
FROM Course AS c
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
INNER JOIN CourseDetail AS cd on cd.CourseId = c.Id
INNER JOIN OrganizationEntity As oe on cd.Tier1_OrganizationEntityId = oe.Id
INNER JOIN OrganizationEntity AS oe2 on cd.Tier2_OrganizationEntityId = oe2.Id
INNER JOIN Subject AS s on c.SubjectId = s.Id
LEFT JOIN CourseObjective AS co on co.CourseId = c.Id
LEFT JOIN CourseSuffix AS cs on cs.Id = c.CourseSuffixId
LEFT JOIN GenericDecimal AS gd on gd.CourseId = c.Id
WHERE c.ClientId = 2
and c.Active = 1
and oe.Title = 'Emeritus Institute'
AND (@useAll = 1 OR c.StatusAliasId = @status)
group by c.Id, oe.Code, oe.Title, oe2.Code, oe2.Title, s.SubjectCode, C.CourseNumber, cs.Code, gd.Decimal11, c.Title, C.Description, c.LectureOutline, c.LabOutline
";

DECLARE @filterSql NVARCHAR(MAX) = 
"
select 
    Id as Value
    ,Coalesce(Cast(Title as nvarchar)
    ,'The Status field is not populated. This uses Catalog configuration of the Status table.') as Text		
from StatusAlias
WHERE Active = 1
UNION
SELECT (select min(Id) from StatusAlias)-1 AS Value
,'All Status' as Text
FROM StatusAlias
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Emeritus Report', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 2)

INSERT INTO AdminReportFilter 
	(
	  AdminReportId
	, AdminReportFilterTypeId
	, FilterSQL
	, VariableName
	, FilterLabel
	, FilterRequired
	)
VALUES 
(
	  @adminReportId
	, 2
	, @filterSql
	, 'status'
	, 'Status'
	, 1
	)

INSERT INTO ClientReports
(Title, ClientReportsGroupId, ClientReportsConfigurationId, ClientId, SortOrder, StartDate)
VALUES
('Emeritus Report', 4, 12, 2, 10, GETDATE())