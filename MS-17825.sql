USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17825';
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
DECLARE @MostRecentCourses TABLE (Id INT);

WITH ActiveCourses AS (
    SELECT *, 
           ROW_NUMBER() OVER (PARTITION BY basecourseId ORDER BY CASE WHEN PreviousId IS NULL THEN Id ELSE PreviousId END DESC) AS RowNum
    FROM Course
    WHERE StatusAliasId = 1
		and Active = 1
)

INSERT INTO @MostRecentCourses
SELECT Id 
FROM ActiveCourses
WHERE RowNum = 1;

SELECT 
cl.Title AS [College],
s.SubjectCode AS [Subject Code],
c.CourseNumber AS [Course Number],
c.Title AS [Title],
CASE WHEN cge.Id IS NOT NULL THEN 'Yes' ELSE NULL END AS [CSU/UC Transferable],
CASE WHEN cge2.Id IS NOT NULL THEN 'Yes' ELSE NULL END AS [CSU Transferable only]
FROM 
Course AS c
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
LEFT JOIN CourseGeneralEducation AS cge on cge.CourseId = c.Id and cge.GeneralEducationElementId = 88
LEFT JOIN CourseGeneralEducation AS cge2 on cge2.CourseId = c.Id and cge2.GeneralEducationElementId = 89
INNER JOIN Client AS cl on c.ClientId = cl.Id
INNER JOIN Subject AS s on c.SubjectId = s.Id
WHERE c.ClientId = 4 --Laney
and c.Id in (SELECT Id FROM @MostRecentCourses)
and (cge.Id IS NOT NULL or cge2.Id IS NOT NULL)
UNION
SELECT 
cl.Title AS [College],
s.SubjectCode AS [Subject Code],
c.CourseNumber AS [Course Number],
c.Title AS [Title],
CASE WHEN cge.Id IS NOT NULL THEN 'Yes' ELSE NULL END AS [CSU/UC Transferable],
CASE WHEN cge2.Id IS NOT NULL THEN 'Yes' ELSE NULL END AS [CSU Transferable only]
FROM 
Course AS c
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
LEFT JOIN CourseGeneralEducation AS cge on cge.CourseId = c.Id and cge.GeneralEducationElementId = 88
LEFT JOIN CourseGeneralEducation AS cge2 on cge2.CourseId = c.Id and cge2.GeneralEducationElementId = 89
INNER JOIN Client AS cl on c.ClientId = cl.Id
INNER JOIN Subject AS s on c.SubjectId = s.Id
WHERE c.ClientId = 5 --Merritt
and c.Id in (SELECT Id FROM @MostRecentCourses)
and (cge.Id IS NOT NULL or cge2.Id IS NOT NULL)
UNION
SELECT 
cl.Title AS [College],
s.SubjectCode AS [Subject Code],
c.CourseNumber AS [Course Number],
c.Title AS [Title],
CASE WHEN cge.Id IS NOT NULL THEN 'Yes' ELSE NULL END AS [CSU/UC Transferable],
CASE WHEN cge2.Id IS NOT NULL THEN 'Yes' ELSE NULL END AS [CSU Transferable only]
FROM 
Course AS c
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
LEFT JOIN CourseGeneralEducation AS cge on cge.CourseId = c.Id and cge.GeneralEducationElementId = 88
LEFT JOIN CourseGeneralEducation AS cge2 on cge2.CourseId = c.Id and cge2.GeneralEducationElementId = 89
INNER JOIN Client AS cl on c.ClientId = cl.Id
INNER JOIN Subject AS s on c.SubjectId = s.Id
WHERE c.ClientId = 3 --Alameda
and c.Id in (SELECT Id FROM @MostRecentCourses)
and (cge.Id IS NOT NULL or cge2.Id IS NOT NULL)
UNION
SELECT 
cl.Title AS [College],
s.SubjectCode AS [Subject Code],
c.CourseNumber AS [Course Number],
c.Title AS [Title],
CASE WHEN cge.Id IS NOT NULL THEN 'Yes' ELSE NULL END AS [CSU/UC Transferable],
CASE WHEN cge2.Id IS NOT NULL THEN 'Yes' ELSE NULL END AS [CSU Transferable only]
FROM 
Course AS c
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
LEFT JOIN CourseGeneralEducation AS cge on cge.CourseId = c.Id and cge.GeneralEducationElementId = 88
LEFT JOIN CourseGeneralEducation AS cge2 on cge2.CourseId = c.Id and cge2.GeneralEducationElementId = 89
INNER JOIN Client AS cl on c.ClientId = cl.Id
INNER JOIN Subject AS s on c.SubjectId = s.Id
WHERE c.ClientId = 2 --Berkley
and c.Id in (SELECT Id FROM @MostRecentCourses)
and (cge.Id IS NOT NULL or cge2.Id IS NOT NULL)
order by College, [Subject Code], [Course Number]
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Articulate and Transfer', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES 
(@adminReportId, 2),
(@adminReportId, 3),
(@adminReportId, 4),
(@adminReportId, 5)

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId2 INT;
DECLARE @sql2 NVARCHAR(MAX) =
"
DROP TABLE IF EXISTS #MostRecentCourses
DROP TABLE IF EXISTS #MostRecentPrograms

CREATE TABLE #MostRecentCourses  (Id INT PRIMARY KEY);

DECLARE @Test2 TABLE (Id int, RowNum int)
INSERT INTO @Test2
    SELECT Id,
           ROW_NUMBER() OVER (PARTITION BY basecourseId ORDER BY CASE WHEN PreviousId IS NULL THEN Id ELSE PreviousId END DESC) AS RowNum
    FROM Course
    WHERE StatusAliasId = 1
		and Active = 1

INSERT INTO #MostRecentCourses
SELECT Id 
FROM @Test2
WHERE RowNum = 1;

CREATE TABLE #MostRecentPrograms (Id INT PRIMARY KEY);

DECLARE @Test TABLE (Id int, RowNum int)
INSERT INTO @Test
    SELECT Id,
           ROW_NUMBER() OVER (PARTITION BY baseprogramId ORDER BY CASE WHEN PreviousId IS NULL THEN Id ELSE PreviousId END DESC) AS RowNum
    FROM Program
    WHERE StatusAliasId = 1
		and Active = 1


INSERT INTO #MostRecentPrograms
SELECT Id 
FROM @Test
WHERE RowNum = 1;

DECLARE @SQL NVARCHAR(MAX) = '		
-- Requisite Courses
declare @requisites table (CourseId int, CourseTitle nvarchar(max), CourseStatus nvarchar(max), RequisiteType nvarchar(max))

insert into @requisites
(CourseId,CourseTitle,CourseStatus,RequisiteType)
SELECT DISTINCT
        c.Id,
        coalesce(c.EntityTitle,s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title) as CourseTitle, 
        sa.Title as CourseStatus, 
        rt.Title as RequisiteType
FROM Course c
		INNER JOIN #MostRecentCourses AS mrc on mrc.Id = c.Id
    INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
    INNER JOIN [Subject] s ON c.SubjectId = s.Id
    INNER JOIN CourseRequisite cr ON c.Id = cr.CourseId
    INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
		WHERE cr.Requisite_CourseId = @EntityId
ORDER BY CourseTitle, CourseStatus;

declare @final NVARCHAR(max) = (
    select STRING_AGG(concat(r.RequisiteType,'' '', r.CourseTitle,'' '', ''*'',r.CourseStatus,''*''), ''; '')
    from @requisites r
)

select 
    0 as Value
    ,case 
        when len(@final) > 0 then @final
    else ''This course is not being used as a requisite for any course''
    end as Text
'

DECLARE @SQL2 NVARCHAR(MAX) = '			
declare @programs table (ProgramId int, ProgramStatus nvarchar(max), ProgramAwardType nvarchar(max), ProgramTitle nvarchar(max), ProposalType nvarchar(max))

INSERT into @programs
(ProgramId,ProgramStatus,ProgramAwardType,ProgramTitle,ProposalType)
SELECT distinct
    p.Id,
    sa.Title as ProgramStatus,
    at.Title as AwardType,
    p.Title as ProgramTitle,
    pt.Title as ProposalType
FROM Program p
		INNER JOIN #MostRecentPrograms AS mrp on mrp.Id = p.Id
    INNER JOIN StatusAlias sa ON p.StatusAliasId = sa.Id
    INNER JOIN ProposalType pt ON p.ProposalTypeId = pt.Id
    LEFT JOIN AwardType at ON p.AwardTypeId = at.Id
		INNER JOIN ProgramSequence AS ps on ps.ProgramId = p.ID
		WHERE ps.CourseId = @EntityId
ORDER BY sa.Title, pt.Title, at.Title, p.Title;

declare @final NVARCHAR(max) = (
    select STRING_AGG(
		concat(p.ProposalType,''-'',p.ProgramAwardType,'' *'',p.ProgramStatus,''* '',p.ProgramTitle), ''; '')
    from @programs p
)

select 0 as Value, case when len(@final) > 0 then @final else ''This course is a stand-alone course and is not incorporated into any programs'' end as Text'

SELECT 
cl.Code AS [College],
CONCAT(s.SubjectCode, ' ', c.CourseNumber) AS [Subject and Course Number],
q.Text AS [Impacted Courses],
q2.Text AS [Impacted Programs]
FROM Course AS c
INNER JOIN #MostRecentCourses AS mrc on mrc.Id = c.Id
INNER JOIN Client AS cl on c.ClientId = cl.Id
INNER JOIN Subject AS s on c.SubjectId = s.Id
outer apply dbo.fnBulkResolveCustomSqlQuery(@SQL, 0, c.Id, 1, 1467, 1,null) q
outer apply dbo.fnBulkResolveCustomSqlQuery(@SQL2, 0, c.Id, 1, 1467, 1,null) q2
ORDER BY [College], [Subject and Course Number]
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Impact Report for all courses', @sql2, 1, 0)
SET @adminReportId2 = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES 
(@adminReportId2, 2),
(@adminReportId2, 3),
(@adminReportId2, 4),
(@adminReportId2, 5)