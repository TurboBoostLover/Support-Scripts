USE [butte];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19874';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text on COR to remove trailing 0.00 ';
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
DECLARE @Id int = 244

DECLARE @SQL NVARCHAR(MAX) = '
--------------------------------------------------------------------
/* Uncomment this line for testing only - use to test query output for a course */
 --DECLARE @entityId INT = 4501; 
--------------------------------------------------------------------

--------------------------------------------------------------------
-- HTML Attributes & Tags
--------------------------------------------------------------------
DECLARE @classAttrib NVARCHAR(MAX) = ''class''	, 
		@idAttrib	 NVARCHAR(MAX) = ''id''		,
		@styleAttrib NVARCHAR(MAX) = ''style''	,
		@cspAttrib	 NVARCHAR(MAX) = ''colspan''	;

DECLARE @space		 NVARCHAR(MAX) = '' ''		;

DECLARE @divTag		 NVARCHAR(MAX) = ''div''		,
		@tableTag	 NVARCHAR(MAX) = ''table''	,
		@theadTag	 NVARCHAR(MAX) = ''thead''	,
		@tfootTag	 NVARCHAR(MAX) = ''tfoot''	,
		@trTag		 NVARCHAR(MAX) = ''tr''		,
		@thTag		 NVARCHAR(MAX) = ''th''		,
		@tdTag		 NVARCHAR(MAX) = ''td''		,
		@boldTag	 NVARCHAR(MAX) = ''b''		,
		@uTag		 NVARCHAR(MAX) = ''u''		;

DECLARE @csp8 NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@cspAttrib, ''8'')),
		@csp2 NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@cspAttrib, ''2''));

--------------------------------------------------------------------
-- Variables
--------------------------------------------------------------------
-----------------------------------------------------
-- Variables temp table
-----------------------------------------------------
DECLARE @variables TABLE (
	CourseId		INT, 
	LecSortOrder	INT,
	LabSortOrder    INT,
	IndSortOrder	INT,
	WxpSortOrder	INT,
	IsLec			INT,
	IsLab			INT,
	IsInd			INT,
	IsAct			INT, 
	LecMin			DECIMAL(16,2), -- Lec Hrs (min)
	LecMax			DECIMAL(16,2), -- Lec Hrs (max)
	LcaMin			DECIMAL(16,2), -- Lec Activity Hrs (min)
	LcaMax			DECIMAL(16,2), -- Lec Activity Hrs (max)
	LabMin			DECIMAL(16,2), -- Lab Hrs (min)
	LabMax			DECIMAL(16,2), -- Lab Hrs (max)
	LbaMin			DECIMAL(16,2), -- Lab Activity Hrs (min)
	LbaMax			DECIMAL(16,2), -- Lab Activity Hrs (max)
	IndMin			DECIMAL(16,2), -- Ind Study Hrs (min)
	IndMax			DECIMAL(16,2), -- Ind Study Hrs (max)
	IdaMin			DECIMAL(16,2), -- Ind Study Activity Hrs (min)
	IdaMax			DECIMAL(16,2), -- Ind Study Activity Hrs (max)
	WxpMin			DECIMAL(16,2), -- Work Exp Hrs (min)
	WxpMax			DECIMAL(16,2), -- Work Exp Hrs (max)
	LecTx			NVARCHAR(MAX), 
	LabTx			NVARCHAR(MAX), 
	IndTx			NVARCHAR(MAX), 
	WxpTx			NVARCHAR(MAX)	
	);
INSERT INTO @variables
-- Lecture
SELECT 
	c.Id,
	co.SortOrder			AS LecSortOrder, 
	NULL, NULL, NULL,		-- Lab SortOrder, Ind SortOrder, Wxp SortOrder
	cp.IsRequired2			AS IsLec,		 
	NULL, NULL,				-- IsLab, IsInd
	cd.IsTBALab				AS IsAct,
	co.LabHours				AS LecMin, 
	co.MaxLabHours			AS LecMax,
	co.LectureHours			AS LcaMin, 
	co.MaxLectureHours		AS LcaMax,		 
	NULL, NULL, NULL, NULL, -- Lab Min/Max, Lba Min/Max
	NULL, NULL, NULL, NULL, -- Ind Min/Max, Ida Min/Max
	NULL, NULL,				-- Wxp Min/Max
	co.LectureOutlineText	AS LecTx, 
	NULL, NULL, NULL		-- LabTx, IndTx, WxpTx
FROM Course c
	INNER JOIN CourseProposal	 cp	ON cp.CourseId	= c.Id
	INNER JOIN CourseDescription cd	ON cd.CourseId	= c.Id
	INNER JOIN CourseOutline	 co	ON co.CourseId	= c.Id
WHERE c.Id = @entityId
UNION 
-- Lab
SELECT 
	c.Id,
	NULL,						-- Lec SortOrder
	cl.SortOrder				AS LabSortOrder, 
	NULL, NULL,					-- Ind SortOrder, Wxp SortOrder
	NULL,						-- IsLec
	c.LabSupportLecture			AS IsLab,		 
	NULL,						-- IsInd
	cd.IsTBALab					AS IsAct, 
	NULL, NULL, NULL, NULL,		-- Lec Min/Max, Lca Min/Max
	cl.ApproximatePercentage	AS LabMin, 
	cl.ApproximatePercentageMax AS LabMax,
	cl.ContentPercent			AS LbaMin, 
	cl.ContentPercentMax		AS LbaMax, 		 
	NULL, NULL, NULL, NULL,		-- Ind Min/Max, Ida Min/Max
	NULL, NULL,					-- Wxp Min/Max
	NULL,						-- LecTx
	cl.OutlineText				AS LabTx, 
	NULL, NULL					-- IndTx, WxpTx
FROM Course c
	INNER JOIN CourseLabContent	 cl	ON cl.CourseId	= c.Id	
	INNER JOIN CourseDescription cd	ON cd.CourseId	= c.Id
WHERE c.Id = @entityId
UNION
-- Independent Study
SELECT 
	c.Id,
	NULL, NULL,					-- Lec SortOrder, Lab SortOrder
	ci.SortOrder				AS IndSortOrder,
	NULL,						-- Wxp SortOrder
	NULL, NULL,					-- IsLec, IsLab
	cd.IsIndependentStudy		AS IsInd,
	cd.IsTBALab					AS IsAct,
	NULL, NULL, NULL, NULL,		-- Lec Min/Max, Lca Min/Max 
	NULL, NULL, NULL, NULL,		-- Lab Min/Max, Lba Min/Max
	ci.ApproximatePercentage	AS IndMin, 
	ci.Decimal01				AS IndMax,
	ci.ContentPercent			AS IdaMin, 
	ci.Decimal02				AS IdaMax,
	NULL, NULL,					-- Wxp Min/Max
	NULL, NULL,					-- LecTx, LabTx
	ci.ContentText				AS IndTx,
	NULL						-- WxpTx
FROM Course c
	INNER JOIN CourseInstructionContent	ci ON ci.CourseId = c.Id
	INNER JOIN CourseDescription		cd ON cd.CourseId = c.Id
WHERE c.Id = @entityId
UNION
-- Work Experience
SELECT 
	c.Id, 
	NULL, NULL, NULL,			-- Lec SortOrder, Lab SortOrder, Ind SortOrder
	c13.SortOrder				AS WxpSortOrder,
	NULL, NULL, NULL, NULL,		-- IsLec, IsLab, IsInd, IsAct
	NULL, NULL, NULL, NULL,		-- Lec Min/Max, Lca Min/Max 
	NULL, NULL, NULL, NULL,		-- Lab Min/Max, Lba Min/Max
	NULL, NULL, NULL, NULL,		-- Ind Min/Max, Ida Min/Max
	c13.Decimal01				AS WxpMin, 
	c13.Decimal02				AS WxpMax,
	NULL, NULL, NULL,			-- LecTx, LabTx, IndTx
	c13.MaxText01				AS WxpTx
FROM Course c
	INNER JOIN CourseLookup13 c13 ON c13.CourseId = c.Id
WHERE c.Id = @entityId

-----------------------------------------------------
/* Uncomment this line for testing only - use for verifying temp table data */
 --SELECT * FROM @variables 
-----------------------------------------------------

-----------------------------------------------------
-- Hour Types
-----------------------------------------------------
DECLARE @isLec INT = (SELECT MAX(IsLec) FROM @variables),
		@isLab INT = (SELECT MAX(IsLab) FROM @variables),
		@isInd INT = (SELECT MAX(IsInd) FROM @variables),
		@isAct INT = (SELECT MAX(IsAct) FROM @variables);

-----------------------------------------------------
-- Hour Totals
-----------------------------------------------------
-- Check existence of totals
DECLARE @chkLecMin NVARCHAR(MAX) = (SELECT CAST(SUM(LecMin) AS NVARCHAR(MAX)) FROM @variables), 
		@chkLecMax NVARCHAR(MAX) = (SELECT CAST(SUM(LecMax) AS NVARCHAR(MAX)) FROM @variables),
		@chkLcaMin NVARCHAR(MAX) = (SELECT CAST(SUM(LcaMin) AS NVARCHAR(MAX)) FROM @variables),
		@chkLcaMax NVARCHAR(MAX) = (SELECT CAST(SUM(LcaMax) AS NVARCHAR(MAX)) FROM @variables),
		@chkLabMin NVARCHAR(MAX) = (SELECT CAST(SUM(LabMin) AS NVARCHAR(MAX)) FROM @variables),
		@chkLabMax NVARCHAR(MAX) = (SELECT CAST(SUM(LabMax) AS NVARCHAR(MAX)) FROM @variables),
		@chkLbaMin NVARCHAR(MAX) = (SELECT CAST(SUM(LbaMin) AS NVARCHAR(MAX)) FROM @variables),
		@chkLbaMax NVARCHAR(MAX) = (SELECT CAST(SUM(LbaMax) AS NVARCHAR(MAX)) FROM @variables),
		@chkIndMin NVARCHAR(MAX) = (SELECT CAST(SUM(IndMin) AS NVARCHAR(MAX)) FROM @variables),
		@chkIndMax NVARCHAR(MAX) = (SELECT CAST(SUM(IndMax) AS NVARCHAR(MAX)) FROM @variables),
		@chkIdaMin NVARCHAR(MAX) = (SELECT CAST(SUM(IdaMin) AS NVARCHAR(MAX)) FROM @variables),
		@chkIdaMax NVARCHAR(MAX) = (SELECT CAST(SUM(IdaMax) AS NVARCHAR(MAX)) FROM @variables),
		@chkWxpMin NVARCHAR(MAX) = (SELECT CAST(SUM(WxpMin) AS NVARCHAR(MAX)) FROM @variables),
		@chkWxpMax NVARCHAR(MAX) = (SELECT CAST(SUM(WxpMax) AS NVARCHAR(MAX)) FROM @variables);

-- Calculate totals (for Lecture, Lab, and Independent Study, which may have ranges)
DECLARE @ttLecMin NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(LecMin, LecMax, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttLecMax NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(LecMax, LecMin, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttLcaMin NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(LcaMin, LcaMax, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttLcaMax NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(LcaMax, LcaMin, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttLabMin NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(LabMin, LabMax, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttLabMax NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(LabMax, LabMin, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttLbaMin NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(LbaMin, LbaMax, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttLbaMax NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(LbaMax, LbaMin, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttIndMin NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(IndMin, IndMax, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttIndMax NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(IndMax, IndMin, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttIdaMin NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(IdaMin, IdaMax, 0)) AS NVARCHAR(MAX)) FROM @variables),
		@ttIdaMax NVARCHAR(MAX) = (SELECT CAST(SUM(COALESCE(IdaMax, IdaMin, 0)) AS NVARCHAR(MAX)) FROM @variables);

-----------------------------------------------------
-- Hour Type Headings - Div above table
-----------------------------------------------------
-- Div class
DECLARE @ttHead  NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''head-tt''));
-- Opening and closing div tags
DECLARE @ttOpen  NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@divTag, @ttHead)),
		@ttClose NVARCHAR(MAX) = (SELECT dbo.fnHtmlCloseTag(@divTag));
-- Conditional additional display output for Lecture and Lab headings
DECLARE @lcHead  NVARCHAR(MAX) = (SELECT CASE WHEN @isAct = 1 AND @chkLcaMin IS NOT NULL THEN ''/Activity'' ELSE NULL END), 
		@lbHead  NVARCHAR(MAX) = (SELECT CASE WHEN @isAct = 1 AND @chkLbaMin IS NOT NULL THEN ''/Activity'' ELSE NULL END);
		
DECLARE @headingLec NVARCHAR(MAX) = (SELECT CONCAT(@ttOpen, ''Lecture'',	@lcHead, @ttClose));
DECLARE @headingLab NVARCHAR(MAX) = (SELECT CONCAT(@ttOpen, ''Lab'',		@lbHead, @ttClose));
DECLARE @headingInd NVARCHAR(MAX) = (SELECT CONCAT(@ttOpen, ''Independent Study'', @ttClose));
DECLARE @headingWxp NVARCHAR(MAX) = (SELECT CONCAT(@ttOpen, ''Work Experience'',	 @ttClose));

-----------------------------------------------------
-- Table
-----------------------------------------------------
-- Table class
DECLARE @ttTable NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''topic-table''));
-- Table ids
DECLARE @ttLec   NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@idAttrib, ''tt-lec'')),
		@ttLab   NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@idAttrib, ''tt-lab'')),
		@ttInd	 NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@idAttrib, ''tt-ind'')),
		@ttWxp   NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@idAttrib, ''tt-wxp''));

-- Opening table tags - with class and id
DECLARE @ttLecTable NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tableTag, CONCAT(@ttTable, @space, @ttLec))),
		@ttLabTable NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tableTag, CONCAT(@ttTable, @space, @ttLab))),
		@ttIndTable NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tableTag, CONCAT(@ttTable, @space, @ttInd))),
		@ttWxpTable NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tableTag, CONCAT(@ttTable, @space, @ttWxp)));
-- Closing table tag
DECLARE @tbClose NVARCHAR(MAX) = (SELECT dbo.fnHtmlCloseTag(@tableTag));

-----------------------------------------------------
-- Table groups and rows 
-----------------------------------------------------
-- Opening tags - thead, tfoot
DECLARE @thead NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@theadTag, NULL)),
		@tfoot NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tfootTag, NULL));
-- Closing tags - thead, tfoot
DECLARE @thdClose NVARCHAR(MAX) = (SELECT dbo.fnHtmlCloseTag(@theadTag)), 
		@tftClose NVARCHAR(MAX) = (SELECT dbo.fnHtmlCloseTag(@tfootTag));

-- Table row classes
DECLARE @trTop		NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''tr-top'')),		-- Thead tr
		@trMiddle	NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''tr-middle'')),	-- Tbody tr
		@trBottom	NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''tr-bottom''));	-- Tfoot tr
-- Table row th/td classes
DECLARE @thTopics NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''th-topics'')), 
		@thMin    NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''th-min-hrs'')), 
		@thMax	  NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''th-max-hrs''));
DECLARE @tdTopics NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''td-topics'')),
		@tdMin    NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''td-min-hrs'')), 
		@tdMax	  NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''td-max-hrs''));
DECLARE @tdLabel  NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''td-label'')),
		@tdMinVal NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''td-min-val'')),
		@tdMaxVal NVARCHAR(MAX) = (SELECT dbo.fnHtmlAttribute(@classAttrib, ''td-max-val''));

-- Opening tags - thead th - top (column headings)
DECLARE @th1  NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@thTag, @thTopics)), 
		@th2  NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@thTag, @thMin)), 
		@th3  NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@thTag, @thMax));
-- Opening tags - tbody td - middle (content)
DECLARE @td1 NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tdTag, @tdTopics)),
		@td2 NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tdTag, @tdMin)),
		@td3 NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tdTag, @tdMax));
-- Opening tags - tfoot td - bottom (totals)
DECLARE @tdt1 NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tdTag, @tdLabel)),
		@tdt2 NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tdTag, @tdMinVal)),
		@tdt3 NVARCHAR(MAX) = (SELECT dbo.fnHtmlOpenTag(@tdTag, @tdMaxVal));
-- Closing tags (th, td)
DECLARE @thClose  NVARCHAR(MAX) = (SELECT dbo.fnHtmlCloseTag(@thTag)), 
		@tdClose  NVARCHAR(MAX) = (SELECT dbo.fnHtmlCloseTag(@tdTag));

-----------------------------------------------------
-- Table - Thead (top) - column headings row
-----------------------------------------------------
/*	@th1 = heading for the Topics column 
	@th2 = heading for the Lec Hrs, Lab Hrs, Ind Hrs, or Min Hrs column 
	@th3 = heading for the Act Hrs or Max Hrs column 
*/

-- Lecture
DECLARE @topLec NVARCHAR(MAX) = (SELECT CONCAT(
	@thead, 
	dbo.fnHtmlOpenTag(@trTag, @trTop), 
		@th1, ''Topics'',  @thClose,
	CASE WHEN @isLec = 1 AND @chkLecMin IS NOT NULL THEN CONCAT(
		@th2, ''Lec Hrs'', @thClose
	) ELSE NULL END,
	CASE WHEN @isAct = 1 AND @chkLcaMin IS NOT NULL THEN CONCAT(
		@th3, ''Act Hrs'', @thClose
	) ELSE NULL END,
	dbo.fnHtmlCloseTag(@trTag), 
	@thdClose
	));
-- Lab
DECLARE @topLab NVARCHAR(MAX) = (SELECT CONCAT(
	@thead, 
	dbo.fnHtmlOpenTag(@trTag, @trTop),
		@th1, ''Topics'',  @thClose,
	CASE WHEN @isLab = 1 AND @chkLabMin IS NOT NULL THEN CONCAT(
		@th2, ''Lab Hrs'', @thClose
	) ELSE NULL END,
	CASE WHEN @isAct = 1 AND @chkLbaMin IS NOT NULL THEN CONCAT(
		@th3, ''Act Hrs'', @thClose
	) ELSE NULL END,
	dbo.fnHtmlCloseTag(@trTag), 
	@thdClose
	));
-- Independent Study
DECLARE @topInd NVARCHAR(MAX) = (SELECT CONCAT(
	@thead, 
	dbo.fnHtmlOpenTag(@trTag, @trTop),
		@th1, ''Topics'',  @thClose,
	CASE WHEN @isInd = 1 AND @chkIndMin IS NOT NULL THEN CONCAT(
		@th2, ''Ind Hrs'', @thClose
	) ELSE NULL END,
	CASE WHEN @isAct = 1 AND @chkIdaMin IS NOT NULL THEN CONCAT(
		@th3, ''Act Hrs'', @thClose
	) ELSE NULL END,
	dbo.fnHtmlCloseTag(@trTag), 
	@thdClose
	));
-- Work Experience
DECLARE @topWxp NVARCHAR(MAX) = (SELECT CONCAT(
	@thead, 
	dbo.fnHtmlOpenTag(@trTag, @trTop),
		@th1, ''Topics'', @thClose,
	CASE WHEN @chkWxpMin IS NOT NULL THEN CONCAT(
		@th2, ''Min Hrs'', @thClose
	) ELSE NULL END,
	CASE WHEN @chkWxpMax IS NOT NULL THEN CONCAT(
		@th3, ''Max Hrs'', @thClose
	) ELSE NULL END,
	dbo.fnHtmlCloseTag(@trTag), 
	@thdClose
	));

-----------------------------------------------------
-- Table - Tbody (middle) - content row(s)
-----------------------------------------------------
/*	Note: the tbody tag is automatically generated as a container 
	for any table content that is not otherwise explicitly contained 
	in the thead or tfoot, so no need to include it here. */

/*	@td1 = data in the first column  (Topics) 
	@td2 = data in the second column (Lec Hrs, Lab Hrs, Ind Hrs, or Min Hrs)
	@td3 = data in the third column  (Act Hrs or Max Hrs)
*/

-- Lecture
DECLARE @contentLec NVARCHAR(MAX) = (SELECT STRING_AGG(CONCAT(
	dbo.fnHtmlOpenTag(@trTag, @trMiddle), 
		@td1, COALESCE(LecTx, ''''), @tdClose,
	CASE WHEN @isLec = 1 AND @chkLecMin IS NOT NULL THEN CONCAT(
		@td2, 
			CAST(COALESCE(LecMin, 0) AS NVARCHAR(MAX)), 
			CASE WHEN LecMax IS NOT NULL THEN CONCAT('' - '', LecMax) ELSE NULL END, 
		@tdClose
	) ELSE NULL END,
	CASE WHEN @isAct = 1 AND @chkLcaMin IS NOT NULL THEN CONCAT(
		@td3, 
			CAST(COALESCE(LcaMin, 0) AS NVARCHAR(MAX)), 
			CASE WHEN LcaMax IS NOT NULL THEN CONCAT('' - '', LcaMax) ELSE NULL END, 
		@tdClose
	) ELSE NULL END,
	dbo.fnHtmlCloseTag(@trTag)
	), '''') WITHIN GROUP (ORDER BY LecSortOrder) 
	FROM @variables WHERE LecSortOrder IS NOT NULL
	);
-- Lab
DECLARE @contentLab NVARCHAR(MAX) = (SELECT STRING_AGG(CONCAT(
	dbo.fnHtmlOpenTag(@trTag, @trMiddle), 
		@td1, COALESCE(LabTx, ''''), @tdClose,
	CASE WHEN @ttLabMin IS NOT NULL AND @isLab = 1 THEN CONCAT(
		@td2, 
			CAST(COALESCE(LabMin, 0) AS NVARCHAR(MAX)), 
			CASE WHEN LabMax IS NOT NULL THEN CONCAT('' - '', LabMax) ELSE NULL END, 
		@tdClose
	) ELSE NULL END,
CASE 
    WHEN @ttLbaMin IS NOT NULL AND @isAct = 1 THEN 
        CONCAT(
            @td3, 
            CASE 
                WHEN LbaMin IS NULL OR LbaMin = 0 
                    THEN '''' 
                    ELSE CAST(LbaMin AS NVARCHAR(MAX)) 
            END,
            CASE 
                WHEN LbaMax IS NOT NULL 
                    THEN CONCAT('' - '', LbaMax) 
                    ELSE '''' 
            END,
            @tdClose
        ) 
    ELSE NULL 
END,
	dbo.fnHtmlCloseTag(@trTag)
	), '''') WITHIN GROUP (ORDER BY LabSortOrder) 
	FROM @variables WHERE LabSortOrder IS NOT NULL
	);
-- Independent Study
DECLARE @contentInd NVARCHAR(MAX) = (SELECT STRING_AGG(CONCAT(
	dbo.fnHtmlOpenTag(@trTag, @trMiddle), 
		@td1, COALESCE(IndTx, ''''), @tdClose,
	CASE WHEN @ttIndMin IS NOT NULL AND @isInd = 1 THEN CONCAT(
		@td2, 
			CAST(COALESCE(IndMin, 0) AS NVARCHAR(MAX)), 
			CASE WHEN IndMax IS NOT NULL THEN CONCAT('' - '', IndMax) ELSE NULL END, 
		@tdClose
	) ELSE NULL END,
	CASE WHEN @ttIdaMin IS NOT NULL AND @isAct = 1 THEN CONCAT(
		@td3, 
			CAST(COALESCE(IdaMin, 0) AS NVARCHAR(MAX)), 
			CASE WHEN IdaMax IS NOT NULL THEN CONCAT('' - '', IdaMax) ELSE NULL END, 
		@tdClose
	) ELSE NULL END,
	dbo.fnHtmlCloseTag(@trTag)
	), '''') WITHIN GROUP (ORDER BY IndSortOrder) 
	FROM @variables WHERE IndSortOrder IS NOT NULL
	);
-- Work Experience
DECLARE @contentWxp NVARCHAR(MAX) = (SELECT STRING_AGG(CONCAT(
	dbo.fnHtmlOpenTag(@trTag, @trMiddle),  
		@td1, COALESCE(WxpTx, ''''), @tdClose,
	CASE WHEN @chkWxpMin IS NOT NULL THEN CONCAT(
		@td2, CAST(COALESCE(WxpMin, 0) AS NVARCHAR(MAX)), @tdClose
	) ELSE NULL END,
	CASE WHEN @chkWxpMax IS NOT NULL THEN CONCAT(
		@td3, CAST(COALESCE(WxpMax, 0) AS NVARCHAR(MAX)), @tdClose
	) ELSE NULL END, 
	dbo.fnHtmlCloseTag(@trTag)
	), '''') WITHIN GROUP (ORDER BY WxpSortOrder) 
	FROM @variables WHERE WxpSortOrder IS NOT NULL
	);

-----------------------------------------------------
-- Table - Tfoot (bottom) - total hours row
-----------------------------------------------------
/*	@tdt1 = Total Hours label (right-aligned) in the first column
	@tdt2 = data total in the second column (Lec Hrs, Lab Hrs, Ind Hrs, or Min Hrs)
	@tdt3 = data total in the third column  (Act Hrs or Max Hrs)
*/ 

-- Lecture
DECLARE @totalLec NVARCHAR(MAX) = (SELECT CONCAT(
	@tfoot, 
	dbo.fnHtmlOpenTag(@trTag, @trBottom),
		@tdt1, ''Total Hours:'', @tdClose,
	CASE WHEN @isLec = 1 AND @chkLecMin IS NOT NULL THEN CONCAT(
		@tdt2, 
			CASE WHEN @chkLecMax IS NOT NULL 
			THEN CONCAT(@ttLecMin, '' - '', @ttLecMax) ELSE @ttLecMin END, 
		@tdClose
	) ELSE NULL END,
	CASE WHEN @isAct = 1 AND @chkLcaMin IS NOT NULL THEN CONCAT(
		@tdt3, 
			CASE WHEN @chkLcaMax IS NOT NULL 
			THEN CONCAT(@ttLcaMin, '' - '', @ttLcaMax) ELSE @ttLcaMin END, 
		@tdClose
	) ELSE NULL END,
	dbo.fnHtmlCloseTag(@trTag), 
	@tftClose
	));
-- Lab
DECLARE @totalLab NVARCHAR(MAX) = (SELECT CONCAT(
	@tfoot, 
	dbo.fnHtmlOpenTag(@trTag, @trBottom),
		@tdt1, ''Total Hours:'', @tdClose,
	CASE WHEN @isLab = 1 AND @chkLabMin IS NOT NULL THEN CONCAT(
		@tdt2, 
			CASE WHEN @chkLabMax IS NOT NULL
			THEN CONCAT(@ttLabMin, '' - '', @ttLabMax) ELSE @ttLabMin END, 
		@tdClose
	) ELSE NULL END,
	CASE WHEN @isAct = 1 AND @chkLbaMin IS NOT NULL THEN CONCAT(
		@tdt3, 
			CASE WHEN @chkLbaMax IS NOT NULL 
			THEN CONCAT(@ttLbaMin, '' - '', @ttLbaMax) ELSE @ttLbaMin END, 
		@tdClose
	) ELSE NULL END,
	dbo.fnHtmlCloseTag(@trTag),
	@tftClose
	));
-- Independent Study
DECLARE @totalInd NVARCHAR(MAX) = (SELECT CONCAT(
	@tfoot, 
	dbo.fnHtmlOpenTag(@trTag, @trBottom),
		@tdt1, ''Total Hours:'', @tdClose,
	CASE WHEN @isInd = 1 AND @chkIndMin IS NOT NULL THEN CONCAT(
		@tdt2, 
			CASE WHEN @chkIndMax IS NOT NULL 
			THEN CONCAT(@ttIndMin, '' - '', @ttIndMax) ELSE @ttIndMin END, 
		@tdClose
	) ELSE NULL END,
	CASE WHEN @isAct = 1 AND @chkIdaMin IS NOT NULL THEN CONCAT(
		@tdt3, 
			CASE WHEN @chkIdaMax IS NOT NULL 
			THEN CONCAT(@ttIdaMin, '' - '', @ttIdaMax) ELSE @ttIdaMin END, 
		@tdClose
	) ELSE NULL END,
	dbo.fnHtmlCloseTag(@trTag), 
	@tftClose
	));
-- Work Experience
DECLARE @totalWxp NVARCHAR(MAX) = (SELECT CONCAT(
	@tfoot, 
	dbo.fnHtmlOpenTag(@trTag, @trBottom),
		@tdt1, ''Total Hours:'', @tdClose,
	CASE WHEN @chkWxpMin IS NOT NULL THEN CONCAT(
		@tdt2, @chkWxpMin, @tdClose
	) ELSE NULL END,
	CASE WHEN @chkWxpMax IS NOT NULL THEN CONCAT(
		@tdt3, @chkWxpMax, @tdClose
	) ELSE NULL END,
	dbo.fnHtmlCloseTag(@trTag), 
	@tftClose
	));

--------------------------------------------------------------------
-- Output
--------------------------------------------------------------------
-- Complete table content (thead, tbody, tfoot)
DECLARE @lecTableCt NVARCHAR(MAX) = (SELECT CONCAT(@topLec, @contentLec, @totalLec)),
		@labTableCt NVARCHAR(MAX) = (SELECT CONCAT(@topLab, @contentLab, @totalLab)),
		@indTableCt NVARCHAR(MAX) = (SELECT CONCAT(@topInd, @contentInd, @totalInd)),
		@wxpTableCt NVARCHAR(MAX) = (SELECT CONCAT(@topWxp, @contentWxp, @totalWxp));
-- Complete table output (heading, opening table tag, table content, closing table tag)
DECLARE @lecTable	NVARCHAR(MAX) = (SELECT CONCAT(@headingLec, @ttLecTable, @lecTableCt, @tbClose)),
		@labTable	NVARCHAR(MAX) = (SELECT CONCAT(@headingLab, @ttLabTable, @labTableCt, @tbClose)),
		@indTable	NVARCHAR(MAX) = (SELECT CONCAT(@headingInd, @ttIndTable, @indTableCt, @tbClose)),
		@wxpTable	NVARCHAR(MAX) = (SELECT CONCAT(@headingWxp, @ttWxpTable, @wxpTableCt, @tbClose));

SELECT 0 AS [Value], CONCAT(
	CASE WHEN (@isLec = 1 AND @chkLecMin IS NOT NULL) OR (@isAct = 1 AND @chkLcaMin IS NOT NULL)		 THEN @lecTable ELSE NULL END, 
	CASE WHEN (@isLab = 1 AND @chkLabMin IS NOT NULL) OR (@isAct = 1 AND @chkLbaMin IS NOT NULL)		 THEN @labTable ELSE NULL END, 
	CASE WHEN (@isInd = 1 AND @chkIndMin IS NOT NULL) OR (@isAct = 1 AND @chkIdaMin IS NOT NULL)		 THEN @indTable ELSE NULL END, 
	CASE WHEN (@chkWxpMin IS NOT NULL OR @chkWxpMax IS NOT NULL) 
		 THEN @wxpTable ELSE NULL END
	) AS [Text]
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