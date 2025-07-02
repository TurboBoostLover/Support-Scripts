USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19608';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text in Program of Study report';
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
DECLARE @Id int = 2340

DECLARE @SQL NVARCHAR(MAX) = '
declare @isNonCredit bit = (
	select
		case
			when p.AwardTypeId in (
				select Id
				from AwardType
				where Title like ''%Certificate of Competency%''
				or Title like ''%Certificate of Completion%''
			)
				then 1
			else 0
		end
	from Program as p
	where p.Id = @entityId
);

--select @isNonCredit as isNonCredit;

declare @queryString nvarchar(max) = ''
	declare @extraDetailsDisplay StringPair;

	drop table if exists #renderedInjections;

	create table #renderedInjections (
		TableName sysname,
		Id int,
		InjectionType nvarchar(255),
		RenderedText nvarchar(max),
		primary key (TableName, Id, InjectionType)
	);

	declare @blockTag nvarchar(10) = ''''div'''';
	declare @dataElementTag nvarchar(10) = ''''span'''';
	declare @identifierWrapperTag nvarchar(5) = ''''sup'''';
	declare @labelTag nvarchar(10) = ''''span'''';
	declare @listTag nvarchar(10) = ''''ul'''';
	declare @listItemTag nvarchar(10) = ''''li'''';

	declare @classAttrib nvarchar(10) = ''''class'''';

	declare @space nvarchar(5) = '''' '''';
	declare @empty nvarchar(1) = '''''''';

	declare @distanceEdIdentifierWrapperClass nvarchar(100) = ''''course-approved-for-de-identifier'''';
	declare @distanceEdIdentifierText nvarchar(10) = ''''DE'''';

	declare @minCrossListingDate datetime = (
		select min(clc.AddedOn)
		from CrossListingCourse clc
	);

	--select @isNonCredit;

	insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
	select
		''''ProgramSequence'''' as TableName, ps.Id, ''''CourseEntryLeftColumnReplacement'''' as InjectionType,
		concat(
			dbo.fnHtmlOpenTag(@dataElementTag, concat(
				dbo.fnHtmlAttribute(@classAttrib, ''''course-identifier''''), @space,
				dbo.fnHtmlAttribute(''''data-course-id'''', c.Id)
			)),
				dbo.fnHtmlOpenTag(@dataElementTag, concat(
					dbo.fnHtmlAttribute(@classAttrib, ''''subject-code''''), @space,
					dbo.fnHtmlAttribute(''''title'''', dbo.fnHtmlEntityEscape(s.Title))
				)),
					s.SubjectCode,
				dbo.fnHtmlCloseTag(@dataElementTag), @space,
				dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''''course-number'''')),
					c.CourseNumber,
				dbo.fnHtmlCloseTag(@dataElementTag),
			dbo.fnHtmlCloseTag(@dataElementTag),
			case
				when cde.IsApproved = 1 then
					concat(
						dbo.fnHtmlOpenTag(@identifierWrapperTag, dbo.fnHtmlAttribute(@classAttrib, @distanceEdIdentifierWrapperClass)),
							@distanceEdIdentifierText,
						dbo.fnHtmlCloseTag(@identifierWrapperTag)
					)
				else ''''''''
			end
		) as [Text]
	from ProgramSequence ps
	inner join Course c on ps.CourseId = c.Id
	inner join [Subject] s on c.SubjectId = s.Id
	left outer join CourseDistanceEducation cde on c.Id = cde.CourseId
	where (
		ps.ProgramId = @entityId
		or exists (
			select top 1 1
			from ProgramSequence ps2
			where ps2.ProgramId = @entityId
			and ps.Id = ps2.ReferenceId
		)
	);

	declare @clcourses table (Id int, RelatedCourseList nvarchar(max));

	insert into @clcourses
	select
		c.Id as Id,
		--dbo.ConcatWithSep_Agg('''', '''', concat(s.SubjectCode, @space, gcd.CourseNumber)) as clc_courses
		replace(dbo.fnTrimWhitespace(dbo.fn_GetCurrentCoursesInCrosslisting (c.Id, 0, 0, 0)), '''' ,'''', '''','''') as clc_courses
	from ProgramSequence ps
		inner join Course c on ps.CourseId = c.Id and c.IsCrossListed = 1
		cross apply fn_GetClcData(c.Id, 1, NULL) gcd
		inner join Crosslisting cl on gcd.CrossListingId = cl.Id
		inner join [Subject] s on s.Id = gcd.SubjectId
			where (
				ps.ProgramId = @entityId
				or exists (
					select top 1 1
					from ProgramSequence ps2
					where ps2.ProgramId = @entityId
					and ps.Id = ps2.ReferenceId
				)
			)		
	group by c.Id;

	insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
	select
		''''ProgramSequence'''' as TableName, ps.Id, ''''CourseEntryMiddleColumn'''' as InjectionType,
		case
			when c.IsCrossListed = 1
				then concat(
					dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''''course-cross-listing-list'''')),
						''''<b>Same as: </b>'''', @space,	clc.RelatedCourseList,
					dbo.fnHtmlCloseTag(@blockTag)
				)
			when rcl.RelatedCourseList is not null
				then concat(
					dbo.fnHtmlOpenTag(@blockTag, dbo.fnHtmlAttribute(@classAttrib, ''''course-cross-listing-list'''')),
						''''<b>Same as: </b>'''', @space,	rcl.RelatedCourseList,
					dbo.fnHtmlCloseTag(@blockTag)
				)
		end as [Text]
	from ProgramSequence ps
		inner join Course c on ps.CourseId = c.Id
		inner join [Subject] sj on c.SubjectId = sj.Id
		left join @clcourses clc on clc.Id = c.Id
		outer apply (
			select crc.CourseId as Id, dbo.ConcatWithSep_Agg('''', '''', concat(crc.SubjectCode, '''' '''', crc.CourseNumber)) as RelatedCourseList
			from  (
				select
					top 100 percent drc.CourseId,
						rcs.SubjectCode,
						rc.CourseNumber
				from (
					/*Some courses have the same course cross-listed multiple times,
						so using a distinct is the easiest and most efficient way
						to remove the duplicates*/
					select distinct crc.CourseId, rc.Id as RelatedCourseId
					from CourseRelatedCourse crc
						inner join Course rc on rc.Id = coalesce(crc.Related_CourseId, crc.RelatedCourseId)
					where crc.CourseId = c.Id
						and c.IsCrossListed = 0
						and coalesce(c.CreatedOn, c.CreatedDate) < @minCrossListingDate
				) drc
					inner join Course rc on drc.RelatedCourseId = rc.Id
					inner join [Subject] rcs on rc.SubjectId = rcs.Id
	
				order by rcs.SubjectCode, rc.CourseNumber, rc.Id
			) crc
			group by crc.CourseId
		) rcl 
	where (
		ps.ProgramId = @entityId
		or exists (
			select top 1 1
			from ProgramSequence ps2
			where ps2.ProgramId = @entityId
			and ps.Id = ps2.ReferenceId
		)
	);
	
	insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
	select ''''ProgramSequence'''' as TableName
		, ps.Id
		, ''''CourseEntryRightColumnReplacement''''
		, case
			when ps.OverrideCalculation = 1
				then concat(
					format(ps.CalcMin, ''''0.0'''')
					, case
						when ps.CalcMax > ps.CalcMin
							then 
								concat(
									''''-''''
									, format(ps.CalcMax, ''''0.0'''')
								)
						else ''''''''
					end
				)
			when @isNonCredit = 1
				then
				case
					when (cd.TeachingUnitsLecture > 0
						or cd.MinSeats > 0
					)
						then concat(
							format((cd.TeachingUnitsLecture + cd.MinSeats), ''''0.0'''')
							, case
								when 1 = 1--Variable
								and (cd.TeachingUnitsWork > cd.TeachingUnitsLecture
									or cd.MaxSeats > cd.MinSeats
								)
									then 
										concat(
											''''-''''
											, format((cd.TeachingUnitsWork + cd.MaxSeats), ''''0.0'''')
										)
								else ''''''''
							end
						)
					else ''''''''
				end
			else
			concat(
				format(cd.MinCreditHour, ''''0.0'''')
				, case
					when 1 = 1--Variable
					and cd.MaxCreditHour > cd.MinCreditHour
						then concat(
							''''-''''
							, format(cd.MaxCreditHour, ''''0.0'''')
						)
					else ''''''''
				end
			)
		end as RenderedText
	from ProgramSequence ps
		left join CourseDescription cd on ps.CourseId = cd.CourseId
		left join CourseYesNo cyn on ps.CourseId = cyn.CourseId
	where ps.ProgramId = @entityId;

	declare @courseLeftColumQuery nvarchar(max) =
	''''select Id as [Value], RenderedText as [Text]
	from #renderedInjections ri
	where ri.TableName = ''''''''ProgramSequence'''''''' and ri.Id = @id
	and ri.InjectionType = ''''''''CourseEntryLeftColumnReplacement'''''''';
	'''';

	declare @courseMiddleColumnQuery nvarchar(max) =
	''''select Id as [Value], RenderedText as [Text]
	from #renderedInjections ri
	where ri.TableName = ''''''''ProgramSequence'''''''' and ri.Id = @id
	and ri.InjectionType = ''''''''CourseEntryMiddleColumn'''''''';
	'''';

	declare @CourseUnitsOveride nvarchar(max) =''''
		select Id as [Value]
			, RenderedText as [Text]
		from #renderedInjections ri
		where ri.TableName = ''''''''ProgramSequence''''''''
		and ri.Id = @id
		and ri.InjectionType = ''''''''CourseEntryRightColumnReplacement''''''''
		;
	'''';

	insert into @extraDetailsDisplay (String1, String2)
	values
		(''''CourseEntryLeftColumnReplacement'''', @courseLeftColumQuery)
		, (''''CourseEntryMiddleColumn'''', @courseMiddleColumnQuery)
		, (''''CourseEntryRightColumnReplacement'''', @CourseUnitsOveride )
	;

	declare @config StringPair;

	insert into @config (String1, String2)
	values (''''BlockItemTable'''', ''''ProgramSequence'''');

	exec upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @config = @config, @outputTotal = 0, @combineBlocks = 0;

	drop table if exists #renderedInjections;
'';

declare @serializedParameters nvarchar(max) = (
	select
		@entityId as id
		, json_query(
			concat(
				''['',
					dbo.fnGenerateBulkResolveQueryParameter(''@entityId'', @entityId, ''int''),
					'','',
					dbo.fnGenerateBulkResolveQueryParameter(''@isNonCredit'', @isNonCredit, ''bool''),
				'']''
			)
		) as [parameters]
	for json path
);

declare @serializedResults nvarchar(max);

exec dbo.upBulkResolveQuery @queryString = @queryString, @serializedParameters = @serializedParameters, @serializedResults = @serializedResults output;

--select @serializedResults;

declare @results table ([Value] int, [Text] nvarchar(max), SortOrder int, MinimumCreditHours decimal, MaximumCreditHours decimal)
insert into @results
select @entityId as [Value]
	, out.[Text]
	, out.SortOrder
	, out.MinimumCreditHours
	, out.MaximumCreditHours
from openjson(@serializedResults) with (
		ParamsParseSuccess bit ''$.paramsParseSuccess'',
		EntityResultSets nvarchar(max) ''$.entityResultSets'' as json,
		StatusMessages nvarchar(max) ''$.statusMessages'' as json
	) srr --srr = serialized results root
	outer apply openjson(srr.EntityResultSets) with (
		Id int ''$.id'',
		SortOrder int ''$.sortOrder'',
		QuerySuccess bit ''$.querySuccess'',
		ResultSets nvarchar(max) ''$.resultSets'' as json
	) ers
	outer apply openjson(ers.ResultSets) with (
		ResultSetNumber int ''$.resultSetNumber'',
		Results nvarchar(max) ''$.results'' as json
	) rs
	outer apply openjson(rs.Results) with (
		SerializedResult nvarchar(max) ''$.serializedResult'' as json,
		StatusMessages nvarchar(max) ''$.statusMessages'' as json
	) res
	outer apply openjson(res.SerializedResult) with (
		[Value] int ''$.Value'',
		[Text] nvarchar(max) ''$.Text'' ,
		SortOrder int ''$.SortOrder'',
		MinimumCreditHours decimal ''$.MinimumCreditHours'',
		MaximumCreditHours decimal ''$.MaximumCreditHours''
	) out
;

declare @tottalMin decimal(16,3) = (
	select sum(s.CalcMin)
	from (
		select
			case
				when @isNonCredit = 0
				and ps.CalcMin > 0
					then ps.CalcMin
				else 
				case
					when ps.CalcMin > 0
						then ps.CalcMin
					when (cd.TeachingUnitsLecture > 0
						or cd.MinSeats > 0
					)
						then (cd.TeachingUnitsLecture + cd.MinSeats)
					else 0
				end
			end as CalcMin
		from ProgramSequence ps
			left join CourseDescription cd on ps.CourseId = cd.CourseId
		where ps.ProgramId = @entityId
		and (ps.Parent_Id is null
			or @IsNonCredit = 1
		)
	) s
);

declare @tottalMax decimal (16,3) = (
	select sum(CalcMax) 
	from (
		select
			case
				when @isNonCredit = 0
				and ps.CalcMax > 0
					then ps.CalcMax
				else 
				case
					when ps.CalcMax > 0
						then ps.CalcMax
					when (cd.TeachingUnitsWork > 0
							or cd.MaxSeats > 0
					)
						then (cd.TeachingUnitsWork + cd.MaxSeats)
					else 0
				end
			end as CalcMax
		from ProgramSequence ps 
			left join CourseDescription cd on ps.CourseId = cd.CourseId
		where ps.ProgramId = @entityId
		and (ps.Parent_Id is null
			or @IsNonCredit = 1
		)
	) s
);

insert into @results ([Value], [Text], SortOrder)
select @entityId as [Value]
	, concat(
		''<div class="row course-blocks-total-credits">
			<div class="col-xs-12 col-sm-12 col-md-12 full-width-column text-right text-end">
				<span class="grand-total-units-label">''
					, case
						when @isNonCredit = 1
							then ''Total Hours''
						else ''Total''
					end
				, ''</span>''
				, ''<span class="grand-total-units-label-colon">: </span>''
				, ''<span class="grand-total-units-display">''
					, format(@tottalmin, ''0.0'')
					, case
						when @tottalmax > @tottalmin
							then
								concat(
									''-<wbr>''
									, format(@tottalmax, ''0.0'')
								)
						else ''''
					end
				, ''</span>''
			, ''</div>''
		, ''</div>''
	) as [Text]
	, (
		select max(SortOrder)
		from @results
	) + 1
;

select 
[Value]
	,STRING_AGG([Text], '''') WITHIN GROUP (ORDER BY SortOrder) AS [Text]
from @results
group by [Value];
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id