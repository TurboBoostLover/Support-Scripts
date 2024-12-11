USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17539';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Impact Report';
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
DECLARE @SQL NVARCHAR(MAX) = '
		-- EffectiveTerm <= 5 Years
		declare @startTerm DATETIME, @endDate DATETIME

		SELECT TOP 1 @startTerm = TermStartDate
		FROM Semester s
			INNER JOIN CourseProposal cp ON cp.SemesterId = s.Id
		WHERE cp.CourseId = @entityId

		select @endDate = TermStartDate
		from Semester
		where Code = (select Code - 75
						from Semester
						where TermStartDate = @startTerm and Active = 1)
			and Active = 1
			
		declare @outputHeader nvarchar(max);
		
		--#Start of output header
		select @outputHeader = (
			select 
				concat(
					''<div style="text-align: center; font-weight: bold; margin-bottom: 15px;">''
						, s.SubjectCode
						, '' ''
						, c.CourseNumber
						, '' - ''
						, c.Title
						, ''<br />**''
						, pt.Title
						, ''**<br />''
						, cli.Title
					, ''</div>''
				) as RenderedHeader
			from Course c
				inner join [Subject] s on c.SubjectId = s.Id
				inner join Client cli on c.ClientId = cli.Id
				inner join ProposalType pt on c.ProposalTypeId = pt.Id
			where c.Id = @entityId
		);
		--#End of output header

		--#Start of courses that have current course as a requisite
		declare @courseFamily as table (
			Id int null
		);

		insert into @courseFamily (Id)
		select c.Id
		from Course c
		where c.Id = @entityId
		union
		select bc.ActiveCourseId
		from Course c
			inner join BaseCourse bc on c.BaseCourseId = bc.Id
		where c.Id = @entityId
		and bc.ActiveCourseId is not null;
			
		declare @requisites table (
			CourseId int
			, CourseTitle nvarchar(max)
			, CourseStatus nvarchar(max)
			, RequisiteType nvarchar(max)
		);

		insert into @requisites (CourseId, CourseTitle, CourseStatus, RequisiteType)
		select distinct
			c.Id
			, coalesce(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title + '' *'' + sa.Title + ''*'') as CourseTitle
			, sa.Title as CourseStatus
			, rt.Title as RequisiteType
		from Course c
			inner join StatusAlias sa on c.StatusAliasId = sa.Id
			inner join [Subject] s on c.SubjectId = s.Id
			inner join CourseRequisite cr on c.Id = cr.CourseId
			inner join RequisiteType rt on cr.RequisiteTypeId = rt.Id
			inner join Client cl on c.ClientId = cl.Id
		where sa.StatusBaseId in (1, 2, 4, 6) /* 1 = Active; 2 = Approved; 4 = Draft; 6 = In Review; */
		and c.DeletedDate is null
		and exists (
			select 1 
			from @courseFamily cf
			where cf.Id = cr.Requisite_CourseId
		)
		order by CourseTitle, CourseStatus;

		declare @outputRequisites nvarchar(max) = (
			select 
				dbo.ConcatWithSep_Agg(''''
					, dbo.fnHtmlElement(''li''
						, concat(
							dbo.fnHtmlElement(''b'', r.RequisiteType, null)
							, space(1)
							, r.CourseTitle
							, space(1)
							, ''*''
							, r.CourseStatus
							, ''*''
						)
					, null)
				)
			from @requisites r
		);
		--#End of courses that have current course as a requisite
		
		--#Start of programs that have the current course as a program course
		declare @courseFamily2 as table (
			Id int
		);
			
		insert into @courseFamily2 (Id)
		select Id
		from Course
		where BaseCourseId in (select BaseCourseId from Course where Id = @entityId)

		declare @programs table (
			ProgramId int
			, ProgramStatus nvarchar(max)
			, ProgramAwardType nvarchar(max)
			, ProgramTitle nvarchar(max)
			, ProposalType nvarchar(max)
			, ProgramCode nvarchar(max)
			, SortOrder int
			, effectiveTerm nvarchar(max)
			, StartDate Datetime
		);
		
		insert into @programs (ProgramId, ProgramStatus, ProgramAwardType, ProgramTitle, ProposalType, ProgramCode, SortOrder, effectiveTerm, StartDate)
		select distinct 
			p.Id
			, sa.Title
			, awt.Title
			, p.Title
			, pt.Title
			, p.Associations
--			, row_number() over (order by oeDiv.Title, awt.Title, sa.Title, p.Title) as SortOrder
			, row_number() over (order by p.Associations asc, s.Code desc) as SortOrder
			, s.Code
			, s.StartDate
		from Program p
			inner join StatusAlias sa on p.StatusAliasId = sa.Id
			inner join ProposalType pt on p.ProposalTypeId = pt.Id
			left join AwardType awt on p.AwardTypeId = awt.Id
			left join OrganizationEntity oeDiv on p.Tier1_OrganizationEntityId = oeDiv.Id
			inner join ProgramProposal pp on pp.ProgramId = p.Id
			inner join Semester s on s.Id = pp.SemesterId
		where p.Active = 1
			and sa.StatusBaseId in (1, 2, 4, 5, 6) /* 1 = Active; 2 = Approved; 4 = Draft; 5 = Historical;6 = In Review; */
			and exists (
				select 1
				from CourseOption co
					inner join ProgramCourse pc on co.Id = pc.CourseOptionId
					inner join @courseFamily2 cf on pc.CourseId = cf.Id
				where co.ProgramId = p.Id
			)
			--and s.Id in (
			--	SELECT Id
			--	FROM Semester 
			--	WHERE TermStartDate BETWEEN @endDate AND @startTerm
			--		AND [Active] = 1
			--);
			
		declare @outputPrograms nvarchar(max) = (
			select 
				dbo.ConcatWithSepOrdered_Agg(''''
					, p.SortOrder
					, dbo.fnHtmlElement(''li''
						, concat(
							p.ProgramTitle
							, '' (''
							, p.ProgramCode
							, '') *<i>''
							, p.ProgramStatus
							, ''</i>* ''
							, ''(''
							, p.effectiveTerm
							, '')''
						)
					, null)
				)
			from @programs p
		);
		--#End of programs that have the current course as a program course
		
		select 0 as [Value]
			, concat(
				''<div>''
					, @outputHeader
					, ''<div style="text-align: center; font-weight: bold; font-size: 20px;">''
						, ''Course Requisites''
					, ''</div>''
					, case 
						when len(@outputRequisites) > 0
							then concat(
								dbo.fnHtmlElement(''i'', ''This course is a requisite for the following course(s):'', null)
								, dbo.fnHtmlElement(''ol'', @outputRequisites, null)
							)
						else ''This course is not being used as a requisite for any course''
					end
					, ''<div style="text-align: center; font-weight: bold; font-size: 20px;">''
						, ''Programs''
					, ''</div>''
					, case 
						when len(@outputPrograms) > 0
							then concat(
								dbo.fnHtmlElement(''i'', ''This course is incorporated into the following program(s):'', null)
								, dbo.fnHtmlElement(''ol'', @outputPrograms, null), ''</div>''
							)
						else ''This course is a stand-alone course and is not incorporated into any programs''
					end
			) as [Text]
		;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 138

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 138
)