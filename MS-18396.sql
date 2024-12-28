USE [frc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18396';
DECLARE @Comments nvarchar(Max) = 
	'Update Course drop down query';
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
SELECT c.Id As Value,
	CONCAT(COALESCE(EntityTitle, CONCAT(s.SubjectCode, '' '', c.CourseNumber, '' - '', c.Title)), '' *'',sa.Title,''*'') As Text,
	SubjectId As FilterValue
FROM Course c
	INNER JOIN StatusAlias sa ON sa.Id = c.StatusAliasId
	INNER JOIN Subject AS s on c.SubjectId = s.ID	
WHERE c.Active = 1
	AND SubjectId IS NOT NULL
	AND sa.StatusBaseId IN (1,2)
	and SubjectId = 10173
ORDER BY Text
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = '
SELECT c.Id As Value,
CONCAT(COALESCE(EntityTitle, CONCAT(s.SubjectCode, '' '', c.CourseNumber, '' - '', c.Title)), '' *'',sa.Title,''*'') As Text,
	SubjectId As FilterValue
FROM Course c
	INNER JOIN StatusAlias sa ON sa.Id = c.StatusAliasId
	INNER JOIN Subject AS s on c.SubjectId = s.ID	
WHERE c.Id = @id
'
WHERE Id = 12

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId fROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 12
)