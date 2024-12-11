USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14245';
DECLARE @Comments nvarchar(Max) = 
	'Added the description they are missing to all active programs, edid the template query for the catalog to fix all their issues';
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
UPDATE p
SET p.Description = p.Description + '<p>The <strong>Academic Pathway</strong> is a tool for students that lists the following items: &bull; the recommended order in which to take the program courses &bull; suggested course when more than one option exists &bull; which semester each course is typically offered &bull; if the course has a prerequisite &bull; courses that may lead to a certificate (if offered in the program) If you are starting the program this term, click here to access the <a href="https://info.spcollege.edu/Community/AP/_layouts/15/WopiFrame.aspx?sourcedoc=/Community/AP/Shared Documents/Current_DIGFORN_AS.xlsx"><u>recommended Academic Pathway</u></a>. If you have already started the program, click here for the <a href="https://info.spcollege.edu/Community/AP/"><u>archived Academic Pathways</u></a>. Please verify the Academic Pathway lists your correct starting semester.</p> '
FROM Program as p
INNER JOIN StatusAlias AS sa on p.StatusAliasId = sa.Id
WHERE sa.Id = 1

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

declare @queryString nvarchar(max) = concat(
''
declare @paramDelim nvarchar(5) = '''','''';
			declare @queryString nvarchar(max) = ''''''''
			declare @inlineTag nvarchar(10) = ''''span'''';
			declare @classAttrib nvarchar(10) = ''''class'''';
			declare @sup nvarchar(5) = ''''sup'''';
			declare @space nvarchar(5) = '''' '''';
			declare @topLevelClass nvarchar(200) = ''''[{"Key":"class","Value":"row block-title-row-core"}]'''';
			declare @blockTypeClass nvarchar(200) = ''''[{"Key":"class","Value":"col-xs-9 col-sm-9 col-md-9 left-column text-left"}]'''';

			DROP TABLE IF EXISTS #renderedInjections;

			create table #renderedInjections (
				TableName sysname,
				Id int,
				InjectionType nvarchar(255),
				RenderedText nvarchar(max),
				primary key (TableName, Id, InjectionType)
			);

			declare @crossListed table (CourseId int, CombinedText nvarchar(max))

			--#region ProgramCourse rendered injections




			--#endregion ProgramCourse rendered injections

			--#region CourseOption rendered injections


			INSERT INTO #renderedInjections
			(TableName, Id, InjectionType, RenderedText)
				SELECT
					''''CourseOption'''' AS TableName
				   ,co.Id
				   ,''''BlockTitleReplacement''''
				   ,dbo.fnHtmlElement(''''div'''', 
					concat(
						dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(@classAttrib, ''''BlockType'''')),
							bt.Title,
						dbo.fnHtmlCloseTag(''''div''''),
						dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(@classAttrib, ''''Area Title'''')),
							co.Title,
						dbo.fnHtmlCloseTag(''''div''''),
						dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(@classAttrib, ''''Course BLock Title'''')),
							co.CourseOptionNote,
						dbo.fnHtmlCloseTag(''''div'''')
						), @topLevelClass
					)
				FROM CourseOption co
					LEFT JOIN BlockType bt ON bt.id = co.BlockTypeId
				WHERE co.ProgramId = @entityId
			--#endregion CourseOption rendered injections

			--Overriding the foot note becasue for some reason the identifer is going above the footnote textt for non-course requirment
			--do not have time to figure out why this is happening

			DECLARE @footnote table (Courseoptionid int, Footnote nvarchar(max))
			INSERT INTO @footnote
			SELECT DISTINCT 
				A.id,
				dbo.ConcatOrdered_Agg(A.SortOrder,concat(
					dbo.fnHtmlOpenTag(''''div'''', dbo.fnHtmlAttribute(''''class'''', ''''footnote'''')),
					dbo.fnHtmlOpenTag(''''sup'''', dbo.fnHtmlAttribute(''''class'''', ''''footnote-identifier'''')),
						A.ExceptionIdentifier,
					dbo.fnHtmlCloseTag(''''sup''''),
					A.OrHigherException,
					dbo.fnHtmlCloseTag(''''div'''')
				),1)
			FROM (select co.Id as id,pc.ExceptionIdentifier as ExceptionIdentifier,pc.OrHigherException,min(pc.SortOrder) as SortOrder
			from ProgramCourse pc 
				INNER JOIN courseoption co on co.id = pc.CourseOptionId
					and co.ProgramId = @entityId
			WHERE pc.ExceptionIdentifier is not null and pc.OrHigherException is not null
			Group by co.Id,pc.ExceptionIdentifier,pc.OrHigherException
			) A
			group by A.id

			INSERT INTO #renderedInjections
			(TableName, Id, InjectionType, RenderedText)
				SELECT
					''''CourseOption'''' AS TableName
				   ,co.Id
				   ,''''footnotetextReplacement''''
				   ,fn.Footnote
				FROM CourseOption co
					INNER JOIN @footnote fn on co.id = fn.Courseoptionid
				WHERE co.ProgramId = @entityId



			declare @programCourseExtraDetails nvarchar(max) =
			''''select
				Id as [Value], RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''''''ProgramCourse'''''''' and ri.Id = @id and ri.InjectionType = ''''''''CourseEntryLeftColumn'''''''';''''

			declare @courseOptionExtraDetails nvarchar(max) = ''''select
				Id as [Value], RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''''''CourseOption'''''''' and ri.Id = @id and ri.InjectionType = ''''''''BlockTitleReplacement'''''''';''''

			declare @noncourseExtraDetails nvarchar(max) = ''''select
				Id as [Value], RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''''''NonCourseTitle'''''''' and ri.Id = @id and ri.InjectionType = ''''''''NonCourseEntryLeftColumn'''''''';''''

			declare @FottnoteExtraDetails nvarchar(max) = ''''select
				Id as [Value], RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''''''CourseOption'''''''' and ri.Id = @id and ri.InjectionType = ''''''''footnotetextReplacement'''''''';''''


			declare @extraDetailsDisplay StringPair;

			INSERT INTO @extraDetailsDisplay
			(String1, String2)
			VALUES
			(''''CourseEntryLeftColumn'''', @programCourseExtraDetails),
			(''''BlockTitleReplacement'''', @courseOptionExtraDetails),
			(''''NonCourseEntryLeftColumn'''',@noncourseExtraDetails),
			(''''BlockFooterSuffix'''',@FottnoteExtraDetails)

			declare @classOverrides StringTriple;

			INSERT INTO @classOverrides
			(String1, String2, String3)
			VALUES
			(''''CourseEntrySubject'''', ''''Wrapper'''', ''''hidden hidden-course-entry-subject''''),
			(''''CourseEntryCourseNumber'''', ''''Wrapper'''', ''''hidden course-entry-course-number''''),
			(''''CourseCrossListingList'''', ''''Wrapper'''', ''''hidden course-cross-listing-list''''),
			(''''NonCourseEntryTitle'''', ''''Wrapper'''', ''''hidden non-course-entry-title'''')
			,(''''footnoteidentifier'''', ''''Wrapper'''', ''''hidden footnote-identifier''''),
			(''''footnotetext'''', ''''Wrapper'''', ''''hidden footnote-text'''')


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


			EXEC upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId
															,@elementClassOverrides = @classOverrides
															,@extraDetailsDisplay = @extraDetailsDisplay
															,@outputTotal = 1
															,@combineBlocks = 1
															,@creditHoursLabel = ''''Credits''''
															,@config = @config
															,@hoursScale = 0;

			DROP TABLE IF EXISTS #renderedInjections;
'',
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
WHERE Id = 2