USE [delta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13596';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Reports, build admin report and "delete" a proposal';
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
UPDATE Module
SET Active = 0
WHERE Id = 451 --"DELETE" A Proposal as per clients request

-------------------------------------------------------------------

SET QUOTED_IDENTIFIER OFF

DECLARE @Report1 nvarchar(max) = "select distinct  
crn.CRNnumber + coalesce(' - ' + sem.Title,'') as Section,
case when (ME01.CRNid is not null ) then 'Assessed'
	else 'Not Assessed'
	end as Assessed,
case when OE.Code is not null then  '(' + OE.Code + ') ' + OE.Title
	else OE.Title end as Division,
case when OE2.Code is not null then  '(' + OE2.Code + ') ' + OE2.Title
	else OE2.Title end as Department,
S.SubjectCode + ' - ' + S.Title as Subject,
u.FirstName + ' ' + u.LastName as Originator
from CRN crn
	inner join CRNOffering co on co.CRNId = crn.Id
	inner join Semester sem on co.SemesterId = sem.Id and sem.Active = 1
	inner join Subject S on S.id = CRN.SubjectId and S.Active = 1
	left join OrganizationSubject OS on S.id = OS.SubjectId and OS.Active = 1
	left join OrganizationLink OL on OS.OrganizationEntityId = OL.Child_OrganizationEntityId and OL.Active = 1
	left join OrganizationEntity OE on OL.Parent_OrganizationEntityId = OE.Id and OE.Active = 1
	left join OrganizationEntity OE2 on OS.OrganizationEntityId = OE2.Id and OE2.Active = 1
	left join (
		select*
		from ModuleExtension01
		where ModuleId in (
			select id
			from Module
			where Active = 1 and StatusAliasId = 1)) ME01 on ME01.CRNid=CRN.id
	left join Module m on m.id = ME01.id
	left join [User] u on u.id = m.UserId
where (s.Id = @subjectId OR @subjectId = 0)
	and sem.Id = @semesterId
	and ((ME01.CRNid is not null and @Assessedid = 1)
		or
		(ME01.CRNid is null and @Assessedid = 0))
order by crn.CRNnumber + coalesce(' - ' + sem.Title,'')"

SET QUOTED_IDENTIFIER ON

UPDATE AdminReport
SET ReportSQL = @Report1
WHERE Id = 3
AND ReportName = 'Section Level Assessment Report'

-----------------------------------------------------------------------------------------------

SET QUOTED_IDENTIFIER OFF

DECLARE @Report2 nvarchar(max) = "
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
CONCAT(s.AcademicYearStart, ' - ', s.AcademicYearEnd) as [Year],
u.FirstName + ' ' + u.LastName AS [Originator],
m.Id as [ID in Meta]
FROM GenericOrderedList01 AS gol
	LEFT JOIN Module AS m ON m.Id = gol.ModuleId
	LEFT JOIN Semester AS s ON s.Id = gol.AcademicYear_SemesterId
	LEFT JOIN ModuleDetail AS md ON md.ModuleId = m.Id
	LEFT JOIN OrganizationEntity AS oe ON oe.Id = md.Tier2_OrganizationEntityId
	LEFT JOIN @lookup14 AS l14 ON gol.Id = l14.ID
	LEFT JOIN [User] as u on u.Id = m.UserId
WHERE m.ProposalTypeId = 46
and m.Active = 1
AND (@useAllYears = 1 OR gol.AcademicYear_SemesterId = @year)
ORDER BY m.Id
"
SET QUOTED_IDENTIFIER ON

UPDATE AdminReport
SET ReportSQL = @Report2
WHERE Id = 14
AND ReportName = 'Resource Request'

----------------------------------------------------------------------------------------

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @ReportId INT;
DECLARE @Report3 NVARCHAR(MAX) =
"
SELECT
	  u.FirstName + ' ' + u.LastName AS [Originator]
	, s.SubjectCode + ' ' + s.Title AS [Subject]
	, c.Title AS [Course]
	, co.OutcomeText AS [Outcome]
	, se.Title AS [Semester]

FROM Module AS m
INNER JOIN ModuleDetail AS md ON md.ModuleId = m.ID
INNER JOIN ModuleTerm AS mt ON mt.ModuleId = m.ID
INNER JOIN [User] AS u ON u.Id = m.UserId
INNER JOIN Subject AS s ON s.Id = md.SubjectId
INNER JOIN Course AS c ON c.Id = md.Reference_CourseId
INNER JOIN CourseOutcome AS co ON co.Id = md.Reference_CourseOutcomeId
INNER JOIN Semester AS se ON mt.SemesterId = se.Id
WHERE m.Active = 1
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Course SLO Assessment Report', @Report3, 1, 0)
SET @ReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@ReportId, 1)
