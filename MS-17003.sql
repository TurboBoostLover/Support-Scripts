
	/************************************************************************************************
	***                               Insertion of Extracted Script                          
	***                                                                                       
	***                                                                                       
	*** Created with the Template Configuration Extract Script and SQL Generator (version 2022.12.14)        
	***                                                                                       
	*** Script generated on Aug  5 2024 10:24AM                                              
	***                                                                                       
	*** Source Client: California Indian Nations College                                                                 
	*** Source Template: 6                                                              
	*** Source Template Name: Course Block Library             
	*** Initial table:        
	*** Initial id: None provided 
	*** 
	***                                                                               
	***  Instructions for manually inserting into a Database:                               
	***                  1. Replace the Database Name in the "Use" statement if necessary     
	***                  2. Replace the Id in the @ClientId declaration if necessary                                 
	***                  3. Run the Script.                                                   
	***                                                                                       
	***  
    ***  Notes:          1. This will insert the template into the target Database            
	***                  2. This INSERTs TemplateType and ProposalType records as well        
	***                  3. If the 
	insert fails with the following error                      
	***                          "Cannot insert the value NULL into column 'ProcessId',            
	***                           table 'IDOE.dbo.ProcessProposalType'; column                     
	***                           does not allow nulls. Update fails."  
	***                      then the Target Client does not have a workflow for the        
	***                      entity type.  To resolve this either 
	***                      a. Create a basic workflow for the entity type, on 
    ***                         the target Database using [config].[spCreateNewOneStepWorkflow] or 
	***                      b. Replace the @ProcessId definition with an existing Process Id.      
    ***  
	***
	***                                                                                             
	***                                                                                       
	************************************************************************************************/
	--COMMIT

Use cinc;

-------------------Items I need to do also the extraction script can't handle-------------------------------------
exec upGetUpdateClientSetting @setting = 'AllowLibraries', @newValue = 1, @clientId = 1, @valuedatatype = 'bit', @section = 'Other'
------------------------------------------------------------------------------------------------------------------

DECLARE @JiraTicketNumber NVARCHAR(20) = 'MS-17003';
DECLARE @Comments NVARCHAR(MAX) = 'Add Course Block Library';
DECLARE @Developer NVARCHAR(50) = 'Nate W.';
DECLARE @ScriptTypeId int = 1; /* Default on this script is 2 = Enhancement
To See all Options run the following Query

SELECT * FROM history.ScriptType
*/
DECLARE @ClientCode nvarchar(50) = NULL ;
DECLARE @InitialTableName NVARCHAR(100);
SET @InitialTableName = '';
DECLARE @InitialId int = 0;
DECLARE @ClientId Int = 1;
DECLARE @OverrideClientId Int = Coalesce((Select Id from Client where Code =  @ClientCode ),(Select top 1 Id from Client where Active = 1));
DECLARE @SourceDatabase NVARCHAR(100) = 'cinc';
DECLARE @SourceTemplateTypeId Int = 6;
DECLARE @SourceTemplateId int  = 6;
DECLARE @InsertToMetaTemplateId int ; --Set this if inserting sections into a different template Id from the extrated template
DECLARE @InsertToMetaTemplateTypeId int ; --Set this if inserting sections into a different template type Id from the extrated template
DECLARE @SourceParentSectionId int ; --Do not set this variable
DECLARE @TargetParentSectionId int ; --Do not set this here set it below if necessary
DECLARE @ClientEntityType NVARCHAR(100) = 'Coruse Block Library';
 
DECLARE @MetaTemplateId int;
DECLARE @MetaTemplateTypeId int;
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

	If exists(select top 1 1 from History.ScriptsRunOnDatabase where TicketNumber = @JiraTicketNumber and Developer = @Developer and Comments = @Comments)
	THROW 51000, 'This Script has already been run', 1;

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

--========================Begin Client Entity Type==============================
		
		/* Get ClientEntityType */
		DECLARE  @ClientEntityTypeTempTable Table
		(ClientEntityType_Id NVARCHAR(MAX),ClientEntityType_ClientId NVARCHAR(MAX),ClientEntityType_EntityTypeId NVARCHAR(MAX),ClientEntityType_SortOrder NVARCHAR(MAX),ClientEntityType_Title NVARCHAR(MAX),ClientEntityType_OrganizationConnectionStrategyId NVARCHAR(MAX),ClientEntityType_ProposalInterlockStrategyId NVARCHAR(MAX),ClientEntityType_Active NVARCHAR(MAX),ClientEntityType_PluralTitle NVARCHAR(MAX),ClientEntityType_ShortTitle NVARCHAR(MAX),ClientEntityType_EquivalencyGroup NVARCHAR(MAX),ClientEntityType_EntitySpecializationTypeId NVARCHAR(MAX),ClientEntityType_PublicSearchVisible NVARCHAR(MAX),ClientEntityType_ClientEntityTypeGroupId NVARCHAR(MAX));
		

		INSERT INTO @ClientEntityTypeTempTable
		(ClientEntityType_Id,ClientEntityType_ClientId,ClientEntityType_EntityTypeId,ClientEntityType_SortOrder,ClientEntityType_Title,ClientEntityType_OrganizationConnectionStrategyId,ClientEntityType_ProposalInterlockStrategyId,ClientEntityType_Active,ClientEntityType_PluralTitle,ClientEntityType_ShortTitle,ClientEntityType_EquivalencyGroup,ClientEntityType_EntitySpecializationTypeId,ClientEntityType_PublicSearchVisible,ClientEntityType_ClientEntityTypeGroupId)
		--OUTPUT INSERTED.*
		VALUES
(12,1,2,10,'Coruse Block Library',2,1,1,'Course Block Libraries',NULL,NULL,2,0,NULL)
;

		/* Insert ClientEntityType into Destination Database */
		


		IF (SELECT COUNT(*) FROM @ClientEntityTypeTempTable) > 0
		BEGIN
		;WITH SourceData AS
		( 
		SELECT ClientEntityType_Id,ClientEntityType_ClientId,ClientEntityType_EntityTypeId,ClientEntityType_SortOrder,ClientEntityType_Title,ClientEntityType_OrganizationConnectionStrategyId,ClientEntityType_ProposalInterlockStrategyId,ClientEntityType_Active,ClientEntityType_PluralTitle,ClientEntityType_ShortTitle,ClientEntityType_EquivalencyGroup,ClientEntityType_EntitySpecializationTypeId,ClientEntityType_PublicSearchVisible,ClientEntityType_ClientEntityTypeGroupId
		FROM @ClientEntityTypeTempTable tt
		)
MERGE INTO ClientEntityType
		USING SourceData sd 
			ON ClientId = @ClientId 
			AND EntityTypeId = sd.ClientEntityType_EntityTypeId
			AND Title = sd.ClientEntityType_Title
		WHEN Not Matched By Target THEN
		INSERT (ClientId,EntityTypeId,SortOrder,Title,OrganizationConnectionStrategyId,ProposalInterlockStrategyId,Active,PluralTitle,ShortTitle,EquivalencyGroup,EntitySpecializationTypeId,PublicSearchVisible,ClientEntityTypeGroupId)
		VALUES (@ClientId,sd.ClientEntityType_EntityTypeId,sd.ClientEntityType_SortOrder,sd.ClientEntityType_Title,sd.ClientEntityType_OrganizationConnectionStrategyId,sd.ClientEntityType_ProposalInterlockStrategyId,sd.ClientEntityType_Active,sd.ClientEntityType_PluralTitle,sd.ClientEntityType_ShortTitle,sd.ClientEntityType_EquivalencyGroup,sd.ClientEntityType_EntitySpecializationTypeId,sd.ClientEntityType_PublicSearchVisible,sd.ClientEntityType_ClientEntityTypeGroupId)
		WHEN Matched THEN UPDATE
		SET Title = sd.ClientEntityType_Title
OUTPUT 'ClientEntityType',sd.ClientEntityType_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);

		END

--========================End Client Entity Type================================

--======================Begin Client Entity Sub Type============================

--======================End Client Entity Sub Type==============================


--=======================Begin Meta Template Type===============================

 
-- Get TemplateType
DECLARE  @TemplateTypeTempTable Table
( OldTemplateTypeId INT,TemplateName NVARCHAR(1000),ReferenceTable NVARCHAR(1000),ReferencePrimaryKey  NVARCHAR(1000),EntityTypeId INT,Active INT,	
IsPresentationView INT,DefaultType INT,TTClientEntityTypeId INT,IsReducedView Bit
);

INSERT INTO @TemplateTypeTempTable
(OldTemplateTypeId,TemplateName,ReferenceTable,ReferencePrimaryKey,EntityTypeId,Active,IsPresentationView,DefaultType,TTClientEntityTypeId,IsReducedView)
--OUTPUT INSERTED.*
VALUES 
(6,'Course Block Library','Program','Id',2,1,0,1,12,NULL)
;

-- INSERT TemplateType INTO Destination Database
;WITH SourceData AS
(
SELECT DISTINCT OldTemplateTypeId,TemplateName,ReferenceTable,ReferencePrimaryKey,tt.EntityTypeId,1 AS Active,@ClientId AS ClientId,IsPresentationView,DefaultType,
cet.Id AS ClientEntityTypeId,IsReducedView
FROM @TemplateTypeTempTable tt
Inner Join ClientEntityType cet on cet.Title = @ClientEntityType
	And ClientId = @ClientId
--LEFT JOIN #KeyTranslation kt ON tt.TTClientEntityTypeId = kt.OldId
--	AND kt.DestinationTable = 'ClientEntityType'
)
MERGE INTO MetaTemplateType
USING SourceData sd ON (1 = 0)
WHEN Not Matched By Target THEN
INSERT (TemplateName,ReferenceTable,ReferencePrimaryKey,EntityTypeId,Active,ClientId,IsPresentationView,DefaultType,ClientEntityTypeId,IsReducedView)
VALUES (sd.TemplateName,sd.ReferenceTable,sd.ReferencePrimaryKey,sd.EntityTypeId,sd.Active,@ClientId,COALESCE(sd.IsPresentationView,0),sd.DefaultType,sd.ClientEntityTypeId,sd.IsReducedView)
OUTPUT 'MetaTemplateType', sd.OldTemplateTypeId, INSERTED.MetaTemplateTypeId INTO #KeyTranslation (DestinationTable, OldId, NewId);

SET @MetaTemplateTypeId = (SELECT newId FROM #KeyTranslation WHERE DestinationTable = 'MetaTemplateType');


--========================End Meta Template Type================================


--===================Begin Meta Report Template Type============================


--====================End Meta Report Template Type=============================



--===========================Begin Award Level==================================


--============================End Award Level===================================


--==========================Begin Proposal Type=================================

		
-- Get ProposalType
DECLARE  @ProposalTypeTempTable Table
(ProposalType_Id NVARCHAR(MAX),ProposalType_ClientId NVARCHAR(MAX),ProposalType_Title NVARCHAR(MAX),ProposalType_EntityTypeId NVARCHAR(MAX),ProposalType_ClientEntitySubTypeId NVARCHAR(MAX),ProposalType_ProcessActionTypeId NVARCHAR(MAX),ProposalType_MetaTemplateTypeId NVARCHAR(MAX),ProposalType_Active NVARCHAR(MAX),ProposalType_DeletedBy_UserId NVARCHAR(MAX),ProposalType_DeletedDate NVARCHAR(MAX),ProposalType_Presentation_MetaTemplateTypeId NVARCHAR(MAX),ProposalType_AvailableForLookup NVARCHAR(MAX),ProposalType_AllowReactivation NVARCHAR(MAX),ProposalType_AllowMultipleApproved NVARCHAR(MAX),ProposalType_ReactivationRequired NVARCHAR(MAX),ProposalType_AwardLevelId NVARCHAR(MAX),ProposalType_ClientEntityTypeId NVARCHAR(MAX),ProposalType_Code NVARCHAR(MAX),ProposalType_CloneRequired NVARCHAR(MAX),ProposalType_AllowDistrictClone NVARCHAR(MAX),ProposalType_AllowCloning NVARCHAR(MAX),ProposalType_MaxClone NVARCHAR(MAX),ProposalType_Instructions NVARCHAR(MAX),ProposalType_HideProposalRequirementFields NVARCHAR(MAX));

INSERT INTO @ProposalTypeTempTable

(ProposalType_Id,ProposalType_ClientId,ProposalType_Title,ProposalType_EntityTypeId,ProposalType_ClientEntitySubTypeId,ProposalType_ProcessActionTypeId,ProposalType_MetaTemplateTypeId,ProposalType_Active,ProposalType_DeletedBy_UserId,ProposalType_DeletedDate,ProposalType_Presentation_MetaTemplateTypeId,ProposalType_AvailableForLookup,ProposalType_AllowReactivation,ProposalType_AllowMultipleApproved,ProposalType_ReactivationRequired,ProposalType_AwardLevelId,ProposalType_ClientEntityTypeId,ProposalType_Code,ProposalType_CloneRequired,ProposalType_AllowDistrictClone,ProposalType_AllowCloning,ProposalType_MaxClone,ProposalType_Instructions,ProposalType_HideProposalRequirementFields)
--OUTPUT INSERTED.*
 VALUES
(10,1,'Course Block Library',2,NULL,1,6,1,NULL,NULL,NULL,0,0,0,0,NULL,12,'ED0ED210-D5A6-4C0A-9106-E773E4217533',0,0,0,NULL,NULL,0)
;
-- Insert ProposalType INTO Destination Database


--DECLARE @ClientId int = (SELECT Top 1 Id FROM Client WHERE Active = 1);
DECLARE @ClientEntityTypeId int = 
	(
		SELECT Top 1 Id 
		FROM ClientEntityType
		WHERE Active = 1 
		 And ClientId = @ClientId
		 And Title = @ClientEntityType
	);

;WITH SourceData AS
( 
SELECT ProposalType_Id,ProposalType_ClientId,ProposalType_Title,ProposalType_EntityTypeId,COALESCE(kt.NewId, ProposalType_ClientEntitySubTypeId) AS ProposalType_ClientEntitySubTypeId,ProposalType_ProcessActionTypeId,kt2.NewId AS ProposalType_MetaTemplateTypeId,ProposalType_Active,ProposalType_DeletedBy_UserId,ProposalType_DeletedDate,ProposalType_Presentation_MetaTemplateTypeId,ProposalType_AvailableForLookup,ProposalType_AllowReactivation,ProposalType_AllowMultipleApproved,ProposalType_ReactivationRequired,kt3.NewId AS ProposalType_AwardLevelId,COALESCE(kt1.NewId,@ClientEntityTypeId) AS ProposalType_ClientEntityTypeId, ProposalType_Code, ProposalType_CloneRequired, ProposalType_AllowDistrictClone, ProposalType_AllowCloning, ProposalType_MaxClone,ProposalType_Instructions,ProposalType_HideProposalRequirementFields
FROM @ProposalTypeTempTable tt
INNER JOIN #KeyTranslation kt2 ON tt.ProposalType_MetaTemplateTypeId = kt2.OldId
	AND kt2.DestinationTable = 'MetaTemplateType'
LEFT JOIN #KeyTranslation kt1 ON tt.ProposalType_ClientEntityTypeId = kt1.OldId
	AND kt1.DestinationTable = 'ClientEntityType'
LEFT JOIN #KeyTranslation kt ON tt.ProposalType_ClientEntitySubTypeId = kt.OldId
	AND kt.DestinationTable = 'ClientEntitySubType'
LEFT JOIN #KeyTranslation kt3 ON tt.ProposalType_AwardLevelId = kt3.OldId
	AND kt3.DestinationTable = 'AwardLevel'
)
MERGE INTO ProposalType
USING SourceData sd ON  1=0 AND upper(@SourceDatabase) = Upper(DB_NAME())
--ProposalType_ClientId = @ClientId
--AND ProposalType_EntityTypeId = EntityTypeId
--AND ProposalType_Title = Title
--WHEN Matched THEN UPDATE
--SET Title = ProposalType_Title
WHEN Not Matched By Target THEN
INSERT (ClientId,Title,EntityTypeId,ClientEntitySubTypeId,ProcessActionTypeId,MetaTemplateTypeId,Active,DeletedBy_UserId,DeletedDate,Presentation_MetaTemplateTypeId,AvailableForLookup,AllowReactivation,AllowMultipleApproved,ReactivationRequired,AwardLevelId,ClientEntityTypeId,/*Code,*/CloneRequired,AllowDistrictClone,AllowCloning,MaxClone,Instructions,HideProposalRequirementFields)
VALUES (@ClientId,sd.ProposalType_Title,sd.ProposalType_EntityTypeId,sd.ProposalType_ClientEntitySubTypeId,sd.ProposalType_ProcessActionTypeId,sd.ProposalType_MetaTemplateTypeId,sd.ProposalType_Active,sd.ProposalType_DeletedBy_UserId,sd.ProposalType_DeletedDate,sd.ProposalType_Presentation_MetaTemplateTypeId,sd.ProposalType_AvailableForLookup,sd.ProposalType_AllowReactivation,sd.ProposalType_AllowMultipleApproved,sd.ProposalType_ReactivationRequired,sd.ProposalType_AwardLevelId,sd.ProposalType_ClientEntityTypeId,/*sd.ProposalType_Code,*/sd.ProposalType_CloneRequired,sd.ProposalType_AllowDistrictClone,sd.ProposalType_AllowCloning,sd.ProposalType_MaxClone,sd.ProposalType_Instructions,sd.ProposalType_HideProposalRequirementFields)
OUTPUT 'ProposalType',sd.ProposalType_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);

--===========================End Proposal Type==================================


--=======================Begin ProcessProposal Type=============================

		
-- Get processProposalType
DECLARE  @processProposalTypeTempTable Table
(ProcessProposalType_Id NVARCHAR(MAX),ProcessProposalType_ProposalTypeId NVARCHAR(MAX),ProcessProposalType_ProcessId NVARCHAR(MAX));

INSERT INTO @processProposalTypeTempTable

(ProcessProposalType_Id,ProcessProposalType_ProposalTypeId,ProcessProposalType_ProcessId)
OUTPUT INSERTED.*
 VALUES
(8,10,11)
;
-- Insert processProposalType INTO Destination Database



DECLARE @PPTIdentity int = (SELECT COALESCE(Max(Id),0) FROM ProcessProposalType);

DECLARE @InValidProcessIdInTempTable int;
SET @InValidProcessIdInTempTable = 
	(
	SELECT COUNT(ProcessProposalType_ProcessId)
	FROM @processProposalTypeTempTable ppt
	WHERE not exists (SELECT 1 FROM Process p WHERE p.Id = ppt.ProcessProposalType_ProcessId)
	);
	--SELECT @InValidProcessIdInTempTable AS invalidprocess
	--PRINT  CAST(@InValidProcessIdInTempTable AS NVARCHAR) + '= invalidprocess'
	
SET Identity_INSERT ProcessProposalType on

IF upper(@SourceDatabase) = Upper(DB_NAME()) AND @InValidProcessIdInTempTable = 0 AND @ProcessId Is NULL
BEGIN
;WITH SourceData AS
( 
SELECT  ROW_NUMBER() OVER (
	ORDER BY ProcessProposalType_Id
   ) + @PPTIdentity AS PPTIdentity,ProcessProposalType_Id,kt.NewId AS ProcessProposalType_ProposalTypeId,ProcessProposalType_ProcessId
FROM @processProposalTypeTempTable tt
INNER JOIN #KeyTranslation kt ON tt.ProcessProposalType_ProposalTypeId = kt.OldId
				AND kt.DestinationTable = 'ProposalType'
)

MERGE INTO processProposalType
USING SourceData sd ON 
ProposalTypeId = ProcessProposalType_ProposalTypeId
WHEN Not Matched By Target THEN
INSERT (Id,ProposalTypeId,ProcessId)
VALUES (sd.PPTIdentity,sd.ProcessProposalType_ProposalTypeId,sd.ProcessProposalType_ProcessId)
OUTPUT 'processProposalType',INSERTED.* ;
END

Else IF @ProcessId Is NOT NULL AND exists (SELECT Id FROM Process WHERE Id = @ProcessId)
BEGIN
;WITH SourceData AS
	( 
	SELECT  ROW_NUMBER() OVER (
		ORDER BY ProcessProposalType_Id
	   ) + @PPTIdentity AS PPTIdentity,ProcessProposalType_Id,kt.NewId AS ProcessProposalType_ProposalTypeId,@ProcessId AS ProcessProposalType_ProcessId
	FROM @processProposalTypeTempTable tt
	INNER JOIN #KeyTranslation kt ON tt.ProcessProposalType_ProposalTypeId = kt.OldId
					AND kt.DestinationTable = 'ProposalType'
	)
	MERGE INTO processProposalType
	USING SourceData sd ON 
	ProposalTypeId = ProcessProposalType_ProposalTypeId
	WHEN Not Matched By Target THEN
	INSERT (Id,ProposalTypeId,ProcessId)
	VALUES (sd.PPTIdentity,sd.ProcessProposalType_ProposalTypeId,sd.ProcessProposalType_ProcessId)
	OUTPUT 'processProposalType',INSERTED.* 
	;
END
SET Identity_INSERT ProcessProposalType off


--=======================End Process Proposal Type==============================


--==========================Begin Meta Template=================================

	
		
-- Get MetaTemplate
DECLARE  @MetaTemplateTempTable Table
(MetaTemplate_MetaTemplateId NVARCHAR(MAX),MetaTemplate_MetaTemplateTypeId NVARCHAR(MAX),MetaTemplate_CreatedDate NVARCHAR(MAX),MetaTemplate_ClientId NVARCHAR(MAX),MetaTemplate_UserId NVARCHAR(MAX),MetaTemplate_StartDate NVARCHAR(MAX),MetaTemplate_EndDate NVARCHAR(MAX),MetaTemplate_Title NVARCHAR(MAX),MetaTemplate_Active NVARCHAR(MAX),MetaTemplate_LAStUPDATEdDate NVARCHAR(MAX),MetaTemplate_DeletedDate NVARCHAR(MAX),MetaTemplate_DeletedByUserId NVARCHAR(MAX),MetaTemplate_IsDraft NVARCHAR(MAX),MetaTemplate_EntityTitleTemplateString NVARCHAR(MAX),MetaTemplate_PublicEntityTitleTemplateString NVARCHAR(MAX));

INSERT INTO @MetaTemplateTempTable
(MetaTemplate_MetaTemplateId,MetaTemplate_MetaTemplateTypeId,MetaTemplate_CreatedDate,MetaTemplate_ClientId,MetaTemplate_UserId,MetaTemplate_StartDate,MetaTemplate_EndDate,MetaTemplate_Title,MetaTemplate_Active,MetaTemplate_LAStUPDATEdDate,MetaTemplate_DeletedDate,MetaTemplate_DeletedByUserId,MetaTemplate_IsDraft,MetaTemplate_EntityTitleTemplateString,MetaTemplate_PublicEntityTitleTemplateString)
--OUTPUT INSERTED.*
VALUES
(6,6,'Aug  5 2024 10:08AM',1,2,'Aug  5 2024 10:14AM',NULL,'Course Block Library',1,'Aug  5 2024 10:13AM',NULL,NULL,0,'[0] [1]',NULL)
;
-- INSERT MetaTemplate INTO Destination Database

;WITH SourceData AS
( 
SELECT MetaTemplate_MetaTemplateId,COALESCE(@InsertToMetaTemplateTypeId,kt.NewId,@MetaTemplateTypeId) AS MetaTemplate_MetaTemplateTypeId, MetaTemplate_CreatedDate, MetaTemplate_ClientId, MetaTemplate_UserId, MetaTemplate_StartDate,MetaTemplate_EndDate,MetaTemplate_Title,MetaTemplate_Active,MetaTemplate_LastUpdatedDate, MetaTemplate_DeletedDate, MetaTemplate_DeletedByUserId,MetaTemplate_IsDraft,MetaTemplate_EntityTitleTemplateString,MetaTemplate_PublicEntityTitleTemplateString
FROM @MetaTemplateTempTable tt 
LEFT JOIN #KeyTranslation kt ON kt. OldId = tt.MetaTemplate_MetaTemplateTypeId
	AND DestinationTable = 'MetaTemplateType'
)
MERGE INTO MetaTemplate
USING SourceData sd ON (1 = 0)
WHEN Not Matched By Target THEN
	INSERT (MetaTemplateTypeId,CreatedDate,ClientId,UserId,StartDate,EndDate,Title,Active,LastUpdatedDate,DeletedDate,DeletedByUserId,IsDraft,EntityTitleTemplateString,PublicEntityTitleTemplateString)
	VALUES (sd.MetaTemplate_MetaTemplateTypeId,sd.MetaTemplate_CreatedDate,@ClientId,@UserId,sd.MetaTemplate_StartDate,sd.MetaTemplate_EndDate,sd.MetaTemplate_Title,sd.MetaTemplate_Active,sd.MetaTemplate_LastUpdatedDate,sd.MetaTemplate_DeletedDate,sd.MetaTemplate_DeletedByUserId,sd.MetaTemplate_IsDraft,sd.MetaTemplate_EntityTitleTemplateString,sd.MetaTemplate_PublicEntityTitleTemplateString)
OUTPUT 'MetaTemplate',sd.MetaTemplate_MetaTemplateId, INSERTED.MetaTemplateId INTO #KeyTranslation (DestinationTable, OldId, NewId);

/* IF no New MetaTemplateType Record was Inserted then Dont Deactivate the previously active version */
IF (SELECT COUNT(NewId) 
	FROM #KeyTranslation 
	WHERE DestinationTable = 'MetaTemplateType'
	) = 0
BEGIN
/* Deactivate the Previously active version */
UPDATE MetaTemplate
SET EndDate = GetDate()
OUTPUT 'Deactivate the Previously active Template' AS Action, INSERTED.*
WHERE MetaTemplateTypeId  = @MetaTemplateTypeId
AND EndDate IS NULL
AND MetaTemplateId NOT IN 
	(SELECT NewId 
	FROM #KeyTranslation 
	WHERE DestinationTable = 'MetaTemplate'
	);
END
	

If (SELECT Count(newid)
	FROM #KeyTranslation
	WHERE DestinationTable='MetaTemplate'
	) = 1
Begin
SET @MetaTemplateId=
	(SELECT newid
	FROM #KeyTranslation
	WHERE DestinationTable='MetaTemplate'
	);
End

--===========================End Meta Template =================================


--=======================Begin Meta SELECTed Section============================

	
		
	-- Get MetaSelectedSection
	DECLARE  @MetaSelectedSectionTempTable Table
	(MetaSelectedSection_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedSection_ClientId NVARCHAR(MAX),MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedSection_SectionName NVARCHAR(MAX),MetaSelectedSection_DisplaySectionName NVARCHAR(MAX),MetaSelectedSection_SectionDescription NVARCHAR(MAX),MetaSelectedSection_DisplaySectionDescription NVARCHAR(MAX),MetaSelectedSection_ColumnPosition NVARCHAR(MAX),MetaSelectedSection_RowPosition NVARCHAR(MAX),MetaSelectedSection_SortOrder NVARCHAR(MAX),MetaSelectedSection_SectionDisplayId NVARCHAR(MAX),MetaSelectedSection_MetASectionTypeId NVARCHAR(MAX),MetaSelectedSection_MetaTemplateId NVARCHAR(MAX),MetaSelectedSection_DisplayFieldId NVARCHAR(MAX),MetaSelectedSection_HeaderFieldId NVARCHAR(MAX),MetaSelectedSection_FooterFieldId NVARCHAR(MAX),MetaSelectedSection_OriginatorOnly NVARCHAR(MAX),MetaSelectedSection_MetaBASeSchemaId NVARCHAR(MAX),MetaSelectedSection_MetadataAttributeMapId NVARCHAR(MAX),MetaSelectedSection_EntityListLibraryTypeId NVARCHAR(MAX),MetaSelectedSection_EditMapId NVARCHAR(MAX),MetaSelectedSection_AllowCopy NVARCHAR(MAX),MetaSelectedSection_ReadOnly NVARCHAR(MAX),MetaSelectedSection_Config NVARCHAR(MAX));
	

	INSERT INTO @MetaSelectedSectionTempTable
	(MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_ClientId,MetaSelectedSection_MetaSelectedSection_MetaSelectedSectionId,MetaSelectedSection_SectionName,MetaSelectedSection_DisplaySectionName,MetaSelectedSection_SectionDescription,MetaSelectedSection_DisplaySectionDescription,MetaSelectedSection_ColumnPosition,MetaSelectedSection_RowPosition,MetaSelectedSection_SortOrder,MetaSelectedSection_SectionDisplayId,MetaSelectedSection_MetASectionTypeId,MetaSelectedSection_MetaTemplateId,MetaSelectedSection_DisplayFieldId,MetaSelectedSection_HeaderFieldId,MetaSelectedSection_FooterFieldId,MetaSelectedSection_OriginatorOnly,MetaSelectedSection_MetaBASeSchemaId,MetaSelectedSection_MetadataAttributeMapId,MetaSelectedSection_EntityListLibraryTypeId,MetaSelectedSection_EditMapId,MetaSelectedSection_AllowCopy,MetaSelectedSection_ReadOnly,MetaSelectedSection_Config)
	OUTPUT INSERTED.*
	VALUES
	
(1408,1,NULL,'Basic Program Information',1,NULL,0,NULL,0,0,1,30,6,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1416,1,NULL,'Codes and Dates',1,NULL,0,NULL,2,2,1,15,6,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1418,1,1408,'Program Information',1,NULL,0,NULL,0,0,1,1,6,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1437,1,1416,'Approval Dates',1,NULL,0,NULL,0,0,1,12,6,NULL,NULL,NULL,0,150,NULL,NULL,NULL,1,0,NULL)
,
(1438,1,1416,NULL,0,NULL,0,NULL,1,1,1,1,6,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1440,1,1416,NULL,0,NULL,0,NULL,3,2,1,1,6,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1446,1,NULL,'Program Requirements',1,NULL,0,NULL,1,1,1,30,6,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1447,1,1446,'Program Requirements',1,NULL,0,NULL,0,0,1,31,6,NULL,NULL,NULL,0,857,NULL,NULL,NULL,1,0,NULL)
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
(386,1,1,'LabelWidth','180',1418)
,
(396,1,1,'ParentTable','Program',1437)
,
(397,1,1,'ForeignKeyToParent','ProgramId',1437)
,
(398,1,1,'LookupTable','ProgramDateType',1437)
,
(399,1,1,'ForeignKeyToLookup','ProgramDateTypeId',1437)
,
(400,1,1,'ValueTable','ProgramDate',1437)
,
(401,1,1,'ValueField','ProgramDate',1437)
,
(402,1,1,'LabelWidth','180',1437)
,
(403,1,1,'LabelWidth','180',1438)
,
(440,1,1,'TitleTable','ProgramSequence',1447)
,
(441,1,1,'TitleColumn','CourseId',1447)
,
(442,1,1,'SortOrderTable','ProgramSequence',1447)
,
(443,1,1,'SortOrderColumn','SortOrder',1447)
,
(444,1,1,'AllowCalcExclude','TRUE',1447)
,
(445,1,1,'AllowCalcOverride','TRUE',1447)
,
(446,1,1,'AllowConditions','TRUE',1447)
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

	

--=================Begin Meta Foreign Key Criteria Client=======================

SET NOCOUNT ON;

--Begin Stephen Tigner's Script
declare @duplicateKeyTranslation table (
	Id int,
	ParentId int
);

with NumberedOverrides as (
	select 
		mfkcc.*, 
		row_number() over (partition by mfkcc.TableName, mfkcc.DefaultValueColumn, mfkcc.DefaultDisplayColumn, mfkcc.CustomSql, mfkcc.ResolutionSql, 
		mfkcc.DefaultSortColumn, mfkcc.Title, mfkcc.LookupLoadTimingType, mfkcc.PickListId order by mfkcc.Id) CopyNumber
	from MetaForeignKeyCriteriaClient mfkcc
)
,OverrideDuplicates as (
	select
		nov.Id, nov.TableName, nov.DefaultValueColumn, nov.DefaultDisplayColumn, nov.CustomSql, nov.ResolutionSql
		,nov.DefaultSortColumn, nov.Title, nov.LookupLoadTimingType, nov.PickListId, nov.CopyNumber, nov.Id as ParentId
	from NumberedOverrides nov
	where nov.CopyNumber = 1
	union all
	select
		nov.Id, nov.TableName, nov.DefaultValueColumn, nov.DefaultDisplayColumn, nov.CustomSql, nov.ResolutionSql
		,nov.DefaultSortColumn, nov.Title, nov.LookupLoadTimingType, nov.PickListId, nov.CopyNumber, od.ParentId
	from NumberedOverrides nov
	inner join OverrideDuplicates od on (
		(nov.TableName = od.TableName or (nov.TableName is null and od.TableName is null))
		and
		(nov.DefaultValueColumn = od.DefaultValueColumn or (nov.DefaultValueColumn is null and od.DefaultValueColumn is null))
		and
		(nov.DefaultDisplayColumn = od.DefaultDisplayColumn or (nov.DefaultDisplayColumn is null and od.DefaultDisplayColumn is null))
		and
		(nov.CustomSql = od.CustomSql or (nov.CustomSql is null and od.CustomSql is null))
		and
		(nov.ResolutionSql = od.ResolutionSql or (nov.ResolutionSql is null and od.ResolutionSql is null))
		and
		(nov.DefaultSortColumn = od.DefaultSortColumn or (nov.DefaultSortColumn is null and od.DefaultSortColumn is null))
		and
		(nov.Title = od.Title or (nov.Title is null and od.Title is null))
		and
		(nov.LookupLoadTimingType = od.LookupLoadTimingType or (nov.LookupLoadTimingType is null and od.LookupLoadTimingType is null))
		and
		(nov.PickListId = od.PickListId or (nov.PickListId is null and od.PickListId is null))
		and nov.CopyNumber = (od.CopyNumber + 1)
	)
)
,DuplicateKeyTranslation as (
	select Id, ParentId
	from OverrideDuplicates
	where Id <> ParentId
)
insert into @duplicateKeyTranslation
select Id, ParentId
from DuplicateKeyTranslation
;

select 'Key translations for duplicate MFKCC records' as QueryName, dkt.*
from @duplicateKeyTranslation dkt;

update MetaSelectedField
set MetaForeignKeyLookupSourceId = dkt.ParentId
output 'Updating MSF records' as QueryName, 'OLD' as Old, deleted.MetaForeignKeyLookupSourceId as OldOverrideId, 'NEW' as New, inserted.*
from MetaSelectedField msf
inner join @duplicateKeyTranslation dkt on msf.MetaForeignKeyLookupSourceId = dkt.Id

delete mfkcc
output 'Deleting duplicate MFKCC records', deleted.*
from MetaForeignKeyCriteriaClient mfkcc
inner join @duplicateKeyTranslation dkt on mfkcc.Id = dkt.Id;

--End Stephen Tigner's Script

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
(1,52,'Program','Id','Title','SELECT	0 AS Value   ,CONVERT( VARCHAR(10), pr.ImplementDate, 120) AS Text FROM Program p	
inner join proposal pr on p.ProposalId = pr.id WHERE p.Id = @EntityId;','SELECT CONVERT( VARCHAR(10), pr.ImplementDate, 120)  FROM Program p WHERe ID = @ID',NULL,'Program ImplimentDate',2,NULL,NULL)
,
(2,54,'Course','Id','Title','
declare @results table (Value int, Text varchar(max), FilterValue int);

declare @courseid int = (
    select CourseId
    from ProgramCourse
    where id = @pkIdValue
)

declare @requisiteTable table(	SortOrder int,	Title nvarchar(max));
declare @igetcTable table(	SortOrder int,	Title nvarchar(max));
declare @csugeTable table(	SortOrder int,	Title nvarchar(max));
declare @smcgeTable table(	SortOrder int,	Title nvarchar(max));


insert into @requisiteTable (SortOrder, Title)
select 	row_number() over (order by cr.SortOrder, cr.Id) as SortOrder,	isnull(''<li class="list-group-item-compact"><strong>'' + rt.Title + '':</strong> '' + s.SubjectCode + '' '' + rc.CourseNumber + ''</li>'',''<li class="list-group-item-compact"><strong>'' + rt.Title + '':</strong> '' + cr.CourseRequisiteComment + ''</li>'') + isnull('' '' + con.Title,'''') as Title
from 	Course c 	
    inner join CourseRequisite cr 	
        left join Condition con on con.Id = cr.ConditionId
        on cr.CourseId = c.Id 
    left join Course rc on cr.Requisite_CourseId = rc.Id	
    left join Subject s on rc.SubjectId = s.Id	
    inner join RequisiteType rt on cr.RequisiteTypeId = rt.Id 
where 	c.Id = @courseid
order by	cr.SortOrder

insert into @igetcTable (SortOrder, Title)	
select		row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,		''<li class="list-group-item-compact">'' + gee.Title + ''</li>'' as Title	
from 		CourseGeneralEducation cge		
    inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id		
    inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id		
    inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id	
where 		CourseId = @courseid		and geg.Id = 1		and geg.Active = 1		and ge.Active = 1		and gee.Active = 1;

insert into @csugeTable (SortOrder, Title)	
select		row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,		''<li class="list-group-item-compact">'' + gee.Title + ''</li>'' as Title	
from 		CourseGeneralEducation cge		
    inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id		
    inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id		
    inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id	
where 		CourseId = @courseid		and geg.Id = 2		and geg.Active = 1		and ge.Active = 1		and gee.Active = 1;

insert into @smcgeTable (SortOrder, Title)	
select		row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,		''<li class="list-group-item-compact">'' + gee.Title + ''</li>'' as Title	
from 		CourseGeneralEducation cge		
    inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id		
    inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id		
    inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id	
where 		CourseId = @courseid		and geg.Id = 3		and geg.Active = 1		and ge.Active = 1		and gee.Active = 1;

declare @requisites nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedRequisites+dbo.fnHtmlCloseTag(''ol'') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedRequisites    from @requisiteTable rt) cli
    );

declare @igetc nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold font-italic py-1''))+''IGETC''+dbo.fnHtmlCloseTag(''label'')+dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedIGETC+dbo.fnHtmlCloseTag(''ol'') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedIGETC    from @igetcTable rt) cli
    );
declare @csuge nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold font-italic py-1''))+''CSU GE''+dbo.fnHtmlCloseTag(''label'')+dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedCSUGE+dbo.fnHtmlCloseTag(''ol'') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedCSUGE    from @csugeTable rt) cli
    );
declare @smcge nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold font-italic py-1''))+''SMC GE''+dbo.fnHtmlCloseTag(''label'')+dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedSMCGE+dbo.fnHtmlCloseTag(''ol'') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedSMCGE    from @smcgeTable rt) cli
    );
    
declare @gc nvarchar(max) = (select ''<li class="list-group-item-compact py-2"><strong><i class="fa fa-globe pr-1"></i>Satisfies Global Citizenship</strong></li>'' from CourseGlobalCitizenship cgc where IsApproved = 1 and CourseId = @courseid);
declare @de nvarchar(max) = (select ''<li class="list-group-item-compact py-2"><strong><i class="pr-1"></i>Transfers to ''+case when ComparableCsuUc = 1 AND ISCSUTransfer = 1 then ''UC/CSU'' when ComparableCsuUc = 1 then ''CSU'' when ISCSUTransfer = 1 then ''UC'' else null end +''</strong></li>'' from Course where (ComparableCsuUc = 1 OR ISCSUTransfer = 1) and Id = @courseid);
----------------------------------------------------
insert into @results (Value,Text,FilterValue)
select 0 as Value, concat(	dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''pl-2 pr-2 pb-2 pt-0'')) + @requisites + dbo.fnHtmlCloseTag(''div''), dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''px-2''))+concat(@igetc, @csuge, @smcge)+dbo.fnHtmlCloseTag(''div''),dbo.fnHtmlOpenTag(''div'','''')+concat(@gc,@de)+dbo.fnHtmlCloseTag(''div'')) as Text, @courseid as FilterValue;

delete from @requisiteTable;
delete from @igetcTable;
delete from @csugeTable;
delete from @smcgeTable;

select * from @results;
','
declare @results table (Value int, Text varchar(max), FilterValue int);

declare @courseid int = (
    select CourseId
    from ProgramCourse
    where id = @pkIdValue
)

declare @requisiteTable table(	SortOrder int,	Title nvarchar(max));
declare @igetcTable table(	SortOrder int,	Title nvarchar(max));
declare @csugeTable table(	SortOrder int,	Title nvarchar(max));
declare @smcgeTable table(	SortOrder int,	Title nvarchar(max));


insert into @requisiteTable (SortOrder, Title)
select 	row_number() over (order by cr.SortOrder, cr.Id) as SortOrder,	isnull(''<li class="list-group-item-compact"><strong>'' + rt.Title + '':</strong> '' + s.SubjectCode + '' '' + rc.CourseNumber + ''</li>'',''<li class="list-group-item-compact"><strong>'' + rt.Title + '':</strong> '' + cr.CourseRequisiteComment + ''</li>'') + isnull('' '' + con.Title,'''') as Title
from 	Course c 	
    inner join CourseRequisite cr 	
        left join Condition con on con.Id = cr.ConditionId
        on cr.CourseId = c.Id 
    left join Course rc on cr.Requisite_CourseId = rc.Id	
    left join Subject s on rc.SubjectId = s.Id	
    inner join RequisiteType rt on cr.RequisiteTypeId = rt.Id 
where 	c.Id = @courseid
order by	cr.SortOrder

insert into @igetcTable (SortOrder, Title)	
select		row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,		''<li class="list-group-item-compact">'' + gee.Title + ''</li>'' as Title	
from 		CourseGeneralEducation cge		
    inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id		
    inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id		
    inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id	
where 		CourseId = @courseid		and geg.Id = 1		and geg.Active = 1		and ge.Active = 1		and gee.Active = 1;

insert into @csugeTable (SortOrder, Title)	
select		row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,		''<li class="list-group-item-compact">'' + gee.Title + ''</li>'' as Title	
from 		CourseGeneralEducation cge		
    inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id		
    inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id		
    inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id	
where 		CourseId = @courseid		and geg.Id = 2		and geg.Active = 1		and ge.Active = 1		and gee.Active = 1;

insert into @smcgeTable (SortOrder, Title)	
select		row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,		''<li class="list-group-item-compact">'' + gee.Title + ''</li>'' as Title	
from 		CourseGeneralEducation cge		
    inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id		
    inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id		
    inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id	
where 		CourseId = @courseid		and geg.Id = 3		and geg.Active = 1		and ge.Active = 1		and gee.Active = 1;

declare @requisites nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedRequisites+dbo.fnHtmlCloseTag(''ol'') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedRequisites    from @requisiteTable rt) cli
    );

declare @igetc nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold font-italic py-1''))+''IGETC''+dbo.fnHtmlCloseTag(''label'')+dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedIGETC+dbo.fnHtmlCloseTag(''ol'') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedIGETC    from @igetcTable rt) cli
    );
declare @csuge nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold font-italic py-1''))+''CSU GE''+dbo.fnHtmlCloseTag(''label'')+dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedCSUGE+dbo.fnHtmlCloseTag(''ol'') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedCSUGE    from @csugeTable rt) cli
    );
declare @smcge nvarchar(max) = 
    (
        select dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold font-italic py-1''))+''SMC GE''+dbo.fnHtmlCloseTag(''label'')+dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedSMCGE+dbo.fnHtmlCloseTag(''ol'') as Text
        from (    select        dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedSMCGE    from @smcgeTable rt) cli
    );
    
declare @gc nvarchar(max) = (select ''<li class="list-group-item-compact py-2"><strong><i class="fa fa-globe pr-1"></i>Satisfies Global Citizenship</strong></li>'' from CourseGlobalCitizenship cgc where IsApproved = 1 and CourseId = @courseid);
declare @de nvarchar(max) = (select ''<li class="list-group-item-compact py-2"><strong><i class="pr-1"></i>Transfers to ''+case when ComparableCsuUc = 1 AND ISCSUTransfer = 1 then ''UC/CSU'' when ComparableCsuUc = 1 then ''CSU'' when ISCSUTransfer = 1 then ''UC'' else null end +''</strong></li>'' from Course where (ComparableCsuUc = 1 OR ISCSUTransfer = 1) and Id = @courseid);
----------------------------------------------------
insert into @results (Value,Text,FilterValue)
select 0 as Value, concat(	dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''pl-2 pr-2 pb-2 pt-0'')) + @requisites + dbo.fnHtmlCloseTag(''div''), dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''px-2''))+concat(@igetc, @csuge, @smcge)+dbo.fnHtmlCloseTag(''div''),dbo.fnHtmlOpenTag(''div'','''')+concat(@gc,@de)+dbo.fnHtmlCloseTag(''div'')) as Text, @courseid as FilterValue;

delete from @requisiteTable;
delete from @igetcTable;
delete from @csugeTable;
delete from @smcgeTable;

select * from @results;
','order by sortorder',NULL,3,NULL,NULL)
,
(3,56,'Course','Id','Title','select c.Id as [Value],
	coalesce(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title, s.SubjectCode + '' '' + c.CourseNumber, c.Title) + 
	case
		when sa.StatusBaseId != 1 then '' ('' + sa.Title + '')'' 
		when sa.StatusBaseID = 1 then ''''
	end as [Text],
	s.Id as FilterValue,
	cd.Variable as IsVariable,
	case
		when csc.CreditStatusCode = ''N'' then cast(0 as decimal(16, 3))
		else cd.MinCreditHour
	end as [Min],
	case
		when csc.CreditStatusCode = ''N'' then cast(0 as decimal(16, 3))
		else cd.MaxCreditHour
	end as [Max]
from Course c
inner join CourseDescription cd on c.Id = cd.CourseId
inner join [Subject] s on c.SubjectId = s.Id
inner join StatusAlias sa on c.StatusAliasId = sa.Id
left outer join CourseAttribute ca on c.Id = ca.CourseId
left outer join CourseCreditStatus ccs on ca.CourseCreditStatusId = ccs.Id
left outer join CourseCBCode ccc on c.Id = ccc.CourseId
left outer join CB04 cb04 on ccc.CB04Id = cb04.Id
cross apply (
	select
		coalesce(cb04.Code, ccs.Code) as CreditStatusCode
) csc
where (
	(
		c.Active = 1
		and sa.StatusBaseId in (1, 2, 4, 6, 8)
	)
	or exists (
		select 1
		from ProgramSequence pc
		where pc.ProgramId = @entityId
		and pc.CourseId = c.Id
	)
)
order by Text','Select EntityTitle as Text from Course where id = @Id','Order By SortOrder',NULL,3,NULL,NULL)
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
VALUES (sd.Id,sd.MetaForeignKeyCriteriaClient_TableName,sd.MetaForeignKeyCriteriaClient_DefaultValueColumn,sd.MetaForeignKeyCriteriaClient_DefaultDisplayColumn,sd.MetaForeignKeyCriteriaClient_CustomSql,sd.MetaForeignKeyCriteriaClient_ResolutionSql,sd.MetaForeignKeyCriteriaClient_DefaultSortColumn,sd.MetaForeignKeyCriteriaClient_Title,sd.MetaForeignKeyCriteriaClient_LookupLoadTimingType,sd.MetaForeignKeyCriteriaClient_PickListId,sd.MetaForeignKeyCriteriaClient_IsSeeded)
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
(1673,'Program Award',1100,1418,1,NULL,NULL,3,0,1,'TelerikCombo',33,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1674,'Discipline',2536,1418,1,NULL,NULL,1,0,1,'TelerikCombo',33,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1675,'Title',1225,1418,1,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1708,'Department',2537,1418,1,NULL,NULL,2,0,1,'TelerikCombo',33,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1666,'Program Date',1176,1437,0,NULL,NULL,1,0,1,'TelerikDate',27,150,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1667,'Date Type',1127,1437,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1679,'Program Originator',1382,1438,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1709,'Implementation Date',9102,1438,0,NULL,NULL,1,0,1,'QueryText',103,150,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,52,NULL,NULL,NULL,NULL)
,
(1684,'Admin Use Only',1140,1440,0,NULL,NULL,0,0,1,'Textarea',17,100,2,120,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1693,'OtherRequirementTitle',6459,1447,0,NULL,NULL,8,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1694,'Exception',1618,1447,0,NULL,NULL,7,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1695,'Exception Identifier',1603,1447,0,NULL,NULL,6,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1696,'Footer',6457,1447,0,NULL,NULL,5,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1697,'Header',6456,1447,0,NULL,NULL,4,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1698,'Group Name',6458,1447,0,NULL,NULL,3,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1706,'Discipline',4046,1447,0,NULL,NULL,0,0,1,'TelerikCombo',33,400,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1707,'include in SLO map',1621,1447,0,NULL,NULL,9,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(1711,'Course Detail',1594,1447,0,NULL,NULL,2,0,1,'QueryText',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,1,1,NULL,54,NULL,NULL,NULL,NULL)
,
(1713,'Course',5555,1447,0,NULL,NULL,1,0,1,'TelerikCombo',33,400,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,56,NULL,NULL,NULL,NULL)
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
(128,'UpdateSubscriptionColumn1','CourseId',1711)
,
(129,'UpdateSubscriptionTable1','ProgramSequence',1711)
,
(130,'FilterSubscriptionTable','ProgramSequence',1713)
,
(131,'FilterSubscriptionColumn','SubjectId',1713)
,
(132,'FilterTargetTable','ProgramSequence',1713)
,
(133,'FilterTargetColumn','CourseId',1713)
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

		
-- Get MetaTitleFields
DECLARE  @MetaTitleFieldsTempTable Table
(MetaTitleFields_Id NVARCHAR(MAX),MetaTitleFields_MetaTemplateId NVARCHAR(MAX),MetaTitleFields_MetaSelectedFieldId NVARCHAR(MAX),MetaTitleFields_Ordinal NVARCHAR(MAX));

INSERT INTO @MetaTitleFieldsTempTable

(MetaTitleFields_Id,MetaTitleFields_MetaTemplateId,MetaTitleFields_MetaSelectedFieldId,MetaTitleFields_Ordinal)
OUTPUT INSERTED.*
 VALUES
(6,6,1675,0)
,
(7,6,1673,1)
;
-- Insert MetaTitleFields INTO Destination Database

;WITH SourceData AS
( 
SELECT MetaTitleFields_Id,COALESCE(kt.NewId,@MetaTemplateId,MetaTitleFields_MetaTemplateId) AS MetaTitleFields_MetaTemplateId,kt1.NewId AS MetaTitleFields_MetaSelectedFieldId,MetaTitleFields_Ordinal
FROM @MetaTitleFieldsTempTable tt 
INNER JOIN #KeyTranslation kt1 ON kt1.OldId = MetaTitleFields_MetaSelectedFieldId
	AND kt1.DestinationTable = 'MetaSelectedField'
LEFT JOIN #KeyTranslation kt ON kt.OldId = MetaTitleFields_MetaTemplateId
	AND kt.DestinationTable = 'MetaTemplate'
)

MERGE INTO MetaTitleFields
USING SourceData sd ON
sd.MetaTitleFields_MetaTemplateId = MetaTemplateId AND
sd.MetaTitleFields_MetaSelectedFieldId = MetaSelectedFieldId AND
MetaTitleFields_Ordinal = Ordinal
WHEN Not Matched By Target THEN
INSERT (MetaTemplateId,MetaSelectedFieldId,Ordinal)
VALUES (sd.MetaTitleFields_MetaTemplateId,sd.MetaTitleFields_MetaSelectedFieldId,sd.MetaTitleFields_Ordinal)
OUTPUT 'MetaTitleFields',sd.MetaTitleFields_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);

--===========================End Meta Title Fields==============================


--=============================Begin Position=====================================


--===============================End Position=====================================


--=========================Begin MetaDataAttribute/Map===========================

		
-- Get MetaDataAttribute
DECLARE  @MetaDataAttributeTempTable Table
(MetadataAttribute_Id NVARCHAR(MAX),MetadataAttribute_Description NVARCHAR(MAX),MetadataAttribute_ValueText NVARCHAR(MAX),MetadataAttribute_ValueInt NVARCHAR(MAX),MetadataAttribute_ValueFloat NVARCHAR(MAX),MetadataAttribute_ValueBoolean NVARCHAR(MAX),MetadataAttribute_ValueDateTime NVARCHAR(MAX),MetadataAttribute_MetadataAttributeTypeId NVARCHAR(MAX),MetadataAttribute_MetadataAttributeMapId NVARCHAR(MAX),MetadataAttribute_MetaSelectedFieldId NVARCHAR(MAX),MetadataAttribute_MetaSelectedSectionId NVARCHAR(MAX),MetadataAttribute_DataType NVARCHAR(MAX),MetadataAttribute_Text1 NVARCHAR(MAX),MetadataAttribute_Text2 NVARCHAR(MAX),MetadataAttribute_Text3 NVARCHAR(MAX),MetadataAttribute_Text4 NVARCHAR(MAX), MetadataAttribute_TableName NVARCHAR(100) );

--==========================End MetaDataAttribute/Map============================


--===========================Begin update EditMap================================


--==========================Begin Show/Hide Tables================================


--=============================Begin Expression===================================


--============================Begin ListItemType==================================

		
-- Get ListItemType
DECLARE  @ListItemTypeTempTable Table
(ListItemType_Id NVARCHAR(MAX),ListItemType_Title NVARCHAR(MAX),ListItemType_Description NVARCHAR(MAX),ListItemType_ListItemTypeOrdinal NVARCHAR(MAX),ListItemType_ListItemTableName NVARCHAR(MAX),ListItemType_ListItemTitleColumn NVARCHAR(MAX),ListItemType_Active NVARCHAR(MAX),ListItemType_SortOrder NVARCHAR(MAX),ListItemType_StartDate NVARCHAR(MAX),ListItemType_EndDate NVARCHAR(MAX),ListItemType_ClientId NVARCHAR(MAX));

INSERT INTO @ListItemTypeTempTable

(ListItemType_Id,ListItemType_Title,ListItemType_Description,ListItemType_ListItemTypeOrdinal,ListItemType_ListItemTableName,ListItemType_ListItemTitleColumn,ListItemType_Active,ListItemType_SortOrder,ListItemType_StartDate,ListItemType_EndDate,ListItemType_ClientId)
OUTPUT INSERTED.*
 VALUES
(16,'Course',NULL,1,'ProgramSequence','CourseId',1,1,'Nov  8 2021 11:43AM',NULL,1)
,
(17,'Group',NULL,2,'ProgramSequence','GroupTitle',1,2,'Nov  8 2021 11:43AM',NULL,1)
,
(18,'Non-Course Requirement',NULL,3,'ProgramSequence','OtherRequirementTitle',1,3,'Nov  8 2021 11:43AM',NULL,1)
;
-- INSERT ListItemType INTO Destination Database


;WITH SourceData AS
( 

SELECT DISTINCT ListItemType_Id,ListItemType_Title,ListItemType_Description,ListItemType_ListItemTypeOrdinal,ListItemType_ListItemTableName,ListItemType_ListItemTitleColumn,ListItemType_Active,ListItemType_SortOrder,ListItemType_StartDate,ListItemType_EndDate,ListItemType_ClientId
FROM @ListItemTypeTempTable tt
INNER JOIN MetaBASeSchema mbs 
	on tt.ListItemType_ListItemTableName = mbs.ForeignTable 
		AND MetaRelationTypeId = 2
)

MERGE INTO ListItemType 
USING SourceData sd 
	ON sd.ListItemType_ListItemTableName = ListItemTableName
	AND sd. ListItemType_ListItemTitleColumn = ListItemTitleColumn
WHEN Not Matched By Target THEN
INSERT (Title,Description,ListItemTypeOrdinal,ListItemTableName,ListItemTitleColumn,Active,SortOrder,StartDate,EndDate,ClientId)
VALUES (sd.ListItemType_Title,sd.ListItemType_Description,sd.ListItemType_ListItemTypeOrdinal,sd.ListItemType_ListItemTableName,sd.ListItemType_ListItemTitleColumn,sd.ListItemType_Active,sd.ListItemType_SortOrder,sd.ListItemType_StartDate,sd.ListItemType_EndDate,@ClientId)

--OUTPUT 'ListItemType',sd.ListItemType_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);
OUTPUT 'ListItemType',INSERTED.* ;

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

		
-- Get MetaSelectedSectionRolePermission
DECLARE  @MetaSelectedSectionRolePermissionTempTable Table
(MetaSelectedSectionRolePermission_Id NVARCHAR(50),MetaSelectedSectionRolePermission_MetaSelectedSectionId NVARCHAR(50),MetaSelectedSectionRolePermission_RoleId NVARCHAR(50),MetaSelectedSectionRolePermission_AccessRestrictionType NVARCHAR(50));

INSERT INTO @MetaSelectedSectionRolePermissionTempTable

(MetaSelectedSectionRolePermission_Id,MetaSelectedSectionRolePermission_MetaSelectedSectionId,MetaSelectedSectionRolePermission_RoleId,MetaSelectedSectionRolePermission_AccessRestrictionType)
OUTPUT INSERTED.*
 VALUES
(33,1416,1,2)
;
-- INSERT MetaSelectedSectionRolePermission INTO Destination Database




;WITH SourceData AS
( 
SELECT MetaSelectedSectionRolePermission_Id,kt.NewId AS MetaSelectedSectionRolePermission_MetaSelectedSectionId,MetaSelectedSectionRolePermission_RoleId,MetaSelectedSectionRolePermission_AccessRestrictionType
FROM @MetaSelectedSectionRolePermissionTempTable tt
INNER JOIN #KeyTranslation kt ON tt.MetaSelectedSectionRolePermission_MetaSelectedSectionId = kt.OldId
	AND kt.DestinationTable = 'MetaSelectedSection'				
)

MERGE INTO MetaSelectedSectionRolePermission
USING SourceData sd ON (1 = 0)
WHEN Not Matched By Target THEN
INSERT (MetaSelectedSectionId,RoleId,AccessRestrictionType)
VALUES (sd.MetaSelectedSectionRolePermission_MetaSelectedSectionId,sd.MetaSelectedSectionRolePermission_RoleId,sd.MetaSelectedSectionRolePermission_AccessRestrictionType)

OUTPUT INSERTED.*;

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

-------------------Items I need to do also the extraction script can't handle-------------------------------------
INSERT INTO config.ClientMenuItem
(Title, MenuItemPresentationTypeId, ClientMenuId, ClientEntityTypeId, StartDate)
VALUES
('Course Block Library', 4, 1, 12, GETDATE())

DECLARE @Item int = SCOPE_IDENTITY()

INSERT INTO config.ClientMenuSection
(ParentId, MenuSectionTypeId, ClientMenuId, SortOrder, StartDate)
VALUES
(4, 2, 1, 6, GETDATE())

DECLARE @Sec int = SCOPE_IDENTITY()

INSERT INTO Config.ClientMenuLayout
(ClientMenuSectionId, ClientMenuItemId, ClientMenuId, StartDate)
VALUES
(@Sec, @Item, 1, GETDATE())

DECLARE @TID int = (SELECT MetaTemplateTypeId FROM MetaTemplateType WHERE TemplateName = 'Course Block Library')

INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
VALUES
(57, @TID, GETDATE()),
(481, @TID, GETDATE())

DECLARE @Fields INTEGERS
INSERT INTO @Fields
SELECT MetaSelectedFieldId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE MetaAvailableFieldId in (
4046, 1621, 1594
)
and mss.MetaTemplateId = @MetaTemplateId

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'listitemtype', 1, Id FROM @Fields

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId = @MetaTemplateId
------------------------------------------------------------------------------------------------------------------

--Commit