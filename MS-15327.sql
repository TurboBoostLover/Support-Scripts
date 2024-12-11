USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15327';
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
UPDATE MetaSelectedSection
SET DisplaySectionName = 0 
WHERE MetaSelectedSectionId in (
	SELECT mss.MEtaSelectedSectionId FROM MetaSelectedSection AS mss
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 7
	and mss.MetaSelectedSection_MetaSelectedSectionId IS NULL
)

DECLARE @SQL NVARCHAR(MAX) = '
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
    select EnableCrossListing
    from Config.ClientSetting
		WHERE ClientId = 1
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


    set @final = (
        select dbo.ConcatWithSep_Agg('''',dbo.fnHtmlElement(''li'',concat(c.CourseTitle,space(1),''*'',c.CourseStatus,''*''),null))
        from @cl c
        group by c.CourseId
    )

end

IF @final IS NULL
    SELECT NULL
ELSE
    SELECT 
        0 as Value,
        CONCAT(
            dbo.fnHtmlElement(''i'', ''This course is cross-listed as the following course(s)'', null),
            dbo.fnHtmlElement(''ol'', @final, null)
        ) as Text;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 2848

DECLARE @SQL2 NVARCHAR(MAX) = '
DECLARE @TABLE TABLE (txt nvarchar(max), sort int)
INSERT INTO @TABLE
SELECT CONCAT(''<b>'', ge.Title, ''</b><br>'', gee.Title), ge.SortOrder
FROM GeneralEducation AS GE
INNER JOIN GeneralEducationElement AS gee ON gee.GeneralEducationId = ge.Id
INNER JOIN CourseGeneralEducation As cge on cge.GeneralEducationElementId = gee.Id
WHERE cge.CourseId = @EntityId
order by ge.SortOrder

SELECT 0 AS Value,
dbo.ConcatWithSep_Agg(''<br>'', txt) AS Text FROM @TABLE
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 2849

UPDATE MetaSelectedField
SET DisplayName = 'General Education'
WHERE MetaForeignKeyLookupSourceId = 2849

DECLARE @SQL3 NVARCHAR(MAX) = '
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

declare @programs table (ProgramId int, ProgramStatus nvarchar(max), ProgramAwardType nvarchar(max), ProgramTitle nvarchar(max), ProposalType nvarchar(max), block nvarchar(max), campus nvarchar(max))

insert into @programs
(ProgramId, ProgramStatus, ProgramAwardType, ProgramTitle, ProposalType, block, campus)
SELECT distinct p.Id,sa.Title,at.Title, p.Title,pt.Title, co.CourseOptionNote, c.Title
FROM Program p
    INNER JOIN StatusAlias sa ON p.StatusAliasId = sa.Id
    INNER JOIN ProposalType pt ON p.ProposalTypeId = pt.Id
    LEFT JOIN AwardType at ON p.AwardTypeId = at.Id
    INNER JOIN Client cl ON p.ClientId = cl.Id
		INNER JOIN CourseOption AS co on co.ProgramId = p.Id
		INNER JOIN ProgramCourse AS pc on pc.CourseOptionId = co.Id
		INNER JOIN @courseFamily cf ON pc.CourseId = cf.Id
		LEFT JOIN Campus AS c on p.CampusId = c.Id
WHERE p.DeletedDate IS NULL
AND sa.StatusBaseId in (1, 2, 4, 6)
AND EXISTS (SELECT 1
            FROM CourseOption co
                INNER JOIN ProgramCourse pc ON co.Id = pc.CourseOptionId
                INNER JOIN @courseFamily cf ON pc.CourseId = cf.Id
            WHERE co.ProgramId = p.Id)

declare @final NVARCHAR(max) = (
    select dbo.ConcatWithSep_Agg(''<br>'',concat(
      COALESCE(CONCAT(''<b>'', p.Campus, ''</b><br>''), ''''),p.ProgramTitle,'' *'',p.ProgramStatus,''* '', p.ProgramAwardType, ''<br>'', p.block
    ))
    from @programs p
)

select 
    0 as Value
    ,case 
        when len(@final) > 0 then dbo.fnHtmlElement(''ol'',concat(''This course is incorporated into the following program(s): <br>'',@final),null) 
        else ''This course is a stand-alone course and is not incorporated into any programs'' 
    end as Text
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL3
, ResolutionSql = @SQL3
WHERE Id = 2850

DELETE FROM MetaSelectedField
WHERE MetaAvailableFieldId = 3418

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 7
)