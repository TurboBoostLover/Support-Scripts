USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16975';
DECLARE @Comments nvarchar(Max) = 
	'Remove bad show hide';
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
Please do not alter the script above this comment� except to set
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
DECLARE @Sections INTEGERS
INSERT INTO @Sections
SELECT MetaSelectedSectionId FROM MetaSelectedSection WHERE SectionName = '2-Year Enrollment Data' and MetaBaseSchemaId = 164
UNION
SELECT MetaSelectedSection_MetaSelectedSectionId FROM MetaSelectedSection WHERE SectionName = '2-Year Enrollment Data' and MetaBaseSchemaId = 164

DELETE FROM MetaDisplaySubscriber
WHERE MetaSelectedSectionId in (
	SELECT Id FROM @Sections
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
wHERE MetaTemplateId in (
SELECT MetaTemplateId FROM MetaSelectedSection WHERE SectionName = '2-Year Enrollment Data' and MetaBaseSchemaId = 164
)