USE [statetechmo];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17102';
DECLARE @Comments nvarchar(Max) = 
	'Update Query to handle multiple sort order';
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
--==================== 
DECLARE @actualCourseId int = (dbo.ufnGetCloneAncestor(@entityId,''Course''));
DECLARE @renderQuery nvarchar(max);
DECLARE @renderIds integers;
DECLARE @style nvarchar(max) = ''
    <style type="text/css">
        .querytext-course-objectives ul {
            counter-reset: item;
        }
        
        .querytext-course-objectives li {
            display: block;
        }
        
        .querytext-course-objectives li:before {
            content: counters(item, "-") " ";
            counter-increment: item;
        }
    </style>
'';

DROP TABLE IF EXISTS #renderedObjectives;

CREATE TABLE #renderedObjectives (
    Id int PRIMARY KEY,
    Parent_Id int INDEX ixRenderedObjectives_Parent_Id,
    RenderedText nvarchar(max),
    SortOrder int INDEX ixRenderedObjectives_SortOrder
);

--==================== 
SET @renderQuery = ''
    DECLARE @childIds integers;

    INSERT INTO @childIds (Id)
    SELECT co2.Id
    FROM CourseObjective co
        INNER JOIN @renderIds ri ON co.Id = ri.Id
        INNER JOIN CourseObjective co2 ON co.Id = co2.Parent_Id
    ;

    IF (
        (
            SELECT COUNT(*)
            FROM @childIds
        ) > 0
    )
    BEGIN
        EXEC sp_executesql @renderQuery, N''''@renderIds integers readonly, @renderQuery nvarchar(max)'''', @childIds, @renderQuery;
    END;

    INSERT INTO #renderedObjectives (Id, Parent_Id, RenderedText, SortOrder)
    SELECT co.Id
        , co.Parent_Id
        , ro.RenderedObjective
        , co.SortOrder
    FROM CourseObjective co
        INNER JOIN @renderIds ri ON co.Id = ri.Id
        OUTER APPLY (
            SELECT STRING_AGG(ro.RenderedText, '''''''') WITHIN GROUP (ORDER BY ro.SortOrder) AS RenderedChildren
            FROM #renderedObjectives ro
            WHERE ro.Parent_Id = co.Id
        ) rc
        OUTER APPLY (
            SELECT CONCAT(
                    dbo.fnHtmlOpenTag(''''ul'''', null),
                    rc.RenderedChildren,
                    dbo.fnHtmlCloseTag(''''ul'''')
                ) AS RenderedChildrenWithListWrapper
            WHERE rc.RenderedChildren IS NOT NULL
            AND LEN(rc.RenderedChildren) > 0
        ) rcw
        CROSS APPLY (
            SELECT CONCAT(
                dbo.fnHtmlOpenTag(''''li'''', null),
                dbo.fnHtmlOpenTag(''''span'''', null),
                COALESCE(co.Header, co.Text, ''''''''),
                dbo.fnHtmlCloseTag(''''span''''),
                rcw.RenderedChildrenWithListWrapper,
                dbo.fnHtmlCloseTag(''''li'''')
            ) AS RenderedObjective
        ) ro
    ;
'';

DECLARE @childIds integers;

INSERT INTO @childIds (Id)
SELECT Id
FROM CourseObjective co
WHERE co.CourseId = @actualCourseId
AND co.Parent_Id IS NULL;

EXEC sp_executesql @renderQuery , N''@renderIds integers readonly, @renderQuery nvarchar(max)'', @childIds, @renderQuery;

SELECT 0 AS [Value],
    CONCAT(
        dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''querytext-course-objectives'')),
        @style,
        dbo.fnHtmlOpenTag(''ul'', null),
        STRING_AGG(ro.RenderedText, '''''''') WITHIN GROUP (ORDER BY ro.SortOrder),
        dbo.fnHtmlCloseTag(''ul''),
        dbo.fnHtmlCloseTag(''div'')
    ) AS [Text]
FROM #renderedObjectives ro
WHERE ro.Parent_Id IS NULL;

DROP TABLE IF EXISTS #renderedObjectives;

'

UPDATE MetaForeignKeyCriteriaClient
sET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE ID = 135

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 135
)