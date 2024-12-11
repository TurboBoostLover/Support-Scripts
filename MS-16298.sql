USE [riohondo];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16298';
DECLARE @Comments nvarchar(Max) = 
	'Redo Catalog Query';
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
UPDATE OutputTemplateClient
SET TemplateQuery = '
--#region template query
declare @hoursScale int = 3;
declare @hoursDecimalFormat nvarchar(10) = concat(''F'', @hoursScale);
declare @truncateInsteadOfRound bit = 0;
declare @empty nvarchar(1) = '''';
declare @space nvarchar(5) = '' '';
declare @newline nvarchar(5) =
''
'';

declare @classAttrib nvarchar(10) = ''class'';
declare @titleAttrib nvarchar(10) = ''title'';
declare @styleAttrib nvarchar(10) = ''style'';

declare @openComment nvarchar(10) = ''<!-- '';
declare @closeComment nvarchar(10) = '' -->'';
declare @innerListDelimiter nvarchar(max) =
''<span class="list-delimiter inner-list-delimiter">, </span>'';
declare @outerListDelimter nvarchar(max) =
''<span class="list-delimiter outer-list-delimiter">; </span>'';
declare @dash nvarchar(10) = ''&mdash;'';
declare @colon nvarchar(10) = '':'';
declare @openParan nvarchar(10) = ''('';
declare @closeParan nvarchar(10) = '')'';

--#region element tags
declare @elementTags table (
	Id int,
	ElementTitle nvarchar(255) unique nonclustered,
	ElementTag nvarchar(10)
);

INSERT INTO @elementTags
(Id, ElementTitle, ElementTag)
VALUES
(1, ''SummaryWrapper'', ''div''),
(2, ''Row'', ''div''),
(3, ''Column'', ''div''),
(4, ''DataElement'', ''span''),
(5, ''Block'', ''div''),
(6, ''Label'', ''b''),
(7, ''Spacer'', ''br''),
(8, ''BoldDataElement'', ''b''),
(9, ''SecondaryLabel'', ''u'')
;

declare
	--The tag name to use for the group wrappers
	@summaryWrapperTag nvarchar(10) = (
	SELECT
		ElementTag
	FROM @elementTags
	WHERE ElementTitle = ''SummaryWrapper''
)
,
--The tag name to use for the row wrappers
@rowTag NVARCHAR(10) = (
	SELECT
		ElementTag
	FROM @elementTags
	WHERE ElementTitle = ''Row''
)
,
--The tag name to use for the column wrappers
@columnTag NVARCHAR(10) = (
	SELECT
		ElementTag
	FROM @elementTags
	WHERE ElementTitle = ''Column''
)
,
--The tag name to use for the wrappers of the individual data elements inside the columns
@dataElementTag NVARCHAR(10) = (
	SELECT
		ElementTag
	FROM @elementTags
	WHERE ElementTitle = ''DataElement''
)
,
--The tag name to use for generic layout blocks
@blockTag NVARCHAR(10) = (
	SELECT
		ElementTag
	FROM @elementTags
	WHERE ElementTitle = ''Block''
)
,
--The tag name to use for wrapping labels
@labelTag NVARCHAR(10) = (
	SELECT
		ElementTag
	FROM @elementTags
	WHERE ElementTitle = ''Label''
)
,
--The tag name for elements to insert vertical blank lines between other elements
@spacerTag NVARCHAR(10) = (
	SELECT
		ElementTag
	FROM @elementTags
	WHERE ElementTitle = ''Spacer''
)
,
--The tag name to use for wrappers around invidual data elements that should be bolded by default
--This allows for bolding of elements w/o having to edit the CSS
@boldDataElementTag NVARCHAR(10) = (
	SELECT
		ElementTag
	FROM @elementTags
	WHERE ElementTitle = ''BoldDataElement''
)
,
--The tag name for secondary labels; ones that need a different formatting than the primary labels
@secondaryLabelTag NVARCHAR(10) = (
	SELECT
		ElementTag
	FROM @elementTags
	WHERE ElementTitle = ''SecondaryLabel''
);

--#endregion element tags

--#region element classes
declare @elementClasses table (
	Id int primary key,
	ClassSetTitle nvarchar(255) unique nonclustered,
	Wrapper nvarchar(255),
	LeftColumn nvarchar(255),
	MiddleColumn nvarchar(255),
	RightColumn nvarchar(255),
	FullWidthColumn nvarchar(255),

	--Computed full class attributes
	WrapperAttrib as coalesce(''class="'' + Wrapper + ''"'', ''''),
	LeftColumnAttrib as coalesce(''class="'' + LeftColumn + ''"'', ''''),
	MiddleColumnAttrib as coalesce(''class="'' + MiddleColumn + ''"'', ''''),
	RightColumnAttrib as coalesce(''class="'' + RightColumn + ''"'', ''''),
	FullWidthColumnAttrib as coalesce(''class="'' + FullWidthColumn + ''"'', '''')
);

INSERT INTO @elementClasses
(Id, ClassSetTitle, Wrapper, LeftColumn, MiddleColumn, RightColumn, FullWidthColumn)
VALUES
(1, ''ThreeColumn'', ''row'', ''col-xs-3 col-sm-3 col-md-1 text-left left-column'', ''col-xs-6 col-sm-6 col-md-10 text-left middle-column'', ''col-xs-3 col-sm-3 col-md-1 text-right right-column'', NULL),
(2, ''TwoColumnShorterRight'', ''row'', ''col-xs-9 col-md-9 col-md-9 text-left left-column'', NULL, ''col-xs-3 col-sm-3 col-md-3 text-right right-column'', NULL),
(3, ''TwoColumnShortRight'', ''row'', ''col-xs-8 col-sm-8 col-md-8 text-left left-column'', NULL, ''col-xs-4 col-sm-4 col-md-4 text-left right-column'', NULL),
(4, ''FullWidthRow'', ''row'', NULL, NULL, NULL, ''col-xs-12 col-sm-12 col-md-12 text-left full-width-column'')
;
--#endregion element classes

--#region model tables
declare @modelRoot table (
	Id int primary key,
	InsertOrder int,
	RootData nvarchar(max)
);

declare @modelRootData table (
	Id int primary key,
	Variable bit,
	MinCreditHour decimal(16, 3),
	MaxCreditHour decimal(16, 3),
	MinLectureHour decimal(16, 3),
	MaxLectureHour decimal(16, 3),
	MinLabHour decimal(16, 3),
	MaxLabHour decimal(16, 3),
	FamilyCount int,
	BaseCourseId int,
	ProcessActionType nvarchar(50),
	StatusBase nvarchar(50),
	StatusAlias nvarchar(50),
	SubjectTitle nvarchar(100),
	SubjectCode nvarchar(10),
	CourseNumber nvarchar(10),
	CourseTitle nvarchar(255),
	IsCreditCourse bit,
	CourseDescription nvarchar(max),
	TransferApps nvarchar(500),
	TransferLimitations nvarchar(max),
	RequisiteCatalogView nvarchar(max),
	CID nvarchar(250)
);

--#region parse model root
INSERT INTO @modelRoot
(
	Id, 
	InsertOrder, 
	RootData
)
	SELECT
		em.[Key] AS Id
	   ,m.InsertOrder
	   ,m.RootData
	FROM @entityModels em
		CROSS APPLY OPENJSON(em.[Value])
			WITH (
			InsertOrder INT ''$.InsertOrder'',
			RootData NVARCHAR(MAX) ''$.RootData'' AS JSON
			) m;
--#endregion parse model root

--#region parse model root data
INSERT INTO @modelRootData
(
  Id
, Variable
, MinCreditHour
, MaxCreditHour
, MinLectureHour
, MaxLectureHour
, MinLabHour
, MaxLabHour
, FamilyCount
, BaseCourseId
, ProcessActionType
, StatusBase
, StatusAlias
, SubjectTitle
, SubjectCode
, CourseNumber
, CourseTitle
, IsCreditCourse
, CourseDescription
, TransferApps
, TransferLimitations
, RequisiteCatalogView
, CID
)
	SELECT
		rd.Id
	   , rd.Variable
	   , rd.MinCreditHour
	   , rd.MaxCreditHour
	   , rd.MinLectureHour
	   , rd.MaxLectureHour
	   , rd.MinLabHour
	   , rd.MaxLabHour
	   , rd.FamilyCount
	   , rd.BaseCourseId
	   , rd.ProcessActionType
	   , rd.StatusBase
	   , rd.StatusAlias
	   , rd.SubjectTitle
	   , rd.SubjectCode
	   , rd.CourseNumber
	   , rd.CourseTitle
	   , rd.IsCreditCourse
	   , rd.CourseDescription
	   , rd.TransferApps
	   , rd.TransferLimitations
	   , rd.RequisiteCatalogView
	   , rd.CID
	FROM @modelRoot mrd
		CROSS APPLY OPENJSON(mrd.RootData)
			WITH (
				Id INT ''$.Id'',
				Variable BIT ''$.Variable'',
				MinCreditHour DECIMAL(16, 3) ''$.MinCreditHour'',
				MaxCreditHour DECIMAL(16, 3) ''$.MaxCreditHour'',
				MinLectureHour DECIMAL(16, 3) ''$.MinLectureHour'',
				MaxLectureHour DECIMAL(16, 3) ''$.MaxLectureHour'',
				MinLabHour DECIMAL(16, 3) ''$.MinLabHour'',
				MaxLabHour DECIMAL(16, 3) ''$.MaxLabHour'',
				FamilyCount INT ''$.FamilyCount'',
				BaseCourseId INT ''$.BaseCourseId'',
				ProcessActionType NVARCHAR(50) ''$.ProcessActionType'',
				StatusBase NVARCHAR(50) ''$.StatusBase'',
				StatusAlias NVARCHAR(50) ''$.StatusAlias'',
				SubjectTitle NVARCHAR(100) ''$.SubjectTitle'',
				SubjectCode NVARCHAR(10) ''$.SubjectCode'',
				CourseNumber NVARCHAR(10) ''$.CourseNumber'',
				CourseTitle NVARCHAR(255) ''$.CourseTitle'',
				IsCreditCourse BIT ''$.IsCreditCourse'',
				CourseDescription NVARCHAR(MAX) ''$.CourseDescription'',
				TransferApps NVARCHAR(500) ''$.TransferApps'',
				TransferLimitations NVARCHAR(MAX) ''$.TransferLimitations'',
				RequisiteCatalogView nvarchar(MAX) ''$.RequisiteCatalogView'',
				CId NVARCHAR(250) ''$.CID''
			) rd;
--#endregion parse model root data

declare @unitHourRanges table (
	CourseId int,
	UnitHourTypeId int,
	TypeName nvarchar(25),
	MinVal decimal(16, 3),
	MaxVal decimal(16, 3),
	RenderedRange nvarchar(100),
	primary key (CourseId, UnitHourTypeId)
);

declare @renderedGenEd table (
	CourseId int primary key,
	CombinedAreas nvarchar(max)
);

declare @renderedCrossListings table (
	CourseId int primary key,
	CombinedCrossListings nvarchar(max)
);

--#endregion additional rendering tables

--#region units/hours compose
INSERT INTO @unitHourRanges
(CourseId, UnitHourTypeId, TypeName, MinVal, MaxVal, RenderedRange)
	SELECT
		mr.Id AS CourseId
	   ,uht.UnitHourTypeId
	   ,uht.TypeName
	   ,uht.MinVal
	   ,uht.MaxVal
	   ,uhr.RenderedRange
	FROM @modelRoot mr
		INNER JOIN @modelRootData mrd ON mr.Id = mrd.Id
		CROSS APPLY (
				SELECT
					1 AS UnitHourTypeId
				   ,''Units'' AS TypeName
				   ,mrd.MinCreditHour AS MinVal
				   ,mrd.MaxCreditHour AS MaxVal
				UNION ALL
				SELECT
					2 AS UnitHourTypeId
				   ,''Lecture'' AS TypeName
				   ,mrd.MinLectureHour AS MinVal
				   ,mrd.MaxLectureHour AS MaxVal
				UNION ALL
				SELECT
					3 AS UnitHourTypeId
				   ,''Lab'' AS TypeName
				   ,mrd.MinLabHour AS MinVal
				   ,mrd.MaxLabHour AS MaxVal
			) uht
		CROSS APPLY (
				SELECT
					CASE
						WHEN isnull(uht.MinVal, 0) = 0 and isnull(uht.MaxVal, 0) = 0 and mrd.IsCreditCourse = 0 then ''0''
						WHEN uht.MinVal IS NOT NULL AND uht.MaxVal IS NOT NULL AND uht.MinVal <> uht.MaxVal THEN 
								CONCAT(
									dbo.FormatDecimal(uht.MinVal, @hoursScale, @truncateInsteadOfRound), ''-'', dbo.FormatDecimal(uht.MaxVal, @hoursScale, @truncateInsteadOfRound)
								)
						WHEN uht.MinVal IS NOT NULL
							THEN dbo.FormatDecimal(uht.MinVal, @hoursScale, @truncateInsteadOfRound)
						WHEN uht.MaxVal IS NOT NULL 
							THEN dbo.FormatDecimal(uht.MaxVal, @hoursScale, @truncateInsteadOfRound)
						ELSE NULL
					END AS RenderedRange
			) uhr
;

DECLARE @CrossListing TABLE (CourseId int, nam nvarchar(max))
INSERT INTO @CrossListing
SELECT mr.Id, dbo.ConcatWithSep_Agg('', '', CONCAT(s.SubjectCode, '' '', c2.CourseNumber)) FROM @modelRoot mr
	INNER JOIN CourseRelatedCourse AS crc on crc.CourseId = mr.Id
	INNER JOIN Course AS c2 on crc.Related_CourseId = c2.Id
	INNER JOIN Subject AS s on c2.SubjectId = s.Id
	GROUP BY mr.Id


SELECT
	mr.Id AS [Value],
	CONCAT (
		dbo.fnHtmlOpenTag(@summaryWrapperTag,
			CONCAT(
				dbo.fnHtmlAttribute(@classAttrib, ''custom-course-summary-context-wrapper''), @space,
				dbo.fnHtmlAttribute(''data-resultset-course-family-count'', mrd.FamilyCount), @space,
				dbo.fnHtmlAttribute(''data-course-has-other-versions'', CASE
					WHEN mrd.FamilyCount > 1 THEN ''true''
					ELSE ''false''
					END
				)
			)
		),
			dbo.fnHtmlOpenTag(
				@summaryWrapperTag,
				CONCAT(
					dbo.fnHtmlAttribute(@classAttrib, ''container-fluid course-summary-wrapper''), @space,
					dbo.fnHtmlAttribute(''data-course-id'', mrd.Id), @space,
					dbo.fnHtmlAttribute(''data-base-course-id'', mrd.BaseCourseId), @space,
					dbo.fnHtmlAttribute(''data-process-action-type'', mrd.ProcessActionType), @space,
					dbo.fnHtmlAttribute(''data-status-base'', mrd.StatusBase), @space,
					dbo.fnHtmlAttribute(''data-status-alias'', mrd.StatusAlias), @space
				)
			),
				--Course Title row (Course subject code, number, and title)
				dbo.fnHtmlOpenTag(@rowTag,
						concat(
							dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-title-header'')),
							dbo.fnHtmlAttribute(@styleAttrib, ''font-weight: inherit'')
						)
					),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						-- course subject
						dbo.fnHtmlOpenTag(@boldDataElementTag, CONCAT(
								dbo.fnHtmlAttribute(@classAttrib, ''course-subject''),
								@space,
								dbo.fnHtmlAttribute(''title'', dbo.fnHtmlEntityEscape(mrd.SubjectTitle))
							)
						),
							mrd.SubjectCode,
						dbo.fnHtmlCloseTag(@boldDataElementTag), @space,
						-- course number
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-number'')), 
							mrd.CourseNumber, 
						-- cid number
						CASE 
							WHEN mrd.CID is not null THEN CONCAT(
								@space,
								@openParan,
								dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-id-number-label'')),
									''C-ID:'', @space,
								dbo.fnHtmlCloseTag(@boldDataElementTag),
								dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-id-number-value'')),
									mrd.CID,
								dbo.fnHtmlCloseTag(@boldDataElementTag),
								@closeParan	
							)
							END,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- course title row
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-title-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						-- course title
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-title'')),
							mrd.CourseTitle,
						dbo.fnHtmlCloseTag(@boldDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- crosslisted row row
				CASE 
					WHEN cl.nam IS NULL
					THEN ''''
					ELSE CONCAT(
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''crosslisted-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						-- Titles
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''crosslisted'')),
							CONCAT(''Same as: '', cl.nam),
						dbo.fnHtmlCloseTag(@boldDataElementTag),
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag))
				END,
				-- hour-units row
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''unit-hours-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						CASE
							--WHEN mrd.IsCreditCourse = 1 AND unithr.RenderedRange IS NOT NULL 
							WHEN unithr.RenderedRange IS NOT NULL
								THEN CONCAT(
									dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''unit-hours-wrapper'')),
										dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''unit-hours-label'')),
											''Units'',
											@colon,
											@space,
										dbo.fnHtmlCloseTag(@boldDataElementTag),
										dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''unit-hours-range'')),
											unithr.RenderedRange,
										dbo.fnHtmlCloseTag(@dataElementTag),
									dbo.fnHtmlCloseTag(@dataElementTag), @space
								)
							ELSE @empty
						END,						
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- requisites row
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-requisites-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''course-requisites-column''))),
						CASE
							WHEN mrd.RequisiteCatalogView IS NOT NULL 
								THEN mrd.RequisiteCatalogView
							ELSE @empty
						END,
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- transfer csu/cu row
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''transfer-status-row''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''transfer-status-column''))),
						CASE
							WHEN mrd.TransferApps IS NOT NULL OR mrd.TransferLimitations IS NOT NULL 
								THEN CONCAT(
									dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''transfer-status-label'')),
										''Transfers to:'',
									dbo.fnHtmlCloseTag(@boldDataElementTag),
									@space,
									dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''transfer-status-value'')),
										CASE
											WHEN mrd.TransferApps IS NOT NULL AND mrd.TransferLimitations IS NOT NULL 
												THEN CONCAT(mrd.TransferApps, '' - '', mrd.TransferLimitations)
											WHEN mrd.TransferApps IS NOT NULL THEN mrd.TransferApps
											WHEN mrd.TransferLimitations IS NOT NULL THEN mrd.TransferLimitations
											ELSE @empty
											END,
									dbo.fnHtmlCloseTag(@dataElementTag)
								)
							ELSE @empty
						END,
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag),

				-- course desciprtion row
				CASE
					WHEN mrd.CourseDescription IS NOT NULL 
						THEN CONCAT(
							dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-description-row''))),
								dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''course-description-column''))),
									dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''course-description'')),
										mrd.CourseDescription,
									dbo.fnHtmlCloseTag(@blockTag),
								dbo.fnHtmlCloseTag(@columnTag),
							dbo.fnHtmlCloseTag(@rowTag)
						)
					ELSE @empty
				END,

				-- lec-lab row
				dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-units-hours-header''))),
					dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
						-- label
						CASE 
							WHEN lecthr.RenderedRange IS NOT NULL or labhr.RenderedRange IS NOT NULL
								THEN CONCAT(dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-lab-lec-label'')),
									''Hours:'', @space,
									dbo.fnHtmlCloseTag(@dataElementTag)
								)
							ELSE @empty
						END,
						-- lecture
						CASE
							WHEN lecthr.RenderedRange IS NOT NULL THEN CONCAT(
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-hours-wrapper'')),
									dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-hours-range'')),
										lecthr.RenderedRange,
									dbo.fnHtmlCloseTag(@dataElementTag),
									dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-hours-label'')),
										@space, ''Lecture.'',
									dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
							ELSE CONCAT(@openComment, ''No lecture hours'', @closeComment)
						END,
						-- lab
						CASE
							WHEN labhr.RenderedRange IS NOT NULL THEN CONCAT(
								@space,
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lab-hours-wrapper'')),
									dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lab-hours-range'')),
										labhr.RenderedRange,
									dbo.fnHtmlCloseTag(@dataElementTag),
									dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lab-hours-label'')),
										@space, ''Lab.'',
									dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlCloseTag(@dataElementTag)
							)
							ELSE CONCAT(@openComment, ''No lab hours'', @closeComment)
						END,
						CASE
							WHEN lecthr.RenderedRange IS NOT NULL OR
								labhr.RenderedRange IS NOT NULL THEN @space
							ELSE @empty
						END,
					dbo.fnHtmlCloseTag(@columnTag),
				dbo.fnHtmlCloseTag(@rowTag), -- end of lec-lab row
			dbo.fnHtmlCloseTag(@summaryWrapperTag),
		dbo.fnHtmlCloseTag(@summaryWrapperTag)
	) AS [Text]
FROM @modelRoot mr
	INNER JOIN @modelRootData mrd ON mr.Id = mrd.Id
	LEFT OUTER JOIN @unitHourRanges unithr ON (mr.Id = unithr.CourseId AND unithr.UnitHourTypeId = 1)
	LEFT OUTER JOIN @unitHourRanges lecthr ON (mr.Id = lecthr.CourseId AND lecthr.UnitHourTypeId = 2)
	LEFT OUTER JOIN @unitHourRanges labhr ON (mr.Id = labhr.CourseId AND labhr.UnitHourTypeId = 3)
	INNER JOIN @elementClasses ec3 ON ec3.Id = 1 --1 = ThreeColumn
	INNER JOIN @elementClasses ec2shorter ON ec2shorter.Id = 2 --2 = TwoColumnShorterRight
	INNER JOIN @elementClasses ec2short ON ec2short.Id = 3 --3 = TwoColumnShortRight
	INNER JOIN @elementClasses ecfw ON ecfw.Id = 4 --4 = FullWidthRow
	LEFT JOIN @CrossListing AS cl on cl.CourseId = mr.Id

ORDER BY mr.InsertOrder
;
--#endregion main rendering

--#endregion template query
'
WHERE Id = 1