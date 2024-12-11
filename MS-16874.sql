USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16874';
DECLARE @Comments nvarchar(Max) = 
	'Fix Calculation for Programs';
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
use hancockcollege

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
SELECT 
	C.Id AS [Value]
    ,EntityTitle + '' - '' + sa.Title  as [Text]  
	, CASE 
		--NonCredit
		WHEN PT.ClientEntitySubTypeId = 1 OR PT.Title like ''%Non-Credit%'' THEN 
			CASE 
				WHEN T.isOldTemplate IS NULL THEN CD.MinContactHoursLecture * 16 -- new template
				ELSE CD.MinContactHoursOther END --  old template
		--Credit
		ELSE (ISNULL(CD.MinLectureHour, 0) + ISNULL(CD.MinLabHour, 0) + ISNULL(CD.InClassHour, 0)) * 16 
	END AS [Min]
	, 
	CASE 
		--NonCredit
		WHEN PT.ClientEntitySubTypeId = 1 OR PT.Title like ''%Non-Credit%'' THEN 
			CASE 
				WHEN T.isOldTemplate IS NULL THEN CD.MaxContactHoursLecture * 16 --new Template
				WHEN cd.MaxContactHoursOther IS NOT NULL and cd.MaxContactHoursOther > ISNULL(cd.MaxStudyHour, 0) THEN cd.MaxContactHoursOther
				ELSE CD.MaxStudyHour END --Old Template
		--Credit
		ELSE (ISNULL(CD.MaxLectureHour, 0) + ISNULL(CD.MaxLabHour, 0) + ISNULL(CD.OutClassHour, 0)) * 16 
	END AS [Max]
	, 
	CASE 
		--new templates
		WHEN T.isOldTemplate is null 
			THEN CASE 
					WHEN PT.ClientEntitySubTypeId = 2 --Credit
						THEN CASE WHEN CD.Variable = 1 THEN 1 ELSE 0 END 
					WHEN PT.ClientEntitySubTypeId = 1 THEN 1 END  --Noncredit
		-- old templates
		ELSE CASE BudgetId
			WHEN 9 THEN 1
			ELSE 0 END
	END AS IsVariable
    ,s.Id as FilterValue
FROM Course C
	JOIN StatusAlias SA ON SA.Id = C.StatusAliasId
	JOIN [Subject] S ON S.Id = C.SubjectId
	JOIN ProposalType PT ON PT.Id = C.ProposalTypeId
	JOIN CourseDescription CD ON CD.CourseId = C.Id
	OUTER APPLY (
		select top 1 1 as isOldTemplate
		from Course c2
			join MetaTemplate mt on mt.MetaTemplateId = c2.MetaTemplateId
			join MetaSelectedSection mss on mss.MetaTemplateId = mt.MetaTemplateId
			join MetaSelectedField msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
		where c2.Id = c.id
			and msf.MetaAvailableFieldId = 2487
	) t
WHERE C.ClientId = @clientId
	AND C.Active = 1
	AND SA.StatusBaseId IN (1,2,4,6)
UNION
SELECT 
	C.Id AS [Value]
    ,EntityTitle + '' - '' + sa.Title  as [Text]  
	, CASE 
		--NonCredit
		WHEN PT.ClientEntitySubTypeId = 1 OR PT.Title like ''%Non-Credit%'' THEN 
			CASE 
				WHEN T.isOldTemplate IS NULL THEN CD.MinContactHoursLecture * 16 -- new template
				ELSE CD.MinContactHoursOther END --  old template
		--Credit
		ELSE (ISNULL(CD.MinLectureHour, 0) + ISNULL(CD.MinLabHour, 0) + ISNULL(CD.InClassHour, 0)) * 16 
	END AS [Min]
	, 
	CASE 
		--NonCredit
		WHEN PT.ClientEntitySubTypeId = 1 OR PT.Title like ''%Non-Credit%'' THEN 
			CASE 
				WHEN T.isOldTemplate IS NULL THEN CD.MaxContactHoursLecture * 16 --new Template
				WHEN cd.MaxContactHoursOther IS NOT NULL and cd.MaxContactHoursOther > ISNULL(cd.MaxStudyHour, 0) THEN cd.MaxContactHoursOther
				ELSE CD.MaxStudyHour END --Old Template
		--Credit
		ELSE (ISNULL(CD.MaxLectureHour, 0) + ISNULL(CD.MaxLabHour, 0) + ISNULL(CD.OutClassHour, 0)) * 16 
	END AS [Max]
	, 
	CASE 
		--new templates
		WHEN T.isOldTemplate is null 
			THEN CASE 
					WHEN PT.ClientEntitySubTypeId = 2 --Credit
						THEN CASE WHEN CD.Variable = 1 THEN 1 ELSE 0 END 
					WHEN PT.ClientEntitySubTypeId = 1 THEN 1 END  --Noncredit
		-- old templates
		ELSE CASE WHEN BudgetId = 9 THEN 1
					WHEN BudgetId = 8 and cd.MaxContactHoursOther IS NOT NULL and cd.MaxContactHoursOther > ISNULL(cd.MaxStudyHour, 0) THEN 1
			ELSE 0 END
	END AS IsVariable
    ,s.Id as FilterValue
FROM Course C
	JOIN StatusAlias SA ON SA.Id = C.StatusAliasId
	JOIN [Subject] S ON S.Id = C.SubjectId
	JOIN ProposalType PT ON PT.Id = C.ProposalTypeId
	JOIN CourseDescription CD ON CD.CourseId = C.Id
	JOIN ProgramSequence PS ON PS.CourseId = C.Id
		AND PS.ProgramId = @entityId
	OUTER APPLY (
		select top 1 1 as isOldTemplate
		from Course c2
			join MetaTemplate mt on mt.MetaTemplateId = c2.MetaTemplateId
			join MetaSelectedSection mss on mss.MetaTemplateId = mt.MetaTemplateId
			join MetaSelectedField msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
		where c2.Id = C.Id
			and msf.MetaAvailableFieldId = 2487
	) t
ORDER BY [Text]
'
, ResolutionSql = '
SELECT
	c.Id AS [Value]
	, c.EntityTitle AS [Text] 
	, CASE 
		--NonCredit
		WHEN PT.ClientEntitySubTypeId = 1 OR PT.Title like ''%Non-Credit%'' THEN 
			CASE 
				WHEN T.isOldTemplate IS NULL THEN CD.MinContactHoursLecture * 16 -- new template
				ELSE CD.MinContactHoursOther END --  old template
		--Credit
		ELSE (ISNULL(CD.MinLectureHour, 0) + ISNULL(CD.MinLabHour, 0) + ISNULL(CD.InClassHour, 0)) * 16 
	END AS [Min]
	, 
	CASE 
		--NonCredit
		WHEN PT.ClientEntitySubTypeId = 1 OR PT.Title like ''%Non-Credit%'' THEN 
			CASE 
				WHEN T.isOldTemplate IS NULL THEN CD.MaxContactHoursLecture * 16 --new Template
				WHEN cd.MaxContactHoursOther IS NOT NULL and cd.MaxContactHoursOther > ISNULL(cd.MaxStudyHour, 0) THEN cd.MaxContactHoursOther
				ELSE CD.MaxStudyHour END --Old Template
		--Credit
		ELSE (ISNULL(CD.MaxLectureHour, 0) + ISNULL(CD.MaxLabHour, 0) + ISNULL(CD.OutClassHour, 0)) * 16 
	END AS [Max]
	, 
	CASE 
		--new templates
		WHEN T.isOldTemplate is null 
			THEN CASE 
					WHEN PT.ClientEntitySubTypeId = 2 --Credit
						THEN CASE WHEN CD.Variable = 1 THEN 1 ELSE 0 END 
					WHEN PT.ClientEntitySubTypeId = 1 THEN 1 END  --Noncredit
		-- old templates
		ELSE CASE WHEN BudgetId = 9 THEN 1
					WHEN BudgetId = 8 and cd.MaxContactHoursOther IS NOT NULL and cd.MaxContactHoursOther > ISNULL(cd.MaxStudyHour, 0) THEN 1
			ELSE 0 END
	END AS IsVariable
FROM Course c
	JOIN ProposalType PT ON PT.Id = C.ProposalTypeId
	JOIN CourseDescription CD ON CD.CourseId = c.Id
	OUTER APPLY (
		select top 1 1 as isOldTemplate
		from Course c2
			join MetaTemplate mt on mt.MetaTemplateId = c2.MetaTemplateId
			join MetaSelectedSection mss on mss.MetaTemplateId = mt.MetaTemplateId
			join MetaSelectedField msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
		where c2.Id = @id
			and msf.MetaAvailableFieldId = 2487
	) t
WHERE c.id = @id
'
WHERE Id = 108

DROP TABLE IF EXISTS #calculationResults;

-- Create temporary table
CREATE TABLE #calculationResults
(
    TableName sysname,
    Id int,
    Min decimal(16, 3),
    Max decimal(16, 3),
    IsVariable bit
);

-- Declare a cursor
DECLARE programCursor CURSOR FAST_FORWARD FOR
	SELECT p.Id FROM Program AS p
	INNER JOIN ProposalType AS pt on p.ProposalTypeId = pt.Id
	WHERE pt.ClientEntitySubTypeId = 3

-- Variable to hold the fetched Id
DECLARE @programId int;

-- Open the cursor
OPEN programCursor;

-- Fetch the first row
FETCH NEXT FROM programCursor
INTO @programId;

-- Loop through all rows fetched by the cursor
WHILE @@FETCH_STATUS = 0
BEGIN
    -- Execute the stored procedure
    EXEC upCalculateNestedCourseBlockEntries @entityId = @programId, @resultTable = '#calculationResults';

    -- Fetch the next row
    FETCH NEXT FROM programCursor
    INTO @programId;
END;

-- Close and deallocate the cursor
CLOSE programCursor;
DEALLOCATE programCursor;


UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 108
)