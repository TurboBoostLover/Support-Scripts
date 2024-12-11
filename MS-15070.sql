USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15070';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog Program Query';
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

UPDATE OutputTemplateClient
SET TemplateQuery = '

		declare @entityModels_internal table (
			InsertOrder int identity (1, 1) primary key,
			Id int index ixEntityModels_internal_Id,
			Model nvarchar(max)
		);

		insert into @entityModels_internal (Id, Model)
		select em.[Key], em.[Value]
		from @entityModels em;

		declare @messageType table (
			Id int primary key not null,
			Title nvarchar(50)
		);

		insert into @messageType (Id, Title)
		values
		(1, ''error''),
		(2, ''warning''),
		(3, ''information''),
		(4, ''debug'');

		declare @errorMessage int = 1;
		declare @warningMessage int = 2;
		declare @informationMessage int = 3;
		declare @debugMessage int = 4;

		declare @renderingMessageText nvarchar(max);

		declare @paramPlaceholder nvarchar(5) = '' '';

		declare @templateMessages table (
			Id int identity (1, 1) primary key,
			MessageTypeId int not null,
			MessageText nvarchar(max)
		);

		declare @messageSource sysname = ''upGenerateGroupConditionsCourseBlockDisplay default wrapper template'';

		declare @space nvarchar(5) = '' '';

		declare @hoursScale int = null;
		declare @creditHoursLabel nvarchar(255) = (
			select 
				case 
					when awt.Id in (
						13--Noncredit Certificate of Competency
						, 14--Noncredit Certificate of Completion
					)
						then ''Hours:''
					else ''Units:''
				end as RenderedText
			from Program p
				inner join AwardType awt on p.AwardTypeId = awt.Id
				inner join @entityModels_internal emi on p.Id = emi.Id
		);
		declare @serializedExtraDetailsDisplay nvarchar(max) = null;

		select
			@hoursScale = atc.HoursScale,
			--@creditHoursLabel = atc.CreditHoursLabel,
			@serializedExtraDetailsDisplay = atc.ExtraDetailsDisplay
		from openjson(@additionalTemplateConfig)
		with (
			HoursScale int ''$.hoursScale'',
			--CreditHoursLabel nvarchar(255) ''$.creditHoursLabel'',
			ExtraDetailsDisplay nvarchar(max) ''$.extraDetailsDisplay''
		) atc;

		declare @queryString nvarchar(max) = concat(
			''declare @extraDetailsDisplay StringPair;

			insert into @extraDetailsDisplay (String1, String2)
			select edd.Title, edd.Query
			from openjson(@serializedExtraDetailsDisplay)
			with (
				Title nvarchar(max) ''''$.title'''',
				Query nvarchar(max) ''''$.query''''
			) edd;
	
			declare @config StringPair;
			insert into @config
			(String1, String2)
			values
			(''''CourseEntryLink'''', ''''{
				"title": "Course Summary",
				"placement": "right",
				"trigger": "focus",
				"content": "",
				"curriculumPresentationId": 1
			}'''');

			------------------------------------------------------------------------------------------------------------
			drop table if exists #renderedInjections;

		create table #renderedInjections (
			TableName sysname
			, Id int
			, InjectionType nvarchar(255)
			, RenderedText nvarchar(max)
			, primary key (TableName, Id, InjectionType)
		);

				insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
		select ''''ProgramCourse'''' as TableName, pc.Id, ''''CourseEntryRightColumnReplacement'''' as InjectionType
			, concat(
				dbo.fnHtmlOpenTag(''''span'''', dbo.fnHtmlAttribute(''''class'''', ''''Units''''))
					,		FORMAT(cd.MinCreditHour, ''''#0.00#'''')
					, dbo.fnHtmlCloseTag(''''span'''')
			)
		from ProgramCourse pc 
			inner join CourseOption co on pc.CourseOptionId = co.Id 
			inner join Course c on pc.CourseId = c.Id 
			inner join CourseDescription cd on c.Id = cd.CourseId 
			inner join Program p on co.ProgramId = p.Id 
		where co.ProgramId = @entityId;


					declare @courseLRightColumQuery nvarchar(max) = ''''
			select Id as [Value]
				, RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''''''ProgramCourse''''''''
			and ri.Id = @id
			and ri.InjectionType = ''''''''CourseEntryRightColumnReplacement'''''''';
		'''';
						insert into @extraDetailsDisplay (String1, String2)
			values 
				(''''NonCourseEntryRightColumnReplacement'''', @courseLRightColumQuery)
				, (''''CourseEntryRightColumnReplacement'''', @courseLRightColumQuery)
			;

			exec dbo.upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @config = @config'',
			case when @hoursScale is not null then '', @hoursScale = @hoursScale'' else '''' end,
			case when @creditHoursLabel is not null then '', @creditHoursLabel = @creditHoursLabel'' else '''' end, '';''
		);

		declare @serializedParameters nvarchar(max) = (
			select
				emi.Id as [id], json_query(p.Parameters) as [parameters]
			from @entityModels_internal emi
			cross apply (
				select
					concat(
						''['',
							dbo.fnGenerateBulkResolveQueryParameter(''@entityId'', emi.Id, ''int''), '','',
							dbo.fnGenerateBulkResolveQueryParameter(''@hoursScale'', @hoursScale, ''int''), '','',
							dbo.fnGenerateBulkResolveQueryParameter(''@creditHoursLabel'', @creditHoursLabel, ''string''), '','',
							dbo.fnGenerateBulkResolveQueryParameterMaxString(''@serializedExtraDetailsDisplay'', @serializedExtraDetailsDisplay, ''string''),
						'']''
					) as Parameters
			) p
			for json path
		);

		declare @serializedResults nvarchar(max);
		exec dbo.upBulkResolveQuery @queryString = @queryString, @serializedParameters = @serializedParameters, @serializedResults = @serializedResults output;

		declare @flattenedResults table (
			Id int index ixFlattenedResults_Id,
			RenderedText nvarchar(max),
			ResultSetNumber int index ixTemplateResults_ResultSetNumber,
			ParamsParseSuccess bit,
			QuerySuccess bit
		);

		insert into @flattenedResults (Id, RenderedText, ResultSetNumber, ParamsParseSuccess, QuerySuccess)
		select
			ers.Id
			, concat( 
				-- course blocks wrapper
				dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''program-requirements-container'')),
					-- header
					dbo.fnHtmlOpenTag(''header'', concat(dbo.fnHtmlAttribute(''class'', ''program-requirements-header''), '' '', dbo.fnHtmlAttribute(''style'', ''border-bottom: 1px solid silver;''))),
						dbo.fnHtmlOpenTag(''h3'', concat(dbo.fnHtmlAttribute(''class'', ''program-requirements-header-title''), '' '', dbo.fnHtmlAttribute(''style'', ''margin-bottom: 3px;''))),
							''Program Requirements'',
						dbo.fnHtmlClosetag(''h3''),
					dbo.fnHtmlCloseTag(''header''),
					-- content
					dbo.fnHtmlOpenTag(''div'', concat(dbo.fnHtmlAttribute(''class'', ''program-requirements-content''), '' '', dbo.fnHtmlAttribute(''style'', ''margin-top:10px;''))),
						dres.[Text],
					dbo.fnHtmlCloseTag(''div''),
				dbo.fnHtmlCloseTag(''div'')
			)
			, rs.ResultSetNumber
			, srr.ParamsParseSuccess
			, ers.QuerySuccess
		from openjson(@serializedResults)
		with (
			ParamsParseSuccess bit ''$.paramsParseSuccess'',
			EntityResultSets nvarchar(max) ''$.entityResultSets'' as json,
			StatusMessages nvarchar(max) ''$.statusMessages'' as json
		) srr
		--srr = serialized results root
		outer apply (
			select *
			from openjson(srr.EntityResultSets)
			with (
				Id int ''$.id'',
				SortOrder int ''$.sortOrder'',
				QuerySuccess bit ''$.querySuccess'',
				ResultSets nvarchar(max) ''$.resultSets'' as json
			) ent
		) ers
		outer apply (
			select *
			from openjson(ers.ResultSets)
			with (
				ResultSetNumber int ''$.resultSetNumber'',
				Results nvarchar(max) ''$.results'' as json
			)
		) rs
		outer apply (
			select *
			from openjson(rs.Results)
			with (
				SerializedResult nvarchar(max) ''$.serializedResult'' as json,
				StatusMessages nvarchar(max) ''$.statusMessages'' as json
			)
		) res
		outer apply (
			select *
			from openjson(res.SerializedResult)
			with (
				[Value] int ''$.Value'',
				[Text] nvarchar(max) ''$.Text''
			)
		) dres;


		select
			emi.Id as [Value], fr.RenderedText as [Text]
		from @entityModels_internal emi
		left outer join @flattenedResults fr on (fr.ResultSetNumber = 1 and emi.Id = fr.Id)
		order by emi.InsertOrder;

		if(exists (
			select top 1 1
			from @flattenedResults fr
			where (fr.ParamsParseSuccess = 0 or fr.QuerySuccess = 0)
		))
		begin;
			set @renderingMessageText = concat(''Call to upGenerateGroupConditionsCourseBlockDisplay failed, '',
				''please examine the serialized call results below for details'');

			--Create and return an extra result set with details of the error
			insert into @templateMessages (MessageTypeId, MessageText)
			values
			(@errorMessage, @renderingMessageText),
			(@errorMessage, @serializedResults);

			select
				@messageSource as MessageSource, tm.Id as OrderInSource, tm.MessageTypeId, mt.Title as MessageTypeTitle, tm.MessageText
			from @templateMessages tm
			inner join @messageType mt on tm.MessageTypeId = mt.Id
			order by tm.Id;

			declare @throwMessage nvarchar(2048) = concat(@messageSource, '': Call to upGenerateGroupConditionsCourseBlockDisplay failed'');
			throw 50000, @throwMessage, 1;
		end;
		'
		WHERE Id = 3

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '		select c.Id as [Value]
			, coalesce(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title, s.SubjectCode + '' '' + c.CourseNumber, c.Title) + 
				case
					when sa.StatusBaseId != 1 then '' ('' + sa.Title + '')'' 
					when sa.StatusBaseId = 1 then ''''
				end as [Text]
			, s.Id as FilterValue
			/*
				Have to force noncredit courses to have Variable = 1, where client has not been using ''Variable'' field at this time, to get the program page ''Course Requirements'' to pull the ''Standard'' value as a ''Max'' value in the form for calculations to work for noncredit  courses.
				Developer: Mike G (11/28/2022)
			*/
			, case 
				when ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then 1
				else cd.Variable
			end as IsVariable
			, case
				when cd.InstrTypeId in (
					7--Lecture
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then cast(cd.MinLectureHour as decimal(16, 2))
				when cd.InstrTypeId in (
					8--Laboratory (Scheduled)
					, 9--Laboratory (Arranged Hour) - Open Entry
					, 10--Laboratory (Arranged Hour) - Not Open Entry
					, 17--Laboratory hours (with homework)
					, 18--Laboratory hours (without homework)
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then cast(cd.MinLabHour as decimal(16, 2))
				when cd.InstrTypeId in (
					11--Lecture/Lab
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then cast(coalesce(cd.MinLectureHour, 0) as decimal(16, 2)) + cast(coalesce(cd.MinLabHour, 0) as decimal(16, 1))
				else cast(cd.MinCreditHour as decimal(16, 2))
			end as [Min]
			, case
				when cd.InstrTypeId in (
					7--Lecture
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then (
						case
							when cd.Variable = 1
								then cast(cd.MaxLectureHour as decimal(16, 2))
							else cast(cd.ShortTermLectureHour as decimal(16, 2))
						end
					)
				when cd.InstrTypeId in (
					8--Laboratory (Scheduled)
					, 9--Laboratory (Arranged Hour) - Open Entry
					, 10--Laboratory (Arranged Hour) - Not Open Entry
					, 17--Laboratory hours (with homework)
					, 18--Laboratory hours (without homework)
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then (
						case
							when cd.Variable = 1
								then cast(cd.MaxLabHour as decimal(16, 2))
							else cast(cd.LabFees as decimal(16, 2))
						end
					)
				when cd.InstrTypeId in (
					11--Lecture/Lab
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then (
						case
							when cd.Variable = 1
								then cast(coalesce(cd.MaxLectureHour, 0) as decimal(16, 2)) + cast(coalesce(cd.MaxLabHour, 0) as decimal(16, 1))
							else cast(coalesce(cd.ShortTermLectureHour, 0) as decimal(16, 2)) + cast(coalesce(cd.LabFees, 0) as decimal(16, 1))
						end
					)
				else cast(cd.MaxCreditHour as decimal(16, 2))
			end as [Max]
		from Course c
			inner join CourseDescription cd on c.Id = cd.CourseId
			inner join [Subject] s on c.SubjectId = s.Id
			inner join StatusAlias sa on c.StatusAliasId = sa.Id
			inner join CourseAttribute ca on c.Id = ca.CourseId
		where c.Active = 1
		and (sa.StatusBaseId in (1, 2, 4, 6, 8)--1 = Active, 2 = Approved, 4 = Draft, 6 = In Review, 8 = Tabled
			or exists (
				select 1
				from ProgramCourse pc
					inner join CourseOption co on pc.CourseOptionId = co.Id
				where co.ProgramId = @entityId
				and pc.CourseId = c.Id
			)
		)
		order by [Text];'
, ResolutionSql = '

		select c.Id as [Value]
			, coalesce(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title, s.SubjectCode + '' '' + c.CourseNumber, c.Title) + 
				case
					when sa.StatusBaseId != 1 then '' ('' + sa.Title + '')'' 
					when sa.StatusBaseId = 1 then ''''
				end as [Text]
			, s.Id as FilterValue
			/*
				Have to force noncredit courses to have Variable = 1, where client has not been using ''Variable'' field at this time, to get the program page ''Course Requirements'' to pull the ''Standard'' value as a ''Max'' value in the form for calculations to work for noncredit  courses.
				Developer: Mike G (11/28/2022)
			*/
			, case 
				when ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then 1
				else cd.Variable
			end as IsVariable
			, case
				when cd.InstrTypeId in (
					7--Lecture
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then cast(cd.MinLectureHour as decimal(16, 2))
				when cd.InstrTypeId in (
					8--Laboratory (Scheduled)
					, 9--Laboratory (Arranged Hour) - Open Entry
					, 10--Laboratory (Arranged Hour) - Not Open Entry
					, 17--Laboratory hours (with homework)
					, 18--Laboratory hours (without homework)
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then cast(cd.MinLabHour as decimal(16, 2))
				when cd.InstrTypeId in (
					11--Lecture/Lab
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then cast(coalesce(cd.MinLectureHour, 0) as decimal(16, 2)) + cast(coalesce(cd.MinLabHour, 0) as decimal(16, 2))
				else cast(cd.MinCreditHour as decimal(16, 2))
			end as [Min]
			, case
				when cd.InstrTypeId in (
					7--Lecture
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then (
						case
							when cd.Variable = 1
								then cast(cd.MaxLectureHour as decimal(16, 2))
							else cast(cd.ShortTermLectureHour as decimal(16, 2))
						end
					)
				when cd.InstrTypeId in (
					8--Laboratory (Scheduled)
					, 9--Laboratory (Arranged Hour) - Open Entry
					, 10--Laboratory (Arranged Hour) - Not Open Entry
					, 17--Laboratory hours (with homework)
					, 18--Laboratory hours (without homework)
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then (
						case
							when cd.Variable = 1
								then cast(cd.MaxLabHour as decimal(16, 2))
							else cast(cd.LabFees as decimal(16, 2))
						end
					)
				when cd.InstrTypeId in (
					11--Lecture/Lab
				)
					and ca.CourseCreditStatusId = 4 --4 = Non-Credit
					then (
						case
							when cd.Variable = 1
								then cast(coalesce(cd.MaxLectureHour, 0) as decimal(16, 2)) + cast(coalesce(cd.MaxLabHour, 0) as decimal(16, 2))
							else cast(coalesce(cd.ShortTermLectureHour, 0) as decimal(16, 2)) + cast(coalesce(cd.LabFees, 0) as decimal(16, 2))
						end
					)
				else cast(cd.MaxCreditHour as decimal(16, 2))
			end as [Max]
		from Course c
			inner join CourseDescription cd on c.Id = cd.CourseId
			inner join [Subject] s on c.SubjectId = s.Id
			inner join StatusAlias sa on c.StatusAliasId = sa.Id
			inner join CourseAttribute ca on c.Id = ca.CourseId
		where c.Id = @id;
	
'
WHERE Id = 141


DECLARE @programId int

DROP TABLE IF EXISTS #calculationResults

create table #calculationResults
(
    TableName sysname,
    Id int,
    Min decimal(16, 3),
    Max decimal(16, 3),
    IsVariable bit
);

declare programCursor cursor fast_forward for
	select id
	FROM Program;

open programCursor;

fetch next from programCursor
	into @programId;

while @@fetch_status = 0
	begin;
    exec upCalculateNestedCourseBlockEntries @entityId = @programId, @resultTable = '#calculationResults';

    fetch next from programCursor
		into @programId;
end;

close programCursor;
deallocate programCursor;

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Mt.MEtaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (
		141
	)
)