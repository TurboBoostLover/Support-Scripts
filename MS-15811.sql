USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15811';
DECLARE @Comments nvarchar(Max) = 
	'Update Query in adhoc report';
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
        '' *'',p.ProgramStatus,''* '',p.ProgramTitle,''; ''
    ))
    from @programs p
)

select 
    0 as Value
    ,case 
        when len(@final) > 0 then @final
        else ''This course is a stand-alone course and is not incorporated into any programs'' 
    end as Text
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 36