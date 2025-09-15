USE [reedley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19532';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog Curriculum Presentation to dispaly part 2 catalog description when the course is CCN';
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
UPDATE OutputTemplateClient
SET TemplateQuery = '
--#region query
DECLARE @hoursScale0 INT = 0, 
		@hoursScale1 INT = 1, 
		@hoursScale2 INT = 2;

DECLARE @hoursDecimalFormat0		NVARCHAR(10) = CONCAT(''F'', @hoursScale0), 
		@hoursDecimalFormat1		NVARCHAR(10) = CONCAT(''F'', @hoursScale1),	
		@hoursDecimalFormat2		NVARCHAR(10) = CONCAT(''F'', @hoursScale2),
		@empty						NVARCHAR(1)  = '''', 
		@space						NVARCHAR(5)  = '' '', 
		@newLine					NVARCHAR(5)  = ''<br>'', 
		@classAttrib				NVARCHAR(10) = ''class'', 
		@titleAttrib				NVARCHAR(10) = ''title'', 
		@openComment				NVARCHAR(10) = ''<!-- '', 
		@closeComment				NVARCHAR(10) = '' -->'', 
		@styleAttribute				NVARCHAR(5)  = ''style'',
		@emptyValueDisplay			NVARCHAR(5)  = ''None'',
		@emptyNumericValueDisplay	NVARCHAR(5)  = ''0'',
		@separator					NVARCHAR(5)  = ''. '';

DECLARE @tags TABLE (
	Id	  INT,
	Title NVARCHAR(255) UNIQUE NONCLUSTERED,
	Tag	  NVARCHAR(10)
	);

INSERT INTO @tags (Id, Title, Tag)
VALUES
	(1,  ''DivWrapper'',		''div'' ),
	(2,  ''Row'',				''div'' ),
	(3,  ''Column'',			''div'' ),
	(4,  ''DataElement'',		''span''),
	(5,  ''Block'',			''div'' ),
	(6,  ''Label'',			''span''),
	(7,  ''Spacer'',			''br''  ),
	(8,  ''BoldElement'',		''b''	  ),
	(9,  ''SecondaryLabel'',	''u''	  ),
	(10, ''ItalicElement'',	''i''   );

DECLARE @divWrapperTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Title = ''DivWrapper''),		-- Group wrappers
		@rowTag			NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Title = ''Row''),				-- Row wrappers
		@columnTag		NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Title = ''Column''),			-- Column wrappers
		@dataElemTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Title = ''DataElement''),		-- Elements in columns
		@blockTag		NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Title = ''Block''),			-- Generic layout blocks
		@labelTag		NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Title = ''Label''),			-- Labels
		@spacerTag		NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Title = ''Spacer''),			-- Line break insert
		@boldElemTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Title = ''BoldElement''),		-- Bold elements
		@secLabelTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Title = ''SecondaryLabel''),	-- Alternate labels
		@italicElemTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Title = ''ItalicElement'');	-- Italic elements

DECLARE @elementClasses TABLE (
	Id						INT PRIMARY KEY,
	ClassSetTitle			NVARCHAR(255) UNIQUE NONCLUSTERED,
	Wrapper					NVARCHAR(255),
	LeftColumn				NVARCHAR(255),
	MiddleColumn			NVARCHAR(255),
	RightColumn				NVARCHAR(255),
	FullWidthColumn			NVARCHAR(255),
	-- Computed full class attributes
	WrapperAttrib			AS COALESCE(''class="'' + Wrapper		 + ''"'', ''''),
	LeftColumnAttrib		AS COALESCE(''class="'' + LeftColumn		 + ''"'', ''''),
	MiddleColumnAttrib		AS COALESCE(''class="'' + MiddleColumn	 + ''"'', ''''),
	RightColumnAttrib		AS COALESCE(''class="'' + RightColumn	 + ''"'', ''''),
	FullWidthColumnAttrib	AS COALESCE(''class="'' + FullWidthColumn + ''"'', '''')
	);

INSERT INTO @elementClasses 
	(Id, ClassSetTitle, Wrapper, LeftColumn, MiddleColumn, RightColumn, FullWidthColumn)
VALUES
	(1, ''ThreeColumn'', ''row'',
	''col-xs-3 col-sm-3 col-md-1 text-left left-column'', 
	''col-xs-6 col-sm-6 col-md-10 text-left middle-column'', 
	''col-xs-3 col-sm-3 col-md-1 text-right right-column'', 
	NULL),
	(2, ''TwoColumnShorterRight'', ''row'', 
	''col-xs-9 col-md-9 col-md-9 text-left left-column'', 
	NULL, 
	''col-xs-3 col-sm-3 col-md-3 text-right right-column'', 
	NULL),
	(3, ''TwoColumnShortRight'', ''row'', 
	''col-xs-8 col-sm-8 col-md-8 text-left left-column'', 
	NULL, 
	''col-xs-4 col-sm-4 col-md-4 text-left right-column'', 
	NULL),
	(4, ''FullWidthRow'', ''row'', 
	NULL, NULL, NULL, 
	''col-xs-12 col-sm-12 col-md-12 text-left full-width-column'')
	;

DECLARE @modelRoot TABLE (
	CourseId INT PRIMARY KEY,
	InsertOrder INT,
	RootData NVARCHAR(MAX)
	);

DECLARE @modelRootData TABLE (
	CourseId				INT PRIMARY KEY,
	SubjectCode				NVARCHAR(MAX),
	CourseNumber			NVARCHAR(MAX),
	CourseTitle				NVARCHAR(MAX),
	Weeks					INT,
	Variable				BIT,
	MinUnit					DECIMAL(16, 3),
	MaxUnit					DECIMAL(16, 3),
	MinLec					DECIMAL(16, 3),
	MaxLec					DECIMAL(16, 3),
	MinLab					DECIMAL(16, 3),
	MaxLab					DECIMAL(16, 3),
	Grading					NVARCHAR(MAX),	
	OpenEntry				BIT,
	Repeats					NVARCHAR(MAX),
	CrossList				NVARCHAR(MAX),
	Formerly				NVARCHAR(MAX),
	Requisites				NVARCHAR(MAX),
	CatalogDesc				NVARCHAR(MAX),
	CatalogDesc2				NVARCHAR(MAX),
	CB05					NVARCHAR(MAX),
	NonCredit				BIT,
	CIDNumber				NVARCHAR(MAX),
	CB04					NVARCHAR(MAX),
	Term					NVARCHAR(MAX)
	);

DECLARE @unitHourRanges TABLE (
	Id				INT NOT NULL IDENTITY PRIMARY KEY,
	CourseId		INT,
	UnitHourTypeId	INT,
	RenderedRange	NVARCHAR(100)
	);

INSERT INTO @modelRoot (CourseId, InsertOrder, RootData)
SELECT em.[Key], m.InsertOrder, m.RootData
FROM @entityModels em
	CROSS APPLY OPENJSON(em.[Value])
		WITH (
			InsertOrder INT ''$.InsertOrder'',
			RootData	NVARCHAR(MAX) ''$.RootData'' AS JSON
		) m
		;

INSERT INTO @modelRootData (
	CourseId,
	SubjectCode,
	CourseNumber,
	CourseTitle,
	Weeks,
	Variable,
	MinUnit,
	MaxUnit,
	MinLec,
	MaxLec,
	MinLab,
	MaxLab,
	Grading,
	OpenEntry,
	Repeats,
	CrossList,
	Formerly,
	Requisites,
	CatalogDesc,
	CatalogDesc2,
	CB05,
	NonCredit,
	CIDNumber,
	CB04,
	Term
	)
	SELECT  
		m.CourseId, 
		m.SubjectCode,
		m.CourseNumber, 
		m.CourseTitle, 
		m.Weeks,
		m.Variable, 
		m.MinUnit, 
		m.MaxUnit, 
		m.MinLec, 
		m.MaxLec, 
		m.MinLab, 
		m.MaxLab,
		CASE WHEN m.Grading		IS NOT NULL AND LEN(m.Grading)		> 0 THEN m.Grading		ELSE NULL END AS Grading, 
		m.OpenEntry, 
		CASE WHEN m.Repeats		IS NOT NULL AND LEN(m.Repeats)		> 0 THEN m.Repeats		ELSE NULL END AS Repeats, 
		CASE WHEN m.CrossList	IS NOT NULL AND LEN(m.CrossList)	> 0 THEN m.CrossList	ELSE NULL END AS CrossList, 
		CASE WHEN m.Formerly	IS NOT NULL AND LEN(m.Formerly)		> 0 THEN m.Formerly		ELSE NULL END, 
		CASE WHEN m.Requisites	IS NOT NULL AND LEN(m.Requisites)	> 0 THEN m.Requisites	ELSE NULL END AS Requisites, 
		CASE WHEN m.CatalogDesc	IS NOT NULL AND LEN(m.CatalogDesc)	> 0 THEN m.CatalogDesc	ELSE NULL END AS CatalogDesc, 
		CASE WHEN m.CatalogDesc2	IS NOT NULL AND LEN(m.CatalogDesc2)	> 0 THEN m.CatalogDesc2	ELSE NULL END AS CatalogDesc2,
		CASE WHEN m.CB05		IS NOT NULL AND LEN(m.CB05)			> 0 THEN m.CB05			ELSE NULL END AS CB05, 
		m.NonCredit,
		CASE WHEN m.CIDNumber	IS NOT NULL AND LEN(m.CIDNumber)	> 0 THEN m.CIDNumber	ELSE NULL END AS CIDNumber, 
		CASE WHEN m.CB04		IS NOT NULL AND LEN(m.CB04)			> 0 THEN m.CB04			ELSE NULL END AS CB04,
		CASE WHEN m.Term		IS NOT NULL AND LEN(m.Term)			> 0 THEN m.Term			ELSE NULL END
	FROM @modelRoot mr
		CROSS APPLY OPENJSON(mr.RootData)
		WITH (
			CourseId		INT				''$.CourseId'',
			SubjectCode		NVARCHAR(MAX)	''$.SubjectCode'',
			CourseNumber	NVARCHAR(MAX)	''$.CourseNumber'',
			CourseTitle		NVARCHAR(MAX)	''$.CourseTitle'',
			Weeks			NVARCHAR(MAX)	''$.Weeks'',
			Variable		BIT				''$.Variable'',
			MinUnit			DECIMAL(16, 3)	''$.MinUnit'',
			MaxUnit			DECIMAL(16, 3)	''$.MaxUnit'',
			MinLec			DECIMAL(16, 3)	''$.MinLec'',
			MaxLec			DECIMAL(16, 3)	''$.MaxLec'',
			MinLab			DECIMAL(16, 3)	''$.MinLab'',
			MaxLab			DECIMAL(16, 3)	''$.MaxLab'',
			Grading			NVARCHAR(MAX)	''$.Grading'',
			OpenEntry		BIT				''$.OpenEntry'',
			Repeats			NVARCHAR(MAX)	''$.Repeats'',
			CrossList		NVARCHAR(MAX)	''$.CrossList'',
			Formerly		NVARCHAR(MAX)	''$.Formerly'',
			Requisites		NVARCHAR(MAX)	''$.Requisites'',
			CatalogDesc		NVARCHAR(MAX)	''$.CatalogDesc'',
			CatalogDesc2		NVARCHAR(MAX)	''$.CatalogDesc2'',
			CB05			NVARCHAR(MAX)	''$.CB05'',
			NonCredit		BIT				''$.NonCredit'',
			CIDNumber		NVARCHAR(MAX)	''$.CIDNumber'',
			CB04			NVARCHAR(MAX)	''$.CB04'',
			Term			NVARCHAR(MAX)	''$.Term''
		) m
		;

INSERT INTO @unitHourRanges (CourseId, UnitHourTypeId, RenderedRange)
SELECT mrd.CourseId, uht.UnitHourTypeId, uhr.RenderedRange
FROM @modelRootData mrd
	CROSS APPLY ( 
		SELECT 1 AS UnitHourTypeId, -- Units
			CASE WHEN mrd.NonCredit = 1 THEN
				CASE WHEN dbo.fnCourseNumberToNumeric(mrd.CourseNumber) BETWEEN 300 AND 399
				THEN FORMAT(mrd.MinUnit, @hoursDecimalFormat1) ELSE NULL END
			ELSE FORMAT(mrd.MinUnit, @hoursDecimalFormat1) END AS MinVal, 
			CASE WHEN mrd.NonCredit = 1 THEN
				CASE WHEN dbo.fnCourseNumberToNumeric(mrd.CourseNumber) BETWEEN 300 AND 399
				THEN FORMAT(mrd.MaxUnit, @hoursDecimalFormat1) ELSE NULL END
			ELSE FORMAT(mrd.MaxUnit, @hoursDecimalFormat1) END AS MaxVal, 
			1 AS RenderIfZero, 
			0 AS ForceRange, 
			mrd.Variable, 
			1 AS FormatType, 
			1 AS Render
		UNION ALL
		SELECT 2 AS UnitHourTypeId, -- Lec
			FORMAT(mrd.MinLec, @hoursDecimalFormat1) AS MinVal, 
			FORMAT(mrd.MaxLec, @hoursDecimalFormat1) AS MaxVal, 
			1 AS RenderIfZero, 
			0 AS ForceRange,
			mrd.Variable, 
			1 AS FormatType, 
			1 AS Render
		UNION ALL
		SELECT 3 AS UnitHourTypeId, -- Lab
			FORMAT(mrd.MinLab, @hoursDecimalFormat1) AS MinVal, 
			FORMAT(mrd.MaxLab, @hoursDecimalFormat1) AS MaxVal, 
			1 AS RenderIfZero, 
			0 AS ForceRange, 
			mrd.Variable, 
			1 AS FormatType, 
			1 AS Render
	) uht
	CROSS APPLY (
		SELECT 
		CASE WHEN uht.Render = 1 THEN 
			CASE WHEN uht.Variable = 1 OR uht.ForceRange = 1 THEN					-- If variable and:
				CASE WHEN CAST(uht.MinVal AS NVARCHAR) IS NOT NULL THEN 
					CASE WHEN CAST(uht.MaxVal AS NVARCHAR) IS NOT NULL THEN 
						CASE WHEN CAST(uht.MinVal AS NVARCHAR) != CAST(uht.MaxVal AS NVARCHAR)
							 AND  CAST(uht.MinVal AS NVARCHAR) < CAST(uht.MaxVal AS NVARCHAR) THEN -- If Max is greater than Min, show Min-Max range
							 CONCAT(uht.MinVal, ''-'', uht.MaxVal)
						ELSE CAST(uht.MinVal AS NVARCHAR) END								-- If Max is equal to or less than Min, show Min only
					ELSE CAST(uht.MinVal AS NVARCHAR) END									-- If Max is null, show Min only
				ELSE 
					CASE WHEN CAST(uht.MaxVal AS NVARCHAR) IS NOT NULL THEN CAST(uht.MaxVal AS NVARCHAR) -- If Min is null but Max is not, show Max only
					ELSE NULL END																		 -- If both Min and Max are null, then null
				END 
			ELSE																	-- If not variable and:
				CASE WHEN CAST(uht.MinVal AS NVARCHAR) IS NOT NULL THEN CAST(uht.MinVal AS NVARCHAR)	 -- If Min is not null, show Min only
				ELSE NULL END																			 -- If Min is null, then null
			END		
		ELSE NULL END AS RenderedRange	
	) uhr
	;

SELECT mr.CourseId AS [Value], CONCAT
	( 
	--------------------------------------------
	-- Custom course summary context wrapper
	--------------------------------------------
	dbo.fnHtmlOpenTag(@divWrapperTag, dbo.fnHtmlAttribute(@classAttrib, ''custom-course-summary-context-wrapper'')),
	--------------------------------------------
	-- Another nested wrapper
	--------------------------------------------
	dbo.fnHtmlOpenTag(@divWrapperTag, CONCAT(
		dbo.fnHtmlAttribute(@classAttrib, ''container-fluid course-summary-wrapper''), @space,
		dbo.fnHtmlAttribute(''data-course-id'', mrd.CourseId))),
	--------------------------------------------
	-- Course Title row (Course subject code, number, and title)
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(
		ecfw.Wrapper, @space, ''course-title-header''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	/* Course Subject */
	dbo.fnHtmlOpenTag(@boldElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-subject'')),
		ISNULL(mrd.SubjectCode, @emptyValueDisplay),
	dbo.fnHtmlCloseTag(@boldElemTag),
	dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-title-course-number-delimeter'')),
		@space,
	dbo.fnHtmlCloseTag(@dataElemTag),
	/* Course Number */
	dbo.fnHtmlOpenTag(@boldElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-number'')),
		ISNULL(mrd.CourseNumber, @emptyValueDisplay), @space,
	dbo.fnHtmlCloseTag(@boldElemTag),
	/* Course Title */
	dbo.fnHtmlOpenTag(@boldElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-title'')),
		COALESCE(mrd.CourseTitle, CONCAT(''('', @emptyValueDisplay, '')'')),
	dbo.fnHtmlCloseTag(@boldElemTag),
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- Units and Hours
	--------------------------------------------
	/* Units */
	CASE WHEN unithr.RenderedRange IS NOT NULL THEN CONCAT
		(
		CASE WHEN mrd.NonCredit = 1 THEN 
			CASE WHEN dbo.fnCourseNumberToNumeric(mrd.CourseNumber) BETWEEN 300 AND 399 THEN ''Units:'' ELSE ''Hours:'' END
		ELSE ''Units:'' END, 
			@space, ISNULL(unithr.RenderedRange, @emptyNumericValueDisplay),
		CASE WHEN lechr.RenderedRange IS NOT NULL OR labhr.RenderedRange IS NOT NULL OR mrd.Weeks IS NOT NULL
		THEN @separator ELSE @empty END
		)
	ELSE @empty END,
	/* Weekly Lecture Hours */
	CASE WHEN lechr.RenderedRange IS NOT NULL THEN CONCAT
		(
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lec-label'')), 
			''Weekly Lecture Hours:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-hours-range'')),
			ISNULL(lechr.RenderedRange, @emptyNumericValueDisplay),
		CASE WHEN  labhr.RenderedRange IS NOT NULL or mrd.Weeks IS NOT NULL THEN @separator ELSE @empty END,
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
	/* Weekly Lab Hours */
	CASE WHEN labhr.RenderedRange IS NOT NULL THEN CONCAT
		(
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lab-label'')),
			''Weekly Lab Hours:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''lab-hours-range'')),
			ISNULL(labhr.RenderedRange, @emptyNumericValueDisplay),
		CASE WHEN  mrd.Weeks IS NOT NULL THEN @separator ELSE @empty END,
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
	/* Weeks */
	CASE WHEN mrd.Weeks IS NOT NULL AND mrd.Weeks != 18 THEN CONCAT
		(
		''Weeks:'', @space,
		CASE WHEN mrd.Weeks IS NULL THEN @emptyNumericValueDisplay ELSE CONCAT(mrd.Weeks, ''.'') END
		)
	ELSE @empty END,							
	/* Course was formerly... */
	CASE WHEN mrd.Formerly IS NOT NULL THEN CONCAT('' Formerly: '', mrd.Formerly, ''.'') ELSE '''' END,
	/* Crosslist */
	CASE WHEN mrd.CrossList IS NOT NULL THEN CONCAT
		(
		'' Cross-Listed Courses:'', @space,
		ISNULL(mrd.CrossList, @emptyValueDisplay),
		CASE WHEN mrd.CrossList IS NULL THEN '''' ELSE ''.'' END
		)
	ELSE @empty END,
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------	
	-- Course Grading
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(
		ecfw.Wrapper, @space, ''course-grading-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	/* Grading Policy */
	CASE WHEN mrd.Grading IS NOT NULL AND mrd.Grading LIKE ''Pass/No Pass Only'' THEN CONCAT	
		(
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-grading-label'')),
			''Grading:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-grading-value'')),
			ISNULL(mrd.Grading, @emptyValueDisplay),
			CASE WHEN  mrd.OpenEntry IS NOT NULL or mrd.Repeats IS NOT NULL THEN @separator ELSE @empty END,
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
	/* Open Entry/Open Exit */
	CASE WHEN mrd.OpenEntry = 1 THEN CONCAT	
		(
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-openentry-label'')),
			''Open Entry/Open Exit:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-openentry-value'')),
			CASE WHEN mrd.OpenEntry = 1 THEN ''Yes''      ELSE ''No''   END,
			CASE WHEN mrd.OpenEntry = 1 THEN @separator ELSE @empty END,
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
	/* Times Repeated */
	CASE WHEN mrd.Repeats > 0 THEN CONCAT	
		(
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-repeat-label'')),
			''Times Repeated:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-repeat-value'')),
			ISNULL(mrd.Repeats, @emptyValueDisplay), 
			CASE WHEN mrd.Repeats > 0 THEN @separator ELSE @empty END, 
			@space,
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- Requisites
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(
		ecfw.Wrapper, @space, ''course-requisite-description-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, ''course-requisite-catalog-view'')),
		ISNULL(mrd.Requisites, @empty),
	dbo.fnHtmlCloseTag(@rowTag),
		CASE WHEN mrd.Requisites IS NOT NULL THEN @space ELSE @empty END,
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- Course Description
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(
		ecfw.Wrapper, @space, ''course-description-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	CASE WHEN mrd.CatalogDesc IS NOT NULL THEN CONCAT 
		(
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-description-label'')),
			''Description:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-description-value'')),
			CONCAT(mrd.CatalogDesc,''<br>''),
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
		CASE WHEN mrd.CatalogDesc2 IS NOT NULL THEN CONCAT 
		(
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-description2-label'')),
			''CCN Description:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-description2-value'')),
			ISNULL(mrd.CatalogDesc2, @empty),
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- CB05 (Transferability)
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(
		ecfw.Wrapper, @space, ''course-transferability-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),		
	/* CB05 */
	CASE WHEN mrd.CB05 IS NOT NULL THEN CONCAT 
		(
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-transferability-label'')),
			''Transferability:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-transferability-value'')),
			ISNULL(mrd.CB05, @emptyValueDisplay), 
			CASE WHEN mrd.CIDNumber IS NOT NULL AND RIGHT(mrd.CB05, 1) != ''.'' THEN @separator ELSE @space END,
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
	/* C-ID */
	CASE WHEN mrd.CIDNumber IS NOT NULL THEN CONCAT
		(
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CID-label'')),
			''C-ID:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-CID-value'')),
			ISNULL(mrd.CIDNumber, @emptyValueDisplay),
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- CB04 (Credit Status)
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(
		ecfw.Wrapper, @space, ''course-credit-status-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),	
	CASE WHEN mrd.CB04 IS NOT NULL THEN CONCAT
		(	
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-credit-status-label'')),
			''Credit Status:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-credit-status-value'')),
			ISNULL(mrd.CB04, @emptyValueDisplay), 
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- Term
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(
		ecfw.Wrapper, @space, ''course-term-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	CASE WHEN mrd.Term IS NOT NULL THEN CONCAT
		(
		dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''course-term-label'')),
			''Term:'', @space,
		dbo.fnHtmlCloseTag(@labelTag),
		dbo.fnHtmlOpenTag(@dataElemTag, dbo.fnHtmlAttribute(@classAttrib, ''course-term-value'')),
			ISNULL(mrd.Term, @emptyValueDisplay),
		dbo.fnHtmlCloseTag(@dataElemTag)
		)
	ELSE @empty END,
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	dbo.fnHtmlCloseTag(@divWrapperTag),
	dbo.fnHtmlCloseTag(@divWrapperTag)
	) AS [Text]
FROM @modelRoot mr
	INNER JOIN @modelRootData  mrd	  ON mr.CourseId  = mrd.CourseId
	LEFT JOIN  @unitHourRanges unithr ON (mr.CourseId = unithr.CourseId AND unithr.UnitHourTypeId = 1)
	LEFT JOIN  @unitHourRanges lechr  ON (mr.CourseId = lechr.CourseId  AND lechr.UnitHourTypeId  = 2)
	LEFT JOIN  @unitHourRanges labhr  ON (mr.CourseId = labhr.CourseId  AND labhr.UnitHourTypeId  = 3)
	INNER JOIN @elementClasses ecfw   ON ecfw.Id	  = 4 -- 4 = FullWidthRow
ORDER BY mr.InsertOrder
--#endregion query
'
WHERE Id = 2

UPDATE OutputModelClient
SET ModelQuery = '
--#region query
DECLARE @entityList_internal TABLE (
	InsertOrder INT IDENTITY(1, 1) PRIMARY KEY,
	CourseId INT
	);

INSERT INTO @entityList_internal (CourseId)
SELECT el.Id FROM @entityList el;
--VALUES (5600);

DECLARE @entityRootData TABLE 
	(	
	CourseId				INT PRIMARY KEY,
	SubjectCode				NVARCHAR(MAX),
	CourseNumber			NVARCHAR(MAX),
	CourseTitle				NVARCHAR(MAX),
	Weeks					INT,
	Variable				BIT,
	MinUnit					DECIMAL(16, 3),
	MaxUnit					DECIMAL(16, 3),
	MinLec					DECIMAL(16, 3),
	MaxLec					DECIMAL(16, 3),
	MinLab					DECIMAL(16, 3),
	MaxLab					DECIMAL(16, 3),
	Grading					NVARCHAR(MAX),
	OpenEntry				BIT,
	Repeats					NVARCHAR(MAX),
	CrossList				NVARCHAR(MAX),
	Formerly				NVARCHAR(MAX),
	Requisites				NVARCHAR(MAX),
	CatalogDesc				NVARCHAR(MAX),
	CatalogDesc2				NVARCHAR(MAX),
	CB05					NVARCHAR(MAX),
	NonCredit				BIT,
	CIDNumber				NVARCHAR(MAX),
	CB04					NVARCHAR(MAX),
	Term					NVARCHAR(MAX)
	);

DECLARE @clientId INT = 1;

DECLARE @prqLabel NVARCHAR(MAX) = ''<span class="rt-label">Prerequisite: </span>'', 
		@crqLabel NVARCHAR(MAX) = ''<span class="rt-label">Corequisite: </span>'' , 
		@limLabel NVARCHAR(MAX) = ''<span class="rt-label">Limitation on Enrollment: </span>'', 
		@advLabel NVARCHAR(MAX) = ''<span class="rt-label">Advisory: </span>'',
		@atrLabel NVARCHAR(MAX) = ''<span class="rt-label">Anti Requisite: </span>'';

INSERT INTO @entityRootData
	(
	CourseId, 
	SubjectCode, 
	CourseNumber, 
	CourseTitle, 
	Weeks, 
	Variable, 
	MinUnit, 
	MaxUnit, 
	MinLec, 
	MaxLec, 
	MinLab, 
	MaxLab, 
	Grading, 
	OpenEntry, 
	Repeats, 
	CrossList, 
	Formerly, 
	Requisites, 
	CatalogDesc,
	CatalogDesc2,
	CB05, 
	NonCredit, 
	CIDNumber,
	CB04,
	Term
	)

SELECT
	c.Id,
	s.SubjectCode,
	c.CourseNumber,
	c.Title,
	cd.ShortTermWeek,
	cd.Variable,
	cd.MinCreditHour,
	cd.MaxCreditHour,
	cd.MinLectureHour,
	cd.MaxLectureHour,
	cd.MinLabHour,
	cd.MaxLabHour,
	gdo.Title,
	c.OpenEntry,
	rep.Code,
	COALESCE(crc.RenderedText, c.CrossListedCourses) AS CrossListedCourses,
	c.MandateDescription,
	CONCAT
		(
		CASE WHEN LEN(prq.Text) > 0 THEN CONCAT(@prqLabel, prq.Text) ELSE NULL END,
		CASE WHEN LEN(crq.Text) > 0 THEN CASE WHEN LEN(prq.Text) > 0 
			 THEN CONCAT(''<br>'', @crqLabel, crq.Text) ELSE CONCAT(@crqLabel, crq.Text) END ELSE NULL END,	 
		CASE WHEN LEN(lim.Text) > 0 THEN CASE WHEN LEN(crq.Text) > 0 OR LEN(prq.Text) > 0
			 THEN CONCAT(''<br>'', @limLabel, lim.Text) ELSE CONCAT(@limLabel, lim.Text) END ELSE NULL END,
		CASE WHEN LEN(adv.Text) > 0 THEN CASE WHEN LEN(lim.Text) > 0 OR LEN(crq.Text) > 0 OR LEN(prq.Text) > 0 
			 THEN CONCAT(''<br>'', @advLabel, adv.Text) ELSE CONCAT(@advLabel, adv.Text) END ELSE NULL END,
		CASE WHEN LEN(atr.Text) > 0 THEN CASE WHEN LEN(adv.Text) > 0 OR LEN(lim.Text) > 0 OR LEN(crq.Text) > 0 OR LEN(prq.Text) > 0
			 THEN CONCAT(''<br>'', @atrLabel, atr.Text) END ELSE NULL END
		) AS Requisites, 	
	c.Description,
	gmt.TextMax08,
	CASE WHEN cb05.Id IS NOT NULL THEN CONCAT(cb05.Code, '' - '', cb05.Description) ELSE NULL END,
	CASE WHEN cb04.Id = 3 THEN 1 ELSE 0 END,
	COALESCE(c.ClientCode, c.Budget, c.CampusOfOrigin, c.PatternNumber) AS CIDNumber,
	CASE WHEN cb04.Id IS NOT NULL THEN CONCAT(cb04.Code, '' - '', cb04.Description) ELSE NULL END,
	sem.Title
FROM Course c
	INNER JOIN @entityList_internal eli		ON c.Id				= eli.CourseId
	INNER JOIN Subject				s		ON s.Id				= c.SubjectId
	INNER JOIN CourseDescription	cd		ON c.Id				= cd.CourseId
	INNER JOIN CourseProposal		cp		ON cd.CourseId		= cp.CourseId
	INNER JOIN CourseCBCode         cbc		ON c.Id				= cbc.CourseId
	INNER JOIN ProposalType			pt		ON pt.Id			= c.ProposalTypeId
	LEFT JOIN GenericMaxText gmt on gmt.CourseId = c.Id
	LEFT JOIN  Semester				sem		ON sem.Id			= cp.SemesterId
	LEFT JOIN  Repeatability		rep		ON rep.Id			= cp.RepeatabilityId
	LEFT JOIN  GradeOption			gdo		ON gdo.Id			= cd.GradeOptionId
	LEFT JOIN  CB05					cb05	ON cb05.Id			= cbc.CB05Id
	LEFT JOIN  CB04					cb04	ON cb04.Id			= cbc.CB04Id
	OUTER APPLY (
		SELECT STRING_AGG(crc.RenderedText, '', '') WITHIN GROUP (ORDER BY crc.SortOrder) AS RenderedText
		FROM (
			SELECT 
				ROW_NUMBER() OVER (PARTITION BY crc.CourseId ORDER BY crcs.SubjectCode, crcc.CourseNumber) AS SortOrder, 
				CONCAT(crcs.SubjectCode, '' '', crcc.CourseNumber) AS RenderedText
			FROM CourseRelatedCourse crc
				INNER JOIN Course    crcc ON crc.RelatedCourseId = crcc.Id
				INNER JOIN [Subject] crcs ON crcc.SubjectId		 = crcs.Id
			WHERE c.Id = crc.CourseId
	) crc) crc
	OUTER APPLY (SELECT STRING_AGG(CONCAT(
		COALESCE(CONCAT(rs.SubjectCode, '' '', rc.CourseNumber), NULL), 
		CASE WHEN rc.Id IS NOT NULL AND cr.CourseRequisiteComment IS NOT NULL THEN '' - '' ELSE NULL END,
		COALESCE(cr.CourseRequisiteComment, NULL)
		), ''; '') AS [Text]
		FROM CourseRequisite cr 
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
			LEFT JOIN Course rc INNER JOIN Subject rs ON rc.SubjectId = rs.Id ON cr.Requisite_CourseId = rc.Id
		WHERE cr.CourseId = c.Id AND rt.Id = 1
	) prq
	OUTER APPLY (SELECT STRING_AGG(CONCAT(
		COALESCE(CONCAT(rs.SubjectCode, '' '', rc.CourseNumber), NULL), 
		CASE WHEN rc.Id IS NOT NULL AND cr.CourseRequisiteComment IS NOT NULL THEN '' - '' ELSE NULL END,
		COALESCE(cr.CourseRequisiteComment, NULL)
		), ''; '') AS [Text]
		FROM CourseRequisite cr 
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
			LEFT JOIN Course rc INNER JOIN Subject rs ON rc.SubjectId = rs.Id ON cr.Requisite_CourseId = rc.Id
		WHERE cr.CourseId = c.Id AND rt.Id = 2
	) crq
	OUTER APPLY (SELECT STRING_AGG(CONCAT(
		COALESCE(CONCAT(rs.SubjectCode, '' '', rc.CourseNumber), NULL), 
		CASE WHEN rc.Id IS NOT NULL AND cr.CourseRequisiteComment IS NOT NULL THEN '' - '' ELSE NULL END,
		COALESCE(cr.CourseRequisiteComment, NULL)
		), ''; '') AS [Text]
		FROM CourseRequisite cr 
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
			LEFT JOIN Course rc INNER JOIN Subject rs ON rc.SubjectId = rs.Id ON cr.Requisite_CourseId = rc.Id
		WHERE cr.CourseId = c.Id AND rt.Id = 6
	) lim
	OUTER APPLY (SELECT STRING_AGG(CONCAT(
		COALESCE(CONCAT(rs.SubjectCode, '' '', rc.CourseNumber), NULL), 
		CASE WHEN rc.Id IS NOT NULL AND cr.CourseRequisiteComment IS NOT NULL THEN '' - '' ELSE NULL END,
		COALESCE(cr.CourseRequisiteComment, NULL)
		), ''; '') AS [Text]
		FROM CourseRequisite cr 
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
			LEFT JOIN Course rc INNER JOIN Subject rs ON rc.SubjectId = rs.Id ON cr.Requisite_CourseId = rc.Id
		WHERE cr.CourseId = c.Id AND rt.Id = 12
	) adv
	OUTER APPLY (SELECT STRING_AGG(CONCAT(
		COALESCE(CONCAT(rs.SubjectCode, '' '', rc.CourseNumber), NULL), 
		CASE WHEN rc.Id IS NOT NULL AND cr.CourseRequisiteComment IS NOT NULL THEN '' - '' ELSE NULL END,
		COALESCE(cr.CourseRequisiteComment, NULL)
		), ''; '') AS [Text]
		FROM CourseRequisite cr 
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
			LEFT JOIN Course rc INNER JOIN Subject rs ON rc.SubjectId = rs.Id ON cr.Requisite_CourseId = rc.Id
		WHERE cr.CourseId = c.Id AND rt.Id = 13
	) atr
WHERE pt.ProcessActionTypeId != 3

SELECT eli.CourseId AS Id, m.Model
FROM @entityList_internal eli
	CROSS APPLY (SELECT (
		SELECT * FROM @entityRootData erd
		WHERE eli.CourseId = erd.CourseId FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	) RootData) erd
	CROSS APPLY (SELECT (
		SELECT eli.InsertOrder, JSON_QUERY(erd.RootData) AS RootData FOR JSON PATH
	) Model) m
'
WHERE Id = 1