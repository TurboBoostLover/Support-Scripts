USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16245';
DECLARE @Comments nvarchar(Max) = 
	'Add filter to admin report';
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
DECLARE @filterSql NVARCHAR(MAX) = 
'
		Select 
			Id as Value, 
			Cast(Title as nvarchar (10)) + ''-'' + Cast(Title + 1 as nvarchar (10)) as [Text] 
		From YearLookup 
		Where Title = (select Cast(Format(GetDate(),''yyyy'') as Int) )
		Union 
		Select 
			yl.Id as Value, 
			Cast(yl.Title as nvarchar (10)) + ''-'' + Cast(yl.Title + 1 as nvarchar (10)) as [Text] 
		From ModuleDetail md
			Inner Join YearLookup yl on md.YearLookupId = yl.Id
UNION
SELECT (select min(Id) from Semester)-1 AS Value
   ,''All Years'' as Text
from Semester 
';

UPDATE AdminReport
SET ReportSQL = '
DECLARE @useAllYears bit = 
CASE 
    WHEN @year < (select min(Id) from Semester)
        THEN  1
    ELSE
        0
END

DECLARE @cetId INT = (
	SELECT Id
	FROM ClientEntityType
	WHERE ClientId = 4
	AND Title = ''Program Review''
);

SELECT
	pvt.Title AS [Proposal Type],
	pvt.Department,
	CASE
		WHEN pvt.[20] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[20], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Mission Statement/Strategic Goals],
	CASE
		WHEN pvt.[21] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[21], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Program Overview],
	CASE
		WHEN pvt.[22] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[22], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Curriculum],
	CASE
		WHEN pvt.[23] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[23], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Assessment],
	CASE
		WHEN pvt.[24] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[24], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Assessment and Major Accomplishments],
	CASE
		WHEN pvt.[25] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[25], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Engagement],
	CASE
		WHEN pvt.[26] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[26], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Career Education (CE/CTE Only)],
	CASE
		WHEN pvt.[27] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[27], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Enrollment Trends],
	CASE
		WHEN pvt.[28] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[28], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Course Completion],
	CASE
		WHEN pvt.[29] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[29], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Degrees & Certificates],
	
	CASE
		WHEN pvt.[30] IS NULL THEN ''No''
		ELSE dbo.RegEx_Replace(dbo.RegEx_Replace(pvt.[30], ''<.+?>'', ''''), ''\&(.*?)\;'', '''')
	END AS [Students Served],
	pvt.TextMax08 AS [IEC or Admin Validator(s)],
	CONVERT(NVARCHAR(MAX), pvt.Date01, 101) AS [IEC or Admin Validator(s) Date],
	pvt.TextMax09 AS [Assessment Validator(s)],
	CONVERT(NVARCHAR(MAX), pvt.Date02, 101) AS [Assessment Validator(s) Date],
	pvt.TextMax10 AS [Curriculum Validator(s)],
	CONVERT(NVARCHAR(MAX), pvt.Date03, 101) AS [Curriculum Validator(s) Date],
	pvt.Validation AS [Validation Status]
FROM
(SELECT
	m.Id,
	m.EntityTitle,
	pt.Title,
	COALESCE(lu6.ShortText, ''Rating Not Selected'') + '' - '' + COALESCE(ml06.Rationale, ''No Rationale Entered'') AS [ShortText],
	l6.Id AS Lookup06Id,
	me02.TextMax08,
	me02.TextMax09,
	me02.TextMax10,
	me02.Date01,
	me02.Date02,
	me02.Date03,
	oe.Title AS [Department],
	ie.Title AS [Validation]
FROM Module m
	INNER JOIN ModuleDetail md ON m.Id = md.ModuleId
	LEFT JOIN OrganizationEntity oe ON md.Tier2_OrganizationEntityId = oe.Id
	INNER JOIN ProposalType pt ON m.ProposalTypeId = pt.Id
	LEFT JOIN ModuleExtension02 me02 ON me02.ModuleId = m.Id
	LEFT JOIN ModuleLookup06 ml06 ON m.Id = ml06.ModuleId
	LEFT JOIN ModuleInstitutionalEffectiveness mie ON mie.ModuleId = m.Id
	LEFT JOIN InstitutionalEffectiveness ie ON ie.Id = mie.InstitutionalEffectivenessId
	LEFT JOIN Lookup06 l6 ON ml06.Lookup06Id = l6.Id
		AND l6.Id IN (20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30)
	LEFT JOIN Lookup06 lu6 ON ml06.Lookup06Id_2 = lu6.Id
WHERE pt.ClientEntityTypeId = @cetId
AND pt.Active = 1
AND (@useAllYears = 1 OR md.YearLookupId = @year)
AND m.Active = 1) p
PIVOT --This will display the repeater items in their own columns
(
MAX (p.ShortText)
FOR p.Lookup06Id IN ([20], [21], [22], [23], [24], [25], [26], [27], [28], [29], [30])
) AS pvt;
'
WHERE Id = 8

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
	  8
	, 2
	, @filterSql
	, 'year'
	, 'Year'
	, 1
	)