USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-20048';
DECLARE @Comments nvarchar(Max) = 
	'Fix Catalog logic for details';
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
use sdccd

UPDATE OutputTemplateClient
SET TemplateQuery = '
DECLARE @modelRoot TABLE (
	CourseId	INT,
	InsertOrder INT IDENTITY(1, 1) PRIMARY KEY,
	RootData	NVARCHAR(MAX)
	);

INSERT INTO @modelRoot (CourseId)		-- Note: When altering and/or testing this script, do the following to view total query output for a specific course OR courses: 
SELECT em.[Key] FROM @entityModels em;	-- Comment out this SELECT statement for testing.
-- values (16743);						-- Uncomment this line AND add one OR more CourseIds AS the value(s) for testing.

DECLARE @requisites TABLE (
	CourseId	INT, 
	[Text]		NVARCHAR(MAX)
	);

DECLARE @sql NVARCHAR(MAX) =
	(SELECT TemplateQuery FROM OutputTemplateClient WHERE Id = 1); -- Using OutputTemplateClient for requisite output instead of upBulkResolveQuery to avoid overcomplication.

DECLARE @additionalTemplateConfig2 NVARCHAR(MAX) = ''{"RenderV2Requisites": false}'';

-- Comment out the below insert statement for testing.
INSERT INTO @requisites
EXEC sp_executesql 
	@sql, 
	N''@entityModels  SimpleKeyValuePair readonly, @additionalTemplateConfig NVARCHAR(MAX)'',
	@entityModels = @entityModels,
	@additionalTemplateConfig = @additionalTemplateConfig2
	;

UPDATE @requisites SET [Text] = REPLACE([Text],'' mt-3'','''');

DECLARE @modelRootData TABLE (
	CourseId			INT PRIMARY KEY, 
	SubjectCode			NVARCHAR(MAX), 
	CourseNumber		NVARCHAR(MAX), 
	CourseTitle			NVARCHAR(MAX),
	CourseHours			NVARCHAR(MAX),
	CourseCredits		NVARCHAR(MAX), 
	GradeOption			NVARCHAR(MAX),
	requisites			NVARCHAR(MAX),
	CourseDescription	NVARCHAR(MAX),
	CourseDetails		NVARCHAR(MAX),
	CourseUCLimitation  NVARCHAR(MAX)
	);

INSERT INTO @modelRootData (
	CourseId, 
	SubjectCode, 
	CourseNumber, 
	CourseTitle, 
	CourseHours,
	CourseCredits, 
	GradeOption,
	requisites,
	CourseDescription, 
	CourseDetails,
	CourseUCLimitation
	)
SELECT
	c.Id							AS CourseId, 
	s.SubjectCode					AS SubjectCode, 
	c.CourseNumber					AS CourseNumber, 
	c.Title							AS CourseTitle,  
	hrs.[Text]						AS CourseHours,
 	units.[Text]					AS CourseCredits,
	gp.[Description]				AS GradeOption, 
	r.[Text]						AS requisites,
	LTRIM(RTRIM(c.[Description]))	AS CourseDescription,
	cdet.[Text]						AS CourseDetails,
	gmt.TextMax10					AS CourseUCLimitation
FROM @modelRoot mr
	INNER JOIN Course c				ON mr.CourseId		= c.Id
	INNER JOIN CourseProposal cp	ON cp.CourseId		= c.Id
	INNER JOIN Subject s			ON c.SubjectId		= s.Id
	LEFT JOIN  CourseCBCode	cbc		ON cbc.CourseId		= c.Id
	LEFT JOIN  Generic1000Text gtt	ON gtt.CourseId		= c.Id
	LEFT JOIN  GenericMaxText gmt	ON gmt.CourseId		= c.Id
	LEFT JOIN @requisites r			ON c.Id				= r.CourseId
	INNER JOIN CourseDescription cd 
	INNER JOIN CourseYesNo cyn		ON cyn.CourseId		= cd.CourseId
	CROSS APPLY (
		SELECT CASE 
			WHEN lecText IS NOT NULL THEN CONCAT(lecText, ''/'' + labText, ''/'' + othText)
			ELSE CASE 
				WHEN labText IS NOT NULL THEN CONCAT(labText, ''/'' + othText)
				ELSE CASE 
					WHEN othText IS NOT NULL THEN othText 
					ELSE NULL 
				END END 
		END AS [Text]
		FROM (
			SELECT CASE 
				WHEN cd.MinContactHoursClinical IS NOT NULL AND cd.MinContactHoursClinical > 0 
				THEN CONCAT
					(
					dbo.FormatDecimal(cd.MinContactHoursClinical, 1, 0), 
					CASE WHEN cd.MaxContactHoursClinical > cd.MinContactHoursClinical THEN CONCAT	
						('' - '', dbo.FormatDecimal(cd.MaxContactHoursClinical, 1, 0)) 
					ELSE '''' END, 
					'' hours lecture''
					)
				ELSE CASE 
					WHEN cd.MinLectureHour IS NULL OR cd.MinLectureHour = 0 
					THEN CASE 
						WHEN cd.MaxLectureHour IS NULL OR cd.MaxLectureHour = 0 THEN NULL 
						WHEN cd.MaxLectureHour = 1 THEN CONCAT
							(dbo.FormatDecimal(cd.MaxLectureHour, 1, 0),'' hour lecture'') 
						ELSE CONCAT
							(dbo.FormatDecimal(cd.MaxLectureHour, 1, 0), '' hours lecture'') END
					ELSE CASE 
						WHEN cd.MaxLectureHour IS NULL OR cd.MaxLectureHour = 0 
						THEN CASE 
							WHEN cd.MinLectureHour = 1 THEN CONCAT
								(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hour lecture'')
							ELSE CONCAT
								(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hours lecture'') END
						ELSE CASE 
							WHEN cd.MinLectureHour < cd.MaxLectureHour 
							THEN CONCAT
								(
								dbo.FormatDecimal(cd.MinLectureHour, 1, 0), ''-'' , 
								dbo.FormatDecimal(cd.MaxLectureHour, 1, 0), '' hours lecture''
								)
							ELSE CASE 
								WHEN cd.MinLectureHour = 1 
								THEN CONCAT
									(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hour lecture'') 
								ELSE CONCAT
									(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hours lecture'') 
					END END END END 
			END AS [lecText], 
			CASE 
				WHEN cd.MinLabHour IS NULL OR cd.MinLabHour = 0 THEN NULL
				WHEN MinContactHoursLecture IS NOT NULL AND MinContactHoursLecture > 0 
				THEN CONCAT
					(
					dbo.FormatDecimal(cd.MinContactHoursLecture, 1, 0), 
					CASE 
						WHEN cd.MaxContactHoursLecture > cd.MinContactHoursLecture 
						THEN CONCAT
							('' - '', dbo.FormatDecimal(cd.MaxContactHoursLecture, 1, 0)) 
					ELSE '''' END, 
					'' hours lab''
					)
				ELSE CONCAT
					(
					dbo.FormatDecimal(cd.MinLabHour * 48, 3, 0), 
					''-'' + dbo.FormatDecimal(
						CASE WHEN cyn.YesNo14Id = 1 THEN cd.MaxLabHour ELSE cd.MinLabHour END 
						* 54, 3, 0
						), 
					'' hours lab''
					)
			END AS [labText], 
			CASE 
				WHEN cd.MinUnitHour IS NOT NULL AND cd.MinUnitHour > 0
				THEN CONCAT
					(
					dbo.FormatDecimal(cd.MinUnitHour, 1, 0), 
					CASE 
						WHEN cd.MaxUnitHour > cd.MinUnitHour
						THEN CONCAT
							('' - '', dbo.FormatDecimal(cd.MaxUnitHour, 1, 0))
					ELSE '''' END, 
					'' hours other''
					) 
				ELSE CASE 
					WHEN cd.MinOtherHour IS NULL OR cd.MinOtherHour = 0
					THEN CASE 
						WHEN cd.MaxOtherHour IS NULL OR cd.MaxOtherHour = 0 THEN NULL
						WHEN cd.MaxOtherHour >= 1 
						THEN CONCAT
							(dbo.FormatDecimal((cd.MaxOtherHour * 54), 1, 0), '' hours other'' )
					 -- ELSE CONCAT
						-- (dbo.FormatDecimal(cd.MaxOtherHour, 1, 0) , '' hours other'') 
						END
					ELSE CASE 
						WHEN cd.MaxOtherHour IS NULL OR cd.MaxOtherHour = 0
						THEN CASE 
							WHEN cd.MinOtherHour >= 1 
							THEN CONCAT
								(
								dbo.FormatDecimal((cd.MinOtherHour * 48), 1, 0), ''-'', 
								dbo.FormatDecimal((cd.MinOtherHour * 54), 1, 0), '' hours other''
								)
						 -- ELSE CONCAT
							-- (dbo.FormatDecimal(cd.MinOtherHour, 1, 0), '' hours other'') 
							end
						ELSE CASE 
							WHEN (cd.MinOtherHour * 48) < (cd.MaxOtherHour * 54)
							THEN CONCAT
								(
								dbo.FormatDecimal((cd.MinOtherHour * 48), 1, 0), ''-'', 
								dbo.FormatDecimal((cd.MaxOtherHour * 54), 1, 0), '' hours other''
								)
							ELSE CASE 
								WHEN cd.MinOtherHour >= 1 
								THEN CONCAT
									(
									dbo.FormatDecimal((cd.MinOtherHour * 48), 1, 0), ''-'', 
									dbo.FormatDecimal((cd.MinOtherHour * 54), 1, 0), '' hours other'')
							 -- ELSE CONCAT
								-- (dbo.FormatDecimal(cd.MinOtherHour, 1, 0), '' hours other'') 
				END END END END 
			END AS [othText]
		) h
	) hrs
	cross apply (
		SELECT CASE 
			WHEN cd.MinCreditHour IS NULL OR cd.MinCreditHour = 0
			THEN CASE 
				WHEN cd.MaxCreditHour IS NULL OR cd.MaxCreditHour = 0 THEN ''0 units''
				WHEN cd.MaxCreditHour = 1 
				THEN CONCAT
					(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' unit'')
				ELSE CONCAT
					(dbo.FormatDecimal(cd.MaxCreditHour, 1, 0), '' units'') END
			ELSE CASE 
				WHEN cd.MaxCreditHour IS NULL OR cd.MaxCreditHour = 0
				THEN CASE 
					WHEN cd.MinCreditHour = 1 
					THEN CONCAT
						(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' unit'') 
					ELSE CONCAT
						(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' units'') END
				ELSE CASE 
					WHEN cd.MinCreditHour < cd.MaxCreditHour 
					THEN CONCAT
						(
						dbo.FormatDecimal(cd.MinCreditHour, 1, 0), ''-'', 
						dbo.FormatDecimal(cd.MaxCreditHour, 1, 0), '' units''
						) 
					ELSE CASE 
						WHEN cd.MinCreditHour = 1 
						THEN CONCAT
							(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' unit'')
						ELSE CONCAT
							(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' units'') END 
		END END END AS [Text]
	) units ON cd.CourseId = c.Id
	LEFT JOIN GradeOption gp ON cd.GradeOptionid = gp.Id
	OUTER APPLY (
SELECT 
    CONCAT_WS(''; '',
        NULLIF(ftText, ''''),
        NULLIF(cb4Text, ''''),
        NULLIF(cb5Text, ''''),
        NULLIF(cidText, '''')
    ) 
    + CASE 
        WHEN uclText IS NOT NULL THEN ''.'' + uclText 
        ELSE '''' 
      END
    + ''.'' AS [Text]
		FROM (
			SELECT 
			CASE WHEN cd.FieldTripReqsId IS NULL OR cd.FieldTripReqsId = 2 THEN NULL 
			ELSE ''FT'' END		AS [ftText], 
			CASE WHEN cbc.CB04Id IS NULL OR cbc.CB04Id in (1, 3) THEN NULL 
			ELSE ''AA/AS'' END	AS [cb4Text], 
			CASE WHEN cbc.CB05Id IS NULL OR cbc.CB05Id IS NOT NULL 
				 THEN CASE 
					WHEN cbc.CB05Id = 1 THEN ''CSU; UC'' 
					WHEN cbc.CB05Id = 2 THEN ''CSU'' 
				 ELSE NULL END 
			END					AS [cb5Text], 
			CASE WHEN gtt.Text100001 IS NULL THEN NULL 
				 ELSE CONCAT(''C-ID: '', gtt.Text100001)
			END					AS [cidText], 
			CASE WHEN gmt.TextMax10 IS NULL THEN NULL 
				 ELSE gmt.TextMax10
			END					AS [uclText]
		) cdt
	) cdet
ORDER BY dbo.fnCourseNumberTonumeric(c.CourseNumber), c.EntityTitle;

SELECT 
	mr.CourseId AS [Value], 
	CONCAT
		(
		''<style>
			.custom-course-summary-context-wrapper {margin-bottom: 5px;}
			.custom-course-summary-context-wrapper b {font-weight: bold;}
			.course-subject-code, .course-number, .course-title {font-weight: bolder !important;}
		@media print {
			.custom-course-summary-context-wrapper {margin-bottom: 10px !important;}
			.course-summary-wrapper span {font-size: 0.9rem;}
			}
		</style>'', 
		-- Course Summary Wrapper 
		''
		<div class="custom-course-summary-context-wrapper">
			<div class="container-fluid course-summary-wrapper" data-course-id="'', 
			mrd.CourseId, 
		''">'', 
		-- Course Title Row
		''
				<div class="row course-title-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b class="course-subject-code">''
							, CONCAT(upper(mrd.SubjectCode), '' '')
						, ''</b>
						<b class="course-number">''
							, CONCAT(upper(mrd.CourseNumber), '' '')
						, ''</b>
						<b class="course-title">''
							, mrd.CourseTitle
						, ''</b> 
					</div>
				</div>'', 
		-- Hours AND Units Row
				''
				<div class="row course-hours-units-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b>
							<span class="course-hours">'', 
								mrd.CourseHours, 
							''</span>'', 
							CASE WHEN LEN(mrd.CourseHours)   > 1 THEN CASE 
								 WHEN LEN(mrd.CourseCredits) > 1 THEN ''; ''
								 ELSE NULL END 
							ELSE NULL END, 
							''<span class="course-credits">'', 
								mrd.CourseCredits, 
							''</span>'', 
						''</b>'', 
					''</div>'', 
				''</div>'', 
		-- Grade Option Row
				CASE WHEN mrd.GradeOption IS NOT NULL 
					 THEN CONCAT
						(
						''
						<div class="row grade-option-row">
							<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
								<b><span class="grade-option-label">'', 
									''Grading: '', 
								''</span></b>
								<span class="grade-option-value">'', 
									mrd.GradeOption, 
								''</span>
							</div>
						</div>
						'') 
				ELSE NULL END,
		-- Course Requisites Row
				''<div class="col-xs-12 col-sm-12 col-md-12 full-width-column"> 
					<span class="course-requisites">'', 
						mrd.Requisites, 
					''</span>
				</div>'', 
		-- Course Description Row
				''<div class="col-xs-12 col-sm-12 col-md-12 full-width-column"> 
					<span class="course-description">'', 
						mrd.CourseDescription, 
					''</span>
				</div>
			</div>'', 
		-- Course Details Row (Field Trip, Credit Status, Transfer Status, C-ID, UC Limitation Comment)
				''<div class="row course-details-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b><span class="course-details">'', 
							mrd.CourseDetails, 
						''</span></b>
						<span class="course-uc-limtext">'', 
							mrd.CourseUCLimitation, 
						''</span>
					</div>
				</div> 		
			</div> 
		</div>''
	) AS [Text]
FROM @modelRoot mr
	INNER JOIN @modelRootData mrd ON mr.CourseId = mrd.CourseId
ORDER BY mr.InsertOrder;
'
WHERE Id = 2 --city

UPDATE OutputTemplateClient
SET TemplateQuery = '
DECLARE @modelRoot TABLE 
	(
	CourseId	INT,
	InsertOrder INT IDENTITY(1, 1) PRIMARY KEY,
	RootData	NVARCHAR(MAX)
	);

INSERT INTO @modelRoot (CourseId)			-- Note: When altering and/or testing this script, do the following to view total query output for a specific course or courses: 
SELECT em.[Key] FROM @entityModels em;		-- Comment out this SELECT statement 
--VALUES (16941)							-- Uncomment this line and add one or more CourseIds as the value(s) 

DECLARE @modelRootData TABLE
	(
	CourseId			INT PRIMARY KEY, 
	SubjectCode			NVARCHAR(MAX), 
	CourseNumber		NVARCHAR(MAX), 
	CourseTitle			NVARCHAR(MAX),
	CourseHours			NVARCHAR(MAX),
	CourseCredits		NVARCHAR(MAX), 
	GradeOption			NVARCHAR(MAX),
	Prerequisite		NVARCHAR(MAX),
	Corequisite			NVARCHAR(MAX),
	Corequisite_CP		NVARCHAR(MAX),
	Advisory			NVARCHAR(MAX),
	Advisory_CC			NVARCHAR(MAX),
	Advisory_CP			NVARCHAR(MAX),
	LimitationEnroll	NVARCHAR(MAX),
	AltPrerequisite		NVARCHAR(MAX),
	CourseDescription	NVARCHAR(MAX),
	CourseDetails		NVARCHAR(MAX),
	CourseUCLimitation  NVARCHAR(MAX)
	);

INSERT INTO @modelRootData 
	(
    CourseId, 
	SubjectCode, 
	CourseNumber, 
	CourseTitle, 
	CourseHours,
	CourseCredits, 
	GradeOption,
	Prerequisite,
	Corequisite,
	Corequisite_CP, 
	Advisory,
	Advisory_CC,
	Advisory_CP, 
	LimitationEnroll,
	AltPrerequisite,
	CourseDescription, 
	CourseDetails,
	CourseUCLimitation
	)
SELECT
	c.Id							AS CourseId, 
	s.SubjectCode					AS SubjectCode, 
	c.CourseNumber					AS CourseNumber, 
	c.Title							AS CourseTitle,  
	hrs.Text						AS CourseHours,
 	units.Text						AS CourseCredits,
	gp.Description					AS GradeOption, 
	prereq.Text						AS Prerequisite,
	coreq.Text						AS Corequisite,
	coreq_cp.Text					AS Corequisite_CP,
	advreq.Text						AS Advisory,
	advreq_cc.Text					AS Advisory_CC,
	advreq_cp.Text					AS Advisory_CP,
	limreq.Text						AS LimitationEnroll,
	altpreq.Text					AS AltPrerequisite,
	LTRIM(RTRIM(c.Description))		AS CourseDescription,
	cdet.Text						AS CourseDetails,
	gmt.TextMax10					AS CourseUCLimitation
FROM @modelRoot mr
	INNER JOIN Course c				ON mr.CourseId		= c.Id
	INNER JOIN CourseProposal cp	ON cp.CourseId		= c.Id
	INNER JOIN Subject s			ON c.SubjectId		= s.Id
	LEFT JOIN  CourseCBCode	cbc		ON cbc.CourseId		= c.Id
	LEFT JOIN  Generic1000Text gtt	ON gtt.CourseId		= c.Id
	LEFT JOIN  GenericMaxText gmt	ON gmt.CourseId		= c.Id
	INNER JOIN CourseDescription cd 
	inner join CourseYesNo CYN		on CYN.courseid		= cd.courseid
		CROSS APPLY (
			SELECT 
				CASE WHEN lecText IS NOT NULL		THEN CONCAT(lecText, ''/'' + labText, ''/'' + othText)
				ELSE CASE WHEN labText IS NOT NULL  THEN CONCAT(labText, ''/'' + othText)
				ELSE CASE WHEN othText IS NOT NULL  THEN othText ELSE NULL END END
				END AS [Text]
				FROM (
					SELECT 
					CASE WHEN cd.MinLectureHour IS NULL OR cd.MinLectureHour = 0 
						 THEN CASE WHEN cd.MaxLectureHour IS NULL OR cd.MaxLectureHour = 0 THEN NULL 
							  WHEN cd.MaxLectureHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MaxLectureHour, 1, 0), '' hour lecture'' ) 
								   ELSE CONCAT(dbo.FormatDecimal(cd.MaxLectureHour, 1, 0), '' hours lecture'') END
						 ELSE CASE WHEN cd.MaxLectureHour IS NULL OR cd.MaxLectureHour = 0 
							  THEN CASE WHEN cd.MinLectureHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hour lecture'' )
								   ELSE CONCAT(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hours lecture'') END
							  ELSE CASE WHEN cd.MinLectureHour < cd.MaxLectureHour 
								   THEN CONCAT
										 (
										 dbo.FormatDecimal(cd.MinLectureHour, 1, 0), ''-'', 
										 dbo.FormatDecimal(cd.MaxLectureHour, 1, 0), '' hours lecture''
										 )
								   ELSE CASE WHEN cd.MinLectureHour = 1 
										THEN CONCAT(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hour lecture'' ) 
										ELSE CONCAT(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hours lecture'') END END END 
					END AS [lecText],
					CASE 
						WHEN cd.MinLabHour IS NULL OR cd.MinLabHour = 0  
							THEN NULL
					else
						concat(dbo.FormatDecimal(cd.MinLabHour * 48, 3, 0), ''-'' + dbo.FormatDecimal(case when CYN.YesNo14Id = 1 then cd.MaxLabHour else cd.MinLabHour end * 54, 3, 0), '' hours lab'')
					end AS [labText],
					CASE WHEN cd.MinOtherHour IS NULL OR cd.MinOtherHour = 0
						 THEN CASE WHEN cd.MaxOtherHour IS NULL OR cd.MaxOtherHour = 0 THEN NULL
							  WHEN cd.MaxOtherHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MaxOtherHour, 1, 0), '' hour other'' )
								   ELSE CONCAT(dbo.FormatDecimal(cd.MaxOtherHour, 1, 0), '' hours other'') END
						 ELSE CASE WHEN cd.MaxOtherHour IS NULL OR cd.MaxOtherHour = 0
							  THEN CASE WHEN cd.MinOtherHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MinOtherHour, 1, 0), '' hour other'' )
								   ELSE CONCAT(dbo.FormatDecimal(cd.MinOtherHour, 1, 0), '' hours other'') END
							  ELSE CASE WHEN cd.MinOtherHour < cd.MaxOtherHour 
								   THEN CONCAT
										 (
										 dbo.FormatDecimal(cd.MinOtherHour, 1, 0), ''-'', 
										 dbo.FormatDecimal(cd.MaxOtherHour, 1, 0), '' hours other''
										 )
								    ELSE CASE WHEN cd.MinOtherHour = 1 
										 THEN CONCAT(dbo.FormatDecimal(cd.MinOtherHour, 1, 0), '' hour other'' )
										 ELSE CONCAT(dbo.FormatDecimal(cd.MinOtherHour, 1, 0), '' hours other'') END END END
					END AS [othText]
					) h
			) hrs
		CROSS APPLY (
			SELECT
			CASE WHEN cd.MinCreditHour IS NULL OR cd.MinCreditHour = 0
				 THEN CASE WHEN cd.MaxCreditHour IS NULL OR cd.MaxCreditHour = 0 THEN ''0 units''
					  WHEN cd.MaxCreditHour = 1 
						   THEN CONCAT(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' unit'')
						   ELSE CONCAT(dbo.FormatDecimal(cd.MaxCreditHour, 1, 0), '' units'') END
				 ELSE CASE WHEN cd.MaxCreditHour IS NULL OR cd.MaxCreditHour = 0
					  THEN CASE WHEN cd.MinCreditHour = 1 
						   THEN CONCAT(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' unit'' ) 
						   ELSE CONCAT(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' units'') END
					  ELSE CASE WHEN cd.MinCreditHour < cd.MaxCreditHour 
						   THEN CONCAT
								(
								dbo.FormatDecimal(cd.MinCreditHour, 1, 0), ''-'', 
								dbo.FormatDecimal(cd.MaxCreditHour, 1, 0), '' units''
								) 
						   ELSE CASE WHEN cd.MinCreditHour = 1 
								THEN CONCAT(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' unit'' )
							    ELSE CONCAT(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' units'') END END END
			END AS [Text]
			) units
	ON cd.CourseId = c.Id
	LEFT JOIN  GradeOption gp ON cd.GradeOptionid = gp.Id
	OUTER APPLY (
SELECT 
    CONCAT_WS(''; '',
        NULLIF(ftText, ''''),
        NULLIF(cb4Text, ''''),
        NULLIF(cb5Text, ''''),
        NULLIF(cidText, '''')
    ) 
    + CASE 
        WHEN uclText IS NOT NULL THEN ''.'' + uclText 
        ELSE '''' 
      END
    + ''.'' AS [Text]
		FROM 
			(SELECT 
				CASE WHEN cd.FieldTripReqsId IS NULL OR cd.FieldTripReqsId = 2 THEN NULL ELSE ''FT''	 END AS [ftText], 
				CASE WHEN cbc.CB04Id IS NULL OR cbc.CB04Id IN (1, 3) THEN NULL ELSE ''AA/AS''			 END AS [cb4Text],
				CASE WHEN cbc.CB05Id IS NULL OR cbc.CB05Id IS NOT NULL THEN CASE 
					 WHEN cbc.CB05Id = 1 THEN ''CSU; UC'' WHEN cbc.CB05Id = 2 THEN ''CSU'' ELSE NULL END END AS [cb5Text],
				CASE WHEN gtt.Text100001 IS NULL THEN NULL ELSE CONCAT(''C-ID: '', gtt.Text100001)	 END AS [cidText],
				CASE WHEN gmt.TextMax10 IS NULL THEN NULL ELSE gmt.TextMax10						 END AS [uclText]
			) cdt
		) cdet
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 1	-- Prerequisite
		) prereq 
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 2 -- Corequisite
		) coreq
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 3 -- Corequisite: Completion...
		) coreq_cp
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 4 -- Advisory
		) advreq
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 5 -- Advisory: Concurrent...
		) advreq_cc
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId =  6 -- Advisory: Completion...
		) advreq_cp
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 7 -- Limitation on Enrollment
		) limreq
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 8 -- Alternate Prerequisite: Concurrent...
		) altpreq
ORDER BY dbo.fnCourseNumberToNumeric(c.CourseNumber), c.EntityTitle

SELECT 
	mr.CourseId AS [Value],
	CONCAT
		(
		''<style>
			.custom-course-summary-context-wrapper {margin-bottom: 5px;}
			.custom-course-summary-context-wrapper b {font-weight: bold;}
			.course-subject-code, .course-number, .course-title {font-weight: bolder !important;}
		@media print {
			.custom-course-summary-context-wrapper {margin-bottom: 10px !important;}
			.course-summary-wrapper span {font-size: 0.9rem;}
			}
		</style>'', 
-- Course Summary Wrapper 
		''
		<div class="custom-course-summary-context-wrapper">
			<div class="container-fluid course-summary-wrapper" data-course-id="'', mrd.CourseId, ''">'',
-- Course Title Row
				''
				<div class="row course-title-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b class="course-subject-code">'', CONCAT(UPPER(mrd.SubjectCode),  '' ''), ''</b>
						<b class="course-number">'',	   CONCAT(UPPER(mrd.CourseNumber), '' ''),  ''</b>
						<b class="course-title">'',		                mrd.CourseTitle,	  ''</b> 
					</div>
				</div>'',
-- Hours and Units Row
				''
				<div class="row course-hours-units-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b>
						<span class="course-hours">'',	  mrd.CourseHours,   ''</span>'',
						CASE WHEN LEN(mrd.CourseHours) > 1 
							 THEN CASE 
								  WHEN LEN(mrd.CourseCredits) > 1 THEN ''; ''
								  ELSE NULL END 
						ELSE NULL END,	
						''<span class="course-credits">'', mrd.CourseCredits, ''</span>
						</b>
					</div>
				</div>'',
-- Grade Option Row
		CASE WHEN mrd.GradeOption IS NOT NULL 
		THEN CONCAT
			(
				''
				<div class="row grade-option-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b><span class="grade-option-label">'', ''Grading: '',     ''</span></b>
						<span class="grade-option-value">'',     mrd.GradeOption,  ''</span>
					</div>
				</div>''
			) 
		ELSE NULL END,
-- Course Requisites Row
				''
				<div class="row course-requisites-row"> 
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">'',
						CASE WHEN mrd.Prerequisite IS NOT NULL THEN CONCAT (
 						''
						<span class="course-prereq">	
							<b>Prerequisite: </b>
							<span>'',  mrd.Prerequisite,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.Corequisite IS NOT NULL THEN CONCAT (
 						''
						<span class="course-coreq">	
							<b>Corequisite: </b>
							<span>'',  mrd.Corequisite,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.Corequisite_CP IS NOT NULL THEN CONCAT (
 						''
						<span class="course-coreq-cp">	
							<b>Corequisite: Completion of or concurrent enrollment in: </b>
							<span>'',  mrd.Corequisite_CP,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.Advisory IS NOT NULL THEN CONCAT (
 						''
						<span class="course-advreq">	
							<b>Advisory: </b>
							<span>'',  mrd.Advisory,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.Advisory_CC IS NOT NULL THEN CONCAT (
 						''
						<span class="course-advreq-cc">	
							<b>Advisory: Concurrent enrollment in: </b>
							<span>'',  mrd.Advisory_CC,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.Advisory_CP IS NOT NULL THEN CONCAT (
 						''
						<span class="course-advreq-cp">	
							<b>Advisory: Completion of or concurrent enrollment in: </b>
							<span>'',  mrd.Advisory_CP,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.LimitationEnroll IS NOT NULL THEN CONCAT (
 						''
						<span class="course-limreq">	
							<b>Limitation on Enrollment: </b>
							<span>'',  mrd.LimitationEnroll,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.AltPrerequisite IS NOT NULL THEN CONCAT (
 						''
						<span class="course-altpreq">	
							<b>Alternate Prerequisite: Concurrent Enrollment in: </b>
							<span>'',  mrd.AltPrerequisite,	''<br></span>
						</span>'') ELSE NULL END,
					''</div>
				</div>'', 
-- Course Description Row
				CASE WHEN mrd.Prerequisite IS NOT NULL OR mrd.Corequisite IS NOT NULL OR mrd.Corequisite_CP IS NOT NULL
					 OR mrd.Advisory IS NOT NULL OR mrd.Advisory_CC IS NOT NULL OR mrd.Advisory_CP IS NOT NULL 
					 OR mrd.LimitationEnroll IS NOT NULL OR mrd.AltPrerequisite IS NOT NULL 
				THEN
				''
				<div class="row course-description-row" style="margin-top: 5px;">''
				WHEN mrd.Prerequisite IS NULL AND mrd.Corequisite IS NULL AND mrd.Corequisite_CP IS NULL 
					 AND mrd.Advisory IS NULL AND mrd.Advisory_CC IS NULL AND mrd.Advisory_CP IS NULL
					 AND mrd.LimitationEnroll IS NULL AND mrd.AltPrerequisite IS NULL 
				THEN
				''
				<div class="row course-description-row">'' END,
					''
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column"> 
						<span class="course-description">'',  mrd.CourseDescription,  ''</span>
					</div>
				</div>'', 
-- Course Details Row (Field Trip, Credit Status, Transfer Status, C-ID, UC Limitation Comment)
				''
				<div class="row course-details-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b><span class="course-details">'',  mrd.CourseDetails,      ''</span></b>
						<span class="course-uc-limtext">'',  mrd.CourseUCLimitation, ''</span>
					</div>
				</div> 		
			</div> 
		</div>''
		) AS [Text]
FROM @modelRoot mr
	INNER JOIN @modelRootData mrd ON mr.CourseId = mrd.CourseId
ORDER BY mr.InsertOrder;
'
WHERE Id = 4 --mesa

UPDATE OutputTemplateClient
SET TemplateQuery = '
DECLARE @modelRoot TABLE 
	(
	CourseId	INT,
	InsertOrder INT IDENTITY(1, 1) PRIMARY KEY,
	RootData	NVARCHAR(MAX)
	);

INSERT INTO @modelRoot (CourseId)			-- Note: When altering and/or testing this script, do the following to view total query output for a specific course or courses: 
SELECT em.[Key] FROM @entityModels em;		-- Comment out this SELECT statement 
--VALUES (16941)							-- Uncomment this line and add one or more CourseIds as the value(s) 

DECLARE @modelRootData TABLE
	(
	CourseId			INT PRIMARY KEY, 
	SubjectCode			NVARCHAR(MAX), 
	CourseNumber		NVARCHAR(MAX), 
	CourseTitle			NVARCHAR(MAX),
	CourseHours			NVARCHAR(MAX),
	CourseCredits		NVARCHAR(MAX), 
	GradeOption			NVARCHAR(MAX),
	Prerequisite		NVARCHAR(MAX),
	Corequisite			NVARCHAR(MAX),
	Corequisite_CP		NVARCHAR(MAX),
	Advisory			NVARCHAR(MAX),
	Advisory_CC			NVARCHAR(MAX),
	Advisory_CP			NVARCHAR(MAX),
	LimitationEnroll	NVARCHAR(MAX),
	AltPrerequisite		NVARCHAR(MAX),
	CourseDescription	NVARCHAR(MAX),
	CourseDetails		NVARCHAR(MAX),
	CourseUCLimitation  NVARCHAR(MAX)
	);

INSERT INTO @modelRootData 
	(
    CourseId, 
	SubjectCode, 
	CourseNumber, 
	CourseTitle, 
	CourseHours,
	CourseCredits, 
	GradeOption,
	Prerequisite,
	Corequisite,
	Corequisite_CP, 
	Advisory,
	Advisory_CC,
	Advisory_CP, 
	LimitationEnroll,
	AltPrerequisite,
	CourseDescription, 
	CourseDetails,
	CourseUCLimitation
	)
SELECT
	c.Id							AS CourseId, 
	s.SubjectCode					AS SubjectCode, 
	c.CourseNumber					AS CourseNumber, 
	c.Title							AS CourseTitle,  
	hrs.Text						AS CourseHours,
 	units.Text						AS CourseCredits,
	gp.Description					AS GradeOption, 
	prereq.Text						AS Prerequisite,
	coreq.Text						AS Corequisite,
	coreq_cp.Text					AS Corequisite_CP,
	advreq.Text						AS Advisory,
	advreq_cc.Text					AS Advisory_CC,
	advreq_cp.Text					AS Advisory_CP,
	limreq.Text						AS LimitationEnroll,
	altpreq.Text					AS AltPrerequisite,
	LTRIM(RTRIM(c.Description))		AS CourseDescription,
	cdet.Text						AS CourseDetails,
	gmt.TextMax10					AS CourseUCLimitation
FROM @modelRoot mr
	INNER JOIN Course c				ON mr.CourseId		= c.Id
	INNER JOIN CourseProposal cp	ON cp.CourseId		= c.Id
	INNER JOIN Subject s			ON c.SubjectId		= s.Id
	LEFT JOIN  CourseCBCode	cbc		ON cbc.CourseId		= c.Id
	LEFT JOIN  Generic1000Text gtt	ON gtt.CourseId		= c.Id
	LEFT JOIN  GenericMaxText gmt	ON gmt.CourseId		= c.Id
	INNER JOIN CourseDescription cd 
	inner join CourseYesNo CYN		on CYN.courseid		= cd.courseid
		CROSS APPLY (
			SELECT 
				CASE WHEN lecText IS NOT NULL		THEN CONCAT(lecText, ''/'' + labText, ''/'' + othText)
				ELSE CASE WHEN labText IS NOT NULL  THEN CONCAT(labText, ''/'' + othText)
				ELSE CASE WHEN othText IS NOT NULL  THEN othText ELSE NULL END END
				END AS [Text]
				FROM (
					SELECT 
					CASE WHEN cd.MinLectureHour IS NULL OR cd.MinLectureHour = 0 
						 THEN CASE WHEN cd.MaxLectureHour IS NULL OR cd.MaxLectureHour = 0 THEN NULL 
							  WHEN cd.MaxLectureHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MaxLectureHour, 1, 0), '' hour lecture'' ) 
								   ELSE CONCAT(dbo.FormatDecimal(cd.MaxLectureHour, 1, 0), '' hours lecture'') END
						 ELSE CASE WHEN cd.MaxLectureHour IS NULL OR cd.MaxLectureHour = 0 
							  THEN CASE WHEN cd.MinLectureHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hour lecture'' )
								   ELSE CONCAT(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hours lecture'') END
							  ELSE CASE WHEN cd.MinLectureHour < cd.MaxLectureHour 
								   THEN CONCAT
										 (
										 dbo.FormatDecimal(cd.MinLectureHour, 1, 0), ''-'', 
										 dbo.FormatDecimal(cd.MaxLectureHour, 1, 0), '' hours lecture''
										 )
								   ELSE CASE WHEN cd.MinLectureHour = 1 
										THEN CONCAT(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hour lecture'' ) 
										ELSE CONCAT(dbo.FormatDecimal(cd.MinLectureHour, 1, 0), '' hours lecture'') END END END 
					END AS [lecText],
					CASE 
						WHEN cd.MinLabHour IS NULL OR cd.MinLabHour = 0  
							THEN NULL
					else
						concat(dbo.FormatDecimal(cd.MinLabHour * 48, 3, 0), ''-'' + dbo.FormatDecimal(case when CYN.YesNo14Id = 1 then cd.MaxLabHour else cd.MinLabHour end * 54, 3, 0), '' hours lab'')
					end AS [labText],
					CASE WHEN cd.MinOtherHour IS NULL OR cd.MinOtherHour = 0
						 THEN CASE WHEN cd.MaxOtherHour IS NULL OR cd.MaxOtherHour = 0 THEN NULL
							  WHEN cd.MaxOtherHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MaxOtherHour, 1, 0), '' hour other'' )
								   ELSE CONCAT(dbo.FormatDecimal(cd.MaxOtherHour, 1, 0), '' hours other'') END
						 ELSE CASE WHEN cd.MaxOtherHour IS NULL OR cd.MaxOtherHour = 0
							  THEN CASE WHEN cd.MinOtherHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MinOtherHour, 1, 0), '' hour other'' )
								   ELSE CONCAT(dbo.FormatDecimal(cd.MinOtherHour, 1, 0), '' hours other'') END
							  ELSE CASE WHEN cd.MinOtherHour < cd.MaxOtherHour 
								   THEN CONCAT
										 (
										 dbo.FormatDecimal(cd.MinOtherHour, 1, 0), ''-'', 
										 dbo.FormatDecimal(cd.MaxOtherHour, 1, 0), '' hours other''
										 )
								    ELSE CASE WHEN cd.MinOtherHour = 1 
										 THEN CONCAT(dbo.FormatDecimal(cd.MinOtherHour, 1, 0), '' hour other'' )
										 ELSE CONCAT(dbo.FormatDecimal(cd.MinOtherHour, 1, 0), '' hours other'') END END END
					END AS [othText]
					) h
			) hrs
		CROSS APPLY (
			SELECT
			CASE WHEN cd.MinCreditHour IS NULL OR cd.MinCreditHour = 0
				 THEN CASE WHEN cd.MaxCreditHour IS NULL OR cd.MaxCreditHour = 0 THEN ''0 units''
					  WHEN cd.MaxCreditHour = 1 
						   THEN CONCAT(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' unit'')
						   ELSE CONCAT(dbo.FormatDecimal(cd.MaxCreditHour, 1, 0), '' units'') END
				 ELSE CASE WHEN cd.MaxCreditHour IS NULL OR cd.MaxCreditHour = 0
					  THEN CASE WHEN cd.MinCreditHour = 1 
						   THEN CONCAT(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' unit'' ) 
						   ELSE CONCAT(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' units'') END
					  ELSE CASE WHEN cd.MinCreditHour < cd.MaxCreditHour 
						   THEN CONCAT
								(
								dbo.FormatDecimal(cd.MinCreditHour, 1, 0), ''-'', 
								dbo.FormatDecimal(cd.MaxCreditHour, 1, 0), '' units''
								) 
						   ELSE CASE WHEN cd.MinCreditHour = 1 
								THEN CONCAT(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' unit'' )
							    ELSE CONCAT(dbo.FormatDecimal(cd.MinCreditHour, 1, 0), '' units'') END END END
			END AS [Text]
			) units
	ON cd.CourseId = c.Id
	LEFT JOIN  GradeOption gp ON cd.GradeOptionid = gp.Id
	OUTER APPLY (
SELECT 
    CONCAT_WS(''; '',
        NULLIF(ftText, ''''),
        NULLIF(cb4Text, ''''),
        NULLIF(cb5Text, ''''),
        NULLIF(cidText, '''')
    ) 
    + CASE 
        WHEN uclText IS NOT NULL THEN ''.'' + uclText 
        ELSE '''' 
      END
    + ''.'' AS [Text]
		FROM 
			(SELECT 
				CASE WHEN cd.FieldTripReqsId IS NULL OR cd.FieldTripReqsId = 2 THEN NULL ELSE ''FT''	 END AS [ftText], 
				CASE WHEN cbc.CB04Id IS NULL OR cbc.CB04Id IN (1, 3) THEN NULL ELSE ''AA/AS''			 END AS [cb4Text],
				CASE WHEN cbc.CB05Id IS NULL OR cbc.CB05Id IS NOT NULL THEN CASE 
					 WHEN cbc.CB05Id = 1 THEN ''CSU; UC'' WHEN cbc.CB05Id = 2 THEN ''CSU'' ELSE NULL END END AS [cb5Text],
				CASE WHEN gtt.Text100001 IS NULL THEN NULL ELSE CONCAT(''C-ID: '', gtt.Text100001)	 END AS [cidText],
				CASE WHEN gmt.TextMax10 IS NULL THEN NULL ELSE gmt.TextMax10						 END AS [uclText]
			) cdt
		) cdet
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 1	-- Prerequisite
		) prereq 
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 2 -- Corequisite
		) coreq
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 3 -- Corequisite: Completion...
		) coreq_cp
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 4 -- Advisory
		) advreq
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 5 -- Advisory: Concurrent...
		) advreq_cc
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId =  6 -- Advisory: Completion...
		) advreq_cp
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 7 -- Limitation on Enrollment
		) limreq
	OUTER APPLY (
		SELECT STRING_AGG (
			CASE WHEN creq.Id IS NOT NULL 
				 THEN CASE WHEN cr.CourseRequisiteComment IS NOT NULL 
					  THEN CONCAT(sreq.SubjectCode, '' '', creq.CourseNumber, '' - '', cr.CourseRequisiteComment)
					  ELSE CONCAT(sreq.SubjectCode,'' '',  creq.CourseNumber) END
					  ELSE CASE WHEN cr.CourseRequisiteComment IS NOT NULL
			 			   THEN cr.CourseRequisiteComment
						   ELSE NULL END END,	
				'', '') WITHIN GROUP(ORDER BY cr.SortOrder)
			AS [Text]
		FROM CourseRequisite cr
			LEFT JOIN Course creq INNER JOIN Subject sreq ON creq.SubjectId = sreq.Id ON cr.Requisite_CourseId = creq.Id
			INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id	
		WHERE cr.CourseId = c.Id AND cr.RequisiteTypeId = 8 -- Alternate Prerequisite: Concurrent...
		) altpreq
ORDER BY dbo.fnCourseNumberToNumeric(c.CourseNumber), c.EntityTitle

SELECT 
	mr.CourseId AS [Value],
	CONCAT
		(
		''<style>
			.custom-course-summary-context-wrapper {margin-bottom: 5px;}
			.custom-course-summary-context-wrapper b {font-weight: bold;}
			.course-subject-code, .course-number, .course-title {font-weight: bolder !important;}
		@media print {
			.custom-course-summary-context-wrapper {margin-bottom: 10px !important;}
			.course-summary-wrapper span {font-size: 0.9rem;}
			}
		</style>'', 
-- Course Summary Wrapper 
		''
		<div class="custom-course-summary-context-wrapper">
			<div class="container-fluid course-summary-wrapper" data-course-id="'', mrd.CourseId, ''">'',
-- Course Title Row
				''
				<div class="row course-title-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b class="course-subject-code">'', CONCAT(UPPER(mrd.SubjectCode),  '' ''), ''</b>
						<b class="course-number">'',	   CONCAT(UPPER(mrd.CourseNumber), '' ''),  ''</b>
						<b class="course-title">'',		                mrd.CourseTitle,	  ''</b> 
					</div>
				</div>'',
-- Hours and Units Row
				''
				<div class="row course-hours-units-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b>
						<span class="course-hours">'',	  mrd.CourseHours,   ''</span>'',
						CASE WHEN LEN(mrd.CourseHours) > 1 
							 THEN CASE 
								  WHEN LEN(mrd.CourseCredits) > 1 THEN ''; ''
								  ELSE NULL END 
						ELSE NULL END,	
						''<span class="course-credits">'', mrd.CourseCredits, ''</span>
						</b>
					</div>
				</div>'',
-- Grade Option Row
		CASE WHEN mrd.GradeOption IS NOT NULL 
		THEN CONCAT
			(
				''
				<div class="row grade-option-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b><span class="grade-option-label">'', ''Grading: '',     ''</span></b>
						<span class="grade-option-value">'',     mrd.GradeOption,  ''</span>
					</div>
				</div>''
			) 
		ELSE NULL END,
-- Course Requisites Row
				''
				<div class="row course-requisites-row"> 
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">'',
						CASE WHEN mrd.Prerequisite IS NOT NULL THEN CONCAT (
 						''
						<span class="course-prereq">	
							<b>Prerequisite: </b>
							<span>'',  mrd.Prerequisite,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.Corequisite IS NOT NULL THEN CONCAT (
 						''
						<span class="course-coreq">	
							<b>Corequisite: </b>
							<span>'',  mrd.Corequisite,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.Corequisite_CP IS NOT NULL THEN CONCAT (
 						''
						<span class="course-coreq-cp">	
							<b>Corequisite: Completion of or concurrent enrollment in: </b>
							<span>'',  mrd.Corequisite_CP,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.Advisory IS NOT NULL THEN CONCAT (
 						''
						<span class="course-advreq">	
							<b>Advisory: </b>
							<span>'',  mrd.Advisory,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.Advisory_CC IS NOT NULL THEN CONCAT (
 						''
						<span class="course-advreq-cc">	
							<b>Advisory: Concurrent enrollment in: </b>
							<span>'',  mrd.Advisory_CC,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.Advisory_CP IS NOT NULL THEN CONCAT (
 						''
						<span class="course-advreq-cp">	
							<b>Advisory: Completion of or concurrent enrollment in: </b>
							<span>'',  mrd.Advisory_CP,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.LimitationEnroll IS NOT NULL THEN CONCAT (
 						''
						<span class="course-limreq">	
							<b>Limitation on Enrollment: </b>
							<span>'',  mrd.LimitationEnroll,	''<br></span>
						</span>'') ELSE NULL END,
						CASE WHEN mrd.AltPrerequisite IS NOT NULL THEN CONCAT (
 						''
						<span class="course-altpreq">	
							<b>Alternate Prerequisite: Concurrent Enrollment in: </b>
							<span>'',  mrd.AltPrerequisite,	''<br></span>
						</span>'') ELSE NULL END,
					''</div>
				</div>'', 
-- Course Description Row
				CASE WHEN mrd.Prerequisite IS NOT NULL OR mrd.Corequisite IS NOT NULL OR mrd.Corequisite_CP IS NOT NULL
					 OR mrd.Advisory IS NOT NULL OR mrd.Advisory_CC IS NOT NULL OR mrd.Advisory_CP IS NOT NULL 
					 OR mrd.LimitationEnroll IS NOT NULL OR mrd.AltPrerequisite IS NOT NULL 
				THEN
				''
				<div class="row course-description-row" style="margin-top: 5px;">''
				WHEN mrd.Prerequisite IS NULL AND mrd.Corequisite IS NULL AND mrd.Corequisite_CP IS NULL 
					 AND mrd.Advisory IS NULL AND mrd.Advisory_CC IS NULL AND mrd.Advisory_CP IS NULL
					 AND mrd.LimitationEnroll IS NULL AND mrd.AltPrerequisite IS NULL 
				THEN
				''
				<div class="row course-description-row">'' END,
					''
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column"> 
						<span class="course-description">'',  mrd.CourseDescription,  ''</span>
					</div>
				</div>'', 
-- Course Details Row (Field Trip, Credit Status, Transfer Status, C-ID, UC Limitation Comment)
				''
				<div class="row course-details-row">
					<div class="col-xs-12 col-sm-12 col-md-12 full-width-column">
						<b><span class="course-details">'',  mrd.CourseDetails,      ''</span></b>
						<span class="course-uc-limtext">'',  mrd.CourseUCLimitation, ''</span>
					</div>
				</div> 		
			</div> 
		</div>''
		) AS [Text]
FROM @modelRoot mr
	INNER JOIN @modelRootData mrd ON mr.CourseId = mrd.CourseId
ORDER BY mr.InsertOrder;
'
WHERE Id = 6 --Miramar