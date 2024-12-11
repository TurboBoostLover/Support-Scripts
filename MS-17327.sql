USE [aurak];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17327';
DECLARE @Comments nvarchar(Max) = 
	'Add Packages';
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

	/************************************************************************************************
	***                               Insertion of Extracted Script                          
	***                                                                                       
	***                                                                                       
	*** Created with the Template Configuration Extract Script and SQL Generator (version 2022.12.14)        
	***                                                                                       
	*** Script generated on Sep 16 2024  4:08PM                                              
	***                                                                                       
	*** Source Client: Nazarbayev University                                                                 
	*** Source Template: 3                                                              
	*** Source Template Name: New Package Initial Version             
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
DECLARE @ClientCode nvarchar(50) = NULL ;
DECLARE @InitialTableName NVARCHAR(100);
SET @InitialTableName = '';
DECLARE @InitialId int = 0;
DECLARE @ClientId Int = 1;
DECLARE @OverrideClientId Int = Coalesce((Select Id from Client where Code =  @ClientCode ),(Select top 1 Id from Client where Active = 1));
DECLARE @SourceDatabase NVARCHAR(100) = 'aurak';
DECLARE @SourceTemplateTypeId Int = 3;
DECLARE @SourceTemplateId int  = 3;
DECLARE @InsertToMetaTemplateId int ; --Set this if inserting sections into a different template Id from the extrated template
DECLARE @InsertToMetaTemplateTypeId int ; --Set this if inserting sections into a different template type Id from the extrated template
DECLARE @SourceParentSectionId int ; --Do not set this variable
DECLARE @TargetParentSectionId int ; --Do not set this here set it below if necessary
DECLARE @ClientEntityType NVARCHAR(100) = 'Package';
 
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
(3,1,3,3,'Package',1,1,1,'Packages',NULL,3,NULL,0,NULL)
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
(3,'Standard Package','Package','Id',3,1,0,1,3,NULL)
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


--==========================Begin Proposal Type=================================

		
-- Get ProposalType
DECLARE  @ProposalTypeTempTable Table
(ProposalType_Id NVARCHAR(MAX),ProposalType_ClientId NVARCHAR(MAX),ProposalType_Title NVARCHAR(MAX),ProposalType_EntityTypeId NVARCHAR(MAX),ProposalType_ClientEntitySubTypeId NVARCHAR(MAX),ProposalType_ProcessActionTypeId NVARCHAR(MAX),ProposalType_MetaTemplateTypeId NVARCHAR(MAX),ProposalType_Active NVARCHAR(MAX),ProposalType_DeletedBy_UserId NVARCHAR(MAX),ProposalType_DeletedDate NVARCHAR(MAX),ProposalType_Presentation_MetaTemplateTypeId NVARCHAR(MAX),ProposalType_AvailableForLookup NVARCHAR(MAX),ProposalType_AllowReactivation NVARCHAR(MAX),ProposalType_AllowMultipleApproved NVARCHAR(MAX),ProposalType_ReactivationRequired NVARCHAR(MAX),ProposalType_AwardLevelId NVARCHAR(MAX),ProposalType_ClientEntityTypeId NVARCHAR(MAX),ProposalType_Code NVARCHAR(MAX),ProposalType_CloneRequired NVARCHAR(MAX),ProposalType_AllowDistrictClone NVARCHAR(MAX),ProposalType_AllowCloning NVARCHAR(MAX),ProposalType_MaxClone NVARCHAR(MAX),ProposalType_Instructions NVARCHAR(MAX),ProposalType_HideProposalRequirementFields NVARCHAR(MAX));

INSERT INTO @ProposalTypeTempTable

(ProposalType_Id,ProposalType_ClientId,ProposalType_Title,ProposalType_EntityTypeId,ProposalType_ClientEntitySubTypeId,ProposalType_ProcessActionTypeId,ProposalType_MetaTemplateTypeId,ProposalType_Active,ProposalType_DeletedBy_UserId,ProposalType_DeletedDate,ProposalType_Presentation_MetaTemplateTypeId,ProposalType_AvailableForLookup,ProposalType_AllowReactivation,ProposalType_AllowMultipleApproved,ProposalType_ReactivationRequired,ProposalType_AwardLevelId,ProposalType_ClientEntityTypeId,ProposalType_Code,ProposalType_CloneRequired,ProposalType_AllowDistrictClone,ProposalType_AllowCloning,ProposalType_MaxClone,ProposalType_Instructions,ProposalType_HideProposalRequirementFields)
--OUTPUT INSERTED.*
 VALUES
(3,1,'New Package',3,NULL,1,3,1,NULL,NULL,NULL,0,0,0,0,NULL,3,'ADFA504F-7736-41D9-8AF5-4D24E3B3FD85',0,0,1,NULL,NULL,0)
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
(3,3,1)
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
(3,3,'Oct 12 2022  9:22AM',1,3,'Oct 12 2022  9:22AM',NULL,'New Package Initial Version',1,'Sep  7 2024  1:16PM',NULL,NULL,0,NULL,NULL)
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
	
(356,1,NULL,'Cover',1,NULL,0,0,0,0,1,15,3,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(357,1,356,NULL,1,NULL,0,0,0,0,1,1,3,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(358,1,NULL,'Courses',1,NULL,0,NULL,1,1,1,15,3,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(359,1,358,'Originated Courses',1,NULL,0,0,0,0,1,18,3,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(360,1,NULL,'Programs',1,NULL,0,NULL,3,2,1,15,3,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(361,1,360,'Originated Programs',1,NULL,0,0,0,0,1,18,3,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
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


--=======================Begin Meta Selected Field==============================

		
-- Get MetaSelectedField
DECLARE  @MetaSelectedFieldTempTable Table
(MetaSelectedField_MetaSelectedFieldId NVARCHAR(MAX),MetaSelectedField_DisplayName NVARCHAR(MAX),MetaSelectedField_MetaAvailableFieldId NVARCHAR(MAX),MetaSelectedField_MetaSelectedSectionId NVARCHAR(MAX),MetaSelectedField_IsRequired NVARCHAR(MAX),MetaSelectedField_MinCharacters NVARCHAR(MAX),MetaSelectedField_MaxCharacters NVARCHAR(MAX),MetaSelectedField_RowPosition NVARCHAR(MAX),MetaSelectedField_ColPosition NVARCHAR(MAX),MetaSelectedField_ColSpan NVARCHAR(MAX),MetaSelectedField_DefaultDisplayType NVARCHAR(MAX),MetaSelectedField_MetaPresentationTypeId NVARCHAR(MAX),MetaSelectedField_Width NVARCHAR(MAX),MetaSelectedField_WidthUnit NVARCHAR(MAX),MetaSelectedField_Height NVARCHAR(MAX),MetaSelectedField_HeightUnit NVARCHAR(MAX),MetaSelectedField_AllowLabelWrap NVARCHAR(MAX),MetaSelectedField_LabelHAlign NVARCHAR(MAX),MetaSelectedField_LabelVAlign NVARCHAR(MAX),MetaSelectedField_LabelStyleId NVARCHAR(MAX),MetaSelectedField_LabelVisible NVARCHAR(MAX),MetaSelectedField_FieldStyle NVARCHAR(MAX),MetaSelectedField_EditDisplayOnly NVARCHAR(MAX),MetaSelectedField_GroupName NVARCHAR(MAX),MetaSelectedField_GroupNameDisplay NVARCHAR(MAX),MetaSelectedField_FieldTypeId NVARCHAR(MAX),MetaSelectedField_ValidationRuleId NVARCHAR(MAX),MetaSelectedField_LiteralValue NVARCHAR(MAX),MetaSelectedField_ReadOnly NVARCHAR(MAX),MetaSelectedField_AllowCopy NVARCHAR(MAX),MetaSelectedField_Precision NVARCHAR(MAX),MetaSelectedField_MetaForeignKeyLookupSourceId NVARCHAR(MAX),MetaSelectedField_MetadataAttributeMapId NVARCHAR(MAX),MetaSelectedField_EditMapId NVARCHAR(MAX),MetaSelectedField_NumericDataLength NVARCHAR(MAX),MetaSelectedField_Config NVARCHAR(MAX));

INSERT INTO @MetaSelectedFieldTempTable

(MetaSelectedField_MetaSelectedFieldId,MetaSelectedField_DisplayName,MetaSelectedField_MetaAvailableFieldId,MetaSelectedField_MetaSelectedSectionId,MetaSelectedField_IsRequired,MetaSelectedField_MinCharacters,MetaSelectedField_MaxCharacters,MetaSelectedField_RowPosition,MetaSelectedField_ColPosition,MetaSelectedField_ColSpan,MetaSelectedField_DefaultDisplayType,MetaSelectedField_MetaPresentationTypeId,MetaSelectedField_Width,MetaSelectedField_WidthUnit,MetaSelectedField_Height,MetaSelectedField_HeightUnit,MetaSelectedField_AllowLabelWrap,MetaSelectedField_LabelHAlign,MetaSelectedField_LabelVAlign,MetaSelectedField_LabelStyleId,MetaSelectedField_LabelVisible,MetaSelectedField_FieldStyle,MetaSelectedField_EditDisplayOnly,MetaSelectedField_GroupName,MetaSelectedField_GroupNameDisplay,MetaSelectedField_FieldTypeId,MetaSelectedField_ValidationRuleId,MetaSelectedField_LiteralValue,MetaSelectedField_ReadOnly,MetaSelectedField_AllowCopy,MetaSelectedField_Precision,MetaSelectedField_MetaForeignKeyLookupSourceId,MetaSelectedField_MetadataAttributeMapId,MetaSelectedField_EditMapId,MetaSelectedField_NumericDataLength,MetaSelectedField_Config)
OUTPUT INSERTED.*
 VALUES
(521,'Originator',1336,357,1,NULL,NULL,2,0,1,'TelerikCombo',33,310,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(522,'Package Title',1338,357,1,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(523,'Brief Description of Course Set and/or Program',1339,357,1,NULL,NULL,4,0,2,'Textarea',17,100,2,200,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(524,'Discipline',1337,357,1,NULL,NULL,1,0,1,'TelerikCombo',33,310,1,24,1,1,0,1,0,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(525,'Course',1348,359,0,NULL,NULL,0,0,1,NULL,33,100,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(526,'Program',1351,361,0,NULL,NULL,0,0,1,NULL,33,100,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
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
(111,'HyperlinkSubstitution','true',525)
,
(112,'HyperlinkSubstitution','true',526)
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


--=========================Begin MetaDataAttribute/Map===========================

		
-- Get MetaDataAttribute
DECLARE  @MetaDataAttributeTempTable Table
(MetadataAttribute_Id NVARCHAR(MAX),MetadataAttribute_Description NVARCHAR(MAX),MetadataAttribute_ValueText NVARCHAR(MAX),MetadataAttribute_ValueInt NVARCHAR(MAX),MetadataAttribute_ValueFloat NVARCHAR(MAX),MetadataAttribute_ValueBoolean NVARCHAR(MAX),MetadataAttribute_ValueDateTime NVARCHAR(MAX),MetadataAttribute_MetadataAttributeTypeId NVARCHAR(MAX),MetadataAttribute_MetadataAttributeMapId NVARCHAR(MAX),MetadataAttribute_MetaSelectedFieldId NVARCHAR(MAX),MetadataAttribute_MetaSelectedSectionId NVARCHAR(MAX),MetadataAttribute_DataType NVARCHAR(MAX),MetadataAttribute_Text1 NVARCHAR(MAX),MetadataAttribute_Text2 NVARCHAR(MAX),MetadataAttribute_Text3 NVARCHAR(MAX),MetadataAttribute_Text4 NVARCHAR(MAX), MetadataAttribute_TableName NVARCHAR(100) );

--==========================End MetaDataAttribute/Map============================


SELECT newid AS MetaTemplateId
FROM #KeyTranslation
WHERE DestinationTable='MetaTemplate'

UPDATE MetaTemplate
SET LastUpdatedDate=GETDATE( )
OUTPUT INSERTED.*
WHERE MetaTemplateId=@MetaTemplateId

--SELECT * FROM #KeyTranslation
DROP TABLE IF EXISTS #KeyTranslation


INSERT INTO config.ClientMenuItem
(Title, MenuItemPresentationTypeId, ClientMenuId, ClientEntityTypeId, StartDate)
VALUES
('Packages', 4, 1, 7, GETDATE())

DECLARE @Item int = SCOPE_IDENTITY()

INSERT INTO config.ClientMenuSection
(ParentId, MenuSectionTypeId, ClientMenuId, SortOrder, StartDate)
VALUES
(1, 2, 1, 7, GETDATE())

DECLARE @section int = SCOPE_IDENTITY()

INSERT INTO config.ClientMenuLayout
(ClientMenuSectionId, ClientMenuItemId, ClientMenuId, StartDate)
VALUES
(@section, @Item, 1, GETDATE())

--Rollback

--Commit