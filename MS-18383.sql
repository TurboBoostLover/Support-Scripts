USE [hkapa];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18383';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin reports';
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
Please do not alter the script above this comment� except to set
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
DECLARE @useProposalTypes bit = 
CASE 
    WHEN @ProposalTypes < (SELECT Min(Id) FROM ProposalType WHERE EntityTypeId = 1 and (Id in (
			SELECT ProposalTypeId FROM Course
			)
			or 
			Active = 1))
   THEN  1
    ELSE
        0
END

DECLARE @useAll bit = 
CASE 
    WHEN @status < (select min(Id) from StatusAlias WHERE Active = 1)
        THEN  1
    ELSE
        0
END

DECLARE @useYear bit = 
CASE 
    WHEN @status < (SELECT min(id) FROM Semester WHERE Active = 1 and Code = 2)
        THEN  1
    ELSE
        0
END

SELECT
    c.CourseNumber AS [Course Code],
    C.Title AS [Course Title],
    s.Title AS [Effective Semester],
    STRING_AGG(s2.Title, ', ') WITHIN GROUP (ORDER BY s2.SortOrder) AS [Year and Term],
    FORMAT(p.ImplementDate, 'MM/dd/yyyy') AS [Approval Date],
    pt.Title AS [Proposal Type],
    sa.Title AS [Status]
FROM Course AS C
    INNER JOIN CourseProposal AS cp ON cp.CourseId = C.Id
    INNER JOIN Semester AS s ON s.Id = cp.SemesterId
    INNER JOIN Proposal AS p ON c.ProposalId = p.Id
    INNER JOIN StatusAlias AS sa ON c.StatusAliasId = sa.ID
    INNER JOIN ProposalType AS pt ON C.ProposalTypeId = pt.Id
    INNER JOIN CourseSemester AS cs ON cs.CourseId = c.Id
    INNER JOIN Semester AS s2 ON cs.SemesterId = s2.Id
WHERE c.Active = 1
AND (@useYear = 1 OR cs.SemesterId = @year)
AND (@useAll = 1 OR c.StatusAliasId = @status)
AND (@useProposalTypes = 1 OR C.ProposalTypeId = @ProposalTypes)
group by C.CourseNumber, C.Title, s.Title, p.ImplementDate, pt.Title, sa.Title
ORDER BY C.CourseNumber
";

DECLARE @filterSql NVARCHAR(MAX) = 
"
SELECT Id AS Value,
Title AS Text,
SortOrder
FROM Semester
WHERE Active = 1
and Code = 2
UNION
SELECT (select min(Id) from Semester WHERE Active = 1
and Code = 2 )-1 AS Value,
'All Year and Term' AS Text,
0 AS SortOrder
ORDER BY SortOrder
";


DECLARE @filterSql2 NVARCHAR(MAX) = 
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

DECLARE @filterSql3 NVARCHAR(MAX) = 
"
SELECT Id AS Value,
Title AS Text
FROM ProposalType
WHERE EntityTypeId = 1
AND (Active = 1
	or
	Id in (
		SELECT ProposalTypeId FROM Course WHERE Active = 1
	)
)
UNION
SELECT (select min(Id) from ProposalType WHERE EntityTypeId = 1
AND (Active = 1
	or
	Id in (
		SELECT ProposalTypeId FROM Course WHERE Active = 1
	)
)) - 1
 AS Value,
'All Proposal Types' AS Text
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Course Report', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()

INSERT INTO ClientReports
(Title, ClientReportsGroupId, ClientReportsConfigurationId, ClientId, SortOrder, StartDate)
VALUES
('Course Report', 23, 12, 1, 6, GETDATE())

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)

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
	, 'year'
	, 'Year and Term'
	, 1
	)
	,
		(
	  @adminReportId
	, 2
	, @filterSql2
	, 'status'
	, 'Status'
	, 0
	)
	,
		(
	  @adminReportId
	, 2
	, @filterSql3
	, 'ProposalTypes'
	, 'Proposal Type'
	, 0
	)

	--------------------Program Report---------------------------------------------------
	SET QUOTED_IDENTIFIER OFF 
 
SET @sql =
"
DECLARE @useProposalTypes bit = 
CASE 
    WHEN @ProposalTypes < (SELECT Min(Id) FROM ProposalType WHERE EntityTypeId = 2 and (Id in (
			SELECT ProposalTypeId FROM Program
			)
			or 
			Active = 1))
   THEN  1
    ELSE
        0
END

DECLARE @useAll bit = 
CASE 
    WHEN @status < (select min(Id) from StatusAlias WHERE Active = 1)
        THEN  1
    ELSE
        0
END

DECLARE @useYear bit = 
CASE 
    WHEN @status < (SELECT min(id) FROM Semester WHERE Active = 1 and Code = 1)
        THEN  1
    ELSE
        0
END

SELECT
    oe.Title AS [School],
		at.Title AS [Programme Type],
		p.Title AS [Programme Title],
		s.Title AS [Effective Year/Semester],
		pt.Title AS [Proposal Type],
		sa.Title AS [Status],
		s.Title AS [Year and Term]
FROM Program AS p
    INNER JOIN ProgramProposal AS pp ON pp.ProgramId = p.Id
    INNER JOIN Proposal AS pr ON p.ProposalId = pr.Id
    INNER JOIN StatusAlias AS sa ON p.StatusAliasId = sa.ID
    INNER JOIN ProposalType AS pt ON p.ProposalTypeId = pt.Id
		INNER JOIN OrganizationEntity AS oe on p.Tier1_OrganizationEntityId = oe.Id
		INNER JOIN AwardType AS at on p.AwardTypeId = at.Id
		INNER JOIN Semester AS s on pp.SemesterId = s.Id
WHERE p.Active = 1
AND (@useYear = 1 OR pp.SemesterId = @year)
AND (@useAll = 1 OR p.StatusAliasId = @status)
AND (@useProposalTypes = 1 OR p.ProposalTypeId = @ProposalTypes)
ORDER BY oe.Title, at.Title, p.Title
";

SET @filterSql = 
"
SELECT Id AS Value,
Title AS Text,
SortOrder
FROM Semester
WHERE Active = 1
and Code = 1
UNION
SELECT (select min(Id) from Semester WHERE Active = 1
and Code = 1 )-1 AS Value,
'All Year and Term' AS Text,
0 AS SortOrder
ORDER BY SortOrder
";


SET @filterSql2 = 
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

SET @filterSql3 = 
"
SELECT Id AS Value,
Title AS Text
FROM ProposalType
WHERE EntityTypeId = 2
AND (Active = 1
	or
	Id in (
		SELECT ProposalTypeId FROM Program WHERE Active = 1
	)
)
UNION
SELECT (select min(Id) from ProposalType WHERE EntityTypeId = 2
AND (Active = 1
	or
	Id in (
		SELECT ProposalTypeId FROM Program WHERE Active = 1
	)
)) - 1
 AS Value,
'All Proposal Types' AS Text
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Program Report', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()

INSERT INTO ClientReports
(Title, ClientReportsGroupId, ClientReportsConfigurationId, ClientId, SortOrder, StartDate)
VALUES
('Program Report', 23, 12, 1, 7, GETDATE())

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)

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
	, 'year'
	, 'Year and Term'
	, 1
	)
	,
		(
	  @adminReportId
	, 2
	, @filterSql2
	, 'status'
	, 'Status'
	, 0
	)
	,
		(
	  @adminReportId
	, 2
	, @filterSql3
	, 'ProposalTypes'
	, 'Proposal Type'
	, 0
	)