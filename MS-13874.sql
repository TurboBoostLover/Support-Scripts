USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13874';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Outline reports';
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
UPDATE MetaReport
SET Title = 'CCCCO Report'
, ReportAttributes = '{"reportTemplateId":34,"isPublicReport":"false","sectionRenderingStrategy":"HideEmptySections","fieldRenderingStrategy":"HideEmptyFields"}'
WHERE Id = 211

UPDATE MetaReport
SET Title = 'CCCCO Report - PDF'
, ReportAttributes = '{"reportTemplateId":34,"isPublicReport":"false","sectionRenderingStrategy":"HideEmptySections","fieldRenderingStrategy":"HideEmptyFields"}'
WHERE Id = 1211

UPDATE MetaReport
SET Title = 'Course Outline'
WHERE Id = 225

UPDATE MetaReport
SET Title = 'Course Outline - PDF'
WHERE Id = 1225

----------------------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @ClientCode nvarchar(50) = NULL ;
DECLARE @InitialTableName NVARCHAR(100);
SET @InitialTableName = 'MetaSelectedSection';
DECLARE @InitialId int = 403;
DECLARE @ClientId Int = 1;
DECLARE @OverrideClientId Int = Coalesce((Select Id from Client where Code =  @ClientCode ),(Select top 1 Id from Client where Active = 1));
DECLARE @SourceDatabase NVARCHAR(100) = 'chaffey';
DECLARE @SourceTemplateTypeId Int = 16;
DECLARE @SourceTemplateId int  = 16;
DECLARE @InsertToMetaTemplateId int = 37; --Set this if inserting sections into a different template Id from the extrated template
DECLARE @InsertToMetaTemplateTypeId int = 24; --Set this if inserting sections into a different template type Id from the extrated template
DECLARE @SourceParentSectionId int ; --Do not set this variable
DECLARE @TargetParentSectionId int ; --Do not set this here set it below if necessary
 

If @InitialId is not NULL and (Select MetaSelectedSection_MetaSelectedSectionId from MetaSelectedSection where MetaSelectedSectionId = @InitialId) Is Not NULL
BEGIN
	Print' Set @TargetParentSectionId = (Select MetaSelectedSection_MetaSelectedSectionId from MetaSelectedSection where MetaSelectedSectionId = ' + @InitialId + '); --Change this if inserting sections into a different Parent Section'

	Print 'SET @SourceParentSectionId='(SELECT MetaSelectedSection_MetaSelectedSectionId
		  FROM MetaSelectedSection
		  WHERE MetaSelectedSectionId= @InitialId ); --Do not change this setting'
END
      
DECLARE @MetaTemplateId int;
DECLARE @MetaTemplateTypeId int;

If @InsertToMetaTemplateId is NULL 
Begin
SET @MetaTemplateId = @SourceTemplateId ;
END
Else 
Begin
SET @MetaTemplateId = @InsertToMetaTemplateId ;
End
DECLARE @AddReports bit = 0;
DECLARE @ProcessId int;
/*
      @ProcessId can be manually changed by uncommenting the following line and adding a valid destination ProcessId.
      It will then insert the new ProcessId if it is valid into the new ProcessProposalType records
*/
 --SET @ProcessId = ; 
DECLARE @CopyStepToFieldIdMapping bit = 1;
/*This can be manually changed by uncommenting the following line*/
 --SET @CopyStepToFieldIdMapping = 0; 
DECLARE @CopyPositions bit = 1;
/*This can be manually changed by uncommenting the following line*/
 --SET @CopyPositions = 0; 
DECLARE @CopyPositionPermissions bit = 1;
/*This can be manually changed by uncommenting the following line*/
 --SET @CopyPositionPermissions = 0; 
 
IF upper(DB_NAME()) <> Upper(@SourceDatabase)
BEGIN;	
	SET @CopyStepToFieldIdMapping = 0;
END;

DECLARE @UserId int;
 Set @UserId = 
	(SELECT top 1 Id FROM [User] 
	WHERE Email like 'SupportAdmin%@CurrIQunet.com' 
	AND ClientId = @ClientId
	);

If @UserId is null
Begin
	 Set @UserId = 
		(SELECT top 1 Id FROM [User] 
		WHERE Email like 'SupportAdmin%@CurrIQunet.com'
		);
End

--================== Create the KeyTranslation Table ===========================

Drop Table If Exists #KeyTranslation

CREATE TABLE #KeyTranslation
(
	DestinationTable NVARCHAR(255),
	OldId INT,
	NewId int
)
CREATE NONCLUSTERED INDEX IDXKeyTranslation
ON #KeyTranslation (DestinationTable);
	
--================== END Create the KeyTranslation Table =======================

--=================Begin Entity Organization Origination========================
		
-- Get EntityOrganizationOrigination
Declare  @EntityOrganizationOriginationTempTable Table
(EntityOrganizationOrigination_ClientId nVarchar(Max),EntityOrganizationOrigination_EntityTypeId nVarchar(Max),EntityOrganizationOrigination_OrganizationTierId nVarchar(Max));

Insert into @EntityOrganizationOriginationTempTable

(EntityOrganizationOrigination_ClientId,EntityOrganizationOrigination_EntityTypeId,EntityOrganizationOrigination_OrganizationTierId)
Output Inserted.*
 Values
(1,6,1)
,
(1,2,1)
,
(1,6,2)
,
(1,2,2)
;
-- Insert EntityOrganizationOrigination into Destination Database


If @SourceDatabase  = DB_NAME()
Begin

;WITH SourceData AS
( 
Select EntityOrganizationOrigination_ClientId,EntityOrganizationOrigination_EntityTypeId,EntityOrganizationOrigination_OrganizationTierId
From @EntityOrganizationOriginationTempTable tt
)

Merge Into EntityOrganizationOrigination as Target
USING SourceData sd ON 
sd.EntityOrganizationOrigination_ClientId = Target.ClientId
And sd.EntityOrganizationOrigination_EntityTypeId = Target.EntityTypeId
And sd.EntityOrganizationOrigination_OrganizationTierId = Target.OrganizationTierId
WHEN NOT MATCHED BY TARGET THEN

Insert (ClientId,EntityTypeId,OrganizationTierId)
Values (sd.EntityOrganizationOrigination_ClientId,sd.EntityOrganizationOrigination_EntityTypeId,sd.EntityOrganizationOrigination_OrganizationTierId)

--OUTPUT 'EntityOrganizationOrigination',sd.EntityOrganizationOrigination_Id, inserted.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);
OUTPUT 'EntityOrganizationOrigination',Inserted.* ;
End

--=================End Entity Organization Origination==========================

--=======================Begin Meta SELECTed Section============================

	
		
	-- Get MetaSelectedSection
	DECLARE  @MetaSelectedSectionTempTable Table
	(MetaSelectedSection_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedSection_ClientId NVARCHAR(MAX),MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedSection_SectionName NVARCHAR(MAX),MetaSelectedSection_DisplaySectionName NVARCHAR(MAX),MetaSelectedSection_SectionDescription NVARCHAR(MAX),MetaSelectedSection_DisplaySectionDescription NVARCHAR(MAX),MetaSelectedSection_ColumnPosition NVARCHAR(MAX),MetaSelectedSection_RowPosition NVARCHAR(MAX),MetaSelectedSection_SortOrder NVARCHAR(MAX),MetaSelectedSection_SectionDisplayId NVARCHAR(MAX),MetaSelectedSection_MetASectionTypeId NVARCHAR(MAX),MetaSelectedSection_MetaTemplateId NVARCHAR(MAX),MetaSelectedSection_DisplayFieldId NVARCHAR(MAX),MetaSelectedSection_HeaderFieldId NVARCHAR(MAX),MetaSelectedSection_FooterFieldId NVARCHAR(MAX),MetaSelectedSection_OriginatorOnly NVARCHAR(MAX),MetaSelectedSection_MetaBASeSchemaId NVARCHAR(MAX),MetaSelectedSection_MetadataAttributeMapId NVARCHAR(MAX),MetaSelectedSection_EntityListLibraryTypeId NVARCHAR(MAX),MetaSelectedSection_EditMapId NVARCHAR(MAX),MetaSelectedSection_AllowCopy NVARCHAR(MAX),MetaSelectedSection_ReadOnly NVARCHAR(MAX),MetaSelectedSection_Config NVARCHAR(MAX));
	

	INSERT INTO @MetaSelectedSectionTempTable
	(MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_ClientId,MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_SectionName,MetaSelectedSection_DisplaySectionName,MetaSelectedSection_SectionDescription,MetaSelectedSection_DisplaySectionDescription,MetaSelectedSection_ColumnPosition,MetaSelectedSection_RowPosition,MetaSelectedSection_SortOrder,MetaSelectedSection_SectionDisplayId,MetaSelectedSection_MetASectionTypeId,MetaSelectedSection_MetaTemplateId,MetaSelectedSection_DisplayFieldId,MetaSelectedSection_HeaderFieldId,MetaSelectedSection_FooterFieldId,MetaSelectedSection_OriginatorOnly,MetaSelectedSection_MetaBASeSchemaId,MetaSelectedSection_MetadataAttributeMapId,MetaSelectedSection_EntityListLibraryTypeId,MetaSelectedSection_EditMapId,MetaSelectedSection_AllowCopy,MetaSelectedSection_ReadOnly,MetaSelectedSection_Config)
	OUTPUT INSERTED.*
	VALUES
	
(403,1,NULL,'DE Addendum',1,'this section will only show if this is on a older template that uses the old DE PAge',0,NULL,12,12,1,15,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(404,1,403,'Regular and Effective Instructor-Student Contact Practices',1,NULL,0,NULL,4,2,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(405,1,403,'',1,NULL,0,NULL,5,3,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(406,1,403,NULL,1,NULL,0,NULL,6,4,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(407,1,403,'Instructor/Student Contact:',1,NULL,0,NULL,7,5,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(408,1,403,'1. Announcements select any that may be used:',1,NULL,0,NULL,8,6,1,23,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(409,1,403,'Frequency of Announcements (regular contact):',1,NULL,0,NULL,9,7,1,23,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(410,1,403,'2. Email: Select any that may be used to demonstrate regular effective contact.',1,NULL,0,NULL,10,8,1,23,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(411,1,403,'Frequency of email (regular contact):',1,NULL,0,NULL,11,9,1,23,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(412,1,403,'Student-to-Instructor Interaction',1,NULL,0,NULL,12,10,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(413,1,403,'Please explain the expected frequency of student-to-instructor contact as well as the intended methods for this contact.',1,NULL,0,NULL,13,11,1,23,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(414,1,403,'Student-to-Student Interaction',1,NULL,0,NULL,14,12,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(415,1,403,'How do students contact each other in this distance education course?',1,NULL,0,NULL,15,13,1,23,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(416,1,403,'Student Learning Outcomes',1,NULL,0,NULL,16,14,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(417,1,403,'Supplemental Meetings',1,NULL,0,NULL,17,15,1,23,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(418,1,403,NULL,1,NULL,0,NULL,18,16,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(419,1,403,'Accessibility Checklist: Web Content Accessibility Guidelines
',1,NULL,0,NULL,19,17,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(451,1,403,NULL,1,NULL,0,NULL,1,0,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(452,1,403,NULL,1,NULL,0,NULL,2,1,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
;
-- INSERT MetaSelectedSection INTO Destination Database
	IF @MetaTemplateId <> (SELECT Top 1 MetaSelectedSection_MetaTemplateId FROM @MetaSelectedSectionTempTable)
	BEGIN
		UPDATE @MetaSelectedSectionTempTable
		SET MetaSelectedSection_MetaTemplateId = @MetaTemplateId
		
		--SELECT * FROM @MetaSelectedSectionTempTable --For troubleshooting
	END 
	
;WITH SourceData AS
	( 
	SELECT MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_ClientId,MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_SectionName,MetaSelectedSection_DisplaySectionName,MetaSelectedSection_SectionDescription,MetaSelectedSection_DisplaySectionDescription,MetaSelectedSection_ColumnPosition,MetaSelectedSection_RowPosition,MetaSelectedSection_SortOrder,MetaSelectedSection_SectionDisplayId,MetaSelectedSection_MetASectionTypeId,
	COALESCE(kt.NewId, @MetaTemplateId,MetaSelectedSection_MetaTemplateId) AS MetaSelectedSection_MetaTemplateId,NULL AS MetaSelectedSection_DisplayFieldId,NULL AS MetaSelectedSection_HeaderFieldId,NULL AS MetaSelectedSection_FooterFieldId,MetaSelectedSection_OriginatorOnly,MetaSelectedSection_MetaBASeSchemaId,NULL AS MetaSelectedSection_MetadataAttributeMapId,NULL AS MetaSelectedSection_EntityListLibraryTypeId,NULL AS MetaSelectedSection_EditMapId,MetaSelectedSection_AllowCopy,MetaSelectedSection_ReadOnly,MetaSelectedSection_Config
	FROM @MetaSelectedSectionTempTable tt 
	LEFT JOIN #KeyTranslation kt ON kt.OldId = tt.MetaSelectedSection_MetaTemplateId
		AND DestinationTable = 'MetaTemplate'
	)
MERGE INTO MetaSelectedSection
	USING SourceData sd ON (1 = 0)
	WHEN Not Matched By Target THEN
	INSERT (ClientId,MetaSelectedSection_MetaSelectedSectionId,SectionName,DisplaySectionName,SectionDescription,DisplaySectionDescription,ColumnPosition,RowPosition,SortOrder,SectionDisplayId,MetASectionTypeId,MetaTemplateId,DisplayFieldId,HeaderFieldId,FooterFieldId,OriginatorOnly,MetaBASeSchemaId,MetadataAttributeMapId,EntityListLibraryTypeId,EditMapId,AllowCopy,ReadOnly,Config)
	VALUES (@ClientId,NULL,sd.MetaSelectedSection_SectionName,sd.MetaSelectedSection_DisplaySectionName,sd.MetaSelectedSection_SectionDescription,sd.MetaSelectedSection_DisplaySectionDescription,sd.MetaSelectedSection_ColumnPosition,sd.MetaSelectedSection_RowPosition,sd.MetaSelectedSection_SortOrder,sd.MetaSelectedSection_SectionDisplayId,sd.MetaSelectedSection_MetASectionTypeId,sd.MetaSelectedSection_MetaTemplateId,NULL,NULL,NULL,sd.MetaSelectedSection_OriginatorOnly,sd.MetaSelectedSection_MetaBASeSchemaId,NULL,sd.MetaSelectedSection_EntityListLibraryTypeId,sd.MetaSelectedSection_EditMapId,sd.MetaSelectedSection_AllowCopy,sd.MetaSelectedSection_ReadOnly,sd.MetaSelectedSection_Config)
	OUTPUT 'MetaSelectedSection',sd.MetaSelectedSection_MetaSelectedSectionId, INSERTED.MetaSelectedSectionId INTO #KeyTranslation (DestinationTable, OldId, NewId);

	UPDATE tbl
	SET MetaSelectedSection_MetaSelectedSectionId = kt2.NewId
	FROM MetaSelectedSection tbl
	INNER JOIN #KeyTranslation kt ON kt.NewId = tbl.MetaSelectedSectionId
	AND kt.DestinationTable= 'MetaSelectedSection'
	INNER JOIN @MetaSelectedSectionTempTable tt ON kt.OldId = tt.MetaSelectedSection_MetaSelectedSectionId
	INNER JOIN #KeyTranslation kt2 ON kt2.OldId = tt.MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId
	AND kt2.DestinationTable= 'MetaSelectedSection'
	;

--========================End Meta Selected Section=============================

	

--=================Begin Meta Selected Section Attribute========================

	
		
-- Get MetaSelectedSectionAttribute
DECLARE  @MetaSelectedSectionAttributeTempTable Table
(MetaSelectedSectionAttribute_Id NVARCHAR(MAX),MetaSelectedSectionAttribute_GroupId NVARCHAR(MAX),MetaSelectedSectionAttribute_AttributeTypeId NVARCHAR(MAX),MetaSelectedSectionAttribute_Name NVARCHAR(MAX),MetaSelectedSectionAttribute_Value NVARCHAR(MAX),MetaSelectedSectionAttribute_MetaSelectedSectionId NVARCHAR(MAX));

INSERT INTO @MetaSelectedSectionAttributeTempTable
(MetaSelectedSectionAttribute_Id,MetaSelectedSectionAttribute_GroupId,MetaSelectedSectionAttribute_AttributeTypeId,MetaSelectedSectionAttribute_Name,MetaSelectedSectionAttribute_Value,MetaSelectedSectionAttribute_MetaSelectedSectionId)
OUTPUT INSERTED.*
 VALUES
(3785,1,1,'ShouldDisplayCheckQuery','
SELECT 
case
    WHen c.MetaTemplateId >= 39 then 0
    else 1
END as ShouldDisplay
FROM Course c
WHERE c.Id = @entityId;
',403)
,
(472,1,1,'ParentTable','CourseDistanceEducationContact',408)
,
(473,1,1,'ForeignKeyToParent','CourseId',408)
,
(474,1,1,'LookupTable','ContactType',408)
,
(475,1,1,'ForeignKeyToLookup','ContactTypeId',408)
,
(476,1,1,'ColumnCount','2',408)
,
(477,1,1,'ParentTable','CourseDistanceEducationContact',409)
,
(478,1,1,'ForeignKeyToParent','CourseId',409)
,
(479,1,1,'LookupTable','ContactType',409)
,
(480,1,1,'ForeignKeyToLookup','ContactTypeId',409)
,
(481,1,1,'ColumnCount','2',409)
,
(482,1,1,'ParentTable','CourseDistanceEducationContact',410)
,
(483,1,1,'ForeignKeyToParent','CourseId',410)
,
(484,1,1,'LookupTable','ContactType',410)
,
(485,1,1,'ForeignKeyToLookup','ContactTypeId',410)
,
(486,1,1,'ColumnCount','2',410)
,
(487,1,1,'ParentTable','CourseDistanceEducationContact',411)
,
(488,1,1,'ForeignKeyToParent','CourseId',411)
,
(489,1,1,'LookupTable','ContactType',411)
,
(490,1,1,'ForeignKeyToLookup','ContactTypeId',411)
,
(491,1,1,'ColumnCount','2',411)
,
(492,1,1,'ParentTable','CourseDistanceEducationContact',413)
,
(493,1,1,'ForeignKeyToParent','CourseId',413)
,
(494,1,1,'LookupTable','ContactType',413)
,
(495,1,1,'ForeignKeyToLookup','ContactTypeId',413)
,
(496,1,1,'ColumnCount','2',413)
,
(497,1,1,'ParentTable','CourseDistanceEducationContact',415)
,
(498,1,1,'ForeignKeyToParent','CourseId',415)
,
(499,1,1,'LookupTable','ContactType',415)
,
(500,1,1,'ForeignKeyToLookup','ContactTypeId',415)
,
(501,1,1,'ColumnCount','2',415)
,
(502,1,1,'ParentTable','CourseDistanceEducationContact',417)
,
(503,1,1,'ForeignKeyToParent','CourseId',417)
,
(504,1,1,'LookupTable','ContactType',417)
,
(505,1,1,'ForeignKeyToLookup','ContactTypeId',417)
,
(506,1,1,'ColumnCount','2',417)
;
-- INSERT MetaSelectedSectionAttribute INTO Destination Database


;WITH SourceData AS
( 
SELECT MetaSelectedSectionAttribute_Id,MetaSelectedSectionAttribute_GroupId,MetaSelectedSectionAttribute_AttributeTypeId,MetaSelectedSectionAttribute_Name,MetaSelectedSectionAttribute_Value,kt.NewId AS MetaSelectedSectionAttribute_MetaSelectedSectionId
FROM @MetaSelectedSectionAttributeTempTable tt 	
INNER JOIN #KeyTranslation kt ON MetaSelectedSectionAttribute_MetaSelectedSectionId =kt.OldId
    AND DestinationTable = 'MetaSelectedSection'
)
MERGE INTO MetaSelectedSectionAttribute
USING SourceData sd ON (1 = 0)
WHEN Not Matched By Target THEN
INSERT (GroupId,AttributeTypeId,Name,Value,MetaSelectedSectionId)
VALUES (sd.MetaSelectedSectionAttribute_GroupId,sd.MetaSelectedSectionAttribute_AttributeTypeId,sd.MetaSelectedSectionAttribute_Name,sd.MetaSelectedSectionAttribute_Value,sd.MetaSelectedSectionAttribute_MetaSelectedSectionId);
--OUTPUT 'MetaSelectedSectionAttribute',sd.MetaSelectedSectionAttribute_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);

--===================End Meta Selected Section Attribute========================

--=================Begin Meta Foreign Key Criteria Client=======================

SET NOCOUNT ON;

Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds, x thousands, x tenthousands--, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	
	SET NOCOUNT OFF;
		
-- Get MetaForeignKeyCriteriaClient
DECLARE  @MetaForeignKeyCriteriaClientTempTable Table
(row_num NVARCHAR(MAX),MetaForeignKeyCriteriaClient_Id NVARCHAR(MAX),MetaForeignKeyCriteriaClient_TableName NVARCHAR(MAX),MetaForeignKeyCriteriaClient_DefaultValueColumn NVARCHAR(MAX),MetaForeignKeyCriteriaClient_DefaultDisplayColumn NVARCHAR(MAX),MetaForeignKeyCriteriaClient_CustomSql NVARCHAR(MAX),MetaForeignKeyCriteriaClient_ResolutionSql NVARCHAR(MAX),MetaForeignKeyCriteriaClient_DefaultSortColumn NVARCHAR(MAX),MetaForeignKeyCriteriaClient_Title NVARCHAR(MAX),MetaForeignKeyCriteriaClient_LookupLoadTimingType NVARCHAR(MAX),MetaForeignKeyCriteriaClient_PickListId NVARCHAR(MAX),MetaForeignKeyCriteriaClient_IsSeeded NVARCHAR(MAX));

INSERT INTO @MetaForeignKeyCriteriaClientTempTable

(row_num,MetaForeignKeyCriteriaClient_Id,MetaForeignKeyCriteriaClient_TableName,MetaForeignKeyCriteriaClient_DefaultValueColumn,MetaForeignKeyCriteriaClient_DefaultDisplayColumn,MetaForeignKeyCriteriaClient_CustomSql,MetaForeignKeyCriteriaClient_ResolutionSql,MetaForeignKeyCriteriaClient_DefaultSortColumn,MetaForeignKeyCriteriaClient_Title,MetaForeignKeyCriteriaClient_LookupLoadTimingType,MetaForeignKeyCriteriaClient_PickListId,MetaForeignKeyCriteriaClient_IsSeeded)
OUTPUT INSERTED.*
 VALUES
(1,146,'ContactType','Id','Title','
		select Id as [Value]
			, Title as [Text]
		from ContactType
		where (Active = 1
			or EndDate > getDate()
		)
		and ParentId = (
			select Id
			from ContactType
			where Title = ''Announcements Parent''
			and (Active = 1
				or EndDate > getDate()
			)
		)
	','Select Title as Text from ContactType where Id = @id','Order by SortOrder','announcements override',2,NULL,NULL)
,
(2,147,'ContactType','Id','Title','
		select Id as [Value]
			, Title as [Text]
		from ContactType
		where (Active = 1
			or EndDate > getDate()
		)
		and ParentId = (
			select Id
			from ContactType
			where Title = ''Frequency Announcements Parent''
			and (Active = 1
				or EndDate > getDate()
			)
		)
	','Select Title as Text from ContactType where Id = @id','Order by SortOrder','announcement frequency override',2,NULL,NULL)
,
(3,148,'ContactType','Id','Title','
		select Id as [Value]
			, Title as [Text]
		from ContactType
		where (Active = 1
			or EndDate > getDate()
		)
		and ParentId = (
			select Id
			from ContactType
			where Title = ''Email Announcements Parent''
			and (Active = 1
				or EndDate > getDate()
			)
		)
	','Select Title as Text from ContactType where Id = @id','Order by SortOrder','email announcement override',2,NULL,NULL)
,
(4,149,'ContactType','Id','Title','
		select Id as [Value]
			, Title as [Text]
		from ContactType
		where (Active = 1
			or EndDate > getDate()
		)
		and ParentId = (
			select Id
			from ContactType
			where Title = ''Email Frequency Parent''
			and (Active = 1
				or EndDate > getDate()
			)
		)
	','Select Title as Text from ContactType where Id = @id','Order by SortOrder','email frequency override',2,NULL,NULL)
,
(5,150,'ContactType','Id','Title','
		select Id as [Value]
			, Title as [Text]
		from ContactType
		where (Active = 1
			or EndDate > getDate()
		)
		and ParentId = (
			select Id
			from ContactType
			where Title = ''Regular Effect Contact Parent''
			and (Active = 1
				or EndDate > getDate()
			)
		)
	','Select Title as Text from ContactType where Id = @id','Order by SortOrder','regular effect contact override',2,NULL,NULL)
,
(6,151,'ContactType','Id','Title','
		select Id as [Value]
			, Title as [Text]
		from ContactType
		where (Active = 1
			or EndDate > getDate()
		)
		and ParentId = (
			select Id
			from ContactType
			where Title = ''Student Announcements Parent''
			and (Active = 1
				or EndDate > getDate()
			)
		)
	','Select Title as Text from ContactType where Id = @id','Order by SortOrder','regular effect contact override',2,NULL,NULL)
,
(7,152,'ContactType','Id','Title','
		select Id as [Value]
			, Title as [Text]
		from ContactType
		where (Active = 1
			or EndDate > getDate()
		)
		and ParentId = (
			select Id
			from ContactType
			where Title = ''Supplemental Meetings Parent''
			and (Active = 1
				or EndDate > getDate()
			)
		)
	','Select Title as Text from ContactType where Id = @id','Order by SortOrder','supplemental meetings override',2,NULL,NULL)
;
-- INSERT MetaForeignKeyCriteriaClient INTO Destination Database



;WITH SourceData AS
( 
SELECT si.Id,MetaForeignKeyCriteriaClient_Id, MetaForeignKeyCriteriaClient_TableName, MetaForeignKeyCriteriaClient_DefaultValueColumn,MetaForeignKeyCriteriaClient_DefaultDisplayColumn,MetaForeignKeyCriteriaClient_CustomSql,MetaForeignKeyCriteriaClient_ResolutionSql,MetaForeignKeyCriteriaClient_DefaultSortColumn,
MetaForeignKeyCriteriaClient_Title,MetaForeignKeyCriteriaClient_LookupLoadTimingType,MetaForeignKeyCriteriaClient_PickListId,MetaForeignKeyCriteriaClient_IsSeeded
FROM @MetaForeignKeyCriteriaClientTempTable tt
inner join  #SeedIds si on si.row_num	= tt.row_num
)

MERGE INTO MetaForeignKeyCriteriaClient
USING SourceData sd ON 
	(TableName = MetaForeignKeyCriteriaClient_TableName  or (TableName is null AND MetaForeignKeyCriteriaClient_TableName is null))
	AND
	(DefaultValueColumn = MetaForeignKeyCriteriaClient_DefaultValueColumn or (DefaultValueColumn is null AND MetaForeignKeyCriteriaClient_DefaultValueColumn is null))
	AND
	(DefaultDisplayColumn = MetaForeignKeyCriteriaClient_DefaultDisplayColumn or (DefaultDisplayColumn is null AND MetaForeignKeyCriteriaClient_DefaultDisplayColumn is null))
	AND
	(CustomSql = MetaForeignKeyCriteriaClient_CustomSql or (CustomSql is null AND MetaForeignKeyCriteriaClient_CustomSql is null))
	AND
	(ResolutionSql = MetaForeignKeyCriteriaClient_ResolutionSql or (ResolutionSql is null AND MetaForeignKeyCriteriaClient_ResolutionSql is null))
	AND
	(DefaultSortColumn = MetaForeignKeyCriteriaClient_DefaultSortColumn or (DefaultSortColumn is null AND MetaForeignKeyCriteriaClient_DefaultSortColumn is null))
	AND
	(Title = MetaForeignKeyCriteriaClient_Title or (Title is null AND MetaForeignKeyCriteriaClient_Title is null))
	AND
	(PickListId = MetaForeignKeyCriteriaClient_PickListId or (PickListId is null AND MetaForeignKeyCriteriaClient_PickListId is null))
	AND
	(LookupLoadTimingType = MetaForeignKeyCriteriaClient_LookupLoadTimingType or (LookupLoadTimingType is null AND MetaForeignKeyCriteriaClient_LookupLoadTimingType is null))
	AND
	(IsSeeded = MetaForeignKeyCriteriaClient_IsSeeded or (IsSeeded is null AND MetaForeignKeyCriteriaClient_IsSeeded is null))
WHEN Not Matched By Target THEN
INSERT (Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,Title,LookupLoadTimingType,PickListId,IsSeeded)
VALUES (Id,sd.MetaForeignKeyCriteriaClient_TableName,sd.MetaForeignKeyCriteriaClient_DefaultValueColumn,sd.MetaForeignKeyCriteriaClient_DefaultDisplayColumn,
	sd.MetaForeignKeyCriteriaClient_CustomSql,sd.MetaForeignKeyCriteriaClient_ResolutionSql,sd.MetaForeignKeyCriteriaClient_DefaultSortColumn,
	sd.MetaForeignKeyCriteriaClient_Title,sd.MetaForeignKeyCriteriaClient_LookupLoadTimingType,sd.MetaForeignKeyCriteriaClient_PickListId,
	sd.MetaForeignKeyCriteriaClient_IsSeeded)
WHEN Matched THEN UPDATE
SET TableName = MetaForeignKeyCriteriaClient_TableName
OUTPUT 'MetaForeignKeyCriteriaClient',sd.MetaForeignKeyCriteriaClient_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);

--==================End Meta Foreign Key Criteria Client========================



--=======================Begin Meta Selected Field==============================

		
-- Get MetaSelectedField
DECLARE  @MetaSelectedFieldTempTable Table
(MetaSelectedField_MetaSelectedFieldId NVARCHAR(MAX),MetaSelectedField_DisplayName NVARCHAR(MAX),MetaSelectedField_MetaAvailableFieldId NVARCHAR(MAX),MetaSelectedField_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedField_IsRequired NVARCHAR(MAX),MetaSelectedField_MinCharacters NVARCHAR(MAX),MetaSelectedField_MaxCharacters NVARCHAR(MAX),MetaSelectedField_RowPosition NVARCHAR(MAX),MetaSelectedField_ColPosition NVARCHAR(MAX),MetaSelectedField_ColSpan NVARCHAR(MAX),MetaSelectedField_DefaultDisplayType NVARCHAR(MAX),MetaSelectedField_MetaPresentationTypeId NVARCHAR(MAX),MetaSelectedField_Width NVARCHAR(MAX),MetaSelectedField_WidthUnit NVARCHAR(MAX),MetaSelectedField_Height NVARCHAR(MAX),MetaSelectedField_HeightUnit NVARCHAR(MAX),MetaSelectedField_AllowLabelWrap NVARCHAR(MAX),MetaSelectedField_LabelHAlign NVARCHAR(MAX),MetaSelectedField_LabelVAlign NVARCHAR(MAX),MetaSelectedField_LabelStyleId NVARCHAR(MAX),MetaSelectedField_LabelVisible NVARCHAR(MAX),MetaSelectedField_FieldStyle NVARCHAR(MAX),MetaSelectedField_EditDisplayOnly NVARCHAR(MAX),MetaSelectedField_GroupName NVARCHAR(MAX),MetaSelectedField_GroupNameDisplay NVARCHAR(MAX),MetaSelectedField_FieldTypeId NVARCHAR(MAX),MetaSelectedField_ValidationRuleId NVARCHAR(MAX),MetaSelectedField_LiteralValue NVARCHAR(MAX),MetaSelectedField_ReadOnly NVARCHAR(MAX),MetaSelectedField_AllowCopy NVARCHAR(MAX),MetaSelectedField_Precision NVARCHAR(MAX),MetaSelectedField_MetaForeignKeyLookupSourceId NVARCHAR(MAX),MetaSelectedField_MetadataAttributeMapId NVARCHAR(MAX),MetaSelectedField_EditMapId NVARCHAR(MAX),MetaSelectedField_NumericDataLength NVARCHAR(MAX),MetaSelectedField_Config NVARCHAR(MAX));

INSERT INTO @MetaSelectedFieldTempTable

(MetaSelectedField_MetaSelectedFieldId,MetaSelectedField_DisplayName,MetaSelectedField_MetaAvailableFieldId,MetaSelectedField_MetaSelectedSectionId,MetaSelectedField_IsRequired,MetaSelectedField_MinCharacters,MetaSelectedField_MaxCharacters,MetaSelectedField_RowPosition,MetaSelectedField_ColPosition,MetaSelectedField_ColSpan,MetaSelectedField_DefaultDisplayType,MetaSelectedField_MetaPresentationTypeId,MetaSelectedField_Width,MetaSelectedField_WidthUnit,MetaSelectedField_Height,MetaSelectedField_HeightUnit,MetaSelectedField_AllowLabelWrap,MetaSelectedField_LabelHAlign,MetaSelectedField_LabelVAlign,MetaSelectedField_LabelStyleId,MetaSelectedField_LabelVisible,MetaSelectedField_FieldStyle,MetaSelectedField_EditDisplayOnly,MetaSelectedField_GroupName,MetaSelectedField_GroupNameDisplay,MetaSelectedField_FieldTypeId,MetaSelectedField_ValidationRuleId,MetaSelectedField_LiteralValue,MetaSelectedField_ReadOnly,MetaSelectedField_AllowCopy,MetaSelectedField_Precision,MetaSelectedField_MetaForeignKeyLookupSourceId,MetaSelectedField_MetadataAttributeMapId,MetaSelectedField_EditMapId,MetaSelectedField_NumericDataLength,MetaSelectedField_Config)
OUTPUT INSERTED.*
 VALUES
(664,'To view best practices on Regular Effective Contact, please view this link: <a href="http://test.curricunet.com/Chaffey/documents/Regulary%20Effective%20Contact.pdf" target="_blank">Regularly Effective Contact</a>',NULL,404,0,NULL,NULL,0,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(665,'Identify where or how expectations for frequency and timing of instructor initiated contact and feedback as well as expectations for student participation will be conveyed to students.',NULL,405,0,NULL,NULL,0,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(666,'Syllabus',1748,405,0,NULL,NULL,2,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(667,'Orientation',1790,405,0,NULL,NULL,3,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(668,'Other:',1792,405,0,NULL,NULL,4,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(669,'Explain Other',259,406,0,NULL,NULL,0,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(670,'How do students contact the instructor in this distance education course? Please explain the expected frequency of instructor-to-student contact as well as the intended methods for this contact.',1720,407,0,NULL,NULL,0,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(671,'Examples of Online Activities (including, but not limited to homework):',1755,407,0,NULL,NULL,1,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(672,'Contact Type',134,408,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,146,NULL,NULL,NULL,NULL)
,
(673,'Explain',3918,408,0,NULL,NULL,1,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(674,'Contact Type',134,409,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,147,NULL,NULL,NULL,NULL)
,
(675,'Explain',3918,409,0,NULL,NULL,1,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(676,'Contact Type',134,410,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,148,NULL,NULL,NULL,NULL)
,
(677,'Explain',3918,410,0,NULL,NULL,1,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(678,'Contact Type',134,411,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,149,NULL,NULL,NULL,NULL)
,
(679,'Explain',3918,411,0,NULL,NULL,1,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(680,'Please explain the expected frequency of student-to-instructor contact as well as the intended methods for this contact.',1771,412,0,NULL,NULL,0,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(681,'Contact Type',134,413,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,150,NULL,NULL,NULL,NULL)
,
(682,'Explain',3918,413,0,NULL,NULL,1,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(683,'Please explain the expected frequency of student-to-student contact as well as the intended methods for this contact.',1780,414,0,NULL,NULL,0,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(684,'Contact Type',134,415,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,151,NULL,NULL,NULL,NULL)
,
(685,'Explain',3918,415,0,NULL,NULL,1,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(686,'Be sure to include information on how you will compare SLO assessments among different modalities this course is offered (e.g. face-to-face vs. DE). Please include the dates for these assessments in your Chronological Assessment Plan.',1784,416,0,NULL,NULL,0,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(687,'Contact Type',134,417,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,152,NULL,NULL,NULL,NULL)
,
(688,'Explain',3918,417,0,NULL,NULL,1,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(689,'In order to be ADA and Section 508 compliant, instructors must address the following:  <ol>      <li>Video Closed Captioning with prerecorded audio</li>      <li>Images and Non-Textual items with Alternative Texts</li>      <li>Prerecorded video with textual transcript describing what is shown in the video</li>      <li>Prerecorded audio with textual transcript describing what is said or played in the video</li>      <li>Content is presented with a logical reading order</li>      <li>Using text to convey colored images (i.e. bold, underline, italics, etc.)</li>      <li>Minimal Onscreen Flashes (no more than three times per second)</li>      <li>Clickable items can be used with keyboard in addition to the computer mouse</li>      <li>Information about DPS</li>  </ol>',NULL,418,0,NULL,NULL,0,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(690,'*Faculty are encouraged to contact Jason Schneck at 909-652-6393 for any additional questions, concerns, and/or more compliant adaptations.',NULL,418,0,NULL,NULL,1,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(691,'It is understood that faculty must address and make accessible the above accommodations, and any additional accommodations not listed above, in order to be ADA and Section 508 compliant.',1786,418,0,NULL,NULL,2,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(692,'<u>Provide text alternatives for non-text content (e.g. images)</u> All images and other non-textual items should have a text alternative that describes what it is, so that blind users are able to understand these items.  <br><br>    <u>Provide alternatives for time-based media (audio and video)</u> Audio and video should be provided with a text-based transcript so that the content is accessible to blind or deaf users.  <ul>      <li>Pre-recorded audio should be captioned with text describing what is said and what happens, so that the audio is accessible to deaf users.</li>      <li>Prerecorded video without an audio track should have a textual transcript describing what it shown in the video.</li>      <li>Prerecorded audio should have a textual transcript describing what is said or played in the audio.</li>  </ul>  <br><br>    <u>Content can be presented in different ways (e.g. through a screen reader) without losing info or structure</u>  <ul>      <li>Check manually that the elements on the page are in a logical reading order and that the tabbing order is logical.</li>  </ul>  <br><br>    <u>Users should not be required to identify elements solely by their shape or their position on the page.</u>  <ul>      <li>Some examples of what NOT to say: "the button on the right", "the left-hand sidebar", "the round button", "the sounds that chimes".</li>  </ul>  <br><br>    <u>Make sure content is readable and the foreground contrasts sufficiently with the background</u><br>  Color should not be used as the only means of conveying information, because blind users are not able to see colors, and colorblind or older users may not see colors correctly.  <ul>      <li>When using color to convey information, use another means (like text) to convey the same information in another way.</li>      <li>Do not rely solely on color to identify links. Distinguish links from regular text by underlining them, bolding them, showing an icon next to each link, or some other means other than color.</li>      <li>In forms, use not just color but also text labels to identify required fields or fields with errors.</li>  </ul>  <br><br>    <u>Make all functionality available from a keyboard</u><br>  Blind users cannot use a mouse; they must use the keyboard to navigate Web pages. Users with hand tremors and other motor skills also have trouble using a mouse.  <ul>      <li>All clickable items should also be selectable using the keyboard</li>      <li>Where "drag and drop" functionality is used, a keyboard-based "cut and paste" alternative should be offered</li>  </ul>  <br><br>  <u>Do not use content that can cause seizures</u> This ensures that users with epilepsy and other who have photosensitive seizure disorders do not get seizures from content that flashes onscreen.  <ul>      <li>Onscreen content should not flash more than 3 times per second, and flashes fall below the general flash thresholds.</li>  </ul>',NULL,419,0,NULL,NULL,0,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(740,'Delivery Method',3123,451,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(663,'	What is the intent of offering this course through Internet-based instruction?  Explain:',280,452,0,NULL,NULL,0,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
;

-- INSERT MetaSelectedField INTO Destination Database

;WITH SourceData AS
( 
SELECT MetaSelectedField_MetaSelectedFieldId,MetaSelectedField_DisplayName,MetaSelectedField_MetaAvailableFieldId,kt.NewId AS MetaSelectedField_MetaSelectedSectionId,MetaSelectedField_IsRequired,MetaSelectedField_MinCharacters,MetaSelectedField_MaxCharacters,MetaSelectedField_RowPosition,MetaSelectedField_ColPosition,MetaSelectedField_ColSpan,MetaSelectedField_DefaultDisplayType,MetaSelectedField_MetaPresentationTypeId,MetaSelectedField_Width,MetaSelectedField_WidthUnit,MetaSelectedField_Height,MetaSelectedField_HeightUnit,MetaSelectedField_AllowLabelWrap,MetaSelectedField_LabelHAlign,MetaSelectedField_LabelVAlign,MetaSelectedField_LabelStyleId,MetaSelectedField_LabelVisible,MetaSelectedField_FieldStyle,MetaSelectedField_EditDisplayOnly,MetaSelectedField_GroupName,MetaSelectedField_GroupNameDisplay,MetaSelectedField_FieldTypeId,MetaSelectedField_ValidationRuleId,MetaSelectedField_LiteralValue,MetaSelectedField_ReadOnly,MetaSelectedField_AllowCopy,MetaSelectedField_Precision,kt2.NewId AS MetaSelectedField_MetaForeignKeyLookupSourceId, MetaSelectedField_MetadataAttributeMapId, kt3.NewId AS MetaSelectedField_EditMapId, MetaSelectedField_NumericDataLength, MetaSelectedField_Config
FROM @MetaSelectedFieldTempTable tt 
INNER JOIN #KeyTranslation kt ON kt.oldId = MetaSelectedField_MetaSelectedSectionId	
	AND kt.DestinationTable = 'MetaSelectedSection'
LEFT JOIN #KeyTranslation kt2 ON kt2.oldId = MetaSelectedField_MetaForeignKeyLookupSourceId	
	AND kt2.DestinationTable = 'MetaForeignKeyCriteriaClient'
LEFT JOIN #KeyTranslation kt3 ON kt3.oldId = MetaSelectedField_MetaForeignKeyLookupSourceId	
	AND kt3.DestinationTable = 'EditMap'
)
MERGE INTO MetaSelectedField
USING SourceData sd ON (1 = 0)
WHEN Not Matched By Target THEN
INSERT (DisplayName,MetaAvailableFieldId,MetaSelectedSectionId,IsRequired,MinCharacters,MaxCharacters,RowPosition,ColPosition,ColSpan,DefaultDisplayType,MetaPresentationTypeId,Width,WidthUnit,Height,HeightUnit,AllowLabelWrap,LabelHAlign,LabelVAlign,LabelStyleId,LabelVisible,FieldStyle,EditDisplayOnly,GroupName,GroupNameDisplay,FieldTypeId,ValidationRuleId,LiteralValue,ReadOnly,AllowCopy,Precision,MetaForeignKeyLookupSourceId,MetadataAttributeMapId,EditMapId,NumericDataLength,Config)
VALUES (sd.MetaSelectedField_DisplayName,sd.MetaSelectedField_MetaAvailableFieldId,sd.MetaSelectedField_MetaSelectedSectionId,sd.MetaSelectedField_IsRequired,sd.MetaSelectedField_MinCharacters,sd.MetaSelectedField_MaxCharacters,sd.MetaSelectedField_RowPosition,sd.MetaSelectedField_ColPosition,sd.MetaSelectedField_ColSpan,sd.MetaSelectedField_DefaultDisplayType,sd.MetaSelectedField_MetaPresentationTypeId,sd.MetaSelectedField_Width,sd.MetaSelectedField_WidthUnit,sd.MetaSelectedField_Height,sd.MetaSelectedField_HeightUnit,sd.MetaSelectedField_AllowLabelWrap,sd.MetaSelectedField_LabelHAlign,sd.MetaSelectedField_LabelVAlign,sd.MetaSelectedField_LabelStyleId,sd.MetaSelectedField_LabelVisible,sd.MetaSelectedField_FieldStyle,sd.MetaSelectedField_EditDisplayOnly,sd.MetaSelectedField_GroupName,sd.MetaSelectedField_GroupNameDisplay,sd.MetaSelectedField_FieldTypeId,sd.MetaSelectedField_ValidationRuleId,sd.MetaSelectedField_LiteralValue,sd.MetaSelectedField_ReadOnly,sd.MetaSelectedField_AllowCopy,sd.MetaSelectedField_Precision,sd.MetaSelectedField_MetaForeignKeyLookupSourceId,NULL/*MetadataAttributeMapId*/,sd.MetaSelectedField_EditMapId,sd.MetaSelectedField_NumericDataLength,sd.MetaSelectedField_Config)
OUTPUT 'MetaSelectedField',sd.MetaSelectedField_MetaSelectedFieldId, INSERTED.MetaSelectedFieldId INTO #KeyTranslation (DestinationTable, OldId, NewId);

--=========================End Meta Selected Field==============================

SELECT newid AS MetaTemplateId
FROM #KeyTranslation
WHERE DestinationTable='MetaTemplate'

UPDATE MetaTemplate
SET LastUpdatedDate=GETDATE( )
OUTPUT INSERTED.*
WHERE MetaTemplateId=@MetaTemplateId

--SELECT * FROM #KeyTranslation
DROP TABLE IF EXISTS #KeyTranslation
----------------------------------------------------------------------------------------------------------------------------------------------------------------



SET @InitialTableName = 'MetaSelectedSection';
SET @InitialId = 3498;

 

If @InitialId is not NULL and (Select MetaSelectedSection_MetaSelectedSectionId from MetaSelectedSection where MetaSelectedSectionId = @InitialId) Is Not NULL
BEGIN
	Print' Set @TargetParentSectionId = (Select MetaSelectedSection_MetaSelectedSectionId from MetaSelectedSection where MetaSelectedSectionId = ' + @InitialId + '); --Change this if inserting sections into a different Parent Section'

	Print 'SET @SourceParentSectionId='(SELECT MetaSelectedSection_MetaSelectedSectionId
		  FROM MetaSelectedSection
		  WHERE MetaSelectedSectionId= @InitialId ); --Do not change this setting'
END
      


If @InsertToMetaTemplateId is NULL 
Begin
SET @MetaTemplateId = @SourceTemplateId ;
END
Else 
Begin
SET @MetaTemplateId = @InsertToMetaTemplateId ;
End
set @AddReports  = 0;

/*
      @ProcessId can be manually changed by uncommenting the following line and adding a valid destination ProcessId.
      It will then insert the new ProcessId if it is valid into the new ProcessProposalType records
*/
 --SET @ProcessId = ; 
set @CopyStepToFieldIdMapping  = 1;
/*This can be manually changed by uncommenting the following line*/
 --SET @CopyStepToFieldIdMapping = 0; 
set @CopyPositions = 1;
/*This can be manually changed by uncommenting the following line*/
 --SET @CopyPositions = 0; 
set @CopyPositionPermissions = 1;
/*This can be manually changed by uncommenting the following line*/
 --SET @CopyPositionPermissions = 0; 
 
IF upper(DB_NAME()) <> Upper(@SourceDatabase)
BEGIN;	
	SET @CopyStepToFieldIdMapping = 0;
END;


 Set @UserId = 
	(SELECT top 1 Id FROM [User] 
	WHERE Email like 'SupportAdmin%@CurrIQunet.com' 
	AND ClientId = @ClientId
	);

If @UserId is null
Begin
	 Set @UserId = 
		(SELECT top 1 Id FROM [User] 
		WHERE Email like 'SupportAdmin%@CurrIQunet.com'
		);
End

--================== Create the KeyTranslation Table ===========================

Drop Table If Exists #KeyTranslation2

CREATE TABLE #KeyTranslation2
(
	DestinationTable NVARCHAR(255),
	OldId INT,
	NewId int
)
CREATE NONCLUSTERED INDEX IDXKeyTranslation
ON #KeyTranslation2 (DestinationTable);
	
--================== END Create the KeyTranslation Table =======================

--=================Begin Entity Organization Origination========================		
-- Get EntityOrganizationOrigination
Declare  @EntityOrganizationOriginationTempTable2 Table
(EntityOrganizationOrigination_ClientId nVarchar(Max),EntityOrganizationOrigination_EntityTypeId nVarchar(Max),EntityOrganizationOrigination_OrganizationTierId nVarchar(Max));

Insert into @EntityOrganizationOriginationTempTable2

(EntityOrganizationOrigination_ClientId,EntityOrganizationOrigination_EntityTypeId,EntityOrganizationOrigination_OrganizationTierId)
Output Inserted.*
 Values
(1,6,1)
,
(1,2,1)
,
(1,6,2)
,
(1,2,2)
;
-- Insert EntityOrganizationOrigination into Destination Database


If @SourceDatabase  = DB_NAME()
Begin

;WITH SourceData AS
( 
Select EntityOrganizationOrigination_ClientId,EntityOrganizationOrigination_EntityTypeId,EntityOrganizationOrigination_OrganizationTierId
From @EntityOrganizationOriginationTempTable2 tt
)

Merge Into EntityOrganizationOrigination as Target
USING SourceData sd ON 
sd.EntityOrganizationOrigination_ClientId = Target.ClientId
And sd.EntityOrganizationOrigination_EntityTypeId = Target.EntityTypeId
And sd.EntityOrganizationOrigination_OrganizationTierId = Target.OrganizationTierId
WHEN NOT MATCHED BY TARGET THEN

Insert (ClientId,EntityTypeId,OrganizationTierId)
Values (sd.EntityOrganizationOrigination_ClientId,sd.EntityOrganizationOrigination_EntityTypeId,sd.EntityOrganizationOrigination_OrganizationTierId)

--OUTPUT 'EntityOrganizationOrigination',sd.EntityOrganizationOrigination_Id, inserted.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);
OUTPUT 'EntityOrganizationOrigination',Inserted.* ;
End

--=================End Entity Organization Origination==========================

--=======================Begin Meta SELECTed Section============================

	
		
	-- Get MetaSelectedSection
	DECLARE  @MetaSelectedSectionTempTable2 Table
	(MetaSelectedSection_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedSection_ClientId NVARCHAR(MAX),MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedSection_SectionName NVARCHAR(MAX),MetaSelectedSection_DisplaySectionName NVARCHAR(MAX),MetaSelectedSection_SectionDescription NVARCHAR(MAX),MetaSelectedSection_DisplaySectionDescription NVARCHAR(MAX),MetaSelectedSection_ColumnPosition NVARCHAR(MAX),MetaSelectedSection_RowPosition NVARCHAR(MAX),MetaSelectedSection_SortOrder NVARCHAR(MAX),MetaSelectedSection_SectionDisplayId NVARCHAR(MAX),MetaSelectedSection_MetASectionTypeId NVARCHAR(MAX),MetaSelectedSection_MetaTemplateId NVARCHAR(MAX),MetaSelectedSection_DisplayFieldId NVARCHAR(MAX),MetaSelectedSection_HeaderFieldId NVARCHAR(MAX),MetaSelectedSection_FooterFieldId NVARCHAR(MAX),MetaSelectedSection_OriginatorOnly NVARCHAR(MAX),MetaSelectedSection_MetaBASeSchemaId NVARCHAR(MAX),MetaSelectedSection_MetadataAttributeMapId NVARCHAR(MAX),MetaSelectedSection_EntityListLibraryTypeId NVARCHAR(MAX),MetaSelectedSection_EditMapId NVARCHAR(MAX),MetaSelectedSection_AllowCopy NVARCHAR(MAX),MetaSelectedSection_ReadOnly NVARCHAR(MAX),MetaSelectedSection_Config NVARCHAR(MAX));
	

	INSERT INTO @MetaSelectedSectionTempTable2
	(MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_ClientId,MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_SectionName,MetaSelectedSection_DisplaySectionName,MetaSelectedSection_SectionDescription,MetaSelectedSection_DisplaySectionDescription,MetaSelectedSection_ColumnPosition,MetaSelectedSection_RowPosition,MetaSelectedSection_SortOrder,MetaSelectedSection_SectionDisplayId,MetaSelectedSection_MetASectionTypeId,MetaSelectedSection_MetaTemplateId,MetaSelectedSection_DisplayFieldId,MetaSelectedSection_HeaderFieldId,MetaSelectedSection_FooterFieldId,MetaSelectedSection_OriginatorOnly,MetaSelectedSection_MetaBASeSchemaId,MetaSelectedSection_MetadataAttributeMapId,MetaSelectedSection_EntityListLibraryTypeId,MetaSelectedSection_EditMapId,MetaSelectedSection_AllowCopy,MetaSelectedSection_ReadOnly,MetaSelectedSection_Config)
	OUTPUT INSERTED.*
	VALUES
	
(3498,1,NULL,'DE Addendum',1,'this section will only show if this is on a newer template that uses the New DE PAge',0,NULL,13,13,1,15,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3499,1,3498,NULL,0,NULL,0,NULL,0,0,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3500,1,3498,'<br>Regular and Substantive Interaction',1,NULL,0,NULL,3,3,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3501,1,3498,'<br>Accessibility',1,NULL,0,NULL,71,71,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3502,1,3498,NULL,1,NULL,0,NULL,73,73,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3503,1,3498,'<br>Distance Education Delivery Methods',1,'Please indicate the type(s) of Distance Education modality (if any) 
	for which this course should be approved.',1,NULL,1,1,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3504,1,3498,'<br>Pre-Course Contact, Orientation Materials, and Syllabus Practices',1,'Check the methods of initial contact <b>recommended by the department</b> for use in this course. 
Use the “other/comments” section to elaborate if desired:',1,0,5,4,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3505,1,3498,NULL,0,'<br><b>A home page in the LMS with the following:</b>',1,0,6,5,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3506,1,3498,NULL,0,'<br><b>Syllabus/orientation materials that:</b>',1,0,7,6,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3507,1,3498,NULL,0,NULL,0,0,8,7,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3508,1,3498,'<br>Instructor-to-Student Contact Practices',1,'Check the methods of instructor-initiated
contact recommended by the department for use in this course. Use the “other/comments” section 
to elaborate, if desired:<br><b>Student Messages</b>',1,0,10,9,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3509,1,3498,NULL,0,NULL,0,0,11,10,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3510,1,3498,NULL,0,'<br><b>Discussions</b>',1,0,13,12,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3511,1,3498,NULL,0,NULL,0,0,14,13,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3512,1,3498,NULL,0,'<br><b>Assignment Feedback</b>',1,0,16,15,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3513,1,3498,NULL,0,NULL,0,0,17,16,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3514,1,3498,NULL,0,'<br><b>Office Hours and Conferences and Chats</b>',1,0,19,18,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3515,1,3498,NULL,0,NULL,0,0,20,19,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3516,1,3498,NULL,0,'<br><b>Faculty Contact via Publisher Packs or Third-Party Tools</b>',1,0,22,21,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3517,1,3498,NULL,0,NULL,0,0,23,22,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3518,1,3498,NULL,0,'<br><b>Surveys',1,0,25,24,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3519,1,3498,NULL,0,NULL,0,0,26,25,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3520,1,3498,'<br>Student-to-Student Contact Practices',1,'Check the methods of student-to-student contact
 <b>recommended by the department</b> for use in this course. Use the “other/comments” section to
  elaborate if desired:<br><b>Peer-to-Peer Replies on Discussions</b>',1,0,28,27,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3521,1,3498,NULL,0,NULL,0,0,29,28,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3522,1,3498,NULL,0,'<br><b>Small Group Collaborations and Group Projects</b>',1,0,30,29,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3523,1,3498,NULL,0,NULL,0,0,31,30,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3524,1,3498,NULL,0,'<br><b>Peer Reviews/Critiques</b>',1,0,33,32,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3525,1,3498,NULL,0,NULL,0,0,34,33,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3526,1,3498,NULL,0,'<br><b>Third-Party Tools for Student-to-Student Interaction</b>',1,0,36,35,1,3,16,NULL,NULL,NULL,0,90,NULL,NULL,NULL,1,0,NULL)
,
(3527,1,3498,NULL,0,NULL,0,0,37,36,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3528,1,3498,'<br>Class Assignment:',1,NULL,0,0,39,38,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3529,1,3498,NULL,0,NULL,0,0,9,8,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3530,1,3498,NULL,0,NULL,0,0,12,11,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3531,1,3498,NULL,0,NULL,0,0,15,14,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3532,1,3498,NULL,0,NULL,0,0,18,17,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3533,1,3498,NULL,0,NULL,0,0,21,20,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3534,1,3498,NULL,0,NULL,0,0,24,23,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3535,1,3498,NULL,0,NULL,0,0,27,26,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3536,1,3498,NULL,0,NULL,0,0,30,29,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3537,1,3498,NULL,0,NULL,0,0,32,31,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3538,1,3498,NULL,0,NULL,0,0,35,34,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3539,1,3498,NULL,0,NULL,0,0,38,37,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3540,1,3498,NULL,0,NULL,0,0,40,39,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3541,1,3498,NULL,0,NULL,0,0,2,1,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(3542,1,3498,NULL,0,NULL,0,0,71,70,1,1,16,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
;
-- INSERT MetaSelectedSection INTO Destination Database
	IF @MetaTemplateId <> (SELECT Top 1 MetaSelectedSection_MetaTemplateId FROM @MetaSelectedSectionTempTable2)
	BEGIN
		UPDATE @MetaSelectedSectionTempTable2
		SET MetaSelectedSection_MetaTemplateId = @MetaTemplateId
		
		--SELECT * FROM @MetaSelectedSectionTempTable --For troubleshooting
	END 
	
;WITH SourceData AS
	( 
	SELECT MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_ClientId,MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_SectionName,MetaSelectedSection_DisplaySectionName,MetaSelectedSection_SectionDescription,MetaSelectedSection_DisplaySectionDescription,MetaSelectedSection_ColumnPosition,MetaSelectedSection_RowPosition,MetaSelectedSection_SortOrder,MetaSelectedSection_SectionDisplayId,MetaSelectedSection_MetASectionTypeId,
	COALESCE(kt.NewId, @MetaTemplateId,MetaSelectedSection_MetaTemplateId) AS MetaSelectedSection_MetaTemplateId,NULL AS MetaSelectedSection_DisplayFieldId,NULL AS MetaSelectedSection_HeaderFieldId,NULL AS MetaSelectedSection_FooterFieldId,MetaSelectedSection_OriginatorOnly,MetaSelectedSection_MetaBASeSchemaId,NULL AS MetaSelectedSection_MetadataAttributeMapId,NULL AS MetaSelectedSection_EntityListLibraryTypeId,NULL AS MetaSelectedSection_EditMapId,MetaSelectedSection_AllowCopy,MetaSelectedSection_ReadOnly,MetaSelectedSection_Config
	FROM @MetaSelectedSectionTempTable2 tt 
	LEFT JOIN #KeyTranslation2 kt ON kt.OldId = tt.MetaSelectedSection_MetaTemplateId
		AND DestinationTable = 'MetaTemplate'
	)
MERGE INTO MetaSelectedSection
	USING SourceData sd ON (1 = 0)
	WHEN Not Matched By Target THEN
	INSERT (ClientId,MetaSelectedSection_MetaSelectedSectionId,SectionName,DisplaySectionName,SectionDescription,DisplaySectionDescription,ColumnPosition,RowPosition,SortOrder,SectionDisplayId,MetASectionTypeId,MetaTemplateId,DisplayFieldId,HeaderFieldId,FooterFieldId,OriginatorOnly,MetaBASeSchemaId,MetadataAttributeMapId,EntityListLibraryTypeId,EditMapId,AllowCopy,ReadOnly,Config)
	VALUES (@ClientId,NULL,sd.MetaSelectedSection_SectionName,sd.MetaSelectedSection_DisplaySectionName,sd.MetaSelectedSection_SectionDescription,sd.MetaSelectedSection_DisplaySectionDescription,sd.MetaSelectedSection_ColumnPosition,sd.MetaSelectedSection_RowPosition,sd.MetaSelectedSection_SortOrder,sd.MetaSelectedSection_SectionDisplayId,sd.MetaSelectedSection_MetASectionTypeId,sd.MetaSelectedSection_MetaTemplateId,NULL,NULL,NULL,sd.MetaSelectedSection_OriginatorOnly,sd.MetaSelectedSection_MetaBASeSchemaId,NULL,sd.MetaSelectedSection_EntityListLibraryTypeId,sd.MetaSelectedSection_EditMapId,sd.MetaSelectedSection_AllowCopy,sd.MetaSelectedSection_ReadOnly,sd.MetaSelectedSection_Config)
	OUTPUT 'MetaSelectedSection',sd.MetaSelectedSection_MetaSelectedSectionId, INSERTED.MetaSelectedSectionId INTO #KeyTranslation2 (DestinationTable, OldId, NewId);

	UPDATE tbl
	SET MetaSelectedSection_MetaSelectedSectionId = kt2.NewId
	FROM MetaSelectedSection tbl
	INNER JOIN #KeyTranslation2 kt ON kt.NewId = tbl.MetaSelectedSectionId
	AND kt.DestinationTable= 'MetaSelectedSection'
	INNER JOIN @MetaSelectedSectionTempTable2 tt ON kt.OldId = tt.MetaSelectedSection_MetaSelectedSectionId
	INNER JOIN #KeyTranslation2 kt2 ON kt2.OldId = tt.MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId
	AND kt2.DestinationTable= 'MetaSelectedSection'
	;

--========================End Meta Selected Section=============================

	

--=================Begin Meta Selected Section Attribute========================

	
		
-- Get MetaSelectedSectionAttribute
DECLARE  @MetaSelectedSectionAttributeTempTable2 Table
(MetaSelectedSectionAttribute_Id NVARCHAR(MAX),MetaSelectedSectionAttribute_GroupId NVARCHAR(MAX),MetaSelectedSectionAttribute_AttributeTypeId NVARCHAR(MAX),MetaSelectedSectionAttribute_Name NVARCHAR(MAX),MetaSelectedSectionAttribute_Value NVARCHAR(MAX),MetaSelectedSectionAttribute_MetaSelectedSectionId NVARCHAR(MAX));

INSERT INTO @MetaSelectedSectionAttributeTempTable2
(MetaSelectedSectionAttribute_Id,MetaSelectedSectionAttribute_GroupId,MetaSelectedSectionAttribute_AttributeTypeId,MetaSelectedSectionAttribute_Name,MetaSelectedSectionAttribute_Value,MetaSelectedSectionAttribute_MetaSelectedSectionId)
OUTPUT INSERTED.*
 VALUES
(3786,1,1,'ShouldDisplayCheckQuery','SELECT 
case
    WHen c.MetaTemplateId >= 39 then 1
    else 0
END as ShouldDisplay
FROM Course c
WHERE c.Id = @entityId;',3498)
,
(3720,1,1,'ParentTable','CourseDistanceEducationContact',3504)
,
(3721,1,1,'ForeignKeyToParent','CourseId',3504)
,
(3722,1,1,'LookupTable','ContactType',3504)
,
(3723,1,1,'ForeignKeyToLookup','ContactTypeId',3504)
,
(3724,1,1,'ColumnCount','2',3504)
,
(3725,1,1,'ParentTable','CourseDistanceEducationContact',3505)
,
(3726,1,1,'ForeignKeyToParent','CourseId',3505)
,
(3727,1,1,'LookupTable','ContactType',3505)
,
(3728,1,1,'ForeignKeyToLookup','ContactTypeId',3505)
,
(3729,1,1,'ColumnCount','2',3505)
,
(3730,1,1,'ParentTable','CourseDistanceEducationContact',3506)
,
(3731,1,1,'ForeignKeyToParent','CourseId',3506)
,
(3732,1,1,'LookupTable','ContactType',3506)
,
(3733,1,1,'ForeignKeyToLookup','ContactTypeId',3506)
,
(3734,1,1,'ColumnCount','2',3506)
,
(3787,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit01 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3507)
,
(3735,1,1,'ParentTable','CourseDistanceEducationContact',3508)
,
(3736,1,1,'ForeignKeyToParent','CourseId',3508)
,
(3737,1,1,'LookupTable','ContactType',3508)
,
(3738,1,1,'ForeignKeyToLookup','ContactTypeId',3508)
,
(3739,1,1,'ColumnCount','2',3508)
,
(3788,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit02 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3509)
,
(3740,1,1,'ParentTable','CourseDistanceEducationContact',3510)
,
(3741,1,1,'ForeignKeyToParent','CourseId',3510)
,
(3742,1,1,'LookupTable','ContactType',3510)
,
(3743,1,1,'ForeignKeyToLookup','ContactTypeId',3510)
,
(3744,1,1,'ColumnCount','2',3510)
,
(3789,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit03 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3511)
,
(3745,1,1,'ParentTable','CourseDistanceEducationContact',3512)
,
(3746,1,1,'ForeignKeyToParent','CourseId',3512)
,
(3747,1,1,'LookupTable','ContactType',3512)
,
(3748,1,1,'ForeignKeyToLookup','ContactTypeId',3512)
,
(3749,1,1,'ColumnCount','2',3512)
,
(3790,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit04 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3513)
,
(3750,1,1,'ParentTable','CourseDistanceEducationContact',3514)
,
(3751,1,1,'ForeignKeyToParent','CourseId',3514)
,
(3752,1,1,'LookupTable','ContactType',3514)
,
(3753,1,1,'ForeignKeyToLookup','ContactTypeId',3514)
,
(3754,1,1,'ColumnCount','2',3514)
,
(3791,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit05 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3515)
,
(3755,1,1,'ParentTable','CourseDistanceEducationContact',3516)
,
(3756,1,1,'ForeignKeyToParent','CourseId',3516)
,
(3757,1,1,'LookupTable','ContactType',3516)
,
(3758,1,1,'ForeignKeyToLookup','ContactTypeId',3516)
,
(3759,1,1,'ColumnCount','2',3516)
,
(3792,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit06 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3517)
,
(3760,1,1,'ParentTable','CourseDistanceEducationContact',3518)
,
(3761,1,1,'ForeignKeyToParent','CourseId',3518)
,
(3762,1,1,'LookupTable','ContactType',3518)
,
(3763,1,1,'ForeignKeyToLookup','ContactTypeId',3518)
,
(3764,1,1,'ColumnCount','2',3518)
,
(3793,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit07 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3519)
,
(3765,1,1,'ParentTable','CourseDistanceEducationContact',3520)
,
(3766,1,1,'ForeignKeyToParent','CourseId',3520)
,
(3767,1,1,'LookupTable','ContactType',3520)
,
(3768,1,1,'ForeignKeyToLookup','ContactTypeId',3520)
,
(3769,1,1,'ColumnCount','2',3520)
,
(3794,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit08 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3521)
,
(3770,1,1,'ParentTable','CourseDistanceEducationContact',3522)
,
(3771,1,1,'ForeignKeyToParent','CourseId',3522)
,
(3772,1,1,'LookupTable','ContactType',3522)
,
(3773,1,1,'ForeignKeyToLookup','ContactTypeId',3522)
,
(3774,1,1,'ColumnCount','2',3522)
,
(3795,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit09 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3523)
,
(3775,1,1,'ParentTable','CourseDistanceEducationContact',3524)
,
(3776,1,1,'ForeignKeyToParent','CourseId',3524)
,
(3777,1,1,'LookupTable','ContactType',3524)
,
(3778,1,1,'ForeignKeyToLookup','ContactTypeId',3524)
,
(3779,1,1,'ColumnCount','2',3524)
,
(3796,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit10 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3525)
,
(3780,1,1,'ParentTable','CourseDistanceEducationContact',3526)
,
(3781,1,1,'ForeignKeyToParent','CourseId',3526)
,
(3782,1,1,'LookupTable','ContactType',3526)
,
(3783,1,1,'ForeignKeyToLookup','ContactTypeId',3526)
,
(3784,1,1,'ColumnCount','2',3526)
,
(3797,1,1,'ShouldDisplayCheckQuery','
		SELECT 
		Case
			When Bit11 = 1 then 1
			Else 0
		END as ShouldDisplay
		FROM Genericbit
		WHERE	CourseId = @EntityID
		',3527)
;
-- INSERT MetaSelectedSectionAttribute INTO Destination Database


;WITH SourceData AS
( 
SELECT MetaSelectedSectionAttribute_Id,MetaSelectedSectionAttribute_GroupId,MetaSelectedSectionAttribute_AttributeTypeId,MetaSelectedSectionAttribute_Name,MetaSelectedSectionAttribute_Value,kt.NewId AS MetaSelectedSectionAttribute_MetaSelectedSectionId
FROM @MetaSelectedSectionAttributeTempTable2 tt 	
INNER JOIN #KeyTranslation2 kt ON MetaSelectedSectionAttribute_MetaSelectedSectionId =kt.OldId
    AND DestinationTable = 'MetaSelectedSection'
)
MERGE INTO MetaSelectedSectionAttribute
USING SourceData sd ON (1 = 0)
WHEN Not Matched By Target THEN
INSERT (GroupId,AttributeTypeId,Name,Value,MetaSelectedSectionId)
VALUES (sd.MetaSelectedSectionAttribute_GroupId,sd.MetaSelectedSectionAttribute_AttributeTypeId,sd.MetaSelectedSectionAttribute_Name,sd.MetaSelectedSectionAttribute_Value,sd.MetaSelectedSectionAttribute_MetaSelectedSectionId);
--OUTPUT 'MetaSelectedSectionAttribute',sd.MetaSelectedSectionAttribute_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);

--===================End Meta Selected Section Attribute========================

--=================Begin Meta Foreign Key Criteria Client=======================

SET NOCOUNT ON;

Drop Table if Exists #SeedIds2
Create Table #SeedIds2 (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds, x thousands, x tenthousands--, x hundredthousands
)	Merge #SeedIds2 as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds2 where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds2.Id)

	Merge #SeedIds2 as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds2
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	
	SET NOCOUNT OFF;
		
-- Get MetaForeignKeyCriteriaClient
DECLARE  @MetaForeignKeyCriteriaClientTempTable2 Table
(row_num NVARCHAR(MAX),MetaForeignKeyCriteriaClient_Id NVARCHAR(MAX),MetaForeignKeyCriteriaClient_TableName NVARCHAR(MAX),MetaForeignKeyCriteriaClient_DefaultValueColumn NVARCHAR(MAX),MetaForeignKeyCriteriaClient_DefaultDisplayColumn NVARCHAR(MAX),MetaForeignKeyCriteriaClient_CustomSql NVARCHAR(MAX),MetaForeignKeyCriteriaClient_ResolutionSql NVARCHAR(MAX),MetaForeignKeyCriteriaClient_DefaultSortColumn NVARCHAR(MAX),MetaForeignKeyCriteriaClient_Title NVARCHAR(MAX),MetaForeignKeyCriteriaClient_LookupLoadTimingType NVARCHAR(MAX),MetaForeignKeyCriteriaClient_PickListId NVARCHAR(MAX),MetaForeignKeyCriteriaClient_IsSeeded NVARCHAR(MAX));

INSERT INTO @MetaForeignKeyCriteriaClientTempTable2

(row_num,MetaForeignKeyCriteriaClient_Id,MetaForeignKeyCriteriaClient_TableName,MetaForeignKeyCriteriaClient_DefaultValueColumn,MetaForeignKeyCriteriaClient_DefaultDisplayColumn,MetaForeignKeyCriteriaClient_CustomSql,MetaForeignKeyCriteriaClient_ResolutionSql,MetaForeignKeyCriteriaClient_DefaultSortColumn,MetaForeignKeyCriteriaClient_Title,MetaForeignKeyCriteriaClient_LookupLoadTimingType,MetaForeignKeyCriteriaClient_PickListId,MetaForeignKeyCriteriaClient_IsSeeded)
OUTPUT INSERTED.*
 VALUES
(1,243,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =36','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(2,244,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =39','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(3,245,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =44','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(4,246,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =51','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(5,247,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =54','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(6,248,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =58','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(7,249,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =63','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(8,250,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =65','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(9,251,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =67','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(10,252,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =69','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(11,253,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =73','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(12,254,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =78','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
,
(13,255,'ContactType','Id','Title','select Id as [Value], Title as [Text] from ContactType
	where (Active = 1 or EndDate > getdate())
		AND ParentId =81','Select Title as Text from ContactType where Id = @id','Order by SortOrder','DE tab lists filters',2,NULL,NULL)
;
-- INSERT MetaForeignKeyCriteriaClient INTO Destination Database



;WITH SourceData AS
( 
SELECT si.Id,MetaForeignKeyCriteriaClient_Id, MetaForeignKeyCriteriaClient_TableName, MetaForeignKeyCriteriaClient_DefaultValueColumn,MetaForeignKeyCriteriaClient_DefaultDisplayColumn,MetaForeignKeyCriteriaClient_CustomSql,MetaForeignKeyCriteriaClient_ResolutionSql,MetaForeignKeyCriteriaClient_DefaultSortColumn,
MetaForeignKeyCriteriaClient_Title,MetaForeignKeyCriteriaClient_LookupLoadTimingType,MetaForeignKeyCriteriaClient_PickListId,MetaForeignKeyCriteriaClient_IsSeeded
FROM @MetaForeignKeyCriteriaClientTempTable2 tt
inner join  #SeedIds2 si on si.row_num	= tt.row_num
)

MERGE INTO MetaForeignKeyCriteriaClient
USING SourceData sd ON 
	(TableName = MetaForeignKeyCriteriaClient_TableName  or (TableName is null AND MetaForeignKeyCriteriaClient_TableName is null))
	AND
	(DefaultValueColumn = MetaForeignKeyCriteriaClient_DefaultValueColumn or (DefaultValueColumn is null AND MetaForeignKeyCriteriaClient_DefaultValueColumn is null))
	AND
	(DefaultDisplayColumn = MetaForeignKeyCriteriaClient_DefaultDisplayColumn or (DefaultDisplayColumn is null AND MetaForeignKeyCriteriaClient_DefaultDisplayColumn is null))
	AND
	(CustomSql = MetaForeignKeyCriteriaClient_CustomSql or (CustomSql is null AND MetaForeignKeyCriteriaClient_CustomSql is null))
	AND
	(ResolutionSql = MetaForeignKeyCriteriaClient_ResolutionSql or (ResolutionSql is null AND MetaForeignKeyCriteriaClient_ResolutionSql is null))
	AND
	(DefaultSortColumn = MetaForeignKeyCriteriaClient_DefaultSortColumn or (DefaultSortColumn is null AND MetaForeignKeyCriteriaClient_DefaultSortColumn is null))
	AND
	(Title = MetaForeignKeyCriteriaClient_Title or (Title is null AND MetaForeignKeyCriteriaClient_Title is null))
	AND
	(PickListId = MetaForeignKeyCriteriaClient_PickListId or (PickListId is null AND MetaForeignKeyCriteriaClient_PickListId is null))
	AND
	(LookupLoadTimingType = MetaForeignKeyCriteriaClient_LookupLoadTimingType or (LookupLoadTimingType is null AND MetaForeignKeyCriteriaClient_LookupLoadTimingType is null))
	AND
	(IsSeeded = MetaForeignKeyCriteriaClient_IsSeeded or (IsSeeded is null AND MetaForeignKeyCriteriaClient_IsSeeded is null))
WHEN Not Matched By Target THEN
INSERT (Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,Title,LookupLoadTimingType,PickListId,IsSeeded)
VALUES (Id,sd.MetaForeignKeyCriteriaClient_TableName,sd.MetaForeignKeyCriteriaClient_DefaultValueColumn,sd.MetaForeignKeyCriteriaClient_DefaultDisplayColumn,
	sd.MetaForeignKeyCriteriaClient_CustomSql,sd.MetaForeignKeyCriteriaClient_ResolutionSql,sd.MetaForeignKeyCriteriaClient_DefaultSortColumn,
	sd.MetaForeignKeyCriteriaClient_Title,sd.MetaForeignKeyCriteriaClient_LookupLoadTimingType,sd.MetaForeignKeyCriteriaClient_PickListId,
	sd.MetaForeignKeyCriteriaClient_IsSeeded)
WHEN Matched THEN UPDATE
SET TableName = MetaForeignKeyCriteriaClient_TableName
OUTPUT 'MetaForeignKeyCriteriaClient',sd.MetaForeignKeyCriteriaClient_Id, INSERTED.Id INTO #KeyTranslation2 (DestinationTable, OldId, NewId);

--==================End Meta Foreign Key Criteria Client========================



--=======================Begin Meta Selected Field==============================

		
-- Get MetaSelectedField
DECLARE  @MetaSelectedFieldTempTable2 Table
(MetaSelectedField_MetaSelectedFieldId NVARCHAR(MAX),MetaSelectedField_DisplayName NVARCHAR(MAX),MetaSelectedField_MetaAvailableFieldId NVARCHAR(MAX),MetaSelectedField_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedField_IsRequired NVARCHAR(MAX),MetaSelectedField_MinCharacters NVARCHAR(MAX),MetaSelectedField_MaxCharacters NVARCHAR(MAX),MetaSelectedField_RowPosition NVARCHAR(MAX),MetaSelectedField_ColPosition NVARCHAR(MAX),MetaSelectedField_ColSpan NVARCHAR(MAX),MetaSelectedField_DefaultDisplayType NVARCHAR(MAX),MetaSelectedField_MetaPresentationTypeId NVARCHAR(MAX),MetaSelectedField_Width NVARCHAR(MAX),MetaSelectedField_WidthUnit NVARCHAR(MAX),MetaSelectedField_Height NVARCHAR(MAX),MetaSelectedField_HeightUnit NVARCHAR(MAX),MetaSelectedField_AllowLabelWrap NVARCHAR(MAX),MetaSelectedField_LabelHAlign NVARCHAR(MAX),MetaSelectedField_LabelVAlign NVARCHAR(MAX),MetaSelectedField_LabelStyleId NVARCHAR(MAX),MetaSelectedField_LabelVisible NVARCHAR(MAX),MetaSelectedField_FieldStyle NVARCHAR(MAX),MetaSelectedField_EditDisplayOnly NVARCHAR(MAX),MetaSelectedField_GroupName NVARCHAR(MAX),MetaSelectedField_GroupNameDisplay NVARCHAR(MAX),MetaSelectedField_FieldTypeId NVARCHAR(MAX),MetaSelectedField_ValidationRuleId NVARCHAR(MAX),MetaSelectedField_LiteralValue NVARCHAR(MAX),MetaSelectedField_ReadOnly NVARCHAR(MAX),MetaSelectedField_AllowCopy NVARCHAR(MAX),MetaSelectedField_Precision NVARCHAR(MAX),MetaSelectedField_MetaForeignKeyLookupSourceId NVARCHAR(MAX),MetaSelectedField_MetadataAttributeMapId NVARCHAR(MAX),MetaSelectedField_EditMapId NVARCHAR(MAX),MetaSelectedField_NumericDataLength NVARCHAR(MAX),MetaSelectedField_Config NVARCHAR(MAX));

INSERT INTO @MetaSelectedFieldTempTable2

(MetaSelectedField_MetaSelectedFieldId,MetaSelectedField_DisplayName,MetaSelectedField_MetaAvailableFieldId,MetaSelectedField_MetaSelectedSectionId,MetaSelectedField_IsRequired,MetaSelectedField_MinCharacters,MetaSelectedField_MaxCharacters,MetaSelectedField_RowPosition,MetaSelectedField_ColPosition,MetaSelectedField_ColSpan,MetaSelectedField_DefaultDisplayType,MetaSelectedField_MetaPresentationTypeId,MetaSelectedField_Width,MetaSelectedField_WidthUnit,MetaSelectedField_Height,MetaSelectedField_HeightUnit,MetaSelectedField_AllowLabelWrap,MetaSelectedField_LabelHAlign,MetaSelectedField_LabelVAlign,MetaSelectedField_LabelStyleId,MetaSelectedField_LabelVisible,MetaSelectedField_FieldStyle,MetaSelectedField_EditDisplayOnly,MetaSelectedField_GroupName,MetaSelectedField_GroupNameDisplay,MetaSelectedField_FieldTypeId,MetaSelectedField_ValidationRuleId,MetaSelectedField_LiteralValue,MetaSelectedField_ReadOnly,MetaSelectedField_AllowCopy,MetaSelectedField_Precision,MetaSelectedField_MetaForeignKeyLookupSourceId,MetaSelectedField_MetadataAttributeMapId,MetaSelectedField_EditMapId,MetaSelectedField_NumericDataLength,MetaSelectedField_Config)
OUTPUT INSERTED.*
 VALUES
(5984,'In order to be ADA and Section 508 compliant, instructors must address the following: 
			<ol>
				<li>Video Closed Captioning with prerecorded audio</li>
				<li>Images and Non-Textual items with Alternative Texts</li>
				<li>Prerecorded video with textual transcript describing what is shown in the video</li>
				<li>Prerecorded audio with textual transcript describing what is said or played in the video</li>
				<li>Content is presented with a logical reading order</li>
				<li>Using text to convey colored images (i.e. bold, underline, italics, etc.)</li>
				<li>Minimal Onscreen Flashes (no more than three times per second)</li>
				<li>Clickable items can be used with keyboard in addition to the computer mouse</li>
				<li>Information about DPS</li>
			</ol>',NULL,3501,0,NULL,NULL,0,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5985,'*See more detailed guidelines here. Faculty are encouraged to contact Jason Schneck at 909-652-6393 for any additional questions, 
			concerns, and/or more compliant adaptations.',NULL,3501,0,NULL,NULL,1,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5986,'Checking this box indicates that the department and dean agree that each section of this course in
 which the instructional time is conducted in part or in whole through distance education will comply with all 
 applicable accessibility requirements in state and federal regulations (Americans with Disabilities Act of 1990 
 (ADA), Section 508 of the Rehabilitation Act of 1973, California Government Code §11135, and Title 5 §55205.',1786,3501,0,NULL,NULL,2,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5988,'Please provide a rationale for not offering this course via distance education.',2000,3502,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5989,'Delivery Method',3123,3503,0,NULL,NULL,0,0,1,'TelerikCombo',33,400,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5990,'Contact Type',134,3504,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,243,NULL,NULL,NULL,NULL)
,
(5991,'Contact Type',134,3505,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,244,NULL,NULL,NULL,NULL)
,
(5992,'Contact Type',134,3506,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,245,NULL,NULL,NULL,NULL)
,
(6003,'Other/comments:',2622,3507,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5993,'Contact Type',134,3508,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,246,NULL,NULL,NULL,NULL)
,
(6004,'Other/comments:',2623,3509,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5994,'Contact Type',134,3510,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,247,NULL,NULL,NULL,NULL)
,
(6005,'Other/comments:',2624,3511,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5995,'Contact Type',134,3512,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,248,NULL,NULL,NULL,NULL)
,
(6006,'Other/comments:',2625,3513,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5996,'Contact Type',134,3514,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,249,NULL,NULL,NULL,NULL)
,
(6007,'Other/comments:',2626,3515,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5997,'Contact Type',134,3516,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,250,NULL,NULL,NULL,NULL)
,
(6008,'Other/comments:',2627,3517,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5998,'Contact Type',134,3518,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,251,NULL,NULL,NULL,NULL)
,
(6009,'Other/comments:',2628,3519,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5999,'Contact Type',134,3520,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,252,NULL,NULL,NULL,NULL)
,
(6010,'Other/comments:',2629,3521,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6000,'Contact Type',134,3522,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,253,NULL,NULL,NULL,NULL)
,
(5982,'Other/comments:',2630,3523,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6001,'Contact Type',134,3524,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,254,NULL,NULL,NULL,NULL)
,
(5983,'Other/comments:',2631,3525,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6002,'Contact Type',134,3526,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,255,NULL,NULL,NULL,NULL)
,
(6011,'Other/comments:',2632,3527,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6024,'Please review the examples provided on the Class Assignments page of the COR. Do any of the assignment descriptions need to be modified for online delivery? ',3398,3528,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6012,'Explain',2554,3529,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6013,'Explain',2555,3530,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6014,'Explain',2556,3531,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6015,'Explain',2557,3532,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6016,'Explain',2558,3533,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6017,'Explain',2559,3534,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6018,'Explain',2560,3535,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6019,'Explain',2561,3536,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6020,'Explain',2955,3537,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6021,'Explain',2956,3538,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6022,'Explain',2957,3539,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6023,'Please describe the modifications',2958,3540,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6025,'Describe which learning outcomes and/or objectives cannot be achieved in a fully online modality (including any relevant external regulations or policies)',2959,3541,1,NULL,NULL,0,0,1,'Textarea',17,100,2,100,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6026,'The completion of the DE information above follow the guidelines established in my department''s DE policy.',3400,3542,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5987,'Would you like to offer this course via Distance Education (DE)? Yes or no',3437,3499,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5981,'<div style = "Color: Purple">
	This section outlines a variety of "best practice" instructional pedagogies for developing and maintaining regular and substantive interaction. 
	<b> NOTE: </b>
	There are many ways to demonstrate regular and substantive interaction, so not every element recommended by the department must be present in every section of the course.
</div>
<br>

Regular interaction refers to frequent, predictable, instructor-initiated opportunities for instructor-student interaction and monitoring of student engagement. Substantive refers to interaction that is academic in nature. Regular and substantive interaction can be accomplished in a number of ways, including through feedback on assignments, participation in discussion forums, and conferencing and other synchronous activities via Zoom. 
	<a href ="https://www.chaffey.edu/policiesandprocedures/docs/aps/4105-ap.pdf" target = "_blank"> AP 4105 </a>
	defines two elements that are central to regular and substantive interaction:

<ul>
	<li>
		<b> Instructor-to-student interaction </b> 
		is a key feature of distance education courses, and it is one factor that distinguishes it from correspondence courses. In course sections in which the instructional time is conducted in part or in whole through distance education, ensuring regular effective instructor/student contact guarantees the student receives the benefit of the instructor’s presence in the learning environment both as a provider of instructional information and as a facilitator of student learning. In a face-to-face instructional format, instructors are present at each course section meeting and interact via announcements, lectures, activities, and discussions that take a variety of forms. In course sections in which the instructional time is conducted in part or in whole through distance education, instructors provide similar experiences.
	</li>
	<li>
		<b> Student-to-student interaction </b> 
		is also a key feature of distance education, and it is another factor that distinguishes it from correspondence courses. These forms of contact are also required by federal regulatory requirements, state education codes, and the Accrediting Commission for Community and Junior Colleges (ACCJC), and are recommended by the Statewide Academic Senate for Community Colleges.
	</li>

</ul>

Regular and substantive interaction is a California Title V educational requirement that requires instructors to incorporate instructor-initiated, regular, substantive interaction into online and any online portion of hybrid course design and delivery. This means that it is the 
<b> responsibility of the instructor </b>
to initiate interaction with students, provide contact information to students, make announcements, question and involve them in discussions, reach out to them when they are absent or missing work, provide meaningful feedback on assignments, and monitor their overall progress. It is also the responsibility of the instructor to design opportunities for students to interact with other students in the course via discussion boards, group collaboration, peer review, and other student-to-student engaged activities. 
<br>
<br>

This form outlines requirements for “Start of the Course” and creating opportunities for “Faculty-Initiated” and “Student-to-Student” interaction. It may also serve as an optional supplement to a hybrid or online course evaluation. 
<br>
<br>

Please note there are many ways to demonstrate regular and substantive interaction, so not all of these elements will be present in every course. For additional information and guidance, please utilize the
	<a href = "https://canvas.chaffey.edu/courses/2503/pages/regular-and-substantive-interaction" target = "_blank"> Regular and Substantive Interaction resources. </a>',NULL,3500,0,NULL,NULL,0,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
;

-- INSERT MetaSelectedField INTO Destination Database

;WITH SourceData AS
( 
SELECT MetaSelectedField_MetaSelectedFieldId,MetaSelectedField_DisplayName,MetaSelectedField_MetaAvailableFieldId,kt.NewId AS MetaSelectedField_MetaSelectedSectionId,MetaSelectedField_IsRequired,MetaSelectedField_MinCharacters,MetaSelectedField_MaxCharacters,MetaSelectedField_RowPosition,MetaSelectedField_ColPosition,MetaSelectedField_ColSpan,MetaSelectedField_DefaultDisplayType,MetaSelectedField_MetaPresentationTypeId,MetaSelectedField_Width,MetaSelectedField_WidthUnit,MetaSelectedField_Height,MetaSelectedField_HeightUnit,MetaSelectedField_AllowLabelWrap,MetaSelectedField_LabelHAlign,MetaSelectedField_LabelVAlign,MetaSelectedField_LabelStyleId,MetaSelectedField_LabelVisible,MetaSelectedField_FieldStyle,MetaSelectedField_EditDisplayOnly,MetaSelectedField_GroupName,MetaSelectedField_GroupNameDisplay,MetaSelectedField_FieldTypeId,MetaSelectedField_ValidationRuleId,MetaSelectedField_LiteralValue,MetaSelectedField_ReadOnly,MetaSelectedField_AllowCopy,MetaSelectedField_Precision,kt2.NewId AS MetaSelectedField_MetaForeignKeyLookupSourceId, MetaSelectedField_MetadataAttributeMapId, kt3.NewId AS MetaSelectedField_EditMapId, MetaSelectedField_NumericDataLength, MetaSelectedField_Config
FROM @MetaSelectedFieldTempTable2 tt 
INNER JOIN #KeyTranslation2 kt ON kt.oldId = MetaSelectedField_MetaSelectedSectionId	
	AND kt.DestinationTable = 'MetaSelectedSection'
LEFT JOIN #KeyTranslation2 kt2 ON kt2.oldId = MetaSelectedField_MetaForeignKeyLookupSourceId	
	AND kt2.DestinationTable = 'MetaForeignKeyCriteriaClient'
LEFT JOIN #KeyTranslation2 kt3 ON kt3.oldId = MetaSelectedField_MetaForeignKeyLookupSourceId	
	AND kt3.DestinationTable = 'EditMap'
)
MERGE INTO MetaSelectedField
USING SourceData sd ON (1 = 0)
WHEN Not Matched By Target THEN
INSERT (DisplayName,MetaAvailableFieldId,MetaSelectedSectionId,IsRequired,MinCharacters,MaxCharacters,RowPosition,ColPosition,ColSpan,DefaultDisplayType,MetaPresentationTypeId,Width,WidthUnit,Height,HeightUnit,AllowLabelWrap,LabelHAlign,LabelVAlign,LabelStyleId,LabelVisible,FieldStyle,EditDisplayOnly,GroupName,GroupNameDisplay,FieldTypeId,ValidationRuleId,LiteralValue,ReadOnly,AllowCopy,Precision,MetaForeignKeyLookupSourceId,MetadataAttributeMapId,EditMapId,NumericDataLength,Config)
VALUES (sd.MetaSelectedField_DisplayName,sd.MetaSelectedField_MetaAvailableFieldId,sd.MetaSelectedField_MetaSelectedSectionId,sd.MetaSelectedField_IsRequired,sd.MetaSelectedField_MinCharacters,sd.MetaSelectedField_MaxCharacters,sd.MetaSelectedField_RowPosition,sd.MetaSelectedField_ColPosition,sd.MetaSelectedField_ColSpan,sd.MetaSelectedField_DefaultDisplayType,sd.MetaSelectedField_MetaPresentationTypeId,sd.MetaSelectedField_Width,sd.MetaSelectedField_WidthUnit,sd.MetaSelectedField_Height,sd.MetaSelectedField_HeightUnit,sd.MetaSelectedField_AllowLabelWrap,sd.MetaSelectedField_LabelHAlign,sd.MetaSelectedField_LabelVAlign,sd.MetaSelectedField_LabelStyleId,sd.MetaSelectedField_LabelVisible,sd.MetaSelectedField_FieldStyle,sd.MetaSelectedField_EditDisplayOnly,sd.MetaSelectedField_GroupName,sd.MetaSelectedField_GroupNameDisplay,sd.MetaSelectedField_FieldTypeId,sd.MetaSelectedField_ValidationRuleId,sd.MetaSelectedField_LiteralValue,sd.MetaSelectedField_ReadOnly,sd.MetaSelectedField_AllowCopy,sd.MetaSelectedField_Precision,sd.MetaSelectedField_MetaForeignKeyLookupSourceId,NULL/*MetadataAttributeMapId*/,sd.MetaSelectedField_EditMapId,sd.MetaSelectedField_NumericDataLength,sd.MetaSelectedField_Config)
OUTPUT 'MetaSelectedField',sd.MetaSelectedField_MetaSelectedFieldId, INSERTED.MetaSelectedFieldId INTO #KeyTranslation2 (DestinationTable, OldId, NewId);

--=========================End Meta Selected Field==============================


--====================Begin Meta Selected Field Attribute=======================

		
-- Get MetaSelectedFieldAttribute
DECLARE  @MetaSelectedFieldAttributeTempTable Table
(MetaSelectedFieldAttribute_Id NVARCHAR(MAX),MetaSelectedFieldAttribute_Name NVARCHAR(MAX),MetaSelectedFieldAttribute_Value NVARCHAR(MAX),MetaSelectedFieldAttribute_MetaSelectedFieldId NVARCHAR(MAX));

INSERT INTO @MetaSelectedFieldAttributeTempTable
(MetaSelectedFieldAttribute_Id,MetaSelectedFieldAttribute_Name,MetaSelectedFieldAttribute_Value,MetaSelectedFieldAttribute_MetaSelectedFieldId)
OUTPUT INSERTED.*
VALUES
(1824,'SubText','If your department doesn''t have a DE policy yet, select N/A',6026)
;

-- INSERT MetaSelectedFieldAttribute INTO Destination Database

;WITH SourceData AS
( 
SELECT MetaSelectedFieldAttribute_Id,MetaSelectedFieldAttribute_Name,MetaSelectedFieldAttribute_Value,kt.NewId AS MetaSelectedFieldAttribute_MetaSelectedFieldId
FROM @MetaSelectedFieldAttributeTempTable tt 
INNER JOIN #KeyTranslation2 kt ON kt.OldId = MetaSelectedFieldAttribute_MetaSelectedFieldId
	AND DestinationTable = 'MetaSelectedField'
)
MERGE INTO MetaSelectedFieldAttribute
USING SourceData sd ON (1 = 0)
WHEN Not Matched By Target THEN
INSERT (Name,Value,MetaSelectedFieldId)
VALUES (sd.MetaSelectedFieldAttribute_Name,sd.MetaSelectedFieldAttribute_Value,sd.MetaSelectedFieldAttribute_MetaSelectedFieldId)
OUTPUT 'MetaSelectedFieldAttribute',sd.MetaSelectedFieldAttribute_Id, INSERTED.MetaSelectedFieldId INTO #KeyTranslation2 (DestinationTable, OldId, NewId);

--UPDATE MetaSelectedField attributes to convert the Value which is a MetaAailableFieldId to the NewId
;WITH SourceData AS 
	(
	SELECT fatt.MetaSelectedFieldAttribute_Name 
	,fatt.MetaSelectedFieldAttribute_Value AS OldFAValue
	,CAST(kt2.NewId AS NVARCHAR) AS NewFAValue
	,kt.NewId AS NewMetaSelectedFieldId
	FROM @MetaSelectedFieldAttributeTempTable fatt
	INNER JOIN #KeyTranslation2 kt
		ON fatt.MetaSelectedFieldAttribute_MetaSelectedFieldId = kt.OldId
			AND kt.DestinationTable = 'MetaSelectedField'
	INNER JOIN #KeyTranslation2 kt2
		ON CAST(fatt.MetaSelectedFieldAttribute_Value AS Int) = kt2.OldId
			AND kt2.DestinationTable = 'MetaSelectedField'
	WHERE fatt.MetaSelectedFieldAttribute_Name = 'subscription'
)
MERGE INTO MetaSelectedFieldAttribute
	USING SourceData sd ON MetaSelectedFieldId = sd.NewMetaSelectedFieldId
	AND Name = 'subscription'
	AND sd.OldFAValue = Value
	WHEN Matched THEN
	UPDATE SET Value = NewFAValue ;
	--OUTPUT INSERTED.*, 'UPDATEing the Value Field ON the FieldAttribute Table'; 

--=====================End Meta Selected Field Attribute========================

--=============================Begin Expression===================================

 
-- Get Expression
DECLARE  @ExpressionTempTable Table
( OldExpressionId Int
);

INSERT INTO @ExpressionTempTable
(OldExpressionId)
OUTPUT INSERTED.*
VALUES 
(1133)
,
(1134)
,
(1135)
,
(1136)
,
(1137)
,
(1138)
,
(1139)
,
(1140)
,
(1141)
,
(1142)
,
(1143)
,
(1144)
,
(1145)
,
(1146)
,
(1147)
;

--INSERT INTO Expression table ON Destination Database

;WITH SourceData AS
(
SELECT ett.OldExpressionId
FROM @ExpressionTempTable ett
)
MERGE INTO Expression
	USING SourceData sd ON (1 = 0)
	WHEN Not Matched By Target THEN
	INSERT DEFAULT VALUES 	
	OUTPUT 'Expression', sd.OldExpressionId, INSERTED.Id INTO #KeyTranslation2 (DestinatioNTable, OldId, NewId);


--===============================End Expression===================================


--============================Begin ExpressionPart================================

 
-- Get ExpressionPart
DECLARE  @ExpressionPartTempTable Table
( OldExpressionPartId INT,OldExpressionId_ExpressionPart INT,OldParent_ExpressionPartId INT,OldSortOrder_ExpressionPart INT,OldExpressionOperatorTypeId INT,OldComparisonDataTypeId INT,
OldOperAND1_MetaSelectedFieldId INT,OldOperAND2_MetaSelectedFieldId INT,OldOperAND2Literal NVARCHAR(500),OldOperAND3_MetaSelectedFieldId INT,OldOperAND3Literal NVARCHAR(500)
);

INSERT INTO @ExpressionPartTempTable
(OldExpressionPartId,OldExpressionId_ExpressionPart,OldParent_ExpressionPartId,OldSortOrder_ExpressionPart,OldExpressionOperatorTypeId,OldComparisonDataTypeId,
OldOperAND1_MetaSelectedFieldId,OldOperAND2_MetaSelectedFieldId,OldOperAND2Literal,OldOperAND3_MetaSelectedFieldId,OldOperAND3Literal)
OUTPUT INSERTED.*
VALUES 
(2889,1133,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2891,1133,2889,1,16,3,5987,NULL,'1',NULL,NULL)
,
(2890,1134,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2892,1134,2890,1,16,3,5987,NULL,'2',NULL,NULL)
,
(2893,1135,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2894,1135,2893,1,3,4,6003,NULL,'false',NULL,NULL)
,
(2895,1136,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2896,1136,2895,1,3,4,6004,NULL,'false',NULL,NULL)
,
(2897,1137,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2898,1137,2897,1,3,4,6005,NULL,'false',NULL,NULL)
,
(2899,1138,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2900,1138,2899,1,3,4,6006,NULL,'false',NULL,NULL)
,
(2901,1139,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2902,1139,2901,1,3,4,6007,NULL,'false',NULL,NULL)
,
(2903,1140,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2904,1140,2903,1,3,4,6008,NULL,'false',NULL,NULL)
,
(2905,1141,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2906,1141,2905,1,3,4,6009,NULL,'false',NULL,NULL)
,
(2907,1142,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2908,1142,2907,1,3,4,6010,NULL,'false',NULL,NULL)
,
(2909,1143,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2910,1143,2909,1,3,4,5982,NULL,'false',NULL,NULL)
,
(2911,1144,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2912,1144,2911,1,3,4,5983,NULL,'false',NULL,NULL)
,
(2913,1145,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2914,1145,2913,1,3,4,6011,NULL,'false',NULL,NULL)
,
(2915,1146,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2916,1146,2915,1,16,3,6024,NULL,'1',NULL,NULL)
,
(2917,1147,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2918,1147,2917,1,3,3,5989,NULL,'11',NULL,NULL)
;

--INSERT INTO ExpressionPart table ON Destination Database

;WITH SourceData AS
(
SELECT ept.OldExpressionPartId,ept.OldExpressionId_ExpressionPart, kt.NewId AS ExpressionId,OldSortOrder_ExpressionPart AS SortOrder,OldExpressionOperatorTypeId AS ExpressionOperatorTypeId,OldComparisonDataTypeId AS ComparisonDataTypeId,kt1.NewId AS OperAND1_MetaSelectedFieldId,kt2.NewId AS OperAND2_MetaSelectedFieldId,OldOperAND2Literal AS OperAND2Literal,kt3.NewId AS OperAND3_MetaSelectedFieldId,OldOperAND3Literal AS OperAND3Literal
FROM @ExpressionPartTempTable ept
LEFT JOIN #KeyTranslation2 kt  ON kt.OldId  = ept.OldExpressionId_ExpressionPart AND kt.DestinatioNTable = 'Expression'
LEFT JOIN #KeyTranslation2 kt1 ON kt1.OldId = ept.OldOperAND1_MetaSelectedFieldId AND kt1.DestinatioNTable = 'MetaSelectedField'
LEFT JOIN #KeyTranslation2 kt2 ON kt2.OldId = ept.OldOperAND2_MetaSelectedFieldId AND kt2.DestinatioNTable = 'MetaSelectedField'
LEFT JOIN #KeyTranslation2 kt3 ON kt3.OldId = ept.OldOperAND3_MetaSelectedFieldId AND kt3.DestinatioNTable = 'MetaSelectedField'
)
MERGE INTO ExpressionPart
		USING SourceData sd ON (1 = 0)
		WHEN Not Matched By Target THEN
		INSERT (ExpressionId,SortOrder,ExpressionOperatorTypeId,ComparisonDataTypeId,OperAND1_MetaSelectedFieldId,OperAND2_MetaSelectedFieldId,OperAND2Literal,OperAND3_MetaSelectedFieldId,OperAND3Literal)
 		VALUES (sd.ExpressionId,sd.SortOrder,sd.ExpressionOperatorTypeId,sd.ComparisonDataTypeId,sd.OperAND1_MetaSelectedFieldId,sd.OperAND2_MetaSelectedFieldId,sd.OperAND2Literal,sd.OperAND3_MetaSelectedFieldId,sd.OperAND3Literal)
		OUTPUT 'ExpressionPart', sd.OldExpressionPartId, INSERTED.Id INTO #KeyTranslation2 (DestinatioNTable, OldId, NewId);

-- UPDATE Expression Part with ParentExpressionPartIds ON Destination Database


;WITH SourceData AS
(
SELECT  ept.OldExpressionPartId, Kt.NewId AS NewExpressionPartId,ept.OldParent_ExpressionPartId,kt1.NewId AS NewParent_ExpressionPartId 
FROM @ExpressionPartTempTable ept
INNER JOIN #KeyTranslation2 kt ON kt.OldId = ept.OldExpressionPartId AND kt.DestinationTable = 'ExpressionPart'
INNER JOIN #KeyTranslation2 kt1  ON kt1.OldId  = ept.OldParent_ExpressionPartId AND kt1.DestinationTable = 'ExpressionPart' AND ept.OldParent_ExpressionPartId is not null
)
UPDATE ExpressionPart 
SET Parent_ExpressionPartId = sd.NewParent_ExpressionPartId 
OUTPUT INSERTED.*
FROM SourceData sd
WHERE Id = sd.NewExpressionPartId ;


--============================End ExpressionPart==================================


--==========================Begin MetaDisplayRule=================================

 
-- Get MetaDisplayRule
DECLARE  @DisplayRuleTempTable Table
( OldDisplayRuleId INT,DisplayRuleName NVARCHAR(500),DisplayRuleValue NVARCHAR(500),OldMetaSelectedFieldId_DisplayRule INT,OldMetaSelectedSectionId_DisplayRule INT,
MetaDisplayRuleTypeId INT,OldExpressionId_DisplayRule int
);

INSERT INTO @DisplayRuleTempTable
(OldDisplayRuleId,DisplayRuleName,DisplayRuleValue,OldMetaSelectedFieldId_DisplayRule,OldMetaSelectedSectionId_DisplayRule,MetaDisplayRuleTypeId,OldExpressionId_DisplayRule)
OUTPUT INSERTED.*
VALUES 
(1132,'show non credit field',NULL,5987,NULL,2,1133)
,
(1133,'show provide rationle',NULL,5987,NULL,2,1134)
,
(1134,'showOther',NULL,6003,NULL,2,1135)
,
(1135,'showOther',NULL,6004,NULL,2,1136)
,
(1136,'showOther',NULL,6005,NULL,2,1137)
,
(1137,'showOther',NULL,6006,NULL,2,1138)
,
(1138,'showOther',NULL,6007,NULL,2,1139)
,
(1139,'showOther',NULL,6008,NULL,2,1140)
,
(1140,'showOther',NULL,6009,NULL,2,1141)
,
(1141,'showOther',NULL,6010,NULL,2,1142)
,
(1142,'showOther',NULL,5982,NULL,2,1143)
,
(1143,'showOther',NULL,5983,NULL,2,1144)
,
(1144,'showOther',NULL,6011,NULL,2,1145)
,
(1145,'pleasedescripeifyes',NULL,6024,NULL,2,1146)
,
(1146,'dm',NULL,5989,NULL,2,1147)
;

--	Merge INTO MetaDisplayRule

;WITH SourceData AS
(
	SELECT drtt.OldDisplayRuleId,drtt.DisplayRuleName,drtt.DisplayRuleValue,kt1.NewId AS MetaSelectedFieldId,kt2.NewId AS MetaSelectedSectionId,drtt.MetaDisplayRuleTypeId,kt3.NewId AS  ExpressionId
	FROM @DisplayRuleTempTable drtt
	LEFT JOIN #KeyTranslation2 kt1 ON drtt.OldMetaSelectedFieldId_DisplayRule = kt1.OldId
	AND kt1.DestinationTable = 'MetaSelectedField'
	LEFT JOIN #KeyTranslation2 kt2 ON drtt.OldMetaSelectedSectionId_DisplayRule = kt2.OldId
	AND kt2.DestinationTable = 'MetaSelectedSection'
	INNER JOIN #KeyTranslation2 kt3 ON drtt.OldExpressionId_DisplayRule = kt3.OldId
	AND kt3.DestinationTable = 'Expression'
)
MERGE INTO MetaDisplayRule
		USING SourceData sd ON (1 = 0)
		WHEN Not Matched By Target THEN
		INSERT (DisplayRuleName,DisplayRuleValue,MetaSelectedFieldId,MetaSelectedSectionId,MetaDisplayRuleTypeId,ExpressionId)
		VALUES (sd.DisplayRuleName,sd.DisplayRuleValue,sd.MetaSelectedFieldId,sd.MetaSelectedSectionId,sd.MetaDisplayRuleTypeId,sd.ExpressionId)
		OUTPUT 'MetaDisplayRule', sd.OldDisplayRuleId, INSERTED.Id INTO #KeyTranslation2 (DestinatioNTable, OldId, NewId);

--============================End MetaDisplayRule=================================


--========================Begin MetaDisplaySubscriber=============================

 
-- Get MetaDisplaySubscriber
DECLARE  @DisplaySubscriberTempTable Table
(OldId_DisplaySubscriber  INT,SubscriberName NVARCHAR(500),OldMetaSelectedFieldId_DisplaySubscriber INT,OldMetaSelectedSectionId_DisplaySubscriber INT,OldMetaDisplayRuleId_DisplaySubscriber Int
);

INSERT INTO @DisplaySubscriberTempTable
(OldId_DisplaySubscriber,SubscriberName,OldMetaSelectedFieldId_DisplaySubscriber,OldMetaSelectedSectionId_DisplaySubscriber,OldMetaDisplayRuleId_DisplaySubscriber)
OUTPUT INSERTED.*
VALUES 
(2199,'Show DE',NULL,3501,1132)
,
(2200,'Show DE',NULL,3500,1132)
,
(2201,'show provide rationle',NULL,3502,1133)
,
(2202,'Show DE',NULL,3503,1132)
,
(2203,'showOther',NULL,3529,1134)
,
(2204,'showOther',NULL,3530,1135)
,
(2205,'showOther',NULL,3531,1136)
,
(2206,'showOther',NULL,3532,1137)
,
(2207,'showOther',NULL,3533,1138)
,
(2208,'showOther',NULL,3534,1139)
,
(2209,'showOther',NULL,3535,1140)
,
(2210,'showOther',NULL,3536,1141)
,
(2211,'showOther',NULL,3537,1142)
,
(2212,'showOther',NULL,3538,1143)
,
(2213,'showOther',NULL,3539,1144)
,
(2214,'pleasedescripeifyes',NULL,3540,1145)
,
(2215,'Show DE',NULL,3504,1132)
,
(2216,'Show DE',NULL,3505,1132)
,
(2217,'Show DE',NULL,3506,1132)
,
(2218,'Show DE',NULL,3507,1132)
,
(2219,'Show DE',NULL,3508,1132)
,
(2220,'Show DE',NULL,3509,1132)
,
(2221,'Show DE',NULL,3510,1132)
,
(2222,'Show DE',NULL,3511,1132)
,
(2223,'Show DE',NULL,3512,1132)
,
(2224,'Show DE',NULL,3513,1132)
,
(2225,'Show DE',NULL,3514,1132)
,
(2226,'Show DE',NULL,3515,1132)
,
(2227,'Show DE',NULL,3516,1132)
,
(2228,'Show DE',NULL,3517,1132)
,
(2229,'Show DE',NULL,3518,1132)
,
(2230,'Show DE',NULL,3519,1132)
,
(2231,'Show DE',NULL,3520,1132)
,
(2232,'Show DE',NULL,3521,1132)
,
(2233,'Show DE',NULL,3522,1132)
,
(2234,'Show DE',NULL,3523,1132)
,
(2235,'Show DE',NULL,3524,1132)
,
(2236,'Show DE',NULL,3525,1132)
,
(2237,'Show DE',NULL,3526,1132)
,
(2238,'Show DE',NULL,3527,1132)
,
(2239,'Show DE',NULL,3528,1132)
,
(2240,'Show DE',NULL,3529,1132)
,
(2241,'Show DE',NULL,3530,1132)
,
(2242,'Show DE',NULL,3531,1132)
,
(2243,'Show DE',NULL,3532,1132)
,
(2244,'Show DE',NULL,3533,1132)
,
(2245,'Show DE',NULL,3534,1132)
,
(2246,'Show DE',NULL,3535,1132)
,
(2247,'Show DE',NULL,3536,1132)
,
(2248,'Show DE',NULL,3537,1132)
,
(2249,'Show DE',NULL,3538,1132)
,
(2250,'Show DE',NULL,3539,1132)
,
(2251,'Show DE',NULL,3540,1132)
,
(2252,'Show DE',NULL,3541,1132)
,
(2253,'Show DE',NULL,3542,1132)
,
(2254,'ShowConsultation',NULL,3541,1146)
;

-- MERGE INTO MetaDisplaySubscriber
;WITH SourceData AS
(
	SELECT OldId_DisplaySubscriber,SubscriberName,kt1.NewId AS MetaSelectedFieldId,kt2.NewId AS MetaSelectedSectionId,kt3.NewId AS MetaDisplayRuleId
	FROM @DisplaySubscriberTempTable dstt
	LEFT JOIN #KeyTranslation2 kt1 ON dstt.OldMetaSelectedFieldId_DisplaySubscriber = kt1.OldId
		AND kt1.DestinationTable = 'MetaSelectedField'
	LEFT JOIN #KeyTranslation2 kt2 ON dstt.OldMetaSelectedSectionId_DisplaySubscriber = kt2.OldId
		AND kt2.DestinationTable = 'MetaSelectedSection'
	INNER JOIN #KeyTranslation2 kt3 ON dstt.OldMetaDisplayRuleId_DisplaySubscriber = kt3.OldId
		AND kt3.DestinationTable = 'MetaDisplayRule'
)
MERGE INTO MetaDisplaySubscriber
		USING SourceData sd ON (1 = 0)
		WHEN Not Matched By Target THEN
		INSERT (SubscriberName,MetaSelectedFieldId,MetaSelectedSectionId,MetaDisplayRuleId)
		VALUES (sd.SubscriberName,sd.MetaSelectedFieldId,sd.MetaSelectedSectionId,sd.MetaDisplayRuleId)
		OUTPUT 'MetaDisplaySubscriber', sd.OldId_DisplaySubscriber, INSERTED.Id INTO #KeyTranslation2 (DestinatioNTable, OldId, NewId);

--=========================End MetaDisplaySubscriber==============================

SELECT newid AS MetaTemplateId
FROM #KeyTranslation2
WHERE DestinationTable='MetaTemplate'

UPDATE MetaTemplate
SET LastUpdatedDate=GETDATE( )
OUTPUT INSERTED.*
WHERE MetaTemplateId=@MetaTemplateId

--SELECT * FROM #KeyTranslation
DROP TABLE IF EXISTS #KeyTranslation2
------------------------------------------------------------------------------------------------------------------------------------------------------------------