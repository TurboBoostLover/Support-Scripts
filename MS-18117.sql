USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18117';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Report';
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
UPDATE AdminReport
SET ReportSQL = '
		/* 
			Package Courses
		*/
		select qf.Title as [Publication Status]
			, gt.Text100001 as [Catalog Publication Sequence]
			, sa.Title as [Proposal Status]
			, coalesce(div.Code, div.Title) as [School]
			, dpt.Title as [Department]
			, et.Title as [Entity Type]
			, pt.Title as [Proposal Type]
			, c.EntityTitle as [Proposal Title]
			, es.Title as [Model]
			, ftreq.Title as [Unit Type]
			, pk.EntityTitle as [Package Containing Proposal]
			, pksa.Title as [Package Status]
			, concat(
				''https://nu.curriqunet.com/Form/Course/Index/''
				, c.Id
			) as [CNET Link - Proposal]
			, case
				when pk.StatusAliasId = 629--Approved
					then prp.ImplementDate
				else null
			end as [Effective Date]
		from Proposal prp
			inner join Package pk on pk.ProposalId = prp.Id
				and pk.Active = 1
			left join PackageCourse pkc on pkc.PackageId = pk.Id
			left join Course c on pkc.CourseId = c.Id
				and c.Active = 1
			left join CourseEntrySkill ces on ces.CourseId = c.Id
			left join EntrySkill es on ces.EntrySkillId = es.Id
			inner join [Subject] s on c.SubjectId = s.Id
			inner join OrganizationSubject os on os.SubjectId = s.Id
				and os.Active = 1	
			left join CourseDescription cdesc on cdesc.CourseId = c.Id
			inner join CourseAttribute ca on ca.CourseId = c.Id
			left join FieldTripRequisite ftreq on cdesc.FieldTripReqsId = ftreq.Id
			inner join ProposalType pt on c.ProposalTypeId = pt.Id
			left join StatusAlias sa on c.StatusAliasId = sa.Id
			inner join EntityType et on pt.EntityTypeId = et.Id
			inner join StatusAlias pksa on pk.StatusAliasId = pksa.Id
			inner join OrganizationLink ol on os.OrganizationEntityId = ol.Child_OrganizationEntityId
				and ol.Active = 1
			inner join OrganizationEntity div on ol.Parent_OrganizationEntityId = div.Id
			inner join OrganizationEntity dpt on ol.Child_OrganizationEntityId = dpt.Id
			left join Generic1000Text gt on gt.CourseId = c.Id
			left join QFLevel qf on ca.QFLevelId = qf.Id	
		where pksa.Id in (
			633--In Review
			, 629--Approved
		) 
		and sa.StatusBaseId not in (
			1--Active
			, 5--Historical (Cancelled, Deactivated)
		)
		union
		/*
			Package Programs
		*/
		select qf.Title as [Publication Status]
			, gt.Text100001 as [Catalog Publication Sequence]
			, sa.Title as [Proposal Status]
			, coalesce(div.Code, div.Title) as [School]
			, case
				when ol.Active = 1
					then dpt.Title
				else 
					concat(
						dpt.Title
						, '' (Inactive)''
					)
			end as [Department]
			, et.Title as [Entity Type]
			, pt.Title as [Proposal Type]
			, p.EntityTitle as [Proposal Title]
			, an.[Text] as [Model]
			, aet.[Text] as [Unit Type]
			, pk.EntityTitle as [Package Containing Proposal]
			, pksa.Title as [Package Status]
			, concat(
				''https://nu.curriqunet.com/Form/Program/Index/''
				, p.Id
			) as [CNET Link - Proposal]
			, case
				when pk.StatusAliasId = 629--Approved
					then prp.ImplementDate
				else null
			end as [Effective Date]
		from Proposal prp
			inner join Package pk on pk.ProposalId = prp.Id
				and pk.Active = 1
			left join PackageProgram pkp on pkp.PackageId = pk.Id
			left join Program p on pkp.ProgramId = p.Id
				and p.Active = 1
			left join ProgramAwardNote pan on pan.ProgramId = p.Id
			left join AwardNote an on pan.AwardNoteId = an.Id
			left join ProgramAdmissionExamType paet on paet.ProgramId = p.Id
			left join AdmissionExamType aet on paet.AdmissionExamTypeId = aet.Id
			inner join ProposalType pt on p.ProposalTypeId = pt.Id
			inner join EntityType et on pt.EntityTypeId = et.Id
			left join StatusAlias sa on p.StatusAliasId = sa.Id
			inner join StatusAlias pksa on pk.StatusAliasId = pksa.Id
			left join OrganizationLink ol on p.Tier2_OrganizationEntityId = ol.Child_OrganizationEntityId
				and ol.Active = 1
			left join OrganizationEntity div on ol.Parent_OrganizationEntityId = div.Id
			left join OrganizationEntity dpt on coalesce(ol.Child_OrganizationEntityId, p.Tier2_OrganizationEntityId) = dpt.Id
			left join Generic1000Text gt on gt.ProgramId = p.Id
			left join QFLevel qf on p.QFLevelId = qf.Id
		where pksa.Id in (
			633--In Review
			, 629--Approved
		) 
		and sa.StatusBaseId not in (
			1--Active
			, 5--Historical (Cancelled, Deactivated)
		)
		union
		/* 
			Courses
		*/
		select qf.Title as [Publication Status]
			, gt.Text100001 as [Catalog Publication Sequence]
			, sa.Title as [Proposal Status]
			, coalesce(div.Code, div.Title) as [School]
			, dpt.Title as [Department]
			, et.Title as [Entity Type]
			, pt.Title as [Proposal Type]
			, c.EntityTitle as [Proposal Title]
			, es.Title as [Model]
			, ftreq.Title as [Unit Type]
			, ''N/A'' as [Package Containing Proposal]
			, ''N/A'' as [Package Status]
			, concat(
				''https://nu.curriqunet.com/Form/Course/Index/''
				, c.Id
			) as [CNET Link - Proposal]
			, case
				when c.StatusAliasId = 629--Approved
					then prp.ImplementDate
				else null
			end as [Effective Date]
		from Proposal prp
			inner join Course c on prp.Id = c.ProposalId
				and c.Active = 1
			left join CourseEntrySkill ces on ces.CourseId = c.Id
			left join EntrySkill es on ces.EntrySkillId = es.Id
			inner join [Subject] s on c.SubjectId = s.Id
			inner join OrganizationSubject os on os.SubjectId = s.Id
				and os.Active = 1	
			left join CourseDescription cdesc on cdesc.CourseId = c.Id
			inner join CourseAttribute ca on ca.CourseId = c.Id
			left join FieldTripRequisite ftreq on cdesc.FieldTripReqsId = ftreq.Id
			inner join ProposalType pt on c.ProposalTypeId = pt.Id
			inner join StatusAlias sa on c.StatusAliasId = sa.Id
			inner join EntityType et on pt.EntityTypeId = et.Id
			inner join OrganizationLink ol on os.OrganizationEntityId = ol.Child_OrganizationEntityId
				and ol.Active = 1
			inner join OrganizationEntity div on ol.Parent_OrganizationEntityId = div.Id
			inner join OrganizationEntity dpt on ol.Child_OrganizationEntityId = dpt.Id
			left join Generic1000Text gt on gt.CourseId = c.Id
			left join QFLevel qf on ca.QFLevelId = qf.Id	
		where sa.Id in (
			633--In Review
			, 629--Approved
		) 
		and sa.StatusBaseId not in (
			1--Active
			, 5--Historical (Cancelled, Deactivated)
		)
		union
		/*
			Programs
		*/
		select qf.Title as [Publication Status]
			, gt.Text100001 as [Catalog Publication Sequence]
			, sa.Title as [Proposal Status]
			, coalesce(div.Code, div.Title) as [School]
			, case
				when ol.Active = 1
					then dpt.Title
				else 
					concat(
						dpt.Title
						, '' (Inactive)''
					)
			end as [Department]
			, et.Title as [Entity Type]
			, pt.Title as [Proposal Type]
			, p.EntityTitle as [Proposal Title]
			, an.[Text] as [Model]
			, aet.[Text] as [Unit Type]
			, ''N/A'' as [Package Containing Proposal]
			, ''N/A'' as [Package Status]
			, concat(
				''https://nu.curriqunet.com/Form/Program/Index/''
				, p.Id
			) as [CNET Link - Proposal]
			, case
				when p.StatusAliasId = 629--Approved
					then prp.ImplementDate
				else null
			end as [Effective Date]
		from Proposal prp
			inner join Program p on prp.Id = p.ProposalId
				and p.Active = 1
			left join ProgramAwardNote pan on pan.ProgramId = p.Id
			left join AwardNote an on pan.AwardNoteId = an.Id
			left join ProgramAdmissionExamType paet on paet.ProgramId = p.Id
			left join AdmissionExamType aet on paet.AdmissionExamTypeId = aet.Id
			inner join ProposalType pt on p.ProposalTypeId = pt.Id
			inner join EntityType et on pt.EntityTypeId = et.Id
			inner join StatusAlias sa on p.StatusAliasId = sa.Id
			left join OrganizationLink ol on p.Tier2_OrganizationEntityId = ol.Child_OrganizationEntityId
				and ol.Active = 1
			left join OrganizationEntity div on ol.Parent_OrganizationEntityId = div.Id
			left join OrganizationEntity dpt on coalesce(ol.Child_OrganizationEntityId, p.Tier2_OrganizationEntityId) = dpt.Id
			left join Generic1000Text gt on gt.ProgramId = p.Id
			left join QFLevel qf on p.QFLevelId = qf.Id
		where sa.Id in (
			633--In Review
			, 629--Approved
		) 
		and sa.StatusBaseId not in (
			1--Active
			, 5--Historical (Cancelled, Deactivated)
		)
		union
		/*
			Modules
		*/
		select qf.Title as [Publication Status]
			, COALESCE(m.Notes, crn.LongText01) as [Catalog Publication Sequence]
			, sa.Title as [Proposal Status]
			, coalesce(div.Code, div.Title) as [School]
			, coalesce(dpt.Title, crn.ShortText02) as [Department]
			, et.Title as [Entity Type]
			, pt.Title as [Proposal Type]
			, COALESCE(m.EntityTitle, m.title) as [Proposal Title]
			, an.[Text] as [Model]
			, aet.[Text] as [Unit Type]
			, ''N/A'' as [Package Containing Proposal]
			, ''N/A'' as [Package Status]
			, concat(
				''https://nu.curriqunet.com/Form/Module/Index/''
				, m.Id
			) as [CNET Link - Proposal]
			, case
				when m.StatusAliasId = 629--Approved
					then prp.ImplementDate
				else null
			end as [Effective Date]
		from Proposal prp
			inner join Module m on prp.Id = m.ProposalId
				and m.Active = 1
			left join ModuleAwardNote man on man.ModuleId = m.Id
			left join ModuleCRN as crn on crn.ModuleId = m.Id
			left join AwardNote an on man.AwardNoteId = an.Id
			left join ModuleAdmissionExamType maet on maet.ModuleId = m.Id
			left join AdmissionExamType aet on maet.AdmissionExamTypeId = aet.Id
			inner join ProposalType pt on m.ProposalTypeId = pt.Id
			inner join EntityType et on pt.EntityTypeId = et.Id
			inner join StatusAlias sa on m.StatusAliasId = sa.Id
			inner join ModuleDetail md on m.Id = md.ModuleId
			left join OrganizationLink ol on md.Tier2_OrganizationEntityId = ol.Child_OrganizationEntityId
				and ol.Active = 1
			left join OrganizationEntity div on ol.Parent_OrganizationEntityId = div.Id
			left join OrganizationEntity dpt on coalesce(ol.Child_OrganizationEntityId, md.Tier2_OrganizationEntityId) = dpt.Id
			left join QFLevel qf on md.QFLevelId = qf.Id
		where sa.Id in (
			633--In Review
			, 629--Approved
		) 
		and sa.StatusBaseId not in (
			1--Active
			, 5--Historical (Cancelled, Deactivated)
		)
		order by pksa.Title, pk.EntityTitle, et.Title, sa.Title, [School], dpt.Title, [Proposal Title];
'
WHERE Id = 10