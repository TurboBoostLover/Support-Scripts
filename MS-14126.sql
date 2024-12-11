USE [evc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14126';
DECLARE @Comments nvarchar(Max) = 
	'Update ILO Assessment';
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
Declare @clientId int =22, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =6; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId = 512

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('Student Data', 'ModuleRelatedModule', 'Reference_CourseId','Ping'),
('Analysis', 'ModuleExtension01', 'TextMax03','Ping2'),
('Student Data', 'ModuleRelatedModule01', 'Reference_ProgramId','Ping3')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and mss.SectionName = rfc.TabName)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
DECLARE @Re int =(SELECT SectionId FROM @Fields WHERE Action = 'Ping')
DECLARE @Re2 int =(SELECT SectionId FROM @Fields WHERE Action = 'Ping3')

UPDATE MetaSelectedSection
SET RowPosition = RowPosition + 2
, SortOrder = SortOrder + 2
WHERE MetaSelectedSectionId in (
	SELECT TabId FROM @Fields WHERE Action in ('Ping', 'Ping2')
)

DECLARE @Temp int = (SELECT TemplateId FROM @Fields WHERE Action = 'Ping')

DECLARE @TABLE TABLE (Id int identity, Id2 int, Names nvarchar(max))

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
output inserted.MetaSelectedSectionId, inserted.SectionName INTO @TABLE (Id2, Names)
values
(
22, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Stand Alone Courses', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
3, -- [RowPosition]
2, -- [SortOrder]
1, -- [SectionDisplayId]
30, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
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
,
(
22, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Programs with ILO', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
4, -- [RowPosition]
3, -- [SortOrder]
1, -- [SectionDisplayId]
30, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
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

DECLARE @Tab1 int = (SELECT Id2 FROM @TABLE WHERE Id = 1 AND Names = 'Stand Alone Courses')
DECLARE @Tab2 int = (SELECT Id2 FROM @TABLE WHERE Id = 2 AND Names = 'Programs with ILO')
DECLARE @Tab3 int = (SELECT DISTINCT TabId FROM @Fields WHERE Action = 'Ping')

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
OUTPUT inserted.MetaSelectedSectionId, inserted.SectionName INTO @TABLE (Id2, Names)
values
(
22, -- [ClientId]
@Tab1, -- [MetaSelectedSection_MetaSelectedSectionId]
'Stand Alone Courses with ILO', -- [SectionName]
1, -- [DisplaySectionName]
'Courses that are in red have not been assessed.', -- [SectionDescription]
1, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
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
,
(
22, -- [ClientId]
@Tab2, -- [MetaSelectedSection_MetaSelectedSectionId]
'Programs with ILO', -- [SectionName]
1, -- [DisplaySectionName]
'Programs that are in red have not been assessed.', -- [SectionDescription]
1, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
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
,
(
22, -- [ClientId]
@Tab3, -- [MetaSelectedSection_MetaSelectedSectionId]
'Results', -- [SectionName]
0, -- [DisplaySectionName]
NULL, -- [SectionDescription]
1, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
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

DECLARE @SEC1 int = (SELECT Id2 FROM @TABLE WHERE Id = 3 AND Names = 'Stand Alone Courses with ILO')
DECLARE @SEC2 int = (SELECT Id2 FROM @TABLE WHERE Id = 4 AND Names = 'Programs with ILO')
DECLARE @SEC3 int = (SELECT Id2 FROM @TABLE WHERE Id = 5 AND Names = 'Results')

DECLARE @MAX int = (SELECT MAX(Id) FROM MetaForeignKeyCriteriaClient) + 1

DECLARE @SQL nvarchar(max) = '
declare @ILO int = (SELECT ClientLearningOutcomeParentId FROM ModuleDetail WHERE ModuleId = @entityid)

DECLARE @Courses TABLE (val int, Texts nvarchar(max), Texts2 nvarchar(max))
INSERT INTO @Courses
SELECT DISTINCT	0 AS Value ,
CAST(        
    Case                
        when (                        
            SELECT Count(M.ID) FROM module M                                
                Inner Join ModuleDetail MD ON M.ID = MD.ModuleId                        
            WHERE M.StatusAliasId = 396                                
            AND M.Active =1                                
            AND MD.Active_CourseId = C.Id                    
            ) =0                
        then ''<span style="color:red;">'' + C.EntityTitle + ''</span>''               
        ELSE  c.EntityTitle             
    END AS Nvarchar(MAX))
		AS Text, c.EntityTitle
FROM CourseOutcomeClientLearningOutcome coclo     
    INNER JOIN ClientLearningOutcome clo	ON clo.Id = coclo.ClientLearningOutcomeId    
    INNER JOIN CourseOutcome co	ON co.id = coclo.CourseOutcomeId    
    INNER JOIN course c	ON c.id = co.CourseId    
WHERE clo.id = @ILO     
    And c.StatusAliasId =396  
    And c.Active =1    
		ORDER BY c.EntityTitle

	SELECT 0 AS Value, dbo.ConcatWithSep_Agg(''<br>'', Texts) AS Text FROM @Courses
'

DECLARE @SQL2 nvarchar(max) = '
declare @ILO int = (SELECT ClientLearningOutcomeParentId FROM ModuleDetail WHERE ModuleId = @entityid)

declare @Programs TABLE (val int, Texts nvarchar(max), Texts2 nvarchar(max))
INSERT INTO @Programs
SELECT DISTINCT	0 AS Value   ,CAST(        
    Case                
        when (                        
            SELECT Count(M.ID) FROM module M                                
                Inner Join ModuleDetail MD ON M.ID = MD.ModuleId                   
                Inner Join MetaTemplate MT ON M.MetaTemplateID = MT.MetaTemplateId                
                INNER JOIN MetaTemplateType MTT ON MT.MetaTemplateTypeId = MTT.MetaTemplateTypeId                     
            WHERE M.StatusAliasId = 396                               
                AND M.Active =1                                
                AND MD.Reference_ProgramId = P.ID                  
                AND MTT.ClientEntityTypeId =51             
        ) =0                
        then ''<span style="color:red;">'' + P.EntityTitle + ''</span>''          
        ELSE  P.EntityTitle             
    END AS Nvarchar(MAX)) AS Text, P.EntityTitle
FROM ClientLearningOutcomeProgramOutcome CLOPO    
    INNER JOIN ClientLearningOutcome CLO ON CLOPO.ClientLearningOutcomeId = CLO.Id    
    INNER JOIN ProgramOutcome PO ON CLOPO.ProgramOutcomeId = PO.Id    
    INNER JOIN Program P ON PO.ProgramId = P.Id
WHERE clo.id = @ILO     
    AND P.Active =1    
    AND p.StatusAliasId =396
Order By P.EntityTitle

SELECT 0 AS Value, dbo.ConcatWithSep_Agg(''<br>'', Texts) AS Text FROM @Programs
'
DECLARE @SQL3 NVARCHAR(MAX) = '
declare @ILO int = (SELECT ClientLearningOutcomeParentId FROM ModuleDetail WHERE ModuleId = @entityid)

DECLARE @Courses TABLE (val int, Texts nvarchar(max), Id int)
INSERT INTO @Courses (val, Id, Texts)
SELECT DISTINCT	0 AS Value ,
 c.Id,
 c.EntityTitle AS Texts
FROM CourseOutcomeClientLearningOutcome coclo     
    INNER JOIN ClientLearningOutcome clo	ON clo.Id = coclo.ClientLearningOutcomeId    
    INNER JOIN CourseOutcome co	ON co.id = coclo.CourseOutcomeId    
    INNER JOIN course c	ON c.id = co.CourseId
WHERE clo.id = @ILO     
    And c.StatusAliasId =396  
    And c.Active =1    
		ORDER BY c.EntityTitle

DECLARE @Results TABLE (Id int, Texts nvarchar(max), Texts2 nvarchar(max), ping nvarchar(max))
INSERT INTO @Results
SELECT DISTINCT c.Id, co.OutcomeText, l9.ShortText, c.EntityTitle
FROM ModuleRelatedModule02 AS mrm
INNER JOIN CourseOutcome AS co on mrm.Reference_CourseOutcomeId = co.Id
INNER JOIN Course AS c on co.CourseId = c.Id
INNER JOIN CourseOutcome AS co2 on co2.CourseId = c.Id
INNER JOIN Lookup09 AS l9 on mrm.Lookup09Id_01 = l9.Id
INNER JOIN @Courses AS c2 on c2.Id = c.Id
WHERE c.StatusAliasId =396  
    And c.Active =1    
		ORDER BY c.EntityTitle

DECLARE @END TABLE (val int, Texts nvarchar(max))
INSERT INTO @END
SELECT DISTINCT
    0 AS Value,
    CONCAT(
        c.Texts,
        ''<li>'',
        STUFF((
            SELECT
                ''<li>'' + CONCAT(
                    r.Texts,
                    CASE WHEN r.Texts2 IS NOT NULL THEN CONCAT(''<ul><li>'', r.Texts2, ''</li></ul>'') ELSE '''' END
                )
            FROM @Results AS r
            WHERE c.Id = r.Id
            FOR XML PATH(''''), TYPE
        ).value(''.'', ''NVARCHAR(MAX)''), 1, 4, ''''), -- Remove leading comma and space
        ''</li></ul>''
    ) AS CombinedTexts
FROM @Courses AS c;

SELECT 0 AS Value, dbo.ConcatWithSep_Agg(''<br>'' ,Texts) AS Text FROM @END
'

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, Title, LookupLoadTimingType)
VALUES
(@MAX, 'modulequerytext', 'Id', 'Title', @SQL, @SQL, 'Stand Alone Courses', 2),
(@MAX + 1, 'modulequerytext', 'Id', 'Title', @SQL2, @SQL2, 'Programs with ILO', 2),
(@MAX + 2, 'modulequerytext', 'Id', 'Title', @SQL3, @SQL3, 'Programs with ILO', 2)

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
values
(
'Courses with ILO', -- [DisplayName]
9265, -- [MetaAvailableFieldId]
@SEC1, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@MAX, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'Programs with ILO', -- [DisplayName]
9266, -- [MetaAvailableFieldId]
@SEC2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@Max + 1, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)
,
(
'Results', -- [DisplayName]
9267, -- [MetaAvailableFieldId]
@SEC3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'QueryText', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
NULL, -- [LabelStyleId]
0, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
5, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
1, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
@Max + 2, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

EXEC spBuilderSectionDelete @clientId, @Re
EXEC spBuilderSectionDelete @clientId, @Re2

UPDATE MetaSelectedSection
SET MetaSectionTypeId = 30
WHERE MetaSelectedSectionId = @Tab3
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

exec EntityExpand @clientId =22 , @entityTypeId =6

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback

