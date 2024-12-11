USE [cuesta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15536';
DECLARE @Comments nvarchar(Max) = 
	'Update Report and bad data';
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
		declare @textbooks nvarchar(max);
		declare @manuals nvarchar(max);
		declare @periodicals nvarchar(max);
		declare @software nvarchar(max);
		declare @oer nvarchar(max)
		declare @other nvarchar(max);
		declare @notes nvarchar(max);
		
		select @textbooks = coalesce(@textbooks, '''') +
			concat(
				Author
				, '' ''
				, ''<i>''
					, Title
				, ''</i>''
				, case
					when Edition is not null
						then
							concat(
								'' (''
								, Edition
								, ''/e). ''
							)
					else ''''
				end
				, Publisher + '', ''
				, City + '', ''
				, case
					when CalendarYear is not null
						then
							concat(
								''(''
								, CalendarYear
								, '').''
							)
					else ''''
				end
				, case
					when Rational is not null
						then
							concat(
								''(''
								, Rational
								, '').''
							)
					else ''''
				end
				, ''<br />''
			)
		from CourseTextbook
		where CourseId = @entityId;

		select @manuals = coalesce(@manuals, '''') +
			concat(
				Title
				, '', ''
				, Author
				, '', ''
				, Publisher
				, '', ''
				, CalendarYear
				, ''<br />''
			)
		from CourseManual
		where CourseId = @entityId;

		select @periodicals = coalesce(@periodicals, '''') +
			concat(
				Title
				, '', ''
				, Author
				, '', ''
				, PublicationName
				, '', ''
				, Volume
				, '', ''
				, PublicationYear
				, ''<br />''
			)
		from CoursePeriodical
		where courseid = @entityId;

		select @software = coalesce(@software, '''') +
			concat(
				Title
				, '', ''
				, Edition
				, '', ''
				, Publisher
				, ''<br />''
			)
		from CourseSoftware
		where CourseId = @entityId;

				select @oer = coalesce(@oer, '''') +
			concat(
				JournalTitle
				, '', ''
				, Author
				, '', ''
				, Rationale
				, '', ''
				, Volume
				, ''<br />''
			)
		from CourseJournal
		where CourseId = @entityId;

		select @other = coalesce(@other, '''') + 
			concat(
				TextOther
				, ''<br />
			'')
		from CourseTextOther
		where CourseId = @entityId;

		select @notes = coalesce(@notes, '''') + 
			concat(
				[Text]
				, ''<br />''
			)
		from CourseNote
		where courseid = @entityId;

		select 	0 as [Value]
			, concat(
				case 
					when @textbooks is null
						then ''''
					else ''<b>Textbooks:</b> <br />''
				end
				, @textbooks
				 ,case
					when @oer is null
						then ''''
					else ''<b>OER: </b><br />''
				end
				, @oer
				, case
					when @manuals is null
						then ''''
					else ''<b>Manuals: </b><br />''
				end
				, @manuals
				, case
					when @periodicals is null
						then ''''
					else ''<b>Periodicals: </b><br />''
				end
				, @periodicals
				, case
					when @software is null
						then ''''
					else ''<b>Software: </b><br />''
				end
				, @software
				, case
					when @other is null
						then ''''
					else ''<b>Other: </b><br />''
				end
				, @other
				, case
					when @notes is null
						then ''''
					else ''<b>Notes: </b><br />''
				end
				, @notes
			) as [Text]
		;
'

UPDATE CoursePeriodical
SET PublicationYear = NULL
WHERE PublicationYear = '1905'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 56174224

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 56174224
)