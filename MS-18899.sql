USE [palomar];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18899';
DECLARE @Comments nvarchar(Max) = 
	'Updated Catalog Config to only show active courses';
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
UPDATE CurriculumPresentation
SET Config = '{"additionalTemplateConfig": {
        "extraDetailsDisplay": "[{\"title\":\"CourseEntryLeftColumnReplacement\",\"query\":\"\\r\\n\\r\\ndeclare @courseEntryLinkTriggerElementTag nvarchar(255) = ''a''\\r\\ndeclare @empty nvarchar(1) = '''';\\r\\ndeclare @space nvarchar(2) = '' '';\\r\\ndeclare @courseEntryLinkConfig nvarchar(max) = ''{\\r\\n\\t\\\"title\\\": \\\"Course Summary\\\",\\r\\n\\t\\\"placement\\\": \\\"right\\\",\\r\\n\\t\\\"trigger\\\": \\\"focus\\\",\\r\\n\\t\\\"content\\\": \\\"\\\",\\r\\n\\t\\\"curriculumPresentationId\\\": 1\\r\\n}''\\r\\ndeclare @courseEntryLinkContentTag nvarchar(255) = ''span'';\\r\\ndeclare @CourseEntryLinkTriggerWrapperAttribute nvarchar(255) = '' class=\\\"course-entry-link-trigger\\\"'';\\r\\ndeclare @CourseEntryLinkContentWrapperAttribute nvarchar(255) = '' class=\\\"course-entry-link-content\\\"'';\\r\\n\\r\\nselect distinct\\r\\n\\tcase \\r\\n\\t\\twhen tv.[text] is not null then \\r\\n\\t\\t\\tconcat(\\r\\n\\t\\t\\t\\tdbo.fnHtmlOpenTag(@courseEntryLinkTriggerElementTag,\\r\\n\\t\\t\\t\\t\\tconcat(\\r\\n\\t\\t\\t\\t\\t\\t@CourseEntryLinkTriggerWrapperAttribute,\\r\\n\\t\\t\\t\\t\\t\\t@space, dbo.fnHtmlAttribute(''data-action'', ''popover''),\\r\\n\\t\\t\\t\\t\\t\\t@space, dbo.fnHtmlAttribute(\\r\\n\\t\\t\\t\\t\\t\\t\\t''data-config'',\\r\\n\\t\\t\\t\\t\\t\\t\\tdbo.fnHtmlEntityEscape(json_modify(@courseEntryLinkConfig, ''$.entityId'', pc.CourseId))\\r\\n\\t\\t\\t\\t\\t\\t),\\r\\n\\t\\t\\t\\t\\t\\t@space, dbo.fnHtmlAttribute(''href'', ''javascript:void(0)''),\\r\\n\\t\\t\\t\\t\\t\\t@space, dbo.fnHtmlAttribute(''tabindex'', ''0'')\\r\\n\\t\\t\\t\\t\\t)\\r\\n\\t\\t\\t\\t),\\r\\n\\t\\t\\t\\t\\tdbo.fnHtmlOpenTag(@courseEntryLinkContentTag, @CourseEntryLinkContentWrapperAttribute),\\r\\n\\t\\t\\t\\t\\t\\ttv.[text],\\r\\n\\t\\t\\t\\t\\tdbo.fnHtmlCloseTag(@courseEntryLinkContentTag),\\r\\n\\t\\t\\t\\tdbo.fnHtmlCloseTag(@courseEntryLinkTriggerElementTag)\\r\\n\\t\\t\\t)\\r\\n\\t\\telse ''(no course)''\\r\\n\\tend as [text]\\r\\nfrom Course c\\r\\n\\tinner join Subject s on c.SubjectId = s.Id\\r\\n\\tinner join ProgramCourse pc on pc.CourseId = c.Id\\r\\n\\tleft join CrossListingCourse clc on (pc.CourseId = clc.CourseId\\r\\n\\t\\t\\t\\t\\t\\t\\t\\t\\tand clc.Active = 1)\\r\\n\\tleft join CrossListing cl on clc.CrossListingId = cl.Id\\r\\n\\touter apply (\\r\\n\\t\\tselect distinct\\r\\n\\t\\tcase\\r\\n\\t\\t\\twhen clc.Id is null then concat(s.SubjectCode, space(1), c.CourseNumber)\\r\\n\\t\\t\\telse coalesce(stuff((select\\r\\n\\t\\t\\t\\t\\t\\tconcat('' \\\/ '', s2.SubjectCode, space(1), c2.CourseNumber)\\r\\n\\t\\t\\t\\t\\tfrom CrossListingCourse clc2\\r\\n\\t\\t\\t\\t\\tinner join Course c2\\r\\n\\t\\t\\t\\t\\t\\ton clc2.CourseId = c2.Id\\r\\n\\t\\t\\t\\t\\tinner join Subject s2\\r\\n\\t\\t\\t\\t\\t\\ton c2.SubjectId = s2.Id\\r\\n\\t\\t\\t\\t\\twhere cl.Id = clc2.CrossListingId\\r\\n\\t\\t\\t\\t\\tand clc2.Active = 1\\r\\n\\t\\t\\t\\t\\tfor xml path (''''), type)\\r\\n\\t\\t\\t\\t.value(''(.\\\/text())[1]'', ''NVARCHAR(MAX)''), 1, 3, ''''), '''')\\r\\n\\t\\tend as [text]\\r\\n\\t) tv\\r\\nwhere pc.Id = @Id;\\r\\n\"}]"
    }
,"statusBaseMapping":[{"catalogStatusBaseId":1,"entityStatusBaseId":1},{"catalogStatusBaseId":2,"entityStatusBaseId":1},{"catalogStatusBaseId":4,"entityStatusBaseId":1},{"catalogStatusBaseId":5,"entityStatusBaseId":1},{"catalogStatusBaseId":5,"entityStatusBaseId":5},{"catalogStatusBaseId":6,"entityStatusBaseId":1},{"catalogStatusBaseId":7,"entityStatusBaseId":1}]}'
WHERE Id = 1