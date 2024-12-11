
	/************************************************************************************************
	***                               Insertion of Extracted Script                          
	***                                                                                       
	***                                                                                       
	*** Created with the Template Configuration Extract Script and SQL Generator (version 2022.12.14)        
	***                                                                                       
	*** Script generated on Jun 15 2023  9:55AM                                              
	***                                                                                       
	*** Source Client: Compton College                                                                 
	*** Source Template: 18                                                              
	*** Source Template Name: Copy of New Course (Content Modification)             
	*** Initial table: MetaSelectedSection       
	*** Initial id: 2352 
	*** 
	***                                                                               
	***  Instructions for manually inserting into a Database:                               
	***                  1. Replace the Database Name in the "Use" statement if necessary     
	***                  2. Replace the Id in the @ClientId declaration if necessary                                 
	***                  3. Run the Script.                                                   
	***                                                                                       
	***  
    ***  Notes:          1. This will insert the selected section and all child sections
    ***                     into the template. 
    ***                  2. @InitialId is a required peramater 	
	***                  3. By default the @MetaTemplateId is set to the Id of the Template it was extracted from 
	***                     this can be manually changed to insert the section(s) into a different template
    ***  
	***
	***                                                                                             
	***                                                                                       
	************************************************************************************************/
Use compton;

DECLARE @JiraTicketNumber NVARCHAR(20) = 'MS-14005';
DECLARE @Comments NVARCHAR(MAX) = 'Add IDEA Tab for Course Review Template';
DECLARE @Developer NVARCHAR(50) = 'Nathan W';
DECLARE @ScriptTypeId int = 2; /* Default on this script is 2 = Enhancement
To See all Options run the following Query

SELECT * FROM history.ScriptType
*/
DECLARE @ClientCode nvarchar(50) = NULL ;
DECLARE @InitialTableName NVARCHAR(100);
SET @InitialTableName = 'MetaSelectedSection';
DECLARE @InitialId int = 2352;
DECLARE @ClientId Int = 1;
DECLARE @OverrideClientId Int = Coalesce((Select Id from Client where Code =  @ClientCode ),(Select top 1 Id from Client where Active = 1));
DECLARE @SourceDatabase NVARCHAR(100) = 'compton';
DECLARE @SourceTemplateTypeId Int = 1;
DECLARE @SourceTemplateId int  = 18;
DECLARE @InsertToMetaTemplateId int = 19; --Set this if inserting sections into a different template Id from the extrated template
DECLARE @InsertToMetaTemplateTypeId int = 18; --Set this if inserting sections into a different template type Id from the extrated template
DECLARE @SourceParentSectionId int ; --Do not set this variable
DECLARE @TargetParentSectionId int ; --Do not set this here set it below if necessary
DECLARE @ClientEntityType NVARCHAR(100) = 'Course';

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

SET XACT_ABORT ON
BEGIN TRAN



	INSERT INTO History.ScriptsRunOnDatabase
	(TicketNumber,Developer,Comments,ScriptTypeId)
	Output Inserted.*
	VALUES
	( @JiraTicketNumber , 
	  @Developer ,
	  @Comments ,
	  @ScriptTypeId 
	);

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
(1,2,1)
,
(1,2,2)
,
(1,6,1)
,
(1,6,2)
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

--======================Begin Client Entity Sub Type============================

--======================End Client Entity Sub Type==============================


--=======================Begin Meta SELECTed Section============================

	
		
	-- Get MetaSelectedSection
	DECLARE  @MetaSelectedSectionTempTable Table
	(MetaSelectedSection_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedSection_ClientId NVARCHAR(MAX),MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedSection_SectionName NVARCHAR(MAX),MetaSelectedSection_DisplaySectionName NVARCHAR(MAX),MetaSelectedSection_SectionDescription NVARCHAR(MAX),MetaSelectedSection_DisplaySectionDescription NVARCHAR(MAX),MetaSelectedSection_ColumnPosition NVARCHAR(MAX),MetaSelectedSection_RowPosition NVARCHAR(MAX),MetaSelectedSection_SortOrder NVARCHAR(MAX),MetaSelectedSection_SectionDisplayId NVARCHAR(MAX),MetaSelectedSection_MetASectionTypeId NVARCHAR(MAX),MetaSelectedSection_MetaTemplateId NVARCHAR(MAX),MetaSelectedSection_DisplayFieldId NVARCHAR(MAX),MetaSelectedSection_HeaderFieldId NVARCHAR(MAX),MetaSelectedSection_FooterFieldId NVARCHAR(MAX),MetaSelectedSection_OriginatorOnly NVARCHAR(MAX),MetaSelectedSection_MetaBASeSchemaId NVARCHAR(MAX),MetaSelectedSection_MetadataAttributeMapId NVARCHAR(MAX),MetaSelectedSection_EntityListLibraryTypeId NVARCHAR(MAX),MetaSelectedSection_EditMapId NVARCHAR(MAX),MetaSelectedSection_AllowCopy NVARCHAR(MAX),MetaSelectedSection_ReadOnly NVARCHAR(MAX),MetaSelectedSection_Config NVARCHAR(MAX));
	

	INSERT INTO @MetaSelectedSectionTempTable
	(MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_ClientId,MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_SectionName,MetaSelectedSection_DisplaySectionName,MetaSelectedSection_SectionDescription,MetaSelectedSection_DisplaySectionDescription,MetaSelectedSection_ColumnPosition,MetaSelectedSection_RowPosition,MetaSelectedSection_SortOrder,MetaSelectedSection_SectionDisplayId,MetaSelectedSection_MetASectionTypeId,MetaSelectedSection_MetaTemplateId,MetaSelectedSection_DisplayFieldId,MetaSelectedSection_HeaderFieldId,MetaSelectedSection_FooterFieldId,MetaSelectedSection_OriginatorOnly,MetaSelectedSection_MetaBASeSchemaId,MetaSelectedSection_MetadataAttributeMapId,MetaSelectedSection_EntityListLibraryTypeId,MetaSelectedSection_EditMapId,MetaSelectedSection_AllowCopy,MetaSelectedSection_ReadOnly,MetaSelectedSection_Config)
	OUTPUT INSERTED.*
	VALUES
	
(2352,1,NULL,'IDEA',1,NULL,0,NULL,15,15,1,15,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2353,1,2352,'IDEA- (Inclusion, Diversity, Equity, and Accessibility)',1,'The IDEA section of the course outline of record is currently optional.<br> If completing, for each question, please answer Yes or Not Applicable (N/A) and include an explanation as required.',1,NULL,0,0,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2355,1,2352,'Course Description',1,NULL,1,NULL,1,1,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2357,1,2352,NULL,1,NULL,1,NULL,2,2,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2359,1,2352,'Content',1,NULL,1,NULL,3,3,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2361,1,2352,NULL,1,'Explain for 1',0,NULL,4,4,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2363,1,2352,NULL,1,'Question 2 in content',0,NULL,5,5,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2365,1,2352,NULL,1,'Explain 2',0,NULL,6,6,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2367,1,2352,NULL,1,'3 in content',0,NULL,7,7,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2369,1,2352,NULL,1,'explain 3 in content',0,NULL,8,8,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2371,1,2352,'Course Objectives',1,NULL,0,NULL,9,9,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2373,1,2352,NULL,1,'Explain for obj 1',0,NULL,10,10,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2375,1,2352,NULL,1,'OBJ 2 question',0,NULL,11,11,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2377,1,2352,NULL,1,'OBJ 2 explain',0,NULL,12,12,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2379,1,2352,NULL,1,'OBJ 3 question',0,NULL,14,14,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2381,1,2352,NULL,1,'OBJ 3 explain',0,NULL,15,15,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2383,1,2352,NULL,1,'OBJ 4 question',0,NULL,16,16,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2387,1,2352,'Methods of Evaluation and Examination',1,NULL,0,NULL,18,17,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2389,1,2352,NULL,1,'Explain for obj 1',0,NULL,19,18,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2391,1,2352,NULL,1,'OBJ 2 question',0,NULL,20,19,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2393,1,2352,NULL,1,'OBJ 2 explain',0,NULL,21,20,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2395,1,2352,NULL,1,'OBJ 3 question',0,NULL,22,21,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2397,1,2352,NULL,1,'OBJ 3 explain',0,NULL,23,22,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2399,1,2352,NULL,1,'OBJ 4 question',0,NULL,24,23,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2401,1,2352,NULL,1,'OBJ 4 explain',0,NULL,25,24,1,1,18,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
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

	
--There are no applicable MetaSelectedSectionAttribute records.

--===================End Meta Selected Section Attribute========================

	

--==================Begin Meta SELECTed Section SETting=========================

	
--There are no applicable MetaSelectedSectionSetting records.

--====================End Meta Selected Section SETting=========================

	

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
(1,98,'YesNo','Id','Title','select Id as Value, Title as Text from YesNo Where Title not in (''No'')','select Id as Value, Title as Text from YesNo Where id = @id','Order By SortOrder','Yes/NA DropDown',1,NULL,NULL)
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
(3864,'Will the IDEA section be completed at this time?',1730,2353,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3865,'The course description takes into consideration IDEA (inclusion, diversity, equity, and accessibility)?',6382,2355,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3877,'Explanation',2961,2357,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3866,'1.	The content appeals to and impacts diverse students’ interests, diverse learning styles, disability/ability, skills, attitudes, and life experiences.',6383,2359,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3878,'Explanation',2963,2361,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3867,'2.	The content is aimed at diversity and/or inclusion-related knowledge, skills, and attitudes.',6384,2363,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3879,'Explanation',2964,2365,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3868,'3.	The content is relevant and personal for students in addressing the impact on students and/or their communities.',6385,2367,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3880,'Explanation',2965,2369,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3869,'1. The course objectives appeal to and impact diverse students’ interests, diverse learning styles, disability/ability, skills, attitudes, and prior knowledge.',6386,2371,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3881,'Explanation',2966,2373,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3870,'2. The course textbook and/or material(s) includes multiple culturally diverse authors that represent historically marginalized groups and/or philosophies.',6387,2375,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3882,'Explanation',2967,2377,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3871,'3. The course textbook(s) and/or materials include a balance of images that display a diversity of identities.',6446,2379,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3883,'Explanation',2968,2381,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3872,'4. This course has an Open Education Resources (OER) or Zero Textbook Cost (ZTC) option for faculty to consider.',6447,2383,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3873,'1.	The methods of evaluation and examination include assessments of in-class activities that encourage peer interactions.',6448,2387,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3884,'Explanation',2969,2389,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3874,'2.	The course activities are aligned with the principles of a Universal Design for Learning (UDL).',6449,2391,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3885,'Explanation',2970,2393,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3875,'3.	The methods of instruction foster real-life scenarios related to the discipline or job skills.',6450,2395,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3886,'Explanation',2971,2397,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3876,'4.	The methods of instruction use rubrics and/or standards for different grading on assessments by providing examples of work that aligns with courses grades.',6451,2399,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,98,NULL,NULL,NULL,NULL)
,
(3887,'Explanation',2972,2401,1,NULL,NULL,0,0,1,'Textarea',17,100,2,75,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
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


--====================Begin Meta Selected Field Attribute=======================


--=====================End Meta Selected Field Attribute========================


--==========================Begin Meta Title Fields=============================


--===========================End Meta Title Fields==============================


--=============================Begin Position=====================================


--===============================End Position=====================================


--=========================Begin MetaDataAttribute/Map===========================


--==========================End MetaDataAttribute/Map============================


--===========================Begin update EditMap================================


--==========================Begin Show/Hide Tables================================


--=============================Begin Expression===================================

 
-- Get Expression
DECLARE  @ExpressionTempTable Table
( OldExpressionId Int
);

INSERT INTO @ExpressionTempTable
(OldExpressionId)
OUTPUT INSERTED.*
VALUES 
(671)
,
(672)
,
(673)
,
(674)
,
(675)
,
(676)
,
(677)
,
(678)
,
(679)
,
(680)
,
(681)
,
(682)
,
(683)
,
(684)
,
(685)
,
(686)
,
(687)
,
(688)
,
(689)
,
(690)
,
(691)
,
(692)
,
(693)
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
	OUTPUT 'Expression', sd.OldExpressionId, INSERTED.Id INTO #KeyTranslation (DestinatioNTable, OldId, NewId);


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
(1429,671,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1430,671,1429,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1431,672,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1432,672,1431,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1433,673,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1434,673,1433,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1435,674,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1436,674,1435,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1437,675,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1438,675,1437,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1439,676,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1440,676,1439,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1441,677,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1442,677,1441,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1443,678,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1444,678,1443,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1445,679,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1446,679,1445,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1447,680,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1448,680,1447,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1449,681,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1450,681,1449,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1451,682,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1452,682,1451,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1453,683,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1454,683,1453,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1455,684,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1456,684,1455,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1457,685,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1458,685,1457,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1459,686,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1460,686,1459,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1461,687,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1462,687,1461,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1463,688,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1464,688,1463,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1465,689,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1466,689,1465,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1467,690,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1468,690,1467,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1469,691,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1470,691,1469,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1471,692,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1472,692,1471,1,3,3,3864,NULL,'false',NULL,NULL)
,
(1473,693,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1474,693,1473,1,3,3,3864,NULL,'false',NULL,NULL)
;

--INSERT INTO ExpressionPart table ON Destination Database

;WITH SourceData AS
(
SELECT ept.OldExpressionPartId,ept.OldExpressionId_ExpressionPart, kt.NewId AS ExpressionId,OldSortOrder_ExpressionPart AS SortOrder,OldExpressionOperatorTypeId AS ExpressionOperatorTypeId,OldComparisonDataTypeId AS ComparisonDataTypeId,kt1.NewId AS OperAND1_MetaSelectedFieldId,kt2.NewId AS OperAND2_MetaSelectedFieldId,OldOperAND2Literal AS OperAND2Literal,kt3.NewId AS OperAND3_MetaSelectedFieldId,OldOperAND3Literal AS OperAND3Literal
FROM @ExpressionPartTempTable ept
LEFT JOIN #KeyTranslation kt  ON kt.OldId  = ept.OldExpressionId_ExpressionPart AND kt.DestinatioNTable = 'Expression'
LEFT JOIN #KeyTranslation kt1 ON kt1.OldId = ept.OldOperAND1_MetaSelectedFieldId AND kt1.DestinatioNTable = 'MetaSelectedField'
LEFT JOIN #KeyTranslation kt2 ON kt2.OldId = ept.OldOperAND2_MetaSelectedFieldId AND kt2.DestinatioNTable = 'MetaSelectedField'
LEFT JOIN #KeyTranslation kt3 ON kt3.OldId = ept.OldOperAND3_MetaSelectedFieldId AND kt3.DestinatioNTable = 'MetaSelectedField'
)
MERGE INTO ExpressionPart
		USING SourceData sd ON (1 = 0)
		WHEN Not Matched By Target THEN
		INSERT (ExpressionId,SortOrder,ExpressionOperatorTypeId,ComparisonDataTypeId,OperAND1_MetaSelectedFieldId,OperAND2_MetaSelectedFieldId,OperAND2Literal,OperAND3_MetaSelectedFieldId,OperAND3Literal)
 		VALUES (sd.ExpressionId,sd.SortOrder,sd.ExpressionOperatorTypeId,sd.ComparisonDataTypeId,sd.OperAND1_MetaSelectedFieldId,sd.OperAND2_MetaSelectedFieldId,sd.OperAND2Literal,sd.OperAND3_MetaSelectedFieldId,sd.OperAND3Literal)
		OUTPUT 'ExpressionPart', sd.OldExpressionPartId, INSERTED.Id INTO #KeyTranslation (DestinatioNTable, OldId, NewId);

-- UPDATE Expression Part with ParentExpressionPartIds ON Destination Database


;WITH SourceData AS
(
SELECT  ept.OldExpressionPartId, Kt.NewId AS NewExpressionPartId,ept.OldParent_ExpressionPartId,kt1.NewId AS NewParent_ExpressionPartId 
FROM @ExpressionPartTempTable ept
INNER JOIN #KeyTranslation kt ON kt.OldId = ept.OldExpressionPartId AND kt.DestinationTable = 'ExpressionPart'
INNER JOIN #KeyTranslation kt1  ON kt1.OldId  = ept.OldParent_ExpressionPartId AND kt1.DestinationTable = 'ExpressionPart' AND ept.OldParent_ExpressionPartId is not null
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
(524,'5-Year Text Rule',NULL,3103,NULL,2,524)
,
(525,'Show Other Evaluation Methods',NULL,3141,NULL,2,525)
,
(526,'Have all faculty in deparmnet be... | Show Explain',NULL,3142,NULL,2,526)
,
(528,'General Education/Articulation | C-ID Articulation',NULL,3174,NULL,2,528)
,
(529,'Show/hide Local GE',NULL,3191,NULL,2,529)
,
(530,'Show/hide CSU',NULL,3192,NULL,2,530)
,
(531,'Show/hide IGETC',NULL,3193,NULL,2,531)
,
(532,'Show/hide UC TCA',NULL,3175,NULL,2,532)
,
(533,'Show Old Manual Justification',NULL,3139,NULL,2,533)
,
(534,'Conditions of Enrollment | Other',NULL,3204,NULL,2,534)
,
(535,'Conditions of Enrollment | PreRequisite',NULL,3204,NULL,2,535)
,
(536,'DE',NULL,3207,NULL,2,536)
,
(537,'Variable Hours',NULL,3216,NULL,2,537)
,
(538,'Show Variable Units',NULL,3216,NULL,2,538)
,
(539,'Show Variable Units',NULL,3216,NULL,2,539)
,
(540,'Show Maximum Units',NULL,3216,NULL,2,540)
,
(541,'Show Lab Only Option',NULL,3218,NULL,2,541)
,
(542,'Show Repeatable Times',NULL,3221,NULL,2,542)
,
(543,'Show Participatory Courses',NULL,3223,NULL,2,543)
,
(544,'Hide Lecture units/hours',NULL,3217,NULL,2,544)
,
(545,'Lab only hide lec',NULL,3217,NULL,2,545)
,
(546,'Lab only hide lec obj',NULL,3217,NULL,2,546)
,
(547,'Lab only hide lec obj',NULL,3217,NULL,2,547)
,
(548,'NonCredit',NULL,3244,NULL,2,548)
,
(549,'NonCredit',NULL,3244,NULL,2,549)
,
(550,'NonCredit',NULL,3244,NULL,2,550)
,
(551,'NonCredit',NULL,3244,NULL,2,551)
,
(552,'NonCredit',NULL,3244,NULL,2,552)
,
(553,'NonCredit',NULL,3244,NULL,2,553)
,
(554,'CTE',NULL,3243,NULL,2,554)
,
(555,'Show Lab Units',NULL,3218,NULL,2,555)
,
(556,'Articulation',NULL,3246,NULL,2,556)
,
(557,'Hide 2 checkboxes',NULL,3244,NULL,2,557)
,
(558,'Enroll feest',NULL,3284,NULL,2,558)
,
(559,'Hide Course Content',NULL,3267,NULL,2,559)
,
(560,'Hide Course Objective',NULL,3267,NULL,2,560)
,
(561,'Hide Requisite Objective',NULL,3267,NULL,2,561)
,
(562,'Hide Requisite Content',NULL,3267,NULL,2,562)
,
(563,'NonCredit',NULL,3244,NULL,2,563)
,
(564,'Method of Eval - reading assignments',NULL,3278,NULL,2,564)
,
(565,'Method of Eval - reading assignments',NULL,3280,NULL,2,565)
,
(566,'Method of Eval - other assignments',NULL,3282,NULL,2,566)
,
(567,'Show Course Requisites',NULL,3287,NULL,2,567)
,
(568,'Show Content Review Require',NULL,3287,NULL,2,568)
,
(569,'Show Content Review Require',NULL,3287,NULL,2,569)
,
(570,'StudentPerformanceObjectivesYesNo',NULL,3297,NULL,2,570)
,
(571,'AssignmentsYesNo',NULL,3299,NULL,2,571)
,
(572,'AssessmentYesNo',NULL,3301,NULL,2,572)
,
(573,'SomeAssignmentsSample',NULL,3277,NULL,2,573)
,
(574,'Entity (Data Entry)',NULL,3340,NULL,2,574)
,
(575,'Entity (Data Entry)',NULL,3341,NULL,2,575)
,
(576,'Entity (Data Entry)',NULL,3343,NULL,2,576)
,
(577,'show content review OL',NULL,3366,NULL,2,577)
,
(578,'Will honors distinction apply to any section of th',NULL,3374,NULL,2,578)
,
(579,'Will honors distinction apply to any section of th',NULL,3288,NULL,2,579)
,
(582,'Will honors distinction apply to any section of th',NULL,3110,NULL,2,582)
,
(583,'Will honors distinction apply to any section of th',NULL,3218,NULL,2,583)
,
(584,'Will honors distinction apply to any section of th',NULL,3386,NULL,2,584)
,
(585,'Will honors distinction apply to any section of th',NULL,3110,NULL,2,585)
,
(586,'Will honors distinction apply to any section of th',NULL,3375,NULL,2,586)
,
(654,'hide concurrent checkbox',NULL,3204,NULL,2,654)
,
(657,'hide notes on requisites',NULL,3204,NULL,2,657)
,
(667,'Hide Fully Online (100% Online)',NULL,3288,NULL,2,667)
,
(669,'Hide if Fully Online',NULL,3844,NULL,2,669)
,
(671,'Show/hide IDEA TAB',NULL,3864,NULL,2,671)
,
(672,'Show/hide IDEA TAB',NULL,3864,NULL,2,672)
,
(673,'Show/hide IDEA TAB',NULL,3864,NULL,2,673)
,
(674,'Show/hide IDEA TAB',NULL,3864,NULL,2,674)
,
(675,'Show/hide IDEA TAB',NULL,3864,NULL,2,675)
,
(676,'Show/hide IDEA TAB',NULL,3864,NULL,2,676)
,
(677,'Show/hide IDEA TAB',NULL,3864,NULL,2,677)
,
(678,'Show/hide IDEA TAB',NULL,3864,NULL,2,678)
,
(679,'Show/hide IDEA TAB',NULL,3864,NULL,2,679)
,
(680,'Show/hide IDEA TAB',NULL,3864,NULL,2,680)
,
(681,'Show/hide IDEA TAB',NULL,3864,NULL,2,681)
,
(682,'Show/hide IDEA TAB',NULL,3864,NULL,2,682)
,
(683,'Show/hide IDEA TAB',NULL,3864,NULL,2,683)
,
(684,'Show/hide IDEA TAB',NULL,3864,NULL,2,684)
,
(685,'Show/hide IDEA TAB',NULL,3864,NULL,2,685)
,
(686,'Show/hide IDEA TAB',NULL,3864,NULL,2,686)
,
(687,'Show/hide IDEA TAB',NULL,3864,NULL,2,687)
,
(688,'Show/hide IDEA TAB',NULL,3864,NULL,2,688)
,
(689,'Show/hide IDEA TAB',NULL,3864,NULL,2,689)
,
(690,'Show/hide IDEA TAB',NULL,3864,NULL,2,690)
,
(691,'Show/hide IDEA TAB',NULL,3864,NULL,2,691)
,
(692,'Show/hide IDEA TAB',NULL,3864,NULL,2,692)
,
(693,'Show/hide IDEA TAB',NULL,3864,NULL,2,693)
;

--	Merge INTO MetaDisplayRule

;WITH SourceData AS
(
	SELECT drtt.OldDisplayRuleId,drtt.DisplayRuleName,drtt.DisplayRuleValue,kt1.NewId AS MetaSelectedFieldId,kt2.NewId AS MetaSelectedSectionId,drtt.MetaDisplayRuleTypeId,kt3.NewId AS  ExpressionId
	FROM @DisplayRuleTempTable drtt
	LEFT JOIN #KeyTranslation kt1 ON drtt.OldMetaSelectedFieldId_DisplayRule = kt1.OldId
	AND kt1.DestinationTable = 'MetaSelectedField'
	LEFT JOIN #KeyTranslation kt2 ON drtt.OldMetaSelectedSectionId_DisplayRule = kt2.OldId
	AND kt2.DestinationTable = 'MetaSelectedSection'
	INNER JOIN #KeyTranslation kt3 ON drtt.OldExpressionId_DisplayRule = kt3.OldId
	AND kt3.DestinationTable = 'Expression'
)
MERGE INTO MetaDisplayRule
		USING SourceData sd ON (1 = 0)
		WHEN Not Matched By Target THEN
		INSERT (DisplayRuleName,DisplayRuleValue,MetaSelectedFieldId,MetaSelectedSectionId,MetaDisplayRuleTypeId,ExpressionId)
		VALUES (sd.DisplayRuleName,sd.DisplayRuleValue,sd.MetaSelectedFieldId,sd.MetaSelectedSectionId,sd.MetaDisplayRuleTypeId,sd.ExpressionId)
		OUTPUT 'MetaDisplayRule', sd.OldDisplayRuleId, INSERTED.Id INTO #KeyTranslation (DestinatioNTable, OldId, NewId);

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
(1124,'5-Year Text Rule',3102,NULL,524)
,
(1125,'Listen Other Evaluation Methods',NULL,1938,525)
,
(1126,'Have all faculty in deparmnet be... | Show Explain',NULL,1951,526)
,
(1128,'General Education/Articulation | C-ID Articulation',NULL,1981,528)
,
(1129,'Show/hide Local GE',NULL,1933,529)
,
(1130,'Show/hide CSU',NULL,1985,530)
,
(1131,'Show/hide IGETC',NULL,1986,531)
,
(1132,'Show/hide UC TCA',NULL,1988,532)
,
(1133,'Listen Old Manual Justification',3200,NULL,533)
,
(1134,'Conditions of Enrollment | Other',3202,NULL,534)
,
(1135,'Conditions of Enrollment | PreRequisite',NULL,1994,535)
,
(1136,'DE',NULL,1950,536)
,
(1137,'Listen Variable Units',NULL,2002,538)
,
(1138,'Listen Variable Units',NULL,2004,539)
,
(1139,'Listen Maximum Units',NULL,2006,540)
,
(1140,'Listen Lab Only Option',NULL,2007,541)
,
(1141,'Listen Repeatable Times',NULL,2009,542)
,
(1142,'Listen Participatory Courses',NULL,2011,543)
,
(1143,'Hide Lecture units/hours',NULL,2014,544)
,
(1147,'NonCredit',NULL,2022,548)
,
(1148,'NonCredit',NULL,2018,549)
,
(1149,'NonCredit',NULL,2017,550)
,
(1150,'NonCredit',NULL,2014,551)
,
(1151,'NonCredit',NULL,2015,552)
,
(1152,'NonCredit',NULL,2016,553)
,
(1153,'DE',NULL,1951,536)
,
(1154,'DE',NULL,1952,536)
,
(1155,'DE',NULL,1953,536)
,
(1156,'DE',NULL,1954,536)
,
(1157,'DE',NULL,1955,536)
,
(1158,'DE',NULL,1956,536)
,
(1159,'DE',NULL,1957,536)
,
(1160,'DE',NULL,1958,536)
,
(1161,'DE',NULL,1959,536)
,
(1162,'DE',NULL,1960,536)
,
(1163,'DE',NULL,1961,536)
,
(1164,'DE',NULL,1962,536)
,
(1165,'DE',NULL,1963,536)
,
(1166,'DE',NULL,1964,536)
,
(1167,'DE',NULL,1965,536)
,
(1168,'DE',NULL,1966,536)
,
(1169,'DE',NULL,1967,536)
,
(1170,'DE',NULL,1968,536)
,
(1171,'DE',NULL,1969,536)
,
(1172,'DE',NULL,1970,536)
,
(1173,'DE',NULL,1971,536)
,
(1174,'DE',NULL,1972,536)
,
(1175,'DE',NULL,1973,536)
,
(1176,'DE',NULL,1976,536)
,
(1177,'DE',NULL,1977,536)
,
(1178,'DE',NULL,1978,536)
,
(1179,'DE',NULL,1979,536)
,
(1180,'Listen Lab Units',NULL,2015,555)
,
(1181,'Articulation',NULL,2024,556)
,
(1182,'Hide 2 checkboxes',NULL,1999,557)
,
(1183,'Hide Lecture units/hours',NULL,2001,544)
,
(1184,'Hide Lecture units/hours',NULL,2002,544)
,
(1185,'NonCredit',NULL,2001,551)
,
(1186,'NonCredit',NULL,2002,551)
,
(1187,'NonCredit',NULL,2003,552)
,
(1188,'NonCredit',NULL,2004,552)
,
(1189,'Listen Lab Units',NULL,2003,555)
,
(1190,'Listen Lab Units',NULL,2004,555)
,
(1191,'NonCredit',NULL,2005,553)
,
(1192,'NonCredit',NULL,2006,553)
,
(1193,'Enroll feest',NULL,2028,558)
,
(1194,'Hide Lecture units/hours',NULL,2029,544)
,
(1195,'NonCredit',NULL,2029,551)
,
(1196,'Hide Lecture units/hours',NULL,2030,544)
,
(1197,'NonCredit',NULL,2030,551)
,
(1198,'Hide Lecture units/hours',NULL,2031,544)
,
(1199,'NonCredit',NULL,2031,551)
,
(1200,'Listen Variable Units',NULL,2031,538)
,
(1201,'Hide Course Content',NULL,2037,559)
,
(1202,'Hide Requisite Content',NULL,2038,562)
,
(1203,'Hide Course Objective',NULL,2039,560)
,
(1204,'Hide Requisite Objectives',NULL,2040,561)
,
(1205,'NonCredit',NULL,2033,563)
,
(1206,'NonCredit',NULL,2034,563)
,
(1207,'Listen Maximum Units',NULL,2034,540)
,
(1208,'Method of Eval - reading assignments',NULL,2044,564)
,
(1209,'Method of Eval - reading assignments',NULL,2046,565)
,
(1210,'Method of Eval - other assignments',NULL,2048,566)
,
(1211,'Listener show requisites',NULL,1993,567)
,
(1212,'Listener Content Review Require',NULL,2036,569)
,
(1213,'StudentPerformanceObjectivesYesNo',NULL,2059,570)
,
(1214,'AssignmentsYesNo',NULL,2061,571)
,
(1215,'AssessmentYesNo',NULL,2063,572)
,
(1216,'ShowSomeAssignmentSample',NULL,2066,573)
,
(1217,'ShowMaxOutsideOfClassHours',NULL,2071,551)
,
(1218,'ShowMaxOutsideOfClassHours',NULL,2072,551)
,
(1219,'ShowMaxOutsideOfClassHours',NULL,2072,538)
,
(1220,'DE',NULL,2052,536)
,
(1221,'DE',NULL,2053,536)
,
(1222,'DE',NULL,2054,536)
,
(1223,'DE',NULL,2055,536)
,
(1224,'DE',NULL,2056,536)
,
(1225,'DE',NULL,2057,536)
,
(1226,'DE',NULL,2058,536)
,
(1227,'DE',NULL,2059,536)
,
(1228,'DE',NULL,2060,536)
,
(1229,'DE',NULL,2061,536)
,
(1230,'DE',NULL,2062,536)
,
(1231,'DE',NULL,2063,536)
,
(1232,'Entity (Data Entry)',NULL,2078,574)
,
(1233,'Entity (Data Entry)',NULL,2080,575)
,
(1234,'Entity (Data Entry)',NULL,2082,576)
,
(1235,'show content review OL',NULL,2036,577)
,
(1236,'Will honors distinction apply to any section of th',NULL,2089,578)
,
(1237,'Listen Maximum Units',NULL,2098,540)
,
(1238,'Listen Maximum Units',NULL,2097,540)
,
(1239,'NonCredit',NULL,2095,553)
,
(1240,'NonCredit',NULL,2096,553)
,
(1241,'NonCredit',NULL,2098,553)
,
(1242,'NonCredit',NULL,2097,553)
,
(1243,'Will honors distinction apply to any section of th',NULL,2053,579)
,
(1246,'Will honors distinction apply to any section of th',NULL,2095,582)
,
(1247,'Will honors distinction apply to any section of th',NULL,2097,582)
,
(1248,'Will honors distinction apply to any section of th',NULL,2029,583)
,
(1249,'Will honors distinction apply to any section of th',NULL,2030,583)
,
(1250,'Will honors distinction apply to any section of th',NULL,2031,583)
,
(1251,'Will honors distinction apply to any section of th',NULL,2094,584)
,
(1252,'Will honors distinction apply to any section of th',NULL,1996,585)
,
(1253,'Will honors distinction apply to any section of th',NULL,2091,586)
,
(1389,'hide concurrent checkbox',3735,NULL,654)
,
(1392,'hide notes on requisites',NULL,2296,657)
,
(1406,'Hide Fully Online (100% Online)',NULL,1973,667)
,
(1408,'Hide if Fully Online',3288,NULL,669)
,
(1410,'Show/hide IDEA TAB',NULL,2355,671)
,
(1411,'Show/hide IDEA TAB',NULL,2357,672)
,
(1412,'Show/hide IDEA TAB',NULL,2359,673)
,
(1413,'Show/hide IDEA TAB',NULL,2361,674)
,
(1414,'Show/hide IDEA TAB',NULL,2363,675)
,
(1415,'Show/hide IDEA TAB',NULL,2365,676)
,
(1416,'Show/hide IDEA TAB',NULL,2367,677)
,
(1417,'Show/hide IDEA TAB',NULL,2369,678)
,
(1418,'Show/hide IDEA TAB',NULL,2371,679)
,
(1419,'Show/hide IDEA TAB',NULL,2373,680)
,
(1420,'Show/hide IDEA TAB',NULL,2375,681)
,
(1421,'Show/hide IDEA TAB',NULL,2377,682)
,
(1422,'Show/hide IDEA TAB',NULL,2379,683)
,
(1423,'Show/hide IDEA TAB',NULL,2381,684)
,
(1424,'Show/hide IDEA TAB',NULL,2383,685)
,
(1425,'Show/hide IDEA TAB',NULL,2387,686)
,
(1426,'Show/hide IDEA TAB',NULL,2389,687)
,
(1427,'Show/hide IDEA TAB',NULL,2391,688)
,
(1428,'Show/hide IDEA TAB',NULL,2393,689)
,
(1429,'Show/hide IDEA TAB',NULL,2395,690)
,
(1430,'Show/hide IDEA TAB',NULL,2397,691)
,
(1431,'Show/hide IDEA TAB',NULL,2399,692)
,
(1432,'Show/hide IDEA TAB',NULL,2401,693)
;

-- MERGE INTO MetaDisplaySubscriber
;WITH SourceData AS
(
	SELECT OldId_DisplaySubscriber,SubscriberName,kt1.NewId AS MetaSelectedFieldId,kt2.NewId AS MetaSelectedSectionId,kt3.NewId AS MetaDisplayRuleId
	FROM @DisplaySubscriberTempTable dstt
	LEFT JOIN #KeyTranslation kt1 ON dstt.OldMetaSelectedFieldId_DisplaySubscriber = kt1.OldId
		AND kt1.DestinationTable = 'MetaSelectedField'
	LEFT JOIN #KeyTranslation kt2 ON dstt.OldMetaSelectedSectionId_DisplaySubscriber = kt2.OldId
		AND kt2.DestinationTable = 'MetaSelectedSection'
	INNER JOIN #KeyTranslation kt3 ON dstt.OldMetaDisplayRuleId_DisplaySubscriber = kt3.OldId
		AND kt3.DestinationTable = 'MetaDisplayRule'
)
MERGE INTO MetaDisplaySubscriber
		USING SourceData sd ON (1 = 0)
		WHEN Not Matched By Target THEN
		INSERT (SubscriberName,MetaSelectedFieldId,MetaSelectedSectionId,MetaDisplayRuleId)
		VALUES (sd.SubscriberName,sd.MetaSelectedFieldId,sd.MetaSelectedSectionId,sd.MetaDisplayRuleId)
		OUTPUT 'MetaDisplaySubscriber', sd.OldId_DisplaySubscriber, INSERTED.Id INTO #KeyTranslation (DestinatioNTable, OldId, NewId);

--=========================End MetaDisplaySubscriber==============================


--===========================End Show/Hide Tables=================================


--============================Begin ListItemType==================================


--=============================End ListItemType===================================


--==========================Begin MetaFieldFormula================================


--===========================End MetaFieldFormula=================================


--=====================Begin MetaFieldFormulaDepENDency===========================


--======================End MetaFieldFormulaDepENDency============================


--================Begin MetaSelectedSectionPositionPermission=====================


--=================End MetaSelectedSectionPositionPermission======================


--==================Begin MetaSelectedFieldPositionPermission=====================


--===================End MetaSelectedFieldPositionPermission======================


--===================Begin MetaSelectedSectionRolePermission======================


--====================End MetaSelectedSectionRolePermission=======================


--===========================Begin MetASqlStatement===========================


--============================End MetASqlStatement============================


--============================Begin MetaControlAttribute==========================


--============================End MetaControlAttribute============================


--====================Begin MetaSelectedFieldRolePermission=======================


--=====================End MetaSelectedFieldRolePermission========================


SELECT newid AS MetaTemplateId
FROM #KeyTranslation
WHERE DestinationTable='MetaTemplate'

UPDATE MetaTemplate
SET LastUpdatedDate=GETDATE( )
OUTPUT INSERTED.*
WHERE MetaTemplateId=@MetaTemplateId

--SELECT * FROM #KeyTranslation
DROP TABLE IF EXISTS #KeyTranslation
SELECT 'Script complete' AS Message

--Rollback

Commit