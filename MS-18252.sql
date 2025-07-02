USE [gavilan];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18252';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Block Display in Catalog to include course info';
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
(TemplateQuery, Title ,Description, StartDate)
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
', 'Program Requirements', 'Program Requirements with Course Links', GETDATE())

DECLARE @Temp int = SCOPE_IDENTITY()

INSERT INTO OutputTemplateModelMappingClient
(OutputTemplateClientId, OutputModelBaseId, Title, Description)
VALUES
(@Temp, 2, 'Program Requirements', 'Standard Program Requirements with Course links')

DECLARE @ID int = SCOPE_IDENTITY()

UPDATE CurriculumPresentationOutputFormat
SET OutputTemplateModelMappingBaseId = NULL
, OutputTemplateModelMappingClientId = @ID
WHERE CurriculumPresentationId = 2