USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15312';
DECLARE @Comments nvarchar(Max) = 
	'Update Workflows';
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
DECLARE @userId int = 618

DECLARE @Proposals INTEGERS
INSERT INTO @Proposals
SELECT ProposalId FROM Module
WHERE Active = 1
AND StatusAliasId = 6
AND ClientId = 2
AND MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId in (
		41, 42
	)
)

EXEC upRemoveProposal @Proposals, @userId, 1

UPDATE Module
SET ProposalTypeId =
CASE WHEN ProposalTypeId = 55
THEN 64
WHEN ProposalTypeId = 56
THEN 65
ELSE ProposalTypeId
END
WHERE Id in (
	SELECT Id FROM Module
	WHERE Active = 1
	AND MetaTemplateId in (
		SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
		INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
		WHERE mtt.MetaTemplateTypeId in (
			41, 42
		)
	)
)

UPDATE Module 
SET Active = 0
WHERE Active = 1
AND Title = 'Test'
AND MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId in (
		41, 42
	)
)