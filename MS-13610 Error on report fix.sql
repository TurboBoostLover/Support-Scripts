USE [butte];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13610';
DECLARE @Comments nvarchar(Max) = 
	'Fix custom sql for cor';
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
declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 1
    AND mtt.ClientId = 1
	AND mtt.MetaTemplateTypeId = 4 --hard code type to remove all other course reports 

SET QUOTED_IDENTIFIER OFF

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = "
DECLARE @innerText nvarchar(max)
    ,@totals nvarchar(max)
    ,@checkLect nvarchar(max)
    ,@checkAct nvarchar(max)
    ,@checkLectMax NVARCHAR(max)
    ,@checkActMax NVARCHAR(max);

SET @checkLect = (
    SELECT
        SUM(LabHours)
    FROM CourseOutline
    WHERE courseId = @EntityId
);
SET @checkAct = (
    SELECT
        SUM(LectureHours)
    FROM CourseOutline
    WHERE courseId = @EntityId
);

set @checkLectMax = (
    select sum(MaxLabHours)
    from CourseOutline
    where CourseId = @entityId
);

set @checkActMax = (
    select sum(MaxLectureHours)
    from CourseOutline
    where CourseId = @entityId
);

SET @innerText = (
SELECT
    STUFF((
        SELECT
            ' ' + CONCAT(
                '<tr>'
                , '<td colspan=""8"">'
                , COALESCE(LectureOutlineText, '')
                , '</td>'
                , CASE
		            WHEN @checkLect IS NOT NULL THEN CONCAT(
                        '<td colspan=""2"" style=""text-align: right;"">'
                        ,CAST(COALESCE(LabHours, 0) AS NVARCHAR(MAX))
                        ,case
                            when MaxLabHours is not null then concat(' - ',MaxLabHours)
                        end
                        ,'</td>'
                    )
		        ELSE ''
	            END
                ,CASE
		            WHEN @checkAct IS NOT NULL THEN CONCAT(
                        '<td colspan=""2"" style=""text-align: right;"">'
                        ,CAST(COALESCE(LectureHours, 0) AS NVARCHAR(MAX))
                        ,case
                            when MaxLectureHours is not null then concat(' - ',MaxLectureHours)
                        end
                        ,'</td>'
                    )
		            ELSE ''
	            END
                ,'</tr>'
            )
        FROM CourseOutline
        WHERE CourseId = @EntityId
        ORDER BY SortOrder, Id
        FOR XML PATH(''), TYPE).value('.', 'nvarchar(max)'), 1, 1, '')
);

SET	@totals = (
    SELECT
        CONCAT(
            '<tr>', '<td colspan=""8"" style=""text-align: right; font-weight: bold;"">', 'Total Hours:', '</td> '
            ,CASE
                WHEN @checkLect IS NOT NULL THEN CONCAT(
                    '<td colspan=""2"" style=""text-align: right;"">'
                    ,CAST(SUM(LabHours) AS NVARCHAR(MAX))
                    ,case
                        when sum(MaxLabHours) is not null then concat(' - ',cast(sum(MaxLabHours) as nvarchar(max)))
                    end
                    ,'</td>'
                )
				ELSE ''
            END
            ,CASE
				WHEN @checkAct IS NOT NULL THEN CONCAT(
                    '<td colspan=""2"" style=""text-align: right;"">'
                    ,CAST(SUM(LectureHours) AS NVARCHAR(MAX))
                    ,case
                        when sum(MaxLectureHours) is not null then concat(' - ',cast(sum(MaxLectureHours) as nvarchar(max)))
                    end
                    ,'</td>'
                )
				ELSE ''
			END
            ,'</tr>'
        )
    FROM CourseOutline
    WHERE courseId = @entityId
);

if (@checkLect is not null or @checkAct is not null)    
begin
SELECT
	0 AS [Value]
   ,CONCAT(
       '<table style=""width:100%; table-layout: fixed;"">', '<th colspan=""8""><u>Topics</u></th>'
        ,CASE
		    WHEN @checkLect IS NOT NULL THEN '<th colspan=""2"" style=""text-align: right;""><u>Lec Hrs</u></th>'
		    ELSE ''
	    END
        ,CASE
		    WHEN @checkAct IS NOT NULL THEN '<th colspan=""2"" style=""text-align: right;""><u>Act Hrs</u></th>'
		    ELSE ''
	    END
        ,@innerText
        ,@totals
        ,'</table>'
    ) AS [Text];
END;
;"
WHERE Id = 163
SET QUOTED_IDENTIFIER ON

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
where MetaTemplateId in (select * from @templateId)