USE [victorvalley];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13594';
DECLARE @Comments nvarchar(Max) = 
	'Fix custom sql for cor - line 76 use to be just SortOrder';
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
	AND mtt.MetaTemplateTypeId = 17 --hard code type to remove all other course reports 

SET QUOTED_IDENTIFIER OFF

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = "
declare @outputText nvarchar(max);

select @outputText = dbo.ConcatOrdered_Agg(rt.SortOrder, rt.RenderedText, 0)
from (
	select concat(
			dbo.fnHtmlOpenTag('li', dbo.fnHtmlAttribute('style', 'list-style-type: none;'))
				, OutlineText
			, dbo.fnHtmlCloseTag('li')
		) as RenderedText
		, ROW_NUMBER ()over (order by SortOrder, Id) AS SortOrder
	from CourseLabContent
	where CourseId = @entityId
) rt;

select 0 as [Value]
	, concat(
		dbo.fnHtmlOpenTag('ol', null)
			, @outputText
		, dbo.fnHtmlCloseTag('ol')
	) as [Text]
;"
WHERE Id = 161
SET QUOTED_IDENTIFIER ON

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
where MetaTemplateId in (select * from @templateId)