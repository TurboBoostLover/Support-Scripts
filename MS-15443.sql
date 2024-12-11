USE [miracosta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15443';
DECLARE @Comments nvarchar(Max) = 
	'Fix COR Report query';
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
select 0 as [Value]
			,concat(
						''<table style="width: 100%"><tr><td style="padding-top: 10px; padding-bottom: 20px;"><b>Units Lecture</b> ''
						, coalesce(format(MinOtherHour, ''N2''), ''0.00'')
						, ''</td><td style="padding-top: 10px; padding-bottom: 20px;"><b>Units Lab</b> ''
						, coalesce(format(MaxLabHour, ''N2''), ''0.00'')
						, ''</td><td style="padding-top: 10px; padding-bottom: 20px;"><b>Units Total</b> ''
						, CASE 
							WHEN MinCreditHour IS NULL OR MinCreditHour = 0
							THEN cast(
							cast(
								coalesce(MaxCreditHour,0) as decimal(16,2)
							) as nvarchar(max)
						)
							ELSE
						 cast(
							cast(
								coalesce(MaxCreditHour,0) as decimal(16,2)
							) as nvarchar(max)
						)
						END
						, ''</td></tr><tr><td style="padding-top: 10px; padding-bottom: 20px;"><b>Lecture Weekly Contact Hours</b> ''
						, coalesce(format(TeachingUnitsWork, ''N2''), ''0.00'')
						, ''</td><td style="padding-top: 10px; padding-bottom: 20px;"><b>Lab Weekly Contact Hours</b> ''
						, coalesce(format(ShortTermLabHour, ''N2''), ''0.00'')
						, ''</td><td style="padding-top: 10px; padding-bottom: 20px;"><b>Total Weekly Contact Hours</b> ''
						, coalesce(format(TeachingUnitsLab, ''N2''), ''0.00'')
						, ''</td></tr><tr><td style="padding-top: 10px; padding-bottom: 20px;"><b>Lecture Weekly Out of Class Hours</b> ''
						, coalesce(format(MaxContactHoursLecture, ''N2''), ''0.00'')
						, ''</td><td style="padding-top: 10px; padding-bottom: 20px;"><b>Lab Weekly Outside of Class Hours</b> ''
						, coalesce(format(MaximumOutsideLab, ''N2''), ''0.00'')
						, ''</td><td style="padding-top: 10px; padding-bottom: 20px;"><b>Total Weekly Outside of Class Hours</b> ''
						, coalesce(format(MinStudyHour, ''N2''), ''0.00'')
						, ''</td></tr><tr><td style="padding-top: 10px; padding-bottom: 20px;"><b>Total Contact Hours</b> ''
						, concat(
								coalesce(format(TeachingUnitsIstudy, ''N2''), ''0.00''), '' - ''
								, coalesce(format(SemesterHour, ''N2''), ''0.00''), ''''
							)
						, ''</td><td style="padding-top: 10px; padding-bottom: 20px;"><b>Total Outside of Class Hours</b> ''
						, concat(
								coalesce(format(LoadValue, ''N2''), ''0.00''), '' - ''
								, coalesce(format(ShortTermLectureHour, ''N2''), ''0.00''), ''''
							)
						, ''</td><td style="padding-top: 10px; padding-bottom: 20px;"><b>Total Course Hours</b> ''
						, concat(
								coalesce(format(LoadValue + TeachingUnitsIstudy, ''N2''), ''0.00''), '' - ''
								, coalesce(format(ShortTermLectureHour + SemesterHour, ''N2''), ''0.00''), ''''
							)
						, ''</td></tr></table>''
					)
			as [Text]
		from CourseDescription
		where courseId = @EntityId;
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 36

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MEtaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 36
)