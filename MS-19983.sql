USE [madera];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19983';
DECLARE @Comments nvarchar(Max) = 
	'Turn on public search, public reports';
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
exec upGetUpdateClientSetting @setting = 'AllowAnonymousAllFieldsReport', @newValue = 1, @clientId = 1, @valuedatatype = 'bit', @section = 'Reports'
exec upGetUpdateClientSetting @setting = 'PublicSearch', @newValue = 1, @clientId = 1, @valuedatatype = 'bit', @section = 'Curriqunet'

INSERT INTO Search.SavedSearches
(Name, Config)
VALUES
('Course', '{"rules":null,"displayColumns":[{"id":"field-check-field-888-2","location":"1"},{"id":"field-check-field-872-3","location":"1"},{"id":"field-check-field-873-1","location":"1"},{"id":"field-check-field-ProposalType-1","location":"1"},{"id":"field-check-field-status-1","location":"1"}],"filterByUser":false,"keyword":"","searchName":"","userId":2,"clientEntityTypeId":1,"clientEntitySubTypeId":null,"clientIds":[1],"entityId":1,"sortOptions":[],"sortAscendingFlag":"1","isDefaultSearchForClientEntityType":false,"isPublicSearchForClientEntityType":true,"publicSearchClientId":1,"campusIds":[],"mode":"basic"}'),
('Program', '{"rules":null,"displayColumns":[{"id":"field-check-field-2537-5","location":"1"},{"id":"field-check-field-1100-6","location":"1"},{"id":"field-check-field-1225-7","location":"1"},{"id":"field-check-field-ProposalType-1","location":"1"},{"id":"field-check-field-status-1","location":"1"}],"filterByUser":false,"keyword":"","searchName":"","userId":2,"clientEntityTypeId":2,"clientEntitySubTypeId":null,"clientIds":[1],"entityId":2,"sortOptions":[],"sortAscendingFlag":"1","isDefaultSearchForClientEntityType":false,"isPublicSearchForClientEntityType":true,"publicSearchClientId":1,"campusIds":[],"mode":"basic"}')

UPDATE ClientEntityType
SET PublicSearchVisible = 1
WHERE Id in (
1, 2
)

UPDATE ClientEntityType
SET PublicSearchVisible = 0
WHERE Id in (
3, 5
)

UPDATE MetaReport
SET ReportAttributes = '{"fieldRenderingStrategy":"HideEmptyFields","sectionRenderingStrategy":"HideEmptySections","suppressEntityTitleDisplay":"true","heading":"Course Outline of Record","isPublicReport":true,"reportTemplateId":7,"cssOverride":".report-body .container.meta-section:nth-child(1) .seperator {visibility: hidden;} .iq-panel-title{font-size: 1.3rem;} div[data-available-field-id=\"8986\"] .querytext-result-row.display-inline-block,div[data-available-field-id=\"8987\"] .querytext-result-row.display-inline-block,div[data-available-field-id=\"8996\"] .querytext-result-row.display-inline-block{display: contents;} div[data-section-id=\"324\"]{page-break-before: always;} .field-label{display: inline;} .section-description{font-weight:500; font-size: 1rem;};}"}'
WHERE Id = 504

UPDATE MetaReport
SET ReportAttributes = '{"fieldRenderingStrategy":"HideEmptyFields","sectionRenderingStrategy":"HideEmptySections","suppressEntityTitleDisplay":"true","isPublicReport":true,"reportTemplateId":19,"cssOverride":".report-body .container.meta-section:nth-child(1) .seperator {visibility: hidden;} .iq-panel-title{font-size: 1.3rem;} .field-label{display: inline;}"}'
WHERE Id = 510

UPDATE MetaReport
SET ReportAttributes = '{"fieldRenderingStrategy":"HideEmptyFields","sectionRenderingStrategy":"HideEmptySections","suppressEntityTitleDisplay":"true","isPublicReport":true,"reportTemplateId":20,"cssOverride":".report-body .container.meta-section:nth-child(1) .seperator {visibility: hidden;} .iq-panel-title{font-size: 1.3rem;} .field-label{display: inline;}"}'
WHERE Id = 511

UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":"true","reportTemplateId":12}'
WHERE Id = 506