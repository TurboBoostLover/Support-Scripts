USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16970';
DECLARE @Comments nvarchar(Max) = 
	'Fix Catalog Query';
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
use sdccd

	declare @serializedStatusBaseMapping nvarchar(max);
 
	select @serializedStatusBaseMapping = (
		select
			vals.Catalog_StatusBaseId as [catalogStatusBaseId],
			vals.Entity_StatusBaseId as [entityStatusBaseId]
		from (
			values
			-- Active catalog
			(1, 1),
			(1, 2),
			--(1, 5),
			-- Approved catalog
			(2, 1),
			(2, 2),
			--(2, 4),
			--(2, 5),
			--(2, 6),
			-- Draft catalog
			(4, 1),
			(4, 2),
			--(4, 4),
			--(4, 5),
			--(4, 6),
			-- Historical catalog
			(5, 1),
			(5, 2),
			(5, 5),
			-- In Review catalog
			(6, 1),
			(6, 2),
			--(6, 4),
			--(6, 5),
			--(6, 6),
			-- Rejected catalog
			(7, 1),
			(7, 2),
			(7, 4),
			(7, 5),
			(7, 6)
		) vals (Catalog_StatusBaseId, Entity_StatusBaseId)
		for json path
	);
 
	update cp
	set cp.Config = json_modify(isnull(cp.Config, '{}'), '$.statusBaseMapping', json_query(@serializedStatusBaseMapping))
	--output inserted.Id, inserted.Title, inserted.Config
	from CurriculumPresentation cp
	where cp.Id in (5, 7, 9, 11);

	DECLARE @SQL2 NVARCHAR(MAX) = '
	
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
					CASE WHEN cd.MinLabHour IS NULL OR cd.MinLabHour = 0 
						 THEN CASE WHEN cd.MaxLabHour IS NULL OR cd.MaxLabHour = 0 THEN NULL
						 	  WHEN cd.MaxLabHour = 1 
						 		   THEN CONCAT(dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hour lab'' )
						 		   ELSE CONCAT(dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hours lab'') END
						 ELSE CASE WHEN cd.MaxLabHour IS NULL OR cd.MaxLabHour = 0
							  THEN CASE WHEN cd.MinLabHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hour lab'' )
								   ELSE CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hours lab'') END
							  ELSE CASE WHEN cd.MinLabHour < cd.MaxLabHour 
								   THEN CONCAT
										(
										dbo.FormatDecimal(cd.MinLabHour, 1, 0), ''-'', 
										dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hours lab''
										)
								    ELSE CASE WHEN cd.MinLabHour = 1 
										 THEN CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hour lab'' )
										 ELSE CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hours lab'') END END END
					END AS [labText],
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
		CASE WHEN ftText IS NOT NULL 
			 THEN CASE WHEN cb4Text IS NOT NULL		 THEN CONCAT(ftText, ''; '', cb4Text, ''; '' + cb5Text, ''; '' + cidText, ''.'', uclText) 
				  ELSE CASE WHEN cb5Text IS NOT NULL THEN CONCAT(ftText, ''; '', cb5Text, ''; '' + cidText, ''.'', uclText)
				  ELSE CASE WHEN cidText IS NOT NULL THEN CONCAT(ftText, ''; '', cidText, ''.'', uclText)
				  ELSE CASE WHEN uclText IS NOT NULL THEN CONCAT(ftText, ''.'', uclText)
													 ELSE CONCAT(ftText, ''.'') END END END END
			 ELSE NULL END AS [Text]
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
	DECLARE @SQL4 NVARCHAR(MAX) = '
	
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
					CASE WHEN cd.MinLabHour IS NULL OR cd.MinLabHour = 0 
						 THEN CASE WHEN cd.MaxLabHour IS NULL OR cd.MaxLabHour = 0 THEN NULL
						 	  WHEN cd.MaxLabHour = 1 
						 		   THEN CONCAT(dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hour lab'' )
						 		   ELSE CONCAT(dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hours lab'') END
						 ELSE CASE WHEN cd.MaxLabHour IS NULL OR cd.MaxLabHour = 0
							  THEN CASE WHEN cd.MinLabHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hour lab'' )
								   ELSE CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hours lab'') END
							  ELSE CASE WHEN cd.MinLabHour < cd.MaxLabHour 
								   THEN CONCAT
										(
										dbo.FormatDecimal(cd.MinLabHour, 1, 0), ''-'', 
										dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hours lab''
										)
								    ELSE CASE WHEN cd.MinLabHour = 1 
										 THEN CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hour lab'' )
										 ELSE CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hours lab'') END END END
					END AS [labText],
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
		CASE WHEN ftText IS NOT NULL 
			 THEN CASE WHEN cb4Text IS NOT NULL		 THEN CONCAT(ftText, ''; '', cb4Text, ''; '' + cb5Text, ''; '' + cidText, ''.'', uclText) 
				  ELSE CASE WHEN cb5Text IS NOT NULL THEN CONCAT(ftText, ''; '', cb5Text, ''; '' + cidText, ''.'', uclText)
				  ELSE CASE WHEN cidText IS NOT NULL THEN CONCAT(ftText, ''; '', cidText, ''.'', uclText)
				  ELSE CASE WHEN uclText IS NOT NULL THEN CONCAT(ftText, ''.'', uclText)
													 ELSE CONCAT(ftText, ''.'') END END END END
			 ELSE NULL END AS [Text]
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
	DECLARE @SQL6 NVARCHAR(MAX) = '
	
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
					CASE WHEN cd.MinLabHour IS NULL OR cd.MinLabHour = 0 
						 THEN CASE WHEN cd.MaxLabHour IS NULL OR cd.MaxLabHour = 0 THEN NULL
						 	  WHEN cd.MaxLabHour = 1 
						 		   THEN CONCAT(dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hour lab'' )
						 		   ELSE CONCAT(dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hours lab'') END
						 ELSE CASE WHEN cd.MaxLabHour IS NULL OR cd.MaxLabHour = 0
							  THEN CASE WHEN cd.MinLabHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hour lab'' )
								   ELSE CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hours lab'') END
							  ELSE CASE WHEN cd.MinLabHour < cd.MaxLabHour 
								   THEN CONCAT
										(
										dbo.FormatDecimal(cd.MinLabHour, 1, 0), ''-'', 
										dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hours lab''
										)
								    ELSE CASE WHEN cd.MinLabHour = 1 
										 THEN CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hour lab'' )
										 ELSE CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hours lab'') END END END
					END AS [labText],
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
		CASE WHEN ftText IS NOT NULL 
			 THEN CASE WHEN cb4Text IS NOT NULL		 THEN CONCAT(ftText, ''; '', cb4Text, ''; '' + cb5Text, ''; '' + cidText, ''.'', uclText) 
				  ELSE CASE WHEN cb5Text IS NOT NULL THEN CONCAT(ftText, ''; '', cb5Text, ''; '' + cidText, ''.'', uclText)
				  ELSE CASE WHEN cidText IS NOT NULL THEN CONCAT(ftText, ''; '', cidText, ''.'', uclText)
				  ELSE CASE WHEN uclText IS NOT NULL THEN CONCAT(ftText, ''.'', uclText)
													 ELSE CONCAT(ftText, ''.'') END END END END
			 ELSE NULL END AS [Text]
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
	DECLARE @SQL8 NVARCHAR(MAX) = '
	
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
					CASE WHEN cd.MinLabHour IS NULL OR cd.MinLabHour = 0 
						 THEN CASE WHEN cd.MaxLabHour IS NULL OR cd.MaxLabHour = 0 THEN NULL
						 	  WHEN cd.MaxLabHour = 1 
						 		   THEN CONCAT(dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hour lab'' )
						 		   ELSE CONCAT(dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hours lab'') END
						 ELSE CASE WHEN cd.MaxLabHour IS NULL OR cd.MaxLabHour = 0
							  THEN CASE WHEN cd.MinLabHour = 1 
								   THEN CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hour lab'' )
								   ELSE CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hours lab'') END
							  ELSE CASE WHEN cd.MinLabHour < cd.MaxLabHour 
								   THEN CONCAT
										(
										dbo.FormatDecimal(cd.MinLabHour, 1, 0), ''-'', 
										dbo.FormatDecimal(cd.MaxLabHour, 1, 0), '' hours lab''
										)
								    ELSE CASE WHEN cd.MinLabHour = 1 
										 THEN CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hour lab'' )
										 ELSE CONCAT(dbo.FormatDecimal(cd.MinLabHour, 1, 0), '' hours lab'') END END END
					END AS [labText],
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
		CASE WHEN ftText IS NOT NULL 
			 THEN CASE WHEN cb4Text IS NOT NULL		 THEN CONCAT(ftText, ''; '', cb4Text, ''; '' + cb5Text, ''; '' + cidText, ''.'', uclText) 
				  ELSE CASE WHEN cb5Text IS NOT NULL THEN CONCAT(ftText, ''; '', cb5Text, ''; '' + cidText, ''.'', uclText)
				  ELSE CASE WHEN cidText IS NOT NULL THEN CONCAT(ftText, ''; '', cidText, ''.'', uclText)
				  ELSE CASE WHEN uclText IS NOT NULL THEN CONCAT(ftText, ''.'', uclText)
													 ELSE CONCAT(ftText, ''.'') END END END END
			 ELSE NULL END AS [Text]
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

	UPDATE OutputTemplateClient
	SET TemplateQuery =
	CASE WHEN Id = 2 THEN @SQL2
	WHEN Id = 4 THEN @SQL4
	WHEN Id = 6 THEN @SQL6
	WHEN Id = 8 THEN @SQL8
	ELSE TemplateQuery
	END