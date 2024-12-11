USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13820';
DECLARE @Comments nvarchar(Max) = 
	'Created Admin report for program reviews';
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
DECLARE @useAllTerms BIT = 
	CASE 
		WHEN 
			(SELECT MAX(CONVERT(INT, Value)) FROM @terms) > (SELECT MAX(Id) FROM Semester) 
			THEN 1
		ELSE 0
	END;

SELECT 
	CONCAT(s.Title, ' - ', c.CourseNumber) AS [Course Subject & Number],
	c.Title AS [Course Title],
	se.Title AS [Effective Term],
	sa.Title AS [Status],
	oe.Title AS [College/School/Dept],
			dbo.ConcatWithSepOrdered_Agg
		(', ', COALESCE(
		u.Id, ''), 
		CONCAT(u.FirstName, ' ', u.LastName)) 
	 AS [Co-Contributors],
	iic.Code AS [Reason for Submission]
FROM Course AS c
LEFT JOIN Subject AS s on c.SubjectId = s.Id
LEFT JOIN CourseProposal AS cp on cp.CourseId = c.Id
LEFT JOIN Semester AS se on cp.SemesterId = se.Id
INNER JOIN StatusAlias AS sa on sa.Id = c.StatusAliasId
LEFT JOIN CourseDetail AS cd on cd.CourseId = c.Id
LEFT JOIN OrganizationEntity AS oe on cd.Tier2_OrganizationEntityId = oe.Id
LEFT JOIN IaiCode AS iic on c.IaiCodeId = iic.Id
LEFT JOIN CourseContributor AS cc on cc.CourseId = c.Id
LEFT JOIN [User] AS u on cc.UserId = u.Id
WHERE c.IaiCodeId = 10
AND c.Active = 1
AND (@useAllTerms = 1 OR se.Id IN (SELECT Value FROM @terms)) -- Either use all the terms or the selected one(s)
Group BY s.Title, c.CourseNumber, c.Title, se.Title, sa.Title, oe.Title, iic.Code
";


DECLARE @filterSql NVARCHAR(MAX) = 
"
DECLARE @now DATETIME = GETDATE();
SELECT
	   Id AS Value
	 , Title 
	   + CASE 
			WHEN Code = '0' THEN ' (0)'
			ELSE ''
		END 
	AS Text
	, SortOrder
FROM [Semester]
WHERE @now BETWEEN StartDate AND ISNULL(EndDate, @now)
	AND ClientId = 1
	AND CatalogYear IS NOT NULL
	AND Active = 1
UNION
SELECT 
     (SELECT MAX(Id) FROM Semester)+1 AS Value
   , 'All Terms' AS Text
   , (SELECT MAX(SortOrder) FROM Semester)+1 AS SortOrder
FROM [Semester] sem
	INNER JOIN ProgramProposal pp ON sem.id = pp.SemesterId 
ORDER BY SortOrder DESC;
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('3 year course review', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()


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
	, 5
	, @filterSql
	, 'terms'
	, 'Term(s)'
	, 1
	)