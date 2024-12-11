USE [tacoma];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13843';
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
DECLARE @Templates TABLE (TId int, FId int, FMA int)
INSERT INTO @Templates (TId, FId, FMA)
SELECT mt.MetaTemplateId, Msf.MetaSelectedFieldId, msf.MetaAvailableFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
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
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2088)	--FMA is MetaAvailable Field

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 7701
, MetaForeignKeyLookupSourceId = @MAXID + 1
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2751)	--FMA is MetaAvailable Field

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 6440
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 286)	--FMA is MetaAvailable Field

INSERT INTO MinimumGrade
(Code, SortOrder, ClientId,StartDate)
VALUES
('A', 1, 1, CURRENT_TIMESTAMP),
('A-', 2, 1, CURRENT_TIMESTAMP),
('B+', 3, 1, CURRENT_TIMESTAMP),
('B', 4, 1, CURRENT_TIMESTAMP),
('B-', 5, 1, CURRENT_TIMESTAMP),
('C+', 6, 1, CURRENT_TIMESTAMP),
('C', 7, 1, CURRENT_TIMESTAMP),
('C-', 8, 1, CURRENT_TIMESTAMP),
('D+', 9, 1, CURRENT_TIMESTAMP),
('D', 10, 1, CURRENT_TIMESTAMP)

UPDATE cr
SET MinimumGradeId = mg.Id
FROM CourseRequisite cr
	INNER JOIN MinimumGrade mg ON cr.MinimumGrade = mg.Code
WHERE cr.MinimumGrade IS NOT NULL;

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
DECLARE @PrerequisiteString NVARCHAR(MAX) = NULL;
  DECLARE @CorequisiteString NVARCHAR(MAX) = NULL;
  DECLARE @OtherString NVARCHAR(MAX) = NULL;
    DECLARE @source TABLE (Id INT NOT NULL IDENTITY, RequisiteType NVARCHAR(MAX), SubjectCode NVARCHAR(MAX), CourseNumber NVARCHAR(MAX), OpenParan NVARCHAR(MAX)
	, CloseParan NVARCHAR(MAX),  Condition NVARCHAR(MAX), OtherRequisite NVARCHAR(MAX), SortOrder INT, IsNonCourse BIT, IsMinGrade BIT, MinimumGrade NVARCHAR(20)
	,IsConcurrent BIT, OrEquivalent BIT, CourseRequisiteComment NVARCHAR(MAX))
INSERT INTO @Source
--OUTPUT INSERTED.*
	SELECT
		rt.Title
	   ,s.SubjectCode
	   ,c.CourseNumber
	   ,sc.Code
	   ,sc2.Code
	   ,cd.Title
	   ,cr.EntrySkill
	   ,cr.SortOrder
	   ,cr.Bit04
	   ,cr.IsMinGrade
	   ,mg.Code
	   ,cr.IsConcurrent
	   ,cr.Bit05
	   ,cr.CourseRequisiteComment
	FROM CourseRequisite cr
	LEFT JOIN Course c
		ON cr.Requisite_CourseId = c.Id
	LEFT JOIN [Subject] s
		ON c.SubjectId = s.Id
	LEFT JOIN RequisiteType rt
		ON cr.RequisiteTypeId = rt.Id
	LEFT JOIN Condition cd
		ON cr.ConditionId = cd.Id
	LEFT JOIN SpecialCharacter As sc
		ON sc.Id = cr.OpenParen_SpecialCharacterId
	LEFT JOIN SpecialCharacter As sc2
		ON sc2.Id = cr.CloseParen_SpecialCharacterId
	LEFT JOIN MinimumGrade AS mg
		ON mg.Id = cr.MinimumGradeId
	WHERE cr.CourseId = @entityId
	AND rt.Title IS NOT NULL
	ORDER BY cr.SortOrder
    DECLARE @numberOfRequistesInPreReq INT = ( SELECT
		COUNT(*)
	FROM @Source
	WHERE RequisiteType = 'Prerequisite')
  DECLARE @lastRecordIdIdInPreqReq INT = ( SELECT
		MAX(Id)
	FROM @Source
	WHERE RequisiteType = 'Prerequisite')
  DECLARE @numberOfRequistesInCoreq INT = ( SELECT
		COUNT(*)
	FROM @Source
	WHERE RequisiteType = 'Corequisite')
  DECLARE @lastRecordIdIdInCoreq INT = ( SELECT
		MAX(Id)
	FROM @Source
	WHERE RequisiteType = 'Corequisite')
  DECLARE @numberOfRequisitesInOther INT = ( SELECT
		COUNT(*)
	FROM @Source
	WHERE RequisiteType = 'Recommended Preparation')
  DECLARE @LastRecordIdIdInOther INT = ( SELECT
		MAX(Id)
	FROM @Source
	WHERE RequisiteType = 'Recommended Preparation')
    DECLARE @isParamOpen BIT = 0;
	WHILE EXISTS (SELECT 1 FROM @source)
	BEGIN
	 DECLARE @currId INT = (SELECT MIN(Id) FROM @source)
	 DECLARE @currRequisiteType NVARCHAR(MAX) = (SELECT RequisiteType FROM @Source WHERE iD = @currid)
	 DECLARE @currOpenParan NVARCHAR(MAX) = (SELECT OpenParan FROM @Source WHERE iD = @currid)
	 DECLARE @currCloseParan NVARCHAR(MAX) = (SELECT CloseParan FROM @Source WHERE iD = @currid)
	 DECLARE @currCourseNumber NVARCHAR(MAX) = (SELECT CourseNumber FROM @Source WHERE iD = @currid)
	 DECLARE @currCondition NVARCHAR(MAX) = (SELECT Condition FROM @Source WHERE iD = @currid)
	 DECLARE @currSubjectCode NVARCHAR(MAX) = (SELECT SubjectCode FROM @Source WHERE iD = @currid)
	 DECLARE @currIsMinGrade NVARCHAR(MAX) = (SELECT IsMinGrade FROM @Source WHERE iD = @currid)
	 DECLARE @currMinGrade NVARCHAR(MAX) = (SELECT MinimumGrade FROM @Source WHERE iD = @currid)
	 DECLARE @currIsNonCourse NVARCHAR(MAX) = (SELECT IsNonCourse FROM @Source WHERE iD = @currid)
	 DECLARE @OtherRequisite NVARCHAR(MAX) = (SELECT OtherRequisite FROM @Source WHERE iD = @currid)
	 DECLARE @IsLastReq BIT = NULL
	 DECLARE @IsConcurrent BIT = (SELECT IsConcurrent FROM @source WHERE Id = @currid);
	 DECLARE @OrEquivalent BIT = (SELECT OrEquivalent FROM @source WHERE Id = @currid);
	 DECLARE @AdditionalInformation NVARCHAR(MAX) = (SELECT CourseRequisiteComment FROM @Source WHERE iD = @currid)
	 IF(@currRequisiteType = 'Prerequisite')
	 BEGIN
	 SET @IsLastReq = (SELECT CASE WHEN Id = @lastRecordIdIdInPreqReq THEN 1 ELSE 0 END FROM @source WHERE Id = @currId AND RequisiteType = 'Prerequisite')
	 IF(@PrerequisiteString IS NULL)
	 BEGIN
	 SET @PrerequisiteString = '<strong>Prerequisite:</strong> '
	 END
	 SET @PrerequisiteString += ' '
	 IF(@currOpenParan = '(')
	 BEGIN
	 SET @PrerequisiteString += @currOpenParan
	 SET @isParamOpen = 1
	 END
	 IF(@OtherRequisite IS NOT NULL AND @currIsNonCourse  = 1)
	 BEGIN
	 SET @PrerequisiteString += LTRIM(RTRIM(@OtherRequisite));
	 END
	 IF(@currSubjectCode IS NOT NULL AND (@currIsNonCourse  = 0 OR @currIsNonCourse IS NULL))
	 BEGIN
	 SET @PrerequisiteString += LTRIM(RTRIM(@currSubjectCode));
	 END
	 IF(@currCourseNumber IS NOT NULL AND (@currIsNonCourse  = 0 OR @currIsNonCourse IS NULL))
	 BEGIN
	 SET @PrerequisiteString += ' ' + LTRIM(RTRIM(@currCourseNumber));
	 END
	 IF(@currIsMinGrade = 1)
	 BEGIN
	 SET @PrerequisiteString += ' with a minimum grade of ' + LTRIM(RTRIM(@currMinGrade));
	 END
	 IF(@IsConcurrent = 1)
	 BEGIN
	 SET @PrerequisiteString += ' (may be taken concurrently) ';
	 END
	 IF(@OrEquivalent = 1)
	 BEGIN
	 SET @PrerequisiteString += ' or equivalent ';
	 END
	 IF(@AdditionalInformation IS NOT NULL)
	 BEGIN
	 SET @PrerequisiteString += ' ' + @AdditionalInformation;
	 END
	 IF(@currCloseParan = ')')
	 BEGIN
	 SET @PrerequisiteString += @currCloseParan
	 SET @isParamOpen = 0
	 END
	 IF (@IsLastReq = 0)
	 BEGIN
	 SET @PrerequisiteString += ' ' + coalesce(@currCondition, '') + ' '
	 END
	 ELSE 
	 BEGIN 
	 SET @PrerequisiteString += '<br>'
	 END
	 SET @PrerequisiteString += ' '
	 END
	 IF(@currRequisiteType = 'Corequisite')
	 BEGIN
	 SET @IsLastReq = (SELECT CASE WHEN Id = @lastRecordIdIdInCoreq THEN 1 ELSE 0 END FROM @source WHERE Id = @currId AND RequisiteType = 'Corequisite')
	 IF(@CorequisiteString IS NULL)
	 BEGIN
	 SET @CorequisiteString = '<strong>Corequisite:</strong> '
	 END
	 SET @CorequisiteString += ' '
	 IF(@currOpenParan = '(')
	 BEGIN
	 SET @CorequisiteString += @currOpenParan
	 SET @isParamOpen = 1
	 END
	 IF(@OtherRequisite IS NOT NULL AND @currIsNonCourse  = 1)
	 BEGIN
	 SET @CorequisiteString += LTRIM(RTRIM(@OtherRequisite));
	 END
	 IF(@currSubjectCode IS NOT NULL AND (@currIsNonCourse  = 0 OR @currIsNonCourse IS NULL))
	 BEGIN
	 SET @CorequisiteString += LTRIM(RTRIM(@currSubjectCode));
	 END
	 IF(@currCourseNumber IS NOT NULL AND (@currIsNonCourse  = 0 OR @currIsNonCourse IS NULL))
	 BEGIN
	 SET @CorequisiteString += ' ' +LTRIM(RTRIM(@currCourseNumber));
	 END
	 IF(@AdditionalInformation IS NOT NULL)
	 BEGIN
	 SET @CorequisiteString += ' ' + @AdditionalInformation;
	 END
	 IF(@currCloseParan = ')')
	 BEGIN
	 SET @CorequisiteString += @currCloseParan
	 SET @isParamOpen = 0
	 END
	 IF (@IsLastReq = 0)
	 BEGIN
	 SET @CorequisiteString += ' ' + coalesce(@currCondition, '') + ' '
	 END
	 ELSE 
	 BEGIN 
	 SET @CorequisiteString += '<br>'
	 END
	 SET @CorequisiteString += ' '
	 END
	 IF(@currRequisiteType = 'Recommended Preparation') 
	 BEGIN      
	 SET @IsLastReq = (SELECT CASE WHEN Id = @LastRecordIdIdInOther THEN 1 ELSE 0 END FROM @source WHERE Id = @currId AND RequisiteType = 'Recommended Preparation')      
	 IF(@OtherString IS NULL) 
	 BEGIN     
	 SET @OtherString = '<strong>Recommended Preparation:</strong>'    
	 END      
	 SET @OtherString += ' '      
	 IF(@currOpenParan = '(') 
	 BEGIN     
	 SET @OtherString += @currOpenParan     
	 SET @isParamOpen = 1    
	 END        
	 IF(@OtherRequisite IS NOT NULL AND @currIsNonCourse  = 1) 
	 BEGIN     
	 SET @OtherString += LTRIM(RTRIM(@OtherRequisite));    
	 END       
	 IF(@currSubjectCode IS NOT NULL AND (@currIsNonCourse  = 0 OR @currIsNonCourse IS NULL)) 
	 BEGIN     
	 SET @OtherString += LTRIM(RTRIM(@currSubjectCode));    
	 END     
	 IF(@currCourseNumber IS NOT NULL AND (@currIsNonCourse  = 0 OR @currIsNonCourse IS NULL)) 
	 BEGIN     
	 SET @OtherString += ' ' +LTRIM(RTRIM(@currCourseNumber));    
	 END      
	 IF(@currIsMinGrade = 1) 
	 BEGIN     
	 SET @OtherString += ' with a minimum grade of' + LTRIM(RTRIM(@currMinGrade));    
	 END
	 IF(@AdditionalInformation IS NOT NULL)
	 BEGIN
	 SET @OtherString += ' ' + @AdditionalInformation;
	 END
	 IF(@currCloseParan = ')') 
	 BEGIN     
	 SET @OtherString += @currCloseParan     
	 SET @isParamOpen = 0    
	 END
	 IF (@IsLastReq = 0) 
	 BEGIN     
	 SET @OtherString += ' ' + coalesce(@currCondition, '') + ' '    
	 END
	 ELSE 
	 BEGIN 
	 SET @OtherString += '<br>'
	 END
	 SET @OtherString += ' '     
	 END -- end of other     -- increment   
	 DELETE FROM @source   
	 WHERE Id = @currId  
	 END
	 DECLARE @FinalString NVARCHAR(MAX) = COALESCE(@PrerequisiteString + ' ' + @CorequisiteString + ' ' + @OtherString + ' '
	 , @PrerequisiteString + ' ' + @CorequisiteString + ' '
	 , @CorequisiteString + ' ' + @OtherString + ' '
	 , @PrerequisiteString + ' ' + @OtherString + ' '
	 , @PrerequisiteString + ' '
	 , @CorequisiteString + ' '
	 , @OtherString + ' ')
	 SELECT @FinalString AS Text, 0 AS Value
"

SET QUOTED_IDENTIFIER ON

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 2

DECLARE @TABLE TABLE (Id int, dropdown int)
INSERT INTO @TABLE
SELECT Id, 
	CASE 
		WHEN HealthText = '(' THEN 11
		ELSE NULL
	END
FROM CourseRequisite
WHERE HealthText IS NOT NULL

DECLARE @TABLE2 TABLE (Id int, dropdown2 int)
INSERT INTO @TABLE2
SELECT Id, 
	CASE 
		WHEN Parenthesis = ')' THEN 12
		ELSE NULL
	END
FROM CourseRequisite
WHERE Parenthesis IS NOT NULL

UPDATE CourseRequisite
SET OpenParen_SpecialCharacterId = t.dropdown
FROM @TABLE AS t
WHERE CourseRequisite.Id = t.Id

UPDATE CourseRequisite
SET CloseParen_SpecialCharacterId = t.dropdown2
FROM @TABLE2 AS t
WHERE CourseRequisite.Id = t.Id

DELETE FROM MetaLiteralList
WHERE MetaSelectedFieldId in (Select FId FROM @Templates)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT TId FROM @Templates
)