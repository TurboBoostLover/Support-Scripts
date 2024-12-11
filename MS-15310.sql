USE [cuesta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15310';
DECLARE @Comments nvarchar(Max) = 
	'Fix Requisite display on COR report';
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
DECLARE @SQL2 NVARCHAR(MAX) = '
DECLARE @Break varchar(10) = ''<br>'',
	@Colon varchar(5) = '':'',
	@space varchar(5) = '' '',
	@empty varchar(5) = ''''
	
select coalesce(dbo.ConcatWithSep_Agg(@Break,PluralRT.Title + @Colon + @space + A.text),@empty) as [Text]
		from (
			select cr.ListItemTypeId,Rt.Id,dbo.ConcatWithSepOrdered_Agg(@space,CR.SortOrder,concat(coalesce(s2.Subjectcode + @space + c2.CourseNumber,cr.CourseRequisiteComment), @space + con.Title)) as Text
			from CourseRequisite cr
				left join Course c2 on cr.Requisite_CourseId = c2.Id
				left join [Subject] s2 on c2.SubjectId = s2.Id
				left join RequisiteType rt on cr.RequisiteTypeId = rt.Id
				left join MinimumGrade mg on mg.Id = cr.MinimumGradeId
				left join CourseRequisite cr2 on CR.Parent_Id = CR2.id
				outer apply(select top 1 1 as id from CourseRequisite cr3 where CR.Parent_Id = CR3.Parent_Id and CR3.SortOrder > CR.SortOrder) cr3
				left join Condition con on con.Id = cr2.GroupConditionId and CR3.id is not null
			where cr.CourseId = @entityId
			group by RT.id, cr.ListItemTypeId
		) A
		LEFT join RequisiteType RT on A.id = RT.Id
		Outer apply
		(
			select case 
				when RT.Title = ''Advisory''
				then ''Advisories''
				when RT.Title = ''Limitation on Enrollment''
				then ''Limitations on Enrollment''
				when A.ListItemTypeId = 14
				then ''Non Course Requirement''
				else RT.Title + ''s'' 
			end as Title
		) PluralRT
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
, ResolutionSql = @SQL2
WHERE ID = 56174212

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate AS mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (56174212)
)