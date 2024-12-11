USE [cuesta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14028';
DECLARE @Comments nvarchar(Max) = 
	'Update COR and course Form';
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
    AND mtt.IsPresentationView = 1
    AND mtt.ClientId = @clientId
	AND mtt.MetaTemplateTypeId = 14

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
('Basic Course Information', 'Course', 'CourseNumber','Update'),
('Basic Course Information', 'CourseQueryText', 'QueryText_05','Query'),
('Basic Course Information', 'CourseQueryText', 'QueryText_06','Query'),
('Basic Course Information', 'CourseQueryText', 'QueryText_08','Query'),
('Basic Course Information', 'CourseQueryText', 'QueryText_09','Query'),
('Basic Course Information', 'CourseMinimumQualification', 'MinimumQualificationId', 'Update2'),
('Basic Course Information', 'CourseMinimumQualification', 'ConditionId', 'Delete'),
('Basic Course Information', 'CourseAttribute', 'DistrictCourseTypeId', 'Update3'),
('Basic Course Information', 'GenericBit', 'Bit01', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit02', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit05', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit21', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit22', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit23', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit24', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit04', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit25', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit26', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit27', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit28', 'Delete'),
('Basic Course Information', 'GenericBit', 'Bit17', 'Delete'),
('Basic Course Information', 'CourseQueryText', 'QueryText_03', 'Update4'),
('Student Learning Outcomes', 'CourseOutcome', 'OutcomeText', 'Update5'),
('Objectives:', 'CourseObjective', 'HasOptionalText', 'Delete'),
('Course Content', 'CourseSkill', 'CourseSkill', 'EXEC1'),
('Topics & Scope:', 'CourseSkillObjective', 'CourseObjectiveId', 'EXEC2'),
('Course Content', 'CourseAssignment', 'AssignmentTypeId', 'EXEC3'),
('Assignments:', 'CourseAssignmentCourseObjective', 'CourseObjectiveId', 'EXEC4'),
('Course Content', 'CourseEvaluationMethod', 'EvaluationMethodId', 'EXEC5'),
('Course Content', 'GenericBit', 'Bit03', 'EXEC6'),
('Course Content', 'CourseTextbook', 'Author', 'EXEC7'),
('Course Content', 'CourseJournal', 'Author', 'EXEC8'),
('Course Content', 'CourseManual', 'Author', 'EXEC9'),
('Course Content', 'CoursePeriodical', 'Title', 'EXEC10'),
('Course Content', 'CourseSoftware', 'Title', 'EXEC11'),
('Course Content', 'CourseTextOther', 'TextOther', 'EXEC12'),
('Basic Course Information', 'CourseGradeOption', 'GradeOptionId', 'Update6')

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
DECLARE @Sec1 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC1')
DECLARE @Sec2 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC2')
DECLARE @Sec3 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC3')
DECLARE @Sec4 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC4')
DECLARE @Sec5 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC5')
DECLARE @Sec6 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC6')
DECLARE @Sec7 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC7')
DECLARE @Sec8 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC8')
DECLARE @Sec9 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC9')
DECLARE @Sec10 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC10')
DECLARE @Sec11 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC11')
DECLARE @Sec12 int = (SELECT SectionId FROM @Fields WHERE Action = 'EXEC12')

EXEC spBuilderSectionDelete @clientId, @Sec1
EXEC spBuilderSectionDelete @clientId, @Sec2
EXEC spBuilderSectionDelete @clientId, @Sec3
EXEC spBuilderSectionDelete @clientId, @Sec4
EXEC spBuilderSectionDelete @clientId, @Sec5
EXEC spBuilderSectionDelete @clientId, @Sec6
EXEC spBuilderSectionDelete @clientId, @Sec7
EXEC spBuilderSectionDelete @clientId, @Sec8
EXEC spBuilderSectionDelete @clientId, @Sec9
EXEC spBuilderSectionDelete @clientId, @Sec10
EXEC spBuilderSectionDelete @clientId, @Sec11
EXEC spBuilderSectionDelete @clientId, @Sec12

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
-- Querytext Table Styling -- 
DECLARE @style NVARCHAR(MAX) =
'
<style>
	.credit-calculator th {
		text-align:left;
		background-color:#A4BE5C;
		border-color: Black;
	}
	.credit-calculator .type {
		text-align:center;
	}
	.credit-calculator tr {
		text-align:left;
		border-color: Black;
	}
	td,th {
		padding:3px;
		text-align:right;
	}
	.empty {
		border-top-style:none;
		border-bottom-style:none;
	}
</style>
';


-- CTE: Inputs--
WITH Inputs AS 
	(
	SELECT
		  cd.CourseId AS CourseId
		, CAST(COALESCE(cd.MinLectureHour, 0) AS DECIMAL(16, 2)) 
			AS MinLectureInClass
		, CAST(COALESCE(cd.MaxLectureHour, 0) AS DECIMAL(16, 2)) 
			AS MaxLectureInClass
		, CAST(COALESCE(cd.MinContactHoursLecture, 0) AS DECIMAL(16, 2)) 
			AS MinLectureOutOfClass
		, CAST(COALESCE(cd.MaxContactHoursLecture, 0) AS DECIMAL(16, 2)) 
			AS MaxLectureOutOfClass
		, CAST(COALESCE(cd.MinLabHour, 0) AS DECIMAL(16, 2)) 
			AS MinLabInClass
		, CAST(COALESCE(cd.MaxLabHour, 0) AS DECIMAL(16, 2)) 
			AS MaxLabInClass
		, CAST(COALESCE(cd.MinContactHoursLab, 0) AS DECIMAL(16, 2)) 
			AS MinLabOutOfClass
		, CAST(COALESCE(cd.MaxContactHoursLab, 0) AS DECIMAL(16, 2)) 
			AS MaxLabOutOfClass
		, CAST(COALESCE(cd.MinFieldHour, 0) AS DECIMAL(16, 2)) 
			AS MinActivity
		, CAST(COALESCE(cd.MaxFieldHour, 0) AS DECIMAL(16, 2)) 
			AS MaxActivity
		, CAST(COALESCE(cd.MinOtherHour, 0) AS DECIMAL(16, 2)) 
			AS TBA
		, CAST(COALESCE(cd.MinStudyHour, 0) AS DECIMAL(16, 2)) 
			AS MinAdditional
		, CAST(COALESCE(cd.MaxStudyHour, 0) AS DECIMAL(16, 2)) 
			AS MaxAdditional
		, ca.DistrictCourseTypeId AS CourseType
		, cd.Variable AS Variable
	FROM CourseDescription cd
		INNER JOIN CourseAttribute ca on cd.CourseId = ca.CourseId
	WHERE cd.courseId = @entityID
	)

-- CTE: Calculations
, Calculations AS 
	(
	SELECT 
		  i.CourseId AS courseId

		-- Min/Max Lecture In Class Term -- 
		, (18 * i.MinLectureInClass) AS MinLectureInClassTerm
		, (18 * i.MaxLectureInClass) AS MaxLectureInClassTerm

		-- Min/Max Lecture Out of Class Calculation -- 
		, CASE
			WHEN i.CourseType IN (1, 2) --Credit
				THEN (2 * i.MinLectureInClass)
			WHEN i.CourseType IN (3)   --NonCredit
				THEN i.MinLectureOutOfClass
		  END AS MinLectureOutOfClassCalc
		, CASE
			WHEN i.CourseType in (1, 2) --Credit
				THEN (2 * i.MaxLectureInClass)
			WHEN i.CourseType IN (3)   --NonCredit
				THEN i.MaxLectureOutOfClass
		  END AS MaxLectureOutOfClassCalc

		-- Min/Max Lecture Out of Class Term -- 
		, (36 * i.MinLectureInClass) AS MinLectureOutOfClassTerm
		, (36 * i.MaxLectureInClass) AS MaxLectureOutOfClassTerm

		-- Min/Max Lab In Class Term -- 
		, (18 * i.MinLabInClass) AS MinLabInClassTerm
		, (18 * i.MaxLabInClass) AS MaxLabInClassTerm

		-- Min/Max Lab Out of Class Calculation -- 
		, CASE
			WHEN i.CourseType IN (1, 2) --Credit
				THEN 0.00
			WHEN i.CourseType IN (3)    --NonCredit
				THEN i.MinLabOutOfClass
		  END AS MinLabOutOfClassCalc
		, CASE
			WHEN i.CourseType IN (1, 2) --Credit
				THEN 0.00
			WHEN i.CourseType IN (3)    --NonCredit
				THEN i.MaxLabOutOfClass
		  END AS MaxLabOutOfClassCalc

		-- Min/Max Lab Out of Class Term --
		, 0.00 AS MinLabOutOfClassTerm
		, 0.00 AS MaxLabOutOfClassTerm

		-- Min/Max Activity In Class Term -- 
		, (18 * i.MinActivity) AS MinActivityInClassTerm
		, (18 * i.MaxActivity) AS MaxActivityInClassTerm

		-- Min/Max Activity Out of Class -- 
		, CAST(.5 * i.MinActivity AS DECIMAL(16, 2)) 
			AS MinActivityOutOfClass
		, CAST(.5 * i.MaxActivity AS DECIMAL(16, 2)) 
			AS MaxActivityOutOfClass

		-- Min/Max Activity Out of Term -- 
		, (9 * i.MinActivity) AS MinActivityOutOfTerm
		, (9 * i.MaxActivity) AS MaxActivityOutOfTerm

		-- Min/Max Weekly Contact
		, (
			i.MinLectureInClass 
			+ i.MinLectureOutOfClass 
			+ i.MinLabInClass 
			+ i.MinLabOutOfClass 
			+ i.MinAdditional
		  ) 
			AS MinWeeklyContact
		, (
			i.MaxLectureInClass 
			+ i.MaxLectureOutOfClass 
			+ i.MaxLabInClass 
			+ i.MaxLabOutOfClass 
			+ i.MaxAdditional
		  ) 
			AS MaxWeeklyContact

		-- Min/Max Total Hours -- 
		, CASE
			WHEN i.CourseType IN (1, 2) --Credit
				THEN (
						  (54 * i.MinLectureInClass) 
						+ (18 * i.MinLabInClass) 
						+ (27 * i.MinActivity)
					 )
			WHEN i.CourseType IN (3)   --NonCredit 
				THEN (
						  (18 * i.MinLectureInClass) 
						+ (18 * i.MinLabInClass) 
						+ (18 * i.MinAdditional)
					 )
		  END AS MinTotalHours
		, CASE
			WHEN i.CourseType IN (1, 2) --Credit
				THEN (
						  (54 * i.MaxLectureInClass) 
						+ (18 * i.MaxLabInClass) 
						+ (27 * i.MaxActivity)
					 )
			WHEN i.CourseType IN (3)   --NonCredit
				THEN (
						  (18 * i.MaxLectureInClass) 
						+ (18 * i.MaxLabInClass) 
						+ (18 * i.MaxAdditional)
					 )
		  END AS MaxTotalHours

		-- Min/Max Total Units --
		, CASE
			WHEN i.CourseType IN (1, 2) --Credit
				THEN 
					CAST(
						i.MinLectureInClass 
						+ (FLOOR((i.MinLabInClass / 3) * 2) *.5 )
						+ (i.MinActivity / 2) 
						AS DECIMAL(16, 2)
						) 
			WHEN i.CourseType IN (3)    --NonCredit
				THEN 0
		  END AS MinUnits
		, CASE
			WHEN i.CourseType IN (1, 2) --Credit
				THEN 
					CAST(
						i.MaxLectureInClass 
						+ (FLOOR((i.MaxLabInClass / 3) * 2) *.5) 
						+ (i.MaxActivity / 2) 
						AS DECIMAL(16, 2)
						) 
			WHEN i.CourseType IN (3)   --NonCredit
				THEN 0
		  END AS MaxUnits
	FROM Inputs i
	)
-- Conditional Display of Table Fields - Credit or NonCredit --
SELECT
	CASE 
		-- Credit Course --
		WHEN i.CourseType IN (1, 2) 
			THEN CONCAT
				(
				  @style
				, '
					<table 
					 class=""credit-calculator"" 
					 border=""1"" 
					 style=""border-collapse:collapse;"" 
					 cellspacing=""1"">
					 <tr>
						<th colspan=""3"">Total Student Hours and Credit </th>
					 </tr
					<tr>
						<th>&nbsp;</th>
						<th>Hours/Week</th>
						<th>Hours/Term</th>
					</tr>
				  '				
				-- Lecture Hours - in class -- 
				, '
					<tr>
						<th>Lecture Hours - in class</th>
					<td>
				  '
				-- Hours/Week --
				, i.MinLectureInClass
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', i.MaxLectureInClass)
				  END
				, '
					</td>
					<td>
				  '
				-- Hours/Term --
				, c.MinLectureInClassTerm
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxLectureInClassTerm)
					END
				, '
					</td>
					</tr>
				  '

				-- Lecture Hours - out of class -- 
				, '
					<tr>
						<th>Lecture Hours - out of class</th>
					<td>
				  '		
				-- Hours/Week --  
				, c.MinLectureOutOfClassCalc
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxLectureOutOfClassCalc)
				  END
				, '
					</td>
					<td>
				  '
				-- Hours/Term -- 
				, c.MinLectureOutOfClassTerm
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxLectureOutOfClassTerm)
				  END
				, '
					</td>
					</tr>
				  '

				-- Lab Hours - in class --
				, '
					<tr>
						<th>Lab Hours - in class</th>
					<td>
				  '
				-- Hours/Week--
				, i.MinLabInClass
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', i.MaxLabInClass)
				  END
				, '
					</td>
					<td>
				  '
				-- Hours/Term --
				, c.MinLabInClassTerm
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxLabInClassTerm)
				  END
				, '
					</td>
					</tr>
				  '

				-- Lab Hours - out of class 
				, '
					<tr>
						<th>Lab Hours - out of class</th>
					<td>
				  '
				-- Hours/Week --
				, c.MinLabOutOfClassCalc
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxLabOutOfClassCalc)
				  END
				, '
					</td>
					<td>
				  '
				-- Hours/Term --
				, c.MinLabOutOfClassTerm
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxLabOutOfClassTerm)
				  END
				, '
					</td>
					</tr>
				  '

				-- Activity Hours - in class --
				, '
					<tr>
						<th>Activity Hours - in class</th>
					<td>
				  '
				-- Hours/Week --
				, i.MinActivity
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', i.MaxActivity)
				  END
				, '
					</td>
					<td>
				  '
				-- Hours/Term --
				, c.MinActivityInCLassTerm
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxActivityInCLassTerm)
				  END
				, '
					</td>
					</tr>
				  '
				
				-- Activity Hours - out of class --
				, '
					<tr>
						<th>Activity Hours - out of class</th>
					<td>
				  '
				-- Hours/Week --
				, c.MinActivityOutOfClass
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxActivityOutOfClass)
				  END
				, '
					</td>
					<td>
				  '
				-- Hours/Term --
				, c.MinActivityOutOfTerm
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxActivityOutOfTerm)
				  END
				, '
					</td>
					</tr>
				  '
				
				-- TBA Hours per term --
				, '
					<tr>
						<th>TBA Hours per term</th>
						
					<td colspan=""2""> 
				  '
				-- Hours/Week
				, i.TBA
				, '
					</td>
					</tr>
				  '

				-- Total Student Hours per term
				,'
					<tr>
						<th>Total Student Hours per term</th>
					<td colspan=""2"">
				  '
				-- Hours/Term --
				, c.MinTotalHours
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxTotalHours)
				  END
				, '
					</td>
					</tr>
				  '
				
				-- Hours per unit Divisor --
				, '
					<tr>
						<th>Hours per unit Divisor</th>
					<td colspan=""2"">54</td>
					</tr>
				  '
				
				-- Units of Credit --
				, '
					<tr>
						<th>Units of Credit</th>
					<td colspan=""2"">
				  '
				-- Hours/Week--
				, c.MinUnits
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxUnits)
				  END
				, '
					</th>
					</tr>
				  '
				, '</table>'
				)

		-- NonCredit Course --
		WHEN i.CourseType IN (3) 
			THEN CONCAT
				(
				  @style
				, '
					<table 
					 class=""credit-calculator"" 
					 border=""1"" 
					 style=""border-collapse:collapse;"" 
					 cellspacing=""1"">
					<tr>
						<th>&nbsp;</th>
						<th>Hours</th>
					</tr>
				  '
				-- Lecture Hours per week - in class --  
				, '
					<tr>
						<th>Lecture Hours per week - in class</th>
					<td>
				  '
				, i.MinLectureInClass
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', i.MaxLectureInClass)
				  END
				, '
					</td>
					</tr>
				  '
				
				-- Lecture Hours per week - out of class --
				, '
					<tr>
						<th>Lecture Hours per week - out of class</th>
					<td>
				  '
				, c.MinLectureOutOfClassCalc
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT (' - ', c.MaxLectureOutOfClassCalc)
				  END
				, '
					</td>
					</tr>
				  '

				-- Lab Hours per week - in class --
				, '
					<tr>
						<th>Lab Hours per week - in class</th>
					<td>
				  '
				, i.MinLabInClass
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', i.MaxLabInClass)
				  END
				, '
					</td>
					</tr>
				  '

				-- Lab Hours per week - out of class --
				, '
					<tr>
						<th>Lab Hours per week - out of class</th>
					<td>
				  '
				, c.MinLabOutOfClassCalc
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxLabOutOfClassCalc)
				  END
				, '
					</td>
					</tr>
				  '

				-- Additional Instructor Contact Hours per week
				, '
					<tr>
						<th>Additional Instructor Contact Hours per week</th>
					<td>
				  '
				, i.MinAdditional
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', i.MaxAdditional)
				  END
				, '
					</td>
					</tr>
				  '

				-- Total Contact Hours per week --
				, '
					<tr>
						<th>Total Contact Hours per week</th>
					<td>
				  '
				, c.MinWeeklyContact
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxWeeklyContact)
				  END
				, '
					</td>
					</tr>
				  '
				
				-- Total Lecture Hours --
				, '
					<tr>
						<th>Total Lecture Hours:</th>
					<td>
				  '
				, c.MinLectureInClassTerm
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxLectureInClassTerm)
				  END
				, '
					</td>
					</tr>
				  '

				-- Total Lab Hours --
				, '
					<tr>
						<th>Total Lab Hours:</th>
					<td>'
				, c.MinLabInClassTerm
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT (' - ', c.MaxLabInClassTerm)
				  END
				, '
					</td>
					</tr>
				  '

				-- Total Contact Hours --
				, '
					<tr>
						<th>Total Contact Hours:</th>
					<td>
				  '
				, c.MinTotalHours
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxTotalHours)
				  END
				, '
					</td>
					</tr>
				  '

				-- Units of Credit -- 
				, '
					<tr>
						<th>Units of Credit:</th>
					<td>
				  '
				, c.MinUnits
				, CASE
					WHEN i.Variable = 1
						THEN CONCAT(' - ', c.MaxUnits)
				  END
				, '
					</td>
					</tr>
				  '
				, '</table>'
			) 

	  END AS Text
	, 0 AS Value
FROM Calculations c
	INNER JOIN Inputs i ON c.CourseId = i.CourseId
	"
DECLARE @SQL2 NVARCHAR(MAX) = "
declare @requisites table (
Id int identity(1,1),
LeftParenthesis nvarchar(max),
RequisteTypeTitle nvarchar(max),
SubjectCode nvarchar(max),
CourseNumber nvarchar(max),
RequisiteComment nvarchar(max),
NonCourseRequirement nvarchar(max),
MinimumGrade nvarchar(max),
RightParenthesis nvarchar(max),
Condition nvarchar(max),
ProgramPlan nvarchar(max)
)

INSERT INTO @requisites
(LeftParenthesis, RequisteTypeTitle, SubjectCode, CourseNumber, RequisiteComment, NonCourseRequirement, MinimumGrade, RightParenthesis, Condition, ProgramPlan)
	SELECT
	    ''
	    ,COALESCE('<b>'+ rt.Title + '</b>' + ' ', ' ')
	    ,COALESCE(s.SubjectCode + ' ', ' ')
	    ,COALESCE(cc.CourseNumber + ' ', ' ')
	    ,CASE
			WHEN cr.EntrySkill IS NULL THEN ' '
			ELSE cr.EntrySkill + ' '
		END
        ,CASE
			WHEN cr.CourseRequisiteComment IS NULL THEN ' '
			ELSE cr.CourseRequisiteComment + ' '
		END
	    ,''
	    ,''
	    ,COALESCE(c.Title + ' ', ' ')
	    ,COALESCE(p.Title + ' ', '')
	FROM CourseRequisite cr
		LEFT JOIN RequisiteType rt ON rt.id = cr.RequisiteTypeId
		LEFT JOIN Condition c ON c.id = cr.ConditionId
		LEFT JOIN Subject s ON s.id = cr.SubjectId
		LEFT JOIN course cc ON cc.Id = cr.Requisite_CourseId
		LEFT JOIN Program p ON p.id = cr.Requisite_ProgramId
	WHERE cr.courseid = @entityId
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
    , RequisiteComment
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

	UPDATE MetaForeignKeyCriteriaClient 
	SET CustomSql = @SQL
	, ResolutionSql = @SQL
	WHERE Id = 429

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 15
WHERE MetaSelectedSectionId = (SELECT TabId FROM @Fields WHERE Action = 'Update')

DECLARE @MAX int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, Title, LookupLoadTimingType)
VALUES
(@MAX, 'CourseQueryText', 'Id', 'Title',
'Select 0 AS Value,
CONCAT(s.Title, '' '', c.CourseNumber, ''<div class = "Effective">'', ''Effective: '',
se.Title,
''</div>'', ''<div class = "LastReviewed">'', ''Last Reviewed: '',
CONVERT(varchar, cd.CourseDate, 10)
, ''</div>'') 
AS Text 
FROM Course as c 
INNER JOIN Subject as s on c.SubjectId = s.ID
LEFT JOIN CourseProposal AS cp on cp.CourseId = c.Id
LEFT JOIN CourseDate AS cd on cd.CourseId = c.Id
LEFT JOIN CourseDateType AS cdt on cd.CourseDateTypeId = cdt.Id 
LEFT JOIN Semester AS se on cp.SemesterId = se.Id
WHERE c.Id = @entityId
and cdt.Id = 5',
'Select 0 AS Value,
CONCAT(s.Title, '' '', c.CourseNumber, ''<div class = "Effective">'', ''Effective: '',
se.Title,
''</div>'', ''<div class = "LastReviewed">'', ''Last Reviewed: '',
CONVERT(varchar, cd.CourseDate, 10)
, ''</div>'') 
AS Text 
FROM Course as c 
INNER JOIN Subject as s on c.SubjectId = s.ID
LEFT JOIN CourseProposal AS cp on cp.CourseId = c.Id
LEFT JOIN CourseDate AS cd on cd.CourseId = c.Id
LEFT JOIN CourseDateType AS cdt on cd.CourseDateTypeId = cdt.Id 
LEFT JOIN Semester AS se on cp.SemesterId = se.Id
WHERE c.Id = @entityId
and cdt.Id = 5', 'CourseNumber for COR', 
2),

(@MAX + 1, 'CourseQueryText', 'Id', 'Title', 'SELECT 0 AS Value,
CONCAT(mq.Title, '' '',co.Title) AS Text
FROM CourseMinimumQualification AS cmq
INNER JOIN Course AS c on cmq.CourseId = c.Id
INNER JOIN MinimumQualification AS mq on cmq.MinimumQualificationId = mq.Id
LEFT JOIN Condition AS co on cmq.ConditionId = co.Id
WHERE c.Id = @entityId', 'SELECT 0 AS Value,
CONCAT(mq.Title, '' '',co.Title) AS Text
FROM CourseMinimumQualification AS cmq
INNER JOIN Course AS c on cmq.CourseId = c.Id
INNER JOIN MinimumQualification AS mq on cmq.MinimumQualificationId = mq.Id
LEFT JOIN Condition AS co on cmq.ConditionId = co.Id
WHERE c.Id = @entityId', 'Coure minimum qual for cor',2),

(@MAX + 2, 'CourseQueryText', 'Id', 'Title', 'SELECT 0 AS Value,
dct.Description AS Text
FROM CourseAttribute AS ca
INNER JOIN Course AS c on ca.CourseId = c.Id
INNER JOIN DistrictCourseType AS dct on ca.DistrictCourseTypeId = dct.Id
WHERE c.Id = @entityId', 'SELECT 0 AS Value,
dct.Description AS Text
FROM CourseAttribute AS ca
INNER JOIN Course AS c on ca.CourseId = c.Id
INNER JOIN DistrictCourseType AS dct on ca.DistrictCourseTypeId = dct.Id
WHERE c.Id = @entityId', 'course info for cor', 2),

(@MAX + 3, 'CourseQueryText', 'Id', 'Title', 'Select 0 AS Value,
CONCAT(''<b>Division: </b>'', oe2.Title, ''<br>'', ''<b>Department: </b>'', oe.Title) AS Text
FROM Course AS c
INNER JOIN Subject AS s on c.SubjectId = s.Id
INNER JOIN OrganizationSubject AS os on os.SubjectId = s.Id
INNER JOIN OrganizationEntity AS oe on os.OrganizationEntityId = oe.Id
INNER JOIN OrganizationLink AS ol on oe.Id = ol.Child_OrganizationEntityId
INNER JOIN OrganizationEntity AS oe2 on ol.Parent_OrganizationEntityId = oe2.Id
WHERE c.Id = @entityId', 'Select 0 AS Value,
CONCAT(''<b>Division: </b>'', oe2.Title, ''<br>'', ''<b>Department: </b>'', oe.Title) AS Text
FROM Course AS c
INNER JOIN Subject AS s on c.SubjectId = s.Id
INNER JOIN OrganizationSubject AS os on os.SubjectId = s.Id
INNER JOIN OrganizationEntity AS oe on os.OrganizationEntityId = oe.Id
INNER JOIN OrganizationLink AS ol on oe.Id = ol.Child_OrganizationEntityId
INNER JOIN OrganizationEntity AS oe2 on ol.Parent_OrganizationEntityId = oe2.Id
WHERE c.Id = @entityId', 'deparment/division for cor' ,2),

(@MAX + 4, 'CourseQueryText', 'Id', 'Title', 'SELECT 0 AS Value, 
dbo.ConcatWithSepOrdered_Agg('', '', gon.Id ,gon.Description) AS Text
FROM Course AS c
INNER JOIN CourseGradeOption AS cgo on cgo.CourseId = c.Id
INNER JOIN GradeOption AS gon on cgo.GradeOptionId = gon.Id
WHERE c.Id = @entityId', 'SELECT 0 AS Value, 
dbo.ConcatWithSepOrdered_Agg('', '', gon.Id ,gon.Description) AS Text
FROM Course AS c
INNER JOIN CourseGradeOption AS cgo on cgo.CourseId = c.Id
INNER JOIN GradeOption AS gon on cgo.GradeOptionId = gon.Id
WHERE c.Id = @entityId','grade option for cor', 2),

(@MAX + 5, 'CourseQueryText', 'Id', 'Title', 'SELECT 0 AS Value,
CONCAT( ''<ul><li>'',
dbo.ConcatWithSepOrdered_Agg(''<li>'', em.Id, em.Title), ''</ul>'') AS Text
FROM Course AS c
INNER JOIN CourseEvaluationMethod AS cem on cem.CourseId = c.Id
INNER JOIN EvaluationMethod as em on cem.EvaluationMethodId = em.Id
WHERE c.Id = @EntityId', 'SELECT 0 AS Value,
CONCAT( ''<ul><li>'',
dbo.ConcatWithSepOrdered_Agg(''<li>'', em.Id, em.Title), ''</ul>'') AS Text
FROM Course AS c
INNER JOIN CourseEvaluationMethod AS cem on cem.CourseId = c.Id
INNER JOIN EvaluationMethod as em on cem.EvaluationMethodId = em.Id
WHERE c.Id = @EntityId','eval method for cor', 2),

(@MAX + 6, 'CourseQueryText', 'Id', 'Title', 'SELECT
  0 AS Value,
  ''Cuesta General Education <br> '' + 
  STUFF((SELECT '', '' + gee.Title
         FROM CourseGE AS cg
         INNER JOIN GeneralEducationElement AS gee ON cg.GeneralEducationElementId = gee.Id
         INNER JOIN Course AS c ON cg.CourseId = c.Id
         WHERE c.Id = @EntityId
         ORDER BY gee.Title ASC
         FOR XML PATH('''')), 1, 2, '''') AS Text;' , 'SELECT
  0 AS Value,
  ''Cuesta General Education <br> '' + 
  STUFF((SELECT '', '' + gee.Title
         FROM CourseGE AS cg
         INNER JOIN GeneralEducationElement AS gee ON cg.GeneralEducationElementId = gee.Id
         INNER JOIN Course AS c ON cg.CourseId = c.Id
         WHERE c.Id = @EntityId
         ORDER BY gee.Title ASC
         FOR XML PATH('''')), 1, 2, '''') AS Text;' , 'ge for cor',2),

(@MAX + 7, 'CourseQueryText', 'Id', 'Title', 'SELECT 
	0 AS Value,
	dbo.ConcatWithSepOrdered_Agg(''<br>'', ge.Id, ge.Title) AS Text
		FROM CourseGeneralEducation AS cge
		INNER JOIN Course AS c on cge.CourseId = c.Id
		INNER JOIN GeneralEducationElement AS ge on cge.GeneralEducationElementId = ge.Id
		WHERE c.Id = @EntityId', 'SELECT 
	0 AS Value,
	dbo.ConcatWithSepOrdered_Agg(''<br>'', ge.Id, ge.Title) AS Text
		FROM CourseGeneralEducation AS cge
		INNER JOIN Course AS c on cge.CourseId = c.Id
		INNER JOIN GeneralEducationElement AS ge on cge.GeneralEducationElementId = ge.Id
		WHERE c.Id = @EntityId','ge for cor', 2),

(@MAX + 8, 'CourseQueryText', 'Id', 'Title', 'SELECT
	0 AS Value,
		CASE 
			WHEN cyt.UcApprovalSemesterId IS NOT NULL AND cyt.CsuApprovalSemesterId IS NOT NULL THEN ''UC Transfer Course<br>CSU Transfer Course''
			WHEN cyt.UcApprovalSemesterId IS NOT NULL THEN ''UC Transfer Course''
			WHEN cyt.CsuApprovalSemesterId IS NOT NULL THEN ''CSU Transfer Course''
		END AS Text
FROM Course AS c
INNER JOIN CourseYearTerm AS cyt ON cyt.CourseId = c.Id
WHERE c.Id = @EntityId;', 'SELECT
	0 AS Value,
		CASE 
			WHEN cyt.UcApprovalSemesterId IS NOT NULL AND cyt.CsuApprovalSemesterId IS NOT NULL THEN ''UC Transfer Course<br>CSU Transfer Course''
			WHEN cyt.UcApprovalSemesterId IS NOT NULL THEN ''UC Transfer Course''
			WHEN cyt.CsuApprovalSemesterId IS NOT NULL THEN ''CSU Transfer Course''
		END AS Text
FROM Course AS c
INNER JOIN CourseYearTerm AS cyt ON cyt.CourseId = c.Id
WHERE c.Id = @EntityId;', 'uc csu for cor',2),

(@MAX + 9, 'CourseQueryText', 'Id', 'Title', '
declare @textbooks nvarchar(max)
declare @manuals NVARCHAR(max)
declare @periodicals NVARCHAR(max)
declare @software NVARCHAR(max)
declare @other NVARCHAR(max)
declare @notes NVARCHAR(max)

SELECT
	@textbooks = COALESCE(@textbooks, '''') +
	CONCAT(Author, '', '',Title, 
	CASE WHEN Edition IS NOT NULL THEN CONCAT(''('', Edition, ''/e)'')
	ELSE ''''
	END
	,'', '', Publisher, '', '', City, '', '',
	CASE WHEN CalendarYear IS NOT NULL THEN CONCAT(''('', CalendarYear, '')'')
	ELSE ''''
	END,
	'','', case when IsTextbookFiveYear = 1 then ''Texts and/or readings are classics or the most recent edition is over five years old'' else '''' end, ''<br>'')
FROM CourseTextbook
WHERE CourseId = @entityId

SELECT
	@manuals = COALESCE(@manuals, '''') +
	CONCAT(Title, '', '', Author, '', '', Publisher, '', '', CalendarYear, ''<br>'')
FROM CourseManual
WHERE CourseId = @entityId

SELECT
	@periodicals = COALESCE(@periodicals, '''') +
	CONCAT(Title, '', '', Author, '', '', PublicationName, '', '', Volume, '', '', PublicationYear, ''<br>'')
FROM CoursePeriodical
WHERE courseid = @entityId

SELECT
	@software = COALESCE(@software, '''') +
	CONCAT(Title, '', '', Edition, '', '', Publisher, ''<br>'')
FROM CourseSoftware
WHERE CourseId = @entityId

SELECT
	@other = COALESCE(@other, '''') + CONCAT(TextOther, ''<br>'')
FROM CourseTextOther
WHERE CourseId = @entityId

SELECT
	@notes = COALESCE(@notes, '''') + CONCAT(Text, ''<br>'')
FROM CourseNote
WHERE courseid = @entityId

SELECT
	0 AS Value
   ,CONCAT(
   CASE WHEN @textbooks IS NULL THEN ''''
   ELSE ''<b>Textbooks:</b> <br>''
   END, @textbooks,
   CASE WHEN @manuals IS NULL THEN ''''
   ELSE ''<b>Manuals: </b><br>''
   END, @manuals,
   CASE WHEN @periodicals IS NULL THEN ''''
   ELSE ''<b>Periodicals: </b><br>''
   END, @periodicals,
   CASE WHEN @software IS NULL THEN ''''
   ELSE	''<b>Software: </b><br>''
   END, @software,
   CASE WHEN @other IS NULL THEN ''''
   ELSE	''<b>Other: </b><br>''
   END, @other,
   CASE WHEN @notes IS NULL THEN ''''
   ELSE	''<b>Notes: </b><br>''
   END, @notes
	) AS Text', 
	'
declare @textbooks nvarchar(max)
declare @manuals NVARCHAR(max)
declare @periodicals NVARCHAR(max)
declare @software NVARCHAR(max)
declare @other NVARCHAR(max)
declare @notes NVARCHAR(max)

SELECT
	@textbooks = COALESCE(@textbooks, '''') +
	CONCAT(Author, '', '',Title, 
	CASE WHEN Edition IS NOT NULL THEN CONCAT(''('', Edition, ''/e)'')
	ELSE ''''
	END
	,'', '', Publisher, '', '', City, '', '',
	CASE WHEN CalendarYear IS NOT NULL THEN CONCAT(''('', CalendarYear, '')'')
	ELSE ''''
	END,
	'','', case when IsTextbookFiveYear = 1 then ''Texts and/or readings are classics or the most recent edition is over five years old'' else '''' end, ''<br>'')
FROM CourseTextbook
WHERE CourseId = @entityId

SELECT
	@manuals = COALESCE(@manuals, '''') +
	CONCAT(Title, '', '', Author, '', '', Publisher, '', '', CalendarYear, ''<br>'')
FROM CourseManual
WHERE CourseId = @entityId

SELECT
	@periodicals = COALESCE(@periodicals, '''') +
	CONCAT(Title, '', '', Author, '', '', PublicationName, '', '', Volume, '', '', PublicationYear, ''<br>'')
FROM CoursePeriodical
WHERE courseid = @entityId

SELECT
	@software = COALESCE(@software, '''') +
	CONCAT(Title, '', '', Edition, '', '', Publisher, ''<br>'')
FROM CourseSoftware
WHERE CourseId = @entityId

SELECT
	@other = COALESCE(@other, '''') + CONCAT(TextOther, ''<br>'')
FROM CourseTextOther
WHERE CourseId = @entityId

SELECT
	@notes = COALESCE(@notes, '''') + CONCAT(Text, ''<br>'')
FROM CourseNote
WHERE courseid = @entityId

SELECT
	0 AS Value
   ,CONCAT(
   CASE WHEN @textbooks IS NULL THEN ''''
   ELSE ''<b>Textbooks:</b> <br>''
   END, @textbooks,
   CASE WHEN @manuals IS NULL THEN ''''
   ELSE ''<b>Manuals: </b><br>''
   END, @manuals,
   CASE WHEN @periodicals IS NULL THEN ''''
   ELSE ''<b>Periodicals: </b><br>''
   END, @periodicals,
   CASE WHEN @software IS NULL THEN ''''
   ELSE	''<b>Software: </b><br>''
   END, @software,
   CASE WHEN @other IS NULL THEN ''''
   ELSE	''<b>Other: </b><br>''
   END, @other,
   CASE WHEN @notes IS NULL THEN ''''
   ELSE	''<b>Notes: </b><br>''
   END, @notes
	) AS Text', 'textbook display for cor',2),

(@Max + 10, 'CourseQueryText', 'Id', 'Title', '
DECLARE @TEMP TABLE (id int, assign nvarchar(MAX), obj nvarchar(MAX))

INSERT INTO @TEMP (id, assign, obj)
SELECT 
    CASE
        WHEN ca.AssignmentTypeId = 14 THEN 14
        WHEN ca.AssignmentTypeId = 15 THEN 15
        ELSE ''''
    END AS [id],
    ca.AssignmentText AS AssignmentText,
    STUFF((SELECT CONCAT(''<li>'', co.Text, ''</li>'')
           FROM CourseAssignmentCourseObjective AS caco
           INNER JOIN CourseObjective AS co ON co.Id = caco.CourseObjectiveId
           WHERE caco.CourseAssignmentId = ca.Id
           FOR XML PATH(''''), TYPE).value(''.'', ''nvarchar(max)''), 1, 0, ''<ul>'') + ''</ul>''AS CourseObjectives
FROM Course AS c
LEFT JOIN CourseAssignment AS ca ON ca.CourseId = c.Id
WHERE c.Id = @EntityId
GROUP BY ca.AssignmentTypeId, ca.AssignmentText, ca.Id

DECLARE @TEMP2 TABLE (prints nvarchar(MAX))
INSERT INTO @TEMP2 (prints)
SELECT
CONCAT(
    CASE 
        WHEN id = 14 AND ROW_NUMBER() OVER (PARTITION BY id ORDER BY (SELECT NULL)) = 1 THEN ''Examples of independent assignments to fulfill 108 total hours of required out-of-class work:<br><ol>''
        WHEN id = 15 AND ROW_NUMBER() OVER (PARTITION BY id ORDER BY (SELECT NULL)) = 1 THEN ''</ol>Class participation and assignments require and develop critical thinking.<br><ol>''
        ELSE ''''
    END,
    CONCAT(''<li>'', assign),
    obj
) AS Text
FROM @TEMP

SELECT 0 as Value,
dbo.ConcatWithSep_Agg(''<br>'',
prints)
as Text
FROM @TEMP2', '
DECLARE @TEMP TABLE (id int, assign nvarchar(MAX), obj nvarchar(MAX))

INSERT INTO @TEMP (id, assign, obj)
SELECT 
    CASE
        WHEN ca.AssignmentTypeId = 14 THEN 14
        WHEN ca.AssignmentTypeId = 15 THEN 15
        ELSE ''''
    END AS [id],
    ca.AssignmentText AS AssignmentText,
    STUFF((SELECT CONCAT(''<li>'', co.Text, ''</li>'')
           FROM CourseAssignmentCourseObjective AS caco
           INNER JOIN CourseObjective AS co ON co.Id = caco.CourseObjectiveId
           WHERE caco.CourseAssignmentId = ca.Id
           FOR XML PATH(''''), TYPE).value(''.'', ''nvarchar(max)''), 1, 0, ''<ul>'') + ''</ul>''AS CourseObjectives
FROM Course AS c
LEFT JOIN CourseAssignment AS ca ON ca.CourseId = c.Id
WHERE c.Id = @EntityId
GROUP BY ca.AssignmentTypeId, ca.AssignmentText, ca.Id

DECLARE @TEMP2 TABLE (prints nvarchar(MAX))
INSERT INTO @TEMP2 (prints)
SELECT
CONCAT(
    CASE 
        WHEN id = 14 AND ROW_NUMBER() OVER (PARTITION BY id ORDER BY (SELECT NULL)) = 1 THEN ''Examples of independent assignments to fulfill 108 total hours of required out-of-class work:<br><ol>''
        WHEN id = 15 AND ROW_NUMBER() OVER (PARTITION BY id ORDER BY (SELECT NULL)) = 1 THEN ''</ol>Class participation and assignments require and develop critical thinking.<br><ol>''
        ELSE ''''
    END,
    CONCAT(''<li>'', assign),
    obj
) AS Text
FROM @TEMP

SELECT 0 as Value,
dbo.ConcatWithSep_Agg(''<br>'',
prints)
as Text
FROM @TEMP2', 'assignments for cor',2),

(@MAX + 11, 'CourseQueryText', 'Id', 'Title', '
DECLARE @TABLE TABLE (Description nvarchar(MAX), scope nvarchar(MAX))
INSERT INTO @TABLE (Description, scope)

SELECT 
	CAST(dbo.stripHtml (dbo.regex_replace(ck.Rationale, N''[''+nchar(8203)+N'']'', N'''')) AS NVARCHAR(MAX)),
	co.Text
    FROM CourseSkill AS ck
	LEFT JOIN CourseSkillObjective AS sko on sko.CourseSkillId = ck.Id
	INNER JOIN Course As c on ck.CourseId = c.Id
	LEFT JOIN CourseObjective AS co on sko.CourseObjectiveId = co.Id
	WHERE c.Id = @EntityId

UPDATE @TABLE SET Description = replace(Description, ''&rsquo;'' collate Latin1_General_CS_AS, ''''''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&#39;'' collate Latin1_General_CS_AS, ''''''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&nbsp;'' collate Latin1_General_CS_AS, '' ''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&amp;'' collate Latin1_General_CS_AS, ''&''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&quot;'' collate Latin1_General_CS_AS, ''"''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&euro;'' collate Latin1_General_CS_AS, ''€''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&lt;'' collate Latin1_General_CS_AS, ''<''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&gt;'' collate Latin1_General_CS_AS, ''>''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&oelig;'' collate Latin1_General_CS_AS, ''oe''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&copy;'' collate Latin1_General_CS_AS, ''©''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&laquo;'' collate Latin1_General_CS_AS, ''«''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&reg;'' collate Latin1_General_CS_AS, ''®''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&plusmn;'' collate Latin1_General_CS_AS, ''±''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&sup2;'' collate Latin1_General_CS_AS, ''²''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&sup3;'' collate Latin1_General_CS_AS, ''³''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&micro;'' collate Latin1_General_CS_AS, ''µ''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&middot;'' collate Latin1_General_CS_AS, ''·''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ordm;'' collate Latin1_General_CS_AS, ''º''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&raquo;'' collate Latin1_General_CS_AS, ''»''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&frac14;'' collate Latin1_General_CS_AS, ''¼''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&frac12;'' collate Latin1_General_CS_AS, ''½''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&frac34;'' collate Latin1_General_CS_AS, ''¾''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Aelig'' collate Latin1_General_CS_AS, ''Æ''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Ccedil;'' collate Latin1_General_CS_AS, ''Ç''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Egrave;'' collate Latin1_General_CS_AS, ''È''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Eacute;'' collate Latin1_General_CS_AS, ''É''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Ecirc;'' collate Latin1_General_CS_AS, ''Ê''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Ouml;'' collate Latin1_General_CS_AS, ''Ö''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&agrave;'' collate Latin1_General_CS_AS, ''à''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&acirc;'' collate Latin1_General_CS_AS, ''â''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&auml;'' collate Latin1_General_CS_AS, ''ä''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&aelig;'' collate Latin1_General_CS_AS, ''æ''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ccedil;'' collate Latin1_General_CS_AS, ''ç''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&egrave;'' collate Latin1_General_CS_AS, ''è''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&eacute;'' collate Latin1_General_CS_AS, ''é''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ecirc;'' collate Latin1_General_CS_AS, ''ê''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&euml;'' collate Latin1_General_CS_AS, ''ë''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&icirc;'' collate Latin1_General_CS_AS, ''î''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ocirc;'' collate Latin1_General_CS_AS, ''ô''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ouml;'' collate Latin1_General_CS_AS, ''ö''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&divide;'' collate Latin1_General_CS_AS, ''÷''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&oslash;'' collate Latin1_General_CS_AS, ''ø''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ugrave;'' collate Latin1_General_CS_AS, ''ù''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&uacute;'' collate Latin1_General_CS_AS, ''ú''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ucirc;'' collate Latin1_General_CS_AS, ''û''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&uuml;'' collate Latin1_General_CS_AS, ''ü''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&lsaquo;'' collate Latin1_General_CS_AS, ''<''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&rsaquo;'' collate Latin1_General_CS_AS, ''>''  collate Latin1_General_CS_AS)

DECLARE @TABLE2 TABLE (prints nvarchar(MAX))
INSERT INTO @TABLE2
SELECT 
    CASE
        WHEN ROW_NUMBER() OVER (ORDER BY t.Description) = 1 THEN CONCAT(''<ol><li>'', Description, ''<ul><li>'', dbo.ConcatWithSep_Agg(''<li>'', scope), ''</ul>'')
        ELSE CONCAT(''<li>'', Description, ''<ul><li>'', dbo.ConcatWithSep_Agg(''<li>'', scope), ''</ul>'')
    END AS Text
FROM @TABLE AS t
GROUP BY t.Description

SELECT 0 AS Value,
dbo.ConcatWithSep_Agg('''',prints) AS Text
FROM @TABLE2', '

DECLARE @TABLE TABLE (Description nvarchar(MAX), scope nvarchar(MAX))
INSERT INTO @TABLE (Description, scope)

SELECT 
	CAST(dbo.stripHtml (dbo.regex_replace(ck.Rationale, N''[''+nchar(8203)+N'']'', N'''')) AS NVARCHAR(MAX)),
	co.Text
    FROM CourseSkill AS ck
	LEFT JOIN CourseSkillObjective AS sko on sko.CourseSkillId = ck.Id
	INNER JOIN Course As c on ck.CourseId = c.Id
	LEFT JOIN CourseObjective AS co on sko.CourseObjectiveId = co.Id
	WHERE c.Id = @EntityId

UPDATE @TABLE SET Description = replace(Description, ''&rsquo;'' collate Latin1_General_CS_AS, ''''''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&#39;'' collate Latin1_General_CS_AS, ''''''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&nbsp;'' collate Latin1_General_CS_AS, '' ''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&amp;'' collate Latin1_General_CS_AS, ''&''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&quot;'' collate Latin1_General_CS_AS, ''"''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&euro;'' collate Latin1_General_CS_AS, ''€''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&lt;'' collate Latin1_General_CS_AS, ''<''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&gt;'' collate Latin1_General_CS_AS, ''>''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&oelig;'' collate Latin1_General_CS_AS, ''oe''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&copy;'' collate Latin1_General_CS_AS, ''©''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&laquo;'' collate Latin1_General_CS_AS, ''«''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&reg;'' collate Latin1_General_CS_AS, ''®''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&plusmn;'' collate Latin1_General_CS_AS, ''±''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&sup2;'' collate Latin1_General_CS_AS, ''²''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&sup3;'' collate Latin1_General_CS_AS, ''³''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&micro;'' collate Latin1_General_CS_AS, ''µ''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&middot;'' collate Latin1_General_CS_AS, ''·''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ordm;'' collate Latin1_General_CS_AS, ''º''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&raquo;'' collate Latin1_General_CS_AS, ''»''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&frac14;'' collate Latin1_General_CS_AS, ''¼''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&frac12;'' collate Latin1_General_CS_AS, ''½''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&frac34;'' collate Latin1_General_CS_AS, ''¾''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Aelig'' collate Latin1_General_CS_AS, ''Æ''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Ccedil;'' collate Latin1_General_CS_AS, ''Ç''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Egrave;'' collate Latin1_General_CS_AS, ''È''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Eacute;'' collate Latin1_General_CS_AS, ''É''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Ecirc;'' collate Latin1_General_CS_AS, ''Ê''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&Ouml;'' collate Latin1_General_CS_AS, ''Ö''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&agrave;'' collate Latin1_General_CS_AS, ''à''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&acirc;'' collate Latin1_General_CS_AS, ''â''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&auml;'' collate Latin1_General_CS_AS, ''ä''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&aelig;'' collate Latin1_General_CS_AS, ''æ''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ccedil;'' collate Latin1_General_CS_AS, ''ç''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&egrave;'' collate Latin1_General_CS_AS, ''è''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&eacute;'' collate Latin1_General_CS_AS, ''é''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ecirc;'' collate Latin1_General_CS_AS, ''ê''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&euml;'' collate Latin1_General_CS_AS, ''ë''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&icirc;'' collate Latin1_General_CS_AS, ''î''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ocirc;'' collate Latin1_General_CS_AS, ''ô''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ouml;'' collate Latin1_General_CS_AS, ''ö''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&divide;'' collate Latin1_General_CS_AS, ''÷''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&oslash;'' collate Latin1_General_CS_AS, ''ø''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ugrave;'' collate Latin1_General_CS_AS, ''ù''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&uacute;'' collate Latin1_General_CS_AS, ''ú''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&ucirc;'' collate Latin1_General_CS_AS, ''û''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&uuml;'' collate Latin1_General_CS_AS, ''ü''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&lsaquo;'' collate Latin1_General_CS_AS, ''<''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Description = replace(Description, ''&rsaquo;'' collate Latin1_General_CS_AS, ''>''  collate Latin1_General_CS_AS)

DECLARE @TABLE2 TABLE (prints nvarchar(MAX))
INSERT INTO @TABLE2
SELECT 
    CASE
        WHEN ROW_NUMBER() OVER (ORDER BY t.Description) = 1 THEN CONCAT(''<ol><li>'', Description, ''<ul><li>'', dbo.ConcatWithSep_Agg(''<li>'', scope), ''</ul>'')
        ELSE CONCAT(''<li>'', Description, ''<ul><li>'', dbo.ConcatWithSep_Agg(''<li>'', scope), ''</ul>'')
    END AS Text
FROM @TABLE AS t
GROUP BY t.Description

SELECT 0 AS Value,
dbo.ConcatWithSep_Agg('''',prints) 
AS Text
FROM @TABLE2', 'scope / topic for cor',2)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, MetaForeignKeyLookupSourceId = @MAX
, MetaAvailableFieldId = 8954
, DefaultDisplayType = 'QueryText'
, FieldTypeId = 5
WHERE MetaSelectedFieldId = (SELECT FieldId FROM @Fields WHERE Action = 'Update')

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, FieldTypeId = 5
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action in ('Query', 'Update4'))

UPDATE MetaForeignKeyCriteriaClient
SET ResolutionSql = CustomSql
WHERE Id = 56174201

Delete FROM MetaSelectedField
WHERE MetaSelectedFieldId in (SELECT FieldId FROM @Fields WHERE Action = 'Delete')

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 1
, MetaBaseSchemaId = NULL
, SectionName = 'Minimum Qualifications Discipline Designation MQDD:'
WHERE MetaSelectedSectionId = (SELECT SectionId FROM @Fields WHERE Action = 'Update2')

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 1
, MetaBaseSchemaId = NULL
WHERE MetaSelectedSectionId = (SELECT SectionId FROM @Fields WHERE Action = 'Update6')

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, MetaForeignKeyLookupSourceId = @MAX + 1
, MetaAvailableFieldId = 8957
, DefaultDisplayType = 'QueryText'
, FieldTypeId = 5
WHERE MetaSelectedFieldId = (SELECT FieldId FROM @Fields WHERE Action = 'Update2')

UPDATE MetaSelectedField
SET DisplayName = 'Degree Applicability:'
, MetaPresentationTypeId = 103
, MetaForeignKeyLookupSourceId = @MAX + 2
, MetaAvailableFieldId = 8958
, DefaultDisplayType = 'QueryText'
, FieldTypeId = 5
WHERE MetaSelectedFieldId = (SELECT FieldId FROM @Fields WHERE Action = 'Update3')

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 103
, MetaForeignKeyLookupSourceId = @MAX + 4
, MetaAvailableFieldId = 8960
, DefaultDisplayType = 'QueryText'
, FieldTypeId = 5
, LabelVisible = 0
WHERE MetaSelectedFieldId = (SELECT FieldId FROM @Fields WHERE Action = 'Update6')

Update DistrictCourseType
SET Description = 'Credit - Not Degree Applicable'
WHERE Id = 1

Update DistrictCourseType
SET Description = 'Credit - Degree Applicable'
WHERE Id = 2

Update DistrictCourseType
SET Description = 'Non Credit'
WHERE Id = 3

Update DistrictCourseType
SET Description = 'Work Experience'
WHERE Id = 4

UPDATE MetaSelectedField
SET RowPosition = 0
WHERE MetaSelectedFieldId = (SELECT FieldId FROM @Fields WHERE Action = 'Update4')

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 31
WHERE MetaSelectedSectionId = (SELECT SectionId FROM @Fields WHERE Action = 'Update5')

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId = (SELECT TabId FROM @Fields WHERE Action = 'Update5')

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 56174212

DECLARE @SEC int = (SELECT SectionId FROM @Fields WHERE Action = 'Update')
DECLARE @Temp int = (SELECT TemplateId FROM @Fields WHERE Action = 'Update')

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Topics & Scope:', -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
3, -- [RowPosition]
3, -- [SortOrder]
1, -- [SectionDisplayId]
15, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)

DECLARE @TabId int = SCOPE_IDENTITY()

DECLARE @SECT Table (id int, name nvarchar(max))

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
OUTPUT inserted.MetaSelectedSectionId, inserted.SectionName into @SECT (id, name)
values
(
1, -- [ClientId]
@TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Topics & Scope:', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)
,
(
1, -- [ClientId]
@TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Assignments:', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
1, -- [RowPosition]
1, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)
,
(
1, -- [ClientId]
@TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Methods of Evaluation:', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
2, -- [RowPosition]
2, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)
,
(
1, -- [ClientId]
@TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Texts, Reading, and Materials:', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
3, -- [RowPosition]
3, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)
,
(
1, -- [ClientId]
@TabId, -- [MetaSelectedSection_MetaSelectedSectionId]
'GE', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
4, -- [RowPosition]
4, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
NULL, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)

DECLARE @Top int = (SELECT id FROM @SECT WHERE name = 'Topics & Scope:')
DECLARE @Assi int = (SELECT id FROM @SECT WHERE name = 'Assignments:')
DECLARE @Metho int = (SELECT id FROM @SECT WHERE name = 'Methods of Evaluation:')
DECLARE @Text int = (SELECT id FROM @SECT WHERE name = 'Texts, Reading, and Materials:')
DECLARE @GE int = (SELECT id FROM @SECT WHERE name = 'GE')

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'QueryText', -- [DisplayName]
8959, -- [MetaAvailableFieldId]
@SEC, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
7, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX + 3, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'QueryText', -- [DisplayName]
8961, -- [MetaAvailableFieldId]
@Top, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX + 11, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'QueryText', -- [DisplayName]
8962, -- [MetaAvailableFieldId]
@Assi, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX + 10, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'QueryText', -- [DisplayName]
8963, -- [MetaAvailableFieldId]
@Metho, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX+5, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'QueryText', -- [DisplayName]
8964, -- [MetaAvailableFieldId]
@Text, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX + 9, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'QueryText', -- [DisplayName]
8965, -- [MetaAvailableFieldId]
@GE, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX + 6, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'QueryText', -- [DisplayName]
8966, -- [MetaAvailableFieldId]
@GE, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX + 7, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'QueryText', -- [DisplayName]
8967, -- [MetaAvailableFieldId]
@GE, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
103, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX + 8, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

DECLARE @jsonStatement nvarchar(max) = '.Effective{position:absolute;top: 0px; right: 15px;}.LastReviewed{position:absolute;top: 20px; right: 15px;}'


UPDATE MetaReport
set ReportAttributes = json_modify(ReportAttributes,'$.cssOverride',(select @jsonStatement as 'cssOverride'))
WHERE Id = 441
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback