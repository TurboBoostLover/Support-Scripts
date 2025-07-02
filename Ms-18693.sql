USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18693';
DECLARE @Comments nvarchar(Max) = 
	'Update the PSD report';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
declare @bit3 int
declare @bit4 int 
declare @text nvarchar(max) = ''''
declare @resourcesCount int
declare @start int = 0

select @bit3=bit03, @bit4=bit04 from GenericBit where ProgramId = @entityId

if (@bit4 = 1)
	begin
		set @text += ''
			<style type="text/css">
			.tk  {border-collapse:collapse;border-spacing:0;}
			.tk td{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
			  overflow:hidden;padding:10px 5px;word-break:normal;}
			.tk th{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
			  font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
			.tk .tg-c3ow{border-color:inherit;text-align:center;vertical-align:top}
			.tk .tg-0pky{border-color:inherit;text-align:left;vertical-align:top}
			</style>
		''
		DECLARE @fundingRequestOptions NVARCHAR(MAX) = (SELECT dbo.ConcatWithSepOrdered_Agg('''', Id, CONCAT(''<li>'', ShortText, ''</li>'')) FROM Lookup01 WHERE Active = 1 and Lookup01ParentId is not null)

		set @text += concat(''
		<table class="tk">
		<thead>
		  <tr>
			<th class="tg-c3ow""></th>
			<th class="tg-c3ow">New Resources</th>
			<th class="tg-0pky">
			Funding Request
			<ol type="a">'',
				@fundingRequestOptions,
			''</ol>
			</th>
			<th class="tg-c3ow">Date of assumption of duty</th>
		  </tr>
	   </thead>
	   <tbody>
		'')

		select @resourcesCount = count(*) from ProgramLookup01 where ProgramId = @entityId

		while (@start < @resourcesCount)
			begin
			set @text += (select concat(
			''<tr><td class="tg-0pky">'', @start + 1, ''</td>'',
			''<td class="tg-0pky">'', MaxText01, ''</td>'',
			''<td class="tg-0pky">'', lu.ShortText, ''</td>'',
			''<td class="tg-0pky">'', Date01, ''</td></tr>''
			) from ProgramComparableType pct
			inner join Lookup01 lu on pct.Lookup01Id_01 = lu.Id
			where ProgramId = @entityId
			order by ProgramId
			offset @start rows
			fetch next 1 rows only)

			set @start += 1
			end
		set @text += ''</tbody></table>''
	end

select 0 as Value, @text as Text
'
, ResolutionSql = '
declare @bit3 int
declare @bit4 int 
declare @text nvarchar(max) = ''''
declare @resourcesCount int
declare @start int = 0

select @bit3=bit03, @bit4=bit04 from GenericBit where ProgramId = @entityId

if (@bit4 = 1)
	begin
		set @text += ''
			<style type="text/css">
			.tk  {border-collapse:collapse;border-spacing:0;}
			.tk td{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
			  overflow:hidden;padding:10px 5px;word-break:normal;}
			.tk th{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
			  font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
			.tk .tg-c3ow{border-color:inherit;text-align:center;vertical-align:top}
			.tk .tg-0pky{border-color:inherit;text-align:left;vertical-align:top}
			</style>
		''
		DECLARE @fundingRequestOptions NVARCHAR(MAX) = (SELECT dbo.ConcatWithSepOrdered_Agg('''', Id, CONCAT(''<li>'', ShortText, ''</li>'')) FROM Lookup01 WHERE Active = 1 and Lookup01ParentId is not null)

		set @text += concat(''
		<table class="tk">
		<thead>
		  <tr>
			<th class="tg-c3ow""></th>
			<th class="tg-c3ow">New Resources</th>
			<th class="tg-0pky">
			Funding Request
			<ol type="a">'',
				@fundingRequestOptions,
			''</ol>
			</th>
			<th class="tg-c3ow">Date of assumption of duty</th>
		  </tr>
	   </thead>
	   <tbody>
		'')

		select @resourcesCount = count(*) from ProgramLookup01 where ProgramId = @entityId

		while (@start < @resourcesCount)
			begin
			set @text += (select concat(
			''<tr><td class="tg-0pky">'', @start + 1, ''</td>'',
			''<td class="tg-0pky">'', MaxText01, ''</td>'',
			''<td class="tg-0pky">'', lu.ShortText, ''</td>'',
			''<td class="tg-0pky">'', Date01, ''</td></tr>''
			) from ProgramComparableType pct
			inner join Lookup01 lu on pct.Lookup01Id_01 = lu.Id
			where ProgramId = @entityId
			order by ProgramId
			offset @start rows
			fetch next 1 rows only)

			set @start += 1
			end
		set @text += ''</tbody></table>''
	end

select 0 as Value, @text as Text
'
WHERE Id = 228

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT
1, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Attachments', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
9, -- [RowPosition]
9, -- [SortOrder]
1, -- [SectionDisplayId]
15, -- [MetaSectionTypeId]
MetaTemplateId, -- [MetaTemplateId]
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
FROM MetaTemplate WHERE MetaTemplateTypeId = 23

DECLARE @Tab int = SCOPE_IDENTITY()

DECLARE @Temp int = (SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 23)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@Tab, -- [MetaSelectedSection_MetaSelectedSectionId]
'Attached File', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
14, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
143, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)

DECLARE @Sec int = SCOPE_IDENTITY()

DECLARE @Fields TABLE (FieldId int, nam NVARCHAR(MAX))

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId, inserted.DisplayName INTO @Fields
values
(
'Attached File Name', -- [DisplayName]
1095, -- [MetaAvailableFieldId]
@Sec, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Title', -- [DisplayName]
1222, -- [MetaAvailableFieldId]
@Sec, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Disk Name', -- [DisplayName]
1379, -- [MetaAvailableFieldId]
@Sec, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Mime Type', -- [DisplayName]
1380, -- [MetaAvailableFieldId]
@Sec, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'FieldSpecialization', 'UploadFilenameField', FieldId FROM @Fields WHERE nam = 'Title'
UNION
SELECT 'FieldSpecialization', 'UploadTextnameField', FieldId FROM @Fields WHERE nam = 'Attached File Name'
UNION
SELECT 'FieldSpecialization', 'UploadDiscnameField', FieldId FROM @Fields WHERE nam = 'Disk Name'
UNION
SELECT 'FieldSpecialization', 'UploadMimetypeField', FieldId FROM @Fields WHERE nam = 'Mime Type'

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT
1, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Attachments', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
9, -- [RowPosition]
9, -- [SortOrder]
1, -- [SectionDisplayId]
15, -- [MetaSectionTypeId]
MetaTemplateId, -- [MetaTemplateId]
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
FROM MetaTemplate WHERE MetaTemplateTypeId = 17

SET @Tab = SCOPE_IDENTITY()

SET @Temp = (SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 17)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@Tab, -- [MetaSelectedSection_MetaSelectedSectionId]
'Attached File', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
14, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
143, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)

DECLARE @Sec2 int = SCOPE_IDENTITY()

DECLARE @Fields2 TABLE (FieldId int, nam NVARCHAR(MAX))

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId, inserted.DisplayName INTO @Fields2
values
(
'Attached File Name', -- [DisplayName]
1095, -- [MetaAvailableFieldId]
@Sec2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Title', -- [DisplayName]
1222, -- [MetaAvailableFieldId]
@Sec2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Disk Name', -- [DisplayName]
1379, -- [MetaAvailableFieldId]
@Sec2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Mime Type', -- [DisplayName]
1380, -- [MetaAvailableFieldId]
@Sec2, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'FieldSpecialization', 'UploadFilenameField', FieldId FROM @Fields2 WHERE nam = 'Title'
UNION
SELECT 'FieldSpecialization', 'UploadTextnameField', FieldId FROM @Fields2 WHERE nam = 'Attached File Name'
UNION
SELECT 'FieldSpecialization', 'UploadDiscnameField', FieldId FROM @Fields2 WHERE nam = 'Disk Name'
UNION
SELECT 'FieldSpecialization', 'UploadMimetypeField', FieldId FROM @Fields2 WHERE nam = 'Mime Type'

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
SELECT
1, -- [ClientId]
NULL, -- [MetaSelectedSection_MetaSelectedSectionId]
'Attachments', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
9, -- [RowPosition]
9, -- [SortOrder]
1, -- [SectionDisplayId]
15, -- [MetaSectionTypeId]
MetaTemplateId, -- [MetaTemplateId]
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
FROM MetaTemplate WHERE MetaTemplateTypeId = 21

SET @Tab = SCOPE_IDENTITY()

SET @Temp = (SELECT MetaTemplateId FROM MetaTemplate WHERE MetaTemplateTypeId = 21)

insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@Tab, -- [MetaSelectedSection_MetaSelectedSectionId]
'Attached File', -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
0, -- [RowPosition]
0, -- [SortOrder]
1, -- [SectionDisplayId]
14, -- [MetaSectionTypeId]
@Temp, -- [MetaTemplateId]
NULL, -- [DisplayFieldId]
NULL, -- [HeaderFieldId]
NULL, -- [FooterFieldId]
0, -- [OriginatorOnly]
143, -- [MetaBaseSchemaId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EntityListLibraryTypeId]
NULL, -- [EditMapId]
1, -- [AllowCopy]
0, -- [ReadOnly]
NULL-- [Config]
)

DECLARE @Sec3 int = SCOPE_IDENTITY()

DECLARE @Fields3 TABLE (FieldId int, nam NVARCHAR(MAX))

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
output inserted.MetaSelectedFieldId, inserted.DisplayName INTO @Fields3
values
(
'Attached File Name', -- [DisplayName]
1095, -- [MetaAvailableFieldId]
@Sec3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Title', -- [DisplayName]
1222, -- [MetaAvailableFieldId]
@Sec3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
0, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Disk Name', -- [DisplayName]
1379, -- [MetaAvailableFieldId]
@Sec3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
2, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
),
(
'Mime Type', -- [DisplayName]
1380, -- [MetaAvailableFieldId]
@Sec3, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
3, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
1, -- [MetaPresentationTypeId]
300, -- [Width]
1, -- [WidthUnit]
24, -- [Height]
1, -- [HeightUnit]
1, -- [AllowLabelWrap]
0, -- [LabelHAlign]
1, -- [LabelVAlign]
0, -- [LabelStyleId]
1, -- [LabelVisible]
0, -- [FieldStyle]
NULL, -- [EditDisplayOnly]
NULL, -- [GroupName]
NULL, -- [GroupNameDisplay]
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'FieldSpecialization', 'UploadFilenameField', FieldId FROM @Fields3 WHERE nam = 'Title'
UNION
SELECT 'FieldSpecialization', 'UploadTextnameField', FieldId FROM @Fields3 WHERE nam = 'Attached File Name'
UNION
SELECT 'FieldSpecialization', 'UploadDiscnameField', FieldId FROM @Fields3 WHERE nam = 'Disk Name'
UNION
SELECT 'FieldSpecialization', 'UploadMimetypeField', FieldId FROM @Fields3 WHERE nam = 'Mime Type'

--Report "Programme Specifications Document", page/section "Section 1 General Information about the Programme", custom display field "Table 1.1: General Information of the Programme", field "Mode of Delivery", update custom display.
DECLARE @SQL NVARCHAR(MAX)
	set quoted_identifier off;
	set @sql = ("
declare @title NVARCHAR(max)
declare @title2 NVARCHAR(MAX)
declare @awardGrantingBody NVARCHAR(max)
declare @primaryAreaStudy NVARCHAR(max)
declare @subAreaStudy NVARCHAR(max)
declare @otherAreaStudy NVARCHAR(max)
declare @programmeLength NVARCHAR(max)
declare @academyCredit NVARCHAR(max)
declare @QFCredit NVARCHAR(max)
declare @QFLevel NVARCHAR(max)
declare @launchYear NVARCHAR(max)
declare @launchMonth NVARCHAR(max)
declare @targetStudents NVARCHAR(max)
declare @studentIntakesPerYear NVARCHAR(max)
declare @studentsPerIntake NVARCHAR(max)
declare @QualificationTitle NVARCHAR(MAX)

select @title = Title from Program
where Id = @entityId

select @title2 = TitleAlias from Program
where Id = @entityId

SELECT @QualificationTitle = coalesce(awt.Code + ' - ','') + awt.Title From AwardTypeAlias AS awt
INNER JOIN Program AS p on p.AwardTypeAliasId = awt.Id
WHERE p.Id = @EntityId

select @awardGrantingBody = lr.Text	
	from ProgramDetail pd 
		inner join LettersOfRecommendationRequirement lr on pd.LettersOfRecommendationRequirementId = lr.Id
	where pd.ProgramId = @entityId

select @primaryAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.First_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @subAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.Second_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @otherAreaStudy = CareerOption 
from Program
where Id = @entityId

select @programmeLength = cc.Title
from Program p
	inner join CategoryCode cc on p.CategoryCodeId = cc.Id
where p.Id = @entityId

select @academyCredit = Int05 
from GenericInt
where ProgramId = @entityId

select @QFCredit = ICCBCreditHours 
from Program
where Id = @entityId

select @QFLevel = qfl.Title
from Program p
	inner join QFLevel qfl on p.QFLevelId = qfl.Id
where p.Id = @entityId

select @launchYear = StartYear 
from ProgramProposal
where ProgramId = @entityId

select  @launchMonth = m.MonthName
from Program p
	inner join Months m on m.Id = p.StartMonth
where p.Id = @entityId

select @targetStudents = EntranceRequirementsText 
from program
where Id = @entityId

select @studentIntakesPerYear = ClassStaffCount
from Program
where Id = @entityId

select @studentsPerIntake = CertificationStaffCount
from Program
where Id = @entityId

declare @modesOfDeliveryFT nvarchar(max) = (
	select 
		case
			when ft.RenderedText is not null
				then 
				concat (
					'<b>Full Time</b><br />'
					, ft.RenderedText
					, '<br />'
				)
			else ''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('', dm.Id, concat('<li style =""list-style-type: none;"">', dm.Title, '</li>')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 1--Full Time
	) ft
)

declare @modesOfDeliverPT nvarchar(max) = (
	select
		case
			when pt.RenderedText is not null
				then
				concat(
					'<b>Part-Time</b>'
					, pt.RenderedText
					, '<br />'
				)
			else ''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('', dm.Id, concat('<li style =""list-style-type: none;"">', dm.Title, '</li>')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 4--Part-Time
	) pt
)

declare @modesOfDeliverFTPT nvarchar(max) = (
	select
		case
			when ftpt.RenderedText is not null
				then
				concat(
					'<b>Full-Time and Part-time</b>'
					, ftpt.RenderedText
					, '<br />'
				)
			else ''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('', dm.Id, concat('<li style =""list-style-type: none;"">', dm.Title, '</li>')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 5--Full-Time and Part-time
	) ftpt
)

declare @modesOfDelivery nvarchar(max) = (
	select 
	concat(
		@modesOfDeliveryFT
		, @modesOfDeliverPT
		, @modesOfDeliverFTPT
	)
)

DECLARE @tbody NVARCHAR(MAX) = (CONCAT(
'<table style=""border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; font-size: 14px;"">',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left; width: 30%;"">Programme Title (English)</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@title, '&nbsp;'), '</td>',
    '</tr>',
		'<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left; width: 30%;"">Programme Title (Chinese)</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@title2, '&nbsp;'), '</td>',
    '</tr>',
		'<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left; width: 30%;"">Qualification Title</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@QualificationTitle, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Award Granting Body</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@awardGrantingBody, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Mode of Delivery</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@modesOfDelivery, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Primary Area of Study / Training</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@primaryAreaStudy, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Sub Area of Study / Training</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@subAreaStudy, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Other Area of Study / Training (if any)</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@otherAreaStudy, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Programme Length</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@programmeLength, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Academy Credit</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@academyCredit, '&nbsp;'), '</td>',
    '</tr>',
    --'<tr>',
    --    '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">QF Credits</th>',
    --    '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@QFCredit, '&nbsp;'), '</td>',
    --'</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">QF Level</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@QFLevel, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Planned Programme Launch Date</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@launchMonth, '&nbsp;'), ', ', ISNULL(@launchYear, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Target Students</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@targetStudents, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Number of Student Intakes Per Year</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@studentIntakesPerYear, '&nbsp;'), '</td>',
    '</tr>',
    '<tr>',
        '<th style=""border: 1px solid black; padding: 8px; text-align: left;"">Number of Students Per Intake</th>',
        '<td style=""border: 1px solid black; padding: 8px;"">', ISNULL(@studentsPerIntake, '&nbsp;'), '</td>',
    '</tr>',
'</table>'
))

SELECT 0 AS [Value], CONCAT(@tbody, '<br>') AS [Text]
	");
	set quoted_identifier on;

	update MetaForeignKeyCriteriaClient
	set CustomSql = @sql
		, ResolutionSql = @sql
	where Id = 224
	;

DECLARE @EnglishProgramTitle TABLE (SecId int, FieldId int, TempId int, pos int)
INSERT INTO @EnglishProgramTitle
SELECT msf.MetaSelectedSectionId, MetaSelectedFieldId, mss.MetaTemplateId, msf.RowPosition FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection As mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaTemplate As mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE msf.MetaAvailableFieldId = 1225
and mt.EndDate IS NULL
and mtt.Active = 1
and mtt.IsPresentationView = 0

UPDATE MetaSelectedField
SET RowPosition = RowPosition + 1
FROM MetaSelectedField AS msf
INNER JOIN @EnglishProgramTitle AS en on msf.MetaSelectedSectionId = en.SecId
WHERE msf.RowPosition > en.pos

insert into [MetaSelectedField]
([DisplayName], [MetaAvailableFieldId], [MetaSelectedSectionId], [IsRequired], [MinCharacters], [MaxCharacters], [RowPosition], [ColPosition], [ColSpan], [DefaultDisplayType], [MetaPresentationTypeId], [Width], [WidthUnit], [Height], [HeightUnit], [AllowLabelWrap], [LabelHAlign], [LabelVAlign], [LabelStyleId], [LabelVisible], [FieldStyle], [EditDisplayOnly], [GroupName], [GroupNameDisplay], [FieldTypeId], [ValidationRuleId], [LiteralValue], [ReadOnly], [AllowCopy], [Precision], [MetaForeignKeyLookupSourceId], [MetadataAttributeMapId], [EditMapId], [NumericDataLength], [Config])
SELECT
'Programme Title (Chinese)', -- [DisplayName]
1665, -- [MetaAvailableFieldId]
SecId, -- [MetaSelectedSectionId]
0, -- [IsRequired]
NULL, -- [MinCharacters]
NULL, -- [MaxCharacters]
Pos + 1, -- [RowPosition]
0, -- [ColPosition]
1, -- [ColSpan]
'Textbox', -- [DefaultDisplayType]
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
1, -- [FieldTypeId]
NULL, -- [ValidationRuleId]
NULL, -- [LiteralValue]
0, -- [ReadOnly]
1, -- [AllowCopy]
NULL, -- [Precision]
NULL, -- [MetaForeignKeyLookupSourceId]
NULL, -- [MetadataAttributeMapId]
NULL, -- [EditMapId]
NULL, -- [NumericDataLength]
NULL-- [Config]
FROM @EnglishProgramTitle

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE mtt.EntityTypeId = 2