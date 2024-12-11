USE [rccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15927';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog Query';
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
UPDATE OutputTemplateClient
SET TemplateQuery = '
		declare @entityModels_internal table (
			InsertOrder int identity (1, 1) primary key,
			Id int index ixEntityModels_internal_Id,
			Model nvarchar(max)
		);

		insert into @entityModels_internal (Id, Model)
		--values (360, '''');
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
		declare @creditHoursLabel nvarchar(255) = null;
		declare @serializedExtraDetailsDisplay nvarchar(max) = null;

		select
			@hoursScale = atc.HoursScale,
			@creditHoursLabel = atc.CreditHoursLabel,
			@serializedExtraDetailsDisplay = atc.ExtraDetailsDisplay
		from openjson(@additionalTemplateConfig)
		with (
			HoursScale int ''$.hoursScale'',
			CreditHoursLabel nvarchar(255) ''$.creditHoursLabel'',
			ExtraDetailsDisplay nvarchar(max) ''$.extraDetailsDisplay''
		) atc;

		declare @queryString nvarchar(max) = ''
		declare @extraDetailsDisplay StringPair;

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
				dbo.fnHtmlOpenTag(''''span'''', dbo.fnHtmlAttribute(''''class'''', ''''Hours''''))
					,dbo.fnHtmlOpenTag(''''span'''', dbo.fnHtmlAttribute(''''class'''', ''''LectureHours''''))
						, ''''Lecture: ''''
						, cd.MinLectureHour
						, case 				
							when cd.Variable = 1
								and cd.MaxLectureHour is not null				
								then concat(''''-'''', cd.MaxLectureHour)			
						end
					, dbo.fnHtmlCloseTag(''''span'''')
					, dbo.fnHtmlOpenTag(''''span'''', dbo.fnHtmlAttribute(''''class'''', ''''ActivityHours''''))
						, ''''<br>Activity: '''', cd.MinOtherHour
						, case
							when cd.Variable = 1
								and cd.MaxOtherHour is not null
								then concat(''''-'''', cd.MaxOtherHour)
						end
					, dbo.fnHtmlCloseTag(''''span'''')
					, dbo.fnHtmlOpenTag(''''span'''', dbo.fnHtmlAttribute(''''class'''', ''''LabHours''''))
						, ''''<br />Lab: ''''
						, cd.MinLabHour
						, case
							when cd.Variable = 1
								and cd.MaxLabHour is not null
								then concat(''''-'''', cd.MaxLabHour)
						end
					, dbo.fnHtmlCloseTag(''''span'''')
				, dbo.fnHtmlCloseTag(''''span'''')
			)
		from ProgramCourse pc 
			inner join CourseOption co on pc.CourseOptionId = co.Id 
			inner join Course c on pc.CourseId = c.Id 
			inner join CourseDescription cd on c.Id = cd.CourseId 
			inner join Program p on co.ProgramId = p.Id 
		where co.ProgramId = @entityId;

		insert into #renderedInjections	(TableName, Id, InjectionType, RenderedText)
		select ''''ProgramCourse'''' as TableName, pc.Id, ''''CourseEntryLeftColumnReplacement'''' as InjectionType
			, concat(
					dbo.fnHtmlOpenTag(''''span'''',
					concat(
						dbo.fnHtmlAttribute(''''class'''', ''''course-identifier'''')
						, '''' ''''
						, dbo.fnHtmlAttribute(''''data-course-id'''', c.Id)
					)
				)
				, dbo.fnHtmlOpenTag(''''span'''',
					concat(
						dbo.fnHtmlAttribute(''''class'''', ''''subject-code'''')
						, '''' ''''
						, dbo.fnHtmlAttribute(''''title'''', dbo.fnHtmlEntityEscape(s.Title))
					)
				)
				, s.SubjectCode
				, dbo.fnHtmlCloseTag(''''span'''')
					, ''''-''''
					, dbo.fnHtmlOpenTag(''''span'''', dbo.fnHtmlAttribute(''''class'''', ''''course-number''''))
						, c.CourseNumber
					, dbo.fnHtmlCloseTag(''''span'''')
				, dbo.fnHtmlCloseTag(''''span'''')
				, dbo.fnHtmlOpenTag(''''sup'''', dbo.fnHtmlAttribute(''''class'''', ''''footnote-identifier''''))
					, pc.ExceptionIdentifier
				, dbo.fnHtmlCloseTag(''''sup'''')
			) as [Text]
		from ProgramCourse pc
			inner join Course c on pc.CourseId = c.Id
			inner join [Subject] s on c.SubjectId = s.Id
			inner join CourseOption co on co.Id = pc.CourseOptionId
		where co.ProgramId = @entityId;

		insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
		select ''''ProgramCourse'''' as TableName, pc.Id, ''''CourseEntryMiddleColumn''''
			, concat(
				dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''row''''))
					, dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''col-xs-9 col-sm-9 col-md-9''''))
						, dbo.fnHtmlOpenTag(''''span'''', dbo.fnHtmlAttribute(''''class'''', ''''course-entry-title''''))
							, c.Title
						, dbo.fnHtmlCloseTag(''''span'''')
					, dbo.fnHtmlCloseTag(''''div'''')
					, case
						when p.AwardTypeId not in (1,2)
							then concat(
								dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''col-xs-3 col-sm-3 col-md-3''''))
									, dbo.fnHtmlOpenTag(''''span'''', dbo.fnHtmlAttribute(''''class'''', ''''course-sequence''''))
										, L10.ShortText
									, dbo.fnHtmlCloseTag(''''span'''')
								, dbo.fnHtmlCloseTag(''''div'''')
							)
						else ''''''''
					end
				, dbo.fnHtmlCloseTag(''''div'''')
			) as RenderedText 
		from ProgramCourse pc     
			inner join CourseOption co on pc.CourseOptionId = co.Id     
			inner join Course c on pc.CourseId = c.Id
			left join Lookup10 L10 on pc.lookup10Id = L10.Id
			inner join Program p on co.ProgramId = p.Id
		where co.ProgramId = @entityId;

		insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
		select ''''CourseOption'''' as TableName, co.Id, ''''BlockHeaderSuffix''''
			, concat(
				dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''row column-heading-row bg-primary''''))
					, dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''col-xs-2 col-sm-2 col-md-2 left-column text-left''''))
						, ''''COURSE''''
					, dbo.fnHtmlCloseTag(''''div'''')
					, dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''col-xs-6 col-sm-6 col-md-6 left-middle-column text-left''''))
						, ''''TITLE''''
					, dbo.fnHtmlCloseTag(''''div'''')
					, dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''col-xs-2 col-sm-2 col-md-2 right-middle-column text-left''''))
						, case
							when p.AwardTypeId not in (1,2)
								then ''''SEQUENCE''''
							else ''''&nbsp;''''
						end
					, dbo.fnHtmlCloseTag(''''div'''')
					, dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''col-xs-2 col-sm-2 col-md-2 right-column text-right''''))
						, case
							when p.AwardTypeId not in (8,9)
								then ''''UNITS''''
							else ''''HOURS''''
						end
					, dbo.fnHtmlCloseTag(''''div'''')
				, dbo.fnHtmlCloseTag(''''div'''')
			) as RenderedText
		from CourseOption co
			inner join Program p on co.ProgramId = p.Id
		where p.Id = @entityId;

		declare @courseLRightColumQuery nvarchar(max) = ''''
			select Id as [Value]
				, RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''''''ProgramCourse''''''''
			and ri.Id = @id
			and ri.InjectionType = ''''''''CourseEntryRightColumnReplacement'''''''';
		'''';

		declare @courseLeftColumQuery nvarchar(max) = ''''
			select Id as [Value]
				, RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''''''ProgramCourse''''''''
			and ri.Id = @id
			and ri.InjectionType = ''''''''CourseEntryLeftColumnReplacement'''''''';
		'''';

		declare @programCourseExtraDetails nvarchar(max) =	''''
			select Id as [Value]
				, RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''''''ProgramCourse''''''''
			and ri.Id = @id
			and ri.InjectionType = ''''''''CourseEntryMiddleColumn'''''''';
		'''';

		declare @blockHeaderExtraDetails nvarchar(max) = ''''
			select Id as [Value]
				, RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''''''CourseOption''''''''
			and ri.Id = @id
			and ri.InjectionType = ''''''''BlockHeaderSuffix'''''''';
		'''';

		if exists (    
			select top 1 1
			from Program
			where Id = @entityId
			and AwardTypeId in (8, 9) /*	8 = Certificate of Competency, 9 = Certificate of Completion */
			and ProgramTypeId <> 215 /* 215 = Non-Credit */
		)
		begin
			insert into @extraDetailsDisplay (String1, String2)
			values 
				(''''CourseEntryLeftColumnReplacement'''', @courseLeftColumQuery)
				, (''''CourseEntryMiddleColumnReplacement'''', @programCourseExtraDetails)
				, (''''CourseEntryRightColumnReplacement'''', @courseLRightColumQuery)
				, (''''BlockHeaderSuffix'''', @blockHeaderExtraDetails)
			;

			exec upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @creditHoursLabel = ''''Hours'''', @hoursScale = 2;

			drop table if exists #renderedInjections;
		end
		else if exists (
			select top 1 1
			from Program
			where Id = @entityId
			and ProgramTypeId = 215 /* 215 = Non-Credit */
		)
		begin
			insert into @extraDetailsDisplay (String1, String2)
			values 
				(''''CourseEntryLeftColumnReplacement'''', @courseLeftColumQuery)
				, (''''CourseEntryMiddleColumnReplacement'''', @programCourseExtraDetails)
				, (''''BlockHeaderSuffix'''', @blockHeaderExtraDetails)
			;

			exec upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @creditHoursLabel = ''''Hours'''', @hoursScale = 2;

			drop table if exists #renderedInjections;
		end
		else 
		begin
			insert into @extraDetailsDisplay (String1, String2)
			values 
				(''''CourseEntryLeftColumnReplacement'''', @courseLeftColumQuery)
				, (''''CourseEntryMiddleColumnReplacement'''', @programCourseExtraDetails)
				, (''''BlockHeaderSuffix'''', @blockHeaderExtraDetails)
			;

			exec upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @hoursScale = 2;

			drop table if exists #renderedInjections;
		end;
	
''

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
			ers.Id, dres.Text, rs.ResultSetNumber,
			srr.ParamsParseSuccess, ers.QuerySuccess
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

		declare @blockWrapperTag nvarchar(10) = ''div'';
		declare @headerTag nvarchar(10) = ''div'';
		declare @listWrapperTag nvarchar(10) = ''ol'';
		declare @listItemTag nvarchar(10) = ''li'';
		declare @dataElementTag nvarchar(10) = ''span'';
		declare @boldDataElementTag nvarchar(10) = ''b'';
		declare @classAttribute nvarchar(10) = ''class'';

		select
			emi.Id as [Value], 
			concat(
				dbo.fnHtmlOpenTag(@blockWrapperTag, dbo.fnHtmlAttribute(@classAttribute, ''program-Requirements-wrapper'')),
							dbo.fnHtmlOpenTag(@headerTag, dbo.fnHtmlAttribute(@classAttribute, ''program-Requirements-header'')),
								dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttribute, ''program-Requirements-header-wrapper'')),
									''Program Requirements'',
								dbo.fnHtmlCloseTag(@boldDataElementTag),
							dbo.fnHtmlCloseTag(@blockWrapperTag),
						dbo.fnHtmlCloseTag(@blockWrapperTag),
				fr.RenderedText
			) as [Text]
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
WHERE Id = 4