USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19007';
DECLARE @Comments nvarchar(Max) = 
	'Update Courses in Programs to active version';
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
UPDATE AdminReport
SET ReportSQL = '
		select s.SubjectCode
			, c.CourseNumber
			, c.Id as CourseId
			, p.RenderedText as Program
			--, CASE WHEN c2.Id IS NULL THEN ''No New Version'' ELSE CAST(c2.Id AS NVARCHAR) END AS [New Course Id]
		from Course c
			inner join [Subject] s on c.SubjectId = s.Id
			INNER JOIN BaseCourse AS bc on c.BaseCourseId = bc.Id
			LEFT JOIN Course AS c2 on c2.BaseCourseId = bc.Id and c2.StatusAliasId = 1
			cross apply (
				select dbo.ConcatWithSepOrdered_Agg(char(10), p.SortOrder, p.OutputText) as RenderedText
				from (
					select concat(
							p.Title
							, '' (''
							, p.Id
							, '') --''
							, bt.Title
						) as OutputText
						, row_number() over (partition by pc.CourseId order by p.Title) as SortOrder
					from Program p
						inner join CourseOption co on p.Id = co.ProgramId
						inner join ProgramCourse pc on co.Id = pc.CourseOptionId
						left join BlockType bt on co.BlockTypeId = bt.Id
					where c.Id = pc.CourseId
					and p.StatusAliasId in (1,2)
				) p
			) p
		where c.StatusAliasId = 5--Historical
		and c.Active = 1
		and exists (
			select 1
			from ProgramCourse pc
				inner join CourseOption co on pc.CourseOptionId = co.Id
				inner join Program p on co.ProgramId = p.Id
			where c.Id = pc.CourseId
			and p.StatusAliasId in (
				1--Active
				, 2--Approved
			)
		)
		order by s.SubjectCode, c.CourseNumber;
		--MS-19007 will have update statement in ticket
'
WHERE Id = 13

DECLARE @Table TABLE (ProgramCourseId int, NewIds int)
INSERT INTO @Table
	select  pc.Id
		, c2.Id AS [New Course Id]
	from Course c
		inner join [Subject] s on c.SubjectId = s.Id
		INNER JOIN BaseCourse AS bc on c.BaseCourseId = bc.Id
		LEFT JOIN Course AS c2 on c2.BaseCourseId = bc.Id and c2.StatusAliasId = 1
		INNER JOIN ProgramCourse AS pc on pc.CourseId = c.Id
		INNER JOIN CourseOption AS co on pc.CourseOptionId = co.Id
		INNER JOIN Program As p on co.ProgramId = p.Id
		WHERE c.Active = 1
		and c.StatusAliasId = 5
		and p.Active = 1
		and p.StatusAliasId in (
			1--Active
			, 2--Approved
		)

UPDATE pc
SET CourseId = t.NewIds
FROM ProgramCourse AS pc
INNER JOIN @Table As t on pc.Id = t.ProgramCourseId
WHERE t.NewIds IS NOT NULL