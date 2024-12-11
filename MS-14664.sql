use stpetersburg 

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14664';
DECLARE @Comments nvarchar(Max) = 'MS-14534 - Updated the report query text to show the value of the Other';
DECLARE @Developer nvarchar(50) = 'Clinton Worle';
DECLARE @ScriptTypeId int = 1; 
/*  
Default for @ScriptTypeId on this script 
is 1 for  Support,  
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

/*
--------------------------------------------------------------------
Please do not alter the script above this comment�except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing something 
		 that is against meta best practices, but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the 
		 word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql
-----------------Script details go below this line------------------
*/


set QUOTED_IDENTIFIER off;

declare @sql nvarchar(max) = 
"declare @GenEds table (GenEdTitle nvarchar(max), GenEdElementTitle nvarchar(max), SortOrder INT, ElementSortorder int)

INSERT INTO @GenEds
	SELECT
		ge.Title
	   ,dbo.fnHtmlElement('li', gee.Title, NULL)
	   ,ge.SortOrder,
	   ROW_NUMBER() over(order by gee.sortorder,gee.Id)
	FROM CourseGeneralEducation cge
		INNER JOIN GeneralEducationElement gee ON gee.Id = cge.GeneralEducationElementId
		INNER JOIN GeneralEducation ge ON ge.id = cge.GeneralEducationId
	WHERE cge.CourseId = @entityID 
		AND ge.Title IN ('State General Education Requirements', 'Institutional Requirements', 'Other Attributes')
		AND gee.Active = 1
UNION 
	select  ge.Title
	   ,dbo.fnHtmlElement('li', TimesOfferedRationale, NULL)
	   ,ge.SortOrder
	   ,99999		 
		from CourseProposal cp 
		join GenericBit b on b.CourseId = cp.CourseId and b.Bit01 = 1
		join GeneralEducation ge on ge.Title = 'Other Attributes'
	where cp.CourseId = @entityId and TimesOfferedRationale is not null and ltrim(rtrim(TimesOfferedRationale)) <> ''
SELECT
	0 AS Value
   ,dbo.fnHtmlElement('ul', CONCAT('<b>',ges.GenEdTitle,'</b>', dbo.ConcatWithSepOrdered_Agg(NULL,ElementSortorder, GenEdElementTitle)), null) AS Text
FROM @GenEds ges
GROUP BY GenEdTitle, ges.SortOrder
ORDER BY ges.SortOrder"

update MetaForeignKeyCriteriaClient set CustomSql = @sql, ResolutionSql = @sql where Id = 97

update MetaTemplate set LastUpdatedDate = getdate() where MetaTemplateId = 9		--report id