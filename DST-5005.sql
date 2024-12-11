
	/************************************************************************************************
	***                               Insertion of Extracted Script                          
	***                                                                                       
	***                                                                                       
	*** Created with the Template Configuration Extract Script and SQL Generator (version 2022.12.14)        
	***                                                                                       
	*** Script generated on Aug 15 2023  2:30PM                                              
	***                                                                                       
	*** Source Client: Gavilan                                                                 
	*** Source Template: 927                                                              
	*** Source Template Name: Initial Version CRN Assessment V1.0             
	*** Initial table: MetaSelectedSection       
	*** Initial id: 44733 
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
	

Use cuesta;

DECLARE @JiraTicketNumber NVARCHAR(20) = 'DST-5005';
DECLARE @Comments NVARCHAR(MAX) = 'test';
DECLARE @Developer NVARCHAR(50) = 'Nate';
DECLARE @ScriptTypeId int = 2; /* Default on this script is 2 = Enhancement
To See all Options run the following Query

SELECT * FROM history.ScriptType
*/
DECLARE @ClientCode nvarchar(50) = NULL ;
DECLARE @InitialTableName NVARCHAR(100);
SET @InitialTableName = 'MetaSelectedSection';
DECLARE @InitialId int = 44733;
DECLARE @ClientId Int = 1;
DECLARE @OverrideClientId Int = Coalesce((Select Id from Client where Code =  @ClientCode ),(Select top 1 Id from Client where Active = 1));
DECLARE @SourceDatabase NVARCHAR(100) = 'gavilan';
DECLARE @SourceTemplateTypeId Int = 532;
DECLARE @SourceTemplateId int  = 927;
DECLARE @InsertToMetaTemplateId int = 1; --Set this if inserting sections into a different template Id from the extrated template
DECLARE @InsertToMetaTemplateTypeId int = 1; --Set this if inserting sections into a different template type Id from the extrated template
DECLARE @SourceParentSectionId int ; --Do not set this variable
DECLARE @TargetParentSectionId int ; --Do not set this here set it below if necessary
DECLARE @ClientEntityType NVARCHAR(100) = 'Course';

If @InitialId is not NULL and (Select MetaSelectedSection_MetaSelectedSectionId from MetaSelectedSection where MetaSelectedSectionId = @InitialId) Is Not NULL
BEGIN
	 Set @TargetParentSectionId = (Select MetaSelectedSection_MetaSelectedSectionId from MetaSelectedSection where MetaSelectedSectionId = 1); --Change this if inserting sections into a different Parent Section

	SET @SourceParentSectionId=(SELECT MetaSelectedSection_MetaSelectedSectionId
		  FROM MetaSelectedSection
		  WHERE MetaSelectedSectionId=44733); --Do not change this setting
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
Insert into #KeyTranslation
		Values
		('MetaSelectedSection',44731, @TargetParentSectionId );

--=================Begin Entity Organization Origination========================
		
-- Get EntityOrganizationOrigination
Declare  @EntityOrganizationOriginationTempTable Table
(EntityOrganizationOrigination_ClientId nVarchar(Max),EntityOrganizationOrigination_EntityTypeId nVarchar(Max),EntityOrganizationOrigination_OrganizationTierId nVarchar(Max));

Insert into @EntityOrganizationOriginationTempTable

(EntityOrganizationOrigination_ClientId,EntityOrganizationOrigination_EntityTypeId,EntityOrganizationOrigination_OrganizationTierId)
Output Inserted.*
 Values
(57,2,107)
,
(57,2,108)
,
(57,6,107)
,
(57,6,108)
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
	
(44733,57,44731,NULL,1,NULL,0,NULL,0,0,1,1,927,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
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
(15077,1,1,'Tier0Table','ModuleDetail',44733)
,
(15078,1,1,'Tier0IdColumn','Id',44733)
,
(15079,1,1,'Tier0CascadeColumn','Id',44733)
,
(15080,1,1,'Tier0ForeignKeyField','SubjectId',44733)
,
(15081,1,1,'Tier1Table','ModuleDetail',44733)
,
(15082,1,1,'Tier1IdColumn','Id',44733)
,
(15083,1,1,'Tier1FilterColumn','SubjectId',44733)
,
(15084,1,1,'Tier1CascadeColumn','Id',44733)
,
(15085,1,1,'Tier1ForeignKeyField','Active_CourseId',44733)
,
(15086,1,1,'Tier2Table','ModuleDetail',44733)
,
(15087,1,1,'Tier2IdColumn','Id',44733)
,
(15088,1,1,'Tier2FilterColumn','Active_CourseId',44733)
,
(15089,1,1,'Tier2CascadeColumn','Id',44733)
,
(15090,1,1,'Tier2ForeignKeyField','Reference_CourseId',44733)
,
(15091,1,1,'Tier3Table','ModuleDetail',44733)
,
(15092,1,1,'Tier3IdColumn','Id',44733)
,
(15093,1,1,'Tier3FilterColumn','Reference_CourseId',44733)
,
(15094,1,1,'Tier3ForeignKeyField','Reference_CourseOutcomeId',44733)
,
(15095,1,1,'LabelWidth','180',44733)
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
(1,3888,'Course','Id','Title','declare @histCourse table (Id int, BaseCourseId int);
INSERT INTO @histCourse (Id, BaseCourseId)
	SELECT
		Id,
		BaseCourseId
	FROM (SELECT
			c_inner2.Id,
			c_inner2.BaseCourseId
		   ,ROW_NUMBER() OVER (PARTITION BY c_inner2.BaseCourseId ORDER BY c_inner2.Id) AS ResultNum
		FROM Course c_inner2
			INNER JOIN StatusAlias sa_inner ON c_inner2.StatusAliasId = sa_inner.Id
		WHERE c_inner2.Active = 1
		AND sa_inner.StatusBaseId = 5) c_inner
	WHERE ResultNum = 1
SELECT
	c.Id AS [Value],
	COALESCE(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title) +
	CASE
		WHEN md.Reference_CourseId IS NOT NULL AND
			c.Id = md.Reference_CourseId THEN '' *''
		ELSE ''''
	END AS [Text],
	c.SubjectId AS FilterValue
FROM Course c
	INNER JOIN [Subject] s ON c.SubjectId = s.Id
	INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
	LEFT OUTER JOIN ModuleDetail md ON md.ModuleId = @entityId
WHERE c.ClientId = @clientId
AND c.Active = 1
AND c.SubjectId IS NOT NULL
AND EXISTS (SELECT
		1
	FROM CourseOutcome co
		INNER JOIN Course c_inner
		INNER JOIN StatusAlias sa_inner ON c_inner.StatusAliasId = sa_inner.Id ON co.CourseId = c_inner.Id
	WHERE c.BaseCourseId = c_inner.BaseCourseId
	AND sa_inner.StatusBaseId IN (1, 5))
AND (sa.StatusBaseId = 1
OR (        --When there is no active course in this course family
NOT EXISTS (SELECT
		1
	FROM Course c_inner
		INNER JOIN StatusAlias sa_inner ON c_inner.StatusAliasId = sa_inner.Id
	WHERE c.BaseCourseId = c_inner.BaseCourseId
	AND sa_inner.StatusBaseId = 1)
AND c.Id = (            --And this course is the most recent historical version of the course
	SELECT
		Id
	FROM @histCourse c_inner
	WHERE c.BaseCourseId = c_inner.BaseCourseId)
)
OR (        --If the course would otherwise not be included but is the selected course, include it        
md.Active_CourseId IS NOT NULL
AND c.Id = md.Active_CourseId
))
ORDER BY Text','select coalesce(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title) as [Text] 
from Course c 
inner join [Subject] s on s.Id = c.SubjectId
where c.id = @Id','order by CourseNumber','Active or Most Recent Historical Course - Active_CourseId',3,NULL,NULL)
,
(2,3889,'Course','Id','Title','DECLARE @histCourse TABLE (Id int, BaseCourseId int);
INSERT INTO @histCourse (Id, BaseCourseId)
	SELECT
		Id,
		BaseCourseId
	FROM (SELECT
			c_inner2.Id,
			c_inner2.BaseCourseId,
			ROW_NUMBER() OVER (PARTITION BY c_inner2.BaseCourseId ORDER BY c_inner2.Id) AS ResultNum
		FROM Course c_inner2
			INNER JOIN StatusAlias sa_inner ON c_inner2.StatusAliasId = sa_inner.Id
		WHERE c_inner2.Active = 1
		AND sa_inner.StatusBaseId = 5) c_inner
	WHERE ResultNum = 1;

DECLARE @CourseFamily TABLE (Value INT PRIMARY KEY, Text NVARCHAR(MAX), StartDate DATETIME, SortOrder INT, filterColumn INT);
INSERT INTO @CourseFamily (Value, Text, StartDate, SortOrder, filterColumn)
	SELECT
		c.Id AS Value,
		COALESCE(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title) AS Text,
		COALESCE(p.ImplementDate, c.CreatedOn) AS StartDate,
		ROW_NUMBER() OVER (PARTITION BY c.BaseCourseId ORDER BY COALESCE(p.ImplementDate, c.CreatedOn), c.Id) AS RowNumber,
		ISNULL(bc.ActiveCourseId, hc.Id) AS FilterValue
	FROM [Course] c
		INNER JOIN BaseCourse bc ON bc.Id = c.BaseCourseId
		INNER JOIN @histCourse hc ON bc.Id = hc.BaseCourseId
		INNER JOIN Subject s ON c.SubjectId = s.Id
		INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
		LEFT JOIN Proposal p ON c.ProposalId = p.Id
	WHERE c.Active = 1
	AND sa.StatusBaseId IN (1, 5)
	AND EXISTS (SELECT
			1
		FROM CourseOutcome co
		WHERE co.CourseId = c.Id);

SELECT
	cf.Value,
	cf.Text + '' ('' +
	CASE cf.SortOrder
		WHEN 1 THEN ''Existing''
		ELSE CONVERT(VARCHAR(10), cf.StartDate, 101)
	END + '' - '' + COALESCE(CONVERT(VARCHAR(10), cf2.StartDate, 101), '' Current'') + '')'' AS Text,
	cf.filterColumn AS FilterValue
FROM @CourseFamily cf
LEFT JOIN @CourseFamily cf2
	ON (cf.SortOrder + 1) = cf2.SortOrder
		AND cf.filterColumn = cf2.filterColumn
ORDER BY cf.filterColumn, cf.SortOrder DESC;','select coalesce(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title) as [Text] 
from Course c 
inner join [Subject] s on s.Id = c.SubjectId
where c.id = @Id','order by CourseNumber','Course Family (Active and Historic) that have outcomes',3,NULL,NULL)
,
(3,3891,'CourseOutcome','Id','OutcomeText',';with AssessmentValues as (
	select 
		m.Id, md.Reference_CourseOutcomeId, coalesce(mcsd.CRNOfferingId, m01.CRNOfferingId) as CRNOfferingId,
		case when mcsd.ModuleId is not null then 1 else 0 end as HasStudentData, m.Active
	from Module m
	left outer join ModuleDetail md on m.Id = md.ModuleId
	left outer join ModuleExtension01 m01 on m.Id = m01.ModuleId
	outer apply (
		select top 1 sd.CRNOfferingId, mcsd.ModuleId
		from ModuleCRNStudentData mcsd
		inner join StudentData sd on mcsd.StudentDataId = sd.Id
		where mcsd.ModuleId = m.Id
	) mcsd
)
,AssessmentsForSameOffering as (
	select av2.Reference_CourseOutcomeId
	from AssessmentValues av
	inner join AssessmentValues av2 on (
		av.Id = @entityId and av2.Id <> @entityId
		and av2.Active = 1
		and av.CRNOfferingId = av2.CRNOfferingId
	)
)
select 
	co.Id as Value, co.OutcomeText as [Text], c.Id as FilterValue
from CourseOutcome co
inner join AssessmentValues av on av.Id = @entityId
inner join Course c on c.Id = co.CourseId
where co.CourseId is not null
and
(
	case
		when av.CRNOfferingId is not null and av.Reference_CourseOutcomeId is not null then case when co.Id = av.Reference_CourseOutcomeId then 1 else 0 end
		when av.CRNOfferingId is not null then
			case when not exists (
				select 1
				from AssessmentsForSameOffering afso
				where afso.Reference_CourseOutcomeId = co.Id
			) then 1 else 0 end
		else 1
	end = 1
)','select OutcomeText as [Text] from CourseOutcome where Id = @Id',NULL,'CRN Assessment Outcome Selection',3,NULL,NULL)
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
(69680,'Subject',4117,44733,1,NULL,NULL,0,0,1,'TelerikCombo',33,550,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(69681,'Course',4137,44733,1,NULL,NULL,1,0,1,'TelerikCombo',33,550,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,3888,NULL,NULL,NULL,NULL)
,
(69682,'Version',4136,44733,1,NULL,NULL,2,0,1,'TelerikCombo',33,550,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,3889,NULL,NULL,NULL,NULL)
,
(69683,'Outcome',4140,44733,1,NULL,NULL,3,0,1,'TelerikCombo',33,550,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,3891,NULL,NULL,NULL,NULL)
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
(4271,'FilterSubscriptionColumn','SubjectId',69681)
,
(4272,'FilterSubscriptionTable','ModuleDetail',69681)
,
(4275,'FilterTargetColumn','Active_CourseId',69681)
,
(4278,'FilterTargetTable','ModuleDetail',69681)
,
(4269,'FilterSubscriptionColumn','Active_CourseId',69682)
,
(4273,'FilterSubscriptionTable','ModuleDetail',69682)
,
(4276,'FilterTargetColumn','Reference_CourseId',69682)
,
(4279,'FilterTargetTable','ModuleDetail',69682)
,
(4270,'FilterSubscriptionColumn','Reference_CourseId',69683)
,
(4274,'FilterSubscriptionTable','ModuleDetail',69683)
,
(4277,'FilterTargetColumn','Reference_CourseOutcomeId',69683)
,
(4280,'FilterTargetTable','ModuleDetail',69683)
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
(184,927,69682,0)
,
(185,927,69683,1)
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