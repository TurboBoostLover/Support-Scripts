USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15850';
DECLARE @Comments nvarchar(Max) = 
	'UPDATE COR report';
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
SET CustomSql = 'SELECT 0 AS Value
,concat(''<ol style="list-style-type: &quot;* &quot;;">'',dbo.ConcatWithSepOrdered_Agg('''',IT.SortOrder, ''<li>'' + IT.Title + ''</li>''),''</ol>'', ge.TextMax07)  AS Text
FROM InstructionType IT
	inner join CourseInstructionType CIT on IT.id = CIT.InstructionTypeId
	INNER JOIN Course AS c on cit.CourseId = c.Id
	LEFT JOIN GenericMaxText AS ge on ge.CourseId = c.Id
where c.id = @entityid
and it.Active = 1
group by ge.TextMax07'
, ResolutionSql = 'SELECT 0 AS Value
,concat(''<ol style="list-style-type: &quot;* &quot;;">'',dbo.ConcatWithSepOrdered_Agg('''',IT.SortOrder, ''<li>'' + IT.Title + ''</li>''),''</ol>'', ge.TextMax07)  AS Text
FROM InstructionType IT
	inner join CourseInstructionType CIT on IT.id = CIT.InstructionTypeId
	INNER JOIN Course AS c on cit.CourseId = c.Id
	LEFT JOIN GenericMaxText AS ge on ge.CourseId = c.Id
where c.id = @entityid
and it.Active = 1
group by ge.TextMax07'
WHERE Id = 99

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MEtaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 99
)