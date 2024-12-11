USE [fresno];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14918';
DECLARE @Comments nvarchar(Max) = 
	'Fix Requisites for RAD 40B';
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
DECLARE @ListItemTypeReq INT = (
    SELECT id
    FROM ListItemType
    WHERE ListItemTypeOrdinal = 1
    AND ListItemTableName = ''CourseRequisite''
)

SELECT
    0 AS [Value],
    REPLACE(REPLACE(REPLACE(rs.[Text], ''and<br>'', ''<br>''), ''or<br>'', ''<br>''), ''Require<br>'', ''<br>'') AS [Text]
FROM (
    SELECT
        @entityId AS Value,
        dbo.ConcatWithSepOrdered_Agg(''<br>'', rto.SortOrder, rrq.RenderedRequisite) AS [Text]
    FROM (
        SELECT
            @entityId AS CourseId,
            rt.Id AS RequisiteTypeId,
            rt.Title AS RequisiteType,
            dbo.ConcatWithSepOrdered_Agg(SPACE(1), COALESCE(rqs.SortOrder, 0), COALESCE(rqs.RequisiteRow, ''None'')) AS Requisites
        FROM RequisiteType rt
        LEFT JOIN (
            SELECT
                cr.CourseId AS CourseId,
                cr.RequisiteTypeId,
                CONCAT(
                    s.subjectCode,
                    CASE
                        WHEN s.subjectCode IS NOT NULL THEN CONCAT(SPACE(1), c.coursenumber)
                        ELSE c.coursenumber
                    END,
                    CASE
                        WHEN c.coursenumber IS NOT NULL THEN CONCAT(SPACE(1), cr.CourseRequisiteComment)
                        ELSE cr.CourseRequisiteComment
                    END,
                    CASE
                        WHEN cr.CourseRequisiteComment IS NOT NULL THEN CONCAT(SPACE(1), COALESCE(con3.Title, con.Title))
                        ELSE COALESCE(con3.Title, con.Title)
                    END,
                    con2.Title
                ) AS RequisiteRow,
                ROW_NUMBER() OVER (PARTITION BY cr.CourseId ORDER BY cr.SortOrder, cr.Id) AS SortOrder
            FROM CourseRequisite cr
            LEFT JOIN [Subject] s ON s.id = cr.SubjectId
            LEFT JOIN course c ON c.id = cr.Requisite_CourseId
            LEFT JOIN CourseRequisite cr2 ON CR.Parent_Id = CR2.id
            OUTER APPLY (
                SELECT TOP 1 1 AS id
                FROM CourseRequisite cr3
                WHERE CR.Parent_Id = CR3.Parent_Id
                AND CR3.SortOrder > CR.SortOrder
            ) cr3
            LEFT JOIN Condition con ON con.Id = cr2.GroupConditionId
            AND CR3.id IS NOT NULL
            LEFT JOIN CourseRequisite cr4 ON CR2.Parent_Id = CR4.id
            OUTER APPLY (
                SELECT MAX(SortOrder) AS SortOrder
                FROM CourseRequisite cr5
                WHERE CR2.Parent_Id = CR5.Parent_Id
                AND CR2.SortOrder < CR5.SortOrder
            ) cr5
            LEFT JOIN Condition con2 ON con2.Id = cr4.GroupConditionId
            AND CR3.id IS NULL
            AND CR.ListItemTypeId = @ListItemTypeReq
            AND CR5.SortOrder IS NOT NULL
            LEFT JOIN Condition con3 ON con3.Id = cr.ConditionId
            WHERE cr.courseId = @entityId
        ) rqs ON rt.Id = rqs.RequisiteTypeId
        WHERE rt.Id IN (1, 2, 3, 5)
        GROUP BY rt.Id, rt.Title
    ) rqs
    CROSS APPLY (
        SELECT
            CONCAT(
                rqs.RequisiteType, '': '',
                rqs.Requisites
            ) AS RenderedRequisite
    ) rrq
    CROSS APPLY (
        SELECT
            CASE
                WHEN rqs.RequisiteTypeId = 1 THEN 1
                WHEN rqs.RequisiteTypeId = 2 THEN 2
                WHEN rqs.RequisiteTypeId = 5 THEN 3
                WHEN rqs.RequisiteTypeId = 3 THEN 4
                ELSE -1
            END AS SortOrder
    ) rto
) rs
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 155

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 155
)