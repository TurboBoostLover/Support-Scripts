USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17920';
DECLARE @Comments nvarchar(Max) = 
	'Add pop outs to courses on program requirements in catalog';
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

SET QUOTED_IDENTIFIER OFF

DECLARE @QUERY NVARCHAR(MAX) = "

		declare @entityModels_internal table (
			InsertOrder int identity (1, 1) primary key,
			Id int index ixEntityModels_internal_Id,
			Model nvarchar(max)
		);

		insert into @entityModels_internal (Id, Model)
		select em.[Key], em.[Value]
		from @entityModels em;

		declare @messageType table (
			Id int primary key not null,
			Title nvarchar(50)
		);

		insert into @messageType (Id, Title)
		values
		(1, 'error'),
		(2, 'warning'),
		(3, 'information'),
		(4, 'debug');

		declare @errorMessage int = 1;
		declare @warningMessage int = 2;
		declare @informationMessage int = 3;
		declare @debugMessage int = 4;

		declare @renderingMessageText nvarchar(max);

		declare @paramPlaceholder nvarchar(5) = ' ';

		declare @templateMessages table (
			Id int identity (1, 1) primary key,
			MessageTypeId int not null,
			MessageText nvarchar(max)
		);

		declare @messageSource sysname = 'upGenerateGroupConditionsCourseBlockDisplay default wrapper template';

		declare @space nvarchar(5) = ' ';

		declare @hoursScale int = null;
		declare @creditHoursLabel nvarchar(255) = (
			select 
				case 
					when awt.Id in (
						13--Noncredit Certificate of Competency
						, 14--Noncredit Certificate of Completion
					)
						then 'Hours:'
					else 'Units:'
				end as RenderedText
			from Program p
				inner join AwardType awt on p.AwardTypeId = awt.Id
				inner join @entityModels_internal emi on p.Id = emi.Id
		);
		declare @serializedExtraDetailsDisplay nvarchar(max) = null;

		select
			@hoursScale = atc.HoursScale,
			--@creditHoursLabel = atc.CreditHoursLabel,
			@serializedExtraDetailsDisplay = atc.ExtraDetailsDisplay
		from openjson(@additionalTemplateConfig)
		with (
			HoursScale int '$.hoursScale',
			--CreditHoursLabel nvarchar(255) '$.creditHoursLabel',
			ExtraDetailsDisplay nvarchar(max) '$.extraDetailsDisplay'
		) atc;

		declare @queryString nvarchar(max) = concat(
			'declare @extraDetailsDisplay StringPair;

			insert into @extraDetailsDisplay (String1, String2)
			select edd.Title, edd.Query
			from openjson(@serializedExtraDetailsDisplay)
			with (
				Title nvarchar(max) ''$.title'',
				Query nvarchar(max) ''$.query''
			) edd;
	
			declare @config StringPair;
			insert into @config
			(String1, String2)
			values
			(''CourseEntryLink'', ''{
				""title"": ""Course Summary"",
				""placement"": ""right"",
				""trigger"": ""focus"",
				""content"": """",
				""curriculumPresentationId"": 12
			}'');

			exec dbo.upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @outputTotal = 0, @config = @config',
			case when @hoursScale is not null then ', @hoursScale = @hoursScale' else '' end,
			case when @creditHoursLabel is not null then ', @creditHoursLabel = @creditHoursLabel' else '' end, ';'
		);

		declare @serializedParameters nvarchar(max) = (
			select
				emi.Id as [id], json_query(p.Parameters) as [parameters]
			from @entityModels_internal emi
			cross apply (
				select
					concat(
						'[',
							dbo.fnGenerateBulkResolveQueryParameter('@entityId', emi.Id, 'int'), ',',
							dbo.fnGenerateBulkResolveQueryParameter('@hoursScale', @hoursScale, 'int'), ',',
							dbo.fnGenerateBulkResolveQueryParameter('@creditHoursLabel', @creditHoursLabel, 'string'), ',',
							dbo.fnGenerateBulkResolveQueryParameterMaxString('@serializedExtraDetailsDisplay', @serializedExtraDetailsDisplay, 'string'),
						']'
					) as Parameters
			) p
			for json path
		);

		declare @serializedResults nvarchar(max);
		exec dbo.upBulkResolveQuery @queryString = @queryString, @serializedParameters = @serializedParameters, @serializedResults = @serializedResults output;

		declare @flattenedResults table (
			Id int index ixFlattenedResults_Id,
			RenderedText nvarchar(max),
			ResultSetNumber int index ixTemplateResults_ResultSetNumber,
			ParamsParseSuccess bit,
			QuerySuccess bit
		);

		insert into @flattenedResults (Id, RenderedText, ResultSetNumber, ParamsParseSuccess, QuerySuccess)
		select
			ers.Id
			, concat( 
				-- course blocks wrapper
				dbo.fnHtmlOpenTag('div', dbo.fnHtmlAttribute('class', 'program-requirements-container')),
					-- header
					dbo.fnHtmlOpenTag('header', concat(dbo.fnHtmlAttribute('class', 'program-requirements-header'), ' ', dbo.fnHtmlAttribute('style', 'border-bottom: 1px solid silver;'))),
						dbo.fnHtmlOpenTag('h3', concat(dbo.fnHtmlAttribute('class', 'program-requirements-header-title'), ' ', dbo.fnHtmlAttribute('style', 'margin-bottom: 3px;'))),
							'Program Requirements',
						dbo.fnHtmlClosetag('h3'),
					dbo.fnHtmlCloseTag('header'),
					-- content
					dbo.fnHtmlOpenTag('div', concat(dbo.fnHtmlAttribute('class', 'program-requirements-content'), ' ', dbo.fnHtmlAttribute('style', 'margin-top:10px;'))),
						dres.[Text],
					dbo.fnHtmlCloseTag('div'),
				dbo.fnHtmlCloseTag('div')
			)
			, rs.ResultSetNumber
			, srr.ParamsParseSuccess
			, ers.QuerySuccess
		from openjson(@serializedResults)
		with (
			ParamsParseSuccess bit '$.paramsParseSuccess',
			EntityResultSets nvarchar(max) '$.entityResultSets' as json,
			StatusMessages nvarchar(max) '$.statusMessages' as json
		) srr
		--srr = serialized results root
		outer apply (
			select *
			from openjson(srr.EntityResultSets)
			with (
				Id int '$.id',
				SortOrder int '$.sortOrder',
				QuerySuccess bit '$.querySuccess',
				ResultSets nvarchar(max) '$.resultSets' as json
			) ent
		) ers
		outer apply (
			select *
			from openjson(ers.ResultSets)
			with (
				ResultSetNumber int '$.resultSetNumber',
				Results nvarchar(max) '$.results' as json
			)
		) rs
		outer apply (
			select *
			from openjson(rs.Results)
			with (
				SerializedResult nvarchar(max) '$.serializedResult' as json,
				StatusMessages nvarchar(max) '$.statusMessages' as json
			)
		) res
		outer apply (
			select *
			from openjson(res.SerializedResult)
			with (
				[Value] int '$.Value',
				[Text] nvarchar(max) '$.Text'
			)
		) dres;


		select
			emi.Id as [Value], fr.RenderedText as [Text]
		from @entityModels_internal emi
		left outer join @flattenedResults fr on (fr.ResultSetNumber = 1 and emi.Id = fr.Id)
		order by emi.InsertOrder;

		if(exists (
			select top 1 1
			from @flattenedResults fr
			where (fr.ParamsParseSuccess = 0 or fr.QuerySuccess = 0)
		))
		begin;
			set @renderingMessageText = concat('Call to upGenerateGroupConditionsCourseBlockDisplay failed, ',
				'please examine the serialized call results below for details');

			--Create and return an extra result set with details of the error
			insert into @templateMessages (MessageTypeId, MessageText)
			values
			(@errorMessage, @renderingMessageText),
			(@errorMessage, @serializedResults);

			select
				@messageSource as MessageSource, tm.Id as OrderInSource, tm.MessageTypeId, mt.Title as MessageTypeTitle, tm.MessageText
			from @templateMessages tm
			inner join @messageType mt on tm.MessageTypeId = mt.Id
			order by tm.Id;

			declare @throwMessage nvarchar(2048) = concat(@messageSource, ': Call to upGenerateGroupConditionsCourseBlockDisplay failed');
			throw 50000, @throwMessage, 1;
		end;	
"
SET QUOTED_IDENTIFIER ON

INSERT INTO OutputTemplateClient
(TemplateQuery, Title, Description, StartDate, EndDate, Config)
VALUES
(@QUERY, 'Program Requirements', 'Program Requirements with link on courses', GETDATE(), NULL, NULL)

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO OutputTemplateModelMappingClient
(OutputTemplateBaseId, OutputTemplateClientId,OutputModelBaseId, OutputModelClientId, Title, Description, Config)
VALUES
(NULL, @ID, NULL, 2, 'Program Requirement links', 'Set a client key to include the links to not effect the base', NULL)

DECLARE @ID2 int = SCOPE_IDENTITY()

UPDATE CurriculumPresentationOutputFormat
SET OutputTemplateModelMappingBaseId = NULL
, OutputTemplateModelMappingClientId = @ID2
WHERE Id in (9, 10)

INSERT INTO CurriculumPresentation
(Title, Description, CurriculumPresentationGroupId, ClientId, StartDate)
VALUES
('Course Summary List for inside program call', 'Standard list of course summaries', 1, 3, GETDATE())

DECLARE @Curric int = SCOPE_IDENTITY()

INSERT INTO OutputTemplateClient
(TemplateQuery, Title, Description, StartDate)
VALUES
('
-- #region hide
DECLARE @hoursScale0 INT = 0, 
		@hoursScale1 INT = 1, 
		@hoursScale2 INT = 2;

DECLARE @hoursDecimalFormat0 NVARCHAR(10) = CONCAT(''F'', @hoursScale0), 
		@hoursDecimalFormat1 NVARCHAR(10) = CONCAT(''F'', @hoursScale1), 
		@hoursDecimalFormat2 NVARCHAR(10) = CONCAT(''F'', @hoursScale2);

DECLARE @empty		  NVARCHAR(1) = '''', 
		@space		  NVARCHAR(5) = '' '', 
		@newLine	  NVARCHAR(5) = ''
		'', 
		@classAttrib  NVARCHAR(10) = ''class'', 
		@titleAttrib  NVARCHAR(10) = ''title'', 
		@openComment  NVARCHAR(10) = ''<!-- '', 
		@closeComment NVARCHAR(10) = '' -->'';

DECLARE @tags TABLE (
	Id		INT,
	Title	NVARCHAR(255) UNIQUE NONCLUSTERED,
	Tag		NVARCHAR(10)
	);

INSERT INTO @tags (Id, Title, Tag)
VALUES
	(1,  ''SummaryWrapper'',  ''div''),
	(2,  ''Row'',				''div''),
	(3,  ''Column'',			''div''),
	(4,  ''DataElement'',	    ''span''),
	(5,  ''Block'',		    ''div''),
	(6,  ''Label'',		    ''b''),
	(7,  ''Spacer'',		    ''br''),
	(8,  ''BoldDataElement'', ''b''),
	(9,  ''SecondaryLabel'',  ''u''),
	(10, ''ItalicElement'',   ''i'');

DECLARE @mainDivTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Id = 1),  -- Group wrappers
		@rowTag		NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Id = 2),  -- Row wrappers
		@columnTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Id = 3),  -- Column wrappers
		@contentTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Id = 4),  -- Column content
		@blockTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Id = 5),  -- Layout blocks
		@labelTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Id = 6),  -- Labels (bolded)
		@spacerTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Id = 7),  -- Line breaks
		@boldTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Id = 8),  -- Bold text
		@italicTag	NVARCHAR(10) = (SELECT Tag FROM @tags WHERE Id = 10); -- Italic text

DECLARE @classes TABLE (
	Id				INT PRIMARY KEY,
	ClassSetTitle	NVARCHAR(255) UNIQUE NONCLUSTERED,
	Wrapper			NVARCHAR(255),
	LeftColumn		NVARCHAR(255),
	MiddleColumn	NVARCHAR(255),
	RightColumn		NVARCHAR(255),
	FullWidthColumn NVARCHAR(255),
	-- Computed full class attributes
	WrapperAttrib		  AS COALESCE(''class="'' + Wrapper         + ''"'', ''''),
	LeftColumnAttrib	  AS COALESCE(''class="'' + LeftColumn      + ''"'', ''''),
	MiddleColumnAttrib	  AS COALESCE(''class="'' + MiddleColumn    + ''"'', ''''),
	RightColumnAttrib	  AS COALESCE(''class="'' + RightColumn     + ''"'', ''''),
	FullWidthColumnAttrib AS COALESCE(''class="'' + FullWidthColumn + ''"'', '''')
	);

INSERT INTO @classes 
	(Id, ClassSetTitle, Wrapper, LeftColumn, MiddleColumn, RightColumn, FullWidthColumn)
VALUES
	(1, ''ThreeColumn'', ''row'', 
		''col-xs-3 col-sm-3 col-md-1 text-left left-column'', 
		''col-xs-6 col-sm-6 col-md-10 text-left middle-column'', 
		''col-xs-3 col-sm-3 col-md-1 text-right right-column'', NULL),
	(2, ''TwoColumnShorterRight'', ''row'', 
		''col-xs-9 col-md-9 col-md-9 text-left left-column'',   NULL,												  
		''col-xs-3 col-sm-3 col-md-3 text-right right-column'', NULL),
	(3, ''TwoColumnShortRight'', ''row'', 
		''col-xs-8 col-sm-8 col-md-8 text-left left-column'',   NULL,												   
		''col-xs-4 col-sm-4 col-md-4 text-left right-column'',  NULL),
	(4, ''FullWidthRow'', ''row'', NULL, NULL, NULL, 
		''col-xs-12 col-sm-12 col-md-12 text-left full-width-column'');

DECLARE @transferType1 NVARCHAR(MAX) = ''Acceptable to CSU, UC or Private'';
DECLARE @transferType2 NVARCHAR(MAX) = ''Acceptable to CSU or Private College'';

-- #endregion

DECLARE @modelRoot TABLE (
	CourseId	INT PRIMARY KEY,
	InsertOrder INT,
	RootData	NVARCHAR(MAX)
	);

DECLARE @modelRootData TABLE (
	CourseId			INT PRIMARY KEY,
	SubjectCode			NVARCHAR(MAX),
	CourseNumber		NVARCHAR(MAX),
	CourseTitle			NVARCHAR(MAX),
	CourseInfo			NVARCHAR(MAX),
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
	Requisites			NVARCHAR(MAX),
	CatalogDescription	NVARCHAR(MAX),
	CourseGrading		NVARCHAR(MAX),
	IsRepeatable		NVARCHAR(10),
	RepeatableCode		NVARCHAR(500),
	TimesRepeated		NVARCHAR(500),
	Suffix				NVARCHAR(500),
	CID					NVARCHAR(500),
	AdminRepeat			NVARCHAR(MAX)
	);

DECLARE @unitHrRg TABLE (
	Id				INT NOT NULL IDENTITY PRIMARY KEY,
	CourseId		INT,
	UnitHourTypeId	INT,
	RenderedRange	NVARCHAR(100),
	Variable		BIT
	);

INSERT INTO @modelRoot (CourseId, InsertOrder, RootData)
SELECT em.[Key], m.InsertOrder, m.RootData FROM @entityModels em
	CROSS APPLY OPENJSON(em.[Value])
		WITH (
			 InsertOrder INT		   ''$.InsertOrder'',
			 RootData	 NVARCHAR(MAX) ''$.RootData'' AS JSON
			 ) m
		;

INSERT INTO @modelRootData (
	CourseId, 
	SubjectCode, 
	CourseNumber, 
	CourseTitle, 
	CourseInfo,
	Variable, 
	MinUnit,  MaxUnit, 
	MinLec,   MaxLec, 
	MinLab,   MaxLab, 
	MinLearn, MaxLearn, 
	TransferType, 
	Requisites,  
	CatalogDescription, 
	CourseGrading, 
	IsRepeatable, 
	RepeatableCode, 
	TimesRepeated, 
	Suffix, 
	CID, 
	AdminRepeat
	)
SELECT
	m.CourseId, 
	CASE WHEN m.SubjectCode  IS NOT NULL AND LEN(m.SubjectCode)  > 0 
		 THEN m.SubjectCode  ELSE @empty END AS SubjectCode, 
	CASE WHEN m.CourseNumber IS NOT NULL AND LEN(m.CourseNumber) > 0 
		 THEN m.CourseNumber ELSE @empty END AS CourseNumber, 
	CASE WHEN m.CourseTitle  IS NOT NULL AND LEN(m.CourseTitle)  > 0 
		 THEN m.CourseTitle  ELSE @empty END AS CourseTitle, 
	m.CourseInfo,
	m.Variable, 
	m.MinUnit,  m.MaxUnit, 
	m.MinLec,   m.MaxLec, 
	m.MinLab,   m.MaxLab, 
	m.MinLearn, m.MaxLearn, 
	CASE WHEN m.TransferType	   IS NOT NULL AND LEN(m.TransferType)		 > 0 
		 THEN m.TransferType	   ELSE @empty END AS TransferType, 
	CASE WHEN m.Requisites		   IS NOT NULL AND LEN(m.Requisites)		 > 0 
		 THEN m.Requisites		   ELSE @empty END AS Requisites, 
	CASE WHEN m.CatalogDescription IS NOT NULL AND LEN(m.CatalogDescription) > 0 
		 THEN m.CatalogDescription ELSE @empty END AS CatalogDescription, 
	CASE WHEN m.CourseGrading	   IS NOT NULL AND LEN(m.CourseGrading)		 > 0 
		 THEN m.CourseGrading	   ELSE @empty	END AS CourseGrading, 
	CASE WHEN m.IsRepeatable	   IS NOT NULL AND LEN(m.IsRepeatable)		 > 0 
		 THEN m.IsRepeatable	   ELSE @empty	END AS IsRepeatable, 
	CASE WHEN m.RepeatableCode	   IS NOT NULL AND LEN(m.RepeatableCode)	 > 0 
		 THEN m.RepeatableCode	   ELSE @empty	END AS RepeatableCode,
	CASE WHEN m.TimesRepeated	   IS NOT NULL AND LEN(m.TimesRepeated)      > 0 
		 THEN m.TimesRepeated	   ELSE @empty	END AS TimesRepeated, 
	CASE WHEN m.Suffix			   IS NOT NULL AND LEN(m.Suffix)			 > 0 
		 THEN m.Suffix			   ELSE @empty END,
	CASE WHEN m.CID				   IS NOT NULL AND LEN(m.CID)				 > 0 
		 THEN m.CID			       ELSE @empty END,
	CASE WHEN m.AdminRepeat		   IS NOT NULL AND LEN(m.AdminRepeat)		 > 0 
		 THEN m.AdminRepeat		   ELSE @empty END
FROM @modelRoot mr
CROSS APPLY OPENJSON(mr.RootData)
	WITH 
		(
		CourseId			INT			   ''$.CourseId'',
		SubjectCode			NVARCHAR(MAX)  ''$.SubjectCode'',
		CourseNumber		NVARCHAR(MAX)  ''$.CourseNumber'',
		CourseTitle			NVARCHAR(MAX)  ''$.CourseTitle'',
		CourseInfo			NVARCHAR(MAX)  ''$.CourseInfo'',
		Variable			BIT			   ''$.Variable'',
		MinUnit				DECIMAL(16, 3) ''$.MinUnit'',
		MaxUnit				DECIMAL(16, 3) ''$.MaxUnit'',
		MinLec				DECIMAL(16, 3) ''$.MinLec'',
		MaxLec				DECIMAL(16, 3) ''$.MaxLec'',
		MinLab				DECIMAL(16, 3) ''$.MinLab'',
		MaxLab				DECIMAL(16, 3) ''$.MaxLab'',
		MinLearn			DECIMAL(16, 3) ''$.MinLearn'',
		MaxLearn			DECIMAL(16, 3) ''$.MaxLearn'',
		TransferType		NVARCHAR(MAX)  ''$.TransferType'',
		Requisites			NVARCHAR(MAX)  ''$.Requisites'',
		CatalogDescription	NVARCHAR(MAX)  ''$.CatalogDescription'',
		CourseGrading		NVARCHAR(MAX)  ''$.CourseGrading'',
		IsRepeatable		NVARCHAR(10)   ''$.IsRepeatable'',
		RepeatableCode		NVARCHAR(10)   ''$.RepeatableCode'',
		TimesRepeated		NVARCHAR(10)   ''$.TimesRepeated'',
		Suffix				NVARCHAR(500)  ''$.Suffix'',
		CID					NVARCHAR(500)  ''$.CID'',
		AdminRepeat			NVARCHAR(500)  ''$.AdminRepeat''
		) m

INSERT INTO @unitHrRg 
	(CourseId, UnitHourTypeId, RenderedRange, Variable)
SELECT 
	mrd.CourseId, 
	uht.UnitHourTypeId, 
	uhr.RenderedRange, 
	uht.Variable 
FROM @modelRootData mrd
	CROSS APPLY (
		SELECT 1 AS UnitHourTypeId, -- Units
			mrd.MinUnit AS MinVal, 
			CASE WHEN ISNULL(mrd.MaxUnit, 0) = 0 
				 THEN mrd.MinUnit ELSE mrd.MaxUnit END AS MaxVal, 
			1 AS RenderIfZero, 0 AS ForceRange, 
			CASE WHEN (mrd.Variable = 1 
			AND mrd.MinUnit <> ISNULL(mrd.MaxUnit,mrd.MinUnit)) 
				 THEN 1 ELSE 0 END AS Variable, 
			1 AS FormatType, 1 AS Render
		UNION ALL
		SELECT 2 AS UnitHourTypeId, -- Lec
			mrd.MinLec AS MinVal, 
			CASE WHEN ISNULL(mrd.MaxLec,0) = 0 
				 THEN mrd.MinLec ELSE mrd.MaxLec END AS MaxVal, 
			0 AS RenderIfZero, 0 AS ForceRange, 
			CASE WHEN (mrd.Variable = 1 
			AND mrd.MinLec <> ISNULL(mrd.MaxLec, mrd.MinLec)) 
				 THEN 1 ELSE 0 END AS Variable, 
			2 AS FormatType, 1 AS Render
		UNION ALL
		SELECT 3 AS UnitHourTypeId, -- Lab
			mrd.MinLab AS MinVal, 
			CASE WHEN ISNULL(mrd.MaxLab,0) = 0 
				 THEN mrd.MinLab ELSE mrd.MaxLab END AS MaxVal, 
			0 AS RenderIfZero, 0 AS ForceRange, 
			CASE WHEN (mrd.Variable = 1 
			AND mrd.MinLab <> ISNULL(mrd.MaxLab,mrd.MinLab)) 
				 THEN 1 ELSE 0 END AS Variable, 
			2 AS FormatType, 1 AS Render
		UNION ALL
		SELECT 4 AS UnitHourTypeId, -- Learn
			mrd.MinLearn AS MinVal, 
			CASE WHEN ISNULL(mrd.MaxLearn,0) = 0 
				 THEN mrd.MinLearn ELSE mrd.MaxLearn END AS MaxVal, 
			0 AS RenderIfZero, 0 AS ForceRange, 
			CASE WHEN (mrd.Variable = 1 
			AND mrd.MinLearn <> ISNULL(mrd.MaxLearn, mrd.MinLearn)) 
				 THEN 1 ELSE 0 END AS Variable, 
			2 AS FormatType, 1 AS Render
	) uht
	CROSS APPLY (
		SELECT CASE 
			WHEN uht.Render = 1
				AND ((uht.Variable = 1 AND uht.MinVal IS NOT NULL 
						AND uht.MaxVal IS NOT NULL AND uht.MinVal != uht.MaxVal)
					OR (uht.ForceRange = 1)) 
			THEN CONCAT (
				FORMAT(uht.MinVal, 
					CASE WHEN uht.FormatType = 0 THEN @hoursDecimalFormat0 
						 WHEN uht.FormatType = 1 THEN @hoursDecimalFormat1 
					ELSE @hoursDecimalFormat2 END),
				''-'',
				FORMAT(uht.MaxVal, 
					CASE WHEN uht.FormatType = 0 THEN @hoursDecimalFormat0 
						 WHEN uht.FormatType = 1 THEN @hoursDecimalFormat1 
					ELSE @hoursDecimalFormat2 END))
			WHEN (uht.Render = 1 AND uht.MaxVal IS NOT NULL 
				 AND (uht.MaxVal > 0 or uht.RenderIfZero = 1)) 
			THEN FORMAT(uht.MaxVal, 
				CASE WHEN uht.FormatType = 0 THEN @hoursDecimalFormat0 
					 WHEN uht.FormatType = 1 THEN @hoursDecimalFormat1 
				ELSE @hoursDecimalFormat2 END)
			ELSE NULL END AS RenderedRange
	) uhr

SELECT mr.CourseId AS [Value],
CONCAT (
	-- Custom Course Summary context wrapper
	dbo.fnHtmlOpenTag (
		@mainDivTag,
		dbo.fnHtmlAttribute(@classAttrib, ''custom-course-summary-context-wrapper'')
		),
		-- Another nested wrapper
		dbo.fnHtmlOpenTag (
			@mainDivTag, 
			CONCAT (
				dbo.fnHtmlAttribute(@classAttrib, ''container-fluid course-summary-wrapper''),
				@space,
				dbo.fnHtmlAttribute(''data-course-id'', mrd.CourseId))
			),
			-- Course Title row (Subject Code, Course Number, and Course Title)
			dbo.fnHtmlOpenTag (
				@rowTag, 
				dbo.fnHtmlAttribute (
					@classAttrib,			-- Course Title Row
					CONCAT(ecfw.Wrapper, @space, ''course-title-header'')
					)
				),
				dbo.fnHtmlOpenTag (
					@columnTag, 
					dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)
					),
					dbo.fnHtmlOpenTag (
						@boldTag,			-- Course Subject
						dbo.fnHtmlAttribute(@classAttrib, ''course-subject'')
						),
						UPPER(mrd.SubjectCode), @space,
					dbo.fnHtmlCloseTag(@boldTag),
					dbo.fnHtmlOpenTag (
						@boldTag,			-- Course Number
						dbo.fnHtmlAttribute(@classAttrib, ''course-number'')
						),
						UPPER(mrd.CourseNumber), 
						CASE WHEN mrd.Suffix IS NOT NULL AND LEN(mrd.Suffix) > 0 
								THEN CONCAT(mrd.Suffix, @space) ELSE @space END,
					dbo.fnHtmlCloseTag(@boldTag),
					dbo.fnHtmlOpenTag (
						@boldTag,			-- Course Title
						dbo.fnHtmlAttribute(@classAttrib, ''course-title'')
						),
						UPPER(mrd.CourseTitle),
					dbo.fnHtmlCloseTag(@boldTag),
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),

			-- Course Info (buttons & modals)
			--dbo.fnHtmlOpenTag (
			--	@rowTag,
			--	dbo.fnHtmlAttribute (
			--		@classAttrib,		-- Course Info Row
			--		CONCAT(ecfw.Wrapper, @space, ''course-info-row'')
			--		)
			--	), 
			--	dbo.fnHtmlOpenTag (
			--		@columnTag,			-- Course Info Output
			--		dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)
			--		),
			--		mrd.CourseInfo,		
			--	dbo.fnHtmlCloseTag(@columnTag),
			--dbo.fnHtmlCloseTag(@rowTag),

			-- Units and Hours
			dbo.fnHtmlOpenTag (
				@rowTag, 
				dbo.fnHtmlAttribute (
					@classAttrib,		-- Units and Hours Row
					CONCAT(ecfw.Wrapper, @space, ''course-units-row'')
					)
				),
				-- Units
				dbo.fnHtmlOpenTag (
					@columnTag, 
					dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)
					),
					dbo.fnHtmlOpenTag (	
						@boldTag,		-- Unit Range
						dbo.fnHtmlAttribute(@classAttrib, ''course-unit-range'')
						),
						ISNULL(unithr.RenderedRange, @empty), @space,
					dbo.fnHtmlCloseTag(@boldTag),
					dbo.fnHtmlOpenTag (
						@boldTag,		-- Unit Output 
						dbo.fnHtmlAttribute(@classAttrib, ''course-unit-label'')
						),
						CASE WHEN LEN(unithr.RenderedRange) > 0 THEN CASE 
								WHEN unithr.Variable = 1 OR unithr.RenderedRange > ''1.0'' 
								THEN ''Units'' ELSE ''Unit'' END
						ELSE @empty END, @space,
					dbo.fnHtmlCloseTag(@boldTag),

					-- Lecture
					dbo.fnHtmlOpenTag (
						@boldTag,		-- Lecture Range
						dbo.fnHtmlAttribute(@classAttrib, ''course-hr-range course-lecture'')
						),
						ISNULL(lechr.RenderedRange, @empty), @space,
					dbo.fnHtmlCloseTag(@boldTag),
					dbo.fnHtmlOpenTag (
						@boldTag,		-- Lecture Output
						dbo.fnHtmlAttribute(@classAttrib, ''course-hr-label course-lecture'')
						),
						CASE WHEN LEN(lechr.RenderedRange) > 0 THEN CASE 
								WHEN lechr.Variable = 1 OR lechr.RenderedRange > ''1.00'' 
								THEN ''hours Lecture'' ELSE ''hour Lecture'' END
						ELSE @empty END, @space,
					dbo.fnHtmlCloseTag(@boldTag),

					-- Lab
					dbo.fnHtmlOpenTag (
						@boldTag,		-- Lab Range
						dbo.fnHtmlAttribute(@classAttrib, ''course-hr-range course-lab'')
						),
						ISNULL(labhr.RenderedRange, @empty), @space,
					dbo.fnHtmlCloseTag(@boldTag),
					dbo.fnHtmlOpenTag (
						@boldTag,		-- Lab Output
						dbo.fnHtmlAttribute(@classAttrib, ''course-hr-label course-lab'')
						),
						CASE WHEN LEN(labhr.RenderedRange) > 0 THEN CASE 
								WHEN labhr.Variable = 1 OR labhr.RenderedRange > ''1.00'' 
								THEN ''hours Lab'' ELSE ''hour Lab'' END
						ELSE @empty END, @space,
					dbo.fnHtmlCloseTag(@boldTag),

					-- Learn
					dbo.fnHtmlOpenTag (
						@boldTag,		-- Learn Range
						dbo.fnHtmlAttribute(@classAttrib, ''course-hr-range course-learn'')
						),
						ISNULL(lrnhr.RenderedRange, @empty), @space,
					dbo.fnHtmlCloseTag(@boldTag),
					dbo.fnHtmlOpenTag (
						@boldTag,		-- Learn Output
						dbo.fnHtmlAttribute(@classAttrib, ''course-hr-label course-learn'')
						),
						CASE WHEN LEN(lrnhr.RenderedRange) > 0 THEN CASE 
								WHEN lrnhr.Variable = 1 OR lrnhr.RenderedRange > ''1.00'' 
								THEN ''hours Learning Center'' ELSE ''hour Learning Center'' END
						ELSE @empty END, @space,
					dbo.fnHtmlCloseTag(@boldTag),
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),

			-- Transfers
			dbo.fnHtmlOpenTag (
				@rowTag, 
				dbo.fnHtmlAttribute (
					@classAttrib,		-- Transfer Row 
					CONCAT(ecfw.Wrapper, @space, ''course-transfer-row'')
					)
				),
				dbo.fnHtmlOpenTag (
					@columnTag, 
					dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)
					),
					dbo.fnHtmlOpenTag (
						@italicTag,		-- Transfer Label
						dbo.fnHtmlAttribute(@classAttrib, ''course-transfer-label'')
						),
						CASE WHEN mrd.TransferType IN (@transferType1, @transferType2) 
								THEN ''Transfers: '' ELSE @empty END, @space,
					dbo.fnHtmlCloseTag(@italicTag),
					dbo.fnHtmlOpenTag (
						@italicTag,		-- Transfer Value
						dbo.fnHtmlAttribute(@classAttrib, ''course-transfer-value'')
						),
						CASE WHEN mrd.TransferType IS NOT NULL 
						AND LEN(mrd.TransferType) > 0 
								THEN CASE 
									WHEN mrd.TransferType = @transferType1  THEN ''CSU, UC''
									WHEN mrd.TransferType = @transferType2  THEN ''CSU'' 
									ELSE @empty END
								ELSE @empty END, @space,
					dbo.fnHtmlCloseTag(@italicTag),
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),

			-- Requisites
			dbo.fnHtmlOpenTag (
				@rowTag, 
				dbo.fnHtmlAttribute (
					@classAttrib,		-- Requisites Row
					CONCAT(ecfw.Wrapper, @space, ''course-requisites-row'')
					)
				),
				dbo.fnHtmlOpenTag (
					@columnTag, 
					dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)
					),
					dbo.fnHtmlOpenTag (
						@contentTag,	-- Requisites Output
						dbo.fnHtmlAttribute(@classAttrib, ''course-requisites-value'')
						),
						CASE WHEN mrd.Requisites IS NOT NULL 
						AND LEN(mrd.Requisites) > 0 
								THEN mrd.Requisites ELSE @empty END, @space,
					dbo.fnHtmlCloseTag(@contentTag),
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),

			-- Description
			dbo.fnHtmlOpenTag (
				@rowTag, 
				dbo.fnHtmlAttribute (
					@classAttrib,		-- Description Row
					CONCAT(ecfw.Wrapper, @space, ''course-description-row'')
					)
				),
				dbo.fnHtmlOpenTag (
					@columnTag, 
					dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)
					),
					dbo.fnHtmlOpenTag (
						@contentTag,	-- Description Output
						dbo.fnHtmlAttribute(@classAttrib, ''course-description-value'')
						),
						CASE WHEN mrd.CatalogDescription IS NOT NULL 
						AND LEN(mrd.CatalogDescription) > 0 
								THEN mrd.CatalogDescription ELSE @empty END, @space,
					dbo.fnHtmlCloseTag(@contentTag),
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),

			-- Grading
			dbo.fnHtmlOpenTag (
				@rowTag, 
				dbo.fnHtmlAttribute (
					@classAttrib,		-- Grading Row
					CONCAT(ecfw.Wrapper, @space, ''course-grading-row'')
					)
				),
				dbo.fnHtmlOpenTag (
					@columnTag, 
					dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)
					),
					dbo.fnHtmlOpenTag (
						@contentTag,	-- Grading Label
						dbo.fnHtmlAttribute(@classAttrib, ''course-grading-label'')
						),
						''Grading Method:'', @space,
					dbo.fnHtmlCloseTag(@contentTag),
					dbo.fnHtmlOpenTag (
						@contentTag,	-- Grading Value
						dbo.fnHtmlAttribute(@classAttrib, ''course-grading-value'')
						),
						ISNULL(mrd.CourseGrading, @empty), @space,
					dbo.fnHtmlCloseTag(@contentTag),
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),

			-- Repeat
			dbo.fnHtmlOpenTag (
				@rowTag, 
				dbo.fnHtmlAttribute (
					@classAttrib,	-- Repeatability Row
					CONCAT(ecfw.Wrapper, @space, ''course-repeatability-row'')
					)
				),
				dbo.fnHtmlOpenTag (
					@columnTag, 
					dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)
					),
					dbo.fnHtmlOpenTag (
						@italicTag,	-- Repeatability Output
						dbo.fnHtmlAttribute(@classAttrib, ''course-repeatability-value'')
						),
						CASE WHEN mrd.IsRepeatable = ''Yes'' 
								AND mrd.RepeatableCode IS NOT NULL 
								AND mrd.TimesRepeated IS NOT NULL 
								AND LEN(mrd.RepeatableCode) > 0 
								AND LEN(mrd.TimesRepeated) > 0 
						THEN CONCAT(
							''R-'', mrd.RepeatableCode, ''-'', mrd.TimesRepeated,
						-- AdminRepeat
							CASE WHEN mrd.AdminRepeat IS NOT NULL 
							AND LEN(mrd.AdminRepeat) > 0 
									THEN CONCAT('' - '', mrd.AdminRepeat) END)
						ELSE ''NR'' END,
					dbo.fnHtmlCloseTag(@italicTag),
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),

			-- C-ID
			dbo.fnHtmlOpenTag (
				@rowTag, 
				dbo.fnHtmlAttribute (
					@classAttrib,		-- C-ID Row
					CONCAT(ecfw.Wrapper, @space, ''course-CID-row'')
					)
				),
				dbo.fnHtmlOpenTag (
					@columnTag, 
					dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)
					),
					dbo.fnHtmlOpenTag (
						@contentTag,	-- C-ID Output
						dbo.fnHtmlAttribute(@classAttrib, ''course-CID-value'')
						),
						CASE WHEN mrd.CID IS NOT NULL AND LEN(mrd.CID) > 0 
								THEN CONCAT(''C-ID: '', mrd.CID) END,
					dbo.fnHtmlCloseTag(@contentTag),
				dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag),
		dbo.fnHtmlCloseTag(@mainDivTag),
	dbo.fnHtmlCloseTag(@mainDivTag)
) AS [Text]
FROM @modelRoot mr
	INNER JOIN @modelRootData mrd ON mr.CourseId  = mrd.CourseId
	LEFT JOIN  @unitHrRg unithr   ON (mr.CourseId = unithr.CourseId AND unithr.UnitHourTypeId = 1)
	LEFT JOIN  @unitHrRg lechr    ON (mr.CourseId = lechr.CourseId  AND lechr.UnitHourTypeId  = 2)
	LEFT JOIN  @unitHrRg labhr    ON (mr.CourseId = labhr.CourseId  AND labhr.UnitHourTypeId  = 3)
	LEFT JOIN  @unitHrRg lrnhr    ON (mr.CourseId = lrnhr.CourseId  AND lrnhr.UnitHourTypeId  = 4)
	INNER JOIN @classes  ecfw	  ON ecfw.Id	  = 4 -- 4 = FullWidthRow
ORDER BY mr.InsertOrder;
', 'Course Summary - Irvine for program display', 'Course Summary - Irvine remove buttons for program call', GETDATE())

DECLARE @cl int = SCOPE_IDENTITY()

INSERT INTO OutputModelClient
(ModelQuery, Title, Description, StartDate, EntityTypeId)
VALUES
('
DECLARE @entityList_internal TABLE 
	(
    InsertOrder INT IDENTITY(1, 1) PRIMARY KEY, 
	CourseId	INT
	);

INSERT INTO @entityList_internal (CourseId)
SELECT el.Id FROM @entityList el ORDER BY InsertOrder;
-- VALUES (26379)

DECLARE @entityRootData TABLE 
	(	
    CourseId			INT PRIMARY KEY,
    SubjectCode			NVARCHAR(MAX),
    CourseNumber		NVARCHAR(MAX),
    CourseTitle			NVARCHAR(MAX),
	CourseInfo			NVARCHAR(MAX), 
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
    Requisites			NVARCHAR(MAX),
    CatalogDescription	NVARCHAR(MAX),
    CourseGrading		NVARCHAR(MAX),
    IsRepeatable		NVARCHAR(10),
    RepeatableCode		NVARCHAR(500),
    TimesRepeated		NVARCHAR(500),
	Suffix				NVARCHAR(500),
    CID					NVARCHAR(500),
    AdminRepeat			NVARCHAR(MAX)
);

DECLARE @clientId INT = 3; -- Irvine

DECLARE @RequisiteQuery NVARCHAR(MAX) = 
	(
    SELECT CustomSql
    FROM MetaForeignKeyCriteriaClient
    WHERE Title = ''Catalog Requisites - All'' 
	);

DECLARE @CourseInfoQuery NVARCHAR(MAX) = 
	(
	SELECT CustomSql
	FROM MetaForeignKeyCriteriaClient
	WHERE Title = ''Course Summary - Info Buttons/Modals''
	);

--============================--
-- Return
--============================--
INSERT INTO @entityRootData 
	(
    CourseId, 
	SubjectCode, 
	CourseNumber, 
	CourseTitle, 
	CourseInfo,
	Variable, 
	MinUnit,  MaxUnit, 
	MinLec,   MaxLec, 
	MinLab,   MaxLab, 
	MinLearn, MaxLearn, 
	TransferType, 
	Requisites, 
	CatalogDescription, 
	CourseGrading, 
	IsRepeatable, 
	RepeatableCode, 
	TimesRepeated, 
	Suffix, 
	CID, 
	AdminRepeat
	)
SELECT 
	c.Id, 
	s.SubjectCode, 
	c.CourseNumber, 
	c.Title, 
	info.Text,									-- Course Info buttons & modals
	cd.Variable, 
	cd.MinCreditHour,  cd.MaxCreditHour,		-- Units
	cd.MinLectureHour, cd.MaxLectureHour,		-- Lecture Hours
	cd.MinLabHour,     cd.MaxLabHour,			-- Lab Hours
	cd.MinContHour,	   cd.MaxContHour,			-- Learning Hours
	ta.Description,								-- Transfer Info
	req.Text,									-- Requisites
	LTRIM(RTRIM(c.[Description])),				-- Course Description 
	CONCAT(gro.Title,'' - '', gro.[Description]),	-- Course Grading
	yn.Title,									-- IsRepeatable
    rpl.Code,									-- RepeatCode
    rp.Code,									-- Times Repeated
	csx.Code,									-- Suffix
    cid.Text,									-- C-ID
    cp.TimesOfferedRationale					-- Admin Repeat
FROM Course c
    INNER JOIN @entityList_internal eli ON eli.CourseId			= c.Id				
    INNER JOIN CourseDescription	cd	ON cd.CourseId			= c.Id
    INNER JOIN CourseProposal		cp	ON cp.CourseId			= cd.CourseId
    INNER JOIN CourseCBcode			cbc ON cbc.CourseId			= c.Id
	INNER JOIN ProposalType			pt	ON c.ProposalTypeId		= pt.Id
		AND pt.ProcessActionTypeId IN (1, 2) 
    LEFT JOIN [Subject]				s	ON c.SubjectId			= s.Id
    LEFT JOIN GradeOption			gro ON cd.GradeOptionId		= gro.Id
    LEFT JOIN CourseYesNo			cyn ON cyn.CourseId			= c.Id
    LEFT JOIN YesNo					yn	ON cyn.YesNo05Id		= yn.Id
    LEFT JOIN TransferApplication	ta	ON cd.TransferAppsId	= ta.Id
    LEFT JOIN RepeatLimit			rpl	ON cp.RepeatLimitId		= rpl.Id
    LEFT JOIN Repeatability			rp	ON cp.RepeatabilityId	= rp.Id
	LEFT JOIN CourseSuffix			csx	ON c.CourseSuffixId		= csx.Id
    OUTER APPLY (
		SELECT * FROM dbo.fnBulkResolveCustomSqlQuery(
			@CourseInfoQuery, 0, c.Id, @clientId, NULL, NULL, NULL)
	) info
	OUTER APPLY (
        SELECT * FROM dbo.fnBulkResolveCustomSqlQuery(
			@RequisiteQuery, 0, c.Id, @clientId, NULL, NULL, NULL)
    ) req
    OUTER APPLY (
        SELECT dbo.ConcatWithSepOrdered_Agg('', '', cs.Id, ReadMaterials) AS Text
        FROM CourseSupply cs WHERE cs.CourseId = c.Id
    ) cid
;

SELECT eli.CourseId AS Id, m.Model
FROM @entityList_internal eli
    CROSS APPLY (SELECT (
		SELECT * FROM @entityRootData erd
        WHERE eli.CourseId = erd.CourseId 
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
		) RootData
	) erd
    CROSS APPLY (SELECT (
        SELECT eli.InsertOrder, JSON_QUERY(erd.RootData) AS RootData
        FOR JSON PATH
		) Model
	) m
	;
', 'Course Summary - Irvine for program display', 'Irvine - custom Course Summary model remove buttons for program', GETDATE(), 2)

DECLARE @mod int = SCOPE_IDENTITY()

INSERT INTO OutputTemplateModelMappingClient
(OutputTemplateClientId, OutputModelClientId, Title, Description)
VALUES
(@cl, @mod, 'Catalog Course summary', 'Remove buttons')

DECLARE @Temp int = SCOPE_IDENTITY()

INSERT INTO CurriculumPresentationOutputFormat
(CurriculumPresentationId, OutputTemplateModelMappingClientId, OutputFormatId)
VALUES
(@Curric, @Temp, 4),
(@Curric, @Temp, 5)