USE [fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19877';
DECLARE @Comments nvarchar(Max) = 
	'Update broken course query in program requirements';
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
DECLARE @sql nvarchar(max) =
'select 
    c.Id as Value    
    ,EntityTitle + '' - '' + sa.Title  as Text         
    ,s.Id as FilterValue 
	,CASE WHEN cb.CB04Id = 3 
		THEN cd.MinLabLecHour
		ELSE cd.MinCreditHour
	END AS Min
	,CASE WHEN cb.CB04Id = 3
		THEN cd.MaxLabLecHour
		ELSE cd.MaxCreditHour
	END AS Max,
	cd.variable AS IsVariable
from Course c
    inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join Subject s on s.id = c.SubjectId
	INNER JOIN CourseDescription cd ON cd.CourseId = c.Id
	INNER JOIN CourseCbCode cb ON cb.CourseId = c.Id
where c.ClientId = @clientId 	
and c.Active = 1
and sa.StatusBaseId in (1,2,4,6)
UNION
select 
    c.Id as Value    
    ,EntityTitle + '' - '' + sa.Title  as Text         
    ,s.Id as FilterValue
	,CASE WHEN cb.CB04Id = 3 
		THEN cd.MinLabLecHour
	ELSE cd.MinCreditHour
	END AS Min
	,CASE WHEN cb.CB04Id = 3
		THEN cd.MaxLabLecHour
		ELSE cd.MaxCreditHour
	END AS Max,
	Coalesce(cd.variable, 0) AS IsVariable
from Course c
	inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join Subject s on s.id = c.SubjectId
	INNER JOIN CourseDescription cd ON cd.CourseId = c.Id
	INNER JOIN CourseCbCode cb ON cb.CourseId = c.Id
	INNER JOIN ProgramSequence pc on pc.CourseId = c.id and pc.ProgramId = @entityID
order by Text'

DECLARE @resolutionSQL nvarchar(max) = 
'select 
    c.Id as Value    
    ,EntityTitle + '' - '' + sa.Title  as Text         
    ,s.Id as FilterValue
	,CASE WHEN cb.CB04Id = 3 
		THEN cd.MinLabLecHour
	ELSE cd.MinCreditHour
	END AS Min
	,CASE WHEN cb.CB04Id = 3
		THEN cd.MaxLabLecHour
		ELSE cd.MaxCreditHour
	END AS Max,
	Coalesce(cd.variable, 0) AS IsVariable
from Course c
	inner join StatusAlias sa on sa.Id = c.StatusAliasId 
    inner join Subject s on s.id = c.SubjectId
	INNER JOIN CourseDescription cd ON cd.CourseId = c.Id
	INNER JOIN CourseCbCode cb ON cb.CourseId = c.Id
WHERE C.Id = @Id'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @sql,
	ResolutionSql = @resolutionSQL
WHERE Id = 76


SET @sql = 
'declare @config StringPair;
insert into @config (String1, String2)
values
(''BlockItemTable'', ''ProgramSequence'');

EXEC dbo.upGenerateGroupConditionsCourseBlockDisplay @entityId, @config = @config'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @sql,
	ResolutionSql = @sql
WHERE Id = 83

DECLARE @programId INT;

DROP Table IF Exists #calculationResults
create table #calculationResults
(
    TableName sysname,
    Id int,
    Min decimal(16, 3),
    Max decimal(16, 3),
    IsVariable bit
);
 
declare programCursor cursor fast_forward for
    select Id
from Program
WHERE PrimaryAreaOfInterestId > 13;
 
open programCursor;
 
fetch next from programCursor
    into @programId;
 
while @@fetch_status = 0
    begin;
    exec upCalculateNestedCourseBlockEntries @entityId = @programId, @resultTable = '#calculationResults';
 
    fetch next from programCursor
        into @programId;
end;
 
close programCursor;
deallocate programCursor;

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()