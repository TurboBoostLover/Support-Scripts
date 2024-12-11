USE [bhcc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13812';
DECLARE @Comments nvarchar(Max) = 
	'Update Literal DropDowns';
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
DECLARE @Templates TABLE (TId int, FId int, FMA int, DV NVARCHAR(2))
INSERT INTO @Templates (TId, FId, FMA, DV)
SELECT mt.MetaTemplateId, Msf.MetaSelectedFieldId, msf.MetaAvailableFieldId, mll.DisplayValue FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaLiteralList AS mll on mll.MetaSelectedFieldId = msf.MetaSelectedFieldId
WHERE msf.MetaPresentationTypeId = 101

DECLARE @MAXID int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, LookupLoadTimingType)
VALUES
(@MAXID, 'CourseRequisite', 'Id', 'Title', 'SELECT Id AS Value, Code AS Text FROM SpecialCharacter WHERE Code = ''(''', 'select Id as Value, Code as Text from SpecialCharacter Where id = @id', 1),
(@MAXID + 1, 'CourseRequisite', 'Id', 'Title', 'SELECT Id AS Value, Code AS Text FROM SpecialCharacter WHERE Code = '')''', 'select Id as Value, Code as Text from SpecialCharacter Where id = @id', 1)	

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 7700
,MetaForeignKeyLookupSourceId = @MAXID
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE DV = '(')	--Have to do a scring compare as the backing stores are inner twined to be able to clean up and map data over, This looks at the options from literal list to figure out which one it should be updated to

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 7701
, MetaForeignKeyLookupSourceId = @MAXID + 1
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE DV = ')')	--Have to do a scring compare as the backing stores are inner twined to be able to clean up and map data over, This looks at the options from literal list to figure out which one it should be updated to

DELETE FROM MetaLiteralList
WHERE MetaSelectedFieldId in (Select FId FROM @Templates)

DECLARE @TABLE TABLE (ID int, OpenP int, CloseP int)
INSERT INTO @TABLE
SELECT Id,
	CASE
		WHEN Parenthesis = '(' THEN 11		--Check both backing stores at the id for open parenthesis to map data over correctly
		WHEN HealthText = '(' THEN 11
		ELSE NULL
	END,
	CASE
		WHEN Parenthesis = ')' THEN 12		--Check both backing stores at the id for close parenthesis to map data over correctly
		WHEN HealthText = ')' THEN 12
		ELSE NULL
	END
FROM CourseRequisite

UPDATE CourseRequisite
SET OpenParen_SpecialCharacterId = OpenP
, CloseParen_SpecialCharacterId = CloseP			--Move data over
FROM @TABLE AS t
WHERE CourseRequisite.Id = t.ID


SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
declare @item_id int;
declare @open_paren nvarchar(100);
declare @course_id int;
declare @subject_code nvarchar(20);
declare @course_number nvarchar(20);
declare @condition_id int;
declare @close_paren nvarchar(100);
declare @output nvarchar(max) = '';
declare @inClause bit = 0;
declare @joinOp int = 3;
declare @curPhrase nvarchar(max) = '';
declare @reqType nvarchar(max) = '';
declare @reqTypeComparison nvarchar(max) = '';
declare @comment nvarchar(max) = '';
declare item_cursor 
cursor for SELECT
	 COALESCE(cr.Id,'')
	,COALESCE(sc2.Code,'')
	,COALESCE(cr.Requisite_CourseId,'')
	,COALESCE(s.SubjectCode,'')
	,COALESCE(c.CourseNumber,'')
	,COALESCE(cr.ConditionId,'')
	,COALESCE(sc.Code,'')
	,COALESCE(rt.Title,'')
	,COALESCE(cr.CourseRequisiteComment,'')
FROM CourseRequisite cr
LEFT JOIN Course c
	ON cr.Requisite_CourseId = c.Id
LEFT JOIN Subject s
	ON c.SubjectId = s.Id
LEFT JOIN RequisiteType rt
	ON cr.RequisiteTypeId = rt.Id
LEFT JOIN SpecialCharacter sc
	ON cr.CloseParen_SpecialCharacterId = sc.Id
LEFT JOIN SpecialCharacter sc2
	ON cr.OpenParen_SpecialCharacterId = sc2.Id
WHERE cr.CourseId = @entityId
AND rt.Title IN ('Prerequisite', 'Co-requisite')
ORDER BY cr.RequisiteTypeId
        open item_cursor
         fetch next from item_cursor into @item_id, @open_paren, @course_id, @subject_code, @course_number, @condition_id, @close_paren, @reqType, @comment
    while @@fetch_status = 0    BEGIN
SET @curPhrase = '';
           if (@open_paren = '(')      begin
SET @inClause = 1;
SET @curPhrase = (SELECT
		@curPhrase + @open_paren);
      end
        if (@reqType != @reqTypeComparison)   begin
SET @curPhrase = (SELECT
		@curPhrase + @reqType + ': ' + @subject_code + ' ' + @course_number + ' ' + @comment);
SET @reqTypeComparison = @reqType;
   end   else   begin
SET @curPhrase = (SELECT
		@curPhrase + @subject_code + ' ' + @course_number + ' ' + @comment);
   end
     if (@close_paren = ')')      BEGIN
SET @inClause = 0;
SET @curPhrase = (SELECT
		@curPhrase + @close_paren);
      END
           declare @condition int = @condition_id;
           fetch next from item_cursor into @item_id, @open_paren, @course_id, @subject_code, @course_number, @condition_id, @close_paren, @reqType, @comment
            if (@@fetch_status = 0)       begin
        if (@condition = 2)        begin
SET @curPhrase = (SELECT
		@curPhrase + ' or');
        end        else        begin
          if (@inClause = 1)          BEGIN
SET @curPhrase = (SELECT
		@curPhrase + ', ');
          END          ELSE          BEGIN
SET @curPhrase = (SELECT
		@curPhrase + '; ');
          END
        end
       end
SET @output = (SELECT
		@output + ' ' + @curPhrase);
    end
        close item_cursor
    deallocate item_cursor
          DECLARE @Description NVARCHAR(MAX) = ( SELECT
		c.Description
	FROM Course c
	WHERE c.Id = @entityId)
SELECT
	@Description + ' ' + @output AS Text
	,0 AS Value;
"

SET QUOTED_IDENTIFIER ON

UPDATE cr
SET HealthText = NULL
, Parenthesis = NULL							---Remove data after mapped
FROM CourseRequisite AS cr
INNER JOIN Course AS c on cr.CourseId = c.Id

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL						--Update SQL where needed (both are already the same to begin with)
WHERE Id in (12, 33)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT TId FROM @Templates
)

--commit