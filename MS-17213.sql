USE [mdc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17213';
DECLARE @Comments nvarchar(Max) = 
	'Move data for DST-5038';
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
SELECT DISTINCT mtt.EntityTypeId, msf.MetaForeignKeyLookupSourceId, msf.DisplayName, mss2.SectionName FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE MetaAvailableFieldId in (2916, 2917, 2941)

--SELECT * FROM Client

--SELECT * FROM MetaSelectedField WHERE MetaAvailableFieldId in (2916)
--SELECT * FROM MetaAvailableField WHERE MetaAvailableFieldId in (2916)
--SELECT * FROM MetaForeignKeyCriteriaBase WHERE Id in (242, 243)

--SELECT * FROM Program

DECLARE @Templates INTEGERS
INSERT INTO @Templates
SELECT DISTINCT mss.MetaTemplateId FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
WHERE MetaAvailableFieldId in (2916, 2917, 2941)

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 3393
WHERE MetaAvailableFieldId = 2916

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 3394
WHERE MetaAvailableFieldId = 2917

UPDATE MetaSelectedField
SET MetaAvailableFieldId = 13331
WHERE MetaAvailableFieldId = 2941

--SELECT * FROM MetaAvailableField WHERE MetaAvailableFieldId in (13331)

UPDATE CourseYesNo
SET YesNo17Id = CASE WHEN p.PickListYes_No01Id = 97 THEN 1 WHEN p.PickListYes_No01Id = 98 THEN 2 WHEN p.PickListYes_No01Id = 276 THEN 3 ELSE NULL END,
YesNo18Id = CASE WHEN p.PickListYes_No01Id = 97 THEN 1 WHEN p.PickListYes_No01Id = 98 THEN 2 WHEN p.PickListYes_No01Id = 276 THEN 3 ELSE NULL END
FROM CourseYesNo AS cyn
INNER JOIN Course AS c on cyn.CoursemId = c.Id
INNER JOIN PickListOneToOne as p on p.CourseId = c.Id
WHERE p.CourseId IS NOT NULL

DELETE FROM PickListOneToOne
WHERE CourseId IS NOT NULL

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Id FROM @Templates
)

--SELECT PickListYes_No01Id, PickListYes_No02Id, * FROM PickListOneToOne
--WHERE ProgramId IS NOT NULL