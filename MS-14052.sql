USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14052';
DECLARE @Comments nvarchar(Max) = 
	'Update Impact Report';
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
declare @reportId int = 451 --need to replace this with the report Id
declare @clientId int = 1
declare @adminUser int = (
    select Id
    from [User]
    where Email = 'supportadmin@curriqunet.com'
)

declare @templateName NVARCHAR(500) = 'Impact'

declare @entityTypeId int = 1
declare @cet int = null
declare @shares integers

--create the template
exec spBuilderTemplateTypeInsert @clientId, @adminUser, @templateName, @entityTypeId, @cet, 1, 0, @shares

declare @newMTT int = (select max(MetaTemplateTypeId) from MetaTemplateType)

declare @newMT int = (select MetaTemplateId from MetaTemplate where MetaTemplateTypeId = @newMTT)

--activate the draft
exec spBuilderTemplateActivate @clientId, @newMT, @newMTT

--template changes
declare @templateId integers

insert into @templateId
VALUES
(@newMT)

--blank the tab name
update MetaSelectedSection
set SectionName = null
, DisplaySectionName = 0
where MetaTemplateId = @newMT

/*add Course Requisites query*/

--#region
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
    select dbo.ConcatWithSep_Agg('''',dbo.fnHtmlElement(''li'',concat(
        dbo.fnHtmlElement(''b'',r.RequisiteType,null),space(1),
        r.CourseTitle,space(1),
        ''*'',r.CourseStatus,''*''
    ),null))
    from @requisites r
)

select 
    0 as Value
    ,case 
        when len(@final) > 0 then concat(dbo.fnHtmlElement(''i'',''This course is a requisite for the following course(s):'',null), dbo.fnHtmlElement(''ol'',@final,null))
    else ''This course is not being used as a requisite for any course''
    end as Text'

declare @maxId int = (select max(id) + 1 from MetaForeignKeyCriteriaClient)

insert into MetaForeignKeyCriteriaClient
(Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,LookupLoadTimingType,Title)
VALUES
(@maxId,'CourseRequisite','Id','Title',@customSQL,@customSQL,'Order by SortOrder',2,'Impact Requisites output')
--#endregion

/*CrossListing query*/

--#region
declare @customSQL2 Nvarchar(max) = '
DECLARE @courseFamily AS TABLE ([Id] INT NULL);
			
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
			
declare @newCL bit = (
    select TOP 1 EnableCrossListing
    from Config.ClientSetting
)

declare @final NVARCHAR(max) = ''''

if (@newCL = 1)
BEGIN
    
    set @final = (
        select replace(CrosslistedCourses,''<h4>Other courses currently in Crosslisting:</h4><br>'','''')
        from Course
        where Id = @entityId
    )

END
ELSE
BEGIN

    declare @cl table (CourseId int, CourseTitle nvarchar(max), CourseStatus nvarchar(max))

    insert into @cl
    (CourseId, CourseTitle, CourseStatus)
    SELECT 
        c.Id,
        coalesce(c.EntityTitle,s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title) as CourseTitle, 
        sa.Title as CourseStatus
    FROM Course c
        INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
        INNER JOIN [Subject] s ON c.SubjectId = s.Id
        INNER JOIN Client cl ON c.ClientId = cl.Id
    WHERE EXISTS (SELECT 1 
                    FROM CourseRelatedCourse crc
                        INNER JOIN @courseFamily cf ON crc.CourseId = cf.Id
                    WHERE crc.RelatedCourseId = c.Id)
    AND sa.StatusBaseId in (1, 2, 4, 6)
    AND c.DeletedDate IS NULL
    ORDER BY 1, 2;

	DECLARE @TEST TABLE (tex nvarchar(max))
	INSERT INTO @TEST (tex)
	SELECT dbo.ConcatWithSep_Agg('''',dbo.fnHtmlElement(''li'',concat(c.CourseTitle,space(1),''*'',c.CourseStatus,''*''),null))       
	from @cl c
        group by c.CourseId

   set @final = (
        select dbo.ConcatWithSep_Agg('''', tex)
        from @TEST
    )

end

SELECT 
    0 AS Value,
    CASE 
        WHEN (SELECT tex FROM @TEST) IS NULL THEN NULL
        ELSE CONCAT(dbo.fnHtmlElement(''i'', ''This course is cross-listed as the following course(s)'', NULL), dbo.fnHtmlElement(''ol'', @final, NULL))
    END AS Text;'

declare @maxId2 int = (select max(id) + 1 from MetaForeignKeyCriteriaClient)

insert into MetaForeignKeyCriteriaClient
(Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,LookupLoadTimingType,Title)
VALUES
(@maxId2,'Course','Id','Title',@customSQL2,@customSQL2,'Order by SortOrder',2,'impact cross listed output')
--#endregion

/*Program Sequence query*/

--#region
declare @customSQL3 Nvarchar(max) = 'DECLARE @courseFamily AS TABLE ([Id] INT NULL);
			
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

INSERT into @programs
(ProgramId,ProgramStatus,ProgramAwardType,ProgramTitle,ProposalType)
SELECT distinct
    p.Id,
    sa.Title as ProgramStatus,
    at.Title as AwardType,
    p.Title as ProgramTitle,
    pt.Title as ProposalType
FROM Program p
    INNER JOIN StatusAlias sa ON p.StatusAliasId = sa.Id
    INNER JOIN ProposalType pt ON p.ProposalTypeId = pt.Id
    LEFT JOIN AwardType at ON p.AwardTypeId = at.Id
    INNER JOIN Client cl ON p.ClientId = cl.Id
WHERE p.DeletedDate IS NULL
    AND sa.StatusBaseId in (1, 2, 4, 6)
AND EXISTS (
    SELECT 1
        FROM ProgramSequence ps
            INNER JOIN @courseFamily cf ON ps.CourseId = cf.Id
        WHERE ps.ProgramId = p.Id)
ORDER BY sa.Title, pt.Title, at.Title, p.Title;

declare @final NVARCHAR(max) = (
    select dbo.ConcatWithSep_Agg('''',dbo.fnHtmlElement(''li'',concat(
        p.ProposalType,''-'',p.ProgramAwardType,'' *'',p.ProgramStatus,''* '',p.ProgramTitle
    ),null))
    from @programs p
)

select 0 as Value, case when len(@final) > 0 then dbo.fnHtmlElement(''ol'',@final,null) else ''This course is a stand-alone course and is not incorporated into any programs'' end as Text'

declare @maxId3 int = (select max(id) + 1 from MetaForeignKeyCriteriaClient)

insert into MetaForeignKeyCriteriaClient
(Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,LookupLoadTimingType,Title)
VALUES
(@maxId3,'ProgramSequence','Id','Title',@customSQL3,@customSQL3,'Order by SortOrder',2,'impact outputting program sequence')
--#endregion

/*CourseOption query*/

--#region
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
    select dbo.ConcatWithSep_Agg('''',dbo.fnHtmlElement(''li'',concat(
        p.ProposalType,''-'',p.ProgramAwardType,'' *'',p.ProgramStatus,''* '',p.ProgramTitle
    ),null))
    from @programs p
)

select 
    0 as Value
    ,case 
        when len(@final) > 0 then dbo.fnHtmlElement(''ol'',concat(''This course is incorporated into the following program(s): <br>'',@final),null) 
        else ''This course is a stand-alone course and is not incorporated into any programs'' 
    end as Text'

declare @maxId4 int = (select max(id) + 1 from MetaForeignKeyCriteriaClient)

insert into MetaForeignKeyCriteriaClient
(Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,LookupLoadTimingType,Title)
VALUES
(@maxId4,'CourseOption','Id','Title',@customSQL4,@customSQL4,'Order by SortOrder',2,'Impact report course option output')

--#endregion

--add tab section
declare @tabSectionId int = (
    select MetaSelectedSectionId
    from MetaSelectedSection
    where MetaTemplateId = @newMT
    and MetaSelectedSection_MetaSelectedSectionId is null
)

exec spBuilderSubSectionInsert 1, @tabSectionId, 1

declare @newSection int = (select max(MetaSelectedSectionId) from MetaSelectedSection)

--add 4 querytexts
insert into MetaSelectedField
(DisplayName,MetaAvailableFieldId,MetaSelectedSectionId,IsRequired,MinCharacters,MaxCharacters,RowPosition,ColPosition,ColSpan,DefaultDisplayType,MetaPresentationTypeId,Width,WidthUnit,Height,HeightUnit,AllowLabelWrap,LabelHAlign,LabelVAlign,LabelStyleId,LabelVisible,FieldStyle,EditDisplayOnly,GroupName,GroupNameDisplay,FieldTypeId,ValidationRuleId,LiteralValue,ReadOnly,AllowCopy,Precision,MetaForeignKeyLookupSourceId,MetadataAttributeMapId,EditMapId,NumericDataLength,Config)
values
('Title',872,@newSection,0,NULL,NULL,0,0,1,'Textbox',1,300,1,24,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL),
('Course Requisites',8993,@newSection,0,NULL,NULL,1,0,1,'QueryText',103,100,2,100,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,@maxId,NULL,NULL,NULL,NULL),
('Cross Listed Courses',8994,@newSection,0,NULL,NULL,3,0,1,'QueryText',103,100,2,100,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,@maxId2,NULL,NULL,NULL,NULL),
('ProgramSequence',8995,@newSection,0,NULL,NULL,4,0,1,'QueryText',103,100,2,100,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,@maxId3,NULL,NULL,NULL,NULL),
('ProgramCourse',8996,@newSection,0,NULL,NULL,5,0,1,'QueryText',103,100,2,100,1,1,0,1,1,1,0,NULL,NULL,NULL,5,NULL,NULL,0,1,NULL,@maxId4,NULL,NULL,NULL,NULL)

update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select * from @templateId)

/*setup metareport*/
insert into MetaReport
(Id,Title,MetaReportTypeId,OutputFormatId, ReportAttributes)
values
(@reportId,'Impact',4,5, '{"fieldRenderingStrategy":"HideEmptyFields"}')

update MetaReport
set ReportAttributes = JSON_MODIFY(ReportAttributes,'$.reportTemplateId',@newMt)
where id = @reportId

if exists (
    select Id
    from metareport
    where id = 3
)
BEGIN

    update MetaReportTemplateType
    set MetaReportId = @reportId
    where MetaReportId = 3

    update MetaReportActionType
    set MetaReportId = @reportId
    where MetaReportId = 3

end
ELSE
BEGIN

    insert into MetaReportTemplateType
    (MetaReportId,MetaTemplateTypeId,StartDate)
    select @reportId,mtt.MetaTemplateTypeId,getdate()
    from MetaTemplateType mtt
    inner join MetaTemplate mt
        on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
    where mtt.EntityTypeId = 1
    and mt.Active = 1
    and mt.IsDraft = 0
    and mtt.Active = 1
    and mtt.IsPresentationView = 0

    declare @newId int = (select max(id) + 1 from MetaReportActionType)

    insert into MetaReportActionType
    (Id,MetaReportId,ProcessActionTypeId)
    values
    (@newId,@reportId,1),
    (@newId + 1,@reportId,2),
    (@newId + 2,@reportId,3)

end

--commit
--rollback