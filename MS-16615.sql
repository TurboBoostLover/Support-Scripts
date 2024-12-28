use [sac]; 

/*
   Commit



	 Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16615';
DECLARE @Comments nvarchar(Max) = 'Adding some CB code subscriptions';
DECLARE @Developer nvarchar(50) = 'Nate W.';
DECLARE @ScriptTypeId int = 1; 
/*  
Default for @ScriptTypeId on this script 
is 1 for  Support,  
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

/*
--------------------------------------------------------------------
Please do not alter the script above this comment?except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing something 
		 that is against meta best practices, but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the 
		 word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql
-----------------Script details go below this line------------------
*/
Insert into MetaSelectedFieldAttribute (Name, Value, MetaSelectedFieldId)
SELECT
	'subscription',
	msf2.MetaSelectedFieldId,
	msf.MetaSelectedFieldId
FROM MetaSelectedField msf
	inner join MetaSelectedSection mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	inner join MetaSelectedSection mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
	inner join MetaSelectedField msf2 on mss2.MetaSelectedSectionId = msf2.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2579 --CB26
	and msf2.MetaAvailableFieldId = 1004 --CB08
Union
SELECT
	'subscription',
	msf2.MetaSelectedFieldId,
	msf.MetaSelectedFieldId
FROM MetaSelectedField msf
	inner join MetaSelectedSection mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	inner join MetaSelectedSection mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
	inner join MetaSelectedField msf2 on mss2.MetaSelectedSectionId = msf2.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 2579 --CB26
	and msf2.MetaAvailableFieldId = 1010 --CB22
Union
SELECT
	'subscription',
	msf2.MetaSelectedFieldId,
	msf.MetaSelectedFieldId
FROM MetaSelectedField msf
	inner join MetaSelectedSection mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	inner join MetaSelectedSection mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
	inner join MetaSelectedField msf2 on mss2.MetaSelectedSectionId = msf2.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 1004 --CB08
	and msf2.MetaAvailableFieldId = 2579 --CB26

Update MetaTemplate
set LastUpdatedDate = GETDATE()
FRom MetaTemplate mt
	inner join MetaSelectedSection mss on mss.MetaTemplateId = mt.MetaTemplateId
	inner join MetaSelectedField msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId in (1004, 1010, 2579)


