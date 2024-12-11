USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17752';
DECLARE @Comments nvarchar(Max) = 
	'UPDATE COR to respect sort order';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'select
    0 as Value,
    concat(
        Author,space(1),Title,space(1),Edition,space(1),Publisher,space(1),IsbnNum,space(1),CalendarYear,SPACE(1),Rational
    ) as Text
from CourseTextbook
where courseid = @entityId
order by SortOrder'
, ResolutionSql = 'select
    0 as Value,
    concat(
        Author,space(1),Title,space(1),Edition,space(1),Publisher,space(1),IsbnNum,space(1),CalendarYear,SPACE(1),Rational
    ) as Text
from CourseTextbook
where courseid = @entityId
order by SortOrder'
WHERE Id = 107

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'select
    0 as Value,
    concat(
        Author,space(1),Title,space(1),Text25501,space(1),Publisher,space(1),[Description],space(1),CalendarYear,SPACE(1),Other
    ) as Text
from CourseManual
where courseid = @entityId
order by SortOrder'
, ResolutionSql = 'select
    0 as Value,
    concat(
        Author,space(1),Title,space(1),Text25501,space(1),Publisher,space(1),[Description],space(1),CalendarYear,SPACE(1),Other
    ) as Text
from CourseManual
where courseid = @entityId
order by SortOrder'
WHERE Id = 108

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'select
    0 as Value,
    concat(
        Title,space(1),Edition,space(1),Publisher,space(1),[Description]
    ) as Text
from CourseSoftware
where courseid = @entityId
order by SortOrder'
, ResolutionSql = 'select
    0 as Value,
    concat(
        Title,space(1),Edition,space(1),Publisher,space(1),[Description]
    ) as Text
from CourseSoftware
where courseid = @entityId
order by SortOrder'
WHERE Id = 109

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'select
    0 as Value,
    concat(
        TextOther,space(1),CalendarYear,space(1),Rationale
    ) as Text
from CourseTextOther
where courseid = @entityId
order by SortOrder'
, ResolutionSql = 'select
    0 as Value,
    concat(
        TextOther,space(1),CalendarYear,space(1),Rationale
    ) as Text
from CourseTextOther
where courseid = @entityId
order by SortOrder'
WHERE Id = 110

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (
		107, 108, 109, 110
	)
)