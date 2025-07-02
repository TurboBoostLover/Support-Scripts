USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18172';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog view for courses and programs for C-identifier
	update reports in programs to show C-identifier
	';
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
UPDATE OutputModelClient
SET ModelQuery = 'declare @entityList_internal table (
    InsertOrder int identity(1, 1) primary key
    , CourseId int
);

insert into @entityList_internal (CourseId)
select el.Id
FROM @entityList el order by InsertOrder;
-- VALUES
-- (24175)

declare @entityRootData table (	
    CourseId int primary key,
    SubjectCode nvarchar(max),
    CourseNumber nvarchar(max),
    CourseTitle nvarchar(max),
    Variable bit,
    MinUnit decimal(16, 3),
    MaxUnit decimal(16, 3),
    MinLec decimal(16, 3),
    MaxLec decimal(16, 3),
    MinLab decimal(16, 3),
    MaxLab decimal(16, 3),
    MinLearn decimal(16,3),
    MaxLearn decimal(16,3), 
    TransferType NVARCHAR(max),
    PreRequisite NVARCHAR(max),
    CoRequisite NVARCHAR(max),
    Limitation NVARCHAR(max),
    Preperation NVARCHAR(max),
    CatalogDescription nvarchar(max),
    CourseGrading nvarchar(max),
    IsRepeatable NVARCHAR(10),
    RepeatableCode NVARCHAR(500),
    TimesRepeated NVARCHAR(500),
	Suffix nvarchar(500),
    CID NVARCHAR(500),
    AdminRepeat NVARCHAR(MAX)
);

declare @clientId int = 2

declare @preRequisiteQuery nvarchar(max) = (
    select CustomSql
    from MetaForeignKeyCriteriaClient
    where Title = ''Catalog PreRequisite''
)

declare @coRequisiteQuery nvarchar(max) = (
    select CustomSql
    from MetaForeignKeyCriteriaClient
    where Title = ''Catalog CoRequisite''
)

declare @limitRequisiteQuery nvarchar(max) = (
    select CustomSql
    from MetaForeignKeyCriteriaClient
    where Title = ''Catalog Limit''
)

declare @prepRequisiteQuery nvarchar(max) = (
    select CustomSql
    from MetaForeignKeyCriteriaClient
    where Title = ''Catalog Prep''
)

-- ============================
-- return
-- ============================
insert into @entityRootData (
    CourseId
    , SubjectCode
    , CourseNumber
    , CourseTitle
    , Variable
    , MinUnit
    , MaxUnit
    , MinLec
    , MaxLec
    , MinLab
    , MaxLab
    , MinLearn
    , MaxLearn
    , TransferType
    , PreRequisite
    , CoRequisite
    , Limitation
    , Preperation
    , CatalogDescription
    , CourseGrading
    , IsRepeatable
    , RepeatableCode
    , TimesRepeated
	, Suffix
    , CID
    , AdminRepeat
)
select c.Id
    , s.SubjectCode ,
			CASE
				WHEN ISNULL(cyn.YesNo50Id,0) = 1
				THEN CONCAT(toc.Code, c.CourseNumber)
				ELSE c.CourseNumber
			END
    , c.Title
    , cd.Variable
    , cd.MinCreditHour
    , cd.MaxCreditHour
    , cd.MinLectureHour
    , cd.MaxLectureHour
    , cd.MinLabHour
    , cd.MaxLabHour
    , cd.MinContHour
    , cd.MaxContHour
    , ta.Description
    , pre.Text
    , co.Text
    , limit.Text
    , prep.Text
    , CASE 
				WHEN ISNULL(cyn.YesNo50Id,0) = 1 
				THEN CONCAT(''Part 1: '', c.COURSE_DESC, '' Part 2: '' ,lTrim(rTrim(c.[Description])))--catalog Description
				ELSE lTrim(rTrim(c.[Description]))
			END
    , concat(gon.Title,'' - '',gon.[Description]) -- course grading
    , yn.Title --isrepeatable
    , rl.Code --repeatcode
    , r.Code --times repeated
	, cs.Code --suffix
    , cid.CID --CID
    , cp.TimesOfferedRationale --admin repeat
from Course c
    inner join @entityList_internal eli on c.Id = eli.CourseId
    inner join CourseDescription cd on c.Id = cd.CourseId
    inner join CourseProposal cp on cd.CourseId = cp.CourseId
    inner join Coursecbcode ccc on c.Id = ccc.CourseId
	inner join ProposalType pt on pt.Id = c.ProposalTypeId
		and pt.ProcessActionTypeId in (1,2) --client does not want deactivations to appear in the catalog removing them at this point means that a deleted course will not show up at all in the catalog.
    left join [Subject] s on c.SubjectId = s.Id
    left join GradeOption gon on cd.GradeOptionId = gon.Id
    left join CourseYesNo cyn on c.Id = cyn.CourseId
    left join YesNo yn on cyn.YesNo05Id = yn.Id
		LEFT join CourseAttribute AS ca on ca.CourseId = c.Id
		LEFT JOIN TypeOfCourse AS toc on toc.Id = ca.TypeOfCourseId
    left join TransferApplication ta on ta.id = cd.TransferAppsId
    left join RepeatLimit rl on rl.id = cp.RepeatlimitId
    left join Repeatability r on r.Id = cp.RepeatabilityId
	left join CourseSuffix cs on cs.Id = c.CourseSuffixId
    outer apply (
        select *
        from dbo.fnBulkResolveCustomsqlquery(@preRequisiteQuery, 1, c.Id, @clientId, NULL, NULL, NULL)
    ) pre
    outer apply (
        select *
        from dbo.fnBulkResolveCustomsqlquery(@coRequisiteQuery, 1, c.Id, @clientId, NULL, NULL, NULL)
    ) co
    outer apply (
        select *
        from dbo.fnBulkResolveCustomsqlquery(@limitRequisiteQuery, 1, c.Id, @clientId, NULL, NULL, NULL)
    ) limit
    outer apply (
        select *
        from dbo.fnBulkResolveCustomsqlquery(@prepRequisiteQuery, 1, c.Id, @clientId, NULL, NULL, NULL)
    ) prep
    outer apply (
        select dbo.ConcatWithSepOrdered_Agg('', '',cs.Id,ReadMaterials) as CID
        from CourseSupply cs
        where cs.CourseId = c.Id
    ) cid
;

select eli.CourseId as Id
    , m.Model
from @entityList_internal eli
    cross apply (
        select (
            select *
            from @entityRootData erd
            where eli.CourseId = erd.CourseId
            for json path, without_array_wrapper
        ) RootData
    ) erd
    cross apply (
        select (
            select eli.InsertOrder
                , json_query(erd.RootData) as RootData
            for json path
        ) Model
    ) m
;'
WHERE Id = 1