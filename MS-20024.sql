USE [ccsf];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-20024';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text for requisites';
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
DECLARE @Id int = 55

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @Pre NVARCHAR(MAX) = (SELECT STRING_AGG(CASE WHEN c.ID IS NOT NULL THEN CONCAT(sc.Code,s.SubjectCode, '' '', c.CourseNumber, sc2.Code, '' '', cc.Title)ELSE CONCAT(sc.Code,CR.CourseRequisiteComment, sc2.Code, '' '', cc.Title) END, '' '') WITHIN GROUP (Order BY cr.SortOrder, cr.Id) FROM CourseRequisite AS cr Left Join Course As c on cr.Requisite_CourseId = c.Id LEFT JOIN Subject AS s on c.SubjectId = s.Id LEFT JOIN Condition As cc on cr.ConditionId = cc.Id LEFT JOIN SpecialCharacter AS sc on cr.OpenParen_SpecialCharacterId = sc.Id LEFT JOIN SpecialCharacter AS sc2 on cr.CloseParen_SpecialCharacterId = sc2.Id WHERE cr.CourseId = @EntityId and cr.RequisiteTypeId = 378)

DECLARE @Cor NVARCHAR(MAX) = (SELECT STRING_AGG(CASE WHEN c.ID IS NOT NULL THEN CONCAT(sc.Code,s.SubjectCode, '' '', c.CourseNumber, sc2.Code, '' '', cc.Title)ELSE CONCAT(sc.Code,CR.CourseRequisiteComment, sc2.Code, '' '', cc.Title) END, '' '') WITHIN GROUP (Order BY cr.SortOrder, cr.Id) FROM CourseRequisite AS cr Left Join Course As c on cr.Requisite_CourseId = c.Id LEFT JOIN Subject AS s on c.SubjectId = s.Id LEFT JOIN Condition As cc on cr.ConditionId = cc.Id LEFT JOIN SpecialCharacter AS sc on cr.OpenParen_SpecialCharacterId = sc.Id LEFT JOIN SpecialCharacter AS sc2 on cr.CloseParen_SpecialCharacterId = sc2.Id WHERE cr.CourseId = @EntityId and cr.RequisiteTypeId = 379)

DECLARE @PreCor NVARCHAR(MAX) = (SELECT STRING_AGG(CASE WHEN c.ID IS NOT NULL THEN CONCAT(sc.Code,s.SubjectCode, '' '', c.CourseNumber, sc2.Code, '' '', cc.Title)ELSE CONCAT(sc.Code,CR.CourseRequisiteComment, sc2.Code, '' '', cc.Title) END, '' '') WITHIN GROUP (Order BY cr.SortOrder, cr.Id) FROM CourseRequisite AS cr Left Join Course As c on cr.Requisite_CourseId = c.Id LEFT JOIN Subject AS s on c.SubjectId = s.Id LEFT JOIN Condition As cc on cr.ConditionId = cc.Id LEFT JOIN SpecialCharacter AS sc on cr.OpenParen_SpecialCharacterId = sc.Id LEFT JOIN SpecialCharacter AS sc2 on cr.CloseParen_SpecialCharacterId = sc2.Id WHERE cr.CourseId = @EntityId and cr.RequisiteTypeId = 381)

DECLARE @Adv NVARCHAR(MAX) = (SELECT STRING_AGG(CASE WHEN c.ID IS NOT NULL THEN CONCAT(sc.Code,s.SubjectCode, '' '', c.CourseNumber, sc2.Code, '' '', cc.Title)ELSE CONCAT(sc.Code,CR.CourseRequisiteComment, sc2.Code, '' '', cc.Title) END, '' '') WITHIN GROUP (Order BY cr.SortOrder, cr.Id) FROM CourseRequisite AS cr Left Join Course As c on cr.Requisite_CourseId = c.Id LEFT JOIN Subject AS s on c.SubjectId = s.Id LEFT JOIN Condition As cc on cr.ConditionId = cc.Id LEFT JOIN SpecialCharacter AS sc on cr.OpenParen_SpecialCharacterId = sc.Id LEFT JOIN SpecialCharacter AS sc2 on cr.CloseParen_SpecialCharacterId = sc2.Id WHERE cr.CourseId = @EntityId and cr.RequisiteTypeId = 380)

DECLARE @AdvPreCor NVARCHAR(MAX) = (SELECT STRING_AGG(CASE WHEN c.ID IS NOT NULL THEN CONCAT(sc.Code,s.SubjectCode, '' '', c.CourseNumber, sc2.Code, '' '', cc.Title)ELSE CONCAT(sc.Code,CR.CourseRequisiteComment, sc2.Code, '' '', cc.Title) END, '' '') WITHIN GROUP (Order BY cr.SortOrder, cr.Id) FROM CourseRequisite AS cr Left Join Course As c on cr.Requisite_CourseId = c.Id LEFT JOIN Subject AS s on c.SubjectId = s.Id LEFT JOIN Condition As cc on cr.ConditionId = cc.Id LEFT JOIN SpecialCharacter AS sc on cr.OpenParen_SpecialCharacterId = sc.Id LEFT JOIN SpecialCharacter AS sc2 on cr.CloseParen_SpecialCharacterId = sc2.Id WHERE cr.CourseId = @EntityId and cr.RequisiteTypeId = 383)

SELECT 0 AS Value,
CONCAT(
''Prerequisite: '', CASE WHEN @Pre IS NULL THEN ''None'' else @Pre END,
''<br>'',
''Corequisite: '', CASE WHEN @Cor IS NULL THEN ''None'' else @Cor END,
''<br>'',
''Pre/Corequisite: '', CASE WHEN @PreCor IS NULL THEN ''None'' else @PreCor END,
''<br>'',
''Advisory: '', CASE WHEN @Adv IS NULL THEN ''None'' else @Adv END,
''<br>'',
''Advisory Pre/Corequisite: '', CASE WHEN @AdvPreCor IS NULL THEN ''None'' else @AdvPreCor END
) AS Text
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id