USE [stpetersburg];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14667';
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
SET ReportSQL = '
DECLARE @TABLE TABLE (pId int, units nvarchar(max))
INSERT INTO @TABLE
SELECT co.ProgramId, 
Case
	When sum(calcMin) != sum(calcMax) and sum(calcMin) is not null and Sum(calcMax) is not null
		Then	concat(sum(calcMin), '' - '', Sum(calcMax))
	When sum(calcMin) = Sum(calcMax) and sum(calcMin)is not null 
		Then	cast(sum(calcMin) AS nvarchar(10))
	Else ''0''
END
	As Text FROM CourseOption AS co
WHere DoNotCalculate != 1
Group by ProgramId

SELECT
	p.Title AS [Degree Name],
	p.Associations AS [Program Code],
	at.Title AS [Award Type],
	s.Title AS [What is the term the Program or associated changes will take effect],
	s2.Title AS [Last Valid requirement term for this version],
	convert(char(10), pro.ImplementDate, 101) AS [Implementation / Approved date],
	t.units	As [Total Credits]

FROM Program AS p
INNER JOIN StatusAlias AS sa ON p.StatusAliasId = sa.Id
LEFT JOIN AwardType AS at ON p.AwardTypeId = at.Id
INNER JOIN ProgramProposal AS pp ON pp.ProgramId = p.Id
LEFT JOIN Semester AS s ON pp.SemesterId = s.Id
LEFT JOIN Semester AS s2 ON pp.LastAssessedSemesterId = s2.Id
INNER JOIN Proposal AS pro ON p.ProposalId = pro.Id
left join CourseOption CO on CO.ProgramId = p.Id AND CO.DoNotCalculate != 1
LEFT JOIN ProgramCourse AS PC on PC.CourseOptionId = CO.Id AND PC.DoNotCalculate != 1
LEFT JOIN @TABLE AS t on p.Id = t.pId
WHERE sa.Id = 1
AND at.Id in (18, 19, 22, 23, 24, 25, 26)
GROUP By p.Title, p.Associations, at.Title, s.Title, s2.Title, pro.ImplementDate, t.units
order by 1
'
WHERE Id = 45