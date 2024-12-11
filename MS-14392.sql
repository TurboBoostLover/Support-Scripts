USE [evc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14392';
DECLARE @Comments nvarchar(Max) = 
	'adhoc report';
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
INSERT INTO AdHocReport
(ClientId, Title, Definition, OutputFormatId, IsPublic, Active)
VALUES
(22, 'SAO Assessments', '{"id":0,"modelId":"9114741f-cfe6-4d46-8060-c30fc2f293a5","modelName":"ApprovalProcess","modelVersion":49,"title":"SAO Assessments","description":"","outputFormatId":1,"isPublic":false,"columns":[{"caption":"Module Title","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Module.Title"}},{"caption":"Department","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"Tier2OrganizationEntity_ModuleDetail_Module.Title"}},{"caption":"Outcome","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"ModuleExtension02_Module.TextMax04"}},{"caption":"Status","sorting":"None","sortIndex":-1,"expr":{"typeName":"ENTATTR","id":"StatusAliasId_StatusAlias_Module.StatusAliasTitle"}}],"justsorted":[],"root":{"linkType":"All","enabled":true,"conditions":[{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"IsTrue","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"Module.Active"}]},{"justAdded":false,"typeName":"SMPL","enabled":true,"operatorID":"Contains","expressions":[{"kind":"Attribute","typeName":"ENTATTR","id":"ProposalType_Module.Title"},{"typeName":"CONST","dataType":"String","kind":"Scalar","value":"(SAO) Report","text":"(SAO) Report"}]}]}}', 1, 0, 1)