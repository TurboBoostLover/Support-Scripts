USE [palomar];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16969';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog Presentation';
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
declare @query nvarchar(max) = '

declare @courseEntryLinkTriggerElementTag nvarchar(255) = ''a''
declare @empty nvarchar(1) = '''';
declare @space nvarchar(2) = '' '';
declare @courseEntryLinkConfig nvarchar(max) = ''{
	"title": "Course Summary",
	"placement": "right",
	"trigger": "focus",
	"content": "",
	"curriculumPresentationId": 1
}''
declare @courseEntryLinkContentTag nvarchar(255) = ''span'';
declare @CourseEntryLinkTriggerWrapperAttribute nvarchar(255) = '' class="course-entry-link-trigger"'';
declare @CourseEntryLinkContentWrapperAttribute nvarchar(255) = '' class="course-entry-link-content"'';

select distinct
	case 
		when tv.[text] is not null then 
			concat(
				dbo.fnHtmlOpenTag(@courseEntryLinkTriggerElementTag,
					concat(
						@CourseEntryLinkTriggerWrapperAttribute,
						@space, dbo.fnHtmlAttribute(''data-action'', ''popover''),
						@space, dbo.fnHtmlAttribute(
							''data-config'',
							dbo.fnHtmlEntityEscape(json_modify(@courseEntryLinkConfig, ''$.entityId'', pc.CourseId))
						),
						@space, dbo.fnHtmlAttribute(''href'', ''javascript:void(0)''),
						@space, dbo.fnHtmlAttribute(''tabindex'', ''0'')
					)
				),
					dbo.fnHtmlOpenTag(@courseEntryLinkContentTag, @CourseEntryLinkContentWrapperAttribute),
						tv.[text],
					dbo.fnHtmlCloseTag(@courseEntryLinkContentTag),
				dbo.fnHtmlCloseTag(@courseEntryLinkTriggerElementTag)
			)
		else ''(no course)''
	end as [text]
from Course c
	inner join Subject s on c.SubjectId = s.Id
	inner join ProgramCourse pc on pc.CourseId = c.Id
	left join CrossListingCourse clc on (pc.CourseId = clc.CourseId
									and clc.Active = 1)
	left join CrossListing cl on clc.CrossListingId = cl.Id
	outer apply (
		select distinct
		case
			when clc.Id is null then concat(s.SubjectCode, space(1), c.CourseNumber)
			else coalesce(stuff((select
						concat('' / '', s2.SubjectCode, space(1), c2.CourseNumber)
					from CrossListingCourse clc2
					inner join Course c2
						on clc2.CourseId = c2.Id
					inner join Subject s2
						on c2.SubjectId = s2.Id
					where cl.Id = clc2.CrossListingId
					and clc2.Active = 1
					for xml path (''''), type)
				.value(''(./text())[1]'', ''NVARCHAR(MAX)''), 1, 3, ''''), '''')
		end as [text]
	) tv
where pc.Id = @Id;
'


declare @newConfig nvarchar(max) = (
	select cw2.title
	, @query as query
	from CurriculumPresentation cp
		cross apply openjson(json_value(cp.Config, '$.additionalTemplateConfig.extraDetailsDisplay')) cw
		cross apply openjson(cw.[Value]) 
		with (
			title nvarchar(max) '$.title',
			query nvarchar(max) '$.query'
		) cw2
	where id = 2
	for json auto -- escape the conntent of nvarchar9max)
);

--select @newConfig as '@newConfig'
	-- the query's value is escaped

declare @additionalTemplateConfig nvarchar(max) = (
	select json_modify(cp.Config, '$.additionalTemplateConfig.extraDetailsDisplay', @newConfig)
	from CurriculumPresentation cp
	where id = 2
	-- the query's value is escaped again!
)

--select @additionalTemplateConfig as '@additionalTemplateConfig'
--, isjson(@additionalTemplateConfig)
--declare @serializedExtraDetailsDisplay nvarchar(max);

update CurriculumPresentation
set Config = @additionalTemplateConfig
where id in (1,2)