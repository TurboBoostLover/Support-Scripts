USE [reedley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15858';
DECLARE @Comments nvarchar(Max) = 
	'UPDATE COR report';
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
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @noncredit bit = (
	SELECT
		CASE
			WHEN cb.CB04Id = 3
				THEN 1
			ELSE 0
		END
	FROM CourseCBCode AS cb
	WHERE cb.CourseId = @EntityId
)

select 0 as Value, 
concat(''<div class="row">'',
	''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Units:</label> <span class="field-value">'',FORMAT(ISNULL(CD.MinCreditHour,0),''N2''),case when CD.Variable = 1 then '' - '' + FORMAT(ISNULL(CD.MaxCreditHour,0),''N2'') else '''' end,''</span></div>'',
	''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Number of Weeks:</label> <span class="field-value">'',COALESCE(CD.ShortTermWeek, 18),''</span></div>'',
	''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Lecture Hours Per Week:</label> <span class="field-value">'',FORMAT(ISNULL(CD.MinLectureHour,0),''N2''),case when CD.Variable = 1 then '' - '' + FORMAT(ISNULL(CD.MaxLectureHour,0),''N2'') else '''' end,''</span></div>'',
	''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Lab Hours Per Week:</label> <span class="field-value">'',FORMAT(ISNULL(CD.MinLabHour,0),''N2''),case when CD.Variable = 1 then '' - '' + FORMAT(ISNULL(CD.MaxLabHour,0),''N2'') else '''' end,''</span></div>'',
	CASE
		WHEN @noncredit = 1
		THEN ''''
		ELSE
	CONCAT(''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Activity Hours:</label> <span class="field-value">'',FORMAT(ISNULL(CD.MinClinicalHour,0),''N2''),case when CD.Variable = 1 then '' - '' + FORMAT(ISNULL(CD.MaxClinicalHour,0),''N2'') else '''' end,''</span></div>'')
	END
	,
	''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Total In Class Contact Hours:</label> <span class="field-value">'',FORMAT(ISNULL(CD.MinContactHoursLecture,0),''N2''),case when CD.Variable = 1 then '' - '' + FORMAT(ISNULL(CD.MaxContactHoursLecture,0),''N2'') else '''' end,''</span></div>'',
		CASE
		WHEN @noncredit = 1
		THEN ''''
		ELSE
	CONCAT(''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Total Out of Class Contact Hours:</label> <span class="field-value">'',FORMAT(ISNULL(CD.MinOtherHour,0),''N2''),case when CD.Variable = 1 then '' - '' + FORMAT(ISNULL(CD.MaxOtherHour,0),''N2'') else '''' end,''</span></div>'')
	END,
	''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Total Contact Hours:</label> <span class="field-value">'',FORMAT(ISNULL(CD.MinLabLecHour,0),''N2''),case when CD.Variable = 1 then '' - '' + FORMAT(ISNULL(CD.MaxLabLecHour,0),''N2'') else '''' end,''</span></div>'',
			CASE
		WHEN @noncredit = 1
		THEN CONCAT(''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Out of Class Lecture Hours:</label> <span class="field-value">'',CD.MinContHour,''</span></div>'')
		ELSE ''''
		END
	,
				CASE
		WHEN @noncredit = 1
		THEN CONCAT(''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Out of Class Lab Hours:</label> <span class="field-value">'',CD.MinContactHoursLab,''</span></div>'')
		ELSE ''''
		END
	,
	''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Number of Repeats for Credit:</label> <span class="field-value">'',ISNULL(R.Code,0),''</span></div>'',
	''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Grading Method:</label> <span class="field-value">'',ISNULL(GO.Title,0),''</span></div>'',
	''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Open Entry/Open Exit:</label> <span class="field-value">'',case when C.OpenEntry = 1 then ''Yes'' else ''No'' end,''</span></div>'',
	''<div class="col-md-12 meta-renderable meta-field bottom-margin-extra-small"><label class="field-label">Eligible for CPL:</label> <span class="field-value">'',YN.Title,''</span></div>'',
	''</div>''
) as Text
from CourseDescription CD
	left join CourseProposal CP on CD.Courseid = CP.Courseid
	left join Repeatability R on CP.RepeatabilityId = R.id
	left join GradeOption GO on CD.GradeOptionId = GO.id
	left join Course C on C.id = CD.Courseid
	left join CourseYesNo CYN on CYN.Courseid = CD.Courseid
	left join YesNo YN on YN.id = CYN.YesNo05Id
where CD.Courseid = @Entityid
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 4

UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":true,"reportTemplateId":14,"showImplementDate":true,"cssOverride":".h4{font-weight: bold; font-size: small !important}; .report-title{font-size: 32px; max-width: 50%}\r\n.bottom-margin-small::before{display: none !important} \r\n.report-header{margin-bottom: 0; padding-bottom: 0 !important}\r\n.report-entity-title{padding-top: 1vh; font-weight: bold}\r\n.report-implementdate{display: none}"}'
WHERE Id = 362

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MEtaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 4
)