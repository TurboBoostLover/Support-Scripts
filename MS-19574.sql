USE [compton];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19574';
DECLARE @Comments nvarchar(Max) = 
	'Update Effective Term drop down';
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
DECLARE @Id int = 91

DECLARE @SQL NVARCHAR(MAX) = '
select s.Id as Value,
s.Title as Text 
,s.SortOrder
from Semester s
where s.TermEndDate >= ''2019-01-01''
And s.TermEndDate < ''2030-01-01''
UNION
select s.Id as Value, s.Title as Text ,s.SortOrder
from Semester s
inner join CourseProposal ms on ms.SemesterId = s.Id
and ms.CourseId = @EntityId
order by s.SortOrder
'

INSERT INTO Semester
(Title, CatalogYear, ClientId, SortOrder, StartDate, TermStartDate, TermEndDate, AcademicYearStart, AcademicYearEnd)
VALUES
('Fall 2028', '2028-2029', 1, 233, GETDATE(), '2028-09-01 00:00:00.000', '2028-12-31 00:00:00.000', '2028', '2029'),

('Winter 2029', '2029-2030', 1, 234, GETDATE(), '2029-01-01 00:00:00.000', '2029-01-31 00:00:00.000', '2028', '2029'),
('Spring 2029', '2029-2030', 1, 235, GETDATE(), '2029-02-01 00:00:00.000', '2029-05-31 00:00:00.000', '2028', '2029'),
('Summer 2029', '2029-2030', 1, 236, GETDATE(), '2029-06-01 00:00:00.000', '2029-08-31 00:00:00.000', '2028', '2029'),
('Fall 2030', '2029-2030', 1, 237, GETDATE(), '2029-09-01 00:00:00.000', '2029-12-31 00:00:00.000', '2029', '2030')

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id