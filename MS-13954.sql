USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13954';
DECLARE @Comments nvarchar(Max) = 
	'Update C&I Admin Report';
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
UPDATE AdminReport
SET ReportSQL = "


DECLARE @useAllTerms BIT = 
	CASE 
		WHEN 
			(SELECT MAX(CONVERT(INT, Value)) FROM @terms) > (SELECT MAX(Id) FROM Semester) 
			THEN 1
		ELSE 0
	END;

DECLARE @reportResults TABLE 
	(
	  [Course Prefix & Number] NVARCHAR(MAX)
	, [Course Title] NVARCHAR(MAX)
	, [Course Status] NVARCHAR(MAX)
	, [Proposal Type] NVARCHAR(MAX)
	, [Effective Date] NVARCHAR(MAX)
	, [Reason for submission] NVARCHAR(MAX)
	, [Originator] NVARCHAR(MAX)
	, [College/School/Department] NVARCHAR(MAX)
	, [Rationale] NVARCHAR(MAX)
	, [Approved Course Outline Reports] NVARCHAR(MAX)
	, [Sort Order] INT
	)

INSERT INTO @reportResults
SELECT
	  CONCAT (s.SubjectCode, ' ', c.CourseNumber) AS [Course Prefix & Number]
	, c.Title AS [Course Title]
	, sa.Title AS [Course Status]
	, pt.Title AS [Proposal Type]
	, sem.Title AS [Effective Date]
	, iai.Code AS [Reason for submission]
	, CONCAT (u.FirstName, ' ', u.LastName) AS [Originator]
	, oe.Title AS [College/School/Department]
	, CAST (dbo.stripHtml (c.Rationale) AS NVARCHAR(MAX)) AS [Rationale] -- Get rid of HTML tags in output
    , CONCAT ('https://stpetersburg.curriqunet.com/DynamicReports/AllFieldsReportByEntity/', c.Id, '?entityType=Course&reportId=50') 
	AS [Approved Course Outline Reports] -- Link to Approved Course Outline report for course proposal
	, sem.SortOrder
FROM Course c
	INNER JOIN Subject s ON c.SubjectId = s.Id
	INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id 
	INNER JOIN ProposalType pt ON c.ProposalTypeId = pt.Id
	LEFT JOIN CourseProposal cp ON cp.CourseId = c.Id
	LEFT JOIN Semester sem ON cp.SemesterId = sem.Id
	LEFT JOIN IaiCode iai ON iai.Id = c.IaiCodeId
	INNER JOIN [User] u ON c.UserId = u.Id
	INNER JOIN CourseDetail cd ON cd.CourseId = c.Id
	INNER JOIN OrganizationEntity oe ON cd.Tier2_OrganizationEntityId = oe.Id
WHERE (@useAllTerms = 1 OR sem.Id IN (SELECT Value FROM @terms)) -- Either use all the terms or the selected one(s)

-- Replacing all known and other common instances of escaped characters in the Rationale output
UPDATE @reportResults SET Rationale = replace(Rationale, '&rsquo;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&#39;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&nbsp;' collate Latin1_General_CS_AS, ' '  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&amp;' collate Latin1_General_CS_AS, '&'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&quot;' collate Latin1_General_CS_AS, '""'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&euro;' collate Latin1_General_CS_AS, '€'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&lt;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&gt;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&oelig;' collate Latin1_General_CS_AS, 'oe'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&copy;' collate Latin1_General_CS_AS, '©'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&laquo;' collate Latin1_General_CS_AS, '«'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&reg;' collate Latin1_General_CS_AS, '®'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&plusmn;' collate Latin1_General_CS_AS, '±'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&sup2;' collate Latin1_General_CS_AS, '²'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&sup3;' collate Latin1_General_CS_AS, '³'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&micro;' collate Latin1_General_CS_AS, 'µ'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&middot;' collate Latin1_General_CS_AS, '·'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&ordm;' collate Latin1_General_CS_AS, 'º'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&raquo;' collate Latin1_General_CS_AS, '»'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&frac14;' collate Latin1_General_CS_AS, '¼'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&frac12;' collate Latin1_General_CS_AS, '½'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&frac34;' collate Latin1_General_CS_AS, '¾'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&Aelig' collate Latin1_General_CS_AS, 'Æ'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&Ccedil;' collate Latin1_General_CS_AS, 'Ç'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&Egrave;' collate Latin1_General_CS_AS, 'È'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&Eacute;' collate Latin1_General_CS_AS, 'É'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&Ecirc;' collate Latin1_General_CS_AS, 'Ê'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&Ouml;' collate Latin1_General_CS_AS, 'Ö'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&agrave;' collate Latin1_General_CS_AS, 'à'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&acirc;' collate Latin1_General_CS_AS, 'â'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&auml;' collate Latin1_General_CS_AS, 'ä'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&aelig;' collate Latin1_General_CS_AS, 'æ'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&ccedil;' collate Latin1_General_CS_AS, 'ç'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&egrave;' collate Latin1_General_CS_AS, 'è'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&eacute;' collate Latin1_General_CS_AS, 'é'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&ecirc;' collate Latin1_General_CS_AS, 'ê'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&euml;' collate Latin1_General_CS_AS, 'ë'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&icirc;' collate Latin1_General_CS_AS, 'î'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&ocirc;' collate Latin1_General_CS_AS, 'ô'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&ouml;' collate Latin1_General_CS_AS, 'ö'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&divide;' collate Latin1_General_CS_AS, '÷'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&oslash;' collate Latin1_General_CS_AS, 'ø'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&ugrave;' collate Latin1_General_CS_AS, 'ù'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&uacute;' collate Latin1_General_CS_AS, 'ú'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&ucirc;' collate Latin1_General_CS_AS, 'û'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&uuml;' collate Latin1_General_CS_AS, 'ü'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&lsaquo;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @reportResults SET Rationale = replace(Rationale, '&rsaquo;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)

SELECT
	  [Course Prefix & Number] 
	, [Course Title] 
	, [Course Status]
	, [Proposal Type] 
	, [Effective Date] 
	, [Reason for submission]
	, [Originator] 
	, [College/School/Department]
	, [Rationale] 
	, [Approved Course Outline Reports] 
FROM @reportResults
ORDER BY [Course Prefix & Number], [Course Title], [Sort Order] ASC; 

"
WHERE Id = 35
SET QUOTED_IDENTIFIER ON