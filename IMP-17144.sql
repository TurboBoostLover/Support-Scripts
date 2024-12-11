use hkapa

DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId = 3244

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
VALUES
('UpdateSubscriptionTable1', 'CourseSchool', 3244),
('UpdateSubscriptionColumn1', 'SchoolId', 3244)

INSERT INTO MetaSelectedSectionAttribute
(Name, Value, MetaSelectedSectionId)
VALUES
('FilterSubscriptionTable', 'CourseSchool', 2348),
('FilterSubscriptionColumn', 'ItemTypeId', 2348)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = 281
WHERE MetaSelectedFieldId = 3244


UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
declare @programmeCodeId int ;
declare @school int;

select @school = 
CASE
WHEN cs.SchoolId = 3 THEN 7
WHEN cs.SchoolId = 4 THEN 8
WHEN cs.SchoolId = 5 THEN 46
WHEN cs.SchoolId = 6 THEN 47
WHEN cs.SchoolId = 7 THEN 48
WHEN cs.SchoolId = 8 THEN 50
WHEN cs.SchoolId = 9 THEN 51
WHEN cs.SchoolId = 10 THEN 80
ELSE cs.SchoolId
END
, @programmeCodeId = cs.ItemTypeId
from CourseSchool cs
where cs.Id = @fktpIdValue 

declare @type int = (
	SELECT 
		CASE
			WHEN @programmeCodeId = 13 THEN 34 
			WHEN @programmeCodeId = 5 THEN 28 
			WHEN @programmeCodeId = 11 THEN 29
			WHEN @programmeCodeId = 12 THEN 33
			WHEN @programmeCodeId = 1 THEN 24
			WHEN @programmeCodeId = 7 THEN 32
			WHEN @programmeCodeId = 14 THEN 30
			WHEN @programmeCodeId = 2 THEN 27
			WHEN @programmeCodeId IN (8,9,10) THEN 26
			-- 3 - BFA/BMus (Before Curriculum C), 4 - BFA/BMus (Curriculum B)
			WHEN @programmeCodeId IN (3, 4) THEN 25
		End AS Id 
)

		select
			Id as Value
			,Title as Text
			,@programmeCodeId as FilterValue
		    
		from EligibilityCriteria
		where Active = 1
		and Code = @type
		and ParentEligibilityCriteriaId in (
			select Id
			from EligibilityCriteria
			where ParentEligibilityCriteriaId is null
			and Title = cast(@school as nvarchar(max))
		)
		and Id <> 2
		order by SortOrder
'
WHERE Id = 281


UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()