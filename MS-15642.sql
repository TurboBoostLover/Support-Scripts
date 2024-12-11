USE [evc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15642';
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
DECLARE @FutureNEEDS TABLE (mId int, need nvarchar(max), ongoing int, onetime int)
INSERT INTO @FutureNEEDS
SELECT
m.Id, it.Title, mra.Int01, NULL
FROM Module AS m
INNER JOIN ModuleResourceAllocation AS mra on mra.ModuleId = m.Id
INNER JOIN ItemType AS it on mra.ItemTypeId = it.Id
UNION
SELECT
m.Id, lo14.Title, gol.Int01, 
CASE
WHEN gol.YesNoId_01 = 1
THEN gol.Int02
ELSE NULL
END
FROM Module AS m
INNER JOIN GenericOrderedList03 AS gol on gol.ModuleId = m.Id
INNER JOIN Lookup14 AS lo14 on gol.Lookup14Id = lo14.Id

SELECT
	  CASE
		WHEN oe_dep.Id IS NULL
			THEN oe_div.Title 
		ELSE oe_dep.Title
	  END
	  AS [Department]
	, m.Title AS [Program Review Name]
	, m.Id AS [Program Review Id]
	, CONCAT(u.FirstName, '' '', u.LastName) AS [Preparer''s Name]
	, sa.Title AS [Status]
	, dbo.ConcatWithSep_Agg(''; '', fn.Need) AS [Future Needs]
	, dbo.ConcatWithSep_Agg(''; '', fn.ongoing) AS [Ongoing Cost]
	, dbo.ConcatWithSep_Agg(''; '', fn.onetime) AS [Onetime Expenditure]
	, SUM(fn.onetime + fn.ongoing) AS [Total Expenses]
	, me1.FloatValue01 AS Prioritization
FROM Module m
	LEFT JOIN GenericOrderedList03 go3 ON go3.ModuleId = m.Id 
	INNER JOIN ModuleDetail md ON md.ModuleId = m.Id
	LEFT JOIN OrganizationEntity oe_dep ON md.Tier2_OrganizationEntityId = oe_dep.Id -- Department
	LEFT JOIN OrganizationEntity oe_div ON md.Tier1_OrganizationEntityId = oe_div.Id -- Division
	INNER JOIN [User] u ON m.UserId = u.Id 
	INNER JOIN StatusAlias sa ON sa.Id = m.StatusAliasId
	INNER JOIN ProposalType pt ON pt.Id = m.ProposalTypeId
	LEFT JOIN ModuleExtension01 AS me1 on me1.ModuleId = m.Id
	INNER JOIN @FutureNEEDS AS	fn on fn.mId = m.Id
WHERE m.ProposalTypeId = 509
	AND pt.ClientEntitySubTypeId = 14
	AND m.Active = 1
	AND m.ModifiedDate BETWEEN @startDate AND @endDate
	group by oe_dep.Id, oe_div.Title , oe_dep.Title, m.Title, m.Id, u.FirstName, u.LastName, sa.Title, me1.FloatValue01
ORDER BY [Department] ASC;
'
WHERE Id = 3