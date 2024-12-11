USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17701';
DECLARE @Comments nvarchar(Max) = 
	'Ensure all MetaTemplateTypes are mapped to all reports';
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
INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
VALUES
(4, 12, GETDATE()),
(43, 12, GETDATE()),
(0, 12, GETDATE()),
(476, 12, GETDATE()),
(258, 12, GETDATE()),
(516, 12, GETDATE()),
(4, 13, GETDATE()),
(43, 13, GETDATE()),
(0, 13, GETDATE()),
(476, 13, GETDATE()),
(258, 13, GETDATE()),
(516, 13, GETDATE()),
(4, 14, GETDATE()),
(43, 14, GETDATE()),
(0, 14, GETDATE()),
(476, 14, GETDATE()),
(258, 14, GETDATE()),
(516, 14, GETDATE()),
(4, 17, GETDATE()),
(43, 17, GETDATE()),
(0, 17, GETDATE()),
(476, 17, GETDATE()),
(258, 17, GETDATE()),
(516, 17, GETDATE()),
(4, 22, GETDATE()),
(43, 22, GETDATE()),
(0, 22, GETDATE()),
(476, 22, GETDATE()),
(258, 22, GETDATE()),
(516, 22, GETDATE()),
(44, 23, GETDATE()),
(57, 23, GETDATE()),
(259, 23, GETDATE()),
(474, 23, GETDATE()),
(477, 23, GETDATE())