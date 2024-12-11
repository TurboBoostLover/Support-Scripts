USE [butte];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16526';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Family Query Text';
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

declare @temp table (
	Id int identity(1,1)
	, [text] nvarchar(max)
);
declare @i int = 1;
declare @targetString nvarchar(max) = '''';
declare @consentOptionTitle nvarchar(max) = '''';

insert @temp
select (s.SubjectCode + '' '' + c.CourseNumber) as [Text]
from ConsentOption co
inner join Course c on co.Id = c.ConsentOptionId
inner join [Subject] s on c.SubjectId = s.Id
where co.Id = (
	select ConsentOptionId
	from Course
	where Id = @entityId
)
and c.Active = 1
and coalesce(StatusAliasId, 2) = 1 /* 1 = Active; 2 = Approved */
order by s.SubjectCode, dbo.fnCourseNumberToNumeric(c.CourseNumber), c.CourseNumber;
	
while @i <= (
	select count(*)
	from @temp
)
begin
	set @targetString += (
		case
			when @i < (
				select max(Id)
				from @temp
			) then (
					select [Text]
					from @temp
					where Id = @i
			) + '', ''
			when @i = (
				select max(Id)
				from @temp
			) then (
				select [Text]
				from @temp
				where Id = @i
			)
		end
	);
	set @i += 1;
end;

set @consentOptionTitle = (
	select co.Title
	from ConsentOption co
	inner join Course c on co.Id = c.ConsentOptionId
	where c.Id = @entityId
);

declare @renderedText nvarchar(max) = (
	case 
		when len(@targetString) > 0 then ''Course families are groups of active participatory courses that are related in content. This course is part of the '' + @consentOptionTitle + '' family ('' + @targetString + ''). Students are limited to no more than four attempts (grade or ''''W'''') within each family group. Individual course repeat restrictions still apply. Students receiving a satisfactory grade in an active participatory course may not enroll in that course again.''
		else ''''
	end
);

select @renderedText as [Text];

'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 226

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 226
)