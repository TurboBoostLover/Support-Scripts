USE [gavilan];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19697';
DECLARE @Comments nvarchar(Max) = 
	'Update SAO Form to pull in the correct divisions';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DROP TABLE IF EXISTS #Table

CREATE TABLE #TABLE (Value int, Text NVARCHAR(MAX))
INSERT INTO #TABLE
exec uspOrganizationGetByUserAndTierOrder @clientId, @userId, 1,''Module'', @EntityId,''Module'',''Tier2_OrganizationEntityId''

SELECT Id AS Value, Text FROM #TABLE AS t
INNER JOIN OrganizationEntity AS oe on oe.Id = t.Value
WHERE oe.OrganizationTierId = 107
and oe.Code IS NULL
'
WHERE Id = 34

UPDATE OrganizationEntityOutcome
SET OrganizationEntityId = CASE
	WHEN OrganizationEntityId = 4998 THEN 4969
	WHEN OrganizationEntityId = 4999 THEN 5069
	WHEN OrganizationEntityId = 5001 THEN 5071
	WHEN OrganizationEntityId = 5002 THEN 5072
	WHEN OrganizationEntityId = 5005 THEN 5073
	WHEN OrganizationEntityId = 5006 THEN 5062
	WHEN OrganizationEntityId = 5007 THEN 5075
	WHEN OrganizationEntityId = 5008 THEN 5076
	WHEN OrganizationEntityId = 5010 THEN 5148
	WHEN OrganizationEntityId = 5011 THEN 4977
	WHEN OrganizationEntityId = 5012 THEN 5101
	WHEN OrganizationEntityId = 5013 THEN 5079
	WHEN OrganizationEntityId = 5014 THEN 5080
	WHEN OrganizationEntityId = 5016 THEN 5081
	WHEN OrganizationEntityId = 5018 THEN 5082
	WHEN OrganizationEntityId = 5020 THEN 5065
	WHEN OrganizationEntityId = 5021 THEN 5143
	WHEN OrganizationEntityId = 5022 THEN 5066
	WHEN OrganizationEntityId = 5023 THEN 5084
	WHEN OrganizationEntityId = 5025 THEN 5117
	WHEN OrganizationEntityId = 5028 THEN 5078
	WHEN OrganizationEntityId = 5036 THEN 5037
	WHEN OrganizationEntityId = 5040 THEN 5055
	WHEN OrganizationEntityId = 5042 THEN 5057
	WHEN OrganizationEntityId = 5043 THEN 5058
	WHEN OrganizationEntityId = 5044 THEN 5059
	WHEN OrganizationEntityId = 5047 THEN 5087
	WHEN OrganizationEntityId = 5048 THEN 5088
	ELSE NULL
END

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 34 or mt.MetaTemplateTypeId = 530