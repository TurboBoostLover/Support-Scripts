USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13968';
DECLARE @Comments nvarchar(Max) = 
	'Update Data in tables to be more consistent for catalog';
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
UPDATE GeneralEducationElement
SET Text = '4c'
WHERE Id = 77

SET QUOTED_IDENTIFIER OFF

UPDATE OutputModelClient
SET ModelQuery = "

		declare @entityList_internal table (
			InsertOrder int Identity(1, 1) primary key
			, CourseId int
		);

		insert into @entityList_internal (CourseId)
		select el.Id
		from @entityList el;
		--select 18660;

		declare @entityRootData table (	
			[Transfer] nvarchar(max),
			PeraltaArea nvarchar(max),
			CSUArea nvarchar(max),
			IGETCArea nvarchar(max),
			TopCode nvarchar(max),
			CourseId int primary key,
			SubjectCode nvarchar(max),
			CourseNumber nvarchar(max),
			CourseTitle nvarchar(max),
			Variable bit,
			MinUnit decimal(16, 3),
			MaxUnit decimal(16, 3),
			MinLec decimal(16, 3),
			MaxLec decimal(16, 3),
			MinLab decimal(16, 3),
			MaxLab decimal(16, 3),
			MinLearn decimal(16,3),
			MaxLearn decimal(16,3), 
			TransferType nvarchar(max),
			Requisite nvarchar(max),
			Limitation nvarchar(max),
			Preperation nvarchar(max),
			CatalogDescription nvarchar(max),
			CourseGrading nvarchar(max),
			IsRepeatable nvarchar(10),
			RepeatableCode nvarchar(500),
			TimesRepeated nvarchar(500),
			Suffix nvarchar(500),
			CID nvarchar(500),
			CIDStatus nvarchar(255),
			CIDNotes nvarchar(max),
			AdminRepeat nvarchar(max),
			IsComment nvarchar(max),
			CourseType int
		);

		declare @clientId int = (
			select top 1 c.ClientId 
			from Course c
				inner join @entityList_internal eli on c.Id = eli.CourseId
		)

		declare @limitRequisiteQuery nvarchar(max) = (
			select CustomSql
			from MetaForeignKeyCriteriaClient
			where Title = 'Catalog Limit'
		)

		declare @prepRequisiteQuery nvarchar(max) = (
			select CustomSql
			from MetaForeignKeyCriteriaClient
			where Title = 'Catalog Prep'
		)

		declare @requisite_mfkccId int = 4012;
		declare @requisite_mfkccQuery nvarchar(max) = (
			select ResolutionSql
			from MetaForeignKeyCriteriaClient
			where Id = @requisite_mfkccId
		);

		-- ============================
		-- return
		-- ============================
		insert into @entityRootData (
			[Transfer]
			, PeraltaArea
			, CSUArea
			, IGETCArea
			, TopCode
			, CourseId
			, SubjectCode
			, CourseNumber
			, CourseTitle
			, Variable
			, MinUnit
			, MaxUnit
			, MinLec
			, MaxLec
			, MinLab
			, MaxLab
			, MinLearn
			, MaxLearn
			, TransferType
			, Requisite
			, Limitation
			, Preperation
			, CatalogDescription
			, CourseGrading
			, IsRepeatable
			, RepeatableCode
			, TimesRepeated
			, Suffix
			, CID
			, CIDStatus
			, CIDNotes
			, AdminRepeat
			, IsComment
			, CourseType
		)
		select distinct
			replace(
				concat('',
					stuff(
						(select concat('~@', stuff((
							select '~@'+ coalesce(case when gee.text = 'Non-transferable' then '' else gee.text end, '')
							from CourseGeneralEducation cge
								inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
								inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
							where cge.Active = 1 
								and gee.Active = 1 
								and cge.CourseId = c.Id
								and ge.Title = a.Title
							for xml path('')
							), 1, 2, '') 
						)
						from (select distinct ge.Title, ge.SortOrder
						from CourseGeneralEducation cge 
							inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
						where cge.Active = 1 
							and ge.Active = 1
							and cge.CourseId = c.Id
							and ge.Id in (7) ) a
						order by a.SortOrder
						for xml path('') 
						)
					, 1, 2, '') 
				)
			, '~@', ', ')
			, replace(
				concat('',
					stuff(
						(select concat('~@', stuff((
							select '~@'+ coalesce(gee.text, '')
							from CourseGeneralEducation cge
								inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
								inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
							where cge.Active = 1 
								and gee.Active = 1 
								and cge.CourseId = c.Id
								and ge.Title = a.Title
							for xml path('')
							), 1, 2, '') 
						)
						from (select distinct ge.Title, ge.SortOrder
						from CourseGeneralEducation cge 
							inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
						where cge.Active = 1 
							and ge.Active = 1
							and cge.CourseId = c.Id
							and ge.Id in (22)) a
						order by a.SortOrder
						for xml path('') 
						)
					, 1, 2, '') 
				)
			, '~@', ', ')
			, replace(
				concat('',
					stuff(
						(select concat('~@', stuff((
							select '~@'+ coalesce(gee.text, '')
							from CourseGeneralEducation cge
								inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
								inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
							where cge.Active = 1 
								and gee.Active = 1 
								and cge.CourseId = c.Id
								and ge.Title = a.Title
							for xml path('')
							), 1, 2, '') 
						)
						from (select distinct ge.Title,ge.SortOrder
						from CourseGeneralEducation cge 
							inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
						where cge.Active = 1 
							and ge.Active = 1
							and cge.CourseId = c.Id
							and ge.Id in (5,15,16,17,18,20,23)) a
						order by a.SortOrder
						for xml path('') 
						)
					, 1, 2, '') 
				)
			, '~@', ', ')
			, replace(
				concat('',
					stuff(
						(select concat('~@', stuff((
							select '~@'+ coalesce(case when ge.id in (13,25) then LEFT(gee.text,1) else gee.text end, '')
							from CourseGeneralEducation cge
								inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
								inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
							where cge.Active = 1 
								and gee.Active = 1 
								and cge.CourseId = c.Id
								and ge.Title = a.Title
							for xml path('')
							), 1, 2, '') 
						)
						from (select distinct ge.Title,ge.SortOrder
						from CourseGeneralEducation cge 
							inner join GeneralEducation ge on cge.GeneralEducationId = ge.Id
						where cge.Active = 1 
							and ge.Active = 1
							and cge.CourseId = c.Id
							and ge.Id in (6,11,12,13,14,19,21,25)) a
						order by a.SortOrder
						for xml path('') 
						)
					, 1, 2, '') 
				)
			, '~@',', ')
			, stuff(CB03.Code, Len(CB03.Code)-1, 0, '.')
			, c.Id
			, s.SubjectCode
			, c.CourseNumber
			, c.Title
			, cd.Variable
			, cd.MinCreditHour
			, cd.MaxCreditHour
			, cd.MinLectureHour
			, cd.MaxLectureHour
			, cd.MinLabHour
			, cd.MaxLabHour
			, cd.MinContHour
			, cd.MaxContHour
			, ta.[Description]
			, REQ.[Text] as Requisite
			, limit.[Text]
			, prep.[Text]
			, lTrim(rTrim(c.[Description]))
			, gon.Title -- course grading
			, yn.Title --isrepeatable
			, rl.Code --repeatcode
			, r.Code --times repeated
			, cs.Code --suffix
			, c.PatternNumber --CID
			, cwes.Title --CID Status
			, c.TangibleProperty --CID Notes
			, cp.TimesOfferedRationale --admin repeat
			, cyt.IsComment
			, CB04.Id as CourseType
		from Course c
			inner join @entityList_internal eli on c.Id = eli.CourseId
			inner join CourseDescription cd on c.Id = cd.CourseId
			inner join CourseProposal cp on cd.CourseId = cp.CourseId
			inner join Coursecbcode ccc on c.Id = ccc.CourseId
			left join CourseCBCode ccbc on ccbc.CourseId = c.Id
			left join CB03 on ccbc.CB03Id = CB03.Id
			left join CB04 on ccbc.CB04Id = CB04.Id
			left join [Subject] s on c.SubjectId = s.Id
			left join GradeOption gon on cd.GradeOptionId = gon.Id
			left join CourseYesNo cyn on c.Id = cyn.CourseId
			left join YesNo yn on cyn.YesNo05Id = yn.Id
			left join TransferApplication ta on ta.Id = cd.TransferAppsId
			left join RepeatLimit rl on rl.Id = cp.RepeatlimitId
			left join Repeatability r on r.Id = cp.RepeatabilityId
			left join CourseSuffix cs on cs.Id = c.CourseSuffixId
			left join ContinuingWorkforceEducationStudyCode cwes on c.AdvancedPro_ContinuingWorkforceEducationStudyCodeId = cwes.Id
			left join CourseYearTerm cyt on c.Id = cyt.CourseId
			outer apply (
				select fn.[Text]
				from (
					select c.Id as entityId
					, @requisite_mfkccQuery as [query]
					, null as isAdmin
					, 1 as serializeRows
					, c.ClientId as client
					, null as userId
					, null as extraParams
				) p
				outer apply (
					select *
					from dbo.fnBulkResolveCustomSqlQuery(p.Query, p.serializeRows, p.entityId, p.client, p.userId, p.isAdmin, p.extraParams) q
				) fn
				where fn.QuerySuccess = 1 
				and fn.TextSuccess = 1
			) REQ
			outer apply (
				select *
				from dbo.fnBulkResolveCustomsqlquery(@limitRequisiteQuery, 1, c.Id, @clientId, NULL, NULL, NULL)
			) limit
			outer apply (
				select *
				from dbo.fnBulkResolveCustomsqlquery(@prepRequisiteQuery, 1, c.Id, @clientId, NULL, NULL, NULL)
			) prep
			--outer apply (
			--	select dbo.concatWithSepOrdered_Agg(', ', cs.Id,ReadMaterials) as CId
			--	from CourseSupply cs
			--	where cs.CourseId = c.Id
			--) cId
		;

		select eli.CourseId as Id
			, m.Model
		from @entityList_internal eli
			cross apply (
				select (
					select *
					from @entityRootData erd
					where eli.CourseId = erd.CourseId
					for json path, without_array_wrapper
				) RootData
			) erd
			cross apply (
				select (
					select eli.InsertOrder
						, json_query(erd.RootData) as RootData
					for json path
				) Model
			) m
		;
	
"
WHERE Id = 9
SET QUOTED_IDENTIFIER ON