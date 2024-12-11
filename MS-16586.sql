USE [cinc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16586';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Requirements Presention';
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
INSERT INTO OutputTemplateClient
(TemplateQuery, Title, Description, StartDate)
VALUES
('
declare @entityModels_internal table (
	InsertOrder int identity (1, 1) primary key,
	Id int index ixEntityModels_internal_Id,
	Model nvarchar(max)
);

insert into @entityModels_internal (Id, Model)
select em.[Key], em.[Value]
from @entityModels em;

declare @flattenedResults table (
	Id int index ixFlattenedResults_Id,
	RenderedText nvarchar(max),
	ResultSetNumber int index ixTemplateResults_ResultSetNumber,
	ParamsParseSuccess bit,
	QuerySuccess bit
);

declare @courseCurriculumPresentationId int = (0);

select @courseCurriculumPresentationId = atc.CurriculumPresentationId
from openjson(@additionalTemplateConfig, ''$.courseLinkSummary'')
with (
	CurriculumPresentationId int ''$.CurriculumPresentationId''
) atc;

declare @queryString nvarchar(max) = 
''SELECT
	''''
	<style>
		.Program-Summary-Details
		{
			border-bottom-style:dotted;
			border-bottom-width:1px; 
			margin-left: 0px !important; 
			border-bottom-color:lightgray;
		}
		.course-block-standard .parent-wrapper[data-has-children="true"]>.non-course-row-core-wrapper>.non-course-row-core 
		{
			background-color: #d9E2FC !important;
			font-weight: bold;
		}
		.header-subject, .header-title, .header-units
		{
			background-color: #2E74B5 !important;
			font-weight: bold;
			color: white;
		}
		.summary-header{
			margin-left: 0px !important;
		}
	</style>
	<div class="row summary-header">
		<div class="col-xs-2 col-sm-2 col-md-2 text-center  header-subject">
			SUBJECT #
		</div>
		<div class="col-xs-8 col-sm-8 col-md-8 text-center  header-title">
			TITLE
		</div>
		<div class="col-xs-2 col-sm-2 col-md-2 text-right header-units">
			UNITS
		</div>
	</div>'''' As Text,
	0 As VAlue''
;

declare @serializedParameters nvarchar(max) = (
	select
		emi.Id as [id], json_query(p.Parameters) as [parameters]
	from @entityModels_internal emi
	cross apply (
		select
			concat(
				''['',
					dbo.fnGenerateBulkResolveQueryParameter(''@entityId'', emi.Id, ''int''),  '','',
					dbo.fnGenerateBulkResolveQueryParameter(''@courseCurriculumPresentationId'', @courseCurriculumPresentationId, ''int''),
				'']''
			) as Parameters
	) p
	for json path
);

declare @serializedResults nvarchar(max);
exec dbo.upBulkResolveQuery @queryString = @queryString, @serializedParameters = @serializedParameters, @serializedResults = @serializedResults output;

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

set @queryString =
''declare @config StringPair;

insert into @config (String1, String2)
values
(''''BlockItemTable'''', ''''ProgramSequence'''');

declare @elementClassOverrides StringTriple;      
insert into @elementClassOverrides (String1, String2, String3)    
values (''''CourseCrossListingList'''', ''''Wrapper'''', ''''hidden d-none'''');   

exec dbo.upGenerateGroupConditionsCourseBlockDisplay 
	@entityId = @entityId
	, @elementClassOverrides = @elementClassOverrides
	, @config = @config
	, @outputTotal = 0
;'' 

exec dbo.upBulkResolveQuery @queryString = @queryString, @serializedParameters = @serializedParameters, @serializedResults = @serializedResults output;

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

set @queryString =
''SELECT
	CONCAT(
		''''<div class="row Program-Summary-Details" style="">'''',
			''''<div class="col-xs-11 col-sm-11 col-md-11 text-right text-end">'''',
				MaxText01,
			''''</div>'''',
			''''<div class="col-xs-1 col-sm-1 col-md-1 three-column right-column text-right text-end">'''',
				''''<b>'''',
					Case
						when Decimal02 is not null
							then CONCAT(FORMAT(Decimal01,''''###.###''''), ''''-'''', FORMAT(Decimal02,''''###.###''''))
						ELSE FORMAT(Decimal01,''''###.###'''')
					END,
				''''</b>'''',
			''''</div>'''',
		''''</div>''''
	) As Text,
	0 As Value
FROM GenericOrderedList01
WHERE ProgramId = @entityid
order by sortorder'' 

exec dbo.upBulkResolveQuery @queryString = @queryString, @serializedParameters = @serializedParameters, @serializedResults = @serializedResults output;

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
', 'Custom Program Output', '1 Tier Program Blocks', GETDATE())

DECLARE @ID int = SCOPE_IDENTITY()

INSERT INTO OutputTemplateModelMappingClient
(OutputTemplateClientId, OutputModelBaseId, Title, Description)
VALUES
(@ID, 2, 'Custom Program Output', '1 Tier Program Blocks')

DECLARE @ID2 int = SCOPE_IDENTITY()

UPDATE CurriculumPresentationOutputFormat
SET OutputTemplateModelMappingClientId = @ID2
, OutputTemplateModelMappingBaseId = NULL
WHERE Id in (3, 4)