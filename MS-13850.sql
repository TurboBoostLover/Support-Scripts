USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13850';
DECLARE @Comments nvarchar(Max) = 
	'Update Literal Drop Downs';
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
Declare @clientId int =1, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =1; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
------------------------------------------------------------------------------------------
INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId					--insert for the report
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 1
    AND mtt.ClientId = @clientId
	AND mtt.MetaTemplateTypeId = 26 --hard code to grab the 1 report template
------------------------------------------------------------------------------------------
declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('Course Requisites', 'CourseRequisite', 'HealthText','Update'),
('Course Requisites', 'CourseRequisite', 'Parenthesis','Update2')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 2573
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Update')

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 2574
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Update2')

INSERT INTO RequisiteValidation
(ClientId,Title, SortOrder, StartDate)
VALUES
(1, '(', 0, GETDATE()),
(1, 'And (', 1, GETDATE()),
(1, 'Or (', 2, GETDATE()),
(1, ')', 3, GETDATE()),
(1, ') And', 4, GETDATE()),
(1, ') Or', 5, GETDATE())

DECLARE @TABLE TABLE (Id int, dropdown int)
INSERT INTO @TABLE
SELECT Id, 
	CASE 
		WHEN HealthText = '(' THEN 1
		WHEN HealthText = 'And (' THEN 2
		WHEN HealthText = 'Or (' THEN 3
		ELSE NULL
	END
FROM CourseRequisite
WHERE HealthText IS NOT NULL

DECLARE @TABLE2 TABLE (Id int, dropdown2 int)
INSERT INTO @TABLE2
SELECT Id, 
	CASE 
		WHEN Parenthesis = ')' THEN 4
		WHEN Parenthesis = ') And' THEN 5
		WHEN Parenthesis = ') Or' THEN 6
		ELSE NULL
	END
FROM CourseRequisite
WHERE Parenthesis IS NOT NULL

UPDATE CourseRequisite
SET RequisiteValidationId01 = t.dropdown
FROM @TABLE AS t
WHERE CourseRequisite.Id = t.Id

UPDATE CourseRequisite
SET RequisiteValidationId02 = t.dropdown2
FROM @TABLE2 AS t
WHERE CourseRequisite.Id = t.Id

DELETE FROM MetaLiteralList
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX)="

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
			WHEN rv.Title IS NULL THEN ' '
			ELSE rv.Title + ' '
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
			WHEN rv2.Title IS NULL THEN ' '
			ELSE rv2.Title + ' '
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
		LEFT JOIN RequisiteValidation rv ON cr.RequisiteValidationId01 = rv.Id
		LEFT JOIN RequisiteValidation rv2 ON cr.RequisiteValidationId02 = rv2.Id
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

/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback