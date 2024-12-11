USE [sac];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18262';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text';
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
DECLARE @Id int = 138

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @hasOrderedListData bit = (
    SELECT TOP 1 1
    FROM CourseObjective co
    WHERE co.CourseId = @EntityId
      AND co.Active = 1
);

IF (@hasOrderedListData = 1)
BEGIN
    WITH ObjectiveHierarchy AS (
        -- Recursive CTE to determine depth for indentation
        SELECT
            co.Id,
            co.Parent_Id,
						CASE WHEN Text IS NOT NULL THEN TEXT WHEN OptionalText IS NOT NULL THEN CONCAT(''<b>'', OptionalText, ''</b>'') ELSE NULL END AS Objective,
            0 AS Depth,
            co.SortOrder
        FROM CourseObjective co
        WHERE co.CourseId = @EntityId AND co.Parent_Id IS NULL
        
        UNION ALL
        
        SELECT
            child.Id,
            child.Parent_Id,
						CASE WHEN child.Text IS NOT NULL THEN child.Text WHEN child.OptionalText IS NOT NULL THEN CONCAT(''<b>'', child.OptionalText, ''</b>'') ELSE NULL END AS Objective,
            parent.Depth + 1 AS Depth,
            child.SortOrder
        FROM CourseObjective child
        INNER JOIN ObjectiveHierarchy parent ON child.Parent_Id = parent.Id
        WHERE child.CourseId = @EntityId
    )
    SELECT CONCAT(
        ''<div>'',
        dbo.ConcatWithSepOrdered_Agg('''', SortOrder, 
            CONCAT(''<div style="padding-left:'', Depth * 20, ''px;">'', 
                   CASE 
                     WHEN Objective IS NOT NULL THEN Objective 
                     ELSE ''<b class="text-danger">Untitled Objective</b>''
                   END, 
                   ''</div>'')
        ),
        ''</div>''
    ) AS [Text],
    0 AS [Value]
    FROM ObjectiveHierarchy
END
ELSE
BEGIN
    SELECT c.SpecifyTransReq AS [Text],
           0 AS [Value]
    FROM Course c
    WHERE c.Id = @EntityId;
END;
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