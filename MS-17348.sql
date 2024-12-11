
	/************************************************************************************************
	***                               Insertion of Extracted Script                          
	***                                                                                       
	***                                                                                       
	*** Created with the Template Configuration Extract Script and SQL Generator (version 2022.12.14)        
	***                                                                                       
	*** Script generated on Oct 15 2024 10:30AM                                              
	***                                                                                       
	*** Source Client: Chaffey College                                                                 
	*** Source Template: 82                                                              
	*** Source Template Name: Student Support Initial Version             
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

Use chaffey;

DECLARE @JiraTicketNumber NVARCHAR(20) = 'MS-17348';
DECLARE @Comments NVARCHAR(MAX) = 'Create Sutden Support Review';
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
DECLARE @SourceDatabase NVARCHAR(100) = 'chaffey';
DECLARE @SourceTemplateTypeId Int = 40;
DECLARE @SourceTemplateId int  = 82;
DECLARE @InsertToMetaTemplateId int ; --Set this if inserting sections into a different template Id from the extrated template
DECLARE @InsertToMetaTemplateTypeId int ; --Set this if inserting sections into a different template type Id from the extrated template
DECLARE @SourceParentSectionId int ; --Do not set this variable
DECLARE @TargetParentSectionId int ; --Do not set this here set it below if necessary
DECLARE @ClientEntityType NVARCHAR(100) = 'Program Review';
 
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

--========================Begin Client Entity Type==============================
		
		/* Get ClientEntityType */
		DECLARE  @ClientEntityTypeTempTable Table
		(ClientEntityType_Id NVARCHAR(MAX),ClientEntityType_ClientId NVARCHAR(MAX),ClientEntityType_EntityTypeId NVARCHAR(MAX),ClientEntityType_SortOrder NVARCHAR(MAX),ClientEntityType_Title NVARCHAR(MAX),ClientEntityType_OrganizationConnectionStrategyId NVARCHAR(MAX),ClientEntityType_ProposalInterlockStrategyId NVARCHAR(MAX),ClientEntityType_Active NVARCHAR(MAX),ClientEntityType_PluralTitle NVARCHAR(MAX),ClientEntityType_ShortTitle NVARCHAR(MAX),ClientEntityType_EquivalencyGroup NVARCHAR(MAX),ClientEntityType_EntitySpecializationTypeId NVARCHAR(MAX),ClientEntityType_PublicSearchVisible NVARCHAR(MAX),ClientEntityType_ClientEntityTypeGroupId NVARCHAR(MAX));
		

		INSERT INTO @ClientEntityTypeTempTable
		(ClientEntityType_Id,ClientEntityType_ClientId,ClientEntityType_EntityTypeId,ClientEntityType_SortOrder,ClientEntityType_Title,ClientEntityType_OrganizationConnectionStrategyId,ClientEntityType_ProposalInterlockStrategyId,ClientEntityType_Active,ClientEntityType_PluralTitle,ClientEntityType_ShortTitle,ClientEntityType_EquivalencyGroup,ClientEntityType_EntitySpecializationTypeId,ClientEntityType_PublicSearchVisible,ClientEntityType_ClientEntityTypeGroupId)
		--OUTPUT INSERTED.*
		VALUES
(6,1,6,7,'Program Review',2,1,1,'Program Reviews',NULL,NULL,8,0,NULL)
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
(40,'Comprehensive Program and Services Review – Student Support Areas','Module','Id',6,1,0,0,6,NULL)
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
(48,1,'Comprehensive Program and Services Review – Student Support Areas',6,NULL,1,40,1,NULL,NULL,NULL,0,0,0,0,NULL,6,'D2D2BE86-AF8A-464F-B6BB-90340D9EF52A',0,0,0,NULL,NULL,0)
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
(31,48,37)
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
(82,40,'Sep 23 2024 11:30AM',1,1041,'Sep 23 2024  2:19PM',NULL,'Student Support Initial Version',1,'Oct 15 2024 10:28AM',NULL,NULL,0,'[0]',NULL)
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
	
(7523,1,NULL,'General Information',1,NULL,0,NULL,0,0,1,15,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7524,1,7523,NULL,1,NULL,0,NULL,0,0,1,1,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7525,1,7523,NULL,1,NULL,0,NULL,1,1,1,22,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7526,1,7523,'Contributor',1,NULL,0,NULL,3,3,1,18,82,NULL,NULL,NULL,0,1456,NULL,NULL,NULL,1,0,NULL)
,
(7527,1,7523,NULL,1,NULL,0,NULL,2,2,1,1,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7528,1,NULL,'Equity and Success Metrics - Data Analysis Documentation (to be completed by data coaches)',1,'This page to be completed by PSR Data Coaches.<br>Upload the following items:',1,NULL,1,1,1,15,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7529,1,7537,'Data Files',1,NULL,0,NULL,0,0,1,14,82,NULL,NULL,NULL,0,1384,NULL,NULL,NULL,1,0,NULL)
,
(7530,1,7538,'Records of data coaching sessions',1,NULL,0,NULL,0,0,1,14,82,NULL,NULL,NULL,0,1384,NULL,NULL,NULL,1,0,NULL)
,
(7531,1,7539,'Other supporting documentation of data analysis',1,NULL,0,NULL,0,0,1,14,82,NULL,NULL,NULL,0,1384,NULL,NULL,NULL,1,0,NULL)
,
(7532,1,NULL,'Equity and Success Metrics - Summary of Key Takeaways and Conclusions',1,'<h6><b>The objectives of this section of Program and Services Review are:</b></h6> 
<ol>
	<li>To serve as evidence for Accreditation STANDARD 2.7: The institution designs and delivers equitable and effective services and programs that support students in their unique educational journeys, address academic and non-academic needs, and maximize their potential for success. Such services include library and learning resources, academic counseling and support, and other services the institution identifies as appropriate for its mission and student needs. (ER 15, ER 17)]</li>
    <li>To serve as evidence for Accreditation STANDARD 2.8: The institution conducts systematic review and assessment to ensure the quality of its academic, learning support, and student services programs and implement improvements and innovations in support of equitable student achievement. (ER 11, ER 14)]</li>
    <li>To serve as evidence for Accreditation STANDARD 2.9: The institution fosters a sense of belonging and community with its students by providing multiple opportunities for engagement with the institution, programs, and peers. Such opportunities reflect the varied needs of the student population and effectively support students’ unique educational journeys. (ER 15)]</li>
    <li>To evaluate the effectiveness of the student support services available to Chaffey students</li>
    <li>To use the analysis of success metrics and equity data to inform strategic planning</li>
</ol>
<div class="fs-4">Summary of Key Takeaways and Conclusions</div>',1,NULL,2,2,1,30,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7533,1,7534,'Student Center Funding Formula:',1,'Check any of the success metrics for which there is data for the students/populations your area serves. A textbox will appear once you check a box. Describe trends in these metrics in the area and identify equity disparities in this box.',0,NULL,0,0,1,32,82,NULL,NULL,NULL,0,1912,NULL,NULL,NULL,1,0,NULL)
,
(7534,1,7528,'Check any of the success metrics for which there is data for the students/populations your area serves. A textbox will appear once you check a box. Describe trends in these metrics in the area and identify equity disparities in this box.',1,NULL,0,NULL,4,4,1,1,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7535,1,7532,'Please describe any trends in access to the services your area provides:',1,NULL,0,NULL,0,0,1,1,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7536,1,7532,'After considering the discussions held during the data-coaching session, please summarize any key findings:',1,NULL,0,NULL,1,1,1,1,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7537,1,7528,'Data files (Required)',1,NULL,0,NULL,0,5,1,1,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7538,1,7528,'Records of data coaching sessions (Required)',1,NULL,0,NULL,1,6,1,1,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7539,1,7528,'Other supporting documentation of data analysis (Optional)',1,NULL,0,NULL,2,7,1,1,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7540,1,7532,NULL,1,NULL,0,NULL,2,2,1,1,82,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
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
(7888,1,1,'LabelWidth','95',7525)
,
(7889,1,1,'Tier2ForeignKeyField','Active_ProgramId',7525)
,
(7890,1,1,'Tier2CascadeColumn','Id',7525)
,
(7891,1,1,'Tier2FilterColumn','OrganizationEntityId',7525)
,
(7892,1,1,'Tier2IdColumn','Id',7525)
,
(7893,1,1,'Tier2Table','ModuleDetail',7525)
,
(7894,1,1,'Tier1ForeignKeyField','Tier2_OrganizationEntityId',7525)
,
(7895,1,1,'Tier1CascadeColumn','Id',7525)
,
(7896,1,1,'Tier1FilterColumn','Parent_OrganizationEntityId',7525)
,
(7897,1,1,'Tier1IdColumn','Id',7525)
,
(7898,1,1,'Tier1Table','ModuleDetail',7525)
,
(7899,1,1,'Tier0ForeignKeyField','Tier1_OrganizationEntityId',7525)
,
(7900,1,1,'Tier0CascadeColumn','Id',7525)
,
(7901,1,1,'Tier0IdColumn','Id',7525)
,
(7902,1,1,'Tier0Table','ModuleDetail',7525)
,
(7903,1,1,'AttachmentType','13',7529)
,
(7904,1,1,'AttachmentType','14',7530)
,
(7905,1,1,'AttachmentType','15',7531)
,
(7906,1,1,'lookuptablename','ModuleLookup08',7533)
,
(7907,1,1,'lookupcolumnname','Lookup08Id',7533)
,
(7908,1,1,'AttachmentType','13',7537)
,
(7909,1,1,'AttachmentType','14',7538)
,
(7910,1,1,'AttachmentType','15',7539)
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
(1,68,'YesNo','Id','Title','select Id as Value, Title as Text from YesNo where id = 1','Select Title as Text from YesNo Where id = @id',NULL,'Yes Dropdown',1,NULL,NULL)
,
(2,80,'OrganizationEntity','Id','Title','
declare @tier1Orgs table(
	Value int,
	[Text] nvarchar(max)
);

insert into @tier1Orgs
exec uspOrganizationGetByUserAndTierOrder @clientId, @userId, 1;

select Value, [Text]
from @tier1Orgs t1o
inner join OrganizationEntity oe on t1o.Value = oe.Id
union
select oe.Id as Value, oe.Title as [Text]
from OrganizationEntity oe
where exists (
	select 1
	from ModuleDetail md
	where oe.Id = md.Tier1_OrganizationEntityId
	and md.ModuleId = @entityId
)
order by [Text];
','
select oe.Title as [Text]
from OrganizationEntity oe
where oe.Id = @id
','Order By SortOrder','Tier1_OrganizationEntityId',2,NULL,NULL)
,
(3,81,'OrganizationEntity','Id','Title','

declare @tierNOrgs table(
    Value int,
    [Text] nvarchar(max),
    FilterId int
);

    DECLARE @Parent_OrganizationEntityId2 int = (SELECT Tier1_OrganizationEntityId FROM ModuleDetail WHERE ModuleId = @EntityId);
    
    insert into @tierNOrgs
    exec spcOrganizationTierNOriginationList @clientId, @userId, @Parent_OrganizationEntityId2;

select tto.Value, tto.[Text], tto.FilterId
from @tierNOrgs tto
union
select oe.Id as Value
, oe.Title as [Text]
, ol.Parent_OrganizationEntityId
from OrganizationEntity oe
	inner join OrganizationLink ol on ol.Child_OrganizationEntityId = oe.Id and ol.Parent_OrganizationEntityId = @Parent_OrganizationEntityId2
where exists (
	select 1
	from ModuleDetail md
	where oe.Id in (md.Tier1_OrganizationEntityId, md.Tier2_OrganizationEntityId, md.Tier3_OrganizationEntityId)
	and md.ModuleId = @entityId
);

','
select oe.Title as [Text]
from OrganizationEntity oe
where oe.Id = @id
','Order By SortOrder','Tier2_OrganizationEntityId',3,NULL,NULL)
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
(12296,'Title',3880,7524,1,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12297,'Originator',3881,7524,0,NULL,NULL,1,0,1,'TelerikCombo',33,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12298,'Division',4122,7525,1,NULL,NULL,0,0,1,'TelerikCombo',33,450,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,80,NULL,NULL,NULL,NULL)
,
(12299,'Department/Area Name',4123,7525,1,NULL,NULL,1,0,1,'TelerikCombo',33,450,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,81,NULL,NULL,NULL,NULL)
,
(12300,'Co-Contributor',4366,7526,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12301,'Enter Program Budget Code',4146,7527,1,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12302,'Mime Type',4054,7529,0,NULL,NULL,3,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12303,'Disk Name',4053,7529,0,NULL,NULL,2,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12304,'Attached File Name',4051,7529,0,NULL,NULL,1,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12305,'Title',4052,7529,0,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12306,'Attachment Type',4055,7529,0,NULL,NULL,4,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12307,'Title',4052,7530,0,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12308,'Attached File Name',4051,7530,0,NULL,NULL,1,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12309,'Disk Name',4053,7530,0,NULL,NULL,2,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12310,'Mime Type',4054,7530,0,NULL,NULL,3,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12311,'Attachment Type',4055,7530,0,NULL,NULL,4,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12312,'Title',4052,7531,0,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12313,'Attached File Name',4051,7531,0,NULL,NULL,1,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12314,'Disk Name',4053,7531,0,NULL,NULL,2,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12315,'Mime Type',4054,7531,0,NULL,NULL,3,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12316,'Attachment Type',4055,7531,0,NULL,NULL,4,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12317,'Success Metric',5002,7533,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12318,'Describe trends in this metric in the area and identify equity disparities',5012,7533,0,NULL,NULL,1,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12328,'I have reviewed this tab',5204,7534,1,NULL,NULL,1,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,68,NULL,NULL,NULL,NULL)
,
(12319,'Are there any disparities in equity of access to the services your area provides, and can any conclusions be drawn as to why the number of users identified as belonging to a special population or community is increasing, decreasing, or stagnant?',2552,7535,1,NULL,NULL,0,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12320,'Are any means or modalities of accessing services more/less successful than others, and are some services or modalities used more often by a specific population of students?',2553,7535,1,NULL,NULL,1,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12321,'Areas of improvement and/or unmet needs',2554,7536,1,NULL,NULL,0,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12322,'Areas of success or effective outreach',2555,7536,1,NULL,NULL,1,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12323,'Other (optional)',2556,7536,0,NULL,NULL,2,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12325,'Additional Comments',2558,7537,0,NULL,NULL,1,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12326,'Additional Comments',2559,7538,0,NULL,NULL,1,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12327,'Additional Comments',2560,7539,0,NULL,NULL,1,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(12324,'Based on the current understanding of your data collection and assessment processes, are there adjustments, strategies, or innovations that should be considered for improvement moving forward?',2557,7540,1,NULL,NULL,0,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
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
(4398,'FilterSubscriptionColumn','Tier1_OrganizationEntityId',12299)
,
(4399,'FilterSubscriptionName','Parent_OrganizationEntityId',12299)
,
(4400,'FilterSubscriptionTable','ModuleDetail',12299)
,
(4401,'FieldSpecialization','UploadMimetypeField',12302)
,
(4402,'FieldSpecialization','UploadDiscnameField',12303)
,
(4403,'FieldSpecialization','UploadFilenameField',12304)
,
(4404,'FieldSpecialization','UploadTextnameField',12305)
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
(159,82,12296,0)
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

		
	-- Get MetASqlStatement
	DECLARE  @MetASqlStatementTempTable Table
	(MetASqlStatement_Id NVARCHAR(MAX),MetASqlStatement_SqlStatement NVARCHAR(MAX),MetASqlStatement_SqlStatementTypeId NVARCHAR(MAX));
	

	INSERT INTO @MetASqlStatementTempTable
	(MetASqlStatement_Id,MetASqlStatement_SqlStatement,MetASqlStatement_SqlStatementTypeId)
	OUTPUT INSERTED.*
	 VALUES
	
(17,'if(
(select count(Id) from ModuleAttachedFile where ModuleId = @entityId and AttachmentTypeId = (select Id from AttachmentType where Title = ''Student Support Data Files'')) > 0
AND
(select count(Id) from ModuleAttachedFile where ModuleId = @entityId and AttachmentTypeId = (select Id from AttachmentType where Title = ''Student Support Data Coaching'')) > 0
)
select 1 
else
select 0',1)
;
-- INSERT MetASqlStatement INTO Destination Database

	


	;WITH SourceData AS
	( 

	SELECT MetASqlStatement_Id,MetASqlStatement_SqlStatement,MetASqlStatement_SqlStatementTypeId
	FROM @MetASqlStatementTempTable tt
	)

	MERGE INTO MetASqlStatement
	USING SourceData sd ON (1 = 0)
	WHEN Not Matched By Target THEN

	INSERT (SqlStatement,SqlStatementTypeId)
	VALUES (sd.MetASqlStatement_SqlStatement,sd.MetASqlStatement_SqlStatementTypeId)

	OUTPUT 'MetASqlStatement',sd.MetASqlStatement_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);
	--OUTPUT 'MetASqlStatement',INSERTED.* 
	;

--============================End MetASqlStatement============================


--============================Begin MetaControlAttribute==========================

		
		-- Get MetaControlAttribute
		DECLARE  @MetaControlAttributeTempTable Table
		(MetaControlAttribute_MetaSelectedSectionId NVARCHAR(MAX),MetaControlAttribute_Name NVARCHAR(MAX),MetaControlAttribute_Description NVARCHAR(MAX),MetaControlAttribute_MetaSelectedFieldId NVARCHAR(MAX),MetaControlAttribute_MetaControlAttributeTypeId NVARCHAR(MAX),MetaControlAttribute_MetaAttributeComparisonTypeId NVARCHAR(MAX),MetaControlAttribute_TargetValue NVARCHAR(MAX),MetaControlAttribute_TotalCount NVARCHAR(MAX),MetaControlAttribute_CustomMessage NVARCHAR(MAX),MetaControlAttribute_MetASqlStatementId NVARCHAR(MAX));
		

		INSERT INTO @MetaControlAttributeTempTable

		(MetaControlAttribute_MetaSelectedSectionId,MetaControlAttribute_Name,MetaControlAttribute_Description,MetaControlAttribute_MetaSelectedFieldId,MetaControlAttribute_MetaControlAttributeTypeId,MetaControlAttribute_MetaAttributeComparisonTypeId,MetaControlAttribute_TargetValue,MetaControlAttribute_TotalCount,MetaControlAttribute_CustomMessage,MetaControlAttribute_MetASqlStatementId)
		OUTPUT INSERTED.*
		 VALUES
		
(7528,'Student Support Attached Files','Require attachment',NULL,6,NULL,NULL,NULL,'At least one Data file and one Record of data coaching sessions is required for this Program Review.',17)
;
-- INSERT MetaControlAttribute INTO Destination Database

	

	;WITH SourceData AS
	( 

	SELECT kt.NewId AS MetaControlAttribute_MetaSelectedSectionId,MetaControlAttribute_Name,MetaControlAttribute_Description,kt2.NewId AS MetaControlAttribute_MetaSelectedFieldId,MetaControlAttribute_MetaControlAttributeTypeId,MetaControlAttribute_MetaAttributeComparisonTypeId,MetaControlAttribute_TargetValue,MetaControlAttribute_TotalCount,MetaControlAttribute_CustomMessage,kt3.NewId AS MetaControlAttribute_MetASqlStatementId
	FROM @MetaControlAttributeTempTable tt
	LEFT JOIN #KeyTranslation kt ON tt.MetaControlAttribute_MetaSelectedSectionId = kt.OldId
		AND kt.DestinationTable = 'MetaSelectedSEction'
	LEFT JOIN #KeyTranslation kt2 ON tt.MetaControlAttribute_MetaSelectedFieldId = kt2.OldId
		AND kt2.DestinationTable = 'MetaSelectedField'
	LEFT JOIN #KeyTranslation kt3 ON tt.MetaControlAttribute_MetASqlStatementId = kt3.OldId
		AND kt3.DestinationTable = 'MetASqlStatement'
	)

	MERGE INTO MetaControlAttribute
	USING SourceData sd ON (1 = 0)
	WHEN Not Matched By Target THEN

	INSERT (MetaSelectedSectionId,Name,Description,MetaSelectedFieldId,MetaControlAttributeTypeId,MetaAttributeComparisonTypeId,TargetValue,TotalCount,CustomMessage,MetASqlStatementId)
	VALUES (sd.MetaControlAttribute_MetaSelectedSectionId,sd.MetaControlAttribute_Name,sd.MetaControlAttribute_Description,sd.MetaControlAttribute_MetaSelectedFieldId,sd.MetaControlAttribute_MetaControlAttributeTypeId,sd.MetaControlAttribute_MetaAttributeComparisonTypeId,sd.MetaControlAttribute_TargetValue,sd.MetaControlAttribute_TotalCount,sd.MetaControlAttribute_CustomMessage,sd.MetaControlAttribute_MetASqlStatementId)

	--OUTPUT 'MetaControlAttribute',sd.MetaControlAttribute_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);
	OUTPUT 'MetaControlAttribute',INSERTED.* ;

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

--Commit