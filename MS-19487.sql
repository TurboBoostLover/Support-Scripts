USE [madera];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19487';
DECLARE @Comments nvarchar(Max) = 
	'Fix Bad Queries that are breaking the system to to concatwithsep';
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
DECLARE @Id int = 132

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @Textbook2 TABLE (CourseId int, txt NVARCHAR(MAX));
INSERT INTO @Textbook2
SELECT CourseId,
       STRING_AGG(Title, ''<br>'') WITHIN GROUP (ORDER BY SortOrder, Id)
FROM CourseTextbook AS ct
WHERE ct.CourseId = @EntityId
GROUP BY CourseId;


SELECT 0 AS Value,
       CONCAT(''Textbooks Part - 1 <br>'', gmt.TextMax06, ''<br>'',
              ''Textbooks Part - 2 <br>'', t2.txt) AS Text
FROM Course AS c
LEFT JOIN @Textbook2 AS t2 ON t2.CourseId = c.Id
LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
WHERE c.Id = @EntityId;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

SET @Id = 90

SET @SQL = '
DECLARE @text NVARCHAR(MAX) = '''';

/**********************************************************************
 * Prerequisite
 **********************************************************************/
SET @text += COALESCE((
    SELECT CASE WHEN COUNT(cr.Id) > 0 THEN
        CONCAT(''<b>Prerequisite:</b> '',
            STRING_AGG(
                CONCAT(s.SubjectCode, '' '', c.CourseNumber, '' '', c.Title,
                    CASE WHEN cr.ConditionId IS NOT NULL THEN CONCAT('' '', con.Title) ELSE '''' END),
                '' ''
            ) WITHIN GROUP (ORDER BY cr.SortOrder, cr.Id)
        )
    END + ''; <br>''
    FROM CourseRequisite cr
    INNER JOIN RequisiteType rt ON rt.Id = cr.RequisiteTypeId
    INNER JOIN Subject s ON s.Id = cr.SubjectId
    INNER JOIN Course c ON c.Id = cr.Requisite_CourseId
    LEFT JOIN Condition con ON con.Id = cr.ConditionId
    WHERE rt.Id = 1 AND cr.CourseId = @entityId
), '''');

/**********************************************************************
 * Corequisite
 **********************************************************************/
SET @text += COALESCE((
    SELECT CASE WHEN COUNT(cr.Id) > 0 THEN
        CONCAT(''<b>Corequisite:</b> '',
            STRING_AGG(
                CONCAT(s.SubjectCode, '' '', c.CourseNumber, '' '', c.Title,
                    CASE WHEN cr.ConditionId IS NOT NULL THEN CONCAT('' '', con.Title) ELSE '''' END),
                '' ''
            ) WITHIN GROUP (ORDER BY cr.SortOrder, cr.Id)
        )
    END + ''; <br>''
    FROM CourseRequisite cr
    INNER JOIN RequisiteType rt ON rt.Id = cr.RequisiteTypeId
    INNER JOIN Subject s ON s.Id = cr.SubjectId
    INNER JOIN Course c ON c.Id = cr.Requisite_CourseId
    LEFT JOIN Condition con ON con.Id = cr.ConditionId
    WHERE rt.Id = 2 AND cr.CourseId = @entityId
), '''');

/**********************************************************************
 * Advisory
 **********************************************************************/
SET @text += COALESCE((
    SELECT CASE WHEN COUNT(cr.Id) > 0 THEN
        CONCAT(''<b>Advisory:</b> '',
            STRING_AGG(
                CONCAT(s.SubjectCode, '' '', c.CourseNumber, '' '', c.Title,
                    CASE WHEN cr.ConditionId IS NOT NULL THEN CONCAT('' '', con.Title) ELSE '''' END),
                '' ''
            ) WITHIN GROUP (ORDER BY cr.SortOrder, cr.Id)
        )
    END + ''; <br>''
    FROM CourseRequisite cr
    INNER JOIN RequisiteType rt ON rt.Id = cr.RequisiteTypeId
    INNER JOIN Subject s ON s.Id = cr.SubjectId
    INNER JOIN Course c ON c.Id = cr.Requisite_CourseId
    LEFT JOIN Condition con ON con.Id = cr.ConditionId
    WHERE rt.Id = 3 AND cr.CourseId = @entityId
), '''');

/**********************************************************************
 * Limitations on Enrollment
 **********************************************************************/
SET @text += COALESCE((
    SELECT CASE WHEN COUNT(cr.Id) > 0 THEN
        CONCAT(''<b>Limitations on Enrollment:</b> '',
            STRING_AGG(
                CONCAT(cr.Description,
                    CASE WHEN cr.ConditionId IS NOT NULL THEN CONCAT('' '', con.Title) ELSE '''' END),
                '' ''
            ) WITHIN GROUP (ORDER BY cr.SortOrder, cr.Id)
        )
    END + ''; <br>''
    FROM CourseRequisite cr
    INNER JOIN RequisiteType rt ON rt.Id = cr.RequisiteTypeId
    LEFT JOIN Condition con ON con.Id = cr.ConditionId
    WHERE rt.Id = 4 AND cr.CourseId = @entityId
), '''');

/**********************************************************************
 * Anti-Requisite
 **********************************************************************/
SET @text += COALESCE((
    SELECT CASE WHEN COUNT(cr.Id) > 0 THEN
        CONCAT(''<b>Anti-Requisite:</b> '',
            STRING_AGG(
                CONCAT(s.SubjectCode, '' '', c.CourseNumber, '' '', c.Title,
                    CASE WHEN cr.ConditionId IS NOT NULL THEN CONCAT('' '', con.Title) ELSE '''' END),
                '' ''
            ) WITHIN GROUP (ORDER BY cr.SortOrder, cr.Id)
        )
    END + ''; <br>''
    FROM CourseRequisite cr
    INNER JOIN RequisiteType rt ON rt.Id = cr.RequisiteTypeId
    INNER JOIN Subject s ON s.Id = cr.SubjectId
    INNER JOIN Course c ON c.Id = cr.Requisite_CourseId
    LEFT JOIN Condition con ON con.Id = cr.ConditionId
    WHERE rt.Id = 5 AND cr.CourseId = @entityId
), '''');

/**********************************************************************
 * Non Course Requirement
 **********************************************************************/
SET @text += COALESCE((
    SELECT CASE WHEN COUNT(cr.Id) > 0 THEN
        CONCAT(''<b>Non Course Requirement:</b> '',
            STRING_AGG(
                CONCAT(cr.MinimumGradeRationale,
                    CASE WHEN cr.ConditionId IS NOT NULL THEN CONCAT('' '', con.Title) ELSE '''' END),
                '' ''
            ) WITHIN GROUP (ORDER BY cr.SortOrder, cr.Id)
        )
    END + ''; <br>''
    FROM CourseRequisite cr
    LEFT JOIN Condition con ON con.Id = cr.ConditionId
    WHERE cr.listitemtypeid = 23 AND cr.CourseId = @entityId
), '''');

SELECT 
    CASE LEN(@text)
        WHEN 0 THEN @text
        ELSE LEFT(@text, LEN(@text) - 1)
    END AS Text,
    0 AS Value;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

SET @Id = 103

SET @SQL = '
SELECT 
    0 AS Value,
    ''<ul>'' + STRING_AGG(''<li>'' + GE.Title + ''</li>'' + txt, '''') 
        WITHIN GROUP (ORDER BY GE.SortOrder, GE.Id) + ''</ul>'' AS Text
FROM (
    SELECT 
        GE.SortOrder,
        GE.Id,
        STRING_AGG(''<li>'' + GEE.Title + ''</li>'', '''') 
            WITHIN GROUP (ORDER BY GEE.SortOrder, GEE.Id) AS txt
    FROM CourseGeneralEducation CGE
        INNER JOIN GeneralEducationElement GEE 
            ON CGE.GeneralEducationElementId = GEE.Id
            AND GEE.GeneralEducationId BETWEEN 14 AND 20
        INNER JOIN GeneralEducation GE 
            ON GEE.GeneralEducationId = GE.Id
    WHERE CGE.CourseId = @EntityId
    GROUP BY GE.SortOrder, GE.Id, GE.Title
) A
INNER JOIN GeneralEducation GE 
    ON GE.SortOrder = A.SortOrder AND GE.Id = A.Id
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

SET @Id = 102

SET @SQL = '
SELECT 
    0 AS Value,
    ''<ul>'' + 
    STRING_AGG(
        ''<li>'' + GE.Title + ''</li>'' + A.txt, ''''
    ) WITHIN GROUP (ORDER BY GE.SortOrder, GE.Id) 
    + ''</ul>'' AS Text
FROM (
    SELECT 
        GE.SortOrder,
        GE.Id,
        ''<ul>'' + 
        STRING_AGG(
            ''<li>'' + GEE.Title + ''</li>'', ''''
        ) WITHIN GROUP (ORDER BY GEE.SortOrder, GEE.Id) 
        + ''</ul>'' AS txt
    FROM CourseGeneralEducation CGE
        INNER JOIN GeneralEducationElement GEE 
            ON CGE.GeneralEducationElementId = GEE.Id
            AND GEE.GeneralEducationId BETWEEN 8 AND 13
        INNER JOIN GeneralEducation GE 
            ON GEE.GeneralEducationId = GE.Id
    WHERE CGE.CourseId = @EntityId
    GROUP BY GE.SortOrder, GE.Id, GE.Title
) A
INNER JOIN GeneralEducation GE 
    ON GE.SortOrder = A.SortOrder AND GE.Id = A.Id
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

SET @Id = 104

SET @SQL = '
SELECT 
    0 AS Value,
    ''<ul>'' + 
    STRING_AGG(
        ''<li>'' + GE.Title + ''</li>'' + A.txt, ''''
    ) WITHIN GROUP (ORDER BY GE.SortOrder, GE.Id) 
    + ''</ul>'' AS Text
FROM (
    SELECT 
        GE.SortOrder,
        GE.Id,
        ''<ul>'' + 
        STRING_AGG(
            ''<li>'' + GEE.Title + ''</li>'', ''''
        ) WITHIN GROUP (ORDER BY GEE.SortOrder, GEE.Id) 
        + ''</ul>'' AS txt
    FROM CourseGeneralEducation CGE
        INNER JOIN GeneralEducationElement GEE 
            ON CGE.GeneralEducationElementId = GEE.Id
            AND GEE.GeneralEducationId BETWEEN 21 AND 31
        INNER JOIN GeneralEducation GE 
            ON GEE.GeneralEducationId = GE.Id
    WHERE CGE.CourseId = @EntityId
    GROUP BY GE.SortOrder, GE.Id, GE.Title
) A
INNER JOIN GeneralEducation GE 
    ON GE.SortOrder = A.SortOrder AND GE.Id = A.Id
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

SET @Id = 101

SET @SQL = '
SELECT 
    0 AS Value,
    ''<ul>'' + 
    STRING_AGG(
        ''<li>'' + GE.Title + ''</li>'' + A.txt, ''''
    ) WITHIN GROUP (ORDER BY GE.SortOrder, GE.Id) 
    + ''</ul>'' AS Text
FROM (
    SELECT 
        GE.SortOrder,
        GE.Id,
        ''<ul>'' + 
        STRING_AGG(
            ''<li>'' + GEE.Title + ''</li>'', ''''
        ) WITHIN GROUP (ORDER BY GEE.SortOrder, GEE.Id) 
        + ''</ul>'' AS txt
    FROM CourseGeneralEducation CGE
        INNER JOIN GeneralEducationElement GEE 
            ON CGE.GeneralEducationElementId = GEE.Id
            AND GEE.GeneralEducationId BETWEEN 1 AND 6
        INNER JOIN GeneralEducation GE 
            ON GEE.GeneralEducationId = GE.Id
    WHERE CGE.CourseId = @EntityId
    GROUP BY GE.SortOrder, GE.Id, GE.Title
) A
INNER JOIN GeneralEducation GE 
    ON GE.SortOrder = A.SortOrder AND GE.Id = A.Id
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

SET @Id = 23

SET @SQL = '
SELECT 
    0 AS Value, 
    STRING_AGG(''<li>'' + Outcome + ''</li>'', '''') 
        WITHIN GROUP (ORDER BY SortOrder, Id) AS Text
FROM ProgramOutcome
WHERE ProgramId = @EntityId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

SET @Id = 111

SET @SQL = '
SELECT 
    0 AS Value,
    STRING_AGG(
        ''<div class="PLO">'' + PLO + ''</div>'' + txt, 
        ''''
    ) WITHIN GROUP (ORDER BY POSortorder, POid) AS Text
FROM (
    SELECT 
        POid,
        PLO,
        POSortorder,
        ''<ul>'' + STRING_AGG(
            ''<li class="Ctitle">'' + Ctitle + ''</li>'' + SLO, 
            ''''
        ) WITHIN GROUP (ORDER BY Cid) + ''</ul>'' AS txt
    FROM (
        SELECT 
            PO.id AS POid,
            PO.Outcome AS PLO,
            PO.SortOrder AS POSortorder,
            C.id AS Cid,
            C.EntityTitle AS Ctitle,
            ''<ul>'' + STRING_AGG(
                ''<li>'' + CO.OutcomeText + ''</li>'', 
                ''''
            ) WITHIN GROUP (ORDER BY CO.SortOrder, CO.Id) + ''</ul>'' AS SLO
        FROM ProgramOutcome PO
        LEFT JOIN ProgramOutcomeMatching POM 
            ON POM.ProgramOutcomeId = PO.Id
        INNER JOIN (
            SELECT 
                Id,
                OutcomeText,
                SortOrder,
                CourseId
            FROM CourseOutcome
        ) CO 
            ON POM.CourseOutcomeId = CO.Id
        INNER JOIN Course C 
            ON CO.CourseId = C.Id
        WHERE PO.ProgramId = @entityId
        GROUP BY PO.Id, PO.Outcome, PO.SortOrder, C.Id, C.EntityTitle
    ) B
    GROUP BY POid, PLO, POSortorder
) A
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
WHERE msf.MetaForeignKeyLookupSourceId in (
	132, 90, 103, 102, 104, 101, 23, 111
)