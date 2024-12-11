USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13906';
DECLARE @Comments nvarchar(Max) = 
	'Update Requisites';
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
UPDATE CourseRequisite
SET CourseRequisiteComment = 'Permission of the Program' + ' ' + CourseRequisiteComment
WHERE RequisiteTypeId = 5
AND Active = 1

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
declare @requisites table (
Id int identity(1,1),
LeftParenthesis nvarchar(max),
RequisteTypeTitle nvarchar(max),
SubjectCode nvarchar(max),
CourseNumber nvarchar(max),
NonCourseRequirement nvarchar(max),
MinimumGrade nvarchar(max),
RightParenthesis nvarchar(max),
Condition nvarchar(max),
ProgramPlan nvarchar(max)
)

INSERT INTO @requisites
(LeftParenthesis, RequisteTypeTitle, SubjectCode, CourseNumber, NonCourseRequirement, MinimumGrade, RightParenthesis, Condition, ProgramPlan)
	SELECT
		CASE
			WHEN cr.HealthText IS NULL OR
				cr.healthtext = '-1' THEN ' '
			ELSE cr.HealthText + ' '
		END
	   ,
	   CASE
			WHEN rt.Id = 5 THEN ''
		ELSE
	  COALESCE(rt.Title + ' ', ' ')
	  END
	   ,COALESCE(s.SubjectCode + ' ', ' ')
	   ,COALESCE(cc.CourseNumber + ' ', ' ')
	   ,CASE
			WHEN cr.CourseRequisiteComment IS NULL THEN ' '
			ELSE CONCAT('<div style=""display:inline-block;"">', cr.CourseRequisiteComment, ' ', '</div>')
		END
	   ,CASE
			WHEN cc.Id IS NOT NULL AND (cr.CourseRequisiteComment IS NULL OR cr.CourseRequisiteComment = '')
			THEN CASE
					WHEN yn.id = 1 THEN 'with a minimum grade of A '
					WHEN yn.id = 2 THEN 'with a minimum grade of B '
					WHEN yn.id = 3 THEN 'with a minimum grade of C '
					ELSE CASE
							WHEN yn2.id = 1 THEN 'with a minimum grade of A '
							WHEN yn2.id = 2 THEN 'with a minimum grade of B '
							WHEN yn2.id = 3 THEN 'with a minimum grade of C '
							ELSE ' '
						END
				END
			ELSE ''
		END
	   ,CASE
			WHEN cr.Parenthesis IS NULL OR
				cr.Parenthesis = '-1' THEN ' '
			ELSE cr.Parenthesis + ' '
		END
	   ,COALESCE(c.Title + ' ', ' ')
	   ,Case
			WHEN cr.Requisite_ProgramId IS NOT NULL AND rt.id = 3
			THEN CONCAT(
				p.Title,
                case 
                    when at.Title is not null 
                        then CONCAT(
                            ' (',
				            AT.Title,
				            ')'
                        )
                    ELSE ''
                End,
                case 
                    when P.Associations is not null 
                        then CONCAT(
                            ' (',
				            P.Associations,
				            ')'
                        )
                    ELSE ''
                End
			)
			ELSE ' '
		END
	FROM CourseRequisite cr
		LEFT JOIN RequisiteType rt ON rt.id = cr.RequisiteTypeId	
		LEFT JOIN Condition c ON c.id = cr.ConditionId
		LEFT JOIN Subject s ON s.id = cr.SubjectId
		LEFT JOIN course cc ON cc.Id = cr.Requisite_CourseId
		LEFT JOIN yesno yn ON yn.id = cr.YesNo02Id
		LEFT JOIN CourseYesNo cyn ON cyn.CourseId = cr.CourseId
		LEFT JOIN YesNo yn2 ON yn2.Id = cyn.YesNo22Id
		LEFT JOIN Program p ON p.id = cr.Requisite_ProgramId
		LEFT JOIN AwardType at ON p.AwardTypeId = at.Id
	WHERE cr.courseid = @entityId and RT.title <> 'Other' 
	ORDER BY cr.SortOrder

declare @final nvarchar(max)

SELECT
	@final = COALESCE(@final, '') +
	CONCAT(
	LeftParenthesis
	, RequisteTypeTitle
	, SubjectCode
	, CourseNumber
	, NonCourseRequirement
	, ProgramPlan
	, MinimumGrade
	, RightParenthesis
	, Condition
	, '<br>'
	)
FROM @requisites

SELECT
	0 AS Value
   ,@final AS Text
"

SET QUOTED_IDENTIFIER ON

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 83

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
	WHERE msf.MetaForeignKeyLookupSourceId = 83
)