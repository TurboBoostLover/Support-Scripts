USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14358';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Summary in catalog';
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
UPDATE OutputModelClient 
SET ModelQuery = '
declare @entityList_internal table (
	InsertOrder int identity(1, 1) primary key,
	ProgramId int
);

insert into @entityList_internal (ProgramId)
select el.Id
from @entityList el;

declare @entityRootData table
(
	ProgramId int primary key,
	CatalogDescription nvarchar(max),
	PLO nvarchar(max),
	car nvarchar(max)
)

insert into @entityRootData 
select p.Id
, p.[Description] as Description
, plo.Text
, p.CareerOption
from Program p
	inner join @entityList_internal eli on p.Id = eli.ProgramId
CROSS APPLY
(
	SELECT dbo.ConcatOrdered_Agg(SortOrder, concat(''<li>'',outcome,''</li>''),1) AS Text
	FROM ProgramOutcome
	WHERE programId = p.id
) PLO


select
	 eli.ProgramId as Id
   , m.Model
from @entityList_internal eli
	cross apply (
		select (
			select erd.CatalogDescription
			,PLO
			,erd.car
			from @entityRootData erd
			where erd.ProgramId = eli.ProgramId
			for json path, without_array_wrapper
		) RootData
	) erd
	cross apply (
		select (
			select eli.InsertOrder
			, json_query(erd.RootData) as RootData
			for json path
		) Model
	) m
;
'
WHERE Id = 7

UPDATE OutputTemplateClient
SET TemplateQuery = '
--#region query

declare @modelRoot table (
	ProgramId int primary key,
	InsertOrder int,
	RootData nvarchar(max)
);

insert into @modelRoot 
(ProgramId, InsertOrder, RootData)
select
	  em.[Key]
	, m.InsertOrder
	, m.RootData
from @entityModels em
	cross apply openjson(em.[Value])
	with (
		InsertOrder int ''$.InsertOrder'',
		RootData nvarchar(max) ''$.RootData'' as json
	) m
;

declare 
	  @blockWrapperTag nvarchar(10) = ''div''
	, @listWrapperTag nvarchar(10) = ''ol''
	, @idiomaticTextTag nvarchar(10) = ''i''
	, @listItemTag nvarchar(10) = ''li''
	, @dataElementTag nvarchar(10) = ''span''
	, @boldDataElementTag nvarchar(10) = ''b''
	, @classAttribute nvarchar(10) = ''class''
	, @headerTag nvarchar(10) = ''header''
	, @headerLevel2Tag nvarchar(10) = ''h2''
	, @headerLevel3Tag nvarchar(10) = ''h3''
	, @headerLevel4Tag nvarchar(10) = ''h4''
	, @headerLevel5Tag nvarchar(10) = ''h5''
	, @space nvarchar(5) = '' ''
	, @styleAttribute nvarchar(5) = ''style''
;

declare @modelRootData table
(
	ProgramId int primary key,
	CatalogDescription nvarchar(max),
	PLO nvarchar(max),
	car nvarchar(max)
);

insert into @modelRootData (ProgramId, CatalogDescription, PLO, car)
select emi.ProgramId
, m.CatalogDescription
,m.PLO
,m.car
from @modelRoot emi
	cross apply openjson(emi.RootData)
		with (
			CatalogDescription nvarchar(max) ''$.CatalogDescription'',
			PLO NVARCHAR(MAX) ''$.PLO'',
			car NVARCHAR(MAX) ''$.car''
		) m
;


select
	mr.ProgramId as [Value],
	concat(
		-- program-summary-wrapper
		dbo.fnHtmlOpenTag(@blockWrapperTag, concat(
				dbo.fnHtmlAttribute(@classAttribute, ''program-summary-wrapper''), @space,
				dbo.fnHtmlAttribute(''data-entity-id'', mr.ProgramId)
			)
		),
			dbo.fnHtmlOpenTag(@blockWrapperTag, dbo.fnHtmlAttribute(@classAttribute, ''program-description-wrapper'')),
				-- description tag
				case
					when LEN(mrd.CatalogDescription) > 0 then concat(
							dbo.fnHtmlOpenTag(@blockWrapperTag, concat(dbo.fnHtmlAttribute(@classAttribute, ''program-description''), @space, dbo.fnHtmlAttribute(@styleAttribute, ''margin-top: 10px;''))),
								mrd.CatalogDescription,
							dbo.fnHtmlCloseTag(@blockWrapperTag)
						)
					else concat(dbo.fnHtmlOpenTag(@idiomaticTextTag, null), ''No description.'', dbo.fnHtmlCloseTag(@idiomaticTextTag))
				end,
				--PLO Header
                case
                    when LEN(mrd.PLO) > 0 then concat(
                        dbo.fnHtmlOpenTag(@headerTag, concat(dbo.fnHtmlAttribute(@classAttribute, ''program-Outcome-header''), @space)),
                                dbo.fnHtmlOpenTag(@boldDataElementTag, concat(dbo.fnHtmlAttribute(@classAttribute, ''program-outcome-header-title''), @space, dbo.fnHtmlAttribute(@styleAttribute, ''margin-bottom: 3px;''))),
                                ''Learning Outcome(s)'',
                                dbo.fnHtmlCloseTag(@boldDataElementTag),
                        dbo.fnHtmlCloseTag(@headerTag)
                    )
                end,
				--PLO TAG
				case
					when LEN(mrd.PLO) > 0 then concat(
							dbo.fnHtmlOpenTag(@blockWrapperTag, concat(dbo.fnHtmlAttribute(@classAttribute, ''program-description''), @space)),
								concat(''<ol>'',mrd.PLO,''</ol>''),
							dbo.fnHtmlCloseTag(@blockWrapperTag)
						)
				end,
				--career Header
                case
                    when LEN(mrd.car) > 0 then concat(
                        dbo.fnHtmlOpenTag(@headerTag, concat(dbo.fnHtmlAttribute(@classAttribute, ''program-career-header''), @space)),
                                dbo.fnHtmlOpenTag(@boldDataElementTag, concat(dbo.fnHtmlAttribute(@classAttribute, ''program-career-header-title''), @space, dbo.fnHtmlAttribute(@styleAttribute, ''margin-bottom: 3px;''))),
                                ''Career Opportunities'',
                                dbo.fnHtmlCloseTag(@boldDataElementTag),
                        dbo.fnHtmlCloseTag(@headerTag)
                    )
                end,
				--career
				case
					when LEN(mrd.car) > 0 then concat(
							dbo.fnHtmlOpenTag(@blockWrapperTag, concat(dbo.fnHtmlAttribute(@classAttribute, ''program-career''), @space, dbo.fnHtmlAttribute(@styleAttribute, ''margin-top: 10px;''))),
								mrd.car,
							dbo.fnHtmlCloseTag(@blockWrapperTag)
						)
					else concat(dbo.fnHtmlOpenTag(@idiomaticTextTag, null), ''No Career Opportunities entered.'', dbo.fnHtmlCloseTag(@idiomaticTextTag))
				end,
			dbo.fnHtmlCloseTag(@blockWrapperTag),
		dbo.fnHtmlCloseTag(@blockWrapperTag)
	) as [Text]
from @modelRoot mr
	inner join @modelRootData mrd on mr.ProgramId = mrd.ProgramId
order by mr.InsertOrder;

--#endregion query
'
WHERE Id = 8