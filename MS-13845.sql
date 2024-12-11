USE [uaeu];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13845';
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
DECLARE @MAXID int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, LookupLoadTimingType)
VALUES
(@MAXID, 'CourseRequisite', 'Id', 'Title', 'SELECT Id AS Value, Code AS Text FROM SpecialCharacter WHERE Code in (''('', '')'')', 'select Id as Value, Code as Text from SpecialCharacter Where id = @id', 1)

DECLARE @Templates TABLE (TId int, FId int, FMA int)
INSERT INTO @Templates (TId, FId, FMA)
SELECT mt.MetaTemplateId, Msf.MetaSelectedFieldId, msf.MetaAvailableFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss ON msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 ON mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss2.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE msf.MetaPresentationTypeId = 101

DELETE FROM MetaLiteralList
WHERE MetaSelectedFieldId in (Select FId FROM @Templates)

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA in (876, 1260, 1203))	--FMA is MetaAvailable Field		--Template Inactive, nothing using it

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 7700
, MetaForeignKeyLookupSourceId = @MAXID
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 2751)	--FMA is MetaAvailable Field
-------------------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE CourseRequisite
SET OpenParen_SpecialCharacterId = 
	CASE
		WHEN Parenthesis = '(' THEN 11
		WHEN Parenthesis = ')' THEN 12
		ELSE NULL
	END
FROM CourseRequisite as cr
WHERE Parenthesis IS NOT NULL
--------------------------------------------------------------------------------------------------------------------------------------------------------------
Update AdHocReport
SET Definition = '
{"id":"16","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Course_Requisites","description":"","outputFormatId":"1","isPublic":false,"columns":[{"caption":"Course.Subject Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"SubjectId_Subject_Course.SubjectSubjectCode"}},{"caption":"Course Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.CourseNumber"}},{"caption":"Course.Status Alias Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"}},{"caption":"Course.Requisite.Requisite Course Subject Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseInfo_RequisiteCourseId_CourseRequisite_Course.SubjectCode"}},{"caption":"Course.Requisite.Requisite Course Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseRequisite_Course.CourseNumber"}},{"caption":"Course.Requisite.Related Course Course Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseInfo_RelatedCourseId_CourseRequisite_Course.CourseTitle"}},{"caption":"Course.Requisite Minimum Grade","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseRequisite_Course.MinimumGrade"}},{"caption":"Course.Requisite Condition Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseRequisite_Course.ConditionTitle"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"active","text":"active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Contains","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"SubjectId_Subject_Course.SubjectSubjectCode"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"phys","text":"phys"}]}]}}
'
WHERE Id = 16

Update AdHocReport
SET Definition = '
{"id":"19","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Sample_Course_detail","description":"","outputFormatId":"1","isPublic":false,"columns":[{"caption":"Course.Subject Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"SubjectId_Subject_Course.SubjectSubjectCode"}},{"caption":"Course Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.CourseNumber"}},{"caption":"Course Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.Title"}},{"caption":"Course.Course Description Min Credit Hour","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"VEA_25"}},{"caption":"Course Lecture Outline","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.LectureOutline"}},{"caption":"Course.Course Outcome Outcome Text","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Outcome_Course.OutcomeText"}},{"caption":"Course.Course Textbook Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseTextbook_Course.Title"}},{"caption":"Course.Course Textbook Author","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseTextbook_Course.Author"}},{"caption":"Course.Course Textbook Edition","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseTextbook_Course.Edition"}},{"caption":"Course.Course Textbook Calendar Year","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseTextbook_Course.CalendarYear"}},{"caption":"Course.Course Textbook Publisher","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseTextbook_Course.Publisher"}},{"caption":"Course.Course Textbook ISBN","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseTextbook_Course.IsbnNum"}},{"caption":"Course Lab Outline","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.LabOutline"}},{"caption":"Course.Distance Education Assign Differ","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseDistanceEducation.AssignDiffer"}},{"caption":"Course.Requisite.Subject Code","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseRequisite_Course.SubjectCode"}},{"caption":"Course.Requisite.Requisite Course Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseRequisite_Course.CourseNumber"}},{"caption":"Course.Requisite.Requisite Course Course Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseRequisite_Course.CourseTitle"}},{"caption":"Course.Requisite Minimum Grade","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseRequisite_Course.MinimumGrade"}},{"caption":"Course.Requisite Condition Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CourseRequisite_Course.ConditionTitle"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Active","text":"Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Course.CourseNumber"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"270","text":"270"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"SubjectId_Subject_Course.SubjectSubjectCode"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"PHYS","text":"PHYS"}]}]}}
'
WHERE Id = 19
--------------------------------------------------------------------------------------------------------------------------------------------------------------
DELETE FROM MetaLiteralList
WHERE MetaSelectedFieldId NOT IN (
	SELECT MetaSelectedFieldId FROM MetaSelectedField AS msf		--Just to ensure everything that is not type 101 has no literal list record
		WHERE MetaPresentationTypeId = 101
)
----------------------------------------------------------------------------------------------------------------------------------------------------------------
UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT TId FROM @Templates
)

--commit