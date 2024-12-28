USE [fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18379';
DECLARE @Comments nvarchar(Max) = 
	'Update Query and the courses it pulls in on the Assessments';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
		declare @courseId int = (
			select md.Active_CourseId
			from ModuleDetail md
			where md.Id = @entityId
		);

		with CourseFamily ([Value], [Text], StartDate, SortOrder, [Status], filterColumn) 
		as (
			select  c.Id as [Value]
				, coalesce(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title) as [Text]
				, coalesce(p.ImplementDate, c.CreatedOn) as StartDate
				, row_number() over (order by coalesce(p.ImplementDate, c.CreatedOn), c.Id) as RowNumber
				, sa.StatusBaseId as [Status]
				, c.BaseCourseId as FilterValue
			from Course c 
				inner join [Subject] s on c.SubjectId = s.Id
				inner join Course c2 on c.BaseCourseId = c2.BaseCourseId 
				inner join StatusAlias sa on c.StatusAliasId = sa.Id 
				left join Proposal p on c.ProposalId = p.Id 
			where c2.Id = @courseId
			and c.Active = 1 
			and sa.StatusBaseId in (
				1--Active
				, 5--Historical
				, 6--In Review
			)
			and exists (
				select 1
				from CourseOutcome co
				where co.CourseId = c.Id
			)
		) 
		select TOP 2 cf.[Value]
			, cf.[Text] + '' ('' + 
				case 
					when cf.[Status] != 6--In Review
					then
						case cf.SortOrder 
							when 1
								then ''Existing'' 
							else convert(varchar(10), cf.StartDate, 101) 
						end + '' - '' + 
						case cf.[Status]
							when 1
								then '' Current''
							else convert(varchar(10), cf2.StartDate, 101)
						end
					else ''In Review''
				end
				+ '')'' as [Text]
				, @courseId as FilterValue
		from CourseFamily cf 
			left join CourseFamily cf2 on (cf.SortOrder + 1) = cf2.SortOrder
		order by cf.SortOrder desc
'
WHERE Id = 218

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 218