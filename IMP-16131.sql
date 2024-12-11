
	/************************************************************************************************
	***                               Insertion of Extracted Script                          
	***                                                                                       
	***                                                                                       
	*** Created with the Template Configuration Extract Script and SQL Generator (version 2022.12.14)        
	***                                                                                       
	*** Script generated on Nov 21 2023 10:54AM                                              
	***                                                                                       
	*** Source Client: California Indian Nations College                                                                 
	*** Source Template: 1                                                              
	*** Source Template Name: New Course V1.0             
	*** Initial table: MetaSelectedSection       
	*** Initial id: 4 
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
	

Use cinc;

DECLARE @JiraTicketNumber NVARCHAR(20) = 'a';
DECLARE @Comments NVARCHAR(MAX) = 'a';
DECLARE @Developer NVARCHAR(50) = 'a';
DECLARE @ScriptTypeId int = 2; /* Default on this script is 2 = Enhancement
To See all Options run the following Query

SELECT * FROM history.ScriptType
*/
DECLARE @ClientCode nvarchar(50) = NULL ;
DECLARE @InitialTableName NVARCHAR(100);
SET @InitialTableName = 'MetaSelectedSection';
DECLARE @InitialId int = 4;
DECLARE @ClientId Int = 1;
DECLARE @OverrideClientId Int = Coalesce((Select Id from Client where Code =  @ClientCode ),(Select top 1 Id from Client where Active = 1));
DECLARE @SourceDatabase NVARCHAR(100) = 'cinc';
DECLARE @SourceTemplateTypeId Int = 1;
DECLARE @SourceTemplateId int  = 1;
DECLARE @InsertToMetaTemplateId int ; --Set this if inserting sections into a different template Id from the extrated template
DECLARE @InsertToMetaTemplateTypeId int ; --Set this if inserting sections into a different template type Id from the extrated template
DECLARE @SourceParentSectionId int ; --Do not set this variable
DECLARE @TargetParentSectionId int ; --Do not set this here set it below if necessary
DECLARE @ClientEntityType NVARCHAR(100) = 'Course';

If @InitialId is not NULL and (Select MetaSelectedSection_MetaSelectedSectionId from MetaSelectedSection where MetaSelectedSectionId = @InitialId) Is Not NULL
BEGIN
	 Set @TargetParentSectionId = (Select MetaSelectedSection_MetaSelectedSectionId from MetaSelectedSection where MetaSelectedSectionId = 4); --Change this if inserting sections into a different Parent Section

	SET @SourceParentSectionId=(SELECT MetaSelectedSection_MetaSelectedSectionId
		  FROM MetaSelectedSection
		  WHERE MetaSelectedSectionId=4); --Do not change this setting
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
	
(4,1,NULL,'Units and Hours2',1,NULL,0,NULL,4,0,1,15,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(25,1,4,NULL,1,NULL,0,NULL,0,0,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(26,1,4,'Instructional Categories (check all that apply):',1,NULL,0,NULL,1,1,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(27,1,4,'Lecture',0,NULL,0,NULL,2,2,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(28,1,4,NULL,0,NULL,0,NULL,8,8,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(29,1,4,NULL,0,NULL,0,NULL,13,13,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(30,1,4,'Lab',0,NULL,0,NULL,16,16,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(31,1,4,'Weekly Hours of Instruction',1,NULL,0,NULL,25,25,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(32,1,4,'Totals',1,NULL,1,NULL,27,27,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(105,1,4,NULL,1,NULL,0,NULL,4,4,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(106,1,4,NULL,1,NULL,0,NULL,9,9,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(107,1,4,'',1,NULL,0,NULL,11,11,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(108,1,4,NULL,1,NULL,0,NULL,14,14,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(109,1,4,NULL,1,NULL,0,NULL,28,28,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(110,1,4,'Min Totals Credit',0,NULL,0,NULL,29,29,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(111,1,4,NULL,1,NULL,0,NULL,3,3,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(112,1,4,NULL,1,NULL,0,NULL,10,10,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(113,1,4,NULL,1,NULL,0,NULL,15,15,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(117,1,4,NULL,1,NULL,0,NULL,20,20,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(118,1,4,'',1,NULL,0,NULL,23,23,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(124,1,4,NULL,0,NULL,0,NULL,21,21,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(125,1,4,NULL,0,NULL,0,NULL,22,22,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(199,1,4,'Max Totals Credit',0,NULL,0,NULL,30,30,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(200,1,4,'Totals',1,NULL,0,NULL,31,31,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(201,1,4,'Max Totals Noncredit',0,NULL,0,NULL,32,32,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(202,1,4,'',1,NULL,0,NULL,5,5,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1200,1,4,NULL,1,NULL,0,NULL,12,12,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1201,1,4,NULL,1,NULL,0,NULL,17,17,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1202,1,4,NULL,1,NULL,0,NULL,24,24,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1203,1,4,NULL,1,NULL,0,NULL,26,26,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1204,1,4,'Min Lecture Non Credit',0,NULL,0,NULL,6,6,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1205,1,4,'Max Lecture Non Credit',0,NULL,0,NULL,7,7,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1206,1,4,'Min Lab Non-credit',0,NULL,0,NULL,18,18,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1207,1,4,'Max Lab Non-credit',0,NULL,0,NULL,19,19,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1279,1,1207,NULL,1,NULL,0,NULL,33,33,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1278,1,1205,NULL,1,NULL,0,NULL,33,33,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1286,1,1202,NULL,1,NULL,0,NULL,39,39,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1284,1,1201,NULL,1,NULL,0,NULL,37,37,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1283,1,1200,NULL,1,NULL,0,NULL,36,36,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1281,1,202,NULL,1,NULL,0,NULL,34,34,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1285,1,125,NULL,1,NULL,0,NULL,38,38,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1287,1,113,NULL,1,NULL,0,NULL,33,33,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1282,1,112,NULL,1,NULL,0,NULL,35,35,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1280,1,111,NULL,1,NULL,0,NULL,33,33,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(198,1,32,NULL,1,NULL,0,NULL,22,22,1,1,1,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
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
(2,1,1,'LabelWidth','275',27)
,
(3,1,1,'LabelWidth','275',30)
,
(110,1,1,'LabelWidth','275',105)
,
(111,1,1,'LabelWidth','275',106)
,
(112,1,1,'LabelWidth','275',107)
,
(113,1,1,'LabelWidth','275',108)
,
(114,1,1,'LabelWidth','275',109)
,
(115,1,1,'LabelWidth','275',110)
,
(116,1,1,'LabelWidth','275',111)
,
(117,1,1,'LabelWidth','275',112)
,
(118,1,1,'LabelWidth','275',113)
,
(123,1,1,'LabelWidth','275',118)
,
(124,1,1,'LabelWidth','275',124)
,
(125,1,1,'LabelWidth','275',125)
,
(263,1,1,'LabelWidth','275',199)
,
(271,1,1,'LabelWidth','275',200)
,
(272,1,1,'LabelWidth','275',201)
,
(264,1,1,'LabelWidth','275',202)
,
(265,1,1,'LabelWidth','275',1201)
,
(266,1,1,'LabelWidth','275',1202)
,
(267,1,1,'LabelWidth','275',1204)
,
(268,1,1,'LabelWidth','275',1205)
,
(269,1,1,'LabelWidth','275',1206)
,
(270,1,1,'LabelWidth','275',1207)
,
(4,1,1,'LabelWidth','275',198)
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

	

--==================Begin Meta SELECTed Section SETting=========================

	
--There are no applicable MetaSelectedSectionSetting records.

--====================End Meta Selected Section SETting=========================

	


--=======================Begin Meta Selected Field==============================

		
-- Get MetaSelectedField
DECLARE  @MetaSelectedFieldTempTable Table
(MetaSelectedField_MetaSelectedFieldId NVARCHAR(MAX),MetaSelectedField_DisplayName NVARCHAR(MAX),MetaSelectedField_MetaAvailableFieldId NVARCHAR(MAX),MetaSelectedField_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedField_IsRequired NVARCHAR(MAX),MetaSelectedField_MinCharacters NVARCHAR(MAX),MetaSelectedField_MaxCharacters NVARCHAR(MAX),MetaSelectedField_RowPosition NVARCHAR(MAX),MetaSelectedField_ColPosition NVARCHAR(MAX),MetaSelectedField_ColSpan NVARCHAR(MAX),MetaSelectedField_DefaultDisplayType NVARCHAR(MAX),MetaSelectedField_MetaPresentationTypeId NVARCHAR(MAX),MetaSelectedField_Width NVARCHAR(MAX),MetaSelectedField_WidthUnit NVARCHAR(MAX),MetaSelectedField_Height NVARCHAR(MAX),MetaSelectedField_HeightUnit NVARCHAR(MAX),MetaSelectedField_AllowLabelWrap NVARCHAR(MAX),MetaSelectedField_LabelHAlign NVARCHAR(MAX),MetaSelectedField_LabelVAlign NVARCHAR(MAX),MetaSelectedField_LabelStyleId NVARCHAR(MAX),MetaSelectedField_LabelVisible NVARCHAR(MAX),MetaSelectedField_FieldStyle NVARCHAR(MAX),MetaSelectedField_EditDisplayOnly NVARCHAR(MAX),MetaSelectedField_GroupName NVARCHAR(MAX),MetaSelectedField_GroupNameDisplay NVARCHAR(MAX),MetaSelectedField_FieldTypeId NVARCHAR(MAX),MetaSelectedField_ValidationRuleId NVARCHAR(MAX),MetaSelectedField_LiteralValue NVARCHAR(MAX),MetaSelectedField_ReadOnly NVARCHAR(MAX),MetaSelectedField_AllowCopy NVARCHAR(MAX),MetaSelectedField_Precision NVARCHAR(MAX),MetaSelectedField_MetaForeignKeyLookupSourceId NVARCHAR(MAX),MetaSelectedField_MetadataAttributeMapId NVARCHAR(MAX),MetaSelectedField_EditMapId NVARCHAR(MAX),MetaSelectedField_NumericDataLength NVARCHAR(MAX),MetaSelectedField_Config NVARCHAR(MAX));

INSERT INTO @MetaSelectedFieldTempTable

(MetaSelectedField_MetaSelectedFieldId,MetaSelectedField_DisplayName,MetaSelectedField_MetaAvailableFieldId,MetaSelectedField_MetaSelectedSectionId,MetaSelectedField_IsRequired,MetaSelectedField_MinCharacters,MetaSelectedField_MaxCharacters,MetaSelectedField_RowPosition,MetaSelectedField_ColPosition,MetaSelectedField_ColSpan,MetaSelectedField_DefaultDisplayType,MetaSelectedField_MetaPresentationTypeId,MetaSelectedField_Width,MetaSelectedField_WidthUnit,MetaSelectedField_Height,MetaSelectedField_HeightUnit,MetaSelectedField_AllowLabelWrap,MetaSelectedField_LabelHAlign,MetaSelectedField_LabelVAlign,MetaSelectedField_LabelStyleId,MetaSelectedField_LabelVisible,MetaSelectedField_FieldStyle,MetaSelectedField_EditDisplayOnly,MetaSelectedField_GroupName,MetaSelectedField_GroupNameDisplay,MetaSelectedField_FieldTypeId,MetaSelectedField_ValidationRuleId,MetaSelectedField_LiteralValue,MetaSelectedField_ReadOnly,MetaSelectedField_AllowCopy,MetaSelectedField_Precision,MetaSelectedField_MetaForeignKeyLookupSourceId,MetaSelectedField_MetadataAttributeMapId,MetaSelectedField_EditMapId,MetaSelectedField_NumericDataLength,MetaSelectedField_Config)
OUTPUT INSERTED.*
 VALUES
(11,'Course Type',1002,25,1,NULL,NULL,0,0,1,'TelerikCombo',33,225,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12,'Lecture',2041,26,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,0,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(13,'Min Lecture Contact Hours',184,105,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,2,NULL,NULL,NULL,6,NULL)
,
(14,'Max Lecture Contact Hours',175,1281,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,2,NULL,NULL,NULL,6,NULL)
,
(15,'Independent Study',1863,28,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,0,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(16,'Min Independent Study Out of Class Hours',179,107,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,2,NULL,NULL,NULL,6,NULL)
,
(17,'Max Independent Study Out of Class Hours',170,1283,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,2,NULL,NULL,NULL,6,NULL)
,
(18,'Lab/Field',2523,29,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,0,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(19,'Min Lab/Field Contact Hours',182,30,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,2,NULL,NULL,NULL,6,NULL)
,
(20,'Max Lab/Field Contact Hours',173,1284,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,2,NULL,NULL,NULL,6,NULL)
,
(21,'Min regularly Scheduled Weekly Hours of Instruction',202,31,1,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,6,NULL)
,
(22,'Max regularly Scheduled Weekly Hours of Instruction',203,1203,1,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,6,NULL)
,
(23,'Min Total Out of Class Hours',189,110,0,NULL,NULL,1,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,2,NULL,NULL,NULL,6,NULL)
,
(24,'Max Total Out of Class Hours',166,199,0,NULL,NULL,1,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,2,NULL,NULL,NULL,6,NULL)
,
(25,'Min Totals Units',180,198,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,2,NULL,NULL,NULL,6,NULL)
,
(26,'Max Totals Units',171,109,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,2,NULL,NULL,NULL,6,NULL)
,
(188,'Min Lecture Units',3159,27,1,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(189,'Max Lecture Out of Class Hours',3165,1281,0,NULL,NULL,1,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(190,'Min Lecture Out of Class Hours',3166,105,0,NULL,NULL,1,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(191,'Min Independent Study Units',3160,106,1,NULL,NULL,0,0,1,'Textbox',1,64,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(192,'Min Lab/Field Units',3161,108,1,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(193,'Min Total Contact Hours',2487,110,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(194,'Max Total Contact Hours',2488,199,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(195,'Max Total Hours',176,199,0,NULL,NULL,2,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(196,'Min Total Hours',186,110,0,NULL,NULL,2,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(197,'Max Lecture Units',3162,1280,1,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(198,'Max Independent Study Units',3163,1282,1,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(199,'Max Lab/Field Units',3164,1287,1,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(204,'<div style="color:#000000">Outside-of-class hours are determined by the following standard ratio. If you override the calculation, you must provide an explanation below. Keep in mind that deviation from this ratio can affect articulation agreements with other institutions.</div><br><table style="width: 100%; border: 1px solid black; border-collapse:collapse" border="1"><tr><th style="background-color: #F5A201; color: #FFFFFF">Instructional Category</th><th style="background-color: #F5A201; color: #FFFFFF">In-Class Hours</th><th style="background-color: #F5A201; color: #FFFFFF">Outside-of-Class Hours</th></tr><tr><td style="text-align:center; color:#000000"><strong>Lecture</strong> (lecture, discussion, seminar, and related work)</td><td style="text-align:center; color:#000000"><strong>1</strong></td><td style="text-align:center; color:#000000"><strong>2</strong></td></tr><tr><td style="text-align:center; color:#000000"><strong>Activity</strong> (activity, lab w/homework, studio, and similar)</td><td style="text-align:center; color:#000000"><strong>2</strong></td><td style="text-align:center; color:#000000"><strong>1</strong></td></tr><tr><td style="text-align:center; color:#000000"><strong>Laboratory/Field</strong> (traditional lab, natural science lab, clinical, and similar)</td><td style="text-align:center; color:#000000"><strong>1</strong></td><td style="text-align:center; color:#000000"><strong>0</strong></td></tr></table>',NULL,25,0,NULL,NULL,1,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(205,'This course has variable hours',3423,25,0,NULL,NULL,2,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(211,'Activity',1856,117,0,NULL,NULL,0,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(212,'Min Activity Contact Hours',178,118,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(213,'Max Activity Contact Hours',169,1286,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(214,'Min Activity Out of Class Hours',181,118,0,NULL,NULL,1,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(215,'Max Activity Out of Class Hours',177,1286,0,NULL,NULL,1,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(225,'Min Activity Units',206,124,1,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(226,'Max Activity Units',207,1285,1,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(372,'Min Student Learning Total Hours',1873,200,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(373,'Min Total Out of Class Hours',1874,200,0,NULL,NULL,1,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(374,'Max Student Learning Total Hours',1868,201,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(375,'Max Total Out of Class Hours',1870,201,0,NULL,NULL,1,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1372,'Min Lecture Contact Hours',2485,1204,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(1373,'Max Lecture Contact Hours',2486,1278,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(1374,'Min Lab Contact Hours',183,1206,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
,
(1375,'Max Lab Contact Hours',174,1279,0,NULL,NULL,0,0,1,'Textbox',1,65,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,2,NULL,NULL,NULL,NULL,NULL)
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

		
-- Get MetaSelectedFieldAttribute
DECLARE  @MetaSelectedFieldAttributeTempTable Table
(MetaSelectedFieldAttribute_Id NVARCHAR(MAX),MetaSelectedFieldAttribute_Name NVARCHAR(MAX),MetaSelectedFieldAttribute_Value NVARCHAR(MAX),MetaSelectedFieldAttribute_MetaSelectedFieldId NVARCHAR(MAX));

INSERT INTO @MetaSelectedFieldAttributeTempTable
(MetaSelectedFieldAttribute_Id,MetaSelectedFieldAttribute_Name,MetaSelectedFieldAttribute_Value,MetaSelectedFieldAttribute_MetaSelectedFieldId)
OUTPUT INSERTED.*
VALUES
(1,'LabelWidth','500',13)
;

-- INSERT MetaSelectedFieldAttribute INTO Destination Database

;WITH SourceData AS
( 
SELECT MetaSelectedFieldAttribute_Id,MetaSelectedFieldAttribute_Name,MetaSelectedFieldAttribute_Value,kt.NewId AS MetaSelectedFieldAttribute_MetaSelectedFieldId
FROM @MetaSelectedFieldAttributeTempTable tt 
INNER JOIN #KeyTranslation kt ON kt.OldId = MetaSelectedFieldAttribute_MetaSelectedFieldId
	AND DestinationTable = 'MetaSelectedField'
)
MERGE INTO MetaSelectedFieldAttribute
USING SourceData sd ON (1 = 0)
WHEN Not Matched By Target THEN
INSERT (Name,Value,MetaSelectedFieldId)
VALUES (sd.MetaSelectedFieldAttribute_Name,sd.MetaSelectedFieldAttribute_Value,sd.MetaSelectedFieldAttribute_MetaSelectedFieldId)
OUTPUT 'MetaSelectedFieldAttribute',sd.MetaSelectedFieldAttribute_Id, INSERTED.MetaSelectedFieldId INTO #KeyTranslation (DestinationTable, OldId, NewId);

--UPDATE MetaSelectedField attributes to convert the Value which is a MetaAailableFieldId to the NewId
;WITH SourceData AS 
	(
	SELECT fatt.MetaSelectedFieldAttribute_Name 
	,fatt.MetaSelectedFieldAttribute_Value AS OldFAValue
	,CAST(kt2.NewId AS NVARCHAR) AS NewFAValue
	,kt.NewId AS NewMetaSelectedFieldId
	FROM @MetaSelectedFieldAttributeTempTable fatt
	INNER JOIN #KeyTranslation kt
		ON fatt.MetaSelectedFieldAttribute_MetaSelectedFieldId = kt.OldId
			AND kt.DestinationTable = 'MetaSelectedField'
	INNER JOIN #KeyTranslation kt2
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
(10)
,
(11)
,
(47)
,
(1086)
,
(1090)
,
(1119)
,
(1120)
,
(1121)
,
(1122)
,
(1123)
,
(1124)
,
(1125)
,
(1126)
,
(1127)
,
(1128)
,
(1129)
,
(1130)
,
(1131)
,
(1132)
,
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
,
(1148)
,
(1149)
,
(1150)
,
(1151)
,
(1152)
,
(1153)
,
(1161)
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
(21,10,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(22,10,21,1,3,4,12,NULL,'false',NULL,NULL)
,
(23,11,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(24,11,23,1,3,4,211,NULL,'false',NULL,NULL)
,
(25,11,23,1,3,4,49,NULL,'false',NULL,NULL)
,
(97,47,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(98,47,97,1,16,3,15,NULL,'1',NULL,NULL)
,
(1189,1086,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1190,1086,1189,1,16,3,12,NULL,'1',NULL,NULL)
,
(1197,1090,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1198,1090,1197,1,16,3,205,NULL,'1',NULL,NULL)
,
(1255,1119,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1256,1119,1255,1,16,3,18,NULL,'1',NULL,NULL)
,
(1257,1120,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1258,1120,1257,1,16,3,18,NULL,'1',NULL,NULL)
,
(1259,1121,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1260,1121,1259,1,16,3,18,NULL,'1',NULL,NULL)
,
(1261,1122,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1262,1122,1261,1,16,3,205,NULL,'1',NULL,NULL)
,
(1263,1123,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1264,1123,1263,1,16,3,205,NULL,'1',NULL,NULL)
,
(1265,1124,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1266,1124,1265,1,16,3,205,NULL,'1',NULL,NULL)
,
(1267,1125,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1268,1125,1267,1,16,3,205,NULL,'1',NULL,NULL)
,
(1269,1126,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1270,1126,1269,1,16,3,205,NULL,'1',NULL,NULL)
,
(1271,1127,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1272,1127,1271,1,16,3,205,NULL,'1',NULL,NULL)
,
(1273,1128,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1274,1128,1273,1,16,3,205,NULL,'1',NULL,NULL)
,
(1275,1129,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1276,1129,1275,1,16,3,205,NULL,'1',NULL,NULL)
,
(1277,1130,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1278,1130,1277,1,16,3,205,NULL,'1',NULL,NULL)
,
(1279,1131,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1280,1131,1279,1,16,3,205,NULL,'1',NULL,NULL)
,
(1281,1132,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1282,1132,1281,1,16,3,205,NULL,'1',NULL,NULL)
,
(1283,1133,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1284,1133,1283,1,16,3,205,NULL,'1',NULL,NULL)
,
(1285,1134,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1286,1134,1285,1,16,3,205,NULL,'1',NULL,NULL)
,
(1287,1135,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1288,1135,1287,1,16,3,205,NULL,'1',NULL,NULL)
,
(1289,1136,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1290,1136,1289,1,16,3,12,NULL,'1',NULL,NULL)
,
(1291,1137,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1292,1137,1291,1,16,3,12,NULL,'1',NULL,NULL)
,
(1293,1138,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1294,1138,1293,1,16,3,12,NULL,'1',NULL,NULL)
,
(1295,1139,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1296,1139,1295,1,16,3,15,NULL,'1',NULL,NULL)
,
(1297,1140,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1298,1140,1297,1,16,3,15,NULL,'1',NULL,NULL)
,
(1299,1141,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1300,1141,1299,1,16,3,15,NULL,'1',NULL,NULL)
,
(1301,1142,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1302,1142,1301,1,16,3,211,NULL,'1',NULL,NULL)
,
(1303,1143,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1304,1143,1303,1,16,3,211,NULL,'1',NULL,NULL)
,
(1305,1144,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1306,1144,1305,1,16,3,12,NULL,'1',NULL,NULL)
,
(1307,1145,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1308,1145,1307,1,16,3,12,NULL,'1',NULL,NULL)
,
(1309,1146,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1310,1146,1309,1,16,3,15,NULL,'1',NULL,NULL)
,
(1311,1147,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1312,1147,1311,1,16,3,18,NULL,'1',NULL,NULL)
,
(1313,1148,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1314,1148,1313,1,16,3,18,NULL,'1',NULL,NULL)
,
(1315,1149,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1316,1149,1315,1,16,3,211,NULL,'1',NULL,NULL)
,
(1317,1150,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1318,1150,1317,1,16,3,211,NULL,'1',NULL,NULL)
,
(1319,1151,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1320,1151,1319,1,16,3,15,NULL,'1',NULL,NULL)
,
(1321,1152,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1322,1152,1321,1,16,3,18,NULL,'1',NULL,NULL)
,
(1323,1153,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1324,1153,1323,1,16,3,211,NULL,'1',NULL,NULL)
,
(1339,1161,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1340,1161,1339,1,16,3,205,NULL,'1',NULL,NULL)
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
(2,'ShowNonCreditHours',NULL,368,NULL,2,2)
,
(6,'CourseHasFees',NULL,31,NULL,2,6)
,
(7,'CourseIsRepeatable',NULL,37,NULL,2,7)
,
(9,'IsCTECourse',NULL,46,NULL,2,9)
,
(10,'LectureContentLectureHours',NULL,12,NULL,2,10)
,
(11,'HasActivityHours',NULL,211,NULL,2,11)
,
(12,'IsStandaloneCourse',NULL,6,NULL,2,12)
,
(13,'PrerequisiteOrCorequisite',NULL,58,NULL,2,13)
,
(14,'AdvisoryRequisiteContent',NULL,58,NULL,2,14)
,
(15,'LimitationsOfEnrollment',NULL,58,NULL,2,15)
,
(17,'IsReadingAssignment',NULL,93,NULL,2,17)
,
(18,'IsWritingAssignment',NULL,95,NULL,2,18)
,
(19,'IsOtherAssignment',NULL,97,NULL,2,19)
,
(20,'IsOnlineDelivery',NULL,101,NULL,2,20)
,
(21,'IsHybridDelivery',NULL,110,NULL,2,21)
,
(22,'IsLocalGE',NULL,111,NULL,2,22)
,
(23,'IsCSU',NULL,114,NULL,2,23)
,
(24,'IsIGETC',NULL,116,NULL,2,24)
,
(25,'IsCID',NULL,118,NULL,2,25)
,
(26,'IsUCTCA',NULL,120,NULL,2,26)
,
(27,'SubmitForArticulation',NULL,122,NULL,2,27)
,
(28,'Other',NULL,70,NULL,2,28)
,
(29,'Other',NULL,70,NULL,2,29)
,
(31,'ishybrid',NULL,182,NULL,2,31)
,
(33,'DE',NULL,206,NULL,2,33)
,
(35,'other DE Delivery Methods',NULL,217,NULL,2,35)
,
(36,'requisite validation',NULL,64,NULL,2,36)
,
(37,'requisite validation',NULL,64,NULL,2,37)
,
(38,'requisite validation',NULL,64,NULL,2,38)
,
(40,'hide contact hour checkboxes when noncredit',NULL,368,NULL,2,40)
,
(42,'Hide if Entrance Skill Type is not Requisite Skill',NULL,230,NULL,2,42)
,
(43,'Hide if Entrance Skill Type is not Recommended Skill',NULL,230,NULL,2,43)
,
(44,'Hide if not "Entrance Skill to Entrance Skill"',NULL,64,NULL,2,44)
,
(45,'Hide sections Current Course Objectives, Requisite Course Objective(s).',NULL,64,NULL,2,45)
,
(46,'Hide sections Current Entrance Skills, Requisite Entrance Skills.',NULL,64,NULL,2,46)
,
(47,'Hide if "This Course has Independent Study Hours" is not yes',NULL,15,NULL,2,47)
,
(65,'Show/hide',NULL,64,NULL,2,66)
,
(66,'Show/hide',NULL,58,NULL,2,67)
,
(1068,'Show/hide',NULL,58,NULL,2,1070)
,
(1069,'Show/hide',NULL,58,NULL,2,1071)
,
(1070,'Show/hide',NULL,1402,NULL,2,1072)
,
(1071,'Show/hide',NULL,1382,NULL,2,1073)
,
(1072,'Show/hide',NULL,30,NULL,2,1074)
,
(1073,'Show/hide',NULL,64,NULL,2,1075)
,
(1084,'Show/hide',NULL,12,NULL,2,1086)
,
(1086,'Show/hide',NULL,368,NULL,2,1088)
,
(1087,'Show/hide',NULL,368,NULL,2,1089)
,
(1088,'Show/hide',NULL,205,NULL,2,1090)
,
(1089,'Show/hide',NULL,368,NULL,2,1091)
,
(1090,'Show/hide',NULL,368,NULL,2,1092)
,
(1091,'Show/hide',NULL,368,NULL,2,1093)
,
(1092,'Show/hide',NULL,368,NULL,2,1094)
,
(1093,'Show/hide',NULL,368,NULL,2,1095)
,
(1094,'Show/hide',NULL,368,NULL,2,1096)
,
(1095,'Show/hide',NULL,368,NULL,2,1097)
,
(1096,'Show/hide',NULL,368,NULL,2,1098)
,
(1097,'Show/hide',NULL,368,NULL,2,1099)
,
(1098,'Show/hide',NULL,368,NULL,2,1100)
,
(1099,'Show/hide',NULL,368,NULL,2,1101)
,
(1100,'Show/hide',NULL,368,NULL,2,1102)
,
(1101,'Show/hide',NULL,368,NULL,2,1103)
,
(1102,'Show/hide',NULL,368,NULL,2,1104)
,
(1103,'Show/hide',NULL,368,NULL,2,1105)
,
(1104,'Show/hide',NULL,368,NULL,2,1106)
,
(1105,'Show/hide',NULL,368,NULL,2,1107)
,
(1106,'Show/hide',NULL,368,NULL,2,1108)
,
(1107,'Show/hide',NULL,368,NULL,2,1109)
,
(1108,'Show/hide',NULL,368,NULL,2,1110)
,
(1109,'Show/hide',NULL,368,NULL,2,1111)
,
(1110,'Show/hide',NULL,368,NULL,2,1112)
,
(1111,'Show/hide',NULL,368,NULL,2,1113)
,
(1112,'Show/hide',NULL,368,NULL,2,1114)
,
(1113,'Show/hide',NULL,368,NULL,2,1115)
,
(1114,'Show/hide',NULL,368,NULL,2,1116)
,
(1115,'Show/hide',NULL,368,NULL,2,1117)
,
(1116,'Show/hide',NULL,368,NULL,2,1118)
,
(1117,'Show/hide',NULL,18,NULL,2,1119)
,
(1118,'Show/hide',NULL,18,NULL,2,1120)
,
(1119,'Show/hide',NULL,18,NULL,2,1121)
,
(1120,'Show/hide',NULL,205,NULL,2,1122)
,
(1121,'Show/hide',NULL,205,NULL,2,1123)
,
(1122,'Show/hide',NULL,205,NULL,2,1124)
,
(1123,'Show/hide',NULL,205,NULL,2,1125)
,
(1124,'Show/hide',NULL,205,NULL,2,1126)
,
(1125,'Show/hide',NULL,205,NULL,2,1127)
,
(1126,'Show/hide',NULL,205,NULL,2,1128)
,
(1127,'Show/hide',NULL,205,NULL,2,1129)
,
(1128,'Show/hide',NULL,205,NULL,2,1130)
,
(1129,'Show/hide',NULL,205,NULL,2,1131)
,
(1130,'Show/hide',NULL,205,NULL,2,1132)
,
(1131,'Show/hide',NULL,205,NULL,2,1133)
,
(1132,'Show/hide',NULL,205,NULL,2,1134)
,
(1133,'Show/hide',NULL,205,NULL,2,1135)
,
(1134,'Show/hide',NULL,12,NULL,2,1136)
,
(1135,'Show/hide',NULL,12,NULL,2,1137)
,
(1136,'Show/hide',NULL,12,NULL,2,1138)
,
(1137,'Show/hide',NULL,15,NULL,2,1139)
,
(1138,'Show/hide',NULL,15,NULL,2,1140)
,
(1139,'Show/hide',NULL,15,NULL,2,1141)
,
(1140,'Show/hide',NULL,211,NULL,2,1142)
,
(1141,'Show/hide',NULL,211,NULL,2,1143)
,
(1142,'Show/hide',NULL,12,NULL,2,1144)
,
(1143,'Show/hide',NULL,12,NULL,2,1145)
,
(1144,'Show/hide',NULL,15,NULL,2,1146)
,
(1145,'Show/hide',NULL,18,NULL,2,1147)
,
(1146,'Show/hide',NULL,18,NULL,2,1148)
,
(1147,'Show/hide',NULL,211,NULL,2,1149)
,
(1148,'Show/hide',NULL,211,NULL,2,1150)
,
(1149,'Show/hide',NULL,15,NULL,2,1151)
,
(1150,'Show/hide',NULL,18,NULL,2,1152)
,
(1151,'Show/hide',NULL,211,NULL,2,1153)
,
(1152,'Show/hide',NULL,368,NULL,2,1154)
,
(1153,'Show/hide',NULL,368,NULL,2,1155)
,
(1154,'Show/hide',NULL,368,NULL,2,1156)
,
(1155,'Show/hide',NULL,368,NULL,2,1157)
,
(1156,'Show/hide',NULL,368,NULL,2,1158)
,
(1157,'Show/hide',NULL,368,NULL,2,1159)
,
(1158,'Show/hide',NULL,368,NULL,2,1160)
,
(1159,'Show/hide',NULL,205,NULL,2,1161)
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
(1,'Hide if Entrance Skill Type is not Requisite Skill',231,NULL,42)
,
(2,'Hide if Entrance Skill Type is not Recommended Skill',232,NULL,43)
,
(6,NULL,NULL,33,2)
,
(7,NULL,NULL,34,2)
,
(8,NULL,NULL,35,2)
,
(9,NULL,NULL,38,6)
,
(10,NULL,NULL,42,7)
,
(12,NULL,50,NULL,10)
,
(13,NULL,51,NULL,11)
,
(16,NULL,NULL,70,17)
,
(17,NULL,NULL,72,18)
,
(18,NULL,NULL,74,19)
,
(19,NULL,NULL,78,22)
,
(20,NULL,NULL,80,23)
,
(21,NULL,NULL,82,24)
,
(22,NULL,NULL,84,25)
,
(23,NULL,NULL,86,26)
,
(24,NULL,NULL,89,27)
,
(38,NULL,NULL,76,33)
,
(39,NULL,NULL,103,33)
,
(41,NULL,218,NULL,35)
,
(42,NULL,NULL,119,33)
,
(45,NULL,NULL,59,37)
,
(46,NULL,NULL,57,38)
,
(56,'Hide if not "Entrance Skill to Entrance Skill"',NULL,129,44)
,
(57,'Hide sections Current Course Objectives, Requisite Course Objective(s).',NULL,59,45)
,
(58,'Hide sections Current Entrance Skills, Requisite Entrance Skills.',NULL,129,46)
,
(59,'Hide if "This Course has Independent Study Hours" is not yes',236,NULL,47)
,
(87,'Show/hide',NULL,197,66)
,
(1125,'Show/hide',369,NULL,1068)
,
(1126,'Show/hide',370,NULL,1069)
,
(1127,'Show/hide',1403,NULL,1070)
,
(1128,'Show/hide',NULL,1217,1071)
,
(1129,'Show/hide',1407,NULL,1072)
,
(1130,'Show/hide',1409,NULL,1073)
,
(1201,'Show/hide',NULL,1204,1084)
,
(1203,'Show/hide',NULL,1205,1084)
,
(1204,'Show/hide',1372,NULL,1086)
,
(1205,'Show/hide',1373,NULL,1087)
,
(1206,'Show/hide',NULL,1278,1088)
,
(1211,'Show/hide',NULL,1206,1089)
,
(1212,'Show/hide',NULL,1207,1090)
,
(1213,'Show/hide',NULL,31,1091)
,
(1214,'Show/hide',NULL,1203,1092)
,
(1215,'Show/hide',NULL,200,1093)
,
(1216,'Show/hide',NULL,201,1094)
,
(1217,'Show/hide',NULL,27,1095)
,
(1218,'Show/hide',NULL,111,1096)
,
(1219,'Show/hide',NULL,105,1097)
,
(1220,'Show/hide',NULL,202,1098)
,
(1221,'Show/hide',NULL,106,1099)
,
(1222,'Show/hide',NULL,112,1100)
,
(1223,'Show/hide',NULL,107,1101)
,
(1224,'Show/hide',NULL,1200,1102)
,
(1225,'Show/hide',NULL,108,1103)
,
(1226,'Show/hide',NULL,113,1104)
,
(1227,'Show/hide',NULL,30,1105)
,
(1228,'Show/hide',NULL,1201,1106)
,
(1229,'Show/hide',NULL,124,1107)
,
(1230,'Show/hide',NULL,125,1108)
,
(1231,'Show/hide',NULL,118,1109)
,
(1232,'Show/hide',NULL,1202,1110)
,
(1233,'Show/hide',NULL,32,1111)
,
(1234,'Show/hide',NULL,109,1112)
,
(1235,'Show/hide',NULL,110,1113)
,
(1236,'Show/hide',NULL,199,1114)
,
(1237,'Show/hide',NULL,28,1115)
,
(1238,'Show/hide',NULL,117,1116)
,
(1239,'Show/hide',192,NULL,1117)
,
(1240,'Show/hide',1374,NULL,1118)
,
(1241,'Show/hide',NULL,1279,1119)
,
(1243,'Show/hide',1375,NULL,1121)
,
(1244,'Show/hide',22,NULL,1122)
,
(1245,'Show/hide',375,NULL,1123)
,
(1246,'Show/hide',NULL,199,1124)
,
(1247,'Show/hide',NULL,109,1125)
,
(1248,'Show/hide',NULL,1202,1126)
,
(1249,'Show/hide',NULL,125,1127)
,
(1250,'Show/hide',NULL,1201,1128)
,
(1251,'Show/hide',NULL,113,1129)
,
(1252,'Show/hide',NULL,1200,1130)
,
(1253,'Show/hide',NULL,112,1131)
,
(1254,'Show/hide',NULL,202,1132)
,
(1255,'Show/hide',NULL,111,1133)
,
(1256,'Show/hide',188,NULL,1134)
,
(1257,'Show/hide',13,NULL,1135)
,
(1258,'Show/hide',190,NULL,1136)
,
(1259,'Show/hide',191,NULL,1137)
,
(1260,'Show/hide',16,NULL,1138)
,
(1261,'Show/hide',19,NULL,1139)
,
(1262,'Show/hide',212,NULL,1140)
,
(1263,'Show/hide',214,NULL,1141)
,
(1264,'Show/hide',NULL,1280,1142)
,
(1265,'Show/hide',NULL,1281,1143)
,
(1266,'Show/hide',NULL,1282,1144)
,
(1267,'Show/hide',NULL,1284,1145)
,
(1268,'Show/hide',NULL,1279,1146)
,
(1269,'Show/hide',NULL,1285,1147)
,
(1270,'Show/hide',NULL,1286,1148)
,
(1271,'Show/hide',NULL,1283,1149)
,
(1272,'Show/hide',NULL,1287,1150)
,
(1273,'Show/hide',225,NULL,1151)
,
(1274,'Show/hide',197,NULL,1152)
,
(1275,'Show/hide',199,NULL,1153)
,
(1276,'Show/hide',20,NULL,1154)
,
(1277,'Show/hide',26,NULL,1155)
,
(1278,'Show/hide',194,NULL,1156)
,
(1279,'Show/hide',24,NULL,1157)
,
(1280,'Show/hide',195,NULL,1158)
,
(1281,'Show/hide',374,NULL,1159)
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

 
-- Get MetaFieldFormula Records
DECLARE  @MetaFieldFormulaTempTable Table
( OldMetaFieldFormulaId INT,OldMetaSelectedFieldId_MetaFieldFormula INT, Formula NVARCHAR (500)
);

INSERT INTO @MetaFieldFormulaTempTable
(OldMetaFieldFormulaId,OldMetaSelectedFieldId_MetaFieldFormula,Formula)
OUTPUT INSERTED.*
VALUES 
(1,13,'([1]*18).toFixed(2)')
,
(2,14,'
if ([2] == 1) {([1]*18).toFixed(2)} else {([3]*18).toFixed(2)}')
,
(3,16,'([1]*48).toFixed(2)')
,
(4,17,'
if ([2] == 1) {([1]*54).toFixed(2)} else {([3]*54).toFixed(2)}')
,
(5,19,'([1]*54).toFixed(2)')
,
(6,20,'
if ([2] == 1) {([1]*54).toFixed(2)} else {([3]*54).toFixed(2)}')
,
(7,23,'([1]*36 + [2]*48 + [3]*24).toFixed(2)')
,
(8,24,'if ([3] == 1) {([1]*36 +[2]*54 + [6]*27).toFixed(2)} else {([4]*36 +[5]*54 + [7]*27).toFixed(2)}')
,
(9,25,'([1]  + [2]+ [3] + [4]).toFixed(2)')
,
(10,26,'([1]  + [2]+ [3] + [4]).toFixed(2)')
,
(11,189,'if ([2] == 1) {([1]*36).toFixed(2)} else {([3]*36).toFixed(2)}')
,
(12,190,'([1]*36).toFixed(2)')
,
(13,193,'([1]*18 + [2]*54 + [3]*48).toFixed(2)')
,
(14,194,'if ([3] == 1) {([1]*18 +[2]*54 + [6]*54).toFixed(2)} else {([4]*18 +[5]*54 + [7]*54).toFixed(2)}')
,
(15,195,'if ([4] == 1) {([1]*18 + [1]*36 + [2]*54 + [3]*54 + [8]*54 +[8]*27).toFixed(2)} else {([5]*18 + [5]*36 + [6]*54 + [7]*54 + [9]*54 + [9]*27).toFixed(2)}')
,
(16,196,'([1]*18 + [1]*36 + [2]*48 + [3]*54 + [4]*48 + [4]*24).toFixed(2)')
,
(17,212,'([1]*48).toFixed(2)')
,
(18,213,'if ([2] == 1) {([1]*54).toFixed(2)} else {([3]*54).toFixed(2)}')
,
(19,214,'([1]*24).toFixed(2)')
,
(20,215,'if ([2] == 1) {([1]*27).toFixed(2)} else {([3]*27).toFixed(2)}')
,
(21,372,'([1]+[2]).toFixed(2)')
,
(22,374,'([1]+[2]).toFixed(2)')
;

--INSERT INTO MetaFieldFormula table ON Destination Database

;WITH SourceData AS
(
	SELECT mfftt.OldMetaFieldFormulaId,mfftt.OldMetaSelectedFieldId_MetaFieldFormula, mfftt.Formula, kt.NewId
	FROM @MetaFieldFormulaTempTable mfftt
	INNER JOIN #KeyTranslation kt ON mfftt.OldMetaSelectedFieldId_MetaFieldFormula = kt.OldId
		AND kt.DestinationTable = 'MetaSelectedField'
)
MERGE INTO MetaFieldFormula
		USING SourceData sd ON (1 = 0)
		WHEN Not Matched By Target THEN
		INSERT (MetaSelectedFieldId, Formula)
		VALUES (sd.NewId, sd.Formula)
		OUTPUT 'MetaFieldFormula', sd.OldMetaFieldFormulaId, INSERTED.Id INTO #KeyTranslation (DestinatioNTable, OldId, NewId);

--===========================End MetaFieldFormula=================================


--=====================Begin MetaFieldFormulaDepENDency===========================

 
-- Get MetaFieldFormulaDepENDency Records
DECLARE  @MetaFieldFormulaDepENDencyTempTable Table
( OldMetaFieldFormulaDepENDencyId INT,OldMetaSelectedFieldId_MetaFieldFormulaDepENDency INT, FormulaIndex Int
);

INSERT INTO @MetaFieldFormulaDepENDencyTempTable
( OldMetaFieldFormulaDepENDencyId,OldMetaSelectedFieldId_MetaFieldFormulaDepENDency, FormulaIndex)
OUTPUT INSERTED.*
VALUES 
(1,188,1)
,
(12,188,1)
,
(13,188,1)
,
(7,188,1)
,
(16,188,1)
,
(9,188,1)
,
(2,188,3)
,
(11,188,3)
,
(14,188,4)
,
(8,188,4)
,
(15,188,5)
,
(3,191,1)
,
(7,191,2)
,
(16,191,2)
,
(9,191,2)
,
(4,191,3)
,
(8,191,5)
,
(15,191,7)
,
(13,192,2)
,
(5,192,1)
,
(16,192,3)
,
(9,192,3)
,
(6,192,3)
,
(14,192,5)
,
(15,192,6)
,
(2,197,1)
,
(11,197,1)
,
(14,197,1)
,
(8,197,1)
,
(15,197,1)
,
(10,197,1)
,
(4,198,1)
,
(15,198,2)
,
(8,198,2)
,
(10,198,2)
,
(14,199,2)
,
(6,199,1)
,
(15,199,3)
,
(10,199,3)
,
(2,205,2)
,
(11,205,2)
,
(4,205,2)
,
(6,205,2)
,
(14,205,3)
,
(8,205,3)
,
(15,205,4)
,
(18,205,2)
,
(20,205,2)
,
(19,225,1)
,
(13,225,3)
,
(7,225,3)
,
(16,225,4)
,
(17,225,1)
,
(18,225,3)
,
(20,225,3)
,
(9,225,4)
,
(14,225,7)
,
(8,225,7)
,
(15,225,9)
,
(20,226,1)
,
(14,226,6)
,
(8,226,6)
,
(15,226,8)
,
(18,226,1)
,
(10,226,4)
,
(21,1372,1)
,
(22,1373,1)
,
(21,1374,2)
,
(22,1375,2)
;


--INSERT INTO MetaFieldFormulaDepENDency table ON Destination Database

;WITH SourceData AS
	(
	SELECT mffdtt.OldMetaFieldFormulaDepENDencyId, 
	kt.NewId AS MetaFieldFormulaId,
	kt1.NewId AS MetaSelectedFieldId,					
		mffdtt.FormulaIndex
	FROM @MetaFieldFormulaDepENDencyTempTable mffdtt
	INNER JOIN #KeyTranslation kt ON mffdtt.OldMetaFieldFormulaDepENDencyId = kt.OldId
		AND kt.DestinationTable = 'MetaFieldFormula'
	INNER JOIN #KeyTranslation kt1 ON mffdtt.OldMetaSelectedFieldId_MetaFieldFormulaDepENDency = kt1.OldId
		AND kt1.DestinationTable = 'MetaSelectedField'
	)
	MERGE INTO MetaFieldFormulaDepENDency
		USING SourceData sd ON (1 = 0)
		WHEN Not Matched By Target THEN
		INSERT (MetaFieldFormulaId,MetaSelectedFieldId, FormulaIndex)
		VALUES (sd.MetaFieldFormulaId,sd.MetaSelectedFieldId, sd.FormulaIndex)
		OUTPUT INSERTED.*;

	

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