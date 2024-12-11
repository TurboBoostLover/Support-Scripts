USE [nu];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14275';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog';
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
UPDATE OutputModelClient
SET ModelQuery = '

--#region model query

--#region model tables
declare @entityList_internal table (
	InsertOrder int identity (1, 1),
	Id int primary key
);

declare @entityRootData table (
	Id int primary key,
	Variable bit,
	MinCreditHour decimal(16, 3),
	MaxCreditHour decimal(16, 3),
	MinLectureHour decimal(16, 3),
	MaxLectureHour decimal(16, 3),
	MinLabHour decimal(16, 3),
	MaxLabHour decimal(16, 3),
	TransferStatus nvarchar(500),
	IsGenEd bit,
	IsRepeatable bit,
	MaxRepeatsAllowed nvarchar(100),
	UnitsRepeatLimit decimal(16, 3),
	GradeOption nvarchar(100),
	IsCrossListed bit,
	Cid nvarchar(max),
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
	Duration nvarchar(max)
);

declare @entityGenEdAreas table (
	InsertOrder int identity(1, 1),
	CourseId int,
	GeneralEducationId int,
	Title nvarchar(1000),
	primary key (CourseId, GeneralEducationId),
	index ixEntityGenEdAreas_InsertOrder nonclustered (InsertOrder)
);

declare @entityGenEdElements table (
	InsertOrder int identity(1, 1),
	CourseId int,
	GeneralEducationId int,
	GeneralEducationElementId int,
	Code nvarchar(1000),
	Title nvarchar(1000),
	primary key (CourseId, GeneralEducationElementId),
	index ixEntityGenEdElements_Area nonclustered (GeneralEducationId),
	index ixEntityGenEdElements_InsertOrder nonclustered (InsertOrder)
);

declare @entityRelatedCourses table (
	InsertOrder int identity(1, 1),
	CourseId int,
	RelatedCourseId int,
	CourseIdentifier nvarchar(25),
	primary key (CourseId, RelatedCourseId),
	index ixEntityRelatedCourses_InsertOrder nonclustered (InsertOrder)
);

declare @effectiveTermRanges table (
	Id int primary key,
	NextId int index ixEffectiveTermRange_NextId nonclustered,
	NextCourseProcessActionType nvarchar(50),
	NextStatusBase nvarchar(50),
	NextStatusAlias nvarchar(50),
	--Semester.Title is currently 150 chars, but I do not want to have to come back
	--in here and fix this if that ever gets expanded, so just using nvarchar(max)
	EffectiveTermRangeStart nvarchar(max),
	EffectiveTermRangeEnd nvarchar(max),
	TermStartDate Datetime
);

--#endregion model tables

INSERT INTO @entityList_internal
(Id)
SELECT
	Id
FROM @entityList;

--#region entity root data
INSERT INTO @entityRootData
(Id, Variable, MinCreditHour, MaxCreditHour, MinLectureHour, MaxLectureHour, MinLabHour, MaxLabHour,
TransferStatus, IsGenEd, IsRepeatable, MaxRepeatsAllowed, UnitsRepeatLimit, GradeOption, IsCrossListed,
Cid, FamilyCount, BaseCourseId, ProcessActionType, StatusBase, StatusAlias, SubjectTitle, SubjectCode,
CourseNumber, CourseTitle, IsCreditCourse, CourseDescription, Duration)
	SELECT
		c.Id
	   ,cd.Variable
	   ,cd.MinCreditHour
	   ,cd.MaxCreditHour
	   ,cd.MinLectureHour
	   ,cd.MaxLectureHour
	   ,cd.MinLabHour
	   ,cd.MaxLabHour
	   ,CASE
			WHEN ts.TransferStatusCode = ''A'' THEN ''UC/CSU''
			WHEN ts.TransferStatusCode = ''B'' THEN ''CSU''
			ELSE NULL
		END AS TransferStatus
	   ,CAST(CASE cyn.YesNo30Id
			WHEN 1 THEN 1
			ELSE 0
		END AS BIT) AS IsGenEd
	   ,CAST(CASE cyn.YesNo04Id
			WHEN 1 THEN 1
			ELSE 0
		END AS BIT) AS IsRepeatable
	   ,rl.Title AS MaxRepeatsAllowed
	   ,cp.UnitsRepeatLimit
	   ,CASE
			--2 = Pass/No Pass Only
			WHEN cd.GradeOptionId = 2 THEN gopt.[Description]
			ELSE NULL
		END AS GradeOption
	   ,CAST(CASE cyn.YesNo03Id
			WHEN 1 THEN 1
			ELSE 0
		END AS BIT) AS IsCrossListed
	   ,gmt.TextMax07 AS Cid
	   ,COUNT(*) OVER (PARTITION BY c.BaseCourseId) AS FamilyCount
	   ,c.BaseCourseId
	   ,dbo.fnTrimWhitespace(pat.Title) AS ProcessActionType
	   ,sb.Title AS StatusBase
	   ,sa.Title AS StatusAlias
	   ,s.Title AS SubjectTitle
	   ,s.SubjectCode
	   ,c.CourseNumber
	   ,c.Title AS CourseTitle
	   ,
		--null values for the credit status are assumed to be Credit Courses
		--If this causes a non-credit course to be treated as a credit course, then
		--the non-credit value needs to be set for CB04 on that course
		CASE cs.CreditStatusCode
			WHEN ''N'' THEN 0
			ELSE 1
		END AS IsCreditCourse
	   ,c.[Description] AS CourseDescription,
		 ccap.Duration AS Duration
	FROM Course c
		INNER JOIN @entityList_internal eli ON c.Id = eli.Id
		--Extension tables
		LEFT OUTER JOIN CourseDescription cd ON c.Id = cd.CourseId
		LEFT OUTER JOIN CourseCBCode ccc ON c.Id = ccc.CourseId
		LEFT OUTER JOIN CourseYesNo cyn ON c.Id = cyn.CourseId
		LEFT OUTER JOIN CourseProposal cp ON c.Id = cp.CourseId
		LEFT OUTER JOIN GenericMaxText gmt ON c.Id = gmt.CourseId
		LEFT OUTER JOIN CourseAttribute ca ON c.Id = ca.CourseId
		LEFT OUTER JOIN GenericBit gb ON c.Id = gb.CourseId
		LEFT OUTER JOIN Generic1000Text g1kt ON c.Id = g1kt.CourseId
		--Look-ups and transforms
		LEFT OUTER JOIN TransferApplication ta ON cd.TransferAppsId = ta.Id
		LEFT OUTER JOIN CB05 cb05 ON ccc.CB05Id = cb05.Id
		LEFT OUTER JOIN CourseCapstone ccap on ccap.CourseId = c.Id
		CROSS APPLY (
				SELECT
					--They are currently using the legacy backing store for this field
					--instead of the new seeded backing store; put this coalesce in here
					--as a bit of future-proofing for when they are eventually migrated to
					--the new backing store
					COALESCE(cb05.Code, ta.Title) AS TransferStatusCode
			) ts
		LEFT OUTER JOIN RepeatLimit rl ON cp.RepeatlimitId = rl.Id
		LEFT OUTER JOIN GradeOption gopt ON cd.GradeOptionId = gopt.Id
		LEFT OUTER JOIN ProposalType pt ON c.ProposalTypeId = pt.Id
		LEFT OUTER JOIN ProcessActionType pat ON pt.ProcessActionTypeId = pat.Id
		LEFT OUTER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
		LEFT OUTER JOIN StatusBase sb ON sa.StatusBaseId = sb.Id
		LEFT OUTER JOIN [Subject] s ON c.SubjectId = s.Id
		LEFT OUTER JOIN CourseCreditStatus ccs ON ca.CourseCreditStatusId = ccs.Id
		LEFT OUTER JOIN CB04 cb04 ON ccc.CB04Id = cb04.Id
		CROSS APPLY (
				SELECT
					--They are currently using the legacy backing store for this field
					--instead of the new seeded backing store; put this coalesce in here
					--as a bit of future-proofing for when they are eventually migrated to
					--the new backing store
					COALESCE(cb04.Code, ccs.Code) AS CreditStatusCode
			) cs
	ORDER BY eli.InsertOrder;
--#endregion entity root data

--#region entity gen ed areas
/*INSERT INTO @entityGenEdAreas
(CourseId, GeneralEducationId, Title)
	SELECT
		eli.Id AS CourseId
	   ,ge.Id AS GeneralEducationId
	   ,ge.Title
	FROM GeneralEducation ge
		CROSS JOIN @entityList_internal eli
	WHERE EXISTS (
		SELECT TOP 1
			1
		FROM CourseGeneralEducation cge
			INNER JOIN GeneralEducationElement gee ON cge.GeneralEducationElementId = gee.Id
		WHERE cge.CourseId = eli.Id
		AND gee.GeneralEducationId = ge.Id
        /*not showing GE area title if the Gen Ed Element doesn''t have approved checkbox checked*/
		and cge.Bit02 = 1
	)
	--Exclude the Transfer gen ed areas
	AND (ge.GeneralEducationGroupId IS NULL
	OR ge.GeneralEducationGroupId <> 1)
	ORDER BY eli.InsertOrder, ge.SortOrder, ge.Id;*/
--#endregion entity gen ed areas

--#region entity gen ed elements
/*INSERT INTO @entityGenEdElements
(CourseId, GeneralEducationId, GeneralEducationElementId, Code, Title)
	SELECT
		cge.CourseId
	   ,gee.GeneralEducationId
	   ,cge.GeneralEducationElementId
	   ,COALESCE(gee.Text, gee.Title) AS Code
	   ,gee.Title
	FROM (
		--Sometimes there is bad data where the same GeneralEducationElementId is in the table more than once for the same course
		--This distinct clause should take care of that
		--The performance impact should be negligible because it is a distinct over two int columns
		SELECT DISTINCT
			cge.CourseId
		   ,cge.GeneralEducationElementId
		FROM CourseGeneralEducation cge
			INNER JOIN @entityList_internal eli ON cge.CourseId = eli.Id
		/*They only want to show GE areas that have "approved" checked*/
		where cge.Bit02 = 1
	) cge
		INNER JOIN GeneralEducationElement gee ON cge.GeneralEducationElementId = gee.Id
	ORDER BY cge.CourseId, gee.GeneralEducationId, gee.SortOrder;*/
--#endregion entity gen ed elements

--#region entity related courses
INSERT INTO @entityRelatedCourses
(CourseId, RelatedCourseId, CourseIdentifier)
	SELECT
		crc.CourseId
	   ,crc.RelatedCourseId
	   ,CONCAT(s.SubjectCode, '' '', c.CourseNumber) AS CourseIdentifier
	FROM CourseRelatedCourse crc
		INNER JOIN @entityList_internal eli ON crc.CourseId = eli.Id
		INNER JOIN Course c ON crc.RelatedCourseId = c.Id
		INNER JOIN [Subject] s ON c.SubjectId = s.Id
	ORDER BY s.SubjectCode, c.CourseNumber, c.Id;
--#endregion entity related courses

--#region effective term ranges
WITH CourseFamilies
AS
(
	--If multiple courses in the same family are included in @entityList_Internal, then we will get duplicates from this CTE
	--Using distinct to filter them out because it is a single column and that should be more efficient than an exists in this case
	SELECT DISTINCT
		c2.Id
	FROM @entityList_Internal eli
		INNER JOIN Course c ON eli.Id = c.Id
		--We want to pull in both the courses that are in @entityList_Internal and the other courses in their families
		--By just joining in c2 on BaseCourseId and not intentionally filtering out by c.Id <> c2.Id, that is what we will get
		INNER JOIN Course c2 ON c.BaseCourseId = c2.BaseCourseId
),
ConsideredCourses
AS
(
	SELECT
		c.Id
	   ,c.BaseCourseId
	   ,c.EntityTitle
	   ,sem.Title AS TermTitle
	   ,sem.TermStartDate
	   ,sem.TermEndDate
	   ,sb.Title AS StatusBase
	   ,sa.Title AS StatusAlias
	   ,dbo.fnTrimWhitespace(pat.Title) AS ProcessActionType
	   ,pat.Id AS ProcessActionTypeId
	FROM Course c
		INNER JOIN CourseFamilies cf ON c.Id = cf.Id
		INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
		INNER JOIN StatusBase sb ON sa.StatusBaseId = sb.Id
		INNER JOIN ProposalType pt ON c.ProposalTypeId = pt.Id
		INNER JOIN ProcessActionType pat ON pt.ProcessActionTypeId = pat.Id
		INNER JOIN CourseProposal cp ON c.Id = cp.CourseId
		INNER JOIN [Semester] sem ON cp.SemesterId = sem.Id
	WHERE c.Active = 1
	AND sa.StatusBaseId IN (1, 2, 5) --StatusBaseId 1 = Active, 2 = Approved, 5 = Historical
	AND sem.TermStartDate IS NOT NULL
	AND sem.TermEndDate IS NOT NULL
)

INSERT INTO @effectiveTermRanges
(Id, NextId, NextCourseProcessActionType, NextStatusBase, NextStatusAlias, EffectiveTermRangeStart, EffectiveTermRangeEnd, TermStartDate)
	SELECT
		cc.Id
	   ,nc.Id AS NextId
	   ,nc.ProcessActionType AS NextCourseProcessActionType
	   ,nc.StatusBase AS NextStatusBase
	   ,nc.StatusAlias AS NextStatusAlias
	   ,cc.TermTitle AS EffectiveTermRangeStart
	   ,nc.TermTitle AS EffectiveTermRangeEnd
	   ,cc.TermStartDate
	FROM ConsideredCourses cc
		OUTER APPLY (
				SELECT TOP 1
					*
				FROM ConsideredCourses cc2
				WHERE cc.BaseCourseId = cc2.BaseCourseId
				AND cc2.TermStartDate > cc.TermStartDate
				ORDER BY cc2.TermStartDate, cc2.Id
			) nc
--#endregion effective term ranges

--#region compose model
SELECT
	eli.Id
   ,m.Model
FROM @entityList_internal eli
	CROSS APPLY (
			SELECT
				(
					SELECT
						*
					FROM @entityRootData erd
					WHERE erd.Id = eli.Id
					FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
				)
				RootData
		) erd
	CROSS APPLY (
			SELECT
				(
					SELECT
						*
					FROM @entityGenEdAreas egea
					WHERE egea.CourseId = eli.Id
					ORDER BY egea.InsertOrder
					FOR JSON PATH
				)
				GenEdAreas
		) egea
	CROSS APPLY (
			SELECT
				(
					SELECT
						*
					FROM @entityGenEdElements egee
					WHERE egee.CourseId = eli.Id
					ORDER BY egee.InsertOrder
					FOR JSON PATH
				)
				GenEdElements
		) egee
	CROSS APPLY (
			SELECT
				(
					SELECT
						*
					FROM @entityRelatedCourses erc
					WHERE erc.CourseId = eli.Id
					ORDER BY erc.InsertOrder
					FOR JSON PATH
				)
				RelatedCourses
		) erc
	CROSS APPLY (
			SELECT
				(
					SELECT
						*
					FROM @effectiveTermRanges etr
					WHERE etr.Id = eli.Id
					FOR JSON PATH
				)
				EffectiveTermRanges
		) etr
	CROSS APPLY (
			SELECT
				(
					SELECT
						eli.InsertOrder
					   ,JSON_QUERY(erd.RootData) AS RootData
					   ,JSON_QUERY(egea.GenEdAreas) AS GenEdAreas
					   ,JSON_QUERY(egee.GenEdElements) AS GenEdElements
					   ,JSON_QUERY(erc.RelatedCourses) AS RelatedCourses
					   ,JSON_QUERY(etr.EffectiveTermRanges) AS EffectiveTermRanges
					FOR JSON PATH
				)
				Model
		) m
ORDER BY eli.InsertOrder;
--#endregion compose model

--#endregion model query


'
WHERE Id = 1

UPDATE OutputTemplateClient
SET TemplateQuery = '

--#region template query

declare @hoursScale int = 2;
declare @hoursDecimalFormat nvarchar(10) = concat(''F'', @hoursScale);

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
	RootData nvarchar(max),
	GenEdAreas nvarchar(max),
	GenEdElements nvarchar(max),
	RelatedCourses nvarchar(max),
	EffectiveTermRanges nvarchar(max)
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
	TransferStatus nvarchar(500),
	IsGenEd bit,
	IsRepeatable bit,
	MaxRepeatsAllowed nvarchar(100),
	UnitsRepeatLimit decimal(16, 3),
	GradeOption nvarchar(100),
	IsCrossListed bit,
	Cid nvarchar(max),
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
	Duration nvarchar(max)
);

declare @modelGenEdAreas table (
	InsertOrder int,
	CourseId int,
	GeneralEducationId int,
	Title nvarchar(1000),
	primary key (CourseId, GeneralEducationId),
	index ixModelGenEdAreas_InsertOrder nonclustered (InsertOrder)
);

declare @modelGenEdElements table (
	InsertOrder int,
	CourseId int,
	GeneralEducationId int,
	GeneralEducationElementId int,
	Code nvarchar(1000),
	Title nvarchar(1000),
	primary key (CourseId, GeneralEducationElementId),
	index ixEntityGenEdElements_Area nonclustered (GeneralEducationId),
	index ixEntityGenEdElements_InsertOrder nonclustered (InsertOrder)
);

declare @modelRelatedCourses table (
	InsertOrder int,
	CourseId int,
	RelatedCourseId int,
	CourseIdentifier nvarchar(25),
	primary key (CourseId, RelatedCourseId),
	index ixEntityRelatedCourses_InsertOrder nonclustered (InsertOrder)
);

declare @modelEffectiveTermRanges table (
	Id int primary key,
	NextId int index ixEffectiveTermRange_NextId nonclustered,
	NextCourseProcessActionType nvarchar(50),
	NextStatusBase nvarchar(50),
	NextStatusAlias nvarchar(50),
	--Semester.Title is currently 150 chars, but I do not want to have to come back
	--in here and fix this if that ever gets expanded, so just using nvarchar(max)
	EffectiveTermRangeStart nvarchar(max),
	EffectiveTermRangeEnd nvarchar(max)
);

--#endregion model tables

--#region parse model

--#region parse model root
INSERT INTO @modelRoot
(Id, InsertOrder, RootData, GenEdAreas, GenEdElements, RelatedCourses, EffectiveTermRanges)
	SELECT
		em.[Key] AS Id
	   ,m.InsertOrder
	   ,m.RootData
	   ,m.GenEdAreas
	   ,m.GenEdElements
	   ,m.RelatedCourses
	   ,m.EffectiveTermRanges
	FROM @entityModels em
		CROSS APPLY OPENJSON(em.[Value])
			WITH (
			InsertOrder INT ''$.InsertOrder'',
			RootData NVARCHAR(MAX) ''$.RootData'' AS JSON,
			GenEdAreas NVARCHAR(MAX) ''$.GenEdAreas'' AS JSON,
			GenEdElements NVARCHAR(MAX) ''$.GenEdElements'' AS JSON,
			RelatedCourses NVARCHAR(MAX) ''$.RelatedCourses'' AS JSON,
			EffectiveTermRanges NVARCHAR(MAX) ''$.EffectiveTermRanges'' AS JSON
			) m;
--#endregion parse model root

--#region parse model root data
INSERT INTO @modelRootData
(Id, Variable, MinCreditHour, MaxCreditHour, MinLectureHour, MaxLectureHour,
MinLabHour, MaxLabHour, TransferStatus, IsGenEd, IsRepeatable, MaxRepeatsAllowed,
UnitsRepeatLimit, GradeOption, IsCrossListed, Cid, FamilyCount, BaseCourseId,
ProcessActionType, StatusBase, StatusAlias, SubjectTitle, SubjectCode,
CourseNumber, CourseTitle, IsCreditCourse, CourseDescription, Duration)
	SELECT
		rd.Id
	   ,rd.Variable
	   ,rd.MinCreditHour
	   ,rd.MaxCreditHour
	   ,rd.MinLectureHour
	   ,rd.MaxLectureHour
	   ,rd.MinLabHour
	   ,rd.MaxLabHour
	   ,rd.TransferStatus
	   ,rd.IsGenEd
	   ,rd.IsRepeatable
	   ,rd.MaxRepeatsAllowed
	   ,rd.UnitsRepeatLimit
	   ,rd.GradeOption
	   ,rd.IsCrossListed
	   ,rd.Cid
	   ,rd.FamilyCount
	   ,rd.BaseCourseId
	   ,rd.ProcessActionType
	   ,rd.StatusBase
	   ,rd.StatusAlias
	   ,rd.SubjectTitle
	   ,rd.SubjectCode
	   ,rd.CourseNumber
	   ,rd.CourseTitle
	   ,rd.IsCreditCourse
	   ,rd.CourseDescription
		 ,rd.Duration
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
			TransferStatus NVARCHAR(500) ''$.TransferStatus'',
			IsGenEd BIT ''$.IsGenEd'',
			IsRepeatable BIT ''$.IsRepeatable'',
			MaxRepeatsAllowed NVARCHAR(100) ''$.MaxRepeatsAllowed'',
			UnitsRepeatLimit DECIMAL(16, 3) ''$.UnitsRepeatLimit'',
			GradeOption NVARCHAR(100) ''$.GradeOption'',
			IsCrossListed BIT ''$.IsCrossListed'',
			Cid NVARCHAR(MAX) ''$.Cid'',
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
			Duration NVARCHAR(MAX) ''$.Duration''
			) rd;
--#endregion parse model root data

--#region requisites compose

declare @requisitesCurriculumPresentationTitle nvarchar(255) = ''Course Requisites Catalog Summary'';
declare @requisitesPresentationId int = (
	SELECT
		Id
	FROM CurriculumPresentation
	WHERE Title = @requisitesCurriculumPresentationTitle
);

declare @requisitesEntityList integers;

INSERT INTO @requisitesEntityList
(Id)
	SELECT
		mr.Id
	FROM @modelRoot mr
	ORDER BY mr.InsertOrder;

DROP TABLE IF EXISTS #renderedRequisites;

declare @renderedRequisites table (
	CourseId int primary key,
	RenderedRequisites nvarchar(max)
);

create table #renderedRequisites (
	[Value] int primary key,
	[Text] nvarchar(max)
);

EXEC upRenderCurriculumPresentation @curriculumPresentationId = @requisitesPresentationId
								   ,@outputFormatId = 5
								   ,@entityTypeId = 1
								   ,@entityList = @requisitesEntityList
								   ,@resultTable = ''#renderedRequisites'';

INSERT INTO @renderedRequisites
(CourseId, RenderedRequisites)
	SELECT
		rr.[Value] AS CourseId
	   ,rr.[Text] AS RenderedRequisites
	FROM #renderedRequisites rr;

DROP TABLE IF EXISTS #renderedRequisites;

--#endregion requisites compose

--#region parse model gen ed areas
INSERT INTO @modelGenEdAreas
(InsertOrder, CourseId, GeneralEducationId, Title)
	SELECT
		gea.InsertOrder
	   ,gea.CourseId
	   ,gea.GeneralEducationId
	   ,gea.Title
	FROM @modelRoot mr
		CROSS APPLY OPENJSON(mr.GenEdAreas)
			WITH (
			InsertOrder INT ''$.InsertOrder'',
			CourseId INT ''$.CourseId'',
			GeneralEducationId INT ''$.GeneralEducationId'',
			Title NVARCHAR(1000) ''$.Title''
			) gea;
--#endregion parse model gen ed areas

--#region parse model gen ed elements
INSERT INTO @modelGenEdElements
(InsertOrder, CourseId, GeneralEducationId, GeneralEducationElementId, Code, Title)
	SELECT
		gee.InsertOrder
	   ,gee.CourseId
	   ,gee.GeneralEducationId
	   ,gee.GeneralEducationElementId
	   ,gee.Code
	   ,gee.Title
	FROM @modelRoot mr
		CROSS APPLY OPENJSON(mr.GenEdElements)
			WITH (
			InsertOrder INT ''$.InsertOrder'',
			CourseId INT ''$.CourseId'',
			GeneralEducationId INT ''$.GeneralEducationId'',
			GeneralEducationElementId INT ''$.GeneralEducationElementId'',
			Code NVARCHAR(1000) ''$.Code'',
			Title NVARCHAR(1000) ''$.Title''
			) gee;
--#endregion parse model gen ed elements

--#region parse model related courses
INSERT INTO @modelRelatedCourses
(InsertOrder, CourseId, RelatedCourseId, CourseIdentifier)
	SELECT
		rc.InsertOrder
	   ,rc.CourseId
	   ,rc.RelatedCourseId
	   ,rc.CourseIdentifier
	FROM @modelRoot mr
		CROSS APPLY OPENJSON(mr.RelatedCourses)
			WITH (
			InsertOrder INT ''$.InsertOrder'',
			CourseId INT ''$.CourseId'',
			RelatedCourseId INT ''$.RelatedCourseId'',
			CourseIdentifier NVARCHAR(25) ''$.CourseIdentifier''
			) rc;
--#endregion parse model related courses

--#region parse model effective term ranges
INSERT INTO @modelEffectiveTermRanges
(Id, NextId, NextCourseProcessActionType, NextStatusBase, NextStatusAlias, EffectiveTermRangeStart, EffectiveTermRangeEnd)
	SELECT
		etr.Id
	   ,etr.NextId
	   ,etr.NextCourseProcessActionType
	   ,etr.NextStatusBase
	   ,etr.NextStatusAlias
	   ,etr.EffectiveTermRangeStart
	   ,etr.EffectiveTermRangeEnd
	FROM @modelRoot mr
		CROSS APPLY OPENJSON(mr.EffectiveTermRanges)
			WITH (
			Id INT ''$.Id'',
			NextId INT ''$.NextId'',
			NextCourseProcessActionType NVARCHAR(50) ''$.NextCourseProcessActionType'',
			NextStatusBase NVARCHAR(50) ''$.NextStatusBase'',
			NextStatusAlias NVARCHAR(50) ''$.NextStatusAlias'',
			EffectiveTermRangeStart NVARCHAR(MAX) ''$.EffectiveTermRangeStart'',
			EffectiveTermRangeEnd NVARCHAR(MAX) ''$.EffectiveTermRangeEnd''
			) etr;
--#endregion parse model effective term ranges

--#endregion parse model

--#region additional rendering tables
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
				   ,1 AS RenderIfZero
				   ,mrd.MinCreditHour AS MinVal
				   ,mrd.MaxCreditHour AS MaxVal
				UNION ALL
				SELECT
					2 AS UnitHourTypeId
				   ,''Lecture'' AS TypeName
				   ,0 AS RenderIfZero
				   ,mrd.MinLectureHour AS MinVal
				   ,mrd.MaxLectureHour AS MaxVal
				UNION ALL
				SELECT
					3 AS UnitHourTypeId
				   ,''Lab'' AS TypeName
				   ,0 AS RenderIfZero
				   ,mrd.MinLabHour AS MinVal
				   ,mrd.MaxLabHour AS MaxVal
			) uht
		CROSS APPLY (
				SELECT
					CASE
						WHEN uht.MinVal IS NOT NULL AND
							uht.MaxVal IS NOT NULL AND
							uht.MinVal <> uht.MaxVal THEN CONCAT(
							FORMAT(uht.MinVal, @hoursDecimalFormat), ''-'', FORMAT(uht.MaxVal, @hoursDecimalFormat)
							)
						WHEN uht.MinVal IS NOT NULL AND
							(uht.MinVal > 0 OR
							uht.RenderIfZero = 1) THEN FORMAT(uht.MinVal, @hoursDecimalFormat)
						ELSE NULL
					END AS RenderedRange
			) uhr
;
--#endregion units/house compose

--#region gen ed compose
INSERT INTO @renderedGenEd
(CourseId, CombinedAreas)
	SELECT
		mr.Id AS CourseId
	   ,gea.CombinedAreas
	FROM @modelRoot mr
		CROSS APPLY (
				SELECT
					dbo.ConcatWithSepOrdered_Agg(@outerListDelimter, egea.InsertOrder, gea.ComposedArea) AS CombinedAreas
				FROM @modelGenEdAreas egea
					CROSS APPLY (
							SELECT
								dbo.ConcatWithSepOrdered_Agg(@innerListDelimiter, egee.InsertOrder, cgee.ComposedElement) AS CombinedElements
							FROM @modelGenEdElements egee
								CROSS APPLY (
										SELECT
											CONCAT(
											dbo.fnHtmlOpenTag(@dataElementTag,
											CONCAT(
											dbo.fnHtmlAttribute(@classAttrib, ''gen-ed-element-code''), @space,
											dbo.fnHtmlAttribute(@titleAttrib, dbo.fnHtmlEntityEscape(egee.Title))
											)
											),
											egee.Code,
											dbo.fnHtmlCloseTag(@dataElementTag)
											) AS ComposedElement
									) cgee
							WHERE egee.CourseId = mr.Id
							AND egee.GeneralEducationId = egea.GeneralEducationId
						) gee
					CROSS APPLY (
							SELECT
								CONCAT(
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''gen-ed-area'')),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''gen-ed-area-label'')),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''gen-ed-area-label-open-paren'')),
								''('',
								dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''gen-ed-area-label-text'')),
								egea.Title,
								dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''gen-ed-area-label-close-paren'')),
								'')'',
								dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''gen-ed-area-label-delimiter'')),
								'':'', @space,
								dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''gen-ed-element-list'')),
								gee.CombinedElements,
								dbo.fnHtmlCloseTag(@dataElementTag),
								dbo.fnHtmlCloseTag(@dataElementTag)
								) AS ComposedArea
						) gea
				WHERE egea.CourseId = mr.Id
			) gea;
--#endregion gen ed compose

--#region cross listings compose
INSERT INTO @renderedCrossListings
(CourseId, CombinedCrossListings)
	SELECT
		mr.Id AS CourseId
	   ,ccl.CombinedCrossListings
	FROM @modelRoot mr
		CROSS APPLY (
				SELECT
					dbo.ConcatWithSepOrdered_Agg(@innerListDelimiter, mrc.InsertOrder, cci.ComposedCourseIdentifier) AS CombinedCrossListings
				FROM @modelRelatedCourses mrc
					CROSS APPLY (
							SELECT
								CONCAT(
								dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''cross-listed-course-list-entry'')),
								mrc.CourseIdentifier,
								dbo.fnHtmlCloseTag(@dataElementTag)
								) ComposedCourseIdentifier
						) cci
				WHERE mrc.CourseId = mr.Id
			) ccl;
--#endregion cross listings compose

--#region main rendering
SELECT
	mr.Id AS [Value]
   ,CONCAT(
	dbo.fnHtmlOpenTag(@summaryWrapperTag,
	CONCAT(
	dbo.fnHtmlAttribute(@classAttrib, ''custom-course-summary-context-wrapper''), @space,
	dbo.fnHtmlAttribute(''data-resultset-course-family-count'', mrd.FamilyCount), @space,
	dbo.fnHtmlAttribute(''data-course-has-other-versions'', CASE
		WHEN mrd.FamilyCount > 1 THEN ''true''
		ELSE ''false''
	END)
	)
	),
	dbo.fnHtmlOpenTag(
		@summaryWrapperTag,
		CONCAT(
			dbo.fnHtmlAttribute(@classAttrib, ''container-fluid course-summary-wrapper''), @space,
			dbo.fnHtmlAttribute(''data-course-id'', mrd.Id), @space,
			dbo.fnHtmlAttribute(''data-base-course-id'', mrd.BaseCourseId), @space,
			dbo.fnHtmlAttribute(''data-next-course-id'', etr.NextId), @space,
			dbo.fnHtmlAttribute(''data-process-action-type'', mrd.ProcessActionType), @space,
			dbo.fnHtmlAttribute(''data-next-course-process-action-type'', etr.NextCourseProcessActionType), @space,
			dbo.fnHtmlAttribute(''data-status-base'', mrd.StatusBase), @space,
			dbo.fnHtmlAttribute(''data-status-alias'', mrd.StatusAlias), @space,
			dbo.fnHtmlAttribute(''data-next-status-base'', etr.NextStatusBase), @space,
			dbo.fnHtmlAttribute(''data-next-status-alias'', etr.NextStatusAlias),
			case	
				when mrd.ProcessActionType = ''Deactivate'' then dbo.fnHtmlAttribute(@styleAttrib, ''display: none;'')
				end
		)
	),
	--Course Title row (Course subject code, number, and title)
	dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-title-header''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	dbo.fnHtmlOpenTag(@boldDataElementTag, CONCAT(
	dbo.fnHtmlAttribute(@classAttrib, ''course-subject''),
	dbo.fnHtmlAttribute(''title'', dbo.fnHtmlEntityEscape(mrd.SubjectTitle))
	)),
	mrd.SubjectCode,
	dbo.fnHtmlCloseTag(@boldDataElementTag), @space,
	dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-number'')), mrd.CourseNumber, dbo.fnHtmlCloseTag(@boldDataElementTag), @space,
	dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-title'')), mrd.CourseTitle, dbo.fnHtmlCloseTag(@boldDataElementTag), @space,
	CASE
		WHEN mrd.IsCreditCourse = 1 AND
			unithr.RenderedRange IS NOT NULL THEN CONCAT(
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''unit-hours-wrapper'')),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''unit-hours-open-paren'')),
			''('',
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''unit-hours-range'')),
			unithr.RenderedRange,
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''unit-hours-close-paren'')),
			'')'',
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlCloseTag(@dataElementTag), @space
			)
		ELSE @empty
	END,

	-- course status display
	dbo.fnHtmlOpenTag(@dataElementTag
		, CONCAT(
			dbo.fnHtmlAttribute(@classAttrib, ''course-status-display''), @space,
			dbo.fnHtmlAttribute(''data-status-base'', mrd.StatusBase), @space,
			dbo.fnHtmlAttribute(''data-status-alias'', mrd.StatusAlias)
		)
	),
		mrd.StatusAlias,
	dbo.fnHtmlCloseTag(@dataElementTag),

	-- course status custom display
	dbo.fnHtmlOpenTag(
		@dataElementTag, concat(
			dbo.fnHtmlAttribute(@classAttrib, ''course-custom-status''),
			dbo.fnHtmlAttribute(@styleAttrib, ''font-style: italic; color: red'')
		)
	),
		case
			when etr.NextCourseProcessActionType = ''Modify'' then ''Historical-Review all addendums''
			when etr.NextCourseProcessActionType = ''Deactivate'' then ''Discontinued''
			else @empty
			end,
	dbo.fnHtmlCloseTag(@dataElementTag),

	-- the rest
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''process-action-type-message-wrapper'')),
	dbo.fnHtmlOpenTag(@dataElementTag,
	CONCAT(
	dbo.fnHtmlAttribute(@classAttrib, ''process-action-type-message-placeholder empty-placeholder''), @space,
	dbo.fnHtmlAttribute(''data-effective-term-range-start'', dbo.fnHtmlEntityEscape(etr.EffectiveTermRangeStart)), @space,
	dbo.fnHtmlAttribute(''data-effective-term-range-end'', dbo.fnHtmlEntityEscape(etr.EffectiveTermRangeEnd)), @space,
	dbo.fnHtmlAttribute(''data-next-effective-term-range-start'', dbo.fnHtmlEntityEscape(netr.EffectiveTermRangeStart)), @space,
	dbo.fnHtmlAttribute(''data-next-effective-term-range-end'', dbo.fnHtmlEntityEscape(netr.EffectiveTermRangeEnd)), @space
	)
	),
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''next-course-process-action-type-message-wrapper'')),
	dbo.fnHtmlOpenTag(@dataElementTag,
	CONCAT(
	dbo.fnHtmlAttribute(@classAttrib, ''next-course-process-action-type-message-placeholder empty-placeholder''), @space,
	dbo.fnHtmlAttribute(''data-effective-term-range-start'', dbo.fnHtmlEntityEscape(etr.EffectiveTermRangeStart)), @space,
	dbo.fnHtmlAttribute(''data-effective-term-range-end'', dbo.fnHtmlEntityEscape(etr.EffectiveTermRangeEnd)), @space,
	dbo.fnHtmlAttribute(''data-next-effective-term-range-start'', dbo.fnHtmlEntityEscape(netr.EffectiveTermRangeStart)), @space,
	dbo.fnHtmlAttribute(''data-next-effective-term-range-end'', dbo.fnHtmlEntityEscape(netr.EffectiveTermRangeEnd)), @space
	)
	),
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlCloseTag(@dataElementTag),
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-units-hours-header''))),
	dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, ecfw.FullWidthColumn)),
	--CASE
	--	WHEN lecthr.RenderedRange IS NOT NULL THEN CONCAT(
	--		dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-hours-wrapper'')),
	--		dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-hours-range'')),
	--		lecthr.RenderedRange,
	--		dbo.fnHtmlCloseTag(@dataElementTag),
	--		dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-hours-label'')),
	--		@space, ''hours lecture'',
	--		dbo.fnHtmlCloseTag(@dataElementTag),
	--		dbo.fnHtmlCloseTag(@dataElementTag)
	--		)
	--	ELSE CONCAT(@openComment, ''No lecture hours'', @closeComment)
	--END,
	--CASE
	--	WHEN lecthr.RenderedRange IS NOT NULL AND
	--		labhr.RenderedRange IS NOT NULL THEN CONCAT(
	--		dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lecture-lab-hours-delimiter'')),
	--		@space, ''-'', @space,
	--		dbo.fnHtmlCloseTag(@dataElementTag)
	--		)
	--	ELSE @empty
	--END,
	--CASE
	--	WHEN labhr.RenderedRange IS NOT NULL THEN CONCAT(
	--		dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lab-hours-wrapper'')),
	--		dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lab-hours-range'')),
	--		labhr.RenderedRange,
	--		dbo.fnHtmlCloseTag(@dataElementTag),
	--		dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''lab-hours-label'')),
	--		@space, ''hours lab'',
	--		dbo.fnHtmlCloseTag(@dataElementTag),
	--		dbo.fnHtmlCloseTag(@dataElementTag)
	--		)
	--	ELSE CONCAT(@openComment, ''No lab hours'', @closeComment)
	--END,
	--CASE
	--	WHEN lecthr.RenderedRange IS NOT NULL OR
	--		labhr.RenderedRange IS NOT NULL THEN @space
	--	ELSE @empty
	--END,
	dbo.fnHtmlCloseTag(@columnTag),
	dbo.fnHtmlCloseTag(@rowTag),
	CASE
		WHEN rr.RenderedRequisites IS NOT NULL THEN CONCAT(
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-requisites-row''))),
			dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''course-requisites-column''))),
			rr.RenderedRequisites,
			dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag)
			)
		ELSE @empty
	END,
	CASE
		WHEN mrd.TransferStatus IS NOT NULL THEN CONCAT(
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''transfer-status-row''))),
			dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''transfer-status-column''))),
			dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''transfer-status-label'')),
			''Transferability:'', @space,
			dbo.fnHtmlCloseTag(@labelTag),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''transfer-status-value'')),
			mrd.TransferStatus,
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag)
			)
		ELSE @empty
	END,
	CASE
		WHEN mrd.IsGenEd = 1 AND
			rge.CombinedAreas IS NOT NULL THEN CONCAT(
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''gen-ed-row''))),
			dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''gen-ed-column''))),
			dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''gen-ed-area-list-label'')),
			''General Education:'', @space,
			dbo.fnHtmlCloseTag(@labelTag),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''gen-ed-area-list'')),
			rge.CombinedAreas,
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag)
			)
		ELSE @empty
	END,
	CASE
		WHEN mrd.IsRepeatable = 1 AND
			(mrd.MaxRepeatsAllowed IS NOT NULL OR
			mrd.UnitsRepeatLimit IS NOT NULL) THEN CONCAT(
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''repeatability-row''))),
			dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''repeatability-column''))),
			dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''repeatability-label'')),
			''Note:'', @space,
			dbo.fnHtmlCloseTag(@labelTag),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''repeatability-value'')),
			''May be taken'', @space,
			CASE
				WHEN mrd.MaxRepeatsAllowed IS NOT NULL THEN CONCAT(''up to'', @space, mrd.MaxRepeatsAllowed, @space, ''times'')
				ELSE @empty
			END,
			CASE
				WHEN mrd.MaxRepeatsAllowed IS NOT NULL AND
					mrd.UnitsRepeatLimit IS NOT NULL THEN CONCAT(@space, ''for'', @space)
				ELSE @empty
			END,
			CASE
				WHEN mrd.UnitsRepeatLimit IS NOT NULL THEN CONCAT(''up to'', @space, FORMAT(mrd.UnitsRepeatLimit, @hoursDecimalFormat), @space, ''total units'')
				ELSE @empty
			END,
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag)
			)
		ELSE @empty
	END,
	CASE
		WHEN mrd.GradeOption IS NOT NULL THEN CONCAT(
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''grade-option-row''))),
			dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''grade-option-column''))),
			dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''grade-option-label'')),
			''Grading:'', @space,
			dbo.fnHtmlCloseTag(@labelTag),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''grade-option-value'')),
			mrd.GradeOption,
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag)
			)
		ELSE @empty
	END,
	CASE
		WHEN mrd.IsCrossListed = 1 AND
			rcl.CombinedCrossListings IS NOT NULL THEN CONCAT(
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''cross-listed-course-list-row''))),
			dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''cross-listed-course-list-column''))),
			dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''cross-listed-course-list-label'')),
			''Cross listed as:'', @space,
			dbo.fnHtmlCloseTag(@labelTag),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''cross-listed-course-list'')),
			rcl.CombinedCrossListings,
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag)
			)
		ELSE @empty
	END,
	CASE
		WHEN mrd.Cid IS NOT NULL THEN CONCAT(
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''cid-row''))),
			dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''cid-column''))),
			dbo.fnHtmlOpenTag(@labelTag, dbo.fnHtmlAttribute(@classAttrib, ''cid-label'')),
			''CID'',
			dbo.fnHtmlCloseTag(@labelTag),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''cid-delimiter'')),
			''-'',
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''cid-value'')),
			mrd.Cid,
			dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag)
			)
		ELSE @empty
	END,
		CASE
		WHEN mrd.Duration IS NOT NULL THEN CONCAT(
			dbo.fnHtmlOpenTag(@rowTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.Wrapper, @space, ''course-duration-row''))),
			dbo.fnHtmlOpenTag(@columnTag, dbo.fnHtmlAttribute(@classAttrib, CONCAT(ecfw.FullWidthColumn, @space, ''course-duration-column''))),
			dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''course-duration'')),
			CONCAT(''Duration: '',mrd.Duration),
			dbo.fnHtmlCloseTag(@blockTag),
			dbo.fnHtmlCloseTag(@columnTag),
			dbo.fnHtmlCloseTag(@rowTag)
			)
		ELSE @empty
	END,
	CASE
		WHEN mrd.CourseDescription IS NOT NULL THEN CONCAT(
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
	dbo.fnHtmlCloseTag(@summaryWrapperTag),
	dbo.fnHtmlCloseTag(@summaryWrapperTag)
	) AS [Text]
FROM @modelRoot mr
	INNER JOIN @modelRootData mrd ON mr.Id = mrd.Id
	LEFT OUTER JOIN @modelEffectiveTermRanges etr ON mr.Id = etr.Id
	LEFT OUTER JOIN @modelEffectiveTermRanges netr ON etr.NextId = netr.Id
	LEFT OUTER JOIN @unitHourRanges unithr ON (mr.Id = unithr.CourseId AND unithr.UnitHourTypeId = 1)
	LEFT OUTER JOIN @unitHourRanges lecthr ON (mr.Id = lecthr.CourseId AND lecthr.UnitHourTypeId = 2)
	LEFT OUTER JOIN @unitHourRanges labhr ON (mr.Id = labhr.CourseId AND labhr.UnitHourTypeId = 3)
	LEFT OUTER JOIN @renderedGenEd rge ON mr.Id = rge.CourseId
	LEFT OUTER JOIN @renderedCrossListings rcl ON mr.Id = rcl.CourseId
	LEFT OUTER JOIN @renderedRequisites rr ON mr.Id = rr.CourseId
	--===
	INNER JOIN @elementClasses ec3 ON ec3.Id = 1 --1 = ThreeColumn
	INNER JOIN @elementClasses ec2shorter ON ec2shorter.Id = 2 --2 = TwoColumnShorterRight
	INNER JOIN @elementClasses ec2short ON ec2short.Id = 3 --3 = TwoColumnShortRight
	INNER JOIN @elementClasses ecfw ON ecfw.Id = 4 --4 = FullWidthRow
--===
ORDER BY mr.InsertOrder
;
--#endregion main rendering

--#endregion template query


'
WHERE Id = 1