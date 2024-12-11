USE [imperial];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14148';
DECLARE @Comments nvarchar(Max) = 
	'Update impact report query text';
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
AND bc.ActiveCourseId IS NOT NULL
UNION
SELECT crc.RelatedCourseId
FROM Course AS c
LEFT JOIN CourseRelatedCourse AS crc ON c.Id = crc.CourseId
LEFT JOIN CourseRelatedCourse AS crc2 ON c.Id = crc2.Related_CourseId
WHERE C.Id = @entityId
			
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

select 0 as Value, case when len(@final) > 0 then dbo.fnHtmlElement(''ol'',@final,null) else ''This course is a stand-alone course and is not incorporated into any programs'' end as Text
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 38

UPDATE MetaTemplate
SET LastUpdatedDate = gETDATE()
WHERE MetaTemplateId in (
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 1
    AND mtt.ClientId = 1
		AND mtt.MetaTemplateTypeId = 10
)