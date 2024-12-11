use cscc;

--rollback
--commit

set xact_abort on;

begin tran
select @@servername as 'Server Name',
    db_name() as 'Database Name';

--========================
--Declare global variables
--========================
INSERT INTO ListItemType
(Title, ListItemTypeOrdinal, ListItemTableName, ListItemTitleColumn, SortOrder, StartDate, ClientId)
VALUES
('Course Requirement', 1, 'ProgramCourse', 'CourseId', 1, GETDATE(), 1),
('Group', 2, 'ProgramCourse', 'ProgramCourseRule', 2, GETDATE(), 1),
('Non-Course Requirement', 3, 'ProgramCourse', 'MaxText02', 3, GETDATE(), 1),
('Program Requirement', 1, 'CourseOption', 'CourseOptionNote', 1, GETDATE(), 1)

DECLARE @Id int = (SELECT Id FROM ListItemType WHERE Title = 'Group')
DECLARE @Id2 int = (SELECT Id FROM ListItemType WHERE Title = 'Non-Course Requirement')
DECLARE @Id3 int = (SELECT Id FROM ListItemType WHERE Title = 'Course Requirement')
DECLARE @Id4 int = (SELECT Id FROM ListItemType WHERE Title = 'Program Requirement')

declare --Set the display names for the CourseOption and ProgramCourse ListItemTypes to show in the UI
			@courseOptionListItemType1Name nvarchar(100) = 'Program Requirement',
			@programCourseListItemType1Name nvarchar(100) = 'Course Requirement',
			@programCourseListItemType2Name nvarchar(100) = 'Group Requirement',
			@programCourseListItemType3Name nvarchar(100) = 'Non-Course Requirement',
			@programCourseListItemType4Name nvarchar(100) = 'Reference',
			--Set if the Exclude, Override, or Reference attributes will be added to the CourseOption section
			--	1 means it is included
			--	0 means not included
			@courseOptionAllowExclude bit = 1,
			@courseOptionAllowOverride bit = 1,
			--Set if the Exclude, Override, or Reference attributes will be added to the ProgramCourse section
			--	1 means it is included
			--	0 means not included
			@programCourseAllowExclude bit = 1,
			@programCourseAllowOverride bit = 1,
			@programCourseListItem3Include bit = 1,
			@programCourseListItem4Include bit = 1,
			--Rest of the variables used
			@currentMSSId int,
			@currentMSFId int,
			@newMFKCCId int,
			@parentMSSId int,
			@cursorClientId int,
			@currentMinRowPosition int,
			@clientId int = 1

--=========================================
--Create any temp tables that will be used.
--=========================================
drop table if exists #fieldsToMove;
drop table if exists #fieldsToDelete;
drop table if exists #sectionsToUpdate;

create table #fieldsToMove
(
    Id int identity primary key,
    MetaSelectedFieldId int,
    MetaSelectedSectionId int,
    MetaAvailableFieldId int,
    ColumnName sysname
);

create table #fieldsToDelete
(
    Id int identity primary key,
    MetaSelectedFieldId int,
    MetaSelectedSectionId int,
    ClientId int
);

create table #sectionsToUpdate
(
    Id int identity primary key,
    TabMetaSelectedSectionId int,
    CourseOptionMetaSelectedSectionId int,
    ProgramCourseMetaSelectedSectionId int
);
declare @courseOptionId int,
			@programCourseId int,
			@currentSortOrder int,
			@currentConditionId int,
			@currentParent int,
			@newParent int,
			@previousConditionId int,
			@previousParentId int,
			@actualSortOrder int,
			@updateItemId int,
			@programId int;;

--Create any temp tables needed
declare @programCourses table
	(
    Id int primary key,
    PreviousId int,
    ParentId int,
    ConditionId int,
    SortOrder int
	);

delete pc
	from ProgramCourse pc
	where pc.CourseOptionId is null;
--===============================
--Populate temp tables as needed.
--===============================
--Populate temp table with the list of subject and course drop downs that are being moved from the Chained Combo sections
insert into #fieldsToMove
    (MetaSelectedFieldId, MetaSelectedSectionId, MetaAvailableFieldId, ColumnName)
select msf.MetaSelectedFieldId, msf.MetaSelectedSectionId, maf.MetaAvailableFieldId, maf.ColumnName
from MetaSelectedField msf
    inner join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
        and maf.TableName = 'ProgramCourse'
        and maf.ColumnName in ('SubjectId', 'CourseId');

--Populate temp table iwth the list of fields that need to be removed from the forms
insert into #fieldsToDelete
    (MetaSelectedFieldId, MetaSelectedSectionId, ClientId)
select msf.MetaSelectedFieldId, mss.MetaSelectedSectionId, mss.ClientId
from MetaSelectedField msf
    inner join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
        and maf.TableName in ('CourseOption', 'ProgramCourse')
        and maf.ColumnName in ('ValueHigh', 'ConditionId', 'ValueLow', 'NumberMin', 'NumberMax', 'Numbering')
    inner join MetaSelectedSection mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId;

--Populate the list of sections that house the ordered lists that are changing.
insert into #sectionsToUpdate
    (TabMetaSelectedSectionId, CourseOptionMetaSelectedSectionId, ProgramCourseMetaSelectedSectionId)
select mss2.MetaSelectedSectionId as TabSection, mss.MetaSelectedSectionId as CourseOptionSection, mss3.MetaSelectedSectionId as ProgramCourseSection
from MetaSelectedSection mss
    inner join MetaSelectedSection mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
    inner join MetaSelectedSection mss3 on mss.MetaSelectedSectionId = mss3.MetaSelectedSection_MetaSelectedSectionId
        and mss3.MetaBaseSchemaId = 164
where mss.MetaBaseSchemaId = 159
    and mss2.MetaSelectedSection_MetaSelectedSectionId is null;

print 'Start: Remove Sections not compatable';
--======================================================================================
--Remove sections that are on the same level as the CourseOption Ordered List.
--This is here because as of right now (2019-06-07) there cannot be any other sections
--on the tab.
--======================================================================================
declare sectionsToRemove cursor for
	select mss.MetaSelectedSectionId, mss.ClientId
from MetaSelectedSection mss
    inner join #sectionsToUpdate s on mss.MetaSelectedSection_MetaSelectedSectionId = s.TabMetaSelectedSectionId
        and mss.MetaSelectedSectionId <> s.CourseOptionMetaSelectedSectionId;

open sectionsToRemove;

fetch next from sectionsToRemove
	into @currentMSSId, @cursorClientId;

while @@fetch_status = 0
	begin;
    delete mssrp
		from MetaSelectedSectionRolePermission mssrp
		where mssrp.MetaSelectedSectionId = @currentMSSId;

    delete msspp
		from MetaSelectedSectionPositionPermission msspp
		where msspp.MetaSelectedSectionId = @currentMSSId;

    exec spBuilderSectionDelete @clientId = @cursorClientId, @sectionId = @currentMSSId;

    fetch next from sectionsToRemove
		into @currentMSSId, @cursorClientId;
end;

close sectionsToRemove;
deallocate sectionsToRemove;
print 'End: Remove Sections not compatable';


--========================================================================
--Move data in CourseOption and ProgramCourse tables to use the new fields
--NOTE: This will need to be updated to match the schools data. This was created
--		for SantaMonica and CUIQ.
--========================================================================
--CourseOption
print 'Start: Update the data in the CourseOption table to use new fields';
update co
	set CalcMin = coalesce(CalcMin, co.ValueLow, co.ValueHigh),
		CalcMax = coalesce(CalcMax, co.ValueHigh, co.ValueLow),
		OverrideCalculation = case
								when coalesce(co.ValueLow, co.ValueHigh) is not null then 1
								else 0
							end
	from CourseOption co;
print 'End: Update the data in the CourseOption table to use new fields';

--ProgramCourse
print 'Start: Update the data in the ProgramCourse table to use the new fields';
update pc
	set CalcMin = coalesce(CalcMin, pc.NumberMin, pc.NumberMax),
		CalcMax = coalesce(CalcMax, pc.NumberMax, pc.NumberMin),
		OverrideCalculation = case
								when pc.NumberMin is not null or pc.NumberMax is not null then 1
								else 0
							end,
		Header = coalesce(pc.Header, pc.ProgramCourseRule)
	from ProgramCourse pc;
print 'End: Update the data in the ProgramCourse table to use the new fields';



print 'Start: Build out the conditions for the course blocks';
--======================================
--Loop over every block for all programs
--======================================
declare courseOptions cursor fast_forward for
	select Id
from CourseOption co
group by Id;

open courseOptions;

fetch next from courseOptions
	into @courseOptionId;

while @@fetch_status = 0
	begin;
    --Populate temp table with the sort order made sequential. The cause for this
    --is that in a lot of schools the SortOrder was not sequential and it would have
    --complicated things.
    insert into @programCourses
        (Id, ParentId, ConditionId, SortOrder)
    select Id, Parent_Id, ConditionId,
        row_number() over(order by SortOrder)
    from ProgramCourse
    where CourseOptionId = @courseOptionId
    order by SortOrder;

    declare programCourse cursor fast_forward for
		select Id, ConditionId, SortOrder
    from ProgramCourse
    where CourseOptionId = @courseOptionId
    order by SortOrder;

    open programCourse;

    fetch next from programCourse
		into @programCourseId, @currentConditionId, @actualSortOrder;

    while @@fetch_status = 0
		begin;
        set @currentSortOrder = (select SortOrder
        from @programCourses
        where Id = @programCourseId);
        set @previousConditionId = (select ConditionId
        from @programCourses
        where SortOrder = @currentSortOrder - 1);
        set @previousParentId = (select ParentId
        from @programCourses
        where SortOrder = @currentSortOrder - 1);

        if (@currentConditionId = 1)
			begin;
            --If previous condition is "And" then set parent as previous items parent
            if (@previousConditionId = 1)
				begin;
                --Update temp table
                update @programCourses
					set ParentId = @previousParentId
					where Id = @programCourseId;

                --Update the actual ProgramCourse table
                update ProgramCourse
					set Parent_Id = @previousParentId
					where Id = @programCourseId;
            end;
				--If previous condition is "Or"
				--	--> Create "And" group and set its parent as the "Or" condition group (previous items parent).
				--	--> Set current items parent to the "And" condition group
				else if (@previousConditionId = 2)
				begin;
                --Insert "And" condition group
                insert into ProgramCourse
                    (SortOrder, CourseOptionId, ListItemTypeId, GroupConditionId, Parent_Id)
                values
                    (@actualSortOrder, @courseOptionId, @Id, 1, @previousParentId);

                set @newParent = scope_identity();

                --Update temp table
                update @programCourses
					set ParentId = @newParent
					where Id = @programCourseId;

                --Update the actual ProgramCourse table
                update ProgramCourse
					set Parent_Id = @newParent
					where Id = @programCourseId;
            end;
				--Else:
				-- --> Create "And" group without a parent
				-- --> Set the "And" group as the parent for the current item
				else
				begin;
                --Insert "And" condition group
                insert into ProgramCourse
                    (SortOrder, CourseOptionId, ListItemTypeId, GroupConditionId)
                values
                    (@actualSortOrder, @courseOptionId, @Id, 1);

                set @newParent = scope_identity();

                --Update temp table
                update @programCourses
					set ParentId = @newParent
					where Id = @programCourseId;

                --Update the actual ProgramCourse table
                update ProgramCourse
					set Parent_Id = @newParent
					where Id = @programCourseId;
            end;
        end;
			else if (@currentConditionId = 2)
			begin;
            --If previous condition is "Or" then set parent as previous items parent
            if (@previousConditionId = 2)
				begin;
                --Update temp table
                update @programCourses
					set ParentId = @previousParentId
					where Id = @programCourseId;

                --Update the actual ProgramCourse table
                update ProgramCourse
					set Parent_Id = @previousParentId
					where Id = @programCourseId;
            end;
				--If previous condition is "And"
				-- --> Create "Or" group and set its parent as the "And" condition group
				-- --> Set current items parent to the "Or" condition group
				else if (@previousConditionId = 1)
				begin;
                --Insert "Or" condition group
                insert into ProgramCourse
                    (SortOrder, CourseOptionId, ListItemTypeId, GroupConditionId, Parent_Id)
                values
                    (@actualSortOrder, @courseOptionId, @Id, 2, @previousParentId);

                set @newParent = scope_identity();

                --Update temp table
                update @programCourses
					set ParentId = @newParent
					where Id = @programCourseId;

                --Update the actual ProgramCourse table
                update ProgramCourse
					set Parent_Id = @newParent
					where Id = @programCourseId;
            end;
				--Else:
				-- --> Create "Or" group without a parent
				-- --> Set the "Or" group as the parent for the current item
				else
				begin;
                --Insert "And" condition group
                insert into ProgramCourse
                    (SortOrder, CourseOptionId, ListItemTypeId, GroupConditionId)
                values
                    (@actualSortOrder, @courseOptionId, @Id, 2);

                set @newParent = scope_identity();

                --Update temp table
                update @programCourses
					set ParentId = @newParent
					where Id = @programCourseId;

                --Update the actual ProgramCourse table
                update ProgramCourse
					set Parent_Id = @newParent
					where Id = @programCourseId;
            end;
        end;
			else
			begin;
            --If previous is "And" or "Or" then set current item to have the same parent as the previous item
            --Else do nothing.
            if (@previousConditionId in (1, 2))
				begin;
                --Update temp table
                update @programCourses
					set ParentId = @previousParentId
					where Id = @programCourseId;

                --Update the actual ProgramCourse table
                update ProgramCourse
					set Parent_Id = @previousParentId
					where Id = @programCourseId;
            end;
        end;

        set @newParent = null;

        fetch next from programCourse
			into @programCourseId, @currentConditionId, @actualSortOrder;
    end;

    close programCourse;
    deallocate programCourse;

    delete from @programCourses;

    fetch next from courseOptions
		into @courseOptionId;
end;

close courseOptions;
deallocate courseOptions;
print 'End: Build out the conditions for the course blocks';

print 'Start: Block Calculations';
--Loop over all programs and have the cached calculations created and saved.
--This process can take some time. (took 6 mins for CUIQ)
create table #calculationResults
(
    TableName sysname,
    Id int,
    Min decimal(16, 3),
    Max decimal(16, 3),
    IsVariable bit
);

declare programCursor cursor fast_forward for
	select Id
from Program;

open programCursor;

fetch next from programCursor
	into @programId;

while @@fetch_status = 0
	begin;
    --exec upCalculateNestedCourseBlockEntries @entityId = @programId, @resultTable = '#calculationResults';

    fetch next from programCursor
		into @programId;
end;

close programCursor;
deallocate programCursor;

print 'End: Block Calculations';

print 'Start: Audits';

UPDATE ProgramCourse
SET ListItemTypeId = @Id2
WHERE ListItemTypeId IS NULL
AND CourseId IS NULL

UPDATE ProgramCourse
SET ListItemTypeId = @Id3
WHERE ListItemTypeId IS NULL

UPDATE CourseOption
SET ListItemTypeId = @Id4
WHERE ListItemTypeId IS NULL

select 'Program Course Conditions', case when count(1) > 0 then 'PASS' else 'FAIL!!!' end
from ProgramCourse pc
where pc.GroupConditionId is not null;

    select 'Null ListItemTypeId in ProgramCourse', case when count(1) > 0 then 'FAIL!!!' else 'PASS' end
    from ProgramCourse pc
    where pc.ListItemTypeId is null
union
    select 'Null ListItemTypeId in CourseOption', case when count(1) > 0 then 'FAIL!!!' else 'PASS' end
    from CourseOption co
    where co.ListItemTypeId is null;

select 'Course Blocks not migrated', case when count(1) = 0 then 'PASS' else 'FAIL!!!' end
from MetaSelectedSection mss
    inner join MetaSelectedSection mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
    inner join MetaSelectedSection mss3 on mss.MetaSelectedSectionId = mss3.MetaSelectedSection_MetaSelectedSectionId
        and mss3.MetaBaseSchemaId = 164
where mss.MetaBaseSchemaId = 159
    and mss2.MetaSelectedSection_MetaSelectedSectionId is null
    and (
		mss2.MetaSectionTypeId <> 30
    or
    mss.MetaSectionTypeId <> 31
    or
    mss3.MetaSectionTypeId <> 31
	);

--Check if the number of records updated by calculate proc matches how many courseoption and programcourse records there are.
declare @count int;
select @count = count(1)
from CourseOption;

select @count += count(1)
from ProgramCourse
where CourseOptionId is not null;

select 'Counts match', case when count(1) <> @count then 'FAIL!!!' else 'PASS' end
from #calculationResults;

print 'End: Audits';

drop table if exists #calculationResults;

COMMIT

SELECT Getdate()