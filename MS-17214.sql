USE [sjcc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17214';
DECLARE @Comments nvarchar(Max) = 
	'Change out picklist';
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
SET MetaAvailableFieldId = 13330
WHERE MetaAvailableFieldId = 2883

INSERT INTO AchievementCategory
(Title, SortOrder, ClientId, StartDate, EndDate)
VALUES
('Skill Demonstration', 0, 49,GETDATE(), GETDATE()),
('C - Career Technical', 1, 49,GETDATE(), NULL),
('T - Transfer', 2, 49,GETDATE(), NULL),
('CT - Career Technical and Transfer', 3, 49,GETDATE(), NULL),
('O - Other - Designed to Meet Community Needs', 4, 49,GETDATE(), NULL)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 3318
WHERE MetaAvailableFieldId = 2916

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 3319
WHERE MetaAvailableFieldId = 2917

exec EntityExpand @clientId =49 , @entityTypeId =6

DECLARE @Achievement TABLE (PRogramId int, PickListAchievementCategoryId int)
INSERT INTO @Achievement
SELECT ProgramId, PickListAchievementCategoryId FROM PickListOneToOne WHERE ProgramId IS NOT NULL and PickListAchievementCategoryId IS NOT NULL

UPDATE Program
SET AchievementCategoryId = 
CASE
WHEN plo.PickListAchievementCategoryId = 7 THEN (SELECT Id FROM AchievementCategory WHERE Title = 'Skill Demonstration')
WHEN plo.PickListAchievementCategoryId = 10000001 THEN (SELECT Id FROM AchievementCategory WHERE Title = 'C - Career Technical')
WHEN plo.PickListAchievementCategoryId = 10000002 THEN (SELECT Id FROM AchievementCategory WHERE Title = 'T - Transfer')
WHEN plo.PickListAchievementCategoryId = 10000003 THEN (SELECT Id FROM AchievementCategory WHERE Title = 'CT - Career Technical and Transfer')
WHEN plo.PickListAchievementCategoryId = 10000004 THEN (SELECT Id FROM AchievementCategory WHERE Title = 'O - Other - Designed to Meet Community Needs')
ELSE NULL
END
FROM Program AS p
INNER JOIN @Achievement AS plo on plo.PRogramId = p.Id

DECLARE @yes TABLE (PRogramId int, PickListYes_No01Id int)
INSERT INTO @yes
SELECT ProgramId, PickListYes_No01Id FROM PickListOneToOne WHERE ProgramId IS NOT NULL and PickListYes_No01Id IS NOT NULL

UPDATE pyn
SET YesNo02Id = CASE 
WHEN PickListYes_No01Id = 97 THEN 1
WHEN PickListYes_No01Id = 98 THEN 2
WHEN PickListYes_No01Id = 276 THEN 3
ELSE NULL
END
FROM Program AS p
INNER JOIN ProgramYesNo AS pyn on pyn.ProgramId = p.Id
INNER JOIN @yes AS y on y.PRogramId = p.Id

DECLARE @no TABLE (PRogramId int, PickListYes_No02Id int)
INSERT INTO @no
SELECT ProgramId, PickListYes_No02Id FROM PickListOneToOne WHERE ProgramId IS NOT NULL and PickListYes_No02Id IS NOT NULL

UPDATE pyn
SET YesNo03Id = CASE 
WHEN PickListYes_No02Id = 202 THEN 1
WHEN PickListYes_No02Id = 203 THEN 2
WHEN PickListYes_No02Id = 277 THEN 3
ELSE NULL
END
FROM Program AS p
INNER JOIN ProgramYesNo AS pyn on pyn.ProgramId = p.Id
INNER JOIN @no AS y on y.PRogramId = p.Id


UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaAvailableFieldId in (
		3318, 3319, 13330
	)
)