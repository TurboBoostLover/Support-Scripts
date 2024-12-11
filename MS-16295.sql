USE [fresno];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16295';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report';
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
UPDATE AdminReport
SET ReportSQL = 'DECLARE @6d TABLE (Goalnumber nvarchar(max), goal nvarchar(max), Resource nvarchar(max), Explain nvarchar(max), comments nvarchar(max), ModuleId int)
INSERT INTO @6d
SELECT gol.Text100001, gol.Text100004, gol.Text100002, gol.Text100003, gol.Text100005, m.Id
FROM GenericOrderedList02 AS gol
INNER JOIN Module As m on gol.ModuleId = m.Id
WHERE m.ProposalTypeId in (12, 15)


SELECT m.EntityTitle AS [Instructional Program Review Title],
dbo.ConcatWithSep_Agg(''; '', CONCAT(''Goal #: '',d.Goalnumber, '' Goal: '', d.goal, '' Resource: '', d.Resource, '' Explain: '', d.Explain, '' Comments: '', d.comments)) as [Resource Table],
me2.TextMax11 AS [Program Review Coordinator Comments],
mqt.QueryText_47 AS [Division Dean Comments],
mqt.QueryText_48 AS [Division Program Review rep Comments]
FROM Module m
	INNER JOIN ModuleExtension02 me2 ON me2.ModuleId = m.Id
	LEFT JOIN ModuleQueryText mqt ON mqt.ModuleId = m.Id
	INNER JOIN StatusAlias sa ON sa.Id = m.StatusAliasId
	LEFT JOIN @6d AS d on d.ModuleId = m.Id
WHERE sa.StatusBaseId IN (1,6)
	AND m.ProposalTypeId in (12, 15)
GROUP BY m.EntityTitle, me2.TextMax11, mqt.QueryText_47, mqt.QueryText_48'
WHERE Id = 15