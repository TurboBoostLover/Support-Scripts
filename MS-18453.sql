USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18453';
DECLARE @Comments nvarchar(Max) = 
	'Correct the backing store for the CIP Code drop down on the ';
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
UPDATE MetaSelectedField
SET MetaAvailableFieldId = 867
WHERE MetaAvailableFieldId = 2467

DECLARE @Table TABLE (ProgramId int, Id int)
INSERT INTO @Table
SELECT DISTINCT p.Id, ccs.Id
FROM Program AS p
INNER JOIN CipCode AS cc on p.CipCodeId = cc.Id
INNER JOIN CipCode_Seeded AS ccs on ccs.Code = cc.Code
WHERE p.CipCodeId IS NOT NULL
and ccs.Active = 1
and p.Active = 1

DELETE FROM @Table WHERE ProgramId in (
	SELECT ProgramId FROM ProgramSeededLookup
)

INSERT INTO ProgramSeededLookup
(ProgramId, CipCode_SeededId)
SELECT ProgramId, Id FROM @Table

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 867