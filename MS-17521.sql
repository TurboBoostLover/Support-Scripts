USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17521';
DECLARE @Comments nvarchar(Max) = 
	'Update Request Faculty on the Non-Instructial Program Review';
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
DECLARE @Tab int = (
SELECT MEtaSelectedSectionId FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
		INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 6
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
    AND mtt.MetaTemplateTypeId = 37
		AND mss.SectionName like '%Faculty%'
		and mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
)

EXEC spBuilderSectionDelete 1, @Tab

DECLARE @ClientCode nvarchar(50) = NULL ;
DECLARE @InitialTableName NVARCHAR(100);
SET @InitialTableName = 'MetaSelectedSection';
DECLARE @InitialId int = 7220;
DECLARE @ClientId Int = 1;
DECLARE @OverrideClientId Int = Coalesce((Select Id from Client where Code =  @ClientCode ),(Select top 1 Id from Client where Active = 1));
DECLARE @SourceDatabase NVARCHAR(100) = 'chaffey';
DECLARE @SourceTemplateTypeId Int = 37;
DECLARE @SourceTemplateId int  = 80;
DECLARE @InsertToMetaTemplateId int ; --Set this if inserting sections into a different template Id from the extrated template
DECLARE @InsertToMetaTemplateTypeId int ; --Set this if inserting sections into a different template type Id from the extrated template
DECLARE @SourceParentSectionId int ; --Do not set this variable
DECLARE @TargetParentSectionId int ; --Do not set this here set it below if necessary
DECLARE @ClientEntityType NVARCHAR(100) = 'Program Review';

If @InitialId is not NULL and (Select MetaSelectedSection_MetaSelectedSectionId from MetaSelectedSection where MetaSelectedSectionId = @InitialId) Is Not NULL
BEGIN
	 Set @TargetParentSectionId = (Select MetaSelectedSection_MetaSelectedSectionId from MetaSelectedSection where MetaSelectedSectionId = 7220); --Change this if inserting sections into a different Parent Section

	SET @SourceParentSectionId=(SELECT MetaSelectedSection_MetaSelectedSectionId
		  FROM MetaSelectedSection
		  WHERE MetaSelectedSectionId=7220); --Do not change this setting
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
	
(7220,1,NULL,'Request - Faculty',1,NULL,0,NULL,3,3,1,30,79,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7240,1,7220,NULL,1,NULL,0,NULL,0,0,1,1,79,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7289,1,7220,NULL,1,NULL,0,NULL,1,1,1,1,79,NULL,NULL,NULL,0,NULL,NULL,NULL,NULL,1,0,NULL)
,
(7225,1,7240,'Faculty',1,'Answer yes below to request FULL-TIME FACULTY ONLY. Part-time faculty, or increased hours should be requested on the OTHER RESOURCES REQUEST FORM as a budget augmentation.',1,NULL,2,0,1,31,79,NULL,NULL,NULL,0,1429,NULL,NULL,NULL,1,0,NULL)
,
(7224,1,7225,'CHAFFEY GOALS',1,'<p><b>Select the Chaffey Goals that directly relate and are MOST relevant to your request.</b></p>
<span>Note: Goals are numbered for the purpose of making reference points so that PSR writers can identify and locate which Chaffey Goals relate to the area. Goal numbers do not represent priority numbers. (Select all that apply)</span>
',1,NULL,5,5,1,32,79,NULL,NULL,NULL,0,1440,NULL,NULL,NULL,1,0,NULL)
,
(7226,1,7225,'UNEXPECTED NEED CRITERIA. Check all that apply.',1,'Add rationale for each resource request.',1,NULL,3,3,1,32,79,NULL,NULL,NULL,0,1440,NULL,NULL,NULL,1,0,NULL)
,
(7227,1,7225,NULL,1,NULL,0,NULL,4,4,1,1,79,NULL,NULL,NULL,0,1429,NULL,NULL,NULL,1,0,NULL)
,
(7287,1,7225,NULL,1,NULL,0,NULL,6,6,1,1,79,NULL,NULL,NULL,0,1429,NULL,NULL,NULL,1,0,NULL)
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
(7646,1,1,'lookuptablename','ModuleResourceRequestLookup',7224)
,
(7647,1,1,'lookupcolumnname','Lookup05Id',7224)
,
(7648,1,1,'columns','1',7224)
,
(7649,1,1,'lookuptablename','ModuleResourceRequestLookup',7226)
,
(7650,1,1,'lookupcolumnname','Lookup01Id',7226)
,
(7651,1,1,'columns','1',7226)
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
(1,84,'YesNo','Id','Title','select Id as Value, Title as Text from YesNo where Title <> ''N/A''','Select Title as Text from YesNo Where id = @id','Order by SortOrder','Yes and no with out N/A',1,NULL,NULL)
,
(2,85,'Lookup05','Id','Title','
select [Id] as [Value], (Description) as [Text] 
from [Lookup05] 
where Active = 1 
and ([ClientId] = @clientId) 
Order By SortOrder
','
select (Description) as [Text]       
from [Lookup05]  
where Id = @Id
','Order By SortOrder','',1,NULL,NULL)
,
(3,87,'Lookup05','Id','Title','select [Id] as [Value], (ShortText) as [Text] 
from [Lookup04] 
where Active = 1 
and ([ClientId] = @clientId) 
and shorttext in (
''Instructional (Credit)'', ''Instructional (Noncredit)'', ''Instructional Support''
)
Order By SortOrder','
select (ShortText) as [Text]       
from [Lookup04]  
where Id = @Id
','Order By SortOrder','',1,NULL,NULL)
,
(4,88,'Lookup05','Id','Title','
select [Id] as [Value], (ShortText) as [Text] 
from [Lookup04] 
where Active = 1 
and ([ClientId] = @clientId) 
and shorttext in (
''Tenure Track'', ''Temporary Full-Time''
)
Order By SortOrder
','
select (ShortText) as [Text]       
from [Lookup04]  
where Id = @Id
','Order By SortOrder','',1,NULL,NULL)
,
(5,170,'Lookup01','Id','Title','
select [Id] as [Value], (ShortText) as [Text] 
from [Lookup01] 
where Active = 1 
	and Lookup01ParentId = 14 
and Id not in (13, 15)
Order By SortOrder
','
select (ShortText) as [Text]       
from [Lookup01]  
where Id = @Id
','Order By SortOrder','look up instructional',1,NULL,NULL)
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
(11825,'Do you have any UNEXPECTED FULL-TIME FACULTY requests?',5179,7240,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,84,NULL,NULL,NULL,NULL)
,
(11910,'Faculty requests have been reviewed and updated as needed.',5176,7289,1,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,84,NULL,NULL,NULL,NULL)
,
(11795,'Department and Subject this request is for (e.g., Business – Real Estate)',4298,7225,0,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(11829,'Lookup05',4361,7224,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,85,NULL,NULL,NULL,NULL)
,
(11814,'Explain',17501,7226,0,NULL,NULL,1,0,1,'Textarea',17,100,2,100,2,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(11833,'Lookup01',4357,7226,0,NULL,NULL,0,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,170,NULL,NULL,NULL,NULL)
,
(11796,'Rancho',4312,7227,0,NULL,NULL,3,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(11797,'Chino',4313,7227,0,NULL,NULL,4,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(11798,'Fontana',4314,7227,0,NULL,NULL,5,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(11799,'Other',4286,7227,0,NULL,NULL,7,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(11801,'<h6 style = "font-weight: bold;">Indicate the location of the requested Staff Position:</h6>',NULL,7227,0,NULL,NULL,2,0,1,'StaticText',35,NULL,0,NULL,0,1,0,1,NULL,NULL,0,NULL,NULL,NULL,2,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(11830,'Indicate the type of Faculty Position requested',4348,7227,0,NULL,NULL,8,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,87,NULL,NULL,NULL,NULL)
,
(11831,'Is this position requested Tenure Track or Temporary Full-Time',4347,7227,0,NULL,NULL,1,0,1,'TelerikCombo',33,150,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,88,NULL,NULL,NULL,NULL)
,
(11975,'Other',4320,7227,0,NULL,NULL,6,0,1,'Checkbox',5,60,1,24,1,1,0,1,NULL,0,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(11800,'Explain how students/area will be adversely affected without this faculty position in the context of the Chaffey Goal(s) selected above.',4296,7287,0,NULL,NULL,0,0,1,'CKEditor',25,100,2,100,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(11908,'Estimated number of students who will be impacted annually.',4321,7287,1,NULL,NULL,1,0,1,'Textbox',1,300,1,24,1,1,0,1,NULL,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL)
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
(4282,'helptext','If position is no longer needed, please delete the request',11910)
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
(2330)
,
(2371)
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
(5944,2330,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(5945,2330,5944,1,16,3,11825,NULL,'1',NULL,NULL)
,
(6031,2371,NULL,1,1,NULL,NULL,NULL,NULL,NULL,NULL)
,
(6032,2371,6031,1,3,4,11975,NULL,'false',NULL,NULL)
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
(2325,'Show/hide',NULL,11824,NULL,2,2326)
,
(2326,'Show/hide',NULL,11824,NULL,2,2327)
,
(2327,'Show/hide',NULL,11836,NULL,2,2328)
,
(2328,'Show/hide',NULL,11836,NULL,2,2329)
,
(2329,'Show/hide',NULL,11825,NULL,2,2330)
,
(2330,'Show/hide',NULL,11826,NULL,2,2331)
,
(2331,'Show/hide',NULL,11827,NULL,2,2332)
,
(2342,'Show when Other/New',NULL,11838,NULL,2,2343)
,
(2344,'Show when Yes',NULL,11930,NULL,2,2345)
,
(2346,'Show when Yes',NULL,11946,NULL,2,2347)
,
(2348,'Show when Yes',NULL,11956,NULL,2,2349)
,
(2370,'Show or Hide Other on Faculity',NULL,11975,NULL,2,2371)
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
(4616,'Show/hide',NULL,7222,2325)
,
(4617,'Show/hide',NULL,7211,2326)
,
(4618,'Show/Hide',NULL,7212,2326)
,
(4619,'Show/hide',NULL,7237,2327)
,
(4620,'Show/hide',NULL,7238,2328)
,
(4621,'Show/hide',NULL,7225,2329)
,
(4622,'Show/hide',NULL,7233,2330)
,
(4623,'Show/hide',NULL,7230,2331)
,
(4637,'Show/hide',NULL,7289,2329)
,
(4639,'Show when Other/New',11916,NULL,2342)
,
(4641,'Show/hide',NULL,7291,2330)
,
(4643,'Show/hide',NULL,7293,2331)
,
(4645,'Show when Yes',NULL,7301,2344)
,
(4646,'Show when Yes',NULL,7299,2344)
,
(4649,'Show when Yes',NULL,7313,2346)
,
(4650,'Show when Yes',NULL,7315,2346)
,
(4653,'Show when Yes',NULL,7321,2348)
,
(4654,'Show when Yes',NULL,7323,2348)
,
(4677,'Other',11799,NULL,2370)
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
(26,'New Item',NULL,1,'ModuleResourceRequest','MaxText03',1,1,'Feb  5 2024  1:58PM',NULL,1)
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