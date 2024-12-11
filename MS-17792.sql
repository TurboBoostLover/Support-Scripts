USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17792';
DECLARE @Comments nvarchar(Max) = 
	'Ms-17792';
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
UPDATE MetaSelectedSection
SET SectionDescription = 'Course Blocks developed here will be copied over to the programme when the New Programme is created.<br><br>
Approved Course Blocks are also available to add in the program content by using the ''Import Library Block'' option in the +Add. You can select one of the available Course Blocks from the library or build your own blocks by adding courses one at a time. <br><br>
<u>Legend</u><br>
CH: Contact Hours<br>
SWH: Student Work Hours<br>
NLH: Notional Learning Hours (Expected Study Load Hours)<br>
CAT: Credit Allocation Types [CAT A (1:<0.5) or CAT B (1:05) or CAT C (1:1) or CAT C (1:1) or CAT D (1:2) or CAT E (1:>2)]<br><br>'
WHERE MetaBaseSchemaId = 857

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT MetaTemplateId FROM MetaSelectedSection WHERE MetaBaseSchemaId = 857
)