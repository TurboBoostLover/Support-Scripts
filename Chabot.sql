DECLARE @OverRidefields TABLE (SecId int, RowPosition int, TempId int, RuleId int, ParentId int)
INSERT INTO @OverRidefields
SELECT  msf.MetaSelectedSectionId, mss.RowPosition, mss.MetaTemplateId, mds.Id, mss.MetaSelectedSection_MetaSelectedSectionId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaDisplaySubscriber AS mds on mds.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.DisplayName like '%Override%' 
and msf.DisplayName not like '%Do you%' 
and msf.DisplayName not like '%below%'

while exists(select top 1 1 from @OverRidefields)
begin
	DECLARE @Sectocopy int = (SELECT TOP 1 SecId FROM @OverRidefields)
	DECLARE @row int = (SELECT RowPosition FROM @OverRidefields WHERE SecId = @Sectocopy)
	DECLARE @Rule int = (SELECT RuleId FROM @OverRidefields WHERE SecId = @Sectocopy)
	DECLARE @ParentSec int = (SELECT ParentId FROM @OverRidefields WHERE SecId = @Sectocopy)
	DECLARE @TemplateSec int = (SELECT TempId FROM @OverRidefields WHERE SecId = @Sectocopy)

	UPDATE MetaSelectedSection
	SET RowPosition = RowPosition + 1
	WHERE RowPosition > @row
	and MetaSelectedSection_MetaSelectedSectionId = @ParentSec

	insert into [MetaSelectedSection]
([ClientId], [MetaSelectedSection_MetaSelectedSectionId], [SectionName], [DisplaySectionName], [SectionDescription], [DisplaySectionDescription], [ColumnPosition], [RowPosition], [SortOrder], [SectionDisplayId], [MetaSectionTypeId], [MetaTemplateId], [DisplayFieldId], [HeaderFieldId], [FooterFieldId], [OriginatorOnly], [MetaBaseSchemaId], [MetadataAttributeMapId], [EntityListLibraryTypeId], [EditMapId], [AllowCopy], [ReadOnly], [Config])
values
(
1, -- [ClientId]
@ParentSec, -- [MetaSelectedSection_MetaSelectedSectionId]
NULL, -- [SectionName]
1, -- [DisplaySectionName]
NULL, -- [SectionDescription]
0, -- [DisplaySectionDescription]
NULL, -- [ColumnPosition]
@row + 1, -- [RowPosition]
@row + 1, -- [SortOrder]
1, -- [SectionDisplayId]
1, -- [MetaSectionTypeId]
@TemplateSec, -- [MetaTemplateId]
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

DECLARE @Sec12 int = SCOPE_IDENTITY()

INSERT INTO MetaDisplaySubscriber
(MetaSelectedSectionId, MetaDisplayRuleId, SubscriberName)
VALUES
(@Sec12, @Rule, 'Maverick Conversion')

DELETE FROM @OverRidefields WHERE SecId = @Sectocopy

end