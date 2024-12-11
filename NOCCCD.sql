DECLARE @StaticText INTEGERS
INSERT INTO @StaticText
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId IS NULL
and DisplayName = 'Min Total'
and MetaPresentationTypeId = 35
UNION
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId IS NULL
and DisplayName = 'Max Total'
and MetaPresentationTypeId = 35
UNION
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId IS NULL
and DisplayName IS NULL

DELETE FROM MetaSelectedField
WHERE MetaSelectedFieldId in (
	SELECT Id FROM @StaticText
)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 1426		--NULL
, MetaPresentationTypeId = 1		--102
, FieldTypeId = 1	--3
, RowPosition = 1
, ColPosition = 0
WHERE MetaSelectedFieldId in (6026, 4322, 4538)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 1427		--NULL
, MetaPresentationTypeId = 1		--102
, FieldTypeId = 1	--3
, RowPosition = 3
, ColPosition = 0
WHERE MetaSelectedFieldId in (6027, 4323, 4539)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 169		--NULL
, MetaPresentationTypeId = 1		--102
, FieldTypeId = 1	--3
, RowPosition = 3
, ColPosition = 0
WHERE MetaSelectedFieldId in (6028, 4325, 4540)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2486		--NULL
, MetaPresentationTypeId = 1		--102
, FieldTypeId = 1	--3
, RowPosition = 5
, ColPosition = 0
WHERE MetaSelectedFieldId in (6029, 4326, 4541)

---------------------------------------------------
UPDATE MetaSelectedField
SET MetaAvailableFieldId = 1426		--NULL
, MetaPresentationTypeId = 1		--102
, FieldTypeId = 1	--3
, RowPosition = 4
, ColPosition = 0
WHERE MetaSelectedFieldId in (1206)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 1427		--NULL
, MetaPresentationTypeId = 1		--102
, FieldTypeId = 1	--3
, RowPosition = 5
, ColPosition = 0
WHERE MetaSelectedFieldId in (1207)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 169		--NULL
, MetaPresentationTypeId = 1		--102
, FieldTypeId = 1	--3
, RowPosition = 3
, ColPosition = 0
WHERE MetaSelectedFieldId in (1209)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 2486		--NULL
, MetaPresentationTypeId = 1		--102
, FieldTypeId = 1	--3
, RowPosition = 4
, ColPosition = 0
WHERE MetaSelectedFieldId in (1210)
----------------------------------------------------------
Merge MetaSelectedFieldAttribute as Target 
	using 
		(
			select 'helptext' as Name, msfa1.Value, msfa1.MetaSelectedFieldId  
	from MetaSelectedFieldAttribute msfa1
	where Name = 'subtext'
	And Not Exists 
	(
	select msfa2.MetaSelectedFieldId 
	from MetaSelectedFieldAttribute msfa2
	where Name = 'HelpText'
		And msfa2.MetaSelectedFieldId
		= msfa1.MetaSelectedFieldId 
	)
) as Source (Name,Value, MetaSelectedFieldId)
	On source.Name = Target.Name
	And source.Value = Target.Value
	And source.MetaSelectedFieldId = Target.MetaSelectedFieldId
When not matched then 
INSERT  (Name,Value, MetaSelectedFieldId)
values  (source.Name,source.Value, source.MetaSelectedFieldId);

UPDATE MetaSelectedField
SET IsRequired = 0
WHERE MetaSelectedFieldId in (
SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE 
(MetaPresentationTypeId = 5
or 
(MetaPresentationTypeId = 1 and FieldTypeId = 5)
or MetaPresentationTypeId = 103)
AND IsRequired = 1
)

UPDATE msf
SET DisplayName = dbo.Format_RemoveAccents(dbo.stripHtml(DisplayName))
from MetaSelectedField msf
    inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
    inner join MetaSelectedSection mss2 on mss2.MetaSelectedSectionId = mss.MetaSelectedSection_MetaSelectedSectionId
    inner join MetaTemplate mt on mt.MetaTemplateId = mss.MetaTemplateId
    inner join MetaTemplateType mtt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    inner join EntityType et on et.Id = mtt.EntityTypeId
where msf.DisplayName <> dbo.Format_RemoveAccents(dbo.stripHtml(msf.DisplayName))
	and msf.MetaAvailableFieldId is not null
	and mtt.IsPresentationView = 0
	and mt.Active = 1
	and mtt.Active = 1

UPDATE mss
SET SectionName = dbo.Format_RemoveAccents(dbo.stripHtml(mss.SectionName))
from MetaSelectedSection mss
    inner join MetaTemplate mt on mt.MetaTemplateId = mss.MetaTemplateId
    inner join MetaTemplateType mtt on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    inner join EntityType et on et.Id = mtt.EntityTypeId
where mss.SectionName <> dbo.Format_RemoveAccents(dbo.stripHtml(mss.SectionName))
	and mtt.IsPresentationView = 0
	and mt.Active = 1
	and mtt.Active = 1

DECLARE @titleFieldsMAF integers
Insert into @titleFieldsMAF
SELECT
	maf.MetaAvailableFieldId
FROM ListItemType lit
	Inner join MetaAvailableField maf on maf.TableName = lit.ListItemTableName
		and maf.ColumnName = lit.ListItemTitleColumn

DECLARE @RTE INTEGERS
INSERT INTO @RTE
SELECT 
	msf.MetaAvailableFieldId
FROM MetaSelectedField msf
	Inner join MetaSelectedSection mss on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	Inner join MetaTemplate mt on mss.MetaTemplateId = mt.MetaTemplateId
	Inner join MetaTemplateType mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	Inner join MetaPresentationType mpt on msf.MetaPresentationTypeId = mpt.Id
	Inner join @titleFieldsMAF tfmaf on msf.MetaAvailableFieldId = tfmaf.Id
WHERE mpt.Id in (25,26)

UPDATE MetaSelectedField
SET DefaultDisplayType = 'TextArea'
, MetaPresentationTypeId = 17
WHERE MetaAvailableFieldId in (
	SELECT Id FROM @RTE
)

DECLARE @TableName NVARCHAR(128);
DECLARE @ColumnName NVARCHAR(128);
DECLARE @sql NVARCHAR(MAX);

DECLARE table_cursor CURSOR FOR
SELECT TableName, ColumnName
FROM MetaAvailableField
WHERE MetaAvailableFieldId IN (SELECT Id FROM @RTE);

OPEN table_cursor;
FETCH NEXT FROM table_cursor INTO @TableName, @ColumnName;

WHILE @@FETCH_STATUS = 0
BEGIN
    SET @sql = 'UPDATE ' + QUOTENAME(@TableName) + 
               ' SET ' + QUOTENAME(@ColumnName) + ' =  dbo.Format_RemoveAccents(dbo.stripHtml(' + QUOTENAME(@ColumnName) +'))'+ -- Change 'New Value' to the desired value
               ' WHERE' + QUOTENAME(@ColumnName) + ' <> dbo.Format_RemoveAccents(dbo.stripHtml('+ QUOTENAME(@ColumnName) +'))';
    
    EXEC sp_executesql @sql;
    
    FETCH NEXT FROM table_cursor INTO @TableName, @ColumnName;
END;

CLOSE table_cursor;
DEALLOCATE table_cursor;

Drop table if exists #Results
;with ProgramSequenceQuery as (
	Select MetaSelectedSectionId, MetaTemplateId, MetaSelectedSection_MetaSelectedSectionId as TabSection, 'ProgramSequence' as TableName
	from MetaSelectedSection 
	where MetaBaseSchemaId = 857 --ProgramSequence
), ProgramCourseQuery as ( 
	Select mss1.MetaSelectedSectionId, mss1.MetaTemplateId,
	mss2.MetaSelectedSection_MetaSelectedSectionId as TabSection, 'ProgramCourse' as TableName
	from MetaSelectedSection mss1
	inner join MetaSelectedSection mss2 on mss2.MetaSelectedSectionId
	= mss1.MetaSelectedSection_MetaSelectedSectionId
		And mss1.MetaBaseSchemaId = 164 --ProgramCourse
		And mss1.MetaSectionTypeId in (31,500)
), OutcomeMatchingQuery as ( 
	Select MetaSelectedSectionId, MetaTemplateId, MetaSelectedSection_MetaSelectedSectionId as TabSection, 'ProgramOutcomeMatching' as TableName
	from MetaSelectedSection
	Where MetaBaseSchemaId	= 204 --ProgramOutcomeMatching
) Select 	ps.MetaTemplateId,
		ps.MetaSelectedSectionId as ProgramSequenceSectionId
		,ps.TabSection as ProgramSequenceTabId
		,pc.MetaSelectedSectionId as ProgramCourseSectionId
		,pc.TabSection as ProgramCourseTabId
		,om.MetaSelectedSectionId as OutcomeMatchingSectionId
		,om.TabSection as OutcomeMatchingTabId
	into #Results
from ProgramSequenceQuery ps
	left join ProgramCourseQuery pc 
		on pc.MetaTemplateId = ps.MetaTemplateId
	left join OutcomeMatchingQuery om 
		on om.MetaTemplateId = ps.MetaTemplateId
;Merge MetaSelectedSectionAttribute as Target
	using(
				select 'triggersectionrefresh' as Name, 
								ProgramCourseTabId as Value,
								ProgramSequenceSectionId as MetaSelectedSectionId 
				from #Results r
				inner join metaSelectedField msf
					on msf.MetaSelectedSectionId = r.ProgramSequenceSectionId
				inner join MetaAvailableField maf 
					on maf.MetaAvailableFieldId = msf.MetaAvailableFieldId
						and ColumnName like '%Subject%Id%'
				Where ProgramCourseTabId is not null
				Union
				select 'triggersectionrefresh' as Name, 
								OutcomeMatchingTabId as Value,
								ProgramSequenceSectionId as MetaSelectedSectionId 
				from #Results r
				Where OutcomeMatchingTabId is not null
) as Source (Name,Value,MetaSelectedSectionId)
on Source.Name = Target.Name and
	 Source.Value = Target.Value and
	 Source.MetaSelectedSectionId = Target.MetaSelectedSectionId
When not Matched THEN
Insert  (Name,Value,MetaSelectedSectionId)
values  (Source.Name,Source.Value,Source.MetaSelectedSectionId);

UPDATE ClientEntityType
SET EntitySpecializationTypeId = 6
WHERE Id = 23

UPDATE ClientEntitySubType
SET Active = 0
WHERE ClientId = 5

UPDATE ProposalType
SET ClientEntitySubTypeId = NULL
, ClientEntityTypeId = 23
WHERE ClientEntitySubTypeId IS NOT NULL

DELETE FROM Config.ClientMenuItem WHERE Id = 25

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()