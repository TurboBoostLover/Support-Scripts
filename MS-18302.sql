USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18302';
DECLARE @Comments nvarchar(Max) = 
	'CCN Course Impacting programs fix';
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
SET QUOTED_IDENTIFIER OFF 

DECLARE @sql NVARCHAR(MAX) =
"
DECLARE @SQL2 NVARCHAR(MAX) = '			
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
		LEFT JOIN ProgramSequence AS ps on ps.ProgramId = p.ID
		LEFT JOIN CourseOption AS co on co.ProgramId = p.Id
		LEFT JOIN ProgramCourse AS pc on pc.CourseOptionId = co.Id
		WHERE (ps.CourseId = @EntityId or pc.CourseId = @EntityId)
ORDER BY sa.Title, pt.Title, at.Title, p.Title;

declare @final NVARCHAR(max) = (
    select STRING_AGG(
		concat(p.ProposalType,''-'',p.ProgramAwardType,'' *'',p.ProgramStatus,''* '',p.ProgramTitle), ''; '')
    from @programs p
)

select 0 as Value, case when len(@final) > 0 then @final else ''This course is a stand-alone course and is not incorporated into any programs'' end as Text'

SELECT 
cl.Code AS [College],
CONCAT(s.SubjectCode, ' ', c.CourseNumber) AS [Subject and Course Number],
c.Id AS [Meta Id],
q2.Text AS [Impacted Programs]
FROM Course AS c
INNER JOIN Client AS cl on c.ClientId = cl.Id
INNER JOIN Subject AS s on c.SubjectId = s.Id
outer apply dbo.fnBulkResolveCustomSqlQuery(@SQL2, 0, c.Id, 1, 1467, 1,null) q2
WHERE c.CourseNumber like 'C%'
and c.ClientId = 3
and c.Active = 1
ORDER BY [College], [Subject and Course Number]
";

SET QUOTED_IDENTIFIER ON 

UPDATE AdminReport
SET ReportSQL = @sql
WHERE Id = 23