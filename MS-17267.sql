USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17267';
DECLARE @Comments nvarchar(Max) = 
	'Update Report Query to be correct';
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
		declare @inlineTag nvarchar(10) = ''span'';
		declare @classAttrib nvarchar(10) = ''class'';

		drop table if exists #renderedInjections;

		create table #renderedInjections (
			TableName sysname
			, Id int
			, InjectionType nvarchar(255)
			, RenderedText nvarchar(max)
			, primary key (TableName, Id, InjectionType)
		);

		--#region CourseOption rendered injections
			insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
			select ''ProgramCourse'' as TableName
				, pc.Id
				, ''CourseEntryMiddleColumnInlineSuffix''
				, concat(
					''&nbsp;''
					, dbo.fnHtmlOpenTag(@inlineTag, dbo.fnHtmlAttribute(@classAttrib, ''approved-for-distance-education-icon fa fa-laptop''))
					, dbo.fnHtmlCloseTag(@inlineTag)
				)
			from ProgramCourse pc
				inner join CourseOption co on pc.CourseOptionId = co.Id
				inner join CourseYesNo cyn on pc.CourseId = cyn.CourseId
			where co.ProgramId = @entityId
			and cyn.YesNo21Id = 1;
		--#endregion CourseOption rendered injections

		insert into #renderedInjections (TableName, Id, InjectionType, RenderedText)
			select ''ProgramCourse'' as TableName
				, pc.Id
				, ''CourseEntryRightColumnReplacement''
				,  CONCAT (
	FORMAT(pc.CalcMin, ''##0.0##''),
		CASE WHEN pc.CalcMax > pc.CalcMin
		THEN CONCAT('' - '', FORMAT(pc.CalcMax, ''##0.0##''))
		ELSE ''''
END
)
			from ProgramCourse pc
				inner join CourseOption co on pc.CourseOptionId = co.Id
			where co.ProgramId = @entityId
		
		declare @programCourseExtraDetails nvarchar(max) = ''
			select Id as [Value]
				, RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''ProgramCourse''''
			and ri.Id = @id
			and ri.InjectionType = ''''CourseEntryMiddleColumnInlineSuffix'''';
		'';

				declare @CourseEnd nvarchar(max) = ''
			select Id as [Value]
				, RenderedText as [Text]
			from #renderedInjections ri
			where ri.TableName = ''''ProgramCourse''''
			and ri.Id = @id
			and ri.InjectionType = ''''CourseEntryRightColumnReplacement'''';
		'';

		declare @extraDetailsDisplay StringPair;

		insert into @extraDetailsDisplay (String1, String2)
		values (''CourseEntryMiddleColumnInlineSuffix'', @programCourseExtraDetails),
		(''CourseEntryRightColumnReplacement'', @CourseEnd);

		--Start display of ''Units:'' or ''Hours:'' text
			declare @creditHoursLabel nvarchar(max);

			set @creditHoursLabel = (
				select 
					case 
						when awt.Id in (
							13--Noncredit Certificate of Competency
							, 14--Noncredit Certificate of Completion
						)
							then ''Hours:''
						else ''Units:''
					end as RenderedText
				from Program p
					inner join AwardType awt on p.AwardTypeId = awt.Id
				where p.Id = @entityId
			);
		--End display of ''Units:'' or ''Hours:'' text

		exec dbo.upGenerateGroupConditionsCourseBlockDisplay @entityId = @entityId, @extraDetailsDisplay = @extraDetailsDisplay, @creditHoursLabel = @creditHoursLabel;

		drop table if exists #renderedInjections;
	
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 184

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 184
)