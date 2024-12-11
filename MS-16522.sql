USE [riohondo];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16522';
DECLARE @Comments nvarchar(Max) = 
	'Update config for catalog to pull in only active courses';
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
			(1, 5),
			-- Approved catalog
			(2, 1),
			--(2, 2),
			--(2, 4),
			(2, 5),
			--(2, 6),
			-- Draft catalog
			(4, 1),
			--(4, 2),
			--(4, 4),
			(4, 5),
			--(4, 6),
			-- Historical catalog
			(5, 1),
			--(5, 2),
			(5, 5),
			-- In Review catalog
			(6, 1),
			--(6, 2),
			--(6, 4),
			(6, 5),
			--(6, 6),
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