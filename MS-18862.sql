
	/************************************************************************************************
	***                               Insertion of Extracted Script                          
	***                                                                                       
	***                                                                                       
	*** Created with the Template Configuration Extract Script and SQL Generator (version 2022.12.14)        
	***                                                                                       
	*** Script generated on Mar 19 2025 11:27AM                                              
	***                                                                                       
	*** Source Client: St. Petersburg College                                                                 
	*** Source Template: 40                                                              
	*** Source Template Name: Industry Certificate Program             
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

Use stpetersburg;

DECLARE @JiraTicketNumber NVARCHAR(20) = 'MS-18862';
DECLARE @Comments NVARCHAR(MAX) = 'Create Industry Certificate Program Form';
DECLARE @Developer NVARCHAR(50) = 'Nate W';
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
DECLARE @SourceDatabase NVARCHAR(100) = 'stpetersburg';
DECLARE @SourceTemplateTypeId Int = 30;
DECLARE @SourceTemplateId int  = 40;
DECLARE @InsertToMetaTemplateId int ; --Set this if inserting sections into a different template Id from the extrated template
DECLARE @InsertToMetaTemplateTypeId int ; --Set this if inserting sections into a different template type Id from the extrated template
DECLARE @SourceParentSectionId int ; --Do not set this variable
DECLARE @TargetParentSectionId int ; --Do not set this here set it below if necessary
DECLARE @ClientEntityType NVARCHAR(100) = 'Program';
 
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

--==================================================Look up DATA=========================
INSERT INTO ItemType
(Title, ItemTableName, SortOrder, StartDate, ClientId, Description)
VALUES
('New certification', 'ProgramLookup01', 12, GETDATE(), 1, 'Industry'),
('Title change', 'ProgramLookup01', 12, GETDATE(), 1, 'Industry'),
('Course(s) added/removed', 'ProgramLookup01', 12, GETDATE(), 1, 'Industry'),
('Program description', 'ProgramLookup01', 12, GETDATE(), 1, 'Industry'),
('Articulation(s)', 'ProgramLookup01', 12, GETDATE(), 1, 'Industry'),
('Other', 'ProgramLookup01', 12, GETDATE(), 1, 'Industry')

INSERT INTO ListSequenceNumber
(IntSequence, SortOrder, StartDate, ClientId)
VALUES
(1, 1, GETDATE(), 1),
(2, 2, GETDATE(), 1),
(3, 3, GETDATE(), 1),
(4, 4, GETDATE(), 1),
(5, 5, GETDATE(), 1)

--==================================================End Look up DATA=========================

--========================Begin Client Entity Type==============================
		
		/* Get ClientEntityType */
		DECLARE  @ClientEntityTypeTempTable Table
		(ClientEntityType_Id NVARCHAR(MAX),ClientEntityType_ClientId NVARCHAR(MAX),ClientEntityType_EntityTypeId NVARCHAR(MAX),ClientEntityType_SortOrder NVARCHAR(MAX),ClientEntityType_Title NVARCHAR(MAX),ClientEntityType_OrganizationConnectionStrategyId NVARCHAR(MAX),ClientEntityType_ProposalInterlockStrategyId NVARCHAR(MAX),ClientEntityType_Active NVARCHAR(MAX),ClientEntityType_PluralTitle NVARCHAR(MAX),ClientEntityType_ShortTitle NVARCHAR(MAX),ClientEntityType_EquivalencyGroup NVARCHAR(MAX),ClientEntityType_EntitySpecializationTypeId NVARCHAR(MAX),ClientEntityType_PublicSearchVisible NVARCHAR(MAX),ClientEntityType_ClientEntityTypeGroupId NVARCHAR(MAX));
		

		INSERT INTO @ClientEntityTypeTempTable
		(ClientEntityType_Id,ClientEntityType_ClientId,ClientEntityType_EntityTypeId,ClientEntityType_SortOrder,ClientEntityType_Title,ClientEntityType_OrganizationConnectionStrategyId,ClientEntityType_ProposalInterlockStrategyId,ClientEntityType_Active,ClientEntityType_PluralTitle,ClientEntityType_ShortTitle,ClientEntityType_EquivalencyGroup,ClientEntityType_EntitySpecializationTypeId,ClientEntityType_PublicSearchVisible,ClientEntityType_ClientEntityTypeGroupId)
		--OUTPUT INSERTED.*
		VALUES
(2,1,2,2,'Program',2,1,1,'Programs',NULL,6,NULL,1,NULL)
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
		
-- Get ClientEntitySubType
DECLARE  @ClientEntitySubTypeTempTable Table
(ClientEntitySubType_Id NVARCHAR(MAX),ClientEntitySubType_EntityTypeId NVARCHAR(MAX),ClientEntitySubType_SortOrder NVARCHAR(MAX),ClientEntitySubType_Title NVARCHAR(MAX),ClientEntitySubType_ClientId NVARCHAR(MAX),ClientEntitySubType_OrganizationConnectionStrategyId NVARCHAR(MAX),ClientEntitySubType_ProposalInterlockStrategyId NVARCHAR(MAX),ClientEntitySubType_ClientEntityTypeId NVARCHAR(MAX),ClientEntitySubType_Active NVARCHAR(MAX),ClientEntitySubType_PluralTitle NVARCHAR(MAX),ClientEntitySubType_ClientEntitySubTypeGroupId NVARCHAR(MAX),ClientEntitySubType_EquivalencyGroup NVARCHAR(MAX),ClientEntitySubType_EntitySpecializationTypeId NVARCHAR(MAX),ClientEntitySubType_PublicSearchVisible NVARCHAR(MAX));

INSERT INTO @ClientEntitySubTypeTempTable
(ClientEntitySubType_Id,ClientEntitySubType_EntityTypeId,ClientEntitySubType_SortOrder,ClientEntitySubType_Title,ClientEntitySubType_ClientId,ClientEntitySubType_OrganizationConnectionStrategyId,ClientEntitySubType_ProposalInterlockStrategyId,ClientEntitySubType_ClientEntityTypeId,ClientEntitySubType_Active,ClientEntitySubType_PluralTitle,ClientEntitySubType_ClientEntitySubTypeGroupId,ClientEntitySubType_EquivalencyGroup,ClientEntitySubType_EntitySpecializationTypeId,ClientEntitySubType_PublicSearchVisible)
--OUTPUT INSERTED.*
 VALUES
(2,2,2,'Program',1,2,1,2,1,'Programs',NULL,NULL,NULL,1)
;

IF (SELECT COUNT(*) FROM @ClientEntitySubTypeTempTable) > 0
BEGIN 
-- INSERT ClientEntitySubType INTO Destination Database
;WITH SourceData AS
( 
SELECT ClientEntitySubType_Id,ClientEntitySubType_EntityTypeId,ClientEntitySubType_SortOrder,ClientEntitySubType_Title,ClientEntitySubType_ClientId,ClientEntitySubType_OrganizationConnectionStrategyId,ClientEntitySubType_ProposalInterlockStrategyId,kt.NewId AS ClientEntitySubType_ClientEntityTypeId,ClientEntitySubType_Active,ClientEntitySubType_PluralTitle,ClientEntitySubType_ClientEntitySubTypeGroupId,ClientEntitySubType_EquivalencyGroup,ClientEntitySubType_EntitySpecializationTypeId,ClientEntitySubType_PublicSearchVisible
FROM @ClientEntitySubTypeTempTable tt
LEFT JOIN #KeyTranslation kt ON tt.ClientEntitySubType_ClientEntityTypeId = kt.OldId
	AND kt.DestinationTable = 'ClientEntityType'
)
MERGE INTO ClientEntitySubType
USING SourceData sd ON 
	ClientId = ClientEntitySubType_ClientId
	AND Title = ClientEntitySubType_Title
WHEN Not Matched By Target THEN
INSERT (EntityTypeId,SortOrder,Title,ClientId,OrganizationConnectionStrategyId,ProposalInterlockStrategyId,ClientEntityTypeId,Active,PluralTitle,ClientEntitySubTypeGroupId,EquivalencyGroup,EntitySpecializationTypeId,PublicSearchVisible)
VALUES (sd.ClientEntitySubType_EntityTypeId,sd.ClientEntitySubType_SortOrder,sd.ClientEntitySubType_Title,@ClientId,sd.ClientEntitySubType_OrganizationConnectionStrategyId,sd.ClientEntitySubType_ProposalInterlockStrategyId,sd.ClientEntitySubType_ClientEntityTypeId,sd.ClientEntitySubType_Active,sd.ClientEntitySubType_PluralTitle,sd.ClientEntitySubType_ClientEntitySubTypeGroupId,sd.ClientEntitySubType_EquivalencyGroup,sd.ClientEntitySubType_EntitySpecializationTypeId,sd.ClientEntitySubType_PublicSearchVisible)
WHEN Matched THEN UPDATE
SET Title = sd.ClientEntitySubType_Title
OUTPUT 'ClientEntitySubType',sd.ClientEntitySubType_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);
END;

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
(30,'Industry Certificate Program','Program','Id',2,1,0,0,2,NULL)
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
(ProposalType_Id NVARCHAR(MAX),ProposalType_ClientId NVARCHAR(MAX),ProposalType_Title NVARCHAR(MAX),ProposalType_EntityTypeId NVARCHAR(MAX),ProposalType_ClientEntitySubTypeId NVARCHAR(MAX),ProposalType_ProcessActionTypeId NVARCHAR(MAX),ProposalType_MetaTemplateTypeId NVARCHAR(MAX),ProposalType_Active NVARCHAR(MAX),ProposalType_DeletedBy_UserId NVARCHAR(MAX),ProposalType_DeletedDate NVARCHAR(MAX),ProposalType_Presentation_MetaTemplateTypeId NVARCHAR(MAX),ProposalType_AvailableForLookup NVARCHAR(MAX),ProposalType_AllowReactivation NVARCHAR(MAX),ProposalType_AllowMultipleApproved NVARCHAR(MAX),ProposalType_ReactivationRequired NVARCHAR(MAX),ProposalType_AwardLevelId NVARCHAR(MAX),ProposalType_ClientEntityTypeId NVARCHAR(MAX),ProposalType_Code NVARCHAR(MAX),ProposalType_CloneRequired NVARCHAR(MAX),ProposalType_AllowDistrictClone NVARCHAR(MAX),ProposalType_AllowCloning NVARCHAR(MAX),ProposalType_MaxClone NVARCHAR(MAX),ProposalType_Instructions NVARCHAR(MAX),ProposalType_HideProposalRequirementFields NVARCHAR(MAX),ProposalType_PluralTitle NVARCHAR(MAX));

INSERT INTO @ProposalTypeTempTable

(ProposalType_Id,ProposalType_ClientId,ProposalType_Title,ProposalType_EntityTypeId,ProposalType_ClientEntitySubTypeId,ProposalType_ProcessActionTypeId,ProposalType_MetaTemplateTypeId,ProposalType_Active,ProposalType_DeletedBy_UserId,ProposalType_DeletedDate,ProposalType_Presentation_MetaTemplateTypeId,ProposalType_AvailableForLookup,ProposalType_AllowReactivation,ProposalType_AllowMultipleApproved,ProposalType_ReactivationRequired,ProposalType_AwardLevelId,ProposalType_ClientEntityTypeId,ProposalType_Code,ProposalType_CloneRequired,ProposalType_AllowDistrictClone,ProposalType_AllowCloning,ProposalType_MaxClone,ProposalType_Instructions,ProposalType_HideProposalRequirementFields,ProposalType_PluralTitle)
--OUTPUT INSERTED.*
 VALUES
(51,1,'Industry Certificate',2,2,1,30,1,NULL,NULL,NULL,0,0,0,0,NULL,2,'DC25D6CC-FB86-4474-9FCB-F56A17740A35',0,0,0,NULL,NULL,0,NULL)
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
SELECT ProposalType_Id,ProposalType_ClientId,ProposalType_Title,ProposalType_EntityTypeId,COALESCE(kt.NewId, ProposalType_ClientEntitySubTypeId) AS ProposalType_ClientEntitySubTypeId,ProposalType_ProcessActionTypeId,kt2.NewId AS ProposalType_MetaTemplateTypeId,ProposalType_Active,ProposalType_DeletedBy_UserId,ProposalType_DeletedDate,ProposalType_Presentation_MetaTemplateTypeId,ProposalType_AvailableForLookup,ProposalType_AllowReactivation,ProposalType_AllowMultipleApproved,ProposalType_ReactivationRequired,kt3.NewId AS ProposalType_AwardLevelId,COALESCE(kt1.NewId,@ClientEntityTypeId) AS ProposalType_ClientEntityTypeId, ProposalType_Code, ProposalType_CloneRequired, ProposalType_AllowDistrictClone, ProposalType_AllowCloning, ProposalType_MaxClone,ProposalType_Instructions,ProposalType_HideProposalRequirementFields,ProposalType_PluralTitle
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
INSERT (ClientId,Title,EntityTypeId,ClientEntitySubTypeId,ProcessActionTypeId,MetaTemplateTypeId,Active,DeletedBy_UserId,DeletedDate,Presentation_MetaTemplateTypeId,AvailableForLookup,AllowReactivation,AllowMultipleApproved,ReactivationRequired,AwardLevelId,ClientEntityTypeId,/*Code,*/CloneRequired,AllowDistrictClone,AllowCloning,MaxClone,Instructions,HideProposalRequirementFields,PluralTitle)
VALUES (@ClientId,sd.ProposalType_Title,sd.ProposalType_EntityTypeId,sd.ProposalType_ClientEntitySubTypeId,sd.ProposalType_ProcessActionTypeId,sd.ProposalType_MetaTemplateTypeId,sd.ProposalType_Active,sd.ProposalType_DeletedBy_UserId,sd.ProposalType_DeletedDate,sd.ProposalType_Presentation_MetaTemplateTypeId,sd.ProposalType_AvailableForLookup,sd.ProposalType_AllowReactivation,sd.ProposalType_AllowMultipleApproved,sd.ProposalType_ReactivationRequired,sd.ProposalType_AwardLevelId,sd.ProposalType_ClientEntityTypeId,/*sd.ProposalType_Code,*/sd.ProposalType_CloneRequired,sd.ProposalType_AllowDistrictClone,sd.ProposalType_AllowCloning,sd.ProposalType_MaxClone,sd.ProposalType_Instructions,sd.ProposalType_HideProposalRequirementFields,sd.ProposalType_PluralTitle)
OUTPUT 'ProposalType',sd.ProposalType_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);

INSERT INTO ClientEntitySubType
(EntityTypeId, SortOrder,Title, ClientId, OrganizationConnectionStrategyId, ProposalInterlockStrategyId, ClientEntityTypeId,Active, PluralTitle, PublicSearchVisible)
VALUES
(2, 3, 'Industry', 1, 2, 1, 2, 1, 'Industries', 1)

DECLARE @SubType int = SCOPE_IDENTITY()

UPDATE ProposalType
SET ClientEntitySubTypeId = @SubType
WHERE Title = 'Industry Certificate'
and Active = 1

--===========================End Proposal Type==================================


--=======================Begin Process Proposal Type=============================

		
-- Get processProposalType
DECLARE  @processProposalTypeTempTable Table
(ProcessProposalType_Id NVARCHAR(MAX),ProcessProposalType_ProposalTypeId NVARCHAR(MAX),ProcessProposalType_ProcessId NVARCHAR(MAX));

INSERT INTO @processProposalTypeTempTable

(ProcessProposalType_Id,ProcessProposalType_ProposalTypeId,ProcessProposalType_ProcessId)
OUTPUT INSERTED.*
 VALUES
(47,51,17)
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
(40,30,'Mar 19 2025  9:00AM',1,744,'Mar 19 2025  9:19AM',NULL,'Industry Certificate Program',1,'Mar 19 2025 11:26AM',NULL,NULL,0,'[0] ([1])','[0] ([1])')
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
	
(1520,1,1981,'Which course(s) relate to this Certification?',1,NULL,0,NULL,3,3,1,31,40,NULL,NULL,NULL,0,857,NULL,NULL,NULL,1,0,NULL)
,
(1650,1,1959,'Which program(s) does this program articulate to?',1,NULL,0,NULL,6,6,1,18,40,NULL,NULL,NULL,0,217,NULL,NULL,NULL,1,0,NULL)
,
(1652,1,2038,'Program Contact Information',1,NULL,0,NULL,1,1,1,500,40,NULL,NULL,NULL,0,1224,NULL,NULL,NULL,1,0,NULL)
,
(1959,1,NULL,'Basic Program Information',1,NULL,0,NULL,0,0,1,15,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1960,1,NULL,'Co-Contributor(s)',1,'A co-contributor has editing capabilities on draft proposals; however, only the originator can launch proposals or 
	shepherd them through the approval process by responding to requests for changes.',1,NULL,2,2,1,15,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1962,1,NULL,'Attachments',1,'<p style="color:red; font-size:1.5em">Attach any required or supporting documents here. 
	Supported file types include Word, PDF, Excel, and other similar file types.</p>',1,NULL,8,8,1,15,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1964,1,1959,'Program Information',1,NULL,0,NULL,0,0,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1965,1,1959,'Proposal Information',1,NULL,0,NULL,3,3,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1966,1,1959,NULL,0,NULL,0,NULL,5,5,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1970,1,1959,NULL,0,NULL,0,NULL,2,2,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1972,1,1979,'
',1,NULL,0,NULL,0,0,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1974,1,1980,NULL,1,NULL,0,NULL,0,0,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1975,1,1980,'Academic course progression to final eligibility course (if applicable)',1,NULL,0,NULL,1,1,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1979,1,NULL,'Overview',1,NULL,0,NULL,4,4,1,15,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1980,1,NULL,'Eligibility',1,NULL,0,NULL,5,5,1,30,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1981,1,NULL,'Programs',1,NULL,0,NULL,3,3,1,15,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(1991,1,1959,'
',0,NULL,0,NULL,1,1,1,22,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2002,1,1960,'Co-Contributor(s)',1,NULL,0,NULL,0,0,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2006,1,1962,NULL,1,NULL,0,NULL,1,1,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2015,1,1962,'Attached File',1,NULL,0,NULL,0,0,1,14,40,NULL,NULL,NULL,0,143,NULL,NULL,NULL,1,0,NULL)
,
(2029,1,1959,'What is being changed on this program?  Please mark all that apply',1,'Please be sure to note each item in the Rationale below.',1,NULL,4,4,1,3,40,NULL,NULL,NULL,0,1816,NULL,NULL,NULL,1,0,NULL)
,
(2038,1,NULL,'Contact Information',1,NULL,0,NULL,1,1,1,30,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2039,1,NULL,'Expectations and Considerations',1,NULL,0,NULL,6,6,1,30,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2040,1,NULL,'Other Requirements and Information',1,NULL,0,NULL,7,7,1,30,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2041,1,NULL,'Codes and Dates',1,NULL,0,NULL,9,9,1,15,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2042,1,2041,'Approval Dates/Proposal Information',1,NULL,0,NULL,1,0,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2043,1,2040,NULL,1,NULL,0,NULL,0,0,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2044,1,2039,NULL,1,NULL,0,NULL,0,0,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2045,1,2038,NULL,1,NULL,0,NULL,0,0,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2047,1,1959,NULL,1,NULL,0,NULL,7,6,1,1,40,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(2048,1,1980,'Requirements',1,'<ol>
    <li>Successfully complete the required course(s) and meet any eligibility requirements.</li>
    <li>Receive Opt-In form invite from your instructor.</li>
    <li>File the Opt-In form.</li>
    <li>Receive Test Prep Toolkit email or Next Step email from the Get Certified Team.</li>
    <li>Complete action items from email(s) received, including comprehensive exam prep.</li>
    <li>Aim to earn 90% or above on comprehensive practice exams and applicable labs.</li>
    <li>Now you are ready to file the Claim Your Voucher form.</li>
    <li>Receive Voucher Included email or Next Step email from the Get Certified Team.</li>
    <li>Schedule exam appointment to get certified within ~30-days of receiving voucher code.</li>
    <li>After the exam, send Score Report to <a target="_blank" href="GetCertified@spcollege.edu">GetCertified@spcollege.edu.</a> (Required for grant reporting.)</li>
</ol>',1,NULL,2,2,1,31,40,NULL,NULL,NULL,0,366,NULL,NULL,NULL,1,0,NULL)
,
(2049,1,1520,'Articulation Agreements',1,NULL,0,NULL,6,6,1,32,40,NULL,NULL,NULL,0,2714,NULL,NULL,NULL,1,0,NULL)
,
(2050,1,1520,'SPC Certificates',1,NULL,0,NULL,8,8,1,32,40,NULL,NULL,NULL,0,2714,NULL,NULL,NULL,1,0,NULL)
,
(2051,1,1520,'SPC Degrees',1,NULL,0,NULL,10,10,1,32,40,NULL,NULL,NULL,0,2714,NULL,NULL,NULL,1,0,NULL)
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
(1836,1,1,'AllowCalcOverride','TRUE',1520)
,
(1837,1,1,'AllowConditions','TRUE',1520)
,
(2007,1,1,'TitleTable','ProgramEntityContact',1652)
,
(2008,1,1,'TitleColumn','ContactName',1652)
,
(2009,1,1,'SortOrderTable','ProgramEntityContact',1652)
,
(2010,1,1,'SortOrderColumn','SortOrder',1652)
,
(2011,1,1,'LableWidth','150',1652)
,
(2012,1,1,'ShowDetails','True',1652)
,
(2480,1,1,'LabelWidth','180',1964)
,
(2470,1,1,'LabelWidth','130',1991)
,
(2471,1,1,'Tier1ForeignKeyField','Tier2_OrganizationEntityId',1991)
,
(2472,1,1,'Tier1FilterColumn','Parent_OrganizationEntityId',1991)
,
(2473,1,1,'Tier1IdColumn','Id',1991)
,
(2474,1,1,'Tier1Table','Program',1991)
,
(2475,1,1,'Tier0ForeignKeyField','Tier1_OrganizationEntityId',1991)
,
(2476,1,1,'Tier0CascadeColumn','Id',1991)
,
(2477,1,1,'Tier0IdColumn','Id',1991)
,
(2478,1,1,'Tier0Table','Program',1991)
,
(2467,1,1,'AttachmentType','1',2015)
,
(2421,1,1,'ParentTable','Program',2029)
,
(2422,1,1,'ForeignKeyToParent','ProgramId',2029)
,
(2423,1,1,'LookupTable','ItemType',2029)
,
(2424,1,1,'ForeignKeyToLookup','ItemTypeId',2029)
,
(2517,1,1,'LabelWidth','300',2042)
,
(2518,1,1,'lookuptablename','ProgramSequenceProgram',2049)
,
(2519,1,1,'lookupcolumnname','Related_ProgramId',2049)
,
(2520,1,1,'lookuptablename','ProgramSequenceProgram',2050)
,
(2521,1,1,'lookupcolumnname','Related_ProgramId',2050)
,
(2522,1,1,'lookuptablename','ProgramSequenceProgram',2051)
,
(2523,1,1,'lookupcolumnname','Related_ProgramId',2051)
,
(2524,1,1,'listitemtype','1',2051)
,
(2525,1,1,'listitemtype','1',2050)
,
(2526,1,1,'listitemtype','1',2049)
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

	
		
-- Get MetaSelectedSectionSetting
DECLARE  @MetaSelectedSectionSettingTempTable Table
(MetaSelectedSectionSetting_Id NVARCHAR(MAX),MetaSelectedSectionSetting_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedSectionSetting_IsRequired NVARCHAR(MAX),MetaSelectedSectionSetting_MinElem NVARCHAR(MAX),MetaSelectedSectionSetting_MaxElem NVARCHAR(MAX),MetaSelectedSectionSetting_LabelWidth NVARCHAR(MAX),MetaSelectedSectionSetting_Height NVARCHAR(MAX));

INSERT INTO @MetaSelectedSectionSettingTempTable
(MetaSelectedSectionSetting_Id,MetaSelectedSectionSetting_MetaSelectedSectionId,MetaSelectedSectionSetting_IsRequired,MetaSelectedSectionSetting_MinElem,MetaSelectedSectionSetting_MaxElem,MetaSelectedSectionSetting_LabelWidth,MetaSelectedSectionSetting_Height)
OUTPUT INSERTED.*
VALUES
(86,1650,1,1,NULL,NULL,NULL)
;
-- INSERT MetaSelectedSectionSetting INTO Destination Database


;WITH SourceData AS
( 
SELECT MetaSelectedSectionSetting_Id,kt.NewId AS MetaSelectedSectionSetting_MetaSelectedSectionId,MetaSelectedSectionSetting_IsRequired,MetaSelectedSectionSetting_MinElem,MetaSelectedSectionSetting_MaxElem,MetaSelectedSectionSetting_LabelWidth,MetaSelectedSectionSetting_Height
FROM @MetaSelectedSectionSettingTempTable tt 
INNER JOIN #KeyTranslation kt ON MetaSelectedSectionSetting_MetaSelectedSectionId =kt.OldId
    AND DestinationTable = 'MetaSelectedSection'	
)
MERGE INTO MetaSelectedSectionSetting
USING SourceData sd ON (1 = 0)
WHEN Not Matched By Target THEN
INSERT (MetaSelectedSectionId,IsRequired,MinElem,MaxElem,LabelWidth,Height)
VALUES (sd.MetaSelectedSectionSetting_MetaSelectedSectionId,sd.MetaSelectedSectionSetting_IsRequired,sd.MetaSelectedSectionSetting_MinElem,sd.MetaSelectedSectionSetting_MaxElem,sd.MetaSelectedSectionSetting_LabelWidth,sd.MetaSelectedSectionSetting_Height);
--OUTPUT 'MetaSelectedSectionSetting',sd.MetaSelectedSectionSetting_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);

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
(1,29,'ProgramCode','Id','Title + '' - '' + TextCode','declare @now datetime = getdate(); select [Id] as [Value], Title as [Text] from [ProgramCode] where @now between StartDate and IsNull(EndDate, @now) AND ClientId = @clientId Order By SortOrder','select Title as [Text] from [ProgramCode] where Id = @id','Order By SortOrder',NULL,2,NULL,NULL)
,
(2,35,'Semester','Id','Title','declare @now datetime = getdate();
SELECT
	Id AS Value
   ,Title + 
	Case 
		WHEN Code = ''0'' THEN '' (0)''
		ELSE ''''
	END As Text,
	SortOrder
FROM [Semester]
WHERE @now BETWEEN StartDate AND ISNULL(EndDate, @now)
AND ClientId = 1
AND CatalogYear IS NOT NULL
UNION
SELECT s.Id AS Value
   ,s.Title + 
	Case 
		WHEN Code = ''0'' THEN '' (0)''
		ELSE ''''
	END As Text,
	SortOrder
FROM [Semester] s
	INNER JOIN ProgramProposal pp on s.id = pp.ActualBegin_SemesterId and pp.programId = @entityId
ORDER BY SortOrder DESC;','select Id AS Value
   ,Title + 
	Case 
		WHEN Code = ''0'' THEN '' (0)''
		ELSE ''''
	END As Text
from [Semester] s
where s.Id = @Id','Order By SortOrder','Semester for First term on program',2,NULL,NULL)
,
(3,47,'Program','Id','Title','
SELECT p.[id] as Value, COALESCE(p.EntityTitle,p.title) + '' *'' + sa.Title + ''*'' as Text 				
FROM  [program] P
	INNER JOIN [statusalias] sa on p.statusaliasid = sa.id 
    LEFT JOIN ProgramAssociation pa on pa.Associated_ProgramId = p.Id AND pa.ProgramId = @EntityId		
WHERE (sa.statusbaseid NOT IN (
		 3 --Draft
		,4 --Cancelled
		,5 --Historical
		,6 --Inactive
		,8 --deleted
		)	
	OR pa.Id IS NOT NULL)			
AND p.clientId = @ClientId 				
ORDER BY p.title;
','SELECT p.Id as Value, COALESCE(p.EntityTitle,p.title) + '' *'' + sa.title + ''*'' as Text
					FROM  [program] P
						INNER JOIN [statusalias] sa on p.statusaliasid = sa.id
					where p.Id = @Id',NULL,'Program Assocation query excluding Historical status',2,NULL,NULL)
,
(4,60,'Course','Id','Title','
		declare @subject int = (
			select SubjectId
			from ProgramSequence
			where Id = @pkIdValue
		)

		select c.Id as [Value]
			, concat(
				s.SubjectCode
				, '' ''
				, c.CourseNumber
				, '' - ''
				, c.Title
				, '' (''
				, sa.Title
				, '')'' 
			) as [Text]
			, s.Id as FilterValue
			, cd.Variable as IsVariable
			, cd.MinCreditHour as [Min]
			, cd.MaxCreditHour as [Max]
		from Course c
			inner join CourseDescription cd on c.Id = cd.CourseId
			inner join [Subject] s on c.SubjectId = s.Id
			inner join StatusAlias sa on c.StatusAliasId = sa.Id
		where (
			(
				c.Active = 1
				and sa.StatusBaseId in (
					1--Active
					, 2--Approved
					, 4--Draft
					, 6--In Review
			)
			)
			or exists (
				select 1
				from ProgramCourse pc
					inner join CourseOption co on pc.CourseOptionId = co.Id
				where co.ProgramId = @entityId
				and c.Id = pc.CourseId
			)
		)
		and s.Id = @subject
		order by [Text]
	','
		select concat(
				s.SubjectCode
				, '' ''
				, c.CourseNumber
				, '' - ''
				, c.Title
				, '' (''
				, sa.Title
				, '')'' 
			) as [Text]
			, s.Id as FilterValue
			, cd.Variable as IsVariable
			, cd.MinCreditHour as [Min]
			, cd.MaxCreditHour as [Max]
		from Course c
			inner join CourseDescription cd on c.Id = cd.CourseId
			inner join [Subject] s on c.SubjectId = s.Id
			inner join StatusAlias sa on c.StatusAliasId = sa.Id
		where c.Id = @id;
	','Order By SortOrder','Course Query Program Sequence',3,NULL,NULL)
,
(5,96,'ItemType','Id','Title','
select Id as Value, Title as Text from ItemType where Active = 1  AND ItemTableName = ''ProgramLookup01'' AND Description = ''Industry'' Order By SortOrder
','
select Id as Value, Title as Text from ItemType where Id = @Id
','Order By SortOrder','ItemType_ProgramLookup01',1,NULL,NULL)
,
(6,102,'Awardtype','Id','Title','SELECT AT.Id AS Value, AT.Title AS Text FROM AwardType at
WHERE AT.Active = 1
and Title NOT like ''%Articulation%''
Union
select [at].[Id] as [Value], at.Title as [Text] 
from [AwardType] at
inner join Program p ON P.AwardTypeId = AT.Id AND P.id = @EntityId;','select id as value, title as Text from Awardtype WHERe ID = @ID;','Order by SortOrder','GetAwardTypeWithoutCode',2,NULL,NULL)
,
(7,106,'Building','Id','IsNull(Location + '': '', '''') + IsNull(Code + '' - '', '''') + Title','
    select [Id] as [Value],  IsNull(Code + '' - '', '''') + Title as [Text] from [Building] 
    where (Active = 1) 
        and ([ClientId] = @clientId) 
        and Location = ''Articulations''
    Order By 2','select   IsNull(Code + '' - '', '''') + Title as [Text] from [Building] WHERE ID = @ID','Order By 2','Active Status for Articulations',2,NULL,NULL)
,
(8,115,'YesNo','Id','Title','SELECT 0 AS Value,
	CONCAT(''<b>Date Approved:</b> '', CONVERT(NVARCHAR(MAX), pv.ImperialCounty, 101), ''<br>'',''<b>Date Last Reviewed:</b> '', CONVERT(NVARCHAR(MAX), gd.Date01, 101), ''<br>'',''<b>Date Deactivated:</b> '', CONVERT(NVARCHAR(MAX), gd.Date03, 101), ''<br>'') AS Text
FROM ProgramVocational pv
	INNER JOIN GenericDate gd ON pv.ProgramId = gd.ProgramId
WHERE gd.ProgramId = @EntityId;','select Id as Value, Title as Text from YesNo Where id = @id','Order By SortOrder',NULL,2,NULL,NULL)
,
(9,120,'Semester','id','title','declare @now datetime = getdate();
SELECT
	Id AS Value
   ,Title + 
	Case 
		WHEN Code = ''0'' THEN '' (0)''
		ELSE ''''
	END As Text,
	SortOrder
FROM [Semester]
WHERE @now BETWEEN StartDate AND ISNULL(EndDate, @now)
AND ClientId = 1
AND CatalogYear IS NOT NULL
UNION
SELECT s.Id AS Value
   ,s.Title + 
	Case 
		WHEN Code = ''0'' THEN '' (0)''
		ELSE ''''
	END As Text,
	SortOrder
FROM [Semester] s
	INNER JOIN ProgramProposal pp on s.id = pp.SemesterId and pp.programId = @entityId
ORDER BY SortOrder DESC;','select Id AS Value
   ,s.Title + 
	Case 
		WHEN Code = ''0'' THEN '' (0)''
		ELSE ''''
	END As Text
from [Semester] s
where s.Id = @Id',NULL,'Semester for First term on Program',2,NULL,NULL)
,
(10,123,'Semester','id','title','declare @now datetime = getdate();
SELECT
	Id AS Value
   ,Title + 
	Case 
		WHEN Code = ''0'' THEN '' (0)''
		ELSE ''''
	END As Text,
	SortOrder
FROM [Semester]
WHERE @now BETWEEN StartDate AND ISNULL(EndDate, @now)
AND ClientId = 1
AND CatalogYear IS NOT NULL
UNION
SELECT s.Id AS Value
   ,s.Title + 
	Case 
		WHEN Code = ''0'' THEN '' (0)''
		ELSE ''''
	END As Text,
	SortOrder
FROM [Semester] s
	INNER JOIN programproposal pp on s.id = pp.LastAssessedSemesterId and pp.programid = @entityId
ORDER BY SortOrder DESC;','select Id AS Value
   ,s.Title + 
	Case 
		WHEN Code = ''0'' THEN '' (0)''
		ELSE ''''
	END As Text
from [Semester] s
where s.Id = @Id',NULL,'Semester for First term on Program',2,NULL,NULL)
,
(11,139,'Program','Id','Title','
SELECT p.Id AS Value,
EntityTitle AS Text
FROM Program AS p
WHERE p.AwardTypeId in (18, 19, 22, 23, 24, 25, 26) --Articulations
and (p.StatusAliasId = 1 or p.Id in (SELECT Related_ProgramId FROM ProgramSequenceProgram AS psp INNER JOIN ProgramSequence AS ps on psp.ProgramSequenceId = ps.Id WHERE ps.ProgramId = @EntityId))
and p.Active = 1
','
SELECT EntityTitle AS Text FROM Program WHERE Id = @Id
','Order By SortOrder','Look up programs',2,NULL,NULL)
,
(12,140,'Program','Id','Title','
SELECT p.Id AS Value,
EntityTitle AS Text
FROM Program AS p
WHERE p.AwardTypeId in (8, 9, 14, 20, 21) --Certificates
and (p.StatusAliasId = 1 or p.Id in (SELECT Related_ProgramId FROM ProgramSequenceProgram AS psp INNER JOIN ProgramSequence AS ps on psp.ProgramSequenceId = ps.Id WHERE ps.ProgramId = @EntityId))
and p.Active = 1
','
SELECT EntityTitle AS Text FROM Program WHERE Id = @Id
','Order By SortOrder','Look up programs',2,NULL,NULL)
,
(13,141,'Program','Id','Title','select
	0 as Value,
	convert(char(10), p.ImplementDate, 101) as Text
from Program pr
	inner join Proposal p on pr.ProposalId = p.Id
where pr.Id = @EntityId','select
	0 as Value,
	convert(char(10), p.ImplementDate, 101) as Text
from Program pr
	inner join Proposal p on pr.ProposalId = p.Id
where pr.Id = @EntityId',NULL,'Program Implementation',2,NULL,NULL)
,
(14,142,'Program','Id','Title','
SELECT p.Id AS Value,
EntityTitle AS Text
FROM Program AS p
WHERE p.AwardTypeId not in (8, 9, 14, 20, 21, 18, 19, 22, 23, 24, 25, 26) --Degrees
and (p.StatusAliasId = 1 or p.Id in (SELECT Related_ProgramId FROM ProgramSequenceProgram AS psp INNER JOIN ProgramSequence AS ps on psp.ProgramSequenceId = ps.Id WHERE ps.ProgramId = @EntityId))
and p.Active = 1
','
SELECT EntityTitle AS Text FROM Program WHERE Id = @Id
','Order By SortOrder','Look up programs',2,NULL,NULL)
,
(15,165,'CourseContributor','Id','Text','SELECT CONCAT(''<div style="color:red;">Once Contributors are added to the page, you will need to refresh the page to see the list of the co-contributors.</div>'', dbo.concatWithSep_Agg(''<br>'', CONCAT(FirstName, '' '', LastName, '' ('', u.email, '')''))) AS Text, 0 AS Value
FROM ProgramContributor pc
	INNER JOIN [user] u ON u.Id = pc.UserId
WHERE ProgramId = @entityId','SELECT CONCAT(''<div style="color:red;">Once Contributors are added to the page, you will need to refresh the page to see the list of the co-contributors.</div>'', dbo.concatWithSep_Agg(''<br>'', CONCAT(FirstName, '' '', LastName, '' ('', u.email, '')''))) AS Text, 0 AS Value
FROM ProgramContributor pc
	INNER JOIN [user] u ON u.Id = pc.UserId
WHERE ProgramId = @entityId',NULL,'Course Contributors',2,NULL,NULL)
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
(2451,'Course Subject',4046,1520,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2452,'Course',5555,1520,0,NULL,NULL,1,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,60,NULL,NULL,NULL,NULL)
,
(2454,'Non Course Requirement',1600,1520,0,NULL,NULL,3,0,1,'CKEditor',25,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2456,'Title',1346,1520,0,NULL,NULL,2,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3361,'Course  Sequence #',1363,1520,0,NULL,NULL,4,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3362,'Does this course count toward an Articulation Agreement?',10899,1520,0,NULL,NULL,5,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3363,'Does this course count toward an SPC Certificate?',10900,1520,0,NULL,NULL,7,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3364,'Does this course count toward an SPC degree?',10901,1520,0,NULL,NULL,9,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3366,'Should this course be indicated on degree Pathway (noted above)?',10902,1520,0,NULL,NULL,11,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3367,'Notes',1594,1520,0,NULL,NULL,12,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2677,'Program list and Degree Type',3211,1650,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,47,NULL,NULL,NULL,NULL)
,
(2680,'Email',3508,1652,0,NULL,NULL,3,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2681,'First Name',3510,1652,0,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2682,'Title',3511,1652,0,NULL,NULL,2,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2683,'Phone Number',3513,1652,0,NULL,NULL,4,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(2684,'Last Name',3524,1652,0,NULL,NULL,1,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3210,'Certification Name',1225,1964,1,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3211,'Certification Code',1535,1964,1,NULL,NULL,1,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,26,NULL,NULL,NULL)
,
(2622,'Next Program Review (Month/Year)',1091,1965,1,NULL,NULL,2,0,1,'TelerikCombo',33,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,35,NULL,NULL,NULL,NULL)
,
(3320,'Effective Term',1214,1965,1,NULL,NULL,0,0,1,'TelerikCombo',33,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,0,NULL,120,NULL,NULL,NULL,NULL)
,
(3353,'Approved by',2620,1965,1,NULL,NULL,1,0,1,'TelerikDate',27,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3204,'Rationale for Proposal',2298,1966,1,NULL,NULL,0,0,2,'CKEditor',25,100,2,100,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,0,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3354,'Does this Certification have an Articulation Agreement(s)?',3347,1966,1,NULL,NULL,1,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3315,'Award Type',1100,1970,1,NULL,NULL,0,0,1,'TelerikCombo',33,450,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,102,NULL,NULL,NULL,NULL)
,
(3344,'Learn more about this certification:',NULL,1972,0,NULL,NULL,1,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3345,'Program Certification Summary',2958,1972,0,NULL,NULL,0,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3346,'What is on the certification exam',2959,1972,0,NULL,NULL,2,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3348,'Cost of the certification exam voucher (free to eligible students',2600,1972,0,NULL,NULL,3,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3349,'Accommodations during a Certification Exam',2960,1972,0,NULL,NULL,4,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3350,'Learn more about apply for this certification exam accommodations',NULL,1972,0,NULL,NULL,5,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3218,'This Certification Exam is the final eligibility course’s final exam',3349,1974,0,NULL,NULL,1,0,1,'TelerikCombo',33,75,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3356,'Final eligibility course',NULL,1974,0,NULL,NULL,0,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3357,'Includes Out-of-class preparation activities',3348,1974,0,NULL,NULL,2,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3358,'Includes In-class eligibility requirements',3362,1974,0,NULL,NULL,3,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3219,'Course Prefix/#; Course Name',1690,1975,0,NULL,NULL,0,0,1,'Textbox',1,790,1,100,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3220,'Course Prefix/#; Course Name',2263,1975,0,NULL,NULL,1,0,1,'Textbox',1,790,1,100,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3268,'Associated Academic Organization',2536,1991,1,NULL,NULL,0,0,1,'TelerikCombo',33,350,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3269,'College/School/Department',2541,1991,1,NULL,NULL,1,0,1,'TelerikCombo',33,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3273,'<div style="color: red">Open the Form Properties to select co-contributors and assign permissions.</div>',NULL,2002,0,NULL,NULL,0,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3327,'',9168,2002,0,NULL,NULL,1,0,1,'QueryText',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,165,NULL,NULL,NULL,NULL)
,
(3301,'Have you attached the documents needed for this proposal?',3365,2006,1,NULL,NULL,0,0,1,'TelerikCombo',33,75,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3236,'Attached File Name',1095,2015,0,NULL,NULL,1,0,1,'Textbox',1,300,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3237,'Title',1222,2015,0,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3238,'Disk Name',1379,2015,0,NULL,NULL,2,0,1,'Textbox',1,300,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3239,'Mime Type',1380,2015,0,NULL,NULL,3,0,1,'Textbox',1,300,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3240,'Attachment Type',3572,2015,0,NULL,NULL,4,0,1,'Textbox',1,300,1,15,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3323,'ItemType',6846,2029,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,96,NULL,NULL,NULL,NULL)
,
(3328,'Implementation/Approved Date',9102,2042,0,NULL,NULL,1,0,1,'QueryText',103,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,141,NULL,NULL,NULL,NULL)
,
(3329,'Admin Notes',1140,2042,0,NULL,NULL,8,0,1,'CKEditor',25,100,2,120,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3330,'Origination Date',1164,2042,0,NULL,NULL,11,0,1,'TelerikDate',27,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3331,'Academic Career',1173,2042,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,29,NULL,NULL,NULL,NULL)
,
(3332,'Actual Program Effective Term',1214,2042,0,NULL,NULL,2,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,120,NULL,NULL,NULL,NULL)
,
(3333,'Program Originator',1382,2042,1,NULL,NULL,10,0,1,'TelerikCombo',33,250,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3334,'Dates/History Notes',9109,2042,0,NULL,NULL,7,0,1,'QueryText',103,100,2,140,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,115,NULL,NULL,NULL,NULL)
,
(3335,'Active Status',1591,2042,0,NULL,NULL,9,0,1,'TelerikCombo',33,350,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,106,NULL,NULL,NULL,NULL)
,
(3336,'Last valid requirement term for this version',2421,2042,0,NULL,NULL,4,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,123,NULL,NULL,NULL,NULL)
,
(3337,'Date Last Reviewed',2612,2042,0,NULL,NULL,5,0,1,'TelerikDate',27,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3338,'Date Deactivated',2614,2042,0,NULL,NULL,6,0,1,'TelerikDate',27,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3339,'Next Program Review',1091,2042,0,NULL,NULL,3,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,35,NULL,NULL,NULL,NULL)
,
(3340,'Other Requirements and Information',2955,2043,0,NULL,NULL,0,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3341,'Expectations and Considerations',2956,2044,0,NULL,NULL,0,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3342,'NOTES',2957,2044,0,NULL,NULL,2,0,1,'CKEditor',25,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3343,'<ul>
<li>Students who become eligible to get certified and plan to accept the opportunity are expected to file their Opt-In form immediately, to receive exam prep access and support.</li>
<li>To ensure students finish what they start and maximize their free certification opportunities at SPC, they should aim to get certified within 6 months after they file their Opt-In form.</li>
<li>All eligible students must finish getting certified no later than 6 months after graduating from their College Credit Certificate or Associate in Science program or entering a Bachelor’s degree program.</li>
<li>It is not recommended that students wait until graduation to pursue their certification opportunities!</li>
<li>Most successfully certified students report spending 30+ hours out of class, per certification, preparing to get certified.</li>
<li>A clear understanding of the exam’s objective domains and competencies, knowledge of terminology, ability to complete hands-on exercises like labs, and earning high scores on comprehensive practice exams in training and testing modes, are necessary to ensure students are well prepared to achieve certification.</li>
<li>Scores on comprehensive practice exams of 90% (or 900) and above are good indicators that students are ready to claim their voucher, and to schedule their exam.</li>
<li>Test prep tools and vouchers are not covered by tuition or student fees. Primary funding is from the federal “Strengthening Career & Technical Education for the 21st Century Act (Perkins V)” for Career and Technical Education (CTE) students, an entitlement grant that St. Petersburg College administers annually.</li>
<li>Once a student has claimed and received their voucher code, they are expected to schedule an exam appointment within approximately 30 days.</li>
<li>The Get Certified team administers the distribution of vouchers to ensure all purchased vouchers are used before their expiration date. If a student neglects to register (apply) their voucher by scheduling an exam appointment within the 30-day window, that voucher may be reassigned to serve another student, and a new Claim Your Voucher form must be filed to receive a replacement voucher.</li>
<li>Retake vouchers are occasionally available to students who have been unsuccessful on their first attempt. To claim a retake voucher, students may be asked to submit proof of a recent, comprehensive practice exam with a score of 90% or above.</li>
</ul>',NULL,2044,0,NULL,NULL,1,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3351,'<p>Unsure if you qualify to get certified, free? Contact us for an “Eligibility Audit”.</p>
<p>Get Certified – Certification Testing<br>
<a target="_blank" href="GetCertified@spcollege.edu">GetCertified@spcollege.edu</a><br>727.341.4760
</p>',NULL,2045,0,NULL,NULL,0,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3355,'If any documentation is associated with this Agreement, please upload on the Attachments page in the Checklist.',NULL,2047,0,NULL,NULL,0,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3360,'Requirement',10794,2048,1,NULL,NULL,0,0,1,'Textarea',17,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(3368,'Related_ProgramId',7255,2049,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,139,NULL,NULL,NULL,NULL)
,
(3369,'Related_ProgramId',7255,2050,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,140,NULL,NULL,NULL,NULL)
,
(3370,'Related_ProgramId',7255,2051,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,142,NULL,NULL,NULL,NULL)
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
(588,'listitemtype','1',2451)
,
(579,'FilterSubscriptionTable','ProgramSequence',2452)
,
(580,'FilterSubscriptionColumn','SubjectId',2452)
,
(581,'FilterTargetTable','ProgramSequence',2452)
,
(582,'FilterTargetColumn','CourseId',2452)
,
(583,'listitemtype','3',2454)
,
(741,'listitemtype','1',3361)
,
(742,'listitemtype','1',3362)
,
(743,'listitemtype','1',3363)
,
(744,'listitemtype','1',3364)
,
(745,'listitemtype','1',3366)
,
(746,'listitemtype','1',3367)
,
(738,'helptext','Each industry certification exam has specific processes and requirements for approved accommodations. (Existing accommodations approved through SPC are not automatically applied.)',3349)
,
(739,'subText','Each industry certification exam has specific processes and requirements for approved accommodations. (Existing accommodations approved through SPC are not automatically applied.)',3349)
,
(734,'FilterSubscriptionColumn','Tier1_OrganizationEntityId',3269)
,
(735,'FilterSubscriptionName','Parent_OrganizationEntityId',3269)
,
(736,'FilterSubscriptionTable','Program',3269)
,
(715,'FieldSpecialization','UploadFilenameField',3236)
,
(716,'FieldSpecialization','UploadTextnameField',3237)
,
(717,'FieldSpecialization','UploadDiscnameField',3238)
,
(718,'FieldSpecialization','UploadMimetypeField',3239)
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
(53,40,3210,0)
,
(54,40,3211,1)
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
		
-- Get MetadataAttributeMap
DECLARE  @MetadataAttributeMapTempTable Table
(MetadataAttributeMap_Id NVARCHAR(MAX));
INSERT INTO @MetadataAttributeMapTempTable

(MetadataAttributeMap_Id)
OUTPUT INSERTED.*
 VALUES
(26)
;


-- INSERT MetadataAttributeMap INTO Destination Database
IF (SELECT COUNT(*) FROM @MetadataAttributeMapTempTable) > 0
BEGIN
;WITH SourceData AS
( 
SELECT MetadataAttributeMap_Id
FROM @MetadataAttributeMapTempTable tt 	
)
MERGE INTO MetadataAttributeMap
USING SourceData sd ON 
Id = MetadataAttributeMap_Id
WHEN Not Matched By Target THEN
INSERT Default VALUES
OUTPUT 'MetadataAttributeMap',sd.MetadataAttributeMap_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);

END
		

INSERT INTO @MetaDataAttributeTempTable

(MetadataAttribute_Id,MetadataAttribute_Description,MetadataAttribute_ValueText,MetadataAttribute_ValueInt,MetadataAttribute_ValueFloat,MetadataAttribute_ValueBoolean,MetadataAttribute_ValueDateTime,MetadataAttribute_MetadataAttributeTypeId,MetadataAttribute_MetadataAttributeMapId,MetadataAttribute_MetaSelectedFieldId,MetadataAttribute_MetaSelectedSectionId,MetadataAttribute_DataType,MetadataAttribute_Text1,MetadataAttribute_Text2,MetadataAttribute_Text3, MetadataAttribute_Text4, MetadataAttribute_TableName)
OUTPUT INSERTED.*
 VALUES
(28,'Web service Cannonical Name','ProgramCode',NULL,NULL,NULL,NULL,2,26,NULL,NULL,NULL,NULL,NULL,NULL,NULL,'Field')
;

-- INSERT MetaDataAttribute INTO Destination Database


IF (SELECT COUNT(*) FROM @MetaDataAttributeTempTable) > 0
BEGIN

;WITH SourceData AS
( 
SELECT MetadataAttribute_Id,MetadataAttribute_Description,MetadataAttribute_ValueText,MetadataAttribute_ValueInt,MetadataAttribute_ValueFloat,MetadataAttribute_ValueBoolean,MetadataAttribute_ValueDateTime,MetadataAttribute_MetadataAttributeTypeId,kt.NewId AS MetadataAttribute_MetadataAttributeMapId,MetadataAttribute_MetaSelectedFieldId,MetadataAttribute_MetaSelectedSectionId,MetadataAttribute_DataType,MetadataAttribute_Text1,MetadataAttribute_Text2,MetadataAttribute_Text3,MetadataAttribute_Text4
FROM @MetaDataAttributeTempTable tt 
INNER JOIN #KeyTranslation kt ON kt.OldId = MetadataAttribute_MetadataAttributeMapId
	AND kt.DestinationTable ='MetaDateAttributeMap'
)
MERGE INTO MetaDataAttribute
USING SourceData sd 
ON description = sd.MetaDataAttribute_Description
	AND ValueText = sd.MetaDataAttribute_ValueText
	AND ValueInt = sd.MetaDataAttribute_ValueInt
	AND ValueFloat = sd.MetaDataAttribute_ValueFloat
	AND ValueBoolean = sd.MetaDataAttribute_ValueBoolean
	AND ValueDateTime = sd.MetaDataAttribute_ValueDateTime
	AND MetadataAttributeTypeId = sd.MetaDataAttribute_MetadataAttributeTypeId
	AND MetadataAttributeMapId = sd.MetaDataAttribute_MetadataAttributeMapId
	AND MetaSelectedFieldId = sd.MetaDataAttribute_MetaSelectedFieldId
	AND MetaSelectedSectionId = sd.MetaDataAttribute_MetaSelectedSectionId
	AND DataType = sd.MetaDataAttribute_DataType
	AND Text1 = sd.MetaDataAttribute_Text1
	AND Text2 = sd.MetaDataAttribute_Text2
	AND Text3 = sd.MetaDataAttribute_Text3
	AND Text4 = sd.MetaDataAttribute_Text4
WHEN Not Matched By Target THEN
INSERT (Description,ValueText,ValueInt,ValueFloat,ValueBoolean,ValueDateTime,MetadataAttributeTypeId,MetadataAttributeMapId,MetaSelectedFieldId,MetaSelectedSectionId,DataType,Text1,Text2,Text3,Text4)
VALUES (sd.MetadataAttribute_Description,sd.MetadataAttribute_ValueText,sd.MetadataAttribute_ValueInt,sd.MetadataAttribute_ValueFloat,sd.MetadataAttribute_ValueBoolean,sd.MetadataAttribute_ValueDateTime,sd.MetadataAttribute_MetadataAttributeTypeId,sd.MetadataAttribute_MetadataAttributeMapId,sd.MetadataAttribute_MetaSelectedFieldId,sd.MetadataAttribute_MetaSelectedSectionId,sd.MetadataAttribute_DataType,sd.MetadataAttribute_Text1,sd.MetadataAttribute_Text2,sd.MetadataAttribute_Text3,sd.MetadataAttribute_Text4)
OUTPUT 'MetaDataAttribute',sd.MetadataAttribute_Id, INSERTED.Id INTO #KeyTranslation (DestinationTable, OldId, NewId);

END

--==========================End MetaDataAttribute/Map============================


--===========================Begin update EditMap================================


--=======================Begin Update MetaSelectedField===========================


;MERGE MetaSelectedField AS Target
USING (
SELECT COALESCE(kt.NewId,NULL) AS MetaSelectedFieldId, 
COALESCE(kt1.NewId,NULL) AS MetaDataAttributeMapId,
COALESCE(kt2.NewId,NULL) AS EditMapId
FROM @MetaSelectedFieldTempTable tt
INNER JOIN #KeyTranslation kt ON kt.OldId = tt.MetaSelectedField_MetaSelectedFieldId
	AND kt.DestinationTable = 'MetaSelectedField'
LEFT JOIN #KeyTranslation kt1 ON kt1.OldId = tt.MetaSelectedField_MetaDataAttributeMapId
	AND kt1.DestinationTable = 'MetadataAttributeMap'
	And Exists
		(
			Select 1 
			from @MetaDataAttributeTempTable mdatt 
			Where mdatt.MetaDataAttribute_Id = kt1.OldId 
				And mdatt.MetadataAttribute_TableName = 'Field'
		)
LEFT JOIN #KeyTranslation kt2 ON kt2.OldId = tt.MetaSelectedField_EditMapId
	AND kt2.DestinationTable = 'EditMap'
WHERE tt.MetaSelectedField_MetadataAttributeMapId IS NOT NULL
	Or  tt.MetaSelectedField_EditMapId IS NOT NULL
) AS Source (MetaSelectedFieldId,MetaDataAttributeMapId,EditMapId)
on Target.MetaSelectedFieldId = Source.MetaSelectedFieldId
WHEN Matched THEN UPDATE
SET MetaDataAttributeMapId = Source.MetaDataAttributeMapId,
	EditMapId = Source. EditMapId
OUTPUT INSERTED.*
	;

--=========================End Update MetaSelectedField===========================


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
(366)
,
(376)
,
(377)
,
(378)
,
(379)
,
(380)
,
(381)
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
(776,366,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(777,366,776,1,16,3,3218,NULL,'1',NULL,NULL)
,
(796,376,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(797,376,796,1,16,3,3354,NULL,'1',NULL,NULL)
,
(798,377,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(799,377,798,1,16,3,3354,NULL,'1',NULL,NULL)
,
(800,378,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(801,378,800,1,16,3,3354,NULL,'1',NULL,NULL)
,
(802,379,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(803,379,802,1,16,3,3362,NULL,'1',NULL,NULL)
,
(804,380,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(805,380,804,1,16,3,3363,NULL,'1',NULL,NULL)
,
(806,381,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(807,381,806,1,16,3,3364,NULL,'1',NULL,NULL)
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
(366,'Show Hide Graduation Requirements',NULL,3218,NULL,2,366)
,
(376,'Show Hide Checklist for AR programs',NULL,3354,NULL,2,376)
,
(377,'Show Hide Checklist for AR programs',NULL,3354,NULL,2,377)
,
(378,'Show Hide Checklist for AR programs',NULL,3354,NULL,2,378)
,
(379,'Show Hide Checklist for programs',NULL,3362,NULL,2,379)
,
(380,'Show Hide Checklist for programs',NULL,3363,NULL,2,380)
,
(381,'Show Hide Checklist for programs',NULL,3364,NULL,2,381)
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
(461,'Show Hide Checklist for AR programs',NULL,1650,377)
,
(462,'Show Hide Checklist for AR programs',NULL,2047,378)
,
(463,'Show Hide Checklist for programs',NULL,2049,379)
,
(464,'Show Hide Checklist for programs',NULL,2050,380)
,
(465,'Show Hide Checklist for programs',NULL,2051,381)
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

		
-- Get ListItemType
DECLARE  @ListItemTypeTempTable Table
(ListItemType_Id NVARCHAR(MAX),ListItemType_Title NVARCHAR(MAX),ListItemType_Description NVARCHAR(MAX),ListItemType_ListItemTypeOrdinal NVARCHAR(MAX),ListItemType_ListItemTableName NVARCHAR(MAX),ListItemType_ListItemTitleColumn NVARCHAR(MAX),ListItemType_Active NVARCHAR(MAX),ListItemType_SortOrder NVARCHAR(MAX),ListItemType_StartDate NVARCHAR(MAX),ListItemType_EndDate NVARCHAR(MAX),ListItemType_ClientId NVARCHAR(MAX));

INSERT INTO @ListItemTypeTempTable

(ListItemType_Id,ListItemType_Title,ListItemType_Description,ListItemType_ListItemTypeOrdinal,ListItemType_ListItemTableName,ListItemType_ListItemTitleColumn,ListItemType_Active,ListItemType_SortOrder,ListItemType_StartDate,ListItemType_EndDate,ListItemType_ClientId)
OUTPUT INSERTED.*
 VALUES
(8,'Course Requirement',NULL,1,'ProgramSequence','CourseId',1,1,'Mar 25 2022  1:54PM',NULL,1)
,
(11,'Non-course requirement',NULL,3,'ProgramSequence','ItemTitle',1,2,'May  5 2022 11:51AM',NULL,1)
,
(16,'Contact',NULL,1,'ProgramEntityContact','ContactName',1,1,'Oct 19 2023  8:16PM',NULL,1)
,
(31,'Requirement',NULL,1,'EntityComment','MaxText01',1,1,'Mar 19 2025 10:40AM',NULL,1)
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
(146,2041,1,2)
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

--Commit