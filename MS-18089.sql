USE [cuesta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18089';
DECLARE @Comments nvarchar(Max) = 
	'Fix Saved Searches';
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
/* ===========================================================================
** fix-generic-update-saved-search-fields-to-latest-fields.sql
** Author: Martin J. Quito 
** Notes: 
** ===========================================================================
*/


/* ==========================================================================
** internal config
** ==========================================================================
*/
declare @_debug bit = 0;

declare @failMatchManualMappings table (
	CurrentFieldId nvarchar(max),
	NewFieldId nvarchar(max)
);
insert into @failMatchManualMappings
values
('field-1202-38411', 'field-2231-38411')
--('field-1225-15919', 'field-1225-38367')
/* ==========================================================================
** MSSPages
** ==========================================================================
*/
/*
- Use this for ms, imp, or testing purposes. If used in dev work, add some indexes to increase performance
- This casacades from top to bottom, so if you pass a tab section id, it will get all its children sections and nested sections
*/
declare @MSSTabs table
(
	MSSId int primary key,
	IsTab bit,
	TabMSSId int,
	TabMSSSectionName nvarchar(500)
); 

with Pages as (
	select mss.MetaSelectedSectionId as MSSId
	, null as ParentId
	, mss.MetaSelectedSectionId as MainParentId
	, case when mss.MetaSelectedSection_MetaSelectedSectionId is null then 1 else 0 end as IsTab
	from MetaSelectedSection mss
	-- add filters as desires
	where mss.MetaSelectedSection_MetaSelectedSectionId is null

	union all

	select mss.MetaSelectedSectionId as MSSId
	, p.MSSId as ParentId
	, p.MainParentId
	, case when mss.MetaSelectedSection_MetaSelectedSectionId is null then 1 else 0 end as IsTab
	from Pages p
		inner join MetaSelectedSection mss on p.MSSId = mss.MetaSelectedSection_MetaSelectedSectionId
)
	insert into @MSSTabs (MSSId, TabMSSId, TabMSSSectionName, IsTab)
	select p.MSSId, p.MainParentId, mss.SectionName, p.IsTab
	from Pages p
		inner join MetaSelectedSection mss on p.MainParentId = mss.MetaSelectedSectionId
;

/* =========================
** Engine to get metadata about current saved search data
** =========================
*/
/*
The three tables to use from this engine 
- @savedSearches - all the saved searches
- @savedFields - all fields from the saved search configs
- @searchFields - all search fields (ouput fields) from all cets and client
- @currentSystemSearchFielIds - all the system fields from the @searchFields that have the tab 'System Fields'
*/

declare @savedSearches table (
	id int,
	[Name] nvarchar(max),
	rules nvarchar(max),
	displayColumns nvarchar(max),
	filterByUser bit,
	keyword nvarchar(max),
	searchName nvarchar(max),
	userId int,
	clientEntityTypeId int,
	clientEntitySubTypeId int,
	clientIds nvarchar(max),
	entityId int,
	sortOptions nvarchar(max),
	sortAscendingFlag int,
	isDefaultSearchForClientEntityType bit,
	isPublicSearchForClientEntityType bit,
	publicSearchClientId int,
	campusIds nvarchar(max),
	mode nvarchar(max)
);

declare @getSearchFieldsResults table(
    id NVARCHAR(MAX),
    tabname NVARCHAR(MAX),
    tablename NVARCHAR(MAX),
    columnname NVARCHAR(MAX),
    label NVARCHAR(MAX),
    precision NVARCHAR(MAX),
    scale NVARCHAR(MAX),
    datatype NVARCHAR(MAX),
    lookupquery NVARCHAR(MAX),
    canfilter BIT,
    selectclause NVARCHAR(MAX),
    joinclause NVARCHAR(MAX),
    whereclause NVARCHAR(MAX),
    clientId int,
    entityTypeId int,
    IsSubject bit,
    IsCourseNumber bit,
    IsCourseTitle bit,
    IsProposalType bit,
    IsStatus bit,
    IsAwardType bit,
    IsProgramTitle bit,
    IsDepartment bit,
    IsCourseSemester bit,
    IsProgramSemester bit,
    IsPackageTitle bit,
    IsModuleTitle bit,
    IsModuleSemester bit,
    IsPackageSubject bit,
    IsDivision bit,
    IsTier3 bit
);

declare @getSearchFieldsResults_approvals table(
    id NVARCHAR(MAX),
    tabname NVARCHAR(MAX),
    tablename NVARCHAR(MAX),
    columnname NVARCHAR(MAX),
    label NVARCHAR(MAX),
    precision NVARCHAR(MAX),
    scale NVARCHAR(MAX),
    datatype NVARCHAR(MAX),
    lookupquery NVARCHAR(MAX),
    canfilter BIT,
    selectclause NVARCHAR(MAX),
    joinclause NVARCHAR(MAX),
    whereclause NVARCHAR(MAX),
    clientId int,
    entityTypeId int,
	IsApprovalSubject bit,
	IsApprovalProposalType bit,
	IsApprovalDepartment bit,
	IsApprovalPosition bit,
	IsDivision bit,
	IsDepartment bit,
	IsTier3 bit,
	IsApprovalOriginator bit,
	IsProposalTitle nvarchar(max)
);

declare @searchFields table(
	_id int primary key identity,
	_clientEntityTypeId int,
	_Parsed_MAF_Id nvarchar(max),
	_Parsed_MSF_Id nvarchar(max),
	_IsSystemField bit,
    id NVARCHAR(MAX),
    tabname NVARCHAR(MAX),
    tablename NVARCHAR(MAX),
    columnname NVARCHAR(MAX),
    label NVARCHAR(MAX),
    precision NVARCHAR(MAX),
    scale NVARCHAR(MAX),
    datatype NVARCHAR(MAX),
    lookupquery NVARCHAR(MAX),
    canfilter BIT,
    selectclause NVARCHAR(MAX),
    joinclause NVARCHAR(MAX),
    whereclause NVARCHAR(MAX),
    clientId int,
    entityTypeId int
    --IsSubject bit,
    --IsCourseNumber bit,
    --IsCourseTitle bit,
    --IsProposalType bit,
    --IsStatus bit,
    --IsAwardType bit,
    --IsProgramTitle bit,
    --IsDepartment bit,
    --IsCourseSemester bit,
    --IsProgramSemester bit,
    --IsPackageTitle bit,
    --IsModuleTitle bit,
    --IsModuleSemester bit,
    --IsPackageSubject bit,
    --IsDivision bit,
    --IsTier3 bit
);

declare @currentSystemSearchFielIds table (FieldId nvarchar(max));

declare @savedFields table (
	_Id int primary key identity,
	CETId int,
	SaveSearchId int,
	KeyStorage nvarchar(max),
	FieldIdRaw nvarchar(max),
	ParsedFieldId nvarchar(max),
	ParsedMetaAvailableFieldId int,
	ParsedMetaSelectedFieldId int,
	IsSystemField bit,
	IsValidFormat bit,
	JSONPath nvarchar(max),
	JSONValue nvarchar(max)
);

insert into @savedSearches
select ss.Id
, ss.Name
, config.*
from Search.SavedSearches ss
	outer apply openjson(ss.Config)
	with (
		rules nvarchar(max) '$.rules' as json,
		displayColumns nvarchar(max) '$.displayColumns' as json,
		filterByUser bit '$.filterByUser',
		keyword nvarchar(max) '$.keyword',
		searchName nvarchar(max) '$.searchName',
		userId int '$.userId',
		clientEntityTypeId int '$.clientEntityTypeId',
		clientEntitySubTypeId int '$.clientEntitySubTypeId',
		clientIds nvarchar(max) '$.clientIds' as json,
		entityId int '$.entityId',
		sortOptions nvarchar(max) '$.sortOptions' as json,
		sortAscendingFlag int '$.sortAscendingFlag',
		isDefaultSearchForClientEntityType bit '$.isDefaultSearchForClientEntityType',
		isPublicSearchForClientEntityType bit '$.isPublicSearchForClientEntityType',
		publicSearchClientId int '$.publicSearchClientId',
		campusIds nvarchar(max) '$.campusIds' as json,
		mode nvarchar(max) '$.mode'
	) config
;

declare @allActiveCET table (Id int identity, CETId int, ClientId int)

insert into @allActiveCET (CETId, ClientId)
select distinct cet.Id, cet.ClientId
from ClientEntityType cet
	inner join Client cl on cet.ClientId = cl.Id
where cet.Active = 1
and cl.Active = 1
union
select fn.CategoryId
, fn2.ClientId
from (
	values (0)
) fn (CategoryId)
	cross apply (
		select c.Id as ClientId
		from Client c
		where c.Active = 1
	) fn2

declare @clientIdsParam integers;

while exists (select 1 from @allActiveCET)
	begin;
		delete from @clientIdsParam;
		delete from @getSearchFieldsResults;
		delete from @getSearchFieldsResults_approvals;

		declare @_id int = (select top 1 Id from @allActiveCET);
		declare @cetId int = (select CETId from @allActiveCET where Id = @_id);
		declare @entityTypeId int = (select EntityTypeId from ClientEntityType where Id = @cetId);

		insert into @clientIdsParam
		select ClientId
		from @allActiveCET
		where Id = @_id
		
		--select '@clientIdsParam', *, @cetId as '@cetId', Id as ClientId
		--from @clientIdsParam

		if (@cetId = 0)
		begin;
			insert into @getSearchFieldsResults_approvals
			exec search.upGetSearchFields 
				@cetId = @cetId,
				@entityTypeId = @entityTypeId,
				-- not needed because we care about knowing all possible fields
				@userId = null,
				@clientIds = @clientIdsParam
			;

			insert into @searchFields
			select @cetId
			, fn2_maf.[Value]
			, fn2_msf.[Value]
			, fn.IsSystemField
			, g.id
			, g.tabname
			, g.tablename
			, g.columnname
			, g.label
			, g.precision
			, g.scale
			, g.datatype
			, g.lookupquery
			, g.canfilter
			, g.selectclause
			, g.joinclause
			, g.whereclause
			, g.clientId
			, g.entityTypeId
			from @getSearchFieldsResults_approvals g
				outer apply (
					select case
							when g.tabname = 'System Fields' then 1
							else 0
							end as IsSystemField
				) fn
				outer apply (
					select *
					from dbo.RegEx_Matches(g.id, '\d+') rx
					where rx.MatchNum = 1
					and fn.IsSystemField = 0
				) fn2_maf -- maf
				outer apply (
					select *
					from dbo.RegEx_Matches(g.id, '\d+') rx
					where rx.MatchNum = 2
					and fn.IsSystemField = 0
				) fn2_msf -- msf
			;		
		end;
		else
		begin;
			insert into @getSearchFieldsResults
			exec search.upGetSearchFields 
				@cetId = @cetId,
				@entityTypeId = @entityTypeId,
				-- not needed because we care about knowing all possible fields
				@userId = null,
				@clientIds = @clientIdsParam 
			;

			insert into @searchFields
			select @cetId
			, fn2_maf.[Value]
			, fn2_msf.[Value]
			, fn.IsSystemField
			, g.id
			, g.tabname
			, g.tablename
			, g.columnname
			, g.label
			, g.precision
			, g.scale
			, g.datatype
			, g.lookupquery
			, g.canfilter
			, g.selectclause
			, g.joinclause
			, g.whereclause
			, g.clientId
			, g.entityTypeId
			from @getSearchFieldsResults g
				outer apply (
					select case
							when g.tabname = 'System Fields' then 1
							else 0
							end as IsSystemField
				) fn
				outer apply (
					select *
					from dbo.RegEx_Matches(g.id, '\d+') rx
					where rx.MatchNum = 1
					and fn.IsSystemField = 0
				) fn2_maf -- maf
				outer apply (
					select *
					from dbo.RegEx_Matches(g.id, '\d+') rx
					where rx.MatchNum = 2
					and fn.IsSystemField = 0
				) fn2_msf -- msf
			;
		end;

		delete from @allActiveCET where id = @_id
	end;

insert into @currentSystemSearchFielIds
select distinct Id
from @searchFields
where tabname = 'System Fields'

--select '@currentSystemSearchFielIds', *
--from @currentSystemSearchFielIds

--select '@searchFields', *
--from @searchFields
--order by _clientEntityTypeId

declare @savedSearchConfigFields table (
	SavedSearchId int,
	Config nvarchar(max),
	JSONPath nvarchar(max),
	Depth int,
	[Key] nvarchar(max),
	[Value] nvarchar(max),
	[ValueType] int,
	extracted_id nvarchar(max),
	extracted_field nvarchar(max),
	keyStorage sysname
);

;with Recur as (
	select cast(ss.id as int) as SavedSearchId
	, ss.Config
	, '$.' + fn.[Key] collate database_default as JSONPath
	, 1 as Depth
	, fn.[Key]
	, fn.[Value]
	, fn.Type as ValueType
	, case 
		when isjson(fn.[Value]) = 1 then json_value(fn.[Value], '$.id')
		else null
		end as field_id
	, case 
		when isjson(fn.[Value]) = 1 then json_value(fn.[Value], '$.field')
		else null
		end as field_field
	, fn.[Key] as KeyStorage
	from search.SavedSearches ss
		cross apply openjson(ss.config) fn

	union all

	select r.SavedSearchId as SavedSearchId
	, r.Config
	, r.JSONPath + 
		case
			when r.ValueType = 4 then '[' + child.[Key] + ']'
			else '.' + child.[Key]
		 end collate database_default as JSONPath
	, r.Depth + 1 as Depth
	, child.[Key] 
	, child.[Value]
	, child.[Type] as ValueType
	, case 
		when isjson(child.[Value]) = 1 then json_value(child.[Value], '$.id')
		else null
		end as field_id
	, case 
		when isjson(child.[Value]) = 1 then json_value(child.[Value], '$.field')
		else null
		end as field_field
	, r.KeyStorage
	from Recur r
		outer apply (
			select fn.[Key] as [Key]
			, fn.[Value] as [Value]
			, fn.[Type] as [Type]
			from openjson(r.[Value]) fn
			where isjson(r.[Value]) = 1
		) child
	where r.[Value] is not null
)
	insert into @savedSearchConfigFields (SavedSearchId, Config, JSONPath, Depth, [Key], [Value], [ValueType], extracted_id, extracted_field, keyStorage)
	select *
	from Recur
	where KeyStorage in ('rules', 'displayColumns')
	and field_id is not null

if exists (
	select *
	from @savedSearchConfigFields
	where keyStorage = 'rules'
	and extracted_field is null
)
	throw 50001, 'rule field without a field value set', 1;

if exists (
	select *
	from @savedSearchConfigFields s
	where json_path_exists(s.Config, s.JSONPath) = 0
	 or JSONPath is null
)
	throw 50001, 'There is at least one invalid JSON path to update the field', 1;


insert into @savedFields (CETId, SaveSearchId, KeyStorage, FieldIdRaw, ParsedFieldId, ParsedMetaAvailableFieldId, ParsedMetaSelectedFieldId, IsSystemField, IsValidFormat, JSONPath, JSONValue)
select ss.clientEntityTypeId
, f.SavedSearchId
, f.[keyStorage]
, f.extracted_id
, mt.FieldId
, fn2a.[Value] as MetaAvailableFieldId
, fn2b.[Value] as MetaSelectedFieldId
, mt.IsSystemField
, mt.IsValidFormat
, f.JSONPath
, f.Value
from @savedSearchConfigFields f
	inner join @savedSearches ss on f.SavedSearchId = ss.id
	outer apply (
		select 
			case 
				when f.keyStorage = 'displayColumns' then dbo.RegEx_IsMatch(f.extracted_id, '^field-check-field-\d+-\d+$|^field-check-field-[A-Za-z]+-1$') 
				else dbo.RegEx_IsMatch(f.extracted_id, '^field-\d+-\d+$|^field-[A-Za-z]+-1$')
			end as IsValidFormat,
			case
				when f.keyStorage = 'displayColumns' then dbo.RegEx_Replace(f.extracted_id, '^field-check-', '')
				else f.extracted_id
			end as FieldId,
			case
				when f.keyStorage = 'displayColumns' then dbo.RegEx_IsMatch(f.extracted_id, '^field-check-field-[A-Za-z]+-1$')
				else dbo.RegEx_IsMatch(f.extracted_id, '^field-[A-Za-z]+-1$')
			end as IsSystemField
	) mt
	outer apply (
		select *
		from dbo.RegEx_Matches(mt.FieldId, '\d+') rx
		where rx.MatchNum = 1
		and mt.IsSystemField = 0
	) fn2a
	outer apply (
		select *
		from dbo.RegEx_Matches(mt.FieldId, '\d+') rx
		where rx.MatchNum = 2
		and mt.IsSystemField = 0
	) fn2b


if @_debug = 1
	select '@savedSearches', *
	from @savedSearches

if @_debug = 1
	select '@savedFields', *
	from @savedFields;

if @_debug = 1
	select '@searchFields', *
	from @searchFields
	order by tablename, columnname

/* ==========================================================================
** find latest field
** ==========================================================================
*/
declare @savedFields_searchFields_fieldMappings table (
	savedFields_Id int,
	searchFields_Id int,
	rowId int
);

declare @unmatchFields table (
	[@savedFieldsId] int
);

insert into @unmatchFields
select sd._Id
from @savedFields sd
where not exists (
	select 1
	from @searchFields sf
	where isnull(sd.ParsedFieldId, '') = isnull(sf.id, '')
	and sd.CETId = sf._clientEntityTypeId
)

if @_debug = 1
	select '@unmatchFields', *
	from @unmatchFields

-- debug start
--select *
--from @searchFields
--where _id = 38

-- to test duplicates
--insert into @searchFields (_clientEntityTypeId, id, tabname, tablename, columnname, label, _Parsed_MAF_Id, _Parsed_MSF_Id)
--values
--(1, 'field-888-1111', 'Cover', 'Course', 'CourseNumber', 'Course Number', 888, 1111)

--delete sf
--from @searchFields sf
--where sf.tablename = 'Course'
--and sf.columnname = 'CourseNumber'

-- debug end

;with Mapping as (
	select sf._Id as savedFields_Id
	, fn._id as searchFields_Id
	, row_number() over (partition by sf._Id order by fn._id) as RowId
	from @unmatchFields um
		inner join @savedFields sf on um.[@savedFieldsId] = sf._Id
		inner join @savedSearches ss on sf.SaveSearchId = ss.Id
		left join MetaSelectedField msf on sf.ParsedMetaSelectedFieldId = msf.MetaSelectedFieldId
										and sf.ParsedMetaAvailableFieldId = msf.MetaAvailableFieldId
		left join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
		left join @MSSTabs m on msf.MetaSelectedSectionId = m.MSSId
		outer apply (
			select *
			from @searchFields sef
			where maf.MetaAvailableFieldId = sef._Parsed_MAF_Id -- by MAF
			and m.TabMSSSectionName = sef.tabname -- by tab
			and sf.CETId = sef._clientEntityTypeId 
			and isnull(trim(msf.DisplayName), '') = isnull(trim(sef.label), '') -- by label
		) fn
)
	insert into @savedFields_searchFields_fieldMappings
	select savedFields_Id
	, searchFields_Id
	, RowId
	from Mapping m;

update s
set s.searchFields_Id = shf._id
from @savedFields_searchFields_fieldMappings s
	inner join @savedFields sf on s.savedFields_Id = sf._Id
	inner join @failMatchManualMappings m on sf.ParsedFieldId = m.CurrentFieldId
	inner join @searchFields shf on m.NewFieldId = shf.id
where s.searchFields_Id is null

if @_debug = 1
	select '@savedFields_searchFields_fieldMappings', *
	from @savedFields_searchFields_fieldMappings

-- bad ones
if exists (
	select *
	from @savedFields_searchFields_fieldMappings f
	where searchFields_Id is null
)
begin;
	select distinct 'Error: Fail to match to latest field. These are saved fields/rules that out of date and need to be updated to the lastest field. Either delete it or update the mappings manually.' as [ErrorMessage]
	, svf.SaveSearchId
	, svf.CETId
	, svf.ParsedFieldId as FieldId
	, msf.MetaSelectedFieldId as MSFId
	, msf.DisplayName as MSFDisplayName
	, maf.MetaAvailableFieldId as MAF
	, concat(maf.TableName, '.', maf.ColumnName) as MAFBackendstore
	, mt.[Data] + concat(' (', mt.id, ')') as 'Same MAF and under same TAB, but label is different'
	, ml.[Data] + concat(' (', ml.id, ')') as 'Same MAF and same label, but tabs are different' 
	, tl.[Data] + concat(' (', tl.id, ')') as 'Same TAB and same label, but MAF are different'
	, 1 as 'Cannot find field'
	from @savedFields_searchFields_fieldMappings f
		inner join @savedFields svf on f.savedFields_Id = svf._Id
		left join MetaSelectedField msf on svf.ParsedMetaSelectedFieldId = msf.MetaSelectedFieldId
										and svf.ParsedMetaAvailableFieldId = msf.MetaAvailableFieldId
		left join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
		left join @MSSTabs m on msf.MetaSelectedSectionId = m.MSSId

		outer apply (
			select sef.[label] as [Data]
			, sef.id
			from @searchFields sef
			where 1 = 1
			and svf.CETId = sef._clientEntityTypeId 
			and maf.MetaAvailableFieldId = sef._Parsed_MAF_Id -- by maf
			and m.TabMSSSectionName = sef.tabname -- by tab
		) mt -- same MAF and tab, but label is different
		outer apply (
			select sef.tabname as [Data]
			, sef.id
			from @searchFields sef
			where 1 = 1
			and svf.CETId = sef._clientEntityTypeId 
			and maf.MetaAvailableFieldId = sef._Parsed_MAF_Id -- by maf
			and isnull(trim(msf.DisplayName), '') = isnull(trim(sef.label), '') -- by label
		) ml -- same MAF and label, but tabs are different
		outer apply (
			select concat(sef.tabname, '.', sef.columnname) as [Data]
			, sef.id
			from @searchFields sef
			where 1 = 1
			and svf.CETId = sef._clientEntityTypeId 
			and isnull(trim(msf.DisplayName), '') = isnull(trim(sef.label), '') -- by label
			and m.TabMSSSectionName = sef.tabname -- by tab
		) tl -- same tab and label, but MAF are different
		outer apply (
			select concat(sef.tabname, '.', sef.columnname) as [Data]
			, sef.id
			from @searchFields sef
			where 1 = 1
			and svf.CETId = sef._clientEntityTypeId 
			and isnull(trim(msf.DisplayName), '') = isnull(trim(sef.label), '') -- by label
			and m.TabMSSSectionName = sef.tabname -- by tab
			and maf.MetaAvailableFieldId = sef._Parsed_MAF_Id -- by maf
		) al 
		
	where searchFields_Id is null
	order by svf.SaveSearchId;

	throw 50001, 'Error: See result sets for info.', 1;
end;

-- bad ones
if exists (
	select *
	from @savedFields_searchFields_fieldMappings f
	where exists (
		select 1
		from @savedFields_searchFields_fieldMappings f2
		where f.savedFields_Id = f2.savedFields_Id
		and f2.rowId > 1
	)
)
begin;
	select distinct 'Found multiple matches' as [ErrorMessage]
	, svf.CETId
	, svf.ParsedFieldId
	, '=>' as '=>'
	--, sf._id as _Id
	, sf._clientEntityTypeId as CETId
	, sf.id
	, sf.tabname
	, sf.label
	, sf.tablename
	, sf.columnname
	from @savedFields_searchFields_fieldMappings f
		inner join @savedFields svf on f.savedFields_Id = svf._Id
		inner join @searchFields sf on f.searchFields_Id = sf._id
	where exists (
		select 1
		from @savedFields_searchFields_fieldMappings f2
		where f.savedFields_Id = f2.savedFields_Id
		and f2.rowId > 1
	)
	order by svf.CETId;
	--, maf.MetaAvailableFieldId;

	throw 50001, 'Error: See result sets for info.', 1;
end;


/* ==========================================================================
** update, but lets do some extra checks
** ==========================================================================
*/
declare @fieldsMappings table (
	KeyStorage nvarchar(max),
	Current_FieldIdRaw nvarchar(max),
	Latest_FieldIdRaw nvarchar(max)
);

insert into @fieldsMappings
select distinct svf.KeyStorage
, svf.FieldIdRaw
, case
	when svf.KeyStorage = 'displayColumns' then 'field-check-' + srf.id
	when svf.KeyStorage = 'rules' then srf.id
	else null
	end as NewFieldId
from @savedFields_searchFields_fieldMappings f
	inner join @savedFields svf on f.savedFields_Id = svf._Id
	inner join @searchFields srf on f.searchFields_Id = srf._id

if @_debug = 1
	select '@fieldsMappings', *
	from @fieldsMappings


if exists (
	select 1
	from @fieldsMappings
	where KeyStorage is null
	or Current_FieldIdRaw is null
	or Latest_FieldIdRaw is null
)
	throw 50001, 'Missing value in one of the three columns.', 1;

-- show whatif
--select 'Update' as [Message]
--, svf.SaveSearchId
--, svf.CETId
--, t.TabMSSSectionName as Old_Tab
--, msf.DisplayName as Old_Label
--, svf.FieldIdRaw as Old_Id
--, svf.JSONPath
--, svf.JSONValue
--, '=>' as '_'
--, case
--	when svf.KeyStorage = 'displayColumns' then 'field-check-' + srf.id
--	else srf.id
--	end as New_FieldId
--, srf.tabname as New_Tab
--, srf.label as New_Label
--from @savedFields_searchFields_fieldMappings f
--	inner join @savedFields svf on f.savedFields_Id = svf._Id
--	inner join MetaSelectedField msf on svf.ParsedMetaSelectedFieldId = msf.MetaSelectedFieldId
--	inner join @MSSTabs t on msf.MetaSelectedSectionId = t.MSSId
--	inner join @searchFields srf on f.searchFields_Id = srf._id
--order by svf.SaveSearchId, svf.KeyStorage, svf.FieldIdRaw

declare @UpdateSavedSearchConfig table (
	SavedSearchId int,
	OldConfig nvarchar(max),
	NewConfig nvarchar(max)
);

;with NewValues as (
	select svf.*
	, case
		when svf.KeyStorage = 'displayColumns' then 'field-check-' + srf.id
		else srf.id
		end as New_FieldId
	from @savedFields_searchFields_fieldMappings f
		inner join @savedFields svf on f.savedFields_Id = svf._Id
		inner join @searchFields srf on f.searchFields_Id = srf._id
)
,UpdatedValues as (
	select t.*
	, case
			when t.KeyStorage = 'displayColumns' then json_modify(t.JSONValue, '$.id', t.New_FieldId)
			else json_modify(json_modify(t.JSONValue, '$.id', t.New_FieldId), '$.field', t.New_FieldId)
		end as UpdatedValue
	, row_number() over (partition by t.SaveSearchId order by _Id) as RowId -- order doesn't matter
	from NewValues t
)
, Recur as  (
	select tss.Id as SavedSearchId
	, ss.Config as OldConfig
	, ss.Config as NewConfig
	, 0 as NextNumber
	from @savedSearches tss
		inner join Search.SavedSearches ss on tss.id = ss.Id
	where exists (
		select 1
		from UpdatedValues uv
		where ss.Id = uv.SaveSearchId -- grab the ones it mattres
	)
	union all
	select r.SavedSearchId
	, r.OldConfig
	, json_modify(r.NewConfig, uv.JSONPath, uv.UpdatedValue) as NewConfig
	, cast(uv.RowId as int) as RowId
	from Recur r
		inner join UpdatedValues uv on r.SavedSearchId = uv.SaveSearchId
									and r.NextNumber + 1 = uv.RowId
)
	insert into @UpdateSavedSearchConfig
	select r.SavedSearchId
	, r.OldConfig
	, r.NewConfig
	from Recur r
	where r.NextNumber = (
		select max(r2.NextNumber)
		from Recur r2
		where r.SavedSearchId = r2.SavedSearchId
	)
	order by r.SavedSearchId, r.NextNumber

if (
	(
		select count(distinct(c.SavedSearchId))
		from @UpdateSavedSearchConfig c
	) !=
	(
		select count(distinct(svf.SaveSearchId))
		from @savedFields_searchFields_fieldMappings f
			inner join @savedFields svf on f.savedFields_Id = svf._Id
	)
)
	throw 50001, 'Error', 1;



update s
set s.Config = u.NewConfig
from @UpdateSavedSearchConfig u
	inner join Search.SavedSearches s on u.SavedSearchId = s.Id


--commit
--rollback