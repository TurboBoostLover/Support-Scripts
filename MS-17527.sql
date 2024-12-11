USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17527';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Requirements report';
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
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @extraDetailsDisplay StringPair;

DROP TABLE IF EXISTS #renderedInjections;

CREATE TABLE #renderedInjections 
	(
	TableName SYSNAME,
	Id INT,
	InjectionType NVARCHAR(255),
	RenderedText NVARCHAR(MAX),
	PRIMARY KEY (TableName, Id, InjectionType)
	);
------------------------------------------------
-- Left Column: Subject & Course #
------------------------------------------------
INSERT INTO #renderedInjections 
	(TableName, Id, InjectionType, RenderedText)
SELECT
	''ProgramSequence'' AS TableName, 
	ps.Id, 
	''CourseEntryLeftColumnReplacement'' AS InjectionType,
	CONCAT
		(
		''<span class = "course-identifier" data-course-id = "'', c.Id, ''">'',
			''<span class = "subject-code" title = "'', s.Title, ''">'',
		s.SubjectCode,
			''</span>'',
		'' '', 
			''<span class = "course-number">'', 
		c.CourseNumber,
			''</span>'',
		''</span>'',
		CASE WHEN cde.IsApproved = 1 
			THEN 
		''<sup class = "course-approved-for-de-identifier">DE</sup>''
			ELSE ''''
		END
		) AS [Text]
FROM ProgramSequence ps
	INNER JOIN Course c ON ps.CourseId = c.Id
	INNER JOIN [Subject] s ON c.SubjectId = s.Id
	LEFT JOIN CourseDistanceEducation cde ON c.Id = cde.CourseId
WHERE ps.ProgramId = @entityId
;

------------------------------------------------
-- Middle Column: Title
------------------------------------------------
INSERT INTO #renderedInjections 
	(TableName, Id, InjectionType, RenderedText)
SELECT
	''ProgramSequence'' AS TableName, 
	ps.Id, 
	''CourseEntryMiddleColumn'' AS InjectionType,
	CONCAT(c.Title, ISNULL(psd.ExceptionIdentifier, ''''), CASE WHEN OrHigherException IS NOT NULL THEN CONCAT( '' '', OrHigherException) ELSE '''' END) AS [Text]
FROM ProgramSequence ps
INNER JOIN ProgramSequenceDetail AS psd on psd.ProgramSequenceId = ps.Id
	INNER JOIN Course c ON ps.CourseId = c.Id
WHERE ps.ProgramId = @entityId
------------------------------------------------
-- Right Column (two divs): Units, Term
------------------------------------------------
INSERT INTO #renderedInjections
	(TableName, Id, InjectionType, RenderedText)
SELECT
	''ProgramSequence'' AS TableName,
	ps.Id, 
	''CourseEntryRightColumnReplacement'' AS InjectionType,
	CONCAT
		(
		-- Entire Third Column
		''<div class = "row">'',
		-- Units
			''<div class = "col-xs-9 col-sm-9 col-md-9">'',
				''<span class = "units-display block-entry-units-display">'',
		CASE		
			WHEN ps.CalcMin = ps.CalcMax THEN FORMAT(ps.CalcMin, ''##0.0'')
			--WHEN ps.CalcMin IS NOT NULL AND ps.CalcMax IS NULL THEN FORMAT(ps.CalcMin, ''##0.0'') 
			--WHEN ps.CalcMin IS NULL THEN ''''
			ELSE CONCAT(FORMAT(ps.CalcMin, ''##0.0''), ''-'', FORMAT(ps.CalcMax, ''##0.0''))
		END,
				''</span>'',
			''</div>'',
		-- Term
			''<div class = "col-xs-3 col-sm-3 col-md-3 pb-term">'',
				''<span class = "pb-term-text">'',
		lsn.TitleSequence,
				''</span>'',
			''</div>'',
		''</div>''
		) AS [Text]
FROM ProgramSequence ps
	INNER JOIN Program p ON ps.ProgramId = p.Id
	INNER JOIN ProgramSequenceDetail psd ON psd.ProgramSequenceId = ps.Id
	INNER JOIN ListItemType lit ON lit.Id = ps.ListItemTypeId AND lit.ListItemTypeOrdinal <> 2
	LEFT JOIN ListSequenceNumber lsn ON psd.ListSequenceNumberId = lsn.Id
WHERE ps.ProgramId = @entityId;

------------------------------------------------
-- Query variables
------------------------------------------------
DECLARE @courseLeftColumnQuery NVARCHAR(MAX) =
''SELECT 
	Id AS [Value], 
	RenderedText AS [Text]
FROM #renderedInjections ri
WHERE ri.TableName = ''''ProgramSequence'''' 
	AND ri.Id = @id
	AND ri.InjectionType = ''''CourseEntryLeftColumnReplacement'''';
'';

DECLARE @courseMiddleColumnQuery NVARCHAR(MAX) =
''SELECT 
	Id AS [Value], 
	REPLACE(REPLACE(RenderedText, ''''<h2>'''', ''''<p>''''), ''''</h2>'''', ''''</p>'''') AS [Text]
FROM #renderedInjections ri
WHERE ri.TableName = ''''ProgramSequence'''' 
	AND ri.Id = @id
	AND ri.InjectionType = ''''CourseEntryMiddleColumn'''';
'';

DECLARE @courseRightColumnQuery NVARCHAR(MAX) = 
''SELECT
	Id AS [Value],
	RenderedText AS [Text]
FROM #renderedInjections ri
WHERE ri.TableName = ''''ProgramSequence''''
	AND ri.Id = @id
	AND ri.InjectionType = ''''CourseEntryRightColumnReplacement'''';
''; 

Declare @NonCourseEntryRightColumnReplacement Nvarchar(max) =
''SELECT
	Id AS [Value],
	RenderedText AS [Text]
FROM #renderedInjections ri
WHERE ri.TableName = ''''ProgramSequence''''
	AND ri.Id = @id
	AND ri.InjectionType = ''''CourseEntryRightColumnReplacement'''';
''


------------------------------------------------
-- Insertions & course block proc
------------------------------------------------
INSERT INTO @extraDetailsDisplay 
	(String1, String2)
VALUES
	(''CourseEntryLeftColumnReplacement'', @courseLeftColumnQuery),
	(''CourseEntryMiddleColumnReplacement'', @courseMiddleColumnQuery),
	(''CourseEntryRightColumnReplacement'', @courseRightColumnQuery),
	(''NonCourseEntryRightColumnReplacement'', @NonCourseEntryRightColumnReplacement)

DECLARE @config StringPair;

INSERT INTO @config 
	(String1, String2)
VALUES
	(''BlockItemTable'', ''ProgramSequence'');

EXEC upGenerateGroupConditionsCourseBlockDisplay 
	@entityId = @entityId, 
	@extraDetailsDisplay = @extraDetailsDisplay, 
	@config = @config;

DROP TABLE IF EXISTS #renderedInjections;
'

UPDATE MetaForeignKeyCriteriaClient
sET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 97

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 97
)