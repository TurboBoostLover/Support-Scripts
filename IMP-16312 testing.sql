SELECT * FROM MetaSelectedSection AS mss
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE (mss.SectionName like '%Program%' or mss.SectionName like '%Specialisation%')
and mt.Active = 1
and mt.EndDate IS NULL
and MetaSelectedSectionId not in (
	SELECT MEtaSelectedSectionId FROM MetaSelectedSection WHERE mss.SectionName like '%Programme%'
)
and DisplaySectionName = 1

SELECT * FROM MetaSelectedField
WHERE (DisplayName like '%Program%' or DisplayName like '%Specialisation%' )
and MetaSelectedFieldId not in (
	SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE DisplayName like '%Programme%'
)
AND DisplayName not like 'ProgramOutcomeId'
AND DisplayName not like 'ProgramObjective'

SELECT * FROM MetaSelectedFieldAttribute 
WHERE (Value like '%Specialisation%' or VAlue like '%Program%')
AND Id not in (
	SELECT Id fROM MetaSelectedFieldAttribute WHERE VAlue like '%Programme%'
)
AND NAme not in (
'ParentLookupTable', 'ParentLookupForeignKey', 'FilterSubscriptionTable', 'FilterTargetTable', 'FilterSubscriptionColumn', 'FilterSubscriptionName'
)

SELECT * FROM MetaSelectedSection AS mss
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
WHERE (mss.SectionDescription like '%Program%' or mss.SectionDescription like '%Specialisation%')
and mt.Active = 1
and mt.EndDate IS NULL
and MetaSelectedSectionId not in (
	SELECT MEtaSelectedSectionId FROM MetaSelectedSection WHERE mss.SectionDescription like '%Programme%'
)
and DisplaySectionDescription = 1