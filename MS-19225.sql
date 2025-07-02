USE [madera];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19225';
DECLARE @Comments nvarchar(Max) = 
	'Fix a broken Query and fix a typo';
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
UPDATE MetaControlAttribute
SET CustomMessage = 'A course with this course number and subject code already exists.'
WHERE CustomMessage = 'A course with this course number and subject code already exisits.'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @Text TABLE (txt NVARCHAR(MAX), cId int)
INSERT INTO @Text
SELECT 
    STRING_AGG(o.[Text], ''<br>'') 
        WITHIN GROUP (ORDER BY o.SortOrder, o.Id),
    o.CourseId
FROM CourseObjective o
WHERE o.CourseId = @EntityId
GROUP BY o.CourseId


DECLARE @Text2 TABLE (txt NVARCHAR(MAX), cId int)
INSERT INTO @Text2
SELECT 
    STRING_AGG(o.Rationale, ''<br>'') 
        WITHIN GROUP (ORDER BY o.SortOrder, o.Id),
    o.CourseId
FROM CourseEligibility o
WHERE o.CourseId = @EntityId
GROUP BY o.CourseId

select 0 as value,
	CONCAT(''Objectives Part 1 <br>'', t.txt, ''<br>'',
	''Objectives Part 2 <br>'', t2.txt)as [Text]
from Course AS c
LEFT JOIN @Text AS t on t.cId = c.ID
LEFT JOIN @Text2 AS t2 on t2.cId = c.Id
WHERE c.Id = @EntityId
'
, ResolutionSql = '
DECLARE @Text TABLE (txt NVARCHAR(MAX), cId int)
INSERT INTO @Text
SELECT 
    STRING_AGG(o.[Text], ''<br>'') 
        WITHIN GROUP (ORDER BY o.SortOrder, o.Id),
    o.CourseId
FROM CourseObjective o
WHERE o.CourseId = @EntityId
GROUP BY o.CourseId


DECLARE @Text2 TABLE (txt NVARCHAR(MAX), cId int)
INSERT INTO @Text2
SELECT 
    STRING_AGG(o.Rationale, ''<br>'') 
        WITHIN GROUP (ORDER BY o.SortOrder, o.Id),
    o.CourseId
FROM CourseEligibility o
WHERE o.CourseId = @EntityId
GROUP BY o.CourseId

select 0 as value,
	CONCAT(''Objectives Part 1 <br>'', t.txt, ''<br>'',
	''Objectives Part 2 <br>'', t2.txt)as [Text]
from Course AS c
LEFT JOIN @Text AS t on t.cId = c.ID
LEFT JOIN @Text2 AS t2 on t2.cId = c.Id
WHERE c.Id = @EntityId
'
WHERE Id = 81

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 81