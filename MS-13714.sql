USE [idoe];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13714';
DECLARE @Comments nvarchar(Max) = 
	'Add admin report Course Not Attached to Program';
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
DECLARE @adminReportId INT;

UPDATE Config.ClientSetting
SET AllowActiveProgramReviewDatesReport = 0
WHERE Id = 4

SET QUOTED_IDENTIFIER OFF

DECLARE @SQL NVARCHAR(MAX) = "
DECLARE @ClientId int = 4

 Declare @DistrictClient int = coalesce((select PrincipalClientId from District),0);    Select Id,Title
    Into #ClientTable
    From Client
    Where 1=0;    IF @ClientId = @DistrictClient
        BEGIN;
            set IDENTITY_INSERT #ClientTable on
                Insert into #ClientTable (Id,Title)
                Select Id,Title 
                From Client 
                Where Id <> @DistrictClient
            set IDENTITY_INSERT #ClientTable OFF
        END;
    ELSE
        BEGIN;
            set IDENTITY_INSERT #ClientTable on;
                Insert into #ClientTable (Id,Title)
                Select Id,Title 
                From Client 
                Where Id = @ClientId;
            set IDENTITY_INSERT #ClientTable off;
        END;
    Select c.Id ,SubjectCode,CourseNumber,c.Title as CourseTitle,sa.Title as CourseStatus,'True' as OnlyInInactivePrograms,ct.title as Client, 1 as FirstOrder,'' as TotalStatus, '' as 'TotalCount'
    Into #CoursesInHistoricProgramsOnly
    from Course c
    inner join #ClientTable ct on c.ClientId = ct.Id 
    Inner join Subject s on s.Id = c.subjectId
    inner join StatusAlias sa on c.statusAliasId = sa.Id
        and sa.statusbaseId in (1,2)
    Where 
    Not exists (Select top 1 1 from ProgramCourse pc2 
                        inner join CourseOption co2 on co2.Id = pc2.CourseOptionId 
                        inner join Program p2 on p2.id = co2.ProgramId  
                        inner join StatusAlias sa2 on sa2.id = p2.statusaliasId 
                            and sa2.statusbaseId in (1,2)
                        Where pc2.CourseId = c.Id)
    And Exists(
    select top 1 cl.Title,c.Id,c. EntityTitle
    from ProgramCourse     pc
    inner join Course c1 on  c1.Id = pc.CourseId
    Inner Join StatusAlias sa on sa.id = c1.statusAliasId
        And sa.StatusbaseId in (1,2)
    inner join CourseOption co on co.Id = pc.CourseOptionId 
    inner join Program p on p.id = co.ProgramId 
    Inner join client cl on cl.id = p.clientId
    inner join StatusAlias sa1 on sa1.Id = p.StatusAliasId  
        And sa1 .StatusbaseId =5
    Where c.Id = c1.Id);    Select c.Id, s.subjectCode, c.CourseNumber, c.Title as CourseTitle,sa.Title as CourseStatus,'' as OnlyInInactivePrograms,ct.Title as Client,1 as FirstOrder,'' as TotalStatus, '' as 'TotalCount'
    into #CoursesNotInPrograms
    from Course c
    inner join #ClientTable ct on c.ClientId = ct.Id 
    inner join Subject s on s.Id = c.SubjectId
    inner join StatusAlias sa on sa.Id = c.StatusAliasId and sa.StatusBaseId in (1,2)
    where not exists (select 1 from ProgramCourse pc where pc.CourseId = c.Id);    ;With Courses as (
        select  subjectCode, CourseNumber, CourseTitle,CourseStatus,OnlyInInactivePrograms,Client,FirstOrder,TotalStatus, TotalCount
        from #CoursesNotInPrograms
        union all
        select  subjectCode, CourseNumber, CourseTitle,CourseStatus,OnlyInInactivePrograms,Client,FirstOrder,TotalStatus, TotalCount
        from #CoursesInHistoricProgramsOnly
        union all
        Select '' as subjectCode, '' as CourseNumber, '' as CourseTitle,'' as Status,'' as OnlyInInactivePrograms, Client,3 as FirstOrder, CourseStatus + ' courses not in a program' as TotalStatus,  Cast(count(CourseTitle)as Nvarchar(10)) as 'TotalCount'
        from #CoursesNotInPrograms
        Group by Client,CourseStatus
        Union ALL
        Select '' as subjectCode, '' as CourseNumber, '' as CourseTitle,'' as Status,'' as OnlyInInactivePrograms,Client,4 as FirstOrder, CourseStatus + ' courses in historic programs only' as TotalStatus,  Cast(count(CourseTitle)as Nvarchar(10)) as 'TotalCount'
        from #CoursesInHistoricProgramsOnly
        Group by Client,CourseStatus
    )
    select SubjectCode, CourseNumber, CourseTitle,CourseStatus as CourseStatus,OnlyInInactivePrograms as OnlyInHistoricPrograms,Client,TotalStatus, TotalCount
    From Courses
    Order by Client,FirstOrder,SubjectCode,CourseNumber,CourseStatus;    Drop table if exists #CoursesInHistoricProgramsOnly;
    Drop table if exists #CoursesNotInPrograms;
    Drop table if exists #ClientTable; 
"

SET QUOTED_IDENTIFIER ON

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Course Not Attached to Program', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 4)