USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19642';
DECLARE @Comments nvarchar(Max) = 
	'Update URL link in field label';
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
DECLARE @Fields INTEGERS

UPDATE MetaSelectedFieldAttribute
SET Value = 'Vision for Success Link:  <a href="https://www.cccco.edu/-/media/CCCCO-Website/Files/Workforce-and-Economic-Development/RFAs/19-300-001/appendix-d-vision-for-success-a11y.pdf?la=en&hash=984F535C5349C3E1EAF6857DCF7D7B73C9288BCE">https://www.cccco.edu/-/media/CCCCO-Website/Files/Workforce-and-Economic-Development/RFAs/19-300-001/appendix-d-vision-for-success-a11y.pdf?la=en&hash=984F535C5349C3E1EAF6857DCF7D7B73C9288BCE</a> Work with Dean to identify how the Program fits into AHC and the State How does it align with the mission, curriculum, and master planning of the college and higher education in California. Does it provide a valid transfer, basic skills, or skilled workforce need? Refer to Institutional Planning & Shared Governance.'
output inserted.MetaSelectedFieldId INTO @Fields
WHERE Name = 'helptext'
and Value like '%https://www.cccco.edu/About-Us/Vision-for-Success%'

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN @Fields AS f on msf.MetaSelectedFieldId = f.Id