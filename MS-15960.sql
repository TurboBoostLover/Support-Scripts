use sdccd 

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15960';
DECLARE @Comments nvarchar(Max) = 'When course were imported, some did not have a created on date.  These were set to the date of import.  However, this has caused problems with some courses where a historical version has a more recent created on date than the current draft version.  I am pushing back this auto set date a bit to resolve the issue.';
DECLARE @Developer nvarchar(50) = 'Nate W';
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
Please do not alter the script above this comment�except to set
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
update Course set CreatedOn = '2023-01-01' where CreatedOn between '2023-12-27' and '2023-12-28'