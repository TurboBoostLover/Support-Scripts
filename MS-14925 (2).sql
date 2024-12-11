USE [nu];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14925';
DECLARE @Comments nvarchar(Max) = 
	'adhoc report of the impact report';
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
Drop Table if Exists #SeedIds
Create Table #SeedIds (row_num int,Id int)
;WITH x AS (SELECT n FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(n)),Numbers as(
SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL))  as Id
FROM x ones, x tens, x hundreds--, x thousands, x tenthousands, x hundredthousands
)	Merge #SeedIds as t
	Using (
	  select Id from Numbers
	  )
	As s 
	on 1=0
	When not matched and s.Id < 100000 then
	insert (Id)
	Values(s.Id);

	delete from #SeedIds where exists (Select Id from MetaForeignKeyCriteriaClient mfkcc where mfkcc.Id = #SeedIds.Id)

	Merge #SeedIds as t
	using (
			SELECT  ROW_NUMBER() OVER (
			ORDER BY Id
		   ) row_num, Id from #SeedIds
	)as s on s.Id = t.Id
	When  matched then Update
	Set t.row_num = s.row_num;
	Select * from #SeedIds Order by row_num asc

DECLARE @MAX int = (SELECT Id FROM #SeedIds WHERE row_num = 1)
--DECLARE @MAX2 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)
--DECLARE @MAX3 int = (SELECT Id FROM #SeedIds WHERE row_num = 3)
DECLARE @MAX4 int = (SELECT Id FROM #SeedIds WHERE row_num = 2)

declare @customSQL Nvarchar(max) = 'DECLARE @courseFamily AS TABLE ([Id] INT NULL);
			
INSERT INTO @courseFamily (Id)
SELECT c.Id
FROM Course c
WHERE c.Id = @entityId
UNION
SELECT bc.ActiveCourseId
FROM Course c
    INNER JOIN BaseCourse bc ON c.BaseCourseId = bc.id
WHERe c.Id = @entityId
AND bc.ActiveCourseId IS NOT NULL;
			
-- Requisite Courses
declare @requisites table (CourseId int, CourseTitle nvarchar(max), CourseStatus nvarchar(max), RequisiteType nvarchar(max))

insert into @requisites
(CourseId,CourseTitle,CourseStatus,RequisiteType)
SELECT DISTINCT
        c.Id,
        coalesce(c.EntityTitle,s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title) as CourseTitle, 
        sa.Title as CourseStatus, 
        rt.Title as RequisiteType
FROM Course c
    INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
    INNER JOIN [Subject] s ON c.SubjectId = s.Id
    INNER JOIN CourseRequisite cr ON c.Id = cr.CourseId
    INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
    INNER JOIN Client cl ON c.ClientId = cl.Id
WHERE sa.StatusBaseId in (1, 2, 4, 6)
AND c.DeletedDate IS NULL
AND EXISTS (SELECT 1 
            FROM @courseFamily cf
            WHERE cf.Id = cr.Requisite_CourseId
            )
ORDER BY CourseTitle, CourseStatus;

declare @final NVARCHAR(max) = (
    select dbo.ConcatWithSep_Agg('''',concat(r.RequisiteType,space(1),
        r.CourseTitle,space(1),
        ''*'',r.CourseStatus,''*''
    ))
    from @requisites r
)

select 
    0 as Value
    ,case 
        when len(@final) > 0 then concat(''This course is a requisite for the following course(s):'',@final)
    else ''This course is not being used as a requisite for any course''
    end as Text'

--declare @customSQL2 Nvarchar(max) = 'DECLARE @courseFamily AS TABLE ([Id] INT NULL);
			
--INSERT INTO @courseFamily (Id)
--SELECT c.Id
--FROM Course c
--WHERE c.Id = @entityId
--UNION
--SELECT bc.ActiveCourseId
--FROM Course c
--    INNER JOIN BaseCourse bc ON c.BaseCourseId = bc.id
--WHERe c.Id = @entityId
--AND bc.ActiveCourseId IS NOT NULL;
			
--declare @newCL bit = (
--    select EnableCrossListing
--    from Config.ClientSetting
--)

--declare @final NVARCHAR(max) = ''''

--if (@newCL = 1)
--BEGIN
    
--    set @final = (
--        select replace(CrosslistedCourses,''Other courses currently in Crosslisting:'','''')
--        from Course
--        where Id = @entityId
--    )

--END
--ELSE
--BEGIN

--    declare @cl table (CourseId int, CourseTitle nvarchar(max), CourseStatus nvarchar(max))

--    insert into @cl
--    (CourseId, CourseTitle, CourseStatus)
--    SELECT 
--        c.Id,
--        coalesce(c.EntityTitle,s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title) as CourseTitle, 
--        sa.Title as CourseStatus
--    FROM Course c
--        INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
--        INNER JOIN [Subject] s ON c.SubjectId = s.Id
--        INNER JOIN Client cl ON c.ClientId = cl.Id
--    WHERE EXISTS (SELECT 1 
--                    FROM CourseRelatedCourse crc
--                        INNER JOIN @courseFamily cf ON crc.CourseId = cf.Id
--                    WHERE crc.RelatedCourseId = c.Id)
--    AND sa.StatusBaseId in (1, 2, 4, 6)
--    AND c.DeletedDate IS NULL
--    ORDER BY 1, 2;


--    set @final = (
--        select dbo.ConcatWithSep_Agg('''',concat(c.CourseTitle,space(1),''*'',c.CourseStatus,''*''))
--        from @cl c
--        group by c.CourseId
--    )

--end

--select 0 as Value, concat(''This course is cross-listed as the following course(s)'',@final) as Text
--'

--declare @customSQL3 Nvarchar(max) = 'DECLARE @courseFamily AS TABLE ([Id] INT NULL);
			
--INSERT INTO @courseFamily (Id)
--SELECT c.Id
--FROM Course c
--WHERE c.Id = @entityId
--UNION
--SELECT bc.ActiveCourseId
--FROM Course c
--    INNER JOIN BaseCourse bc ON c.BaseCourseId = bc.id
--WHERe c.Id = @entityId
--AND bc.ActiveCourseId IS NOT NULL;
			
--declare @programs table (ProgramId int, ProgramStatus nvarchar(max), ProgramAwardType nvarchar(max), ProgramTitle nvarchar(max), ProposalType nvarchar(max))

--INSERT into @programs
--(ProgramId,ProgramStatus,ProgramAwardType,ProgramTitle,ProposalType)
--SELECT distinct
--    p.Id,
--    sa.Title as ProgramStatus,
--    at.Title as AwardType,
--    p.Title as ProgramTitle,
--    pt.Title as ProposalType
--FROM Program p
--    INNER JOIN StatusAlias sa ON p.StatusAliasId = sa.Id
--    INNER JOIN ProposalType pt ON p.ProposalTypeId = pt.Id
--    LEFT JOIN AwardType at ON p.AwardTypeId = at.Id
--    INNER JOIN Client cl ON p.ClientId = cl.Id
--WHERE p.DeletedDate IS NULL
--    AND sa.StatusBaseId in (1, 2, 4, 6)
--AND EXISTS (
--    SELECT 1
--        FROM ProgramSequence ps
--            INNER JOIN @courseFamily cf ON ps.CourseId = cf.Id
--        WHERE ps.ProgramId = p.Id)
--ORDER BY sa.Title, pt.Title, at.Title, p.Title;

--declare @final NVARCHAR(max) = (
--    select dbo.ConcatWithSep_Agg('''',concat(
--        p.ProposalType,''-'',p.ProgramAwardType,'' *'',p.ProgramStatus,''* '',p.ProgramTitle
--    ))
--    from @programs p
--)

--select 0 as Value, case when len(@final) > 0 then @final else ''This course is a stand-alone course and is not incorporated into any programs'' end as Text'

declare @customSQL4 Nvarchar(max) = 'DECLARE @courseFamily AS TABLE ([Id] INT NULL);
			
INSERT INTO @courseFamily (Id)
SELECT c.Id
FROM Course c
WHERE c.Id = @entityId
UNION
SELECT bc.ActiveCourseId
FROM Course c
    INNER JOIN BaseCourse bc ON c.BaseCourseId = bc.id
WHERe c.Id = @entityId
AND bc.ActiveCourseId IS NOT NULL;

declare @programs table (ProgramId int, ProgramStatus nvarchar(max), ProgramAwardType nvarchar(max), ProgramTitle nvarchar(max), ProposalType nvarchar(max))

insert into @programs
(ProgramId, ProgramStatus, ProgramAwardType, ProgramTitle, ProposalType)
SELECT distinct p.Id,sa.Title,at.Title, p.Title,pt.Title
FROM Program p
    INNER JOIN StatusAlias sa ON p.StatusAliasId = sa.Id
    INNER JOIN ProposalType pt ON p.ProposalTypeId = pt.Id
    LEFT JOIN AwardType at ON p.AwardTypeId = at.Id
    INNER JOIN Client cl ON p.ClientId = cl.Id
WHERE p.DeletedDate IS NULL
AND sa.StatusBaseId in (1, 2, 4, 6)
AND EXISTS (SELECT 1
            FROM CourseOption co
                INNER JOIN ProgramCourse pc ON co.Id = pc.CourseOptionId
                INNER JOIN @courseFamily cf ON pc.CourseId = cf.Id
            WHERE co.ProgramId = p.Id)

declare @final NVARCHAR(max) = (
    select dbo.ConcatWithSep_Agg('''',concat(
        p.ProposalType,''-'',p.ProgramAwardType,'' *'',p.ProgramStatus,''* '',p.ProgramTitle
    ))
    from @programs p
)

select 
    0 as Value
    ,case 
        when len(@final) > 0 then concat(''This course is incorporated into the following program(s):'',@final)
        else ''This course is a stand-alone course and is not incorporated into any programs'' 
    end as Text'

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', @customSQL, @customSQL, 'Order By SortOrder', 'Adhocreportsql', 2),
--(@MAX2, 'Course', 'Id', 'Title', @customSQL2, @customSQL2, 'Order By SortOrder', 'Adhocreportsql', 2),
--(@MAX3, 'Course', 'Id', 'Title', @customSQL3, @customSQL3, 'Order By SortOrder', 'Adhocreportsql', 2),
(@MAX4, 'Course', 'Id', 'Title', @customSQL4, @customSQL4, 'Order By SortOrder', 'Adhocreportsql', 2)

INSERT INTO AdHocReport
(ClientId, Title, Definition, OutputFormatId, IsPublic ,Active)
VALUES
(51, 'Impact Report', CONCAT('{"id":"71","modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"Impact Report","description":"","outputFormatId":"1","isPublic":false,"columns":[{"caption":"Course Entity Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Course.EntityTitle"}},{"caption":"Status","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"}},{"caption":"Requisite","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL_Course.Text"}},{"caption":"In Program","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"CustomSQL4_Course.Text"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"StartsWith","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Course.StatusAliasTitle"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"Active","text":"Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL_Course.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"', @MAX,'","text":"52"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Equal","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"CustomSQL4_Course.MFKCCId"},{"typeName":"CONST","dataType":"Int","kind":"Scalar","value":"',@MAX4,'","text":"',@MAX4,'"}]}]}}'), 1, 0 ,1)

--COMMIT