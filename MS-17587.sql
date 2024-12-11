USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17587';
DECLARE @Comments nvarchar(Max) = 
	'Update query to be filtered';
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
UPDATE MetaForeignKeyCriteriaClient
sET CustomSql = '--DECLARE @Course int = (SELECT CourseRequisiteId FROM CourseContentReview WHERE Id = @fktpIdValue)

Select co.Id as Value
, Coalesce(''<b>'' + ot.Title + ''.</b> '' + co.[Text],co.GroupHeading, co.[Text], ''No Objective'') as Text  
, cr.Id as filterValue 
, cr.Id as FilterValue 
from CourseRequisite CR
	inner join CourseObjective co on cr.Requisite_CourseId = co.CourseId
	LEFT JOIN ObjectiveType ot ON co.ObjectiveTypeId = ot.Id
where CR.courseid = @entityid
--and cr.Id = @Course
ORDER BY co.CourseId, Co.SortOrder'
, LookupLoadTimingType = 3
WHERE Id = 3

DECLARE @Fields TABLE (FieldId int)
INSERT INTO @Fields
SELECT mss.MetaSelectedSectionId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE MetaAvailableFieldId = 3776

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'FilterSubscriptionTable', 'CourseContentReview', FieldId FROM @Fields
UNION
SELECT 'FilterSubscriptionColumn', 'CourseRequisiteId', FieldId FROM @Fields

DECLARE @TriggerFields TABLE (TempId int, FieldId int)
INSERT INTO @TriggerFields
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId  FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2832

DECLARE @CourseContent TABLE (TempId int, FieldId int)
INSERT INTO @CourseContent
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId  FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2833

DECLARE @ReqContent TABLE (TempId int, FieldId int)
INSERT INTO @ReqContent
SELECT mss.MetaTemplateId, msf.MetaSelectedFieldId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2834

DECLARE @CourseOBJ TABLE (TempId int, SecId int)
INSERT INTO @CourseOBJ
SELECT mss.MetaTemplateId, mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
WHERE MetaBaseSchemaId = 86
and mss.RowPosition = 6
and mss.SortOrder = 6

DECLARE @REQOBJ TABLE (TempId int, SecId int)
INSERT INTO @REQOBJ
SELECT mss.MetaTemplateId, mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
WHERE MetaBaseSchemaId = 1305

SELECT tf.TempId, tf.FieldId, co.FieldId, 4 FROM @TriggerFields AS tf INNER JOIN @CourseContent AS co on co.TempId = tf.TempId

DELETE FROM MetaDisplaySubscriber WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @CourseContent
	UNION
	SELECT FieldId FROM @ReqContent
)

DECLARE @Rules TABLE (RuleId int, ExId int)
INSERT INTO @Rules
SELECT MetaDisplayRuleId, ExpressionId FROM MetaDisplayRule AS mdr
INNER JOIN MetaDisplaySubscriber AS mds on mds.MetaDisplayRuleId = mdr.Id
WHERE mdr.Id in (
	SELECT MetaDisplayRuleId FROM MetaDisplaySubscriber WHERE MetaSelectedFieldId in (
		SELECT FieldId FROM @CourseContent
	UNION
	SELECT FieldId FROM @ReqContent
	)
	UNIOn
	SELECT MetaDisplayRuleId FROM MetaDisplaySubscriber WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @CourseOBJ
	UNION
	SELECT SecId FROM @REQOBJ
)
)

DELETE FROM MetaDisplaySubscriber WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @CourseOBJ
	UNION
	SELECT SecId FROM @REQOBJ
)

DELETE FROM MetaDisplayRule WHERE Id in (
	SELECT RuleId FROM @Rules
)

DELETE FROM ExpressionPart WHERE ExpressionId in (
	SELECT EXId FROM @Rules
)

DELETE FROM Expression WHERE Id in (
	SELECT EXId FROM @Rules
)

DECLARE @ShowHIDE TABLE (TemplateId int, TriggerId int, ListenerId int, ruleId int)
INSERT INTO @ShowHIDE
SELECT tf.TempId, tf.FieldId, SecId, 1 FROM @TriggerFields AS tf INNER JOIN @CourseOBJ AS co on co.TempId = tf.TempId

while exists(select top 1 1 from @ShowHIDE)
begin
    declare @TID int = (select top 1 TemplateId from @ShowHIDE)
		declare @Trig int = (SELECT Top 1 TriggerId FROM @ShowHIDE WHERE TemplateId = @TID)
		DECLARE @Sec int = (SELECT TOP 1 ListenerId FROM @ShowHIDE WHERE TemplateId = @TID and TriggerId = @Trig)
		exec upAddShowHideRule @Trig, null, 2, 18, 3, '"3,4,5,6"', null, null, @Sec, 'Show or Hide for Content Review', 'Show or Hide for Content Review'
		delete from @ShowHIDE WHERE TemplateId = @TID and TriggerId = @Trig and ListenerId =@SEc
end

DECLARE @ShowHIDE2 TABLE (TemplateId int, TriggerId int, ListenerId int, ruleId int)
INSERT INTO @ShowHIDE2
SELECT tf.TempId, tf.FieldId, SecId, 2 FROM @TriggerFields AS tf INNER JOIN @REQOBJ AS co on co.TempId = tf.TempId

while exists(select top 1 1 from @ShowHIDE2)
begin
    declare @TID2 int = (select top 1 TemplateId from @ShowHIDE2)
		declare @Trig2 int = (SELECT Top 1 TriggerId FROM @ShowHIDE2 WHERE TemplateId = @TID2)
		DECLARE @Sec2 int = (SELECT TOP 1 ListenerId FROM @ShowHIDE2 WHERE TemplateId = @TID2 and TriggerId = @Trig2)
		exec upAddShowHideRule @Trig2, null, 2, 18, 3, '"2,3,5,6"', null, null, @Sec2, 'Show or Hide for Content Review', 'Show or Hide for Content Review'
		delete from @ShowHIDE2 WHERE TemplateId = @TID2 and TriggerId = @Trig2 and ListenerId =@SEc2
end

DECLARE @ShowHIDE3 TABLE (TemplateId int, TriggerId int, ListenerId int, ruleId int)
INSERT INTO @ShowHIDE3
SELECT tf.TempId, tf.FieldId, co.FieldId, 3 FROM @TriggerFields AS tf INNER JOIN @ReqContent AS co on co.TempId = tf.TempId

while exists(select top 1 1 from @ShowHIDE3)
begin
    declare @TID3 int = (select top 1 TemplateId from @ShowHIDE3)
		declare @Trig3 int = (SELECT Top 1 TriggerId FROM @ShowHIDE3 WHERE TemplateId = @TID3)
		DECLARE @list int = (SELECT Top 1 ListenerId FROM @ShowHIDE3 WHERE TemplateId = @TID3 and TriggerId = @Trig3)
		exec upAddShowHideRule @Trig3, null, 2, 18, 3, '"1,4,5,6"', null, @list, null, 'Show or Hide for Content Review', 'Show or Hide for Content Review'
		delete from @ShowHIDE3 WHERE TemplateId = @TID3 and TriggerId = @Trig3 and ListenerId = @list
end

DECLARE @ShowHIDE4 TABLE (TemplateId int, TriggerId int, ListenerId int, ruleId int)
INSERT INTO @ShowHIDE4
SELECT tf.TempId, tf.FieldId, co.FieldId, 4 FROM @TriggerFields AS tf INNER JOIN @CourseContent AS co on co.TempId = tf.TempId

while exists(select top 1 1 from @ShowHIDE4)
begin
    declare @TID4 int = (select top 1 TemplateId from @ShowHIDE4)
		declare @Trig4 int = (SELECT Top 1 TriggerId FROM @ShowHIDE4 WHERE TemplateId = @TID4)
		DECLARE @list2 int = (SELECT Top 1 ListenerId FROM @ShowHIDE4 WHERE TemplateId = @TID4 and TriggerId = @Trig4)
		exec upAddShowHideRule @Trig4, null, 2, 18, 3, '"1,2,5,6"', null, @list2, NULL, 'Show or Hide for Content Review', 'Show or Hide for Content Review'
		delete from @ShowHIDE4 WHERE TemplateId = @TID4 and TriggerId = @Trig4 and ListenerId =@list2
end

DECLARE @List12 TABLE (TempId int, SecId int, ParentId int, rowpos int, sort int)
INSERT INTO @List12
SELECT mss.MetaTemplateId, mss.MetaSelectedSectionId, mss.MetaSelectedSection_MetaSelectedSectionId, mss.RowPosition, mss.SortOrder FROM MetaSelectedSection AS mss WHERE MetaBaseSchemaId in (86) and MetaSectionTypeId = 32

DECLARE @List21 TABLE (TempId int, SecId int, ParentId int, rowpos int, sort int)
INSERT INTO @List21
SELECT mss.MetaTemplateId, mss.MetaSelectedSectionId, mss.MetaSelectedSection_MetaSelectedSectionId, mss.RowPosition, mss.SortOrder FROM MetaSelectedSection AS mss WHERE MetaBaseSchemaId in (1305)

UPDATE MetaSelectedSection
SET MetaBaseSchemaId = 1305
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @List12
)

DECLARE @Parent TABLE (TempId int, SecId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaTemplateId, inserted.MetaSelectedSectionId INTO @Parent
SELECT
1, -- [ClientId]
ParentId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Current Obj', -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
rowpos, -- [RowPosition]
sort, -- [SortOrder]
1, -- [SectionDisplayId]
11, -- [MetaSectionTypeId]
TempId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
86, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @List12

DECLARE @Parent2 TABLE (TempId int, SecId int)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaTemplateId, inserted.MetaSelectedSectionId INTO @Parent2
SELECT
1, -- [ClientId]
ParentId, -- [MetaSelectedSection_MetaSelectedSectionId]
'Req Obj', -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
rowpos, -- [RowPosition]
sort, -- [SortOrder]
1, -- [SectionDisplayId]
11, -- [MetaSectionTypeId]
TempId, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
86, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
FROM @List21

UPDATE mss
SET MetaSelectedSection_MetaSelectedSectionId = p.SecId
FROM MetaSelectedSection AS mss
INNER JOIN @List12 AS l on mss.MetaSelectedSectionId = l.SecId
INNER JOIN @Parent As p on mss.MetaTemplateId = p.TempId

UPDATE mss
SET MetaSelectedSection_MetaSelectedSectionId = p.SecId
FROM MetaSelectedSection AS mss
INNER JOIN @List21 AS l on mss.MetaSelectedSectionId = l.SecId
INNER JOIN @Parent2 As p on mss.MetaTemplateId = p.TempId

UPDATE mds
SET MetaSelectedSectionId = mss.MetaSelectedSection_MetaSelectedSectionId
FROM MetaDisplaySubscriber AS mds
INNER JOIN MetaSelectedSection AS mss on mss.MetaSelectedSectionId = mds.MetaSelectedSectionId
WHERE mss.MetaSelectedSectionId in (
	SELECT SecId FROM @List12
	UNION
	SELECT SecId FROM @List21
)

DECLARE @Hide INTEGERS

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId INTO @Hide
SELECT
'Do not Delete, here to get detail form to work and checklist must be in it or show hide breaks', -- [DisplayName]
13282, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Checkbox', -- [DefaultDisplayType]
5, -- [MetaPresentationTypeId]
60, -- [Width]
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
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Parent2
UNION
SELECT
'Do not Delete, here to get detail form to work and checklist must be in it or show hide breaks', -- [DisplayName]
13281, -- [MetaAvailableFieldId]
secId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Checkbox', -- [DefaultDisplayType]
5, -- [MetaPresentationTypeId]
60, -- [Width]
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
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @Parent

INSERT INTO MetaSelectedFieldPositionPermission
(PositionId, AccessRestrictionType, MetaSelectedFieldId)
SELECT 1, 2, Id FROM @Hide

UPDATE ExpressionPart
SET Operand2Literal = 6
WHERE Id in (
108,
351,
408,
465,
522,
579,
636,
693,
750
)

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 3
)