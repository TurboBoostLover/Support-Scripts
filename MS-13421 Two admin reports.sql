USE [delta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13421';
DECLARE @Comments nvarchar(Max) = 
	'Create two admin reports labeled: Prior Resource Allocation  and Resource Request ';
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
DECLARE @useAllYears bit = 
CASE 
    WHEN @year < (select min(Id) from Semester)
        THEN  1
    ELSE
        0
END

SELECT
	CASE
		WHEN myn.YesNo01Id = 1 THEN 'Yes'
		ELSE 'No'
	END AS [Previous Funding]
	, mcrn.TextMax01 AS [Funded Resource]
	, mcrn.TextMax02 AS [Utilization of Resource]
	, mcrn.TextMax03 AS [Impact]
	, oe.Title AS [Department]
	, s.Title AS [Year]
	, m.Id AS [ID in Meta]

FROM Module AS m
	INNER JOIN ModuleYesNo AS myn On myn.ModuleId = m.Id
	INNER JOIN ModuleCRN AS mcrn ON mcrn.ModuleId = m.Id
	INNER JOIN ModuleDetail AS md ON md.ModuleId = m.Id
	INNER JOIN OrganizationEntity AS oe ON oe.Id = md.Tier2_OrganizationEntityId
	LEFT JOIN Semester AS s on s.Id = m.SemesterId
WHERE m.Active = 1
AND m.ProposalTypeId = 46
AND (@useAllYears = 1 OR m.SemesterId = @year)
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Prior Resource Allocation', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)

/************************************************************************************/

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId2 INT;
DECLARE @sql2 NVARCHAR(MAX) =
"
DECLARE @useAllYears bit = 
CASE 
    WHEN @year < (select min(Id) from Semester)
        THEN  1
    ELSE
        0
END

DECLARE @lookup14 TABLE (Id INT, ResourceType NVARCHAR(MAX));

INSERT INTO @lookup14
    SELECT 
          g14.GenericOrderedList01Id
        , dbo.CONCATWITHSEP_AGG (', ', l14.Title)
    FROM GenericOrderedList01Lookup14 g14
        INNER JOIN Lookup14 l14 ON g14.Lookup14Id = l14.Id
    GROUP BY g14.GenericOrderedList01Id;

SELECT gol.MaxText01 as [Resource Request],
	CASE
		WHEN gol.Bit_01 = 1 THEN 'Yes'
		ELSE 'No'
	END
AS [New Request],
	CASE
		WHEN gol.Bit_02 = 1 THEN 'Yes'
		ELSE 'No'
	END
AS [Previous Request],
	CASE
		WHEN gol.Bit_03 = 1 THEN 'Yes'
		ELSE 'No'
	END
AS [Partially Funded Previous Request],
s.Title AS [Review Year],
l14.ResourceType AS [Resource Type],
gol.Decimal01 as [Estimated Cost],
	CASE
		WHEN gol.YesNo01Id = 1 THEN 'Yes'
		ELSE 'No'
	END
as [Annual Extended Costs],
	CASE
		WHEN gol.YesNo02Id = 1 THEN 'Yes'
		ELSE 'No'
	END
AS [Current Budget Cover Cost],
gol.MaxText03 AS [Description],
	CASE
		WHEN gol.Bit_04 = 1 THEN 'Yes'
		ELSE 'No'
	END
AS [Student-Centered],
	CASE
		WHEN gol.Bit_05 = 1 THEN 'Yes'
		ELSE 'No'
	END
AS [Innovative and Inclusive],
	CASE
		WHEN gol.Bit_06 = 1 THEN 'Yes'
		ELSE 'No'
	END
AS [Community-Focused],
oe.Title AS [Department],
m.Id as [ID in Meta]
FROM GenericOrderedList01 AS gol
	LEFT JOIN Module AS m ON m.Id = gol.ModuleId
	LEFT JOIN Semester AS s ON s.Id = gol.AcademicYear_SemesterId
	LEFT JOIN ModuleDetail AS md ON md.ModuleId = m.Id
	LEFT JOIN OrganizationEntity AS oe ON oe.Id = md.Tier2_OrganizationEntityId
	LEFT JOIN @lookup14 AS l14 ON gol.Id = l14.ID
WHERE m.ProposalTypeId = 46
and m.Active = 1
AND (@useAllYears = 1 OR gol.AcademicYear_SemesterId = @year)
ORDER BY m.Id
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Resource Request', @sql2, 1, 0)
SET @adminReportId2 = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId2, 1)

SET QUOTED_IDENTIFIER OFF
DECLARE @filtersql nvarchar(max) =
"
select 
    Id as Value
    ,Coalesce(Cast(AcademicYearStart as nvarchar) + '-' +	Cast(AcademicYearEnd as nvarchar)
    ,'The AcademicYearStart and/or AcademicYearEnd field is not populated. This uses Catalog configuration of the semester table.') as Text, 
    AcademicYearStart,
    SortOrder 
from Semester 
Where EndDate Is NULL 
and Active = 1 
and Title like '%Fall%' 
UNION
SELECT (select min(Id) from Semester)-1 AS Value
   ,'All Years' as Text,
   (select min(AcademicYearStart) from Semester)-1 as AcademicYearStart,
   (select min(SortOrder) from Semester)-1 as SortOrder
from Semester 
Order by AcademicYearStart, SortOrder
"
SET QUOTED_IDENTIFIER ON

INSERT INTO AdminReportFilter (AdminReportId, AdminReportFilterTypeId, FilterSQL, VariableName, FilterLabel, FilterRequired)
VALUES (@adminReportId2, 2, @filtersql, 'year', 'Year', 1)
, (@adminReportId, 2, @filtersql, 'year', 'Year', 1)
