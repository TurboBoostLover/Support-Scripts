USE [sbcc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17977';
DECLARE @Comments nvarchar(Max) = 
	'Update COR to show textboooks in a list';
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
		select 0 as [Value]
		   , dbo.fnHtmlElement(''ul'', CONCAT(''<li>'',dbo.ConcatWithSep_Agg(''<li>'',
				concat(dbo.fnHtmlElement(''i'', Title, null)
					, '' ''
					, case
						when ct.Author is not null then concat(ct.Author, '', '')
					end
					, case
						when ct.Publisher is not null then concat(ct.Publisher, '', '')
					end
					, case
						when ct.CalendarYear is not null then concat(ct.CalendarYear, '''')
					end
					, ''. ''
				))
			), null) as [Text]
		from CourseTextbook ct
		where ct.CourseId = @entityId
		group by ct.CourseId
'

DECLARE @SQL2 NVARCHAR(MAX) = '
		select 0 as [Value]
			, dbo.fnHtmlElement(''ul'', CONCAT(''<li>'',dbo.ConcatWithSep_Agg(''<li>'',
				concat(dbo.fnHtmlElement(''i'', cm.Title, null)
					, '' ''
					, case
						when cm.Author is not null then concat(cm.Author, '', '')
					end
					, case
						when cm.Publisher is not null then concat(cm.Publisher, '', '')
					end
					, case
						when cm.PubDate is not null then concat(cm.PubDate, '''')
					end
					, ''. ''
				))
			), null) as [Text]
		from CourseManual cm
		where cm.CourseId = @entityId
		group by cm.CourseId
'

DECLARE @SQL3 NVARCHAR(MAX) = '
		select 0 as [Value]
			, dbo.fnHtmlElement(''ul'', CONCAT(''<li>'',dbo.ConcatWithSep_Agg(''<li>'',
				concat(dbo.fnHtmlElement(''i'', cp.Title, null)
					, '' ''
					, case
						when cp.Author is not null then concat(cp.Author, '', '')
					end
					, case
						when cp.PublicationName is not null then concat(cp.PublicationName, '', '')
					end
					, case
						when cp.PublicationYear is not null then concat(cp.PublicationYear, '''')
					end
					, ''. ''
				))
			), null) as [Text]
		from CoursePeriodical cp
		where cp.CourseId = @entityId
		group by cp.CourseId
'

DECLARE @SQL4 NVARCHAR(MAX) = '

		select 0 as [Value]
			, dbo.fnHtmlElement(''ul'', CONCAT(''<li>'',dbo.ConcatWithSep_Agg(''<li>'',
				concat(dbo.fnHtmlElement(''i'', cs.Title, null)
					, '' ''
					, case
						when cs.[Description] is not null then concat(cs.[Description], '', '')
					end
					, case
						when cs.Publisher is not null then concat(cs.Publisher, '', '')
					end
					, case
						when cs.Edition is not null then concat(cs.Edition, '''')
					end
					, ''. ''
				))
			), null) as [Text]
		from CourseSoftware cs
		where cs.CourseId = @entityId
		group by cs.CourseId
	
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 23

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE Id = 27905

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL3
, ResolutionSql = @SQL3
WHERE Id = 27906

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL4
, ResolutionSql = @SQL4
WHERE Id = 27907

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (
	23, 27905, 27906, 27907
	)
)