USE [imperial];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18136';
DECLARE @Comments nvarchar(Max) = 
	'Update COR for Objectives';
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
		declare @outputText nvarchar(max);

		select @outputText = dbo.ConcatOrdered_Agg(rt.rowOrder, rt.RenderedText, 0)
		from (
			select concat(
					dbo.fnHtmlOpenTag(''li'', dbo.fnHtmlAttribute(''style'', ''list-style-type: decimal;''))
						, [Text]
					, dbo.fnHtmlCloseTag(''li'')
				) as RenderedText
				, row_number() over (order by SortOrder) as rowOrder
			from CourseObjective
			where CourseId = @entityId
		) rt;
		
		select 0 as [Value]
			, CASE WHEN gmt.TextMax01 IS NULL THEN			
			concat(
				''<div style="font-size: 12px;">''
					, ''Upon satisfactory completion of the course, students will be able to:''
					, dbo.fnHtmlOpenTag(''ol'', null)
						, @outputText
					, dbo.fnHtmlCloseTag(''ol'')
				, ''</div>''
			)
			ELSE concat(
				''<div style="font-size: 12px;">''
					, ''Upon satisfactory completion of the course, students will be able to:<br>''
					,''Part 1:'', gmt.TextMax01, ''<br> Part 2:''
					, dbo.fnHtmlOpenTag(''ol'', null)
						, @outputText
					, dbo.fnHtmlCloseTag(''ol'')
				, ''</div>''
			)
			END as [Text]
			FROM Course As c
			LEFT JOIN GenericMaxText AS gmt on gmt.CourseId = c.Id
			WHERE c.Id = @EntityId
		;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 55

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection as mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 55
)