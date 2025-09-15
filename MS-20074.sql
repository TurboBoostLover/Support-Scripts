USE [nukz];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-20074';
DECLARE @Comments nvarchar(Max) = 
	'Ensure Course it linked to Package correctly and it shows';
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
DECLARE @Id int = 3127

DECLARE @SQL NVARCHAR(MAX) = '
		declare @subjectId int = (
			select SubjectId
			from Package
			where Id = @entityId
		);

		select c.Id as [Value]
			, case
				when c.SubjectId <> @subjectId
					then
					''<span style="color: red";>''
						+ ''[{@{HyperLink}@, @{EntityEdit}@, @{Course}@, @{'' + convert(varchar(20), c.Id) + ''}@, @{''
						+ coalesce(s.SubjectCode,'''') 
						+ coalesce('' '' + c.CourseNumber,'''')
						+ coalesce('' - '' + c.Title, '''') + ''}@}] ''
						+ coalesce(''<div style="float:right; color:red">'' + convert(nvarchar(20),c.createdOn,101) + ''</div>'','''')
						+ coalesce(''<br />**'' + pt.Title + ''**'','''')
					+ '' This course needs to be removed from this package where this course subject in the selected course no longer matches the selected subject in this package!</span>''
				else 
				''[{@{HyperLink}@, @{EntityEdit}@, @{Course}@, @{'' + convert(varchar(20), c.Id) + ''}@, @{''
				+ coalesce(s.SubjectCode,'''') 
				+ coalesce('' '' + c.CourseNumber,'''')
				+ coalesce('' - '' + c.Title, '''') + ''}@}] ''
				+ coalesce(''<div style="float:right; color:red">'' + convert(nvarchar(20),c.createdOn,101) + ''</div>'','''')
				+ coalesce(''<br />**'' + pt.Title + ''**'','''')
			end as [Text]
		from [Course] c
			inner join [Subject] s on c.SubjectId = s.Id
			left join [ProposalType] pt on c.ProposalTypeId = pt.Id
			inner join [StatusAlias] sa on c.StatusAliasId = sa.Id
		where c.ClientId = @clientId
		and c.Active = 1
		and (c.SubjectId = @subjectId
			or exists (
				select 1
				from PackageCourse pc
				where c.Id = pc.CourseId
				and pc.PackageId = @entityId
			)
		)
		and (
			--the course is already in the package
			--c.Id in (
			--	select pc.CourseId 
			--	from PackageCourse pc 
			--	where pc.PackageId = @entityId
			--)
			--or (
				sa.StatusBaseId = 4
					or exists (
				select 1
				from PackageCourse pc
				where c.Id = pc.CourseId
				and pc.PackageId = @entityId
				)
				 --draft status
				--the item is not already in another package
				and c.Id not in (
					select pc.CourseId 
					from PackageCourse pc
					where pc.PackageId != @entityId
				)
				--the item is not in a crosslisting
				and c.Id not in (
					select clc.CourseId 
					from [CrosslistingCourse] clc 
					where clc.Active = 1
				)
				--the items parent is not active in a crosslisting
				and c.PreviousId not in (
					select clc.CourseId 
					from [CrosslistingCourse] clc 
					where clc.Active = 1
				)
			--)
		)
		order by s.SubjectCode, c.CourseNumber;
	
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id