USE [chabot];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16436';
DECLARE @Comments nvarchar(Max) = 
	'Create SAO report';
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
INSERT INTO AdminReport
(ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES
('SAO Assessment Report', '
DECLARE @allsubject bit = 
CASE 
    WHEN @discipline = -1
        THEN  1
    ELSE
        0
END

DECLARE @allsem bit = 
CASE 
    WHEN @semesters = -1
        THEN  1
    ELSE
        0
END

SELECT
	oe.Title AS [Department],
	m.Title AS [Assessment Title],
	dbo.ConcatWithSep_Agg(''; '', oeo.Outcome) AS [Outcomes],
	concat(s.AcademicYearStart,''-'',s.AcademicYearEnd)As [Last Assessment]
FROM OrganizationEntity AS oe
INNER JOIN OrganizationEntityOutcome AS oeo on oeo.OrganizationEntityId = oe.ID
LEFT JOIN ModuleDetail as md on md.Tier2_OrganizationEntityId = oe.Id
LEFT JOIN Module AS m on md.ModuleId = m.Id
LEFT JOIN Semester As s on m.SemesterId = s.Id
LEFT JOIN Proposal AS p on m.ProposalId = p.Id
where oe.OrganizationTierId = 2
and (m.Active = 1 or m.Active IS NULL)
and (m.ProposalTypeId = 35 or m.ProposalTypeId IS NULL)
and oeo.Active = 1
and (@allsem = 1 OR m.SemesterId = @semesters)
and (@allsubject = 1 OR oe.Id = @discipline)
group by oe.Title, m.Title, p.ImplementDate, s.AcademicYearStart, s.AcademicYearEnd', 1, 0)

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO AdminReportClient
(AdminReportId, ClientId)
VALUES
(@ID, 1)

INSERT INTO AdminReportFilter
(AdminReportId, AdminReportFilterTypeId, FilterSQL, FilterAttributes, VariableName, FilterLabel, FilterRequired)
VALUES
(@ID, 2, 'select * from (
select -1 as Value, ''--All Departments--'' as Text
Union
select Id as Value, Title as Text from OrganizationEntity 
where Active = 1 and OrganizationTierId = 2) s
Order by case when Text like ''-%'' then 1 else 2 end, Text', NULL, 'discipline', 'Department', 1),
(@ID, 2, 'SELECT ''--All Years--'' AS Text, -1 AS Value
UNION
SELECT 
    CONVERT(nvarchar(50), S.CatalogYear) AS Text, 
    S.Id AS Value
FROM
    (SELECT DISTINCT CatalogYear
     FROM Semester) A
CROSS APPLY 
    (SELECT TOP 1 id 
     FROM Semester 
     WHERE A.CatalogYear = CatalogYear 
     ORDER BY id) Semid
INNER JOIN Semester S 
    ON Semid.id = S.id
WHERE TermEndDate > DATEADD(year, -10, GETDATE()) 
  AND TermEndDate < GETDATE()
Order by Value', NULL, 'semesters', 'Academic Year', 1)