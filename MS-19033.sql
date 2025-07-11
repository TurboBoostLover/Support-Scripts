USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19033';
DECLARE @Comments nvarchar(Max) = 
	'Fix Slow Queries';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @Subject int = (SELECT SubjectId FROM ProgramSequence WHERE Id = @PkIdValue)

select 
    c.Id as Value    
    ,EntityTitle + '' - '' + sa.Title  as Text         
    ,s.Id as FilterValue
		,s.Id as filterValue
from Course c
    inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join Subject s on s.id = c.SubjectId
where c.ClientId = @clientId 	
and c.Active = 1
and sa.StatusBaseId in (1,2,4,6)
and s.Id = @Subject
UNION
select 
    c.Id as Value    
    ,EntityTitle + '' - '' + sa.Title  as Text         
    ,s.Id as FilterValue
		,s.Id as filterValue
from Course c
	inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join Subject s on s.id = c.SubjectId
	INNER JOIN ProgramSequence pc on pc.CourseId = c.id and pc.ProgramId = @entityID
	WHERE s.Id = @Subject
order by Text
'
, LookupLoadTimingType = 3
WHERE Id = 80

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @Subject int = (SELECT SubjectId FROM ProgramCourse WHERE Id = @PkIdValue)

select 
    c.Id as Value    
    ,EntityTitle + '' - '' + sa.Title  as Text         
    ,s.Id as FilterValue
		,s.Id as filterValue
from Course c
    inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join Subject s on s.id = c.SubjectId
where c.ClientId = @clientId 	
and c.Active = 1
and sa.StatusBaseId in (1,2,4,6)
and s.Id = @Subject
UNION
select 
    c.Id as Value    
    ,EntityTitle + '' - '' + sa.Title  as Text         
    ,s.Id as FilterValue
		,s.Id as filterValue
from Course c
	inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join Subject s on s.id = c.SubjectId
	INNER JOIN Programcourse pc on pc.CourseId = c.id 
	inner join courseoption co on pc.CourseOptionId = co.Id
		and co.ProgramId = @entityID
	WHERE s.Id = @Subject
order by Text
'
, LookupLoadTimingType = 3
WHERE Id = 99

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @Subject int = (SELECT SubjectId FROM ProgramCourse WHERE Id = @PkIdValue)

SELECT c.Id AS [Value]
	, c.EntityTitle AS [Text]
	, s.SubjectCode
	, c.CourseNumber
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
	END AS IsVariable,
	c.SubjectId As filterValue,
	c.SubjectId AS FilterValue
FROM Course c
	JOIN ProgramSequence ps ON c.Id = ps.CourseId
	JOIN [Subject] s ON ps.SubjectId = s.Id
	JOIN CourseDescription CD ON CD.CourseId = C.Id
	JOIN ProposalType PT ON PT.Id = C.ProposalTypeId
	OUTER APPLY (
		select top 1 1 as isOldTemplate
		from Course c2
			join MetaTemplate mt on mt.MetaTemplateId = c2.MetaTemplateId
			join MetaSelectedSection mss on mss.MetaTemplateId = mt.MetaTemplateId
			join MetaSelectedField msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
		where c2.Id = C.Id
			and msf.MetaAvailableFieldId = 2487
	) t
WHERE ps.ProgramId = @entityId
and c.SubjectId = @Subject
ORDER BY s.SubjectCode, CAST(dbo.RegEx_Replace(c.CourseNumber, ''[^0-9]'', '''') AS INT);
'
, LookupLoadTimingType = 3
WHERE Id = 131

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @Subject int = (SELECT SubjectId FROM ProgramSequence WHERE Id = @PkIdValue)

SELECT 
	C.Id AS [Value]
    ,EntityTitle + '' - '' + sa.Title  as [Text]  
	, CASE 
		--NonCredit
		WHEN PT.ClientEntitySubTypeId = 1 OR PT.Title like ''%Non-Credit%'' THEN 
			CASE 
				WHEN T.isOldTemplate IS NULL THEN CD.MinContactHoursLecture -- new template
				ELSE CD.MinContactHoursOther END --  old template
		--Credit
		ELSE (ISNULL(CD.MinLectureHour, 0) + ISNULL(CD.MinLabHour, 0) + ISNULL(CD.InClassHour, 0)) * 16 
	END AS [Min]
	, 
	CASE 
		--NonCredit
		WHEN PT.ClientEntitySubTypeId = 1 OR PT.Title like ''%Non-Credit%'' THEN 
			CASE 
				WHEN T.isOldTemplate IS NULL THEN CD.MaxContactHoursLecture --new Template
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
		ELSE CASE 
			WHEN BudgetId = 9 or cd.MaxContactHoursOther IS NOT NULL and cd.MaxContactHoursOther > ISNULL(cd.MaxStudyHour, 0) THEN 1
			ELSE 0 END
	END AS IsVariable
    ,s.Id as FilterValue
		,S.Id AS filterValue
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
	AND c.SubjectId = @Subject
UNION
SELECT 
	C.Id AS [Value]
    ,EntityTitle + '' - '' + sa.Title  as [Text]  
	, CASE 
		--NonCredit
		WHEN PT.ClientEntitySubTypeId = 1 OR PT.Title like ''%Non-Credit%'' THEN 
			CASE 
				WHEN T.isOldTemplate IS NULL THEN CD.MinContactHoursLecture -- new template
				ELSE CD.MinContactHoursOther END --  old template
		--Credit
		ELSE (ISNULL(CD.MinLectureHour, 0) + ISNULL(CD.MinLabHour, 0) + ISNULL(CD.InClassHour, 0)) * 16 
	END AS [Min]
	, 
	CASE 
		--NonCredit
		WHEN PT.ClientEntitySubTypeId = 1 OR PT.Title like ''%Non-Credit%'' THEN 
			CASE 
				WHEN T.isOldTemplate IS NULL THEN CD.MaxContactHoursLecture --new Template
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
		,s.Id as filterValue
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
WHERE S.Id = @Subject
ORDER BY [Text]
'
, LookupLoadTimingType = 3
WHERE Id = 108

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (80, 99, 131, 108)