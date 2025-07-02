USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19092';
DECLARE @Comments nvarchar(Max) = 
	'Remove text on the curriculum presentation';
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
--#region hide

DECLARE @hoursScale0 INT = 0, 
		@hoursScale1 INT = 1, 
		@hoursScale2 INT = 2, 
		@hoursScale3 INT = 3;

DECLARE @hoursDecimalFormat0 NVARCHAR(10) = CONCAT(''F'', @hoursScale0), 
		@hoursDecimalFormat1 NVARCHAR(10) = CONCAT(''F'', @hoursScale1),	
		@hoursDecimalFormat2 NVARCHAR(10) = CONCAT(''F'', @hoursScale2), 
		@hoursDecimalFormat3 NVARCHAR(10) = ''###.###'', 
		@empty				 NVARCHAR(1)  = '''', 
		@space				 NVARCHAR(5)  = '' '', 
		@newLine			 NVARCHAR(5)  = ''<br>'', 
		@classAttrib		 NVARCHAR(10) = ''class'', 
		@titleAttrib		 NVARCHAR(10) = ''title'', 
		@openComment		 NVARCHAR(10) = ''<!-- '', 
		@closeComment		 NVARCHAR(10) = '' -->'', 
		@styleAttribute		 NVARCHAR(5)  = ''style'';

DECLARE @elementTags TABLE (
	Id			 INT,
	ElementTitle NVARCHAR(255) UNIQUE NONCLUSTERED,
	ElementTag	 NVARCHAR(10)
	);

INSERT INTO @elementTags (Id, ElementTitle, ElementTag)
VALUES
	(1, ''SummaryWrapper'',	''div'' ),
	(2, ''Row'',				''div'' ),
	(3, ''Column'',			''div'' ),
	(4, ''DataElement'',		''span''),
	(5, ''Block'',			''div'' ),
	(6, ''Label'',			''b''   ),
	(7, ''Spacer'',			''br''  ),
	(8, ''BoldDataElement'',	''b''	  ),
	(9, ''SecondaryLabel'',	''u''	  ),
	(10, ''ItalicElement'',	''i''   );

DECLARE @summaryWrapperTag		NVARCHAR(10) = (SELECT ElementTag FROM @elementTags WHERE ElementTitle = ''SummaryWrapper''),  -- Group wrappers
		@rowTag					NVARCHAR(10) = (SELECT ElementTag FROM @elementTags WHERE ElementTitle = ''Row''),			 -- Row wrappers
		@columnTag				NVARCHAR(10) = (SELECT ElementTag FROM @elementTags WHERE ElementTitle = ''Column''),			 -- Column wrappers
		@dataElementTag			NVARCHAR(10) = (SELECT ElementTag FROM @elementTags WHERE ElementTitle = ''DataElement''),	 -- Elements in columns
		@blockTag				NVARCHAR(10) = (SELECT ElementTag FROM @elementTags WHERE ElementTitle = ''Block''),			 -- Generic layout blocks
		@labelTag				NVARCHAR(10) = (SELECT ElementTag FROM @elementTags WHERE ElementTitle = ''Label''),			 -- Labels
		@spacerTag				NVARCHAR(10) = (SELECT ElementTag FROM @elementTags WHERE ElementTitle = ''Spacer''),			 -- Line break insert
		@boldDataElementTag		NVARCHAR(10) = (SELECT ElementTag FROM @elementTags WHERE ElementTitle = ''BoldDataElement''), -- Bold elements
		@secondaryLabelTag		NVARCHAR(10) = (SELECT ElementTag FROM @elementTags WHERE ElementTitle = ''SecondaryLabel''),  -- Alternate labels
		@italicDataElementTag	NVARCHAR(10) = (SELECT ElementTag FROM @elementTags WHERE ElementTitle = ''ItalicElement'');	 -- Italic elements

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

DECLARE @transferType1 NVARCHAR(MAX) = ''Acceptable to CSU, UC or Private'';
DECLARE @transferType2 NVARCHAR(MAX) = ''Acceptable to CSU or Private College'';

--#endregion

DECLARE @modelRoot TABLE (
	CourseId INT PRIMARY KEY,
	InsertOrder INT,
	RootData NVARCHAR(MAX)
	);

DECLARE @modelRootData TABLE (
	Transfer			NVARCHAR(MAX),
	PeraltaArea			NVARCHAR(MAX),
	CSUArea				NVARCHAR(MAX),
	IGETCArea			NVARCHAR(MAX),
	TopCode				NVARCHAR(MAX),
	Department			NVARCHAR(MAX),
	CourseId			INT PRIMARY KEY,
	SubjectCode			NVARCHAR(MAX),
	CourseNumber		NVARCHAR(MAX),
	CourseTitle			NVARCHAR(MAX),
	Variable			BIT,
	MinUnit				DECIMAL(16, 3),
	MaxUnit				DECIMAL(16, 3),
	MinLec				DECIMAL(16, 3),
	MaxLec				DECIMAL(16, 3),
	MinLab				DECIMAL(16, 3),
	MaxLab				DECIMAL(16, 3),
	MinLearn			DECIMAL(16,3),
	MaxLearn			DECIMAL(16,3), 
	TransferType		NVARCHAR(MAX),
	Requisite			NVARCHAR(MAX),
	Limitation			NVARCHAR(MAX),
	Preparation			NVARCHAR(MAX),
	CatalogDescription	NVARCHAR(MAX),
	CourseGrading		NVARCHAR(MAX),
	IsRepeatable		NVARCHAR(10),
	RepeatableCode		NVARCHAR(500),
	TimesRepeated		NVARCHAR(500),
	Suffix				NVARCHAR(500),
	CID					NVARCHAR(500),
	CIDStatus			NVARCHAR(255),
	CIDNotes			NVARCHAR(MAX),
	AdminRepeat			NVARCHAR(MAX),
	CreditByExam		BIT
	);

DECLARE @unitHourRanges TABLE (
	Id				INT NOT NULL IDENTITY PRIMARY KEY,
	CourseId		INT,
	UnitHourTypeId	INT,
	RenderedRange	NVARCHAR(100)
	);

-- testing
	-- DECLARE @entityModels table ([Key] NVARCHAR(MAX), [Value] NVARCHAR(MAX))

	-- INSERT INTO @entityModels
	-- VALUES (''18369'', ''[{"InsertOrder":1,"RootData":{"Transfer":"CSU, UC","PeraltaArea":"2","CSUArea":"D","IGETCArea":"4","TopCode":"2105.00","CourseId":18369,"SubjectCode":"ADJUS","CourseNumber":"021","CourseTitle":"Introduction to Administration of Justice","Variable":false,"MinUnit":3.000,"MinLec":3.000,"Requisite":"","CatalogDescription":"History and philosophy of administration of justice in America: Identification of various subsystems emphasizing US courts, corrections, and law enforcement, role expectations and their interrelationships; theories of crime, punishment, and rehabilitation; ethics; and education and training for professionalism.","CourseGrading":"GR","IsRepeatable":"Yes","CID":"AJ 110","CIDStatus":"Approved","CreditByExam":true}}]'');
-- end testing

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
	[Transfer], 
	PeraltaArea, 
	CSUArea, 
	IGETCArea, 
	TopCode, 
	Department, 
	CourseId, 
	SubjectCode, 
	CourseNumber,
	CourseTitle, 
	Variable,
	MinUnit,
	MaxUnit,
	MinLec,
	MaxLec,
	MinLab,
	MaxLab,
	MinLearn,
	MaxLearn,
	TransferType,
	Requisite, 
	Limitation, 
	Preparation,
	CatalogDescription,
	CourseGrading,
	IsRepeatable,
	RepeatableCode,
	TimesRepeated,
	Suffix,
	CID,
	CIDStatus,
	CIDNotes,
	AdminRepeat,
	CreditByExam
	)
SELECT 
	m.[Transfer], 
	m.PeraltaArea, 
	m.CSUArea, 
	m.IGETCArea, 
	m.TopCode, 
	m.Department, 
	m.CourseId, 
	CASE WHEN m.SubjectCode  IS NOT NULL AND LEN(m.SubjectCode)  > 0 THEN m.SubjectCode  ELSE @empty END AS SubjectCode, 
	CASE WHEN m.CourseNumber IS NOT NULL AND LEN(m.CourseNumber) > 0 THEN m.CourseNumber ELSE @empty END AS CourseNumber, 
	CASE WHEN m.CourseTitle  IS NOT NULL AND LEN(m.CourseTitle)  > 0 THEN m.CourseTitle  ELSE @empty END AS CourseTitle, 
	m.Variable, 
	m.MinUnit, 
	m.MaxUnit, 
	m.MinLec, 
	m.MaxLec, 
	m.MinLab, 
	m.MaxLab,
	m.MinLearn, 
	m.MaxLearn, 
	CASE WHEN m.TransferType		IS NOT NULL AND LEN(m.TransferType)			> 0 THEN m.TransferType			ELSE @empty END AS TransferType, 
	CASE WHEN m.Requisite			IS NOT NULL AND LEN(m.Requisite)			> 0 THEN m.Requisite			ELSE @empty END AS Requisite, 
	CASE WHEN m.Limitation			IS NOT NULL AND LEN(m.Limitation)			> 0 THEN m.Limitation			ELSE @empty END AS Limitation, 
	CASE WHEN m.Preparation			IS NOT NULL AND LEN(m.Preparation)			> 0 THEN m.Preparation			ELSE @empty END AS Preparation, 
	CASE WHEN m.CatalogDescription	IS NOT NULL AND LEN(m.CatalogDescription)	> 0 THEN m.CatalogDescription	ELSE @empty END AS CatalogDescription, 
	CASE WHEN m.CourseGrading		IS NOT NULL AND LEN(m.CourseGrading)		> 0 THEN m.CourseGrading		ELSE @empty END AS CourseGrading, 
	CASE WHEN m.IsRepeatable		IS NOT NULL AND LEN(m.IsRepeatable)			> 0 THEN m.IsRepeatable			ELSE @empty END AS IsRepeatable, 
	CASE WHEN m.RepeatableCode		IS NOT NULL AND LEN(m.RepeatableCode)		> 0 THEN m.RepeatableCode		ELSE @empty END AS RepeatableCode,
	CASE WHEN m.TimesRepeated		IS NOT NULL AND LEN(m.TimesRepeated)		> 0 THEN m.TimesRepeated		ELSE @empty END AS TimesRepeated,
	CASE WHEN m.Suffix				IS NOT NULL AND LEN(m.Suffix)				> 0 THEN m.Suffix				ELSE @empty END, 
	CASE WHEN m.CID					IS NOT NULL AND LEN(m.CID)					> 0 THEN m.CID					ELSE @empty END, 
	CASE WHEN m.CIDStatus			IS NOT NULL AND LEN(m.CIDStatus)			> 0 THEN m.CIDStatus			ELSE @empty END, 
	CASE WHEN m.CIDNotes			IS NOT NULL AND LEN(m.CIDNotes)				> 0 THEN m.CIDNotes				ELSE @empty END, 
	CASE WHEN m.AdminRepeat			IS NOT NULL AND LEN(m.AdminRepeat)			> 0 THEN m.AdminRepeat			ELSE @empty END, 
	CreditByExam
FROM @modelRoot mr
	CROSS APPLY OPENJSON(mr.RootData)
		WITH (
			Transfer			NVARCHAR(MAX)	''$.Transfer'',
			PeraltaArea			NVARCHAR(MAX)	''$.PeraltaArea'',
			CSUArea				NVARCHAR(MAX)	''$.CSUArea'',
			IGETCArea			NVARCHAR(MAX)	''$.IGETCArea'',
			TopCode				NVARCHAR(MAX)	''$.TopCode'',
			Department			NVARCHAR(MAX)	''$.Department'',
			CourseId			INT				''$.CourseId'',
			SubjectCode			NVARCHAR(MAX)	''$.SubjectCode'',
			CourseNumber		NVARCHAR(MAX)	''$.CourseNumber'',
			CourseTitle			NVARCHAR(MAX)	''$.CourseTitle'',
			Variable			BIT				''$.Variable'',
			MinUnit				DECIMAL(16, 3)	''$.MinUnit'',
			MaxUnit				DECIMAL(16, 3)	''$.MaxUnit'',
			MinLec				DECIMAL(16, 3)	''$.MinLec'',
			MaxLec				DECIMAL(16, 3)	''$.MaxLec'',
			MinLab				DECIMAL(16, 3)	''$.MinLab'',
			MaxLab				DECIMAL(16, 3)	''$.MaxLab'',
			MinLearn			DECIMAL(16,3)	''$.MinLearn'',
			MaxLearn			DECIMAL(16,3)	''$.MaxLearn'',
			TransferType		NVARCHAR(MAX)	''$.TransferType'',
			Requisite			NVARCHAR(MAX)	''$.Requisite'',
			Limitation			NVARCHAR(MAX)	''$.Limitation'',
			Preparation			NVARCHAR(MAX)	''$.Preparation'',
			CatalogDescription	NVARCHAR(MAX)	''$.CatalogDescription'',
			CourseGrading		NVARCHAR(MAX)	''$.CourseGrading'',
			IsRepeatable		NVARCHAR(10)	''$.IsRepeatable'',
			RepeatableCode		NVARCHAR(10)	''$.RepeatableCode'',
			TimesRepeated		NVARCHAR(10)	''$.TimesRepeated'',
			Suffix				NVARCHAR(500)	''$.Suffix'',
			CID					NVARCHAR(500)	''$.CID'',
			CIDStatus			NVARCHAR(500)	''$.CIDStatus'',
			CIDNotes			NVARCHAR(500)	''$.CIDNotes'',
			AdminRepeat			NVARCHAR(500)	''$.AdminRepeat'',
			CreditByExam		BIT				''$.CreditByExam''
		) m
		;

INSERT INTO @unitHourRanges (CourseId, UnitHourTypeId, RenderedRange)
SELECT mrd.CourseId, uht.UnitHourTypeId, uhr.RenderedRange
FROM @modelRootData mrd
	CROSS APPLY ( 
		SELECT 1 AS UnitHourTypeId, -- Units
			mrd.MinUnit	AS MinVal, 
			CASE WHEN ISNULL(mrd.MaxUnit,0) = 0 THEN mrd.MinUnit ELSE mrd.MaxUnit END			
						AS MaxVal, 
			1	AS RenderIfZero, 
			0	AS ForceRange, 
			mrd.Variable, 
			3	AS FormatType, 
			1	AS Render
		UNION ALL
		SELECT 2 AS UnitHourTypeId, -- Lec
			mrd.MinLec	AS MinVal, 
			CASE WHEN ISNULL(mrd.MaxLec,0) = 0 THEN mrd.MinLec ELSE mrd.MaxLec END			
						AS MaxVal,
			0	AS RenderIfZero, 
			0	AS ForceRange, 
			mrd.Variable, 
			3	AS FormatType, 
			1	AS Render
		UNION ALL
		SELECT 3 AS UnitHourTypeId, -- Lab
			mrd.MinLab	AS MinVal, 
			CASE WHEN ISNULL(mrd.MaxLab,0) = 0 THEN mrd.MinLab ELSE mrd.MaxLab END 
						AS MaxVal, 
			0	AS RenderIfZero, 
			0	AS ForceRange, 
			mrd.Variable, 
			3	AS FormatType, 
			1	AS Render
		UNION ALL
		SELECT 4 AS UnitHourTypeId, -- Learn
			mrd.MinLearn AS MinVal, 
			CASE WHEN ISNULL(mrd.MaxLearn,0) = 0 THEN mrd.MinLearn ELSE mrd.MaxLearn END
						 AS MaxVal,
			0	AS RenderIfZero, 
			0	AS ForceRange, 
			mrd.Variable,
			3	AS FormatType, 
			1	AS Render

	) uht
	CROSS APPLY (
		SELECT CASE 
			WHEN uht.Render = 1 
			AND (
				(uht.Variable = 1 AND uht.MinVal IS NOT NULL AND uht.MaxVal IS NOT NULL AND uht.MinVal != uht.MaxVal)
				OR 
				(uht.ForceRange = 1)
				) 
			THEN CONCAT
				(
				CASE WHEN uht.MinVal <> 0 THEN FORMAT(
						uht.MinVal,
						CASE WHEN uht.FormatType = 0 THEN @hoursDecimalFormat0
							 WHEN uht.FormatType = 1 THEN @hoursDecimalFormat1
						     WHEN uht.FormatType = 3 THEN @hoursDecimalFormat3
						ELSE @hoursDecimalFormat2 END
						) 
				ELSE ''0'' END,
				'' - '',
				FORMAT(
					uht.MaxVal,
					CASE WHEN uht.FormatType = 0 THEN @hoursDecimalFormat0
						 WHEN uht.FormatType = 1 THEN @hoursDecimalFormat1
						 WHEN uht.FormatType = 3 THEN @hoursDecimalFormat3
					ELSE @hoursDecimalFormat2 END
					)
				) 
			WHEN (uht.Render = 1 AND uht.MaxVal IS NOT NULL AND (uht.MaxVal > 0 OR uht.RenderIfZero = 1)) 
			THEN 
				CASE WHEN uht.MaxVal <> 0 THEN FORMAT(
					uht.MaxVal,
					CASE WHEN uht.FormatType = 0 THEN @hoursDecimalFormat0
						 WHEN uht.FormatType = 1 THEN @hoursDecimalFormat1
						 WHEN uht.FormatType = 3 THEN @hoursDecimalFormat3
					ELSE @hoursDecimalFormat2 END
					)
				ELSE ''0'' END
			ELSE NULL END AS RenderedRange
	) uhr
	;

SELECT mr.CourseId AS [Value], CONCAT
	( 
	--------------------------------------------
	-- Custom course summary context wrapper
	--------------------------------------------
	''<div style="font-family: Calibri; font-size: 12px; padding-left: 10px; padding-right: 10px; margin-top: 10px;">'',
	dbo.fnHtmlOpenTag(@summaryWrapperTag, dbo.fnHtmlAttribute(@classAttrib, ''custom-course-summary-context-wrapper'')),
	--------------------------------------------
	-- Another nested wrapper
	--------------------------------------------
	dbo.fnHtmlOpenTag(@summaryWrapperTag, CONCAT(
		dbo.fnHtmlAttribute(@classAttrib, ''container-fluid course-summary-wrapper''), @space,
		dbo.fnHtmlAttribute(''data-course-id'', mrd.CourseId))),
	/* 
	-- Department row (Department)
	dbo.fnHtmlOpenTag(@rowTag,    dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-department-header''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-department'')),
		UPPER(mrd.Department),
	dbo.fnHtmlCloseTag(@boldDataElementTag),
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	*/
	--------------------------------------------
	-- Course Title row (Course subject code, number, and title)
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag,    dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-title-header''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	/* Course Subject */
	dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-subject'')),
		UPPER(mrd.SubjectCode),@space,
	dbo.fnHtmlCloseTag(@boldDataElementTag),
	/* Course Number */
	dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-number'')),
		UPPER(SUBSTRING(mrd.CourseNumber, PATINDEX(''%[^0]%'', mrd.CourseNumber + ''.''), LEN(mrd.CourseNumber))), 
		CASE WHEN mrd.Suffix IS NOT NULL AND LEN(mrd.Suffix) > 0 THEN CONCAT(mrd.Suffix,@space) 
		ELSE @space END, ''</br>'',
	dbo.fnHtmlCloseTag(@boldDataElementTag),
	/* Course Title */
	dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-title'')),
		mrd.CourseTitle,
	dbo.fnHtmlCloseTag(@boldDataElementTag),
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- Units and Hours
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag,    dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-units-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	/* Units */
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-unit-range'')),
		ISNULL(unithr.RenderedRange, @empty), @space,
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-unit-label'')),
		CASE WHEN LEN(unithr.RenderedRange) > 0 THEN CONCAT(
				CASE WHEN unithr.RenderedRange <> ''1'' THEN  '' Units'' ELSE ''Unit'' END,  
				CASE WHEN LEN(lechr.RenderedRange) > 0 
				OR LEN(labhr.RenderedRange) > 0 OR LEN(lrnhr.RenderedRange) > 0
				THEN '', '' ELSE @empty END 
				)
		ELSE @empty END,
	dbo.fnHtmlCloseTag(@dataElementTag),
	/* Lecture Hours */
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-range'')),
		ISNULL(lechr.RenderedRange, @empty), @space,
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lecture-label'')),
		CASE WHEN LEN(lechr.RenderedRange) > 0 THEN 
			CASE WHEN lechr.RenderedRange <> ''1'' THEN  '' hours lecture'' ELSE ''hour lecture'' END
		ELSE @empty END,
		CASE WHEN LEN(lechr.RenderedRange) IS NOT NULL AND LEN(labhr.RenderedRange) IS NOT NULL THEN '', ''
		ELSE '''' END,
	dbo.fnHtmlCloseTag(@dataElementTag),
	/* Lab Hours */
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lab-range'')),
		ISNULL(labhr.RenderedRange, @empty), @space,
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lab-label'')),
		CASE WHEN LEN(labhr.RenderedRange) > 0 THEN 
			CASE WHEN labhr.RenderedRange <> ''1'' THEN  '' hours lab'' ELSE ''hour lab'' END
			ELSE @empty END,
		CASE WHEN LEN(lrnhr.RenderedRange) IS NOT NULL THEN '','' END,
		@space,
	dbo.fnHtmlCloseTag(@dataElementTag),
	/* Learning Hours */ --Removing from MS-19092
	--dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-learn-range'')),
	--	ISNULL(lrnhr.RenderedRange, @empty), @space,
	--dbo.fnHtmlCloseTag(@dataElementTag),
	--dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-learn-label'')),
	--	CASE WHEN LEN(lrnhr.RenderedRange) > 0 THEN 
	--		CASE WHEN lrnhr.RenderedRange <> ''1'' THEN  '' hours Learning Center'' ELSE ''hour Learning Center'' END
	--	ELSE @empty END, 
	--	@space,
	--dbo.fnHtmlCloseTag(@dataElementTag),
	/* Grading Policy */
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-grading-label'')),
		''('', 
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-grading-value'')),
		CASE WHEN mrd.CourseGrading = ''GC''	    THEN ''GR or P/NP''
			 WHEN mrd.CourseGrading = ''P/NP/SP'' THEN ''SP or P/NP''
		ELSE ISNULL(mrd.CourseGrading, @empty) END, 
		'')'',
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-credit-by-exam'')),
		CASE WHEN mrd.CreditByExam = 1 THEN ''<br />Eligible for credit by examination'' ELSE '''' END,
	dbo.fnHtmlCloseTag(@boldDataElementTag),
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- Requisites
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag,    dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-requisite-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-requisite-value'')),
		ISNULL(mrd.Requisite, @empty),
		@space,
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- Acceptable for Credit: ((UC, CSU))
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag,    dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-transfer-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-transfer-value'')),
		CASE WHEN ISNULL(mrd.Transfer,'''') <> '''' THEN ''Acceptable for Credit '' ELSE @empty END,
		ISNULL(mrd.Transfer, @empty),
		@space,
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	-- Course Description
	dbo.fnHtmlOpenTag(@rowTag,    dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-description-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-description-value'')),
		CASE WHEN mrd.CatalogDescription IS NOT NULL AND LEN(mrd.CatalogDescription) > 0
			 THEN mrd.CatalogDescription
		 ELSE @empty END,
		 @space,
	dbo.fnHtmlCloseTag(@dataElementTag),
	--------------------------------------------
	-- TOP Code
	--------------------------------------------
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-topcode-value'')),
		@space, 
		UPPER(mrd.TopCode),
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- Peralta GE Areas fulfilled
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag,    dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-ge-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
		CASE WHEN mrd.PeraltaArea IS NOT NULL and mrd.PeraltaArea <> '''' THEN CONCAT
			(	
			dbo.fnHtmlOpenTag(@dataElementTag, 
				dbo.fnHtmlAttribute(@classAttrib, ''course-ge-value'')),
			CASE WHEN ISNULL(mrd.PeraltaArea,'''') <> '''' THEN ''Peralta GE Areas '' ELSE @empty END,
			ISNULL(mrd.PeraltaArea + ''; '',@empty),
			@space,
			dbo.fnHtmlCloseTag(@dataElementTag)
			)
		END,
	--------------------------------------------
	-- CSU Area fulfilled
	--------------------------------------------
		CASE WHEN mrd.CSUArea IS NOT NULL and mrd.CSUArea <> '''' THEN CONCAT
			(	
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-csu-value'')),
			CASE WHEN ISNULL(mrd.CSUArea ,'''') <> '''' THEN ''CSU area '' ELSE @empty END,
			ISNULL(mrd.CSUArea + ''; '' ,@empty),
			@space,
			dbo.fnHtmlCloseTag(@dataElementTag)
			)
		END,
	--------------------------------------------
	-- IGETC area fulfilled
	--------------------------------------------
		CASE WHEN mrd.IGETCArea IS NOT NULL and mrd.IGETCArea <> '''' THEN CONCAT
			(
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-igetc-value'')),
			CASE WHEN ISNULL(mrd.IGETCArea + ''; '','''') <> '''' THEN ''IGETC area '' ELSE @empty END,
			ISNULL(mrd.IGETCArea + ''; '',@empty),
			@space,
			dbo.fnHtmlCloseTag(@dataElementTag)
			)
		END,
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	--------------------------------------------
	-- C-ID number, if applicable
	--------------------------------------------
	dbo.fnHtmlOpenTag(@rowTag,    dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-cid-row''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
		CASE WHEN LOWER(mrd.CIDStatus) = ''approved'' AND mrd.CID IS NOT NULL AND LEN(mrd.CID) > 0 THEN CONCAT
			(
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cid-value-prefix'')),
				''('',
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cid-value'')),
				''C-ID: '', mrd.CID, 
			dbo.fnHtmlCloseTag(@dataElementTag),
			CASE WHEN mrd.CIDNotes IS NOT NULL AND LEN(mrd.CIDNotes) > 0 THEN CONCAT
				(
				dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cid-value-notes'')),
					'' '', mrd.CIDNotes,
				dbo.fnHtmlCloseTag(@dataElementTag)
				) -- Removed comma for MS-13571
			ELSE @empty END,
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-cid-value-suffix'')),
				'')'',
			dbo.fnHtmlCloseTag(@dataElementTag)
			)
		ELSE @empty END,
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	dbo.fnHtmlCloseTag(@summaryWrapperTag),
	dbo.fnHtmlCloseTag(@summaryWrapperTag), 
	''</div>''
	) AS [Text]
FROM @modelRoot mr
	INNER JOIN @modelRootData  mrd		ON mr.CourseId  = mrd.CourseId
	LEFT JOIN  @unitHourRanges unithr	ON (mr.CourseId = unithr.CourseId AND unithr.UnitHourTypeId = 1)
	LEFT JOIN  @unitHourRanges lechr	ON (mr.CourseId = lechr.CourseId  AND lechr.UnitHourTypeId  = 2)
	LEFT JOIN  @unitHourRanges labhr	ON (mr.CourseId = labhr.CourseId  AND labhr.UnitHourTypeId  = 3)
	LEFT JOIN  @unitHourRanges lrnhr	ON (mr.CourseId = lrnhr.CourseId  AND lrnhr.UnitHourTypeId  = 4)
	INNER JOIN @elementClasses ecfw		ON ecfw.Id		= 4 --4 = FullWidthRow
ORDER BY mr.InsertOrder;
'
WHERE Id = 2