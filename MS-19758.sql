USE [madera];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19758';
DECLARE @Comments nvarchar(Max) = 
	'Add Catalog query for programs since they use ProgramSequence and not CourseOption';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
SET QUOTED_IDENTIFIER OFF

DECLARE @TempQuery NVARCHAR(MAX)= "
declare @entityModels_internal table (
	InsertOrder int identity (1, 1) primary key,
	Id int index ixEntityModels_internal_Id,
	Model nvarchar(max)
);

insert into @entityModels_internal (Id, Model)
select em.[Key], em.[Value]
from @entityModels em;

declare @queryString nvarchar(max) = 
'Declare @config stringpair
insert into @config
(String1,String2)
values
(''BlockItemTable'',''ProgramSequence'');

exec dbo.upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @config = @config;'
;

declare @serializedParameters nvarchar(max) = (
	select
		emi.Id as [id], json_query(p.Parameters) as [parameters]
	from @entityModels_internal emi
	cross apply (
		select
			concat(
				'[',
					dbo.fnGenerateBulkResolveQueryParameter('@entityId', emi.Id, 'int'),
				']'
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
	ParamsParseSuccess bit '$.paramsParseSuccess',
	EntityResultSets nvarchar(max) '$.entityResultSets' as json,
	StatusMessages nvarchar(max) '$.statusMessages' as json
) srr
--srr = serialized results root
outer apply (
	select *
	from openjson(srr.EntityResultSets)
	with (
		Id int '$.id',
		SortOrder int '$.sortOrder',
		QuerySuccess bit '$.querySuccess',
		ResultSets nvarchar(max) '$.resultSets' as json
	) ent
) ers
outer apply (
	select *
	from openjson(ers.ResultSets)
	with (
		ResultSetNumber int '$.resultSetNumber',
		Results nvarchar(max) '$.results' as json
	)
) rs
outer apply (
	select *
	from openjson(rs.Results)
	with (
		SerializedResult nvarchar(max) '$.serializedResult' as json,
		StatusMessages nvarchar(max) '$.statusMessages' as json
	)
) res
outer apply (
	select *
	from openjson(res.SerializedResult)
	with (
		[Value] int '$.Value',
		[Text] nvarchar(max) '$.Text'
	)
) dres;

select
	emi.Id as [Value], fr.RenderedText as [Text]
from @entityModels_internal emi
left outer join @flattenedResults fr on (fr.ResultSetNumber = 1 and emi.Id = fr.Id)
order by emi.InsertOrder;
"

DECLARE @SumQuery NVARCHAR (MAX) = "
declare @entityModels_internal table (
	InsertOrder int identity (1, 1) primary key,
	Id int index ixEntityModels_internal_Id,
	Model nvarchar(max)
);

insert into @entityModels_internal (Id, Model)
select em.[Key], em.[Value]
from @entityModels em;


declare @entityId int = (select id from @entityModels_internal)

--#region program outcomes output
declare @blockWrapperTag nvarchar(10) = 'div';
declare @headerTag nvarchar(10) = 'div';
declare @listWrapperTag nvarchar(10) = 'ol';
declare @listItemTag nvarchar(10) = 'li';
declare @dataElementTag nvarchar(10) = 'span';
declare @boldDataElementTag nvarchar(10) = 'b';
declare @classAttribute nvarchar(10) = 'class';
declare @space nvarchar(5) = ' ';
declare @templateId int = (select MetaTemplateId from Program where Id = @entityId);
declare @composedOutcomes table (
	SortOrder int identity (1, 1),
	ComposedOutcome nvarchar(max)
);
insert into @composedOutcomes (ComposedOutcome)
select
	concat(
		'<li class = ""program-outcomes-list-items""style =""list-style: none"">',
			--Some clients (e.g. SAC, Imperial) use Outcome, others use OutcomeText
			coalesce(po.Outcome, po.OutcomeText),
		'</li>'
	) as ComposedOutcome
from ProgramOutcome po
where po.ProgramId = @entityId
and po.Active = 1
order by po.SortOrder, po.Id;
declare @outcomesCount int = (select count(*) from @composedOutcomes);
declare @combinedOutcomes nvarchar(max) = (
	select
		dbo.ConcatWithSepOrdered_Agg(null, co.SortOrder, co.ComposedOutcome)
	from @composedOutcomes co
);
declare @fullOutcomesBlock nvarchar(max) = (
	select
		case when @outcomesCount > 0 then
			concat(
				dbo.fnHtmlOpenTag(@blockWrapperTag, dbo.fnHtmlAttribute(@classAttribute, 'program-outcomes-summary-wrap')),
					dbo.fnHtmlOpenTag(@headerTag, dbo.fnHtmlAttribute(@classAttribute, 'program-outcomes-summary-head')),
						dbo.fnHtmlOpenTag(@boldDataElementTag, dbo.fnHtmlAttribute(@classAttribute, 'program-outcomes-summary-header-wrap')),
							'Learning Outcome(s):',
						dbo.fnHtmlCloseTag(@boldDataElementTag),
						dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttribute, 'program-outcomes-summary-header-placeholder')),
						dbo.fnHtmlCloseTag(@dataElementTag),
					dbo.fnHtmlCloseTag(@headerTag),
					dbo.fnHtmlOpenTag(@blockWrapperTag, dbo.fnHtmlAttribute(@classAttribute, 'program-outcomes-list-wrap')),
						'<ul Class = ""program-outcomes-list"" style =""list-style: none"">',
							@combinedOutcomes,
						'</ul>',
					dbo.fnHtmlCloseTag(@blockWrapperTag),
				dbo.fnHtmlCloseTag(@blockWrapperTag)
			)
		else null end as ComposedOutcomes
);
--#endregion program outcomes output
declare @fieldUsage table (
	TableName sysname,
	ColumnName sysname,
	index ixFieldUsage_TableColumn clustered (TableName, ColumnName)
);
insert into @fieldUsage (TableName, ColumnName)
select 
	maf.TableName, 
	maf.ColumnName
from Program p
inner join MetaTemplate mt on p.MetaTemplateId = mt.MetaTemplateId
inner join MetaSelectedSection mss on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedField msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
where p.Id = @entityId;
declare @summaryFields table(
	Faculty nvarchar(max),
	ProgramHeader nvarchar(max),
	Description nvarchar(max),
	FacultyAdvisors nvarchar(max),
	EmeritiFaculty nvarchar(max),
	Associations nvarchar(max),
	AffiliatedFaculty nvarchar(max),
	ProgramOutcomes nvarchar(max)
);
insert into @summaryFields(Faculty, ProgramHeader, [Description], FacultyAdvisors, EmeritiFaculty, Associations, AffiliatedFaculty, ProgramOutcomes)
select
	case 
		when exists (select top 1 1 from @fieldUsage u where u.TableName = 'GenericMaxText' and u.ColumnName = 'TextMax09')
			then gmt.TextMax09 
		else ''
	end as Faculty,
	case 
		when exists (select top 1 1 from @fieldUsage u where u.TableName = 'Program' and u.ColumnName = 'AdministrationPlan')
			then p.AdministrationPlan 
		else ''
	end as ProgramHeader,
	case 
		when exists (select top 1 1 from @fieldUsage u where u.TableName = 'Program' and u.ColumnName = 'Description')
			then p.Description 
		else ''
	end as Description, 
	case 
		when exists (select top 1 1 from @fieldUsage u where u.TableName = 'Program' and u.ColumnName = 'AdvisoryCommitteeMemberList')
			then p.AdvisoryCommitteeMemberList 
		else ''
	end as FacultyAdvisors, 
	case 
		when exists (select top 1 1 from @fieldUsage u where u.TableName = 'ProgramDescription' and u.ColumnName = 'FacultyMembers')
			then pd.FacultyMembers 
		else ''
	end as EmeritiFaculty,
	case 
		when exists (select top 1 1 from @fieldUsage u where u.TableName = 'Program' and u.ColumnName = 'Associations')
			then p.Associations 
		else ''
	end as Associations,
	case 
		when exists (select top 1 1 from @fieldUsage u where u.TableName = 'ProgramFaculty' and u.ColumnName = 'FacultyQual')
			then pf.FacultyQual 
		else ''
	end as AffiliatedFaculty,
	@fullOutcomesBlock as ProgramOutcomes
from Program p
left outer join GenericMaxText gmt on p.Id = gmt.ProgramId
left outer join ProgramDescription as pd on p.Id = pd.ProgramId 
left outer join ProgramFaculty as pf on p.Id = pf.ProgramId 
where p.Id = @entityId;
select 
	@entityId as Value,
	concat(
		dbo.fnHtmlOpenTag(@blockWrapperTag, concat(
			dbo.fnHtmlAttribute(@classAttribute, 'program-summary-wrapper'), @space,
			dbo.fnHtmlAttribute('data-entity-id', @entityId)
		)),
			sf.ProgramHeader, sf.[Description], sf.Associations, sf.Faculty, sf.EmeritiFaculty,
			sf.AffiliatedFaculty, sf.FacultyAdvisors, sf.ProgramOutcomes,
		dbo.fnHtmlCloseTag(@blockWrapperTag)
	) as [Text]
from @summaryFields sf;
"

SET QUOTED_IDENTIFIER ON

INSERT INTO OutputTemplateClient
(TemplateQuery, Title, Description, StartDate)
VALUES
(@TempQuery, 'Custom Program Requirement Template', 'Custom Program Requirement Template', GETDATE())

DECLARE @Temp int = SCOPE_IDENTITY()

INSERT INTO OutputTemplateClient
(TemplateQuery, Title, Description, StartDate)
VALUES
(@SumQuery, 'Custom Program Summary Template', 'Custom Program Summary Template', GETDATE())

DECLARE @Temp2 int = SCOPE_IDENTITY()

INSERT INTO OutputTemplateModelMappingClient
(OutputTemplateBaseId, OutputTemplateClientId, OutputModelBaseId, OutputModelClientId, Title, Description)
VALUES
(NULL, @Temp, 2, NULL, 'Program Requirements', 'Custom program requirements model and template mapping')

DECLARE @map int = scope_identity()

INSERT INTO OutputTemplateModelMappingClient
(OutputTemplateBaseId, OutputTemplateClientId, OutputModelBaseId, OutputModelClientId, Title, Description)
VALUES
(NULL, @Temp2, 2, NULL, 'Program Summary', 'Custom program summary model and template mapping')

DECLARE @map2 int = scope_identity()

UPDATE CurriculumPresentationOutputFormat
SET OutputTemplateModelMappingBaseId = NULL
, OutputTemplateModelMappingClientId = @map
WHERE Id in (3, 4)

UPDATE CurriculumPresentationOutputFormat
SET OutputTemplateModelMappingBaseId = NULL
, OutputTemplateModelMappingClientId = @map2
WHERE Id in (5, 6)