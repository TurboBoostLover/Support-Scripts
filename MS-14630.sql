USE [clovis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14630';
DECLARE @Comments nvarchar(Max) = 
	'Update Semester Table with correct dates';
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
UPDATE Semester
SET TermStartDate = '2024-01-08 00:00:00.000'
WHERE Id = 182

UPDATE Semester
SET TermStartDate = '2024-08-12 00:00:00.000'
WHERE Id = 184

UPDATE Semester
SET TermStartDate = '2025-01-13 00:00:00.000'
WHERE Id = 185

UPDATE Semester
SET TermStartDate = '2025-08-11 00:00:00.000'
WHERE Id = 187

UPDATE Semester
SET TermStartDate = '2026-01-12 00:00:00.000'
WHERE Id = 188

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = 'select 0 as Value,
convert(char(10), s.TermStartDate, 126)as Text
from Course c 
inner join CourseProposal AS cp on cp.CourseId = c.Id 
INNER JOIN Semester AS s on cp.SemesterId = s.Id
and c.Id = @EntityId'
, ResolutionSql = 'select 0 as Value,
convert(char(10), s.TermStartDate, 126)as Text
from Course c 
inner join CourseProposal AS cp on cp.CourseId = c.Id 
INNER JOIN Semester AS s on cp.SemesterId = s.Id
and c.Id = @EntityId'
WHERE Id = 935

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 935
)