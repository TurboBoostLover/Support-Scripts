USE [madera];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18911';
DECLARE @Comments nvarchar(Max) = 
	'Course & Program Templates - CORRECTIONS';
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
UPDATE CourseCBCode
SET CB27Id = 2
WHERE CB27Id = 1

DECLARE @Id int = 131

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @TABLE TABLE (Value int, Text NVARCHAR(MAX))
INSERT INTO @TABLE
EXEC upGenerateCBCustomSQL @CBCode = ''CB27'', @entityId = @entityId

SELECT * FROM @TABLE ORDER BY Value DESC
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
WHERE Id= @Id

UPDATE CourseDescription
SET ShortTermWeek = 18
WHERE 1 = 1 

DECLARE @UnitsMin TABLE (CourseId int, val decimal(16,3))
INSERT INTO @UnitsMin
SELECT 
    c.Id AS CourseId,
    CASE 
        WHEN COALESCE(cd.MinUnitHour, 0) > 0 THEN COALESCE(cd.MinUnitHour, 0)
        WHEN COALESCE(cb.Cb04Id, 0) = 3 THEN 0
        ELSE 
            CASE 
                WHEN (
                    (COALESCE(cd.MinLectureHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                    + ((COALESCE(cd.MinLabHour, 0) + COALESCE(cd.MinFieldHour, 0)) * COALESCE(cd.ShortTermWeek, 0)) 
                    + (COALESCE(cd.MinClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                    + (COALESCE(cd.MinLectureHour, 0) * (COALESCE(cd.ShortTermWeek, 0) * 2)) 
                    + ((COALESCE(cd.MinClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) / 2)
                  ) / 54 < 0.5 
                THEN 
                    CAST(FLOOR((
                        (COALESCE(cd.MinLectureHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                        + ((COALESCE(cd.MinLabHour, 0) + COALESCE(cd.MinFieldHour, 0)) * COALESCE(cd.ShortTermWeek, 0)) 
                        + (COALESCE(cd.MinClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                        + (COALESCE(cd.MinLectureHour, 0) * (COALESCE(cd.ShortTermWeek, 0) * 2)) 
                        + ((COALESCE(cd.MinClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) / 2)
                      ) / 54 * 10) / 10 AS DECIMAL(10,1))
                ELSE 
                    CAST(FLOOR((
                        (COALESCE(cd.MinLectureHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                        + ((COALESCE(cd.MinLabHour, 0) + COALESCE(cd.MinFieldHour, 0)) * COALESCE(cd.ShortTermWeek, 0)) 
                        + (COALESCE(cd.MinClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                        + (COALESCE(cd.MinLectureHour, 0) * (COALESCE(cd.ShortTermWeek, 0) * 2)) 
                        + ((COALESCE(cd.MinClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) / 2)
                      ) / 54 * 2) / 2 AS DECIMAL(10,1))
            END
    END AS CalculatedValue
FROM Course AS c
INNER JOIN CourseCbCode AS cb ON cb.CourseId = c.Id
INNER JOIN CourseDescription AS cd ON cd.CourseId = c.Id;

DECLARE @UnitsMax TABLE (CourseId int, val decimal(16,3))
INSERT INTO @UnitsMax
SELECT 
    c.Id AS CourseId,
    CASE 
        WHEN COALESCE(cd.MaxUnitHour, 0) > 0 THEN COALESCE(cd.MaxUnitHour, 0)
        WHEN COALESCE(cb.Cb04Id, 0) = 3 THEN 0
        ELSE 
            CASE 
                WHEN (
                    (COALESCE(cd.MaxLectureHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                    + ((COALESCE(cd.MaxLabHour, 0) + COALESCE(cd.MaxFieldHour, 0)) * COALESCE(cd.ShortTermWeek, 0)) 
                    + (COALESCE(cd.MaxClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                    + (COALESCE(cd.MaxLectureHour, 0) * (COALESCE(cd.ShortTermWeek, 0) * 2)) 
                    + ((COALESCE(cd.MaxClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) / 2)
                  ) / 54 < 0.5 
                THEN 
                    CAST(FLOOR((
                        (COALESCE(cd.MaxLectureHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                        + ((COALESCE(cd.MaxLabHour, 0) + COALESCE(cd.MaxFieldHour, 0)) * COALESCE(cd.ShortTermWeek, 0)) 
                        + (COALESCE(cd.MaxClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                        + (COALESCE(cd.MaxLectureHour, 0) * (COALESCE(cd.ShortTermWeek, 0) * 2)) 
                        + ((COALESCE(cd.MaxClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) / 2)
                      ) / 54 * 10) / 10 AS DECIMAL(10,1))
                ELSE 
                    CAST(FLOOR((
                        (COALESCE(cd.MaxLectureHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                        + ((COALESCE(cd.MaxLabHour, 0) + COALESCE(cd.MaxFieldHour, 0)) * COALESCE(cd.ShortTermWeek, 0)) 
                        + (COALESCE(cd.MaxClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) 
                        + (COALESCE(cd.MaxLectureHour, 0) * (COALESCE(cd.ShortTermWeek, 0) * 2)) 
                        + ((COALESCE(cd.MaxClinicalHour, 0) * COALESCE(cd.ShortTermWeek, 0)) / 2)
                      ) / 54 * 2) / 2 AS DECIMAL(10,1))
            END
    END AS CalculatedValue
FROM Course AS c
INNER JOIN CourseCbCode AS cb ON cb.CourseId = c.Id
INNER JOIN CourseDescription AS cd ON cd.CourseId = c.Id;

UPDATE cd
SET MinCreditHour = um.val
, MaxCreditHour = CASE WHEN cd.Variable = 1 THEN ua.val ELSE NULL END
FROM CourseDescription AS cd
INNER JOIN @UnitsMin as um on um.CourseId = cd.CourseId
INNER JOIN @UnitsMax AS ua on ua.CourseId = cd.CourseId
WHERE 1 = 1

-- ==================================
-- Calculation
-- ============================================
declare
	@programId int,
	@currentCount int = 1,
	@totalCount int = (select count(1) from Program);

drop table if exists #calculationResults;

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
where Active = 1;

open programCursor;

fetch next from programCursor
into @programId;

set xact_abort off;
while @@fetch_status = 0
begin;
	print 'Start ProgramId = ' + cast(@programId as nvarchar) + ' (' + cast(@currentCount as nvarchar) + ' of ' + cast(@totalCount as nvarchar) + ')';

	exec upCalculateNestedCourseBlockEntries @entityId = @programId, @resultTable = '#calculationResults';
	
	print 'Completed ProgramId = ' + cast(@programId as nvarchar) + ' (' + cast(@currentCount as nvarchar) + ' of ' + cast(@totalCount as nvarchar) + ')';

	set @currentCount = @currentCount + 1;

	fetch next from programCursor
	into @programId;
end;

close programCursor;
deallocate programCursor;

drop table if exists #calculationResults;

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
WHERE 1 = 1 --updating course and program data and that is all they have