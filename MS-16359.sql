USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16359';
DECLARE @Comments nvarchar(Max) = 
	'Fix COR styling and add logo';
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
UPDATE MetaReport
SET ReportAttributes = '{"isPublicReport":true,"reportTemplateId":23,"suppressEntityTitleDisplay":true,"heading":"","cssOverride":" label {display: block;} .entry-dates {position: absolute; right: 20px; text-align: right;} #cic {top: 0px;} #last-rev {top: 20px;} #state {top: 40px;} #effterm {top: 60px;} .entry-title {margin-top: -20px; text-align: center;} .report-body .container.meta-section[data-section-id=\"1748\"] .seperator{display:none;} .h1, .h2, .h3 {font-weight: bold;} .bottom-margin-extra-small {padding-bottom: 10px;} .report-body .bottom-margin-normal {margin-bottom: 40px;} .container.container-list .container {margin-left: 10px;} .iq-data-field {margin-bottom: 0.75rem;} .iq-panel[data-section-id=\"1769\"] .iq-data-field-value > div > div {margin-bottom: 0.75rem;}.c-labels-container {padding: 0;} .c-labels {width: 50%; float: left; padding: 0;} #c-title-label {text-align: left;} #c-units-label {text-align: right;} .title-units-container {padding: 0;} .title-units {width: 50%; float: left; padding: 0;  margin-bottom: 0.75rem;} #c-title {text-align: left;} #c-units {text-align: right;} .meta-section > .iq-panel > .iq-panel-children > .iq-panel > .iq-panel-title {font-size: 1.4rem; font-weight: bold;} .iq-panel-children > .iq-panel > .iq-panel-children > .iq-panel > .iq-panel-title {font-size: 1.15rem; font-weight: bold;} "}'
WHERE Id = 493

UPDATE MetaSelectedField
SET LabelVisible = 0
, DisplayName = ''
WHERE MetaSelectedFieldId in (
	SELECT MetaSelectedFieldId FROM MetaSelectedField As msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate As mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType As mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	where mtt.MetaTemplateTypeId = 4
	and msf.MetaAvailableFieldId = 8969
)

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId = 4
)