USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17855';
DECLARE @Comments nvarchar(Max) = 
	'Update COR query to not duplicate data';
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
DECLARE @outputText NVARCHAR(MAX);

WITH RecentDates AS (
    SELECT 
        cd.CourseDateTypeId,
        CONCAT(
            dbo.fnHtmlOpenTag(''li'', dbo.fnHtmlAttribute(''style'', ''list-style-type: none;'')),
            ''<b>'', cdt.Title, '':</b> '', FORMAT(cd.CourseDate, ''MM/dd/yyyy''),
            dbo.fnHtmlCloseTag(''li'')
        ) AS RenderedText,
        ROW_NUMBER() OVER (PARTITION BY cd.CourseDateTypeId ORDER BY cd.CourseDate DESC) AS rn,
        cdt.SortOrder
    FROM CourseDate cd
    INNER JOIN CourseDateType cdt ON cd.CourseDateTypeId = cdt.Id
    WHERE cd.CourseId = @EntityId
)
SELECT @outputText = dbo.ConcatOrdered_Agg(rt.rowOrder, rt.RenderedText, 0)
FROM (
    SELECT RenderedText, ROW_NUMBER() OVER (ORDER BY SortOrder) AS rowOrder
    FROM RecentDates
    WHERE rn = 1  -- Only select the most recent date for each CourseDateType
) rt;

SELECT 
    0 AS [Value],
    CASE
        WHEN LEN(@outputText) > 0
        THEN CONCAT(
            ''<div style="font-weight: bold;">Approval Dates:</div>'',
            dbo.fnHtmlOpenTag(''ol'', null),
            @outputText,
            dbo.fnHtmlCloseTag(''ol'')
        )
        ELSE ''''
    END AS [Text];
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 2357

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 2357
)