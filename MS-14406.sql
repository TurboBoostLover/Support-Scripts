USE [evc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14406';
DECLARE @Comments nvarchar(Max) = 
	'New Admin Report';
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
DECLARE @adminReportId INT;
DECLARE @SQL NVARCHAR(MAX) = '
SELECT 
OutcomeText AS [Outcome],
oe2.Title AS [Division],
oe.Title AS [Department],
p.LaunchDate AS [Launch Date],
CASE
	WHEN p.LaunchDate IS NULL
		THEN ''Not Assessed''
		ELSE ''Assessed''
End AS [Assessed or Not]
FROM OrganizationLevelOutcome AS OLO
INNER JOIN OrganizationEntity AS oe on olo.OrganizationEntityId = oe.Id
INNER JOIN OrganizationLink AS ol on ol.Child_OrganizationEntityId = oe.Id
INNER JOIN OrganizationEntity AS oe2 on ol.Parent_OrganizationEntityId = oe2.Id
LEFT JOIN ModuleOrganizationLevelOutcome AS molo on molo.OrganizationLevelOutcomeId = olo.Id
LEFT JOIN Module AS m on molo.ModuleId = m.Id
LEFT JOIN Proposal AS p on m.ProposalId = p.Id
WHERE olo.Active = 1
UNION
SELECT DISTINCT
OutcomeText AS [Outcome],
oe2.Title AS [Division],
oe.Title AS [Department],
NULL AS [Launch Date],
''Not Assessed'' AS [Assessed or Not]
FROM OrganizationLevelOutcome AS OLO
INNER JOIN OrganizationSubject AS os on olo.SubjectId = os.SubjectId
INNER JOIN OrganizationEntity AS oe on  os.OrganizationEntityId = oe.Id
INNER JOIN OrganizationLink AS ol on ol.Child_OrganizationEntityId = oe.Id
INNER JOIN OrganizationEntity AS oe2 on ol.Parent_OrganizationEntityId = oe2.Id
LEFT JOIN ModuleOrganizationLevelOutcome AS molo on molo.OrganizationLevelOutcomeId = olo.Id
WHERE olo.Active = 1
and outcometext not in (
SELECT DISTINCT
OutcomeText
FROM OrganizationLevelOutcome AS OLO
INNER JOIN OrganizationSubject AS os on olo.SubjectId = os.SubjectId
INNER JOIN OrganizationEntity AS oe on  os.OrganizationEntityId = oe.Id
INNER JOIN OrganizationLink AS ol on ol.Child_OrganizationEntityId = oe.Id
INNER JOIN OrganizationEntity AS oe2 on ol.Parent_OrganizationEntityId = oe2.Id
INNER JOIN ModuleOrganizationLevelOutcome AS molo on molo.OrganizationLevelOutcomeId = olo.Id
INNER JOIN Module AS m on molo.ModuleId = m.Id
INNER JOIN Proposal AS p on m.ProposalId = p.Id
WHERE olo.Active = 1
)
UNION
SELECT DISTINCT
OutcomeText AS [Outcome],
oe2.Title AS [Division],
oe.Title AS [Department],
p.LaunchDate AS [Launch Date],
CASE
	WHEN p.LaunchDate IS NULL
		THEN ''Not Assessed''
		ELSE ''Assessed''
End AS [Assessed or Not]
FROM OrganizationLevelOutcome AS OLO
INNER JOIN OrganizationSubject AS os on olo.SubjectId = os.SubjectId
INNER JOIN OrganizationEntity AS oe on  os.OrganizationEntityId = oe.Id
INNER JOIN OrganizationLink AS ol on ol.Child_OrganizationEntityId = oe.Id
INNER JOIN OrganizationEntity AS oe2 on ol.Parent_OrganizationEntityId = oe2.Id
INNER JOIN ModuleOrganizationLevelOutcome AS molo on molo.OrganizationLevelOutcomeId = olo.Id
INNER JOIN Module AS m on molo.ModuleId = m.Id
INNER JOIN Proposal AS p on m.ProposalId = p.Id
WHERE olo.Active = 1
ORDER By oe2.Title, oe.Title, OutcomeText
'

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('SAO Assessments', @sql, 1, 1)
SET @adminReportId = SCOPE_IDENTITY ()


INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 22)