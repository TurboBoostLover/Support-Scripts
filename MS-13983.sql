USE [chabot];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13983';
DECLARE @Comments nvarchar(Max) = 
	'Update and create admin reports';
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
DECLARE @TABLE TABLE (id int)
SET QUOTED_IDENTIFIER OFF

UPDATE AdminReport
SET ReportSQL = "
SELECT 
	p.Title AS [Degree/Certificate Name],
	at.Title AS [Award Type],
	p.Id AS [Program Id],
	sa.Title AS [Status]

FROM 
	Program AS p
	INNER JOIN StatusAlias AS sa on p.StatusAliasId = sa.Id
	LEFT JOIN CourseOption AS co ON co.ProgramId = p.Id
	LEFT JOIN AwardType AS at on p.AwardTypeId = at.Id
	WHERE p.Active = 1
	AND sa.Id = 1
	AND co.Id IS NULL
	ORDER BY p.Title
"
WHERE Id = 21

DECLARE @SQL NVARCHAR(MAX) = "
SELECT 
	CONCAT(s.SubjectCode,' ', c.CourseNumber) as [Course Subject & Number],
	c.Title as [full course title],
	cd.MinUnitHour AS [min units],
	cd.MaxUnitHour AS [Max units],
	cd.MinContactHoursLecture AS [Minimum Lecture Hours],
	cd.MinContactHoursLab AS [Minimum Lab Hours],
	cb.CB00 AS [CCC Control Number],
	c.Description AS [Catalog Description],
	CONCAT(cb3.Code,' - ', cb3.Description) AS [Top Code],

	dbo.ConcatWithSep_Agg(
		CASE 
			WHEN c2.Title IS NULL
				THEN ''
			ELSE
	', '
		END
	,  
		CASE
			WHEN c2.Title IS NULL
				THEN ''
			ELSE
	CONCAT (rt.Title,': ', s2.SubjectCode, ' ', c2.CourseNumber)
		END
	) AS [Requisite],
	CASE 
	WHEN cd.HasSpecialTopics = 1 
	THEN 'Yes'
	ELSE 'No'
	END
	AS [Transfer to UC],
	CASE
	WHEN c.ISCSUTransfer = 1
	THEN 'Yes'
	ELSE 'No'
	END
	AS [Transfer to CSU],
	sa.Title AS [Status]
FROM Course AS C
	INNER JOIN StatusAlias AS sa ON c.StatusAliasId = sa.Id
	LEFT JOIN CourseDescription AS cd ON cd.CourseId = c.Id
	LEFT JOIN CourseCBCode AS cb ON cb.CourseId = c.Id
	LEFT JOIN CB03 AS cb3 ON cb.CB03Id = cb3.Id
	LEFT JOIN CourseRequisite AS cr ON cr.CourseId = c.Id
	LEFT JOIN Subject AS s ON c.SubjectId = s.Id
	LEFT JOIN RequisiteType AS rt on cr.RequisiteTypeId = rt.Id
	LEFT JOIN Course AS c2 on cr.Requisite_CourseId = c2.Id
	LEFT JOIN Subject AS s2 on c2.SubjectId = s2.Id
	WHERE c.Active = 1
	AND sa.Id = 1
	group by s.SubjectCode, c.CourseNumber, c.Title, cd.MinUnitHour, cd.MaxUnitHour, cd.MinContactHoursLecture, cd.MinContactHoursLab, c.Description, cb3.Code, cb3.Description, cd.HasSpecialTopics, c.ISCSUTransfer, cb.CB00, sa.Title, s2.SubjectCode
"

DECLARE @SQL2 NVARCHAR(MAX) = "
SELECT 
	p.Title AS [Degree/Certificate Name],
	at.Title AS [Award Type],
	SUM(co.CalcMin) AS [Minimum Units],
	SUM(co.CalcMax) AS [Maximum Units],
	p.UniqueCode2 AS [State ID],
	CONCAT(cb3.Code, ' - ', cb3.Description) AS [TOP Code],
	p.Description AS [Catalog Description],
	dbo.ConcatWithSep_Agg('; ',
	po.Outcome) AS [Program Learning Outcomes],
	sa.Title AS [Status]
FROM Program AS p
	INNER JOIN StatusAlias AS sa ON p.StatusAliasId = sa.Id
	LEFT JOIN AwardType AS at ON p.AwardTypeId = at.Id
	LEFT JOIN CourseOption AS co ON co.ProgramId = p.Id
	LEFT JOIN ProgramCBCode AS pcc ON pcc.ProgramId = p.Id
	LEFT JOIN CB03 AS cb3 ON pcc.CB03Id = cb3.Id
	LEFT JOIN ProgramOutcome AS po ON po.ProgramId = p.Id
WHERE p.Active = 1
	AND sa.Id = 1
GROUP BY 
	p.Title,
	at.Title,
	p.UniqueCode2,
	cb3.Code, 
	cb3.Description,
	p.Description,
	sa.Title
ORDER BY p.Title;
"

DECLARE @SQL3 NVARCHAR(MAX) = "
SELECT 
	dbo.ConcatWithSep_Agg(', ',
	l.Title) AS [Learning and Career Pathway primary],
	p.Title AS [Degree/Certificate name],
	at.Title AS [Award Type],
	p.Id AS [Program Id],
	sa.Title AS [Status]

FROM 
	Program AS P
	INNER JOIN StatusAlias AS sa on p.StatusAliasId = sa.Id
	LEFT JOIN AwardType AS at on p.AwardTypeId = at.Id
	LEFT JOIN ProgramLookup14 AS pl on pl.ProgramId = p.Id
	LEFT JOIN Lookup14 AS l on pl.Lookup14Id = l.Id
	WHERE p.Active = 1
	AND sa.Id = 1
	Group by p.Title, at.Title, p.Id, sa.Title
	ORDER BY P.Title
"

SET QUOTED_IDENTIFIER ON

INSERT INTO AdminReport
(ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
OUTPUT inserted.Id into @TABLE (id)
VALUES
('Course data', @SQL, 1, 0),
('Program level data', @SQL2, 1, 0),
('Pathway data', @SQL3, 1, 0)



INSERT INTO AdminReportClient 
(AdminReportId, ClientId)
SELECT id, 1 FROM @TABLE