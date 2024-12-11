USE [imperial];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15183';
DECLARE @Comments nvarchar(Max) = 
	'Update COR custom SQL that pulls in requisites';
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
DECLARE @SQL NVARCHAR(MAX) = '
-- String variables for all requisite types and requisites --
DECLARE @prereqString NVARCHAR(MAX) = NULL;
DECLARE @coreqString NVARCHAR(MAX) = NULL;
DECLARE @recPrepString NVARCHAR(MAX) = NULL;
DECLARE @recCompCourseString NVARCHAR(MAX) = NULL;

-- Temp table for requisite course content -- 
DECLARE @source TABLE 
	(
	  Id INT NOT NULL IDENTITY
	, RequisiteType NVARCHAR(MAX)
	, SubjectCode NVARCHAR(MAX)
	, CourseNumber NVARCHAR(MAX)
	, Condition NVARCHAR(MAX)
	, NonCourseRequirements NVARCHAR(MAX)
	, SortOrder INT
	);

INSERT INTO @source
SELECT 
	  rt.Title
	, s.SubjectCode
	, c.CourseNumber
	, cd.Title
	, cr.CourseRequisiteComment
	, cr.SortOrder
FROM CourseRequisite cr
	LEFT JOIN Course c ON cr.Requisite_CourseId = c.Id
	LEFT JOIN [Subject] s ON c.SubjectId = s.Id
	LEFT JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
	LEFT JOIN Condition cd ON cr.ConditionId = cd.Id
WHERE cr.CourseId = @entityId
	AND rt.Title IS NOT NULL
ORDER BY cr.SortOrder;

---------------------------------------------------------
-- Variables for the display loop below: number of requisites listed for each requisite type, and the requisite CourseId listed last in each requisite type -- 
DECLARE @numOfReqsInPreReq INT = (SELECT COUNT (*) FROM @source WHERE RequisiteType = ''Prerequisite'');
DECLARE @lastIdPreReq INT = (SELECT MAX(Id) FROM @source WHERE RequisiteType = ''Prerequisite'');

DECLARE @numOfReqsInCoReq INT = (SELECT COUNT (*) FROM @source WHERE RequisiteType = ''Corequisite'');
DECLARE @lastIdCoReq INT = (SELECT MAX(Id) FROM @source WHERE RequisiteType = ''Corequisite'');

DECLARE @numOfReqsInRecPrep INT = (SELECT COUNT (*) FROM @source WHERE RequisiteType =''Recommended Preparation'');
DECLARE @lastIdRecPrep INT = (SELECT MAX(Id) FROM @source WHERE RequisiteType = ''Recommended Preparation'');

DECLARE @numOfReqsInRecCompCourse INT = (SELECT COUNT (*) FROM @source WHERE RequisiteType =''Recommended Companion Course'');
DECLARE @lastIdRecCompCourse INT = (SELECT MAX(Id) FROM @source WHERE RequisiteType = ''Recommended Companion Course'');

---------------------------------------------------------
-- Loop to set up how requisites display on the report, to allow for changes in the order of requisite items within each requisite type in the ordered list --
WHILE EXISTS (SELECT 1 FROM @source)
BEGIN 
	-- Variable: Current Requisite Course Id --
	DECLARE @currId int = (SELECT MIN(Id) FROM @source);

	-- Variable: Current Requisite Type --
	DECLARE @currReqType NVARCHAR(MAX) = (SELECT RequisiteType FROM @source WHERE Id = @currId);

	-- Variable: Current Requisite Course Subject Code --
	DECLARE @currSubjectCode NVARCHAR(MAX) = (SELECT SubjectCode FROM @source WHERE Id = @currId);

	-- Variable: Current Requisite Course Number --
	DECLARE @currCourseNumber NVARCHAR(MAX) = (SELECT CourseNumber FROM @source WHERE Id = @currId);

	-- Variable: Current Condition (and, or, NULL)
	DECLARE @currCondition NVARCHAR(MAX) = (SELECT Condition FROM @source WHERE Id = @currId);

	-- Variable: Current Requisite Comment --
	DECLARE @nonCourseRequirements NVARCHAR(MAX) = (SELECT NonCourseRequirements FROM @source WHERE Id = @currId);

	-- Variable: Whether the requisite is the last one listed in each requisite type
	DECLARE @isLastReq BIT = 0;

-- Prerequisite --
	IF (@currReqType = ''Prerequisite'')
	BEGIN
		SET @isLastReq = (SELECT CASE 
								 WHEN Id = @lastIdPreReq THEN 1 
								 ELSE 0 
								 END 
						  FROM @source WHERE Id = @currId AND RequisiteType = ''Prerequisite''
						  );

		-- Requisite Type label
		IF (@preReqString IS NULL)
		BEGIN
			SET @preReqString = ''<b>PREREQUISITES: </b>''; 
		END;
		
		-- When Subject Code exists, show it as the first part of each requisite item.
		IF (@currSubjectCode IS NOT NULL)
		BEGIN
			SET @preReqString += lTrim(rTrim(@currSubjectCode));
		END;

		-- When Course Number exists, show it after Subject Code, separated by a space.
		IF (@currCourseNumber IS NOT NULL)
		BEGIN
			SET @preReqString += '' '' + lTrim(rTrim(@currCourseNumber));
		END;

		-- When Requisite Commment content exists, show it at the end of the course title (SubjectCode CourseNumber), separated by a spaced dash.
		IF (@nonCourseRequirements IS NOT NULL)
		BEGIN 
			SET @preReqString += '' - '' + lTrim(rTrim(@nonCourseRequirements));
		END;

		-- If requisite condition is either ''and'' or ''or'' and the course is not the last requisite listed in the type:
		IF (@currCondition IN (''or'',''and'') AND @isLastReq = 0)
		BEGIN
			SET @preReqString += '' '' + @currCondition + '' '';
		END;
		-- Then show a space, the condition, and another space before the next course.

		-- If requisite condition is not ''and'' or ''or'' (NULL, no selection), and the course is NOT the last requisite listed in the type:
		IF ((@currCondition NOT IN (''or'',''and'') 
				OR @currCondition IS NULL 
				OR @currCondition = ''-1'') 
			 AND @isLastReq = 0)
		BEGIN
			SET @preReqString += '', '';
		END;
		-- Then show a comma and a space before the next course.

		-- If there is any condition selected for a requisite course, or no condition selected, and the course IS the last requisite listed in the type:
		IF ((@currCondition IN (''or'', ''and'')
			    OR @currCondition NOT IN (''or'', ''and'')
				OR @currCondition IS NULL
				OR @currCondition = ''-1'')
			AND @isLastReq = 1)
		BEGIN
			SET @preReqString += '''';
		END; 
		-- Then show nothing after the end of the course.

	END;

-- Corequisite --
	IF (@currReqType = ''Corequisite'')
	BEGIN
		SET @isLastReq = (SELECT CASE 
								 WHEN Id = @lastIdCoReq THEN 1 
								 ELSE 0 
								 END 
						  FROM @source WHERE Id = @currId AND RequisiteType = ''Corequisite''
						  );
		
		-- If Prerequisites label is showing, add a line break
		IF (@coReqString IS NULL AND @preReqString IS NOT NULL)
		BEGIN
			SET @coReqString = ''<br /><b>COREQUISITES: </b>''; 
		END;		
		
		-- If Prerequisites label is not showing, no line break
		IF (@coReqString IS NULL AND @preReqString IS NULL)
		BEGIN
			SET @coReqString = ''<br /><b>COREQUISITES: </b>''; 
		END;
		
		IF (@currSubjectCode IS NOT NULL)
		BEGIN
			SET @coReqString += lTrim(rTrim(@currSubjectCode));
		END;

		IF (@currCourseNumber IS NOT NULL)
		BEGIN
			SET @coReqString += '' '' +lTrim(rTrim(@currCourseNumber));
		END;

		IF (@nonCourseRequirements IS NOT NULL)
		BEGIN
			SET @coReqString += '' - '' + lTrim(rTrim(@nonCourseRequirements));
		END;

		IF (@currCondition IN (''or'',''and'') AND @isLastReq = 0)
		BEGIN
			SET @coReqString += '' '' + @currCondition + '' '';
		END;

		IF ((@currCondition NOT IN (''or'',''and'') 
			 OR @currCondition IS NULL 
			 OR @currCondition = ''-1'') 
			 AND @isLastReq = 0)
		BEGIN
			SET @coReqString += '', '';
		END;

		IF ((@currCondition IN (''or'', ''and'')
			    OR @currCondition NOT IN (''or'', ''and'')
				OR @currCondition IS NULL
				OR @currCondition = ''-1'')
			AND @isLastReq = 1)
		BEGIN
			SET @coReqString += '''';
		END; 

	END;

-- Recommended Preparation --
	IF (@currReqType = ''Recommended Preparation'')
	BEGIN
		SET @isLastReq = (SELECT CASE 
								 WHEN Id = @lastIdRecPrep THEN 1 
								 ELSE 0 
								 END 
						  FROM @source WHERE Id = @currId AND RequisiteType = ''Recommended Preparation''
						  );

		-- If Prerequisites or Corequisites label is showing, add a line break
		IF ((@RecPrepString IS NULL AND @preReqString IS NOT NULL) 
		 OR (@RecPrepString IS NULL AND @coReqString IS NOT NULL))
		BEGIN
			SET @RecPrepString = ''<br /><b>RECOMMENDED PREPARATION: </b>''; 
		END;

		-- If neither Prerequisites nor Corequisites label is showing, no line break
		IF (@coReqString IS NULL AND @preReqString IS NULL AND @RecPrepString IS NULL)
		BEGIN
			SET @RecPrepString = ''<br /><b>RECOMMENDED PREPARATION: </b>''; 
		END;

		IF (@currSubjectCode IS NOT NULL)
		BEGIN
			SET @RecPrepString += lTrim(rTrim(@currSubjectCode));
		END;

		IF (@currCourseNumber IS NOT NULL)
		BEGIN
			SET @RecPrepString += '' '' + lTrim(rTrim(@currCourseNumber));
		END;
		
		IF (@nonCourseRequirements IS NOT NULL)
		BEGIN
			SET @RecPrepString += '' - '' + lTrim(rTrim(@nonCourseRequirements));
		END;

		IF (@currCondition IN (''or'',''and'') AND @isLastReq = 0)
		BEGIN
			SET @RecPrepString += '' '' + @currCondition + '' '';
		END;

		IF ((@currCondition NOT IN (''or'',''and'') 
			 OR @currCondition IS NULL 
			 OR @currCondition = ''-1'') 
			 AND @isLastReq = 0)
		BEGIN
			SET @RecPrepString += '', '';
		END;

		IF ((@currCondition IN (''or'', ''and'')
			    OR @currCondition NOT IN (''or'', ''and'')
				OR @currCondition IS NULL
				OR @currCondition = ''-1'')
			AND @isLastReq = 1)
		BEGIN
			SET @RecPrepString += '''';
		END; 

	END;

-- Recommended Companion Course --
	IF (@currReqType = ''Recommended Companion Course'')
	BEGIN
		SET @isLastReq = (SELECT CASE 
								 WHEN Id = @lastIdRecCompCourse THEN 1 
								 ELSE 0 
								 END 
						  FROM @source WHERE Id = @currId AND RequisiteType = ''Recommended Companion Course''
						  );

		-- If Prerequisites, Corequisites, or Recommended Preparation label is showing, add a line break
		IF ((@RecCompCourseString IS NULL AND @preReqString IS NOT NULL) 
		 OR (@RecCompCourseString IS NULL AND @coReqString IS NOT NULL) 
		 OR (@RecCompCourseString IS NULL AND @RecPrepString IS NOT NULL))
		BEGIN
			SET @RecCompCourseString = ''<br /><b>RECOMMENDED COMPANION COURSE: </b>''; 
		END;

		-- If neither Prerequisites, Corequisites, nor Recommended Preparation label is showing, no line break
		IF (@RecCompCourseString IS NULL AND @preReqString IS NULL AND @coReqString IS NULL AND @RecPrepString IS NULL)
		BEGIN
			SET @RecCompCourseString = ''<br /><b>RECOMMENDED COMPANION COURSE: </b>''; 
		END;

		IF (@currSubjectCode IS NOT NULL)
		BEGIN
			SET @RecCompCourseString += lTrim(rTrim(@currSubjectCode));
		END;

		IF (@currCourseNumber IS NOT NULL)
		BEGIN
			SET @RecCompCourseString += '' '' + lTrim(rTrim(@currCourseNumber));
		END;
		
		IF (@nonCourseRequirements IS NOT NULL)
		BEGIN 
			SET @RecCompCourseString += '' - '' + lTrim(rTrim(@nonCourseRequirements));
		END;

		IF (@currCondition IN (''or'',''and'') AND @isLastReq = 0)
		BEGIN
			SET @RecCompCourseString += '' '' + @currCondition + '' '';
		END;

		IF ((@currCondition NOT IN (''or'',''and'') 
			 OR @currCondition IS NULL 
			 OR @currCondition = ''-1'') 
			 AND @isLastReq = 0)
		BEGIN
			SET @RecCompCourseString += '', '';
		END;

		IF ((@currCondition IN (''or'', ''and'')
			    OR @currCondition NOT IN (''or'', ''and'')
				OR @currCondition IS NULL
				OR @currCondition = ''-1'')
			AND @isLastReq = 1)
		BEGIN
			SET @RecCompCourseString += '''';
		END; 

	END;

-- If there are no requisites, then same display behavior as requisite type None (nothing will show) --
	IF (LEN(@currReqType) = '''')
	BEGIN
		SET @currReqType = ''None'';
	END;


-- Increment --
	DELETE 
	FROM @source
	WHERE Id = @currId;

END;
-- End of loop --
---------------------------------------------------------

-- Text display --	
DECLARE @renderedText NVARCHAR(MAX);

IF (@preReqString IS NULL
	AND @coReqString IS NULL
	AND @recPrepString IS NULL
    AND @recCompCourseString IS NULL
    )
	BEGIN
		SET @renderedText = CONCAT (
		 ''<div style="padding-left: 25px;font-size: 12px;">''
		, ''None''
		, ''</div>''
		);
	END;
ELSE
	BEGIN
		SET @renderedText = CONCAT (
		 ''<div style="padding-left: 25px; font-size: 12px;">''
		, @preReqString
		, @coReqString
		, @recPrepString
		, @recCompCourseString
	    , ''</div>''
		);
	END;

DECLARE @finalString NVARCHAR(MAX) = @renderedText;

SELECT 
	  0 AS [Value]
	, @finalString AS [Text];

'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 44

UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":true,"suppressEntityTitleDisplay":true,"reportTemplateId":22,"fieldRenderingStrategy":"Standard","sectionRenderingStrategy":"HideEmptySections","subheading":"Course Outline of Record","heading":"IMPERIAL COMMUNITY COLLEGE DISTRICT \n IMPERIAL VALLEY COLLEGE","cssOverride":"\r\n.college-logo-wrapper {max-width: 100%;} \r\n.college-logo {max-width: 50%; width: 50%;}\r\n\r\n.report-title {float: inherit; padding-top: 1.5%; white-space: break-spaces;} \r\n.report-title, .report-subtitle {max-width: 100%; font-size: 14px; text-align: center; font-weight: bold; margin-right: 25%; margin-left: 25%;} \r\n\r\n.body-content > .container {padding-bottom: 0;} \r\n\r\n.field-label {margin-top: 10px;}\r\n\r\nul, ol, \r\n.col-md-12.meta-renderable.meta-field.bottom-margin-extra-small,\r\n.querytext-result-row.display-block p, \r\n.bottom-margin-normal {margin-bottom: 0;}\r\n\r\n.querytext-result-row.display-block:first-of-type p {margin-top: 0;}\r\n.querytext-result-row.display-block p {margin-top: 10px;}\r\n\r\n.meta-renderable.meta-field.bottom-margin-extra-small:empty,\r\n.col-md-12:has(.row > .meta-renderable.meta-field.bottom-margin-extra-small:empty)"}'
WHERE Id = 369

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 44
)

--commit