USE [imperial];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15404';
DECLARE @Comments nvarchar(Max) = 
	'Update COR Report';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @CrosslistedC nvarchar(max) = REPLACE(REPLACE(dbo.fn_GetCurrentCoursesInCrosslisting(@entityId,0, 1,1),''<h2>'',''<h2 style="display:none;">''),''<br>'','', '')

		select 0 as [Value]
			, concat(
				''<table style="width: 100%;" col>''
					, ''<colgroup>''
						, ''<col span="1" style="width: 22%;">''
						, ''<col span="1" style="width: 17%;">''
						, ''<col span="1" style="width: 27%;">''
						, ''<col span="1" style="width: 17%;">''
						, ''<col span="1" style="width: 17%;">''
					, ''</colgroup>''
					, ''<tr>''
						, ''<td colspan="4">''
							, ''<span style="font-size: 13px; font-weight: bold;">DIVISION: </span>''
							, ''<span style="font-size: 12px;">''
								, oe.Title
							, ''</span>''
						, ''</td>''
						, ''<td>''
							, ''<span style="font-size: 13px; font-weight: bold">DATE: </span>''
							, ''<span style="font-size: 12px;">''
								, convert(varchar(max), cDate.CourseDate, 107)
							, ''</span>''
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td colspan="4">''
							, ''<span style="font-size: 13px; font-weight: bold">COURSE: </span>''
							, ''<span style="font-size: 12px;">''
								, s.SubjectCode
								, '' ''
								, c.CourseNumber
								, '' - ''
								, c.Title
							, ''</span>''
						, ''</td>''
						, ''<td>''
							, ''<span style="font-size: 13px; font-weight: bold">UNITS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinCreditHour as decimal(16, 2))
								, case
									when cd.MaxCreditHour > cd.MinCreditHour
										then concat(
											'' - ''
											, cast(cd.MaxCreditHour as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td colspan="2">''
							, ''<span style="font-size: 13px; font-weight: bold">LEC HRS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinContactHoursLecture as decimal(16, 2))
								, case
									when cd.MaxContactHoursLecture > cd.MinContactHoursLecture
										then concat(
											'' - ''
											, cast(cd.MaxContactHoursLecture as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
						, ''<td>''
							, ''<span style="font-size: 13px; font-weight: bold">ACTIVITY LAB HRS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinContactHoursOther as decimal(16, 2))
								, case
									when cd.MaxContactHoursOther > cd.MinContactHoursOther
										then concat(
											'' - ''
											, cast(cd.MaxContactHoursOther as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
						, ''<td colspan="2">''
							, ''<span style="font-size: 13px; font-weight: bold">LAB HRS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinContactHoursLab as decimal(16, 2))
								, case
									when cd.MaxContactHoursLab > cd.MinContactHoursLab
										then concat(
											'' - ''
											, cast(cd.MaxContactHoursLab as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td colspan="2">''
							, ''<span style="font-size: 13px; font-weight: bold">OUT OF CLASS HRS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinStudyHour as decimal(16, 2))
								, case
									when cd.MaxStudyHour > cd.MinStudyHour
										then concat(
											'' - ''
											, cast(cd.MaxStudyHour as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
						, ''<td colspan="3">''
							, ''<span style="font-size: 13px; font-weight: bold">TOTAL STUDENT LEARNING HRS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinContHour as decimal(16, 2))
								, case
									when cd.MaxContHour > cd.MinContHour
										then concat(
											'' - ''
											, cast(cd.MaxContHour as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td>''
							, ''<span style="font-size: 13px; font-weight: bold">CLASS SIZE: </span>''
							, ''<span style="font-size: 12px;">''
								, cp.CourseCoop
							, ''</span>''
						, ''</td>''
						, ''<td colspan="2">''
							, ''<span style="font-size: 13px; font-weight: bold">ONLINE CLASS SIZE: </span>''
							, ''<span style="font-size: 12px;">''
								, cp.CourseControl
							, ''</span>''
						, ''</td>''
						, ''<td colspan="2">''
							, ''<span style="font-size: 13px; font-weight: bold">LARGE QUOTA: </span>''
							, ''<span style="font-size: 12px;">''
								, case
									when cp.AssociateOnly = 1
										then ''Yes''
									else ''No''
								end
							, ''</span>''
						, ''</td>''
					, ''</tr>''
					,	''<tr>''
						, ''<td colspan="5">''
								, case
									when LEN(@CrosslistedC) < 5
										then ''''
									else CONCAT(
							 ''<span style="font-size: 13px; font-weight: bold">CROSS-REFERENCED COURSE: </span>''
							, ''<span style="font-size: 12px;">'',
									@CrosslistedC
							, ''</span>''
					)
								end
						, ''</td>''
					, ''</tr>''
				, ''</table>''
			) as [Text]
		from Course c
			inner join OrganizationSubject os on c.SubjectId = os.SubjectId
			inner join OrganizationEntity oe on os.OrganizationEntityId = oe.Id
			left join CourseDate cDate
				inner join CourseDateType cdt on cDate.CourseDateTypeId = cdt.Id
					and cdt.Id in (5) --5 = Last Outline Revision
			on c.Id = cDate.CourseId
			inner join [Subject] s on c.SubjectId = s.Id
			inner join CourseDescription cd on c.Id = cd.CourseId
			inner join CourseProposal cp on c.Id = cp.CourseId
		where c.Id = @entityId
		and os.Active = 1
		and oe.Active = 1;
'
, 
ResolutionSql = '

DECLARE @CrosslistedC nvarchar(max) = REPLACE(REPLACE(dbo.fn_GetCurrentCoursesInCrosslisting(@entityId,0, 1,1),''<h2>'',''<h2 style="display:none;">''),''<br>'','', '')

		select 0 as [Value]
			, concat(
				''<table style="width: 100%;" col>''
					, ''<colgroup>''
						, ''<col span="1" style="width: 22%;">''
						, ''<col span="1" style="width: 17%;">''
						, ''<col span="1" style="width: 27%;">''
						, ''<col span="1" style="width: 17%;">''
						, ''<col span="1" style="width: 17%;">''
					, ''</colgroup>''
					, ''<tr>''
						, ''<td colspan="4">''
							, ''<span style="font-size: 13px; font-weight: bold;">DIVISION: </span>''
							, ''<span style="font-size: 12px;">''
								, oe.Title
							, ''</span>''
						, ''</td>''
						, ''<td>''
							, ''<span style="font-size: 13px; font-weight: bold">DATE: </span>''
							, ''<span style="font-size: 12px;">''
								, convert(varchar(max), cDate.CourseDate, 107)
							, ''</span>''
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td colspan="4">''
							, ''<span style="font-size: 13px; font-weight: bold">COURSE: </span>''
							, ''<span style="font-size: 12px;">''
								, s.SubjectCode
								, '' ''
								, c.CourseNumber
								, '' - ''
								, c.Title
							, ''</span>''
						, ''</td>''
						, ''<td>''
							, ''<span style="font-size: 13px; font-weight: bold">UNITS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinCreditHour as decimal(16, 2))
								, case
									when cd.MaxCreditHour > cd.MinCreditHour
										then concat(
											'' - ''
											, cast(cd.MaxCreditHour as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td colspan="2">''
							, ''<span style="font-size: 13px; font-weight: bold">LEC HRS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinContactHoursLecture as decimal(16, 2))
								, case
									when cd.MaxContactHoursLecture > cd.MinContactHoursLecture
										then concat(
											'' - ''
											, cast(cd.MaxContactHoursLecture as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
						, ''<td>''
							, ''<span style="font-size: 13px; font-weight: bold">ACTIVITY LAB HRS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinContactHoursOther as decimal(16, 2))
								, case
									when cd.MaxContactHoursOther > cd.MinContactHoursOther
										then concat(
											'' - ''
											, cast(cd.MaxContactHoursOther as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
						, ''<td colspan="2">''
							, ''<span style="font-size: 13px; font-weight: bold">LAB HRS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinContactHoursLab as decimal(16, 2))
								, case
									when cd.MaxContactHoursLab > cd.MinContactHoursLab
										then concat(
											'' - ''
											, cast(cd.MaxContactHoursLab as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td colspan="2">''
							, ''<span style="font-size: 13px; font-weight: bold">OUT OF CLASS HRS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinStudyHour as decimal(16, 2))
								, case
									when cd.MaxStudyHour > cd.MinStudyHour
										then concat(
											'' - ''
											, cast(cd.MaxStudyHour as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
						, ''<td colspan="3">''
							, ''<span style="font-size: 13px; font-weight: bold">TOTAL STUDENT LEARNING HRS: </span>''
							, ''<span style="font-size: 12px;">''
								, cast(cd.MinContHour as decimal(16, 2))
								, case
									when cd.MaxContHour > cd.MinContHour
										then concat(
											'' - ''
											, cast(cd.MaxContHour as decimal(16, 2))
										)
									else ''''
								end
							, ''</span>''
						, ''</td>''
					, ''</tr>''
					, ''<tr>''
						, ''<td>''
							, ''<span style="font-size: 13px; font-weight: bold">CLASS SIZE: </span>''
							, ''<span style="font-size: 12px;">''
								, cp.CourseCoop
							, ''</span>''
						, ''</td>''
						, ''<td colspan="2">''
							, ''<span style="font-size: 13px; font-weight: bold">ONLINE CLASS SIZE: </span>''
							, ''<span style="font-size: 12px;">''
								, cp.CourseControl
							, ''</span>''
						, ''</td>''
						, ''<td colspan="2">''
							, ''<span style="font-size: 13px; font-weight: bold">LARGE QUOTA: </span>''
							, ''<span style="font-size: 12px;">''
								, case
									when cp.AssociateOnly = 1
										then ''Yes''
									else ''No''
								end
							, ''</span>''
						, ''</td>''
					, ''</tr>''
					,	''<tr>''
						, ''<td colspan="5">''
								, case
									when LEN(@CrosslistedC) < 5
										then ''''
									else CONCAT(
							 ''<span style="font-size: 13px; font-weight: bold">CROSS-REFERENCED COURSE: </span>''
							, ''<span style="font-size: 12px;">'',
									@CrosslistedC
							, ''</span>''
					)
								end
						, ''</td>''
					, ''</tr>''
				, ''</table>''
			) as [Text]
		from Course c
			inner join OrganizationSubject os on c.SubjectId = os.SubjectId
			inner join OrganizationEntity oe on os.OrganizationEntityId = oe.Id
			left join CourseDate cDate
				inner join CourseDateType cdt on cDate.CourseDateTypeId = cdt.Id
					and cdt.Id in (5) --5 = Last Outline Revision
			on c.Id = cDate.CourseId
			inner join [Subject] s on c.SubjectId = s.Id
			inner join CourseDescription cd on c.Id = cd.CourseId
			inner join CourseProposal cp on c.Id = cp.CourseId
		where c.Id = @entityId
		and os.Active = 1
		and oe.Active = 1;
'
WHERE Id = 41

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MEtaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 41
)