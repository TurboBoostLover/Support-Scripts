USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18040';
DECLARE @Comments nvarchar(Max) = 
	'Update Order of query in the course drop down in the blocks';
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
select c.Id as Value,
		coalesce(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title, s.SubjectCode + '' '' + c.CourseNumber, c.Title) + 
		case
			when sa.StatusBaseId != 1 then '' ('' + sa.Title + '')'' 
			when sa.StatusBaseID = 1 then ''''
		end as Text,
		s.Id as FilterValue,
		case when CA.DistrictCourseTypeid = 2 then 1
		else 0 end as IsVariable,
		case when CA.DesignationId = 2 
			then cd.MinCreditHour/2 
			else cd.MinCreditHour end as Min,
		case when CA.DesignationId = 2
			then cd.MinCreditHour/2
			else cd.MaxCreditHour end as Max
from Course c
	inner join CourseDescription cd on c.Id = cd.CourseId
	inner join CourseAttribute CA on CA.CourseId = c.id
	inner join Subject s on c.SubjectId = s.Id
	inner join StatusAlias sa on c.StatusAliasId = sa.Id
	INNER JOIN CourseDetail AS cd2 on cd.CourseId = cd2.Id
	INNER JOIN SubDivisionCategory AS sd on cd2.SubDivisionCategoryId = sd.Id
	INNER JOIN DisciplineType AS dt on dt.Id = c.DisciplineTypeId
	INNER JOIN ConsentOption As co on c.ConsentOptionId = co.Id
where (
	(
		c.Active = 1
		and sa.StatusBaseId in (1, 2, 4, 6)
	)
	--or exists (
	--	select 1
	--	from ProgramCourse pc
	--		inner join CourseOption co on pc.CourseOptionId = co.Id
	--	where co.ProgramId = @entityId
	--	and pc.CourseId = c.Id
	--)
)
order by sd.Title, c.Title, dt.Code, co.Code, c.CurriculumNumber
'
WHERE Id = 122

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 122
)