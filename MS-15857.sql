USE [delta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15857';
DECLARE @Comments nvarchar(Max) = 
	'Fix COR report';
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
DECLARE @SQL NVARCHAR(MAX) = '
WITH a AS
(
SELECT DISTINCT 
	rt.Title AS RequisiteType, 
	t.Text AS Text
FROM CourseRequisite cr
	INNER JOIN RequisiteType rt ON cr.RequisiteTypeId = rt.Id
	OUTER APPLY
	(
	SELECT 
		dbo.ConcatWithSepOrdered_Agg(
		''<br>'', 
		oa.SortOrder,
		CASE WHEN c.Id IS NOT NULL 
		THEN CONCAT
			(
			s.SubjectCode + '' '' + c.CourseNumber,
			'' '' + ''with a minimum grade of '' + cr2.MinimumGrade,
			'' '' + rv.Title,
			'' '' + con.Title
			)
		ELSE CONCAT(cr2.CommText + '' '', con.Title,'' '' + rv.Title)
		END
		) AS Text
	FROM CourseRequisite cr2 
		LEFT JOIN Course c ON cr2.Requisite_CourseId = c.Id
		LEFT JOIN Subject s ON c.SubjectId = s.Id
		LEFT JOIN Condition con ON cr2.ConditionId = con.Id
		LEFT JOIN RequisiteValidation rv on cr2.RequisiteValidationId01 = rv.Id
		INNER JOIN 
        (
        SELECT 
			ROW_NUMBER() OVER (ORDER BY cr3.SortOrder) AS SortOrder, 
			cr3.Id  
        FROM CourseRequisite cr3
        WHERE CourseId = @entityId
        ) oa ON oa.Id = cr2.Id
	WHERE cr2.RequisiteTypeId = cr.RequisiteTypeId
		AND cr2.CourseId = @entityId 
	) t
WHERE cr.CourseId = @entityId
) 

SELECT 
	0 AS Value,
	CONCAT
		(
		''<label class=''''field-label''''>'', 
		RequisiteType, 
		''</label><br>'', 
		Text
		)
	AS Text
FROM a
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 8688

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MEtaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 8688
)