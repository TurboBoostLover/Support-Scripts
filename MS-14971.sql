USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14971';
DECLARE @Comments nvarchar(Max) = 
	'Update Bad look up timing types';
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
DROP TABLE IF EXISTS #Nate;

SELECT
    pt.Title AS [Proposal Type],
    mss.SectionName AS [Section Name],
    msf.DisplayName AS [Field Name],
    mfkcc.Id AS [Look up Id]
INTO #Nate -- Creating a temporary table to store the results
FROM ProposalType AS pt
INNER JOIN MetaTemplateType AS mtt on pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaTemplate AS mt on mt.MetaTemplateTypeId= mtt.MetaTemplateTypeId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
LEFT JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedFieldAttribute AS msfa on msfa.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaForeignKeyCriteriaClient AS mfkcc on msf.MetaForeignKeyLookupSourceId = mfkcc.Id
WHERE mfkcc.LookupLoadTimingType = 2
AND mss.MetaSelectedSectionId in (
    SELECT DISTINCT MetaSelectedSectionId FROM MetaSelectedSectionAttribute WHERE Name = 'FilterSubscriptionTable'
);

UPDATE MetaForeignKeyCriteriaClient
SeT LookupLoadTimingType = 2
WHERE Id in (
	SELECT DISTINCT Id FROM #Nate
)

DROP TABLE #Nate;