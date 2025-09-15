USE [cscc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-20089';
DECLARE @Comments nvarchar(Max) = 
	'Fix Catalog course Summary on code/dats tab with the correct hours';
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
DECLARE @HourType TABLE (SecId int, TempId int)
INSERT INTO @HourType
SELECT MetaSelectedSectionId, mss.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mss.MetaBaseSchemaId = 507
and mtt.IsPresentationView = 0

DECLARE @Codes TABLE (SecId int, TempId int)
INSERT INTO @Codes
SELECT MetaSelectedSectionId, MetaTemplateId FROM MetaSelectedSection AS mss
WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
and mss.SectionName like '%Codes%'

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'triggersectionrefresh', c.SecId, ht.SecId FROM @HourType AS ht
INNER JOIN @Codes AS c on ht.TempId = c.TempId
WHERE ht.SecId not in (
	SELECT MetaSelectedSectionId FROM MetaSelectedSectionAttribute
	WHERE Name = 'triggersectionrefresh'
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT c.TempId FROM @Codes AS c
	INNER JOIN @HourType AS ht on c.TempId = ht.TempId
)

DECLARE @Id int = 85

DECLARE @SQL NVARCHAR(MAX) = '

-------------------------------------------------------
 --DECLARE @entityId INT = 5142; -- Uncomment this line to test output.
-------------------------------------------------------

-------------------------------------------------------
-- Requisites
-------------------------------------------------------
DECLARE @reqs NVARCHAR(MAX) = (
	SELECT CustomSql FROM MetaForeignKeyCriteriaClient WHERE Id = 43
	);

-------------------------------------------------------
-- HTML Tags and Attributes
-------------------------------------------------------
DECLARE @divTag			NVARCHAR(10)  = ''div''				 , 
		@spanTag		NVARCHAR(10)  = ''span''				 ,
		@labelTag		NVARCHAR(10)  = ''label''				 ,
		@boldTag		NVARCHAR(10)  = ''b''					 , 
		@italTag		NVARCHAR(10)  = ''i''					 ,
		@undlTag		NVARCHAR(10)  = ''u''					 ,		
		@brTag			NVARCHAR(10)  = ''<br>''				 ,
		@dash			NVARCHAR(10)  = ''—''					 ,
		@space			NVARCHAR(10)  = '' ''					 ,
		@empty			NVARCHAR(10)  = ''''					 , 
		@classAttrib	NVARCHAR(10)  = ''class''				 , 
		@titleAttrib	NVARCHAR(10)  = ''title''				 ,
		@cidAttrib		NVARCHAR(MAX) = ''data-course-id''	 , 
		@bcidAttrib		NVARCHAR(MAX) = ''data-base-course-id'',
		@dgoAttrib		NVARCHAR(MAX) = ''data-grade-option''	 ,
		@styleAttrib	NVARCHAR(10)  = ''style''				 ;
-------------------------------------------------------
-- Classes
-------------------------------------------------------
DECLARE 
		-- Row wrapper
		@row	NVARCHAR(MAX) = ''row''															,
		-- Row - three columns
		@l3		NVARCHAR(MAX) = ''col-xs-3 col-sm-3 col-md-1 text-left left-column''				, 
		@m3		NVARCHAR(MAX) = ''col-xs-6 col-sm-6 col-md-10 text-left middle-column''			, 
		@r3		NVARCHAR(MAX) = ''col-xs-3 col-sm-3 col-md-1 text-right right-column''			, 
		-- Row - two columns - short right
		@l2s	NVARCHAR(MAX) = ''col-xs-8 col-sm-8 col-md-8 text-left left-column''				, 
		@r2s	NVARCHAR(MAX) = ''col-xs-4 col-sm-4 col-md-4 text-left right-column''				,
		-- Row - two columns - shorter right
		@l2xs	NVARCHAR(MAX) = ''col-xs-9 col-md-9 col-md-9 text-left left-column''				, 
		@r2xs	NVARCHAR(MAX) = ''col-xs-3 col-sm-3 col-md-3 text-right right-column''			,
		-- Row - one column - full width row
		@fwrc	NVARCHAR(MAX) = ''col-xs-12 col-sm-12 col-md-12 text-left full-width-column''		, 

		-- Summary wrapper
		@sumw		NVARCHAR(MAX) = ''container-fluid course-summary-wrapper''					,

		-- Paragraph header row wrapper
		@pghrow		NVARCHAR(MAX) = ''row course-summary-paragraph-header''						, 
		-- Paragraph header row - left column
		@pgl		NVARCHAR(MAX) = ''col-xs-10 col-sm-10 col-md-10 text-left left-column''		,
		-- Paragraph header row - right column
		@pgr		NVARCHAR(MAX) = ''col-xs-2 col-sm-2 col-md-2 text-right right-column''		,

		-- Paragraph row wrapper
		@pgrow		NVARCHAR(MAX) = ''row course-summary-paragraph''								, 
		-- Paragraph row - full width column
		@pgfw		NVARCHAR(MAX) = ''col-xs-12 col-sm-12 col-md-12 text-left full-width-column''	;

-------------------------------------------------------
-- Credits and Hours
-------------------------------------------------------
DECLARE @hoursScale INT = 1;
DECLARE @hoursDecimalFormat NVARCHAR(10) = CONCAT(''F'', @hoursScale);

DECLARE @courseCredits NVARCHAR(MAX) = (
SELECT CASE
	WHEN MinCreditHour IS NOT NULL AND MaxCreditHour IS NOT NULL
	AND MinCreditHour < MaxCreditHour AND COALESCE(Variable, 0) = 1
		THEN CONCAT
			(
			FORMAT(MinCreditHour, @hoursDecimalFormat), 
			''-'' , 
			FORMAT(MaxCreditHour, @hoursDecimalFormat)
			)
	WHEN MinCreditHour IS NOT NULL 
		THEN FORMAT(MinCreditHour, @hoursDecimalFormat)
	ELSE '''' END AS CourseCredits
FROM CourseDescription WHERE CourseId = @entityId
); 

DECLARE @combinedHours TABLE (
	CourseId INT PRIMARY KEY,
	CombinedText NVARCHAR(MAX)
	);

DECLARE @hourTypes TABLE (
	Id				INT IDENTITY(1, 1) PRIMARY KEY,
	CourseId		INT,
	Label			NVARCHAR(255),
	Min				DECIMAL(16, 3),
	Max				DECIMAL(16, 3),
	RenderedRange	NVARCHAR(255)
	);

WITH CourseDescriptionEntries AS (
	SELECT cd.* FROM CourseHourType cd WHERE cd.CourseId = @entityId
	)
INSERT INTO @hourTypes (CourseId, Label, Min, Max)
SELECT cht.CourseId, ht.Title , cht.MinCreditHours, cht.MaxCreditHours FROM CourseHourType AS cht
INNER JOIN HourType AS ht on cht.HourTypeId = ht.Id
WHERE cht.CourseId = @entityId

MERGE INTO @hourTypes t
USING (
	SELECT
	ht.Id,
	CASE 
		WHEN ht.Min IS NOT NULL AND ht.Max IS NOT NULL 
		AND ht.Min < ht.Max
		THEN CONCAT
			(
			FORMAT(ht.Min, @hoursDecimalFormat), 
			''-'', 
			FORMAT(ht.Max, @hoursDecimalFormat)
			)
		WHEN ht.Min IS NOT NULL AND ht.Min > 0 THEN FORMAT(ht.Min, @hoursDecimalFormat)
	ELSE NULL END AS RenderedRange
	FROM @hourTypes ht
	) s 
ON (t.Id = s.Id)
WHEN MATCHED THEN UPDATE SET t.RenderedRange = s.RenderedRange
;

INSERT INTO @combinedHours (CourseId, CombinedText)
SELECT ht.CourseId, STRING_AGG(rht.RenderedHourType, '', '')
FROM @hourTypes ht
	CROSS APPLY (
	SELECT CONCAT
		(
		dbo.fnHtmlOpenTag(@spanTag, 
			dbo.fnHtmlAttribute(@classAttrib, ''contact-hour-type-wrapper'')),
		dbo.fnHtmlOpenTag(@spanTag, 
			dbo.fnHtmlAttribute(@classAttrib, ''contact-hour-type-label'')),
			ht.Label,
		dbo.fnHtmlCloseTag(@spanTag),
			@space,
		dbo.fnHtmlOpenTag(@spanTag,
			dbo.fnHtmlAttribute(@classAttrib, ''contact-hour-type-value'')),
			ht.RenderedRange,  
		dbo.fnHtmlCloseTag(@spanTag),
		dbo.fnHtmlCloseTag(@spanTag)
		)
		AS RenderedHourType
	) rht
WHERE ht.RenderedRange IS NOT NULL
GROUP BY ht.CourseId;

-------------------------------------------------------
-- General Education
-------------------------------------------------------
/* 
The original query (63) was trying to pull in Gavilan GE information (which makes no sense),
and IGETC and CSU (which are California community college GE requirements). 

Since this was not showing any output for CSCC anyway, I am not including it here.
Something for their actual GE may need to be added here at some point, however, if they request it.
*/

-------------------------------------------------------
-- Output
-------------------------------------------------------
SELECT c.Id AS [Value],
	CONCAT
		(
		----------------------------------------------------------
		-- Course summary wrapper
		----------------------------------------------------------
		dbo.fnHtmlOpenTag(@divTag, CONCAT(
			dbo.fnHtmlAttribute(@classAttrib,	@sumw), @space,
			dbo.fnHtmlAttribute(@cidAttrib,		c.Id),  @space,
			dbo.fnHtmlAttribute(@bcidAttrib,	c.BaseCourseId)
		)),
		---------------------------------------------------
		-- Header row
		---------------------------------------------------
		dbo.fnHtmlOpenTag(@divTag, 
			dbo.fnHtmlAttribute(@classAttrib,	@pghrow)),
		dbo.fnHtmlOpenTag(@divTag, 
			dbo.fnHtmlAttribute(@classAttrib,	@pgl)),
		-- Subject
		dbo.fnHtmlOpenTag(@spanTag, CONCAT(
			dbo.fnHtmlAttribute(@classAttrib,   ''course-subject''), @space,
			dbo.fnHtmlAttribute(@titleAttrib,	s.Title)
		)), 
			s.SubjectCode, @space, 
		dbo.fnHtmlCloseTag(@spanTag),
		-- Course Number
		dbo.fnHtmlOpenTag(@spanTag, 
			dbo.fnHtmlAttribute(@classAttrib,	''course-number'')),
			c.CourseNumber, @space,
		dbo.fnHtmlCloseTag(@spanTag),
		-- Dash
		dbo.fnHtmlOpenTag(@spanTag, 
			dbo.fnHtmlAttribute(@classAttrib,	''course-number-title-separator'')),
			@dash,
		dbo.fnHtmlCloseTag(@spanTag),
		-- Course Title
		dbo.fnHtmlOpenTag(@spanTag, 
			dbo.fnHtmlAttribute(@classAttrib,	''course-title'')),
			c.Title, @space,
		dbo.fnHtmlCloseTag(@spanTag),
		-- Course Credits
		dbo.fnHtmlOpenTag(@spanTag,
			dbo.fnHtmlAttribute(@classAttrib,	''course-credits'')),
			''('', @courseCredits, '')'',
		dbo.fnHtmlCloseTag(@spanTag),
		dbo.fnHtmlCloseTag(@divTag),
		dbo.fnHtmlCloseTag(@divTag),
		---------------------------------------------------
		-- Summary content row 
		---------------------------------------------------
		dbo.fnHtmlOpenTag(@divTag, 
			dbo.fnHtmlAttribute(@classAttrib,	@pgrow)),
		dbo.fnHtmlOpenTag(@divTag,
			dbo.fnHtmlAttribute(@classAttrib,	@pgfw)),
		-- Hours
		dbo.fnHtmlOpenTag(@divTag,
			dbo.fnHtmlAttribute(@classAttrib,  ''course-hours-wrapper'')),
		dbo.fnHtmlOpenTag(@spanTag,
			dbo.fnHtmlAttribute(@classAttrib,  ''course-hours'')),
			CASE WHEN LEN(ch.CombinedText) > 0 THEN CONCAT(ch.CombinedText, ''.'') 
			ELSE '''' END,
		dbo.fnHtmlCloseTag(@spanTag),
		dbo.fnHtmlCloseTag(@divTag),
		-- Requisites
		dbo.fnHtmlOpenTag(@divTag, 
			dbo.fnHtmlAttribute(@classAttrib,	''course-requisites-wrapper'')),
		dbo.fnHtmlOpenTag(@spanTag,
			dbo.fnHtmlAttribute(@classAttrib,	''course-requisites'')),
			CASE WHEN rq.SerializationSuccess = 1 AND QuerySuccess = 1
			THEN sfr.Text ELSE ''(Something went wrong)''
			END,
		dbo.fnHtmlCloseTag(@spanTag),
		dbo.fnHtmlCloseTag(@divTag),
		-- Course Description, Lab Fees
		dbo.fnHtmlOpenTag(@divTag, 
			dbo.fnHtmlAttribute(@classAttrib,	''course-description-wrapper'')),
		dbo.fnHtmlOpenTag(@spanTag,
			dbo.fnHtmlAttribute(@classAttrib,	''course-description'')),
			COALESCE(c.Description, ''''),
		dbo.fnHtmlCloseTag(@spanTag),
		dbo.fnHtmlOpenTag(@spanTag, 
			dbo.fnHtmlAttribute(@classAttrib,	''course-lab-fees'')),
			CASE WHEN cf.CurrentFee IS NOT NULL 
			THEN CONCAT('' Lab Fee: $'', CAST(cf.CurrentFee AS NVARCHAR)) 
			ELSE NULL END,
		dbo.fnHtmlCloseTag(@spanTag),
		dbo.fnHtmlCloseTag(@divTag),
		dbo.fnHtmlCloseTag(@divTag),
		-- The original query (63) had a Grade Option here, but currently CSCC does not have grading options.
		---------------------------------------------------
		dbo.fnHtmlCloseTag(@divTag)
		----------------------------------------------------------
		) AS [Text]
FROM Course c 
	INNER JOIN Subject			s			ON c.SubjectId = s.Id
	LEFT JOIN @combinedHours	ch			ON ch.CourseId = c.Id
	LEFT JOIN CourseFee			cf			ON cf.CourseId = c.Id
	LEFT JOIN CourseDescription cd
		LEFT JOIN GradeOption	gpt	ON cd.GradeOptionId	  = gpt.Id
											ON cd.CourseId = c.Id
	LEFT JOIN CourseProposal	cp 
		LEFT JOIN Repeatability rp  ON cp.RepeatabilityId = rp.Id
		LEFT JOIN Semester      sem ON cp.SemesterId	  = sem.Id
											ON cp.CourseId = c.Id
	OUTER APPLY dbo.fnBulkResolveResolutionSqlQuery(
		@reqs, 1, c.Id, 
		CONCAT(''['', dbo.fnGenerateBulkResolveQueryParameter(''@entityId'', c.Id, ''int''), '']'')
	) rq
	OUTER APPLY OPENJSON(rq.SerializedFullRow)
	WITH (
		[Value] INT			  ''$.Value'',
		[Text]	NVARCHAR(MAX) ''$.Text''
	) sfr
WHERE c.Id = @entityId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id