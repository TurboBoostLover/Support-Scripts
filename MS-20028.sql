USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-20028';
DECLARE @Comments nvarchar(Max) = 
	'Fix show hide on content review checklist';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
DECLARE @SectionsToFix TABLE (SecId int, TempId int, nam NVARCHAR(MAX))
INSERT INTO @SectionsToFix
SELECT msf.MetaSelectedSectionId, mss.MetaTemplateId, msf.DisplayName
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId in (
	2474, --Course Objective
	2833, --Course Content
	2834, --Requisite Course Content
	3776  --Requisite Course Objective
)

DECLARE @Triggers TABLE (FieldId int, TempId int)
INSERT INTO @Triggers
SELECT msf.MetaSelectedFieldId, mss.MetaTemplateId
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2832

DECLARE @Showhide TABLE (SecId int, TrigId int, TempId int, nam NVARCHAR(MAX))
INSERT INTO @Showhide
SELECT SecId, FieldId, t.TempId, nam FROM @SectionsToFix AS sf
INNER JOIN @Triggers AS t on sf.TempId = t.TempId

DELETE MetaDisplaySubscriber
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @Showhide
)

while exists(select Top 1 SecId from @Showhide)
		BEGIN

		DECLARE @Secs int = (SELECT TOP 1 SecId FROM @Showhide)
		DECLARE @Trig int = (SELECT TrigId FROM @Showhide WHERE SecId = @Secs)
		DECLARE @nam NVARCHAR(MAX) = (SELECT nam FROM @Showhide WHERE SecId = @Secs)
		DECLARE @op2 NVARCHAR(MAX) = (
			SELECT CASE
			WHEN @nam = 'Course Objective' THEN '"3,4"'
			WHEN @nam = 'Course Content' THEN '"1,2"'
			WHEN @nam = 'Requisite Course Content' THEN '"1,4"'
			WHEN @nam = 'Requisite Course Objective' THEN '"2,3"'
			ELSE NULL
			END
		)

		EXEC upAddShowHideRule 
	@TriggerselectedFieldId =  @Trig,
	@TriggerselectedSectionId = NULL,
	@displayRuleTypeId = 2,
	@ExpressionOperatorTypeId = 18,
	@ComparisonDataTypeId = 3,
	@Operand2Literal = @op2,
	@Operand3Literal = NULL,
	@listenerSelectedFieldId = NULL,
	@listenerSelectedSectionId = @Secs,
	@DisplayRuleName = 'Show Hide for Content Review selection',
	@SubscriberName = 'Show Hide for Content Review selection'

	DELETE FROM @Showhide
	WHERE SecId = @Secs

	END

DECLARE @Explain TABLE (SecId int, TempId int)
INSERT INTO @Explain
SELECT msf.MetaSelectedSectionId, mss.MetaTemplateId 
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 3871

DECLARE @ExTrig TABLE (FieldId int, TempId int)
INSERT INTO @ExTrig
SELECT msf.MetaSelectedFieldId, mss.MetaTemplateId
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 3870

DECLARE @Sho TABLE (SecId int, TrigId int)
INSERT INTO @Sho
SELECT e.SecId, et.FieldId
FROM @Explain AS e
INNER JOIN @ExTrig AS et on e.TempId = et.TempId

DELETE MetaDisplaySubscriber
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @Sho
)

while exists(select Top 1 SecId from @Sho)
		BEGIN

		DECLARE @Secs2 int = (SELECT TOP 1 SecId FROM @Sho)
		DECLARE @Trig2 int = (SELECT TrigId FROM @Sho WHERE SecId = @Secs2)

		EXEC upAddShowHideRule 
	@TriggerselectedFieldId =  @Trig2,
	@TriggerselectedSectionId = NULL,
	@displayRuleTypeId = 2,
	@ExpressionOperatorTypeId = 18,
	@ComparisonDataTypeId = 3,
	@Operand2Literal = '"1"',
	@Operand3Literal = NULL,
	@listenerSelectedFieldId = NULL,
	@listenerSelectedSectionId = @Secs2,
	@DisplayRuleName = 'Show Hide for Content Review selection',
	@SubscriberName = 'Show Hide for Content Review selection'

	DELETE FROM @Sho
	WHERE SecId = @Secs2

	END

DECLARE @ClientId int = 1

		DECLARE @SectionstoNest TABLE (SectionId int, TemplateId int, sort int, rowsa int, TabId int)
		INSERT INTO @SectionstoNest
		SELECT DISTINCT mss.MetaSelectedSectionId, mss.MetaTemplateId, mss.SortOrder, mss.RowPosition, mss.MetaSelectedSection_MetaSelectedSectionId FROM MetaSelectedSection AS mss
		INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
		INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
		INNER JOIN MetaDisplaySubscriber AS mds on mds.MetaSelectedSectionId = mss.MetaSelectedSectionId
		WHERE MetaSectionTypeId in (3, 18)
		and mtt.IsPresentationView = 0
		and mtt.ClientId = @ClientId
		and mss.MetaBaseSchemaId in (
			585, 1305
		)

	while exists(select Top 1 SectionId from @SectionstoNest)
		BEGIN

		DECLARE @SectoNest int = (SELECT TOP 1 SectionId FROM @SectionstoNest)
		DECLARE @TemplateSec int = (SELECT TemplateId FROM @SectionstoNest WHERE SectionId = @SectoNest)
		DECLARE @SortingId int = (SELECT Sort FROM @SectionstoNest WHERE SectionId = @SectoNest)
		DECLARE @RowId int = (SELECT rowsa FROM @SectionstoNest WHERE SectionId = @SectoNest)
		DECLARE @TabIdNest int = (SELECT TabId FROM @SectionstoNest WHERE SectionId = @SectoNest)

			insert into [MetaSelectedSection]
			([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
			values
			(
			@ClientId, -- [ClientId]
			@TabIdNest, -- [MetaSelectedSection_MetaSelectedSectionId]
			NULL, -- [SectionName]
			0, -- [DisplaySectionName]
			NULL, -- [SectionDescription]
			0, -- [DisplaySectionDescription]
			NULL, -- [ColumnPosition]
			@RowId, -- [RowPosition]
			@SortingId, -- [SortOrder]
			1, -- [SectionDisplayId]
			1, -- [MetaSectionTypeId]
			@TemplateSec, -- [MetaTemplateId]
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

			DECLARE @NewSecId int = SCOPE_IDENTITY()

			UPDATE MetaSelectedSection
			SET MetaSelectedSection_MetaSelectedSectionId = @NewSecId
			WHERE MetaSelectedSectionId = @SectoNest

			UPDATE MetaDisplaySubscriber
			SET MetaSelectedSectionId = @NewSecId
			WHERE MetaSelectedSectionId = @SectoNest

			DELETE FROM @SectionstoNest
			WHERE SectionId = @SectoNest

		END

DECLARE @obj TABLE (SecId int, TempId int)
INSERT INTO @obj
SELECT mss.MetaSelectedSectionId, mss.MetaTemplateId
FROM MetaSelectedSection AS mss
WHERE mss.MetaBaseSchemaId = 104

DECLARE @Validation TABLE (TabId int, TempId int)
INSERT INTO @Validation
SELECT mss.MetaSelectedSectionId, mss.MetaTemplateId
FROM MetaSelectedSection AS mss
WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
and mss.SectionName like '%Validation%'

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'triggersectionrefresh', v.TabId, obj.SecId FROM @Validation AS v
INNER JOIN @obj as obj on obj.TempId = v.TempId

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
SELECT 'FilterSubscriptionTable', 'CourseContentReview', mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
WHERE mss.MetaBaseSchemaId = 1305
UNION
SELECT 'FilterSubscriptionColumn', 'CourseRequisiteId', mss.MetaSelectedSectionId FROM MetaSelectedSection AS mss
WHERE mss.MetaBaseSchemaId = 1305

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'Select co.Id as Value,
Coalesce(co.[Text],co.GroupHeading) As Text,
cr.Id as filterValue,
cr.Id AS FilterValue
from CourseObjective co 
inner join Course c on co.CourseId = c.Id
inner join CourseRequisite cr on cr.Requisite_CourseId = c.Id
WHERE cr.Id in (
	SELECT CourseRequisiteId FROM CourseContentReview WHERE CourseId = @EntityId
)'
WHERE Id = 142

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mss.MetaBaseSchemaId in (
	585, 1305
)