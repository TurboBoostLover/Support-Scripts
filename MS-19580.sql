USE [sbcc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19580';
DECLARE @Comments nvarchar(Max) = 
	'Add look up value';
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
INSERT INTO Designation
(Title, SortOrder, ClientId, StartDate)
VALUES
('Baccalaureate Degree BA/BS', 0, 1, GETDATE())

UPDATE Designation
SET SortOrder =
	CASE 
	WHEN Id = 4 THEN 0
	WHEN Id = 5 THEN 1
	WHEN Id = 6 THEN 2
	WHEN Id = 7 THEN 3
	WHEN Id = 8 THEN 4
	WHEN Id = 9 THEN 5
	WHEN Id = 10 THEN 6
	WHEN Id = 11 THEN 7
	WHEN Id = 12 THEN 8
	WHEN Id = 13 THEN 9
	WHEN Id = 14 THEN 10
	WHEN Id = 1 THEN 100 --inactive
	WHEN Id = 2 THEN 101 --inactive
	WHEN Id = 3 THEN 102 --inactive
	ELSE SortOrder
	END
WHERE Id = 4

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 231