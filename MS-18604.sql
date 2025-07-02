USE [Clovis];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18604';
DECLARE @Comments nvarchar(Max) = 
	'Update Query for look up for SUO Assessments';
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
DECLARE @Id int = 1397

DECLARE @SQL NVARCHAR(MAX) = '
		select sem.Id as [Value]
			, sem.Title as [Text]
		from Semester sem
		where TermStartDate > ''2014-08-12 00:00:00.000''
	and TermStartDate < ''2027-01-10 00:00:00.000''
			and (sem.Title like ''Fall%''
				or sem.Title like ''Spring%''
			)
			and sem.Active = 1
			or exists(
				select 1
				from ModuleDetail md
				where sem.Id = md.AcademicYear_SemesterId
				and md.ModuleId = @entityId
			)
		order by sem.TermStartDate, sem.Title
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
WHERE Id= @Id

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
select [Id] as [Value], (Title) as [Text]
from [Semester] 
where Active = 1 
	and TermStartDate > ''2014-08-12 00:00:00.000''
	and TermStartDate < ''2027-01-10 00:00:00.000''
Order By SortOrder
'
WHERE Id = 31

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (@Id, 31)