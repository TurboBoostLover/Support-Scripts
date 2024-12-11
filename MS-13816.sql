USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13816';
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

DELETE FROM MetaLiteralList
WHERE MetaSelectedFieldId in (Select FId FROM @Templates)


UPDATE MetaSelectedField
SET MetaPresentationTypeId = 33
, DefaultDisplayType = 'TelerikCombo'
, FieldTypeId = 5
, MetaAvailableFieldId = 6804
WHERE MetaSelectedFieldId in (Select FId FROM @Templates WHERE FMA = 1436)	--FMA is MetaAvailable Field

UPDATE cmq
SET ConditionId = 
	CASE 
		WHEN cmq.OtherText = 'And' 
			THEN (SELECT Id FROM Condition WHERE Title = 'and')
		WHEN cmq.OtherText = 'Or'
			THEN (SELECT Id FROM Condition WHERE Title = 'or')
		ELSE NULL
	END
FROM CourseMinimumQualification AS cmq
INNER JOIN Course As c on cmq.CourseId = c.Id

UPDATE CourseMinimumQualification
SET OtherText = NULL
FROM CourseMinimumQualification AS cmq
INNER JOIN Course AS c on cmq.CourseId = c.ID

UPDATE AdHocReport
SET Definition = '
{"id":"54","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Min Qualifications","description":"","outputFormatId":"1","isPublic":false,"columns":[{"caption":"Subject","sorting":"Ascending","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"SubjectId_Subject_Course.SubjectSubjectCode"}},{"caption":"Course Number","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.CourseNumber"}},{"caption":"Course Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.Title"}},{"caption":"Minimum Qualification ","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"MinimumQualification_Course.Id"}},{"caption":"Condition","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"MinimumQualification_Course.ConditionTitle"}},{"caption":"Course.Course Minimum Qualification Description","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"MinimumQualification_Course.Description"}},{"caption":"Status","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"InList","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"List","value":"Active,In Review,Approved","text":"Active,In Review,Approved"}]}]}}
'
WHERE Id = 54

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT DISTINCT TId FROM @Templates
)

--commit