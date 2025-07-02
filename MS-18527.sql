USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18527';
DECLARE @Comments nvarchar(Max) = 
	'Add more to Semester Table';
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
INSERT INTO Semester
(Title, CatalogYear, ClientId, SortOrder, Code, StartDate, TermStartDate, TermEndDate)
VALUES
('Fall 2029 (715) ', '2029', 1, 117, 715, GETDATE(), '2028-07-23 00:00:00.000', '2029-12-01 00:00:00.000'),
('Spring 2030 (720)', '2030', 1, 118, 720, GETDATE(), '2029-12-02 00:00:00.000', '2030-05-04 00:00:00.000'),
('Summer 2030 (725)', '2030', 1, 119, 725, GETDATE(), '2030-05-05 00:00:00.000', '2030-07-20 00:00:00.000')