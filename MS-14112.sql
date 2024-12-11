USE [ucdavis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14112';
DECLARE @Comments nvarchar(Max) = 
	'Literal Drop Down clean up';
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
DECLARE @mt Table (Id INT IDENTITY(1,1), mtId INT, Type NVARCHAR(max))
DECLARE @msf Table (Id INT IDENTITY(1,1),msfId INT, Type NVARCHAR(max))

INSERT INTO @msf (msfId, Type)
SELECT MetaSelectedFieldId, DisplayName
FROM MetaSelectedField 
WHERE MetaAvailableFieldId IN (2459)

INSERT INTO @mt (mtId, Type)
SELECT mss.MetaTemplateId, DisplayName
FROM MetaSelectedField	msf
	INNER JOIN MetaSelectedSection mss ON mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
WHERE MetaAvailableFieldId IN (2459)

DECLARE @MAX int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'DisciplineTypeId', 'Text', 'SELECT Id AS Value, Title AS Text FROM ContentReviewCategory WHERE Active = 1', 'SELECT Title AS Text FROM ContentReviewCategory WHERE Id = @Id', 'Consent of Instructor look up', 1)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (
	SELECT msfId FROM @msf WHERE Type = 'Consent of Instructor'
)

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
declare @item_id int;
      declare @open_paren nvarchar(100);
    declare @is_concurrent bit;
      declare @min_grade nvarchar(12);
      declare @course_id int;
      declare @subject_code nvarchar(20);
      declare @course_number nvarchar(20);
      declare @condition_id int;
      declare @close_paren nvarchar(100);
    declare @output nvarchar(max) = '';
      declare @inClause int = 0;
      declare @joinOp int = 3;
      declare @curPhrase nvarchar(max) = '';
          declare @consent nvarchar(200) = ( SELECT
		dt.Title
	FROM DisciplineType AS dt
	INNER JOIN Course AS c on c.DisciplineTypeId = dt.Id
	WHERE c.Id = @entityId);
        declare @recommended nvarchar(max) = ( SELECT
		RequisiteStandardText
	FROM CourseRequisiteJustification
	WHERE CourseId = @entityId);
           declare item_cursor cursor for SELECT
	cr.Id
   ,sc1.Code
   ,cr.IsConcurrent
   ,cr.MinimumGrade
   ,cr.Requisite_CourseId
   ,s.SubjectCode
   ,c.CourseNumber
   ,cr.ConditionId
   ,sc2.Code
FROM CourseRequisite cr
INNER JOIN Course c
	ON cr.Requisite_CourseId = c.Id
INNER JOIN Subject s
	ON c.SubjectId = s.Id
LEFT JOIN SpecialCharacter sc1
	ON cr.OpenParen_SpecialCharacterId = sc1.Id
LEFT JOIN SpecialCharacter sc2
	ON cr.CloseParen_SpecialCharacterId = sc2.Id
WHERE cr.CourseId = @entityId
ORDER BY cr.SortOrder
          open item_cursor
      fetch next from item_cursor into @item_id, @open_paren, @is_concurrent, @min_grade, @course_id, @subject_code, @course_number, @condition_id, @close_paren
      while @@fetch_status = 0      BEGIN
SET @curPhrase = '';
             if (@open_paren = '(' or @open_paren = '((')     begin
SET @inClause = @inClause + 1;
SET @curPhrase = (SELECT
		@curPhrase + @open_paren);
        end
SET @curPhrase = (SELECT
		@curPhrase + @subject_code + ' ' + @course_number);
        if (len(@min_grade) > 0)        BEGIN
       if(@min_grade != 'D-')      begin
       if (@min_grade != 'A')           begin
SET @curPhrase = (SELECT
		@curPhrase + ' ' + UPPER(@min_grade) + ' or better');
           end           else           begin
SET @curPhrase = (SELECT
		@curPhrase + ' ' + UPPER(@min_grade) + ' is required');
           end
       end
       END
            if (@is_concurrent = 1)       BEGIN
SET @curPhrase = (SELECT
		@curPhrase + ' { can be concurrent }');
        END
             if (@close_paren = ')' or @close_paren = '))')     BEGIN
SET @inClause =
CASE
	WHEN @inClause > 0 THEN @inClause - 1
	ELSE 0
END;
SET @curPhrase = (SELECT
		@curPhrase + @close_paren);
        END
        declare @condition int = @condition_id;
             fetch next from item_cursor into @item_id, @open_paren, @is_concurrent, @min_grade, @course_id, @subject_code, @course_number, @condition_id, @close_paren
        if (@@fetch_status = 0)         begin
          if (@condition = 2)          begin
SET @curPhrase = (SELECT
		@curPhrase + ' or');
          end          else          begin
            if (@inClause > 0)            BEGIN
SET @curPhrase = (SELECT
		@curPhrase + ', ');
            END            ELSE            BEGIN
SET @curPhrase = (SELECT
		@curPhrase + '; ');
            END
          end
         end         ELSE         BEGIN
          if (@consent is not null and @consent != '-1' or @recommended is not null)          BEGIN
SET @curPhrase = (SELECT
		@curPhrase + '; ');
          END
         END
SET @output = (SELECT
		@output + ' ' + @curPhrase);
      end
          close item_cursor
      deallocate item_cursor
          if (@consent is not null and @consent != '-1')      begin
SET @output = (SELECT
		@output + ' ' + @consent + '. ');
      end
          if (@recommended is not null)       begin
SET @output = (SELECT
		@output + ' ' + @recommended);
      END
SELECT
	@output AS Text
   ,0 AS Value;
"

SET QUOTED_IDENTIFIER ON

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 2

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId IN (SELECT mtId FROM @mt)