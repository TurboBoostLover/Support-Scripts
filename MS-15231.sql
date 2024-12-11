USE [butte];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15231';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Summary Report';
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
DECLARE @SQL NVARCHAR(MAX) = '
declare @extraDetailsDisplay StringPair;

DECLARE @CrossListingIds INTEGERS
DECLARE @SubjectCodes TABLE (Id INT IDENTITY Primary Key, code NVARCHAR(MAX), CrosslistingId INT)

INSERT INTO @CrossListingIds
SELECT CrossListingId FROM ProgramSequence ps
	INNER JOIN CrossListingCourse clc ON ps.CourseId = clc.CourseId
WHERE ps.ProgramId = @EntityId

INSERT INTO @SubjectCodes
SELECT dbo.ConcatWithSep_Agg('' / '', concat (s.SubjectCode, '' '', c.CourseNumber)), clc.CrossListingId
FROM Course c
	INNER JOIN CrossListingCourse clc ON c.Id = clc.CourseId
	INNER JOIN Subject s ON s.Id = c.SubjectId
WHERE clc.ACTIVE = 1
	AND clc.IsSynced = 1
	AND clc.CrossListingId IN (SELECT Id FROM @crossListingIds)
Group BY CrossListingId

drop table if exists #renderedInjections;

create table #renderedInjections (
	TableName sysname,
	Id int,
	InjectionType nvarchar(255),
	RenderedText nvarchar(max)
);

declare @blockTag nvarchar(10) = ''div'';
declare @dataElementTag nvarchar(10) = ''span'';
declare @identifierWrapperTag nvarchar(5) = ''sup'';
declare @labelTag nvarchar(10) = ''label'';
declare @listTag nvarchar(10) = ''ul'';
declare @listItemTag nvarchar(10) = ''li'';

declare @classAttrib nvarchar(10) = ''class'';

declare @space nvarchar(5) = '' '';
declare @empty nvarchar(1) = '''';

declare @distanceEdIdentifierWrapperClass nvarchar(100) = ''course-approved-for-de-identifier'';
declare @distanceEdIdentifierText nvarchar(10) = ''DE'';

declare @minCrossListingDate datetime = (
	select min(clc.AddedOn)
	from CrossListingCourse clc
);

insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
select
	''ProgramSequence'' as TableName, ps.Id, ''CourseEntryLeftColumnReplacement'' as InjectionType,
	concat(
		dbo.fnHtmlOpenTag(@dataElementTag, concat(
			dbo.fnHtmlAttribute(@classAttrib, ''course-identifier''), @space,
			dbo.fnHtmlAttribute(''data-course-id'', c.Id)
		)),
			dbo.fnHtmlOpenTag(@dataElementTag, concat(
				dbo.fnHtmlAttribute(@classAttrib, ''subject-code''), @space,
				dbo.fnHtmlAttribute(''title'', dbo.fnHtmlEntityEscape(s.Title))
			)),
				CASE 
				WHEN c.IsCrossListed = 1 AND clc.Active = 1 AND clc.IsSynced = 1
					THEN (SELECT code FROM @SubjectCodes where CrosslistingId = clc.CrossListingId)
				ELSE s.SubjectCode
				END,
			dbo.fnHtmlCloseTag(@dataElementTag), @space,
			dbo.fnHtmlOpenTag(@dataElementTag, dbo.fnHtmlAttribute(@classAttrib, ''course-number'')),
				CASE 
				WHEN c.IsCrossListed = 1 AND clc.Active = 1 AND clc.IsSynced = 1
					THEN ''''
				ELSE c.CourseNumber
				END,
			dbo.fnHtmlCloseTag(@dataElementTag),
		dbo.fnHtmlCloseTag(@dataElementTag),
		case
			when cde.IsApproved = 1 then
				concat(
					dbo.fnHtmlOpenTag(@identifierWrapperTag, dbo.fnHtmlAttribute(@classAttrib, @distanceEdIdentifierWrapperClass)),
						@distanceEdIdentifierText,
					dbo.fnHtmlCloseTag(@identifierWrapperTag)
				)
			else ''''
		end
	) as [Text]
from ProgramSequence ps
	inner join Course c on ps.CourseId = c.Id
	inner join [Subject] s on c.SubjectId = s.Id
	left outer join CourseDistanceEducation cde on c.Id = cde.CourseId
	LEFT JOIN CrossListingCourse clc ON clc.CourseId = c.Id
		AND clc.Active = 1
		AND clc.IsSynced = 1
	LEFT JOIN @SubjectCodes sc ON sc.CrosslistingId = clc.CrossListingId
where (
	ps.ProgramId = @EntityId
	or exists (
		select top 1 1
		from ProgramSequence ps2
		where ps2.ProgramId = @EntityId
		and ps.Id = ps2.ReferenceId
	)
);


declare @courseLeftColumQuery nvarchar(max) =
''select Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''''ProgramSequence'''' and ri.Id = @id
and ri.InjectionType = ''''CourseEntryLeftColumnReplacement'''';
'';

insert into @extraDetailsDisplay (String1, String2)
values
(''CourseEntryLeftColumnReplacement'', @courseLeftColumQuery)

declare @config StringPair;

insert into @config (String1, String2)
values
(''BlockItemTable'', ''ProgramSequence'');

exec upGenerateGroupConditionsCourseBlockDisplay @entityId = @EntityId, @extraDetailsDisplay = @extraDetailsDisplay, @config = @config;

drop table if exists #renderedInjections;
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 202

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT Mt.MEtaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 202
)