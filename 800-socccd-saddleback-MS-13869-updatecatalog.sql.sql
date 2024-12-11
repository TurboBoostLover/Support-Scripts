use socccd;

/*
Commit
						Rollback
*/

----------------------------------------------------------------------_----------------------------------------------------------------------
declare @JiraTicketNumber nvarchar(20) = 'MS-13869';
declare @Comments nvarchar(max) = 'Update Config to not inlcude approved courses in the active catalog';
declare @Developer nvarchar(50) = 'Nathan W';
declare @ScriptTypeId int = 1;
/*  
Default for @ScriptTypeId on this script is 1 for Support, for a complete list run the following query.
@ScriptTypeId above should = 2 when for enhancement.

select * from History.ScriptType;
*/
select @@servername as 'Server Name'
	, db_name() as 'Database Name'
	, @JiraTicketNumber as 'Jira Ticket Number'
;

set xact_abort on;
begin tran;

insert into History.ScriptsRunOnDatabase (TicketNumber, Developer, Comments, ScriptTypeId)
values (@JiraTicketNumber, @Developer, @Comments, @ScriptTypeId);
----------------------------------------------------------------------_----------------------------------------------------------------------

--select Id, Title, Code, Active from Client;
--2	Saddleback College

--update Course
--set Title = concat(Id, ' ', Title)
--where Id is not null;

--select c2.Id, c2.EntityTitle, s.Title, sa.title, s.TermStartDate, s.TermEndDate, c2.CreatedOn, prop.ImplementDate, c2.Active
--from course c
--	join course c2 on c.BaseCourseId = c2.BaseCourseId
--	join statusalias sa on c2.StatusAliasId = sa.Id
--	join CourseProposal cp on cp.CourseId = c2.Id 
--	join Semester s on s.Id = cp.SemesterId
--	join Proposal prop on c.ProposalId = prop.Id
----where c.Id = 26138--ART 143
--where c.Id = 26420--HSC 291
----where c.Id = 24236--KOR 901
----where c.Id = 24237--KOR 902
----where c.Id = 24240--KOR 903
----where c.Id = 24239--KOR 904
----where c.Id = 24696--ENG 332A
--order by c2.CreatedOn;

--select * from Semester where ClientId = 2 order by TermStartDate, Title;
--select * from CurriculumPresentation where ClientId = 2;
--select * from CurriculumPresentationOutputFormat where CurriculumPresentationId = 1;
--select * from OutputTemplateModelMappingClient where Id = 3;
--select * from OutputTemplateClient where Id = 3;
--select * from OutputModelClient where id = 1;
--select * from StatusBase;
--select * from StatusAlias;

--declare variables
	--declare @clientId int = (select Id from Client where Active = 1);
	--declare @sql nvarchar(max);

--Add config for catalog status to course status on what is allowed to display in catalog.
	declare @serializedStatusBaseMapping nvarchar(max);
 
	select @serializedStatusBaseMapping = (
		select
			vals.Catalog_StatusBaseId as [catalogStatusBaseId],
			vals.Entity_StatusBaseId as [entityStatusBaseId]
		from (
			values
			-- Active catalog
			(1, 1),
			--(1, 2),
			--(1, 5),
			-- Approved catalog
			(2, 1),
			(2, 2),
			--(2, 4),
			--(2, 5),
			--(2, 6),
			-- Draft catalog
			(4, 1),
			(4, 2),
			(4, 4),
			--(4, 5),
			(4, 6),
			-- Historical catalog
			(5, 1),
			(5, 2),
			(5, 5),
			-- In Review catalog
			(6, 1),
			(6, 2),
			(6, 4),
			(6, 5),
			(6, 6),
			-- Rejected catalog
			(7, 1),
			(7, 2),
			(7, 4),
			(7, 5),
			(7, 6)
		) vals (Catalog_StatusBaseId, Entity_StatusBaseId)
		for json path
	);
 
	update cp
	set cp.Config = json_modify(isnull(cp.Config, '{}'), '$.statusBaseMapping', json_query(@serializedStatusBaseMapping))
	--output inserted.Id, inserted.Title, inserted.Config
	from CurriculumPresentation cp
	where cp.Id = 1;

--update meta template last updated date to current date
	--update MetaTemplate
	--set LastUpdatedDate = getDate()
	--where MetaTemplateId in ();

--commit;
--rollback;