USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19054';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text for Program Pathway report';
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
DECLARE @Id int = 64

DECLARE @SQL NVARCHAR(MAX) = '
		drop table if exists #MaxSequence;

		select pcpp.ProgramPathwayId, max(pcpp.Lookup11Id) as MaxSequenceId#
		into #MaxSequence
		from ProgramSequenceProgramPathway pcpp
		inner join ProgramPathway pp on pp.Id = pcpp.ProgramPathwayId
			and pp.ProgramId = @entityId
		group by pcpp.ProgramPathwayId;

		drop table if exists #MissedSequenceNumber;

		create table #MissedSequenceNumber (
		ProgramPathwayId int,
		SequenceId# int,
		MissedSeqIdentifier nvarchar(2)
		);

		declare @ProgramPathwayId int = (select top 1 ProgramPathwayId from #MaxSequence);
		declare @MaxSequence# int = (select top 1 MaxSequenceId# from #MaxSequence where ProgramPathwayId = @ProgramPathwayId);

		while @ProgramPathwayId is not null
		begin
		merge #MissedSequenceNumber as target   
		using (    
			select l11.Id as SequenceId#
				, @ProgramPathwayId as ProgramPathwayId
				, '' *'' as MissedSeqIdentifier
			from Lookup11 l11
			where l11.Lookup11ParentId = 1 
			and not exists (
				select 1
				from ProgramSequenceProgramPathway pcpp
				where l11.Id = pcpp.Lookup11Id 
				and pcpp.ProgramPathwayId = @ProgramPathwayId     
			)   
		) as source (SequenceId#, ProgramPathwayId, MissedSeqIdentifier)   
		on (1 = 0)   
		when not matched
		and source.SequenceId# <= @MaxSequence#
		then
			insert (ProgramPathwayId, SequenceId#, MissedSeqIdentifier)   
			values (source.ProgramPathwayId, source.SequenceId# + 1, MissedSeqIdentifier)
		;

		delete
		from #MaxSequence
		where ProgramPathwayId = @ProgramPathwayId;

		set @ProgramPathwayId = (select top 1 ProgramPathwayId from #MaxSequence);

		set @MaxSequence# = (select top 1 MaxSequenceId# from #MaxSequence where ProgramPathwayId = @ProgramPathwayId);
		end;

		drop table if exists #DuplicateSequence;

		with BaseQuery as (
		select pcpp.ProgramPathwayId
			, pcpp.Lookup11Id
			, count(pcpp.Lookup11Id) as records
		from ProgramSequenceProgramPathway pcpp
			inner join ProgramPathway pp on pp.Id = pcpp.ProgramPathwayId
				and ProgramId = @entityId
		group by pcpp.ProgramPathwayId, pcpp.Lookup11Id
		)
		select ProgramPathwayId
		, Lookup11Id
		, '' *'' as DuplicateIdentifier
		into #DuplicateSequence
		from BaseQuery bq
		inner join Lookup11 l11 on l11.Id = bq.Lookup11Id
		where records > 1;

		drop table if exists #ProgramPathways;

		select Id, ShortText, row_number() over (order by ShortText) as SortOrder
		into #ProgramPathways
		from ProgramPathway
		where ProgramId = @entityId;

		declare @certs table (Id int identity, CertId int, Title varchar(200));

		insert into @certs (CertId, Title)
		select distinct ec.Id, isNull(ec.Title , '''')
		from ProgramSequence pc
		inner join ProgramSequenceExternalCertificate pcec on pc.Id = pcec.ProgramSequenceId
		inner join ExternalCertificate ec on pcec.ExternalCertificateId = ec.Id
		where pc.EmbeddedIndustryCertificate_YesNoId = 1 
		and pc.ProgramId = @entityId;

		declare @SequenceTemp table (
		[Value] int,
		[Text] nvarchar(max),
		Seq# Int,
		SequenceFlag nvarchar (100),
		Coursetype nvarchar (100),
		Course nvarchar (max)      
		);

		declare @ConCatSequence nvarchar(max);

		declare @FullConcat table (
		Sort int,
		[Text] nvarchar(max)
		);

		declare @Pathway int = (select top 1 Id from #ProgramPathways order by SortOrder);

		declare @PathwayTitle nvarchar(500) = (select ShortText from #ProgramPathways where Id = @Pathway);

		declare @Sort int = (select Sortorder from #ProgramPathways where Id = @Pathway);

		while @Pathway is not null
		begin
		declare @FootNotes table  (Id int identity, ProgramCourseid int, IsSpcCert bit, isCA bit, [Text] nvarchar(max), SortOrder int, Seq int);

		insert into @FootNotes (ProgramCourseId, IsSpcCert, [Text], Seq, isCA)
		select fn.Id
			, 1
			, dbo.ConcatWithSepOrdered_Agg('', '', fn.SortOrder, coalesce(''<a href="../../../DynamicReports/AllFieldsReportByEntity/''+ cast(fn.ProgramId as nvarchar) + ''?entityType=Program&reportId=''+cast(Case when fn.ClientEntitySubTypeId = 1 then 236 else 218 END as nvarchar)+ ''" target="_blank">''+ 
				--case
				--	when pc.ItemTypeId = 12 then p.entityTitle
				--		else p.Associations
				--	End +
				fn.Associations +
			''</a>'', ''''))
			, fn.ShortText
			, case
				when fn.ClientEntitySubTypeId = 1
					then 1
				else 0
			End as isCA
		from (
			select pc.Id, row_number() over (partition by pc.Id order by p.Associations) as SortOrder
				, l11.ShortText, CASE WHEN p.StatusAliasId <> 1 and p2.Id IS NOT NULL THEN p2.Id ELSE p.Id END as ProgramId, pt.ClientEntitySubTypeId, p.Associations
			from ProgramSequence pc
					inner join ProgramSequenceProgramPathway pcpp on (pc.Id = pcpp.ProgramSequenceId
						and pcpp.ProgramPathwayId = @Pathway
					)
					inner join ProgramSequenceProgram pcp on pc.Id = pcp.ProgramSequenceId
					inner join Program p on pcp.Related_ProgramId = p.Id
						LEFT JOIN Program AS p2 on p.BaseProgramId = p2.BaseProgramId and p2.StatusAliasId = 1
					inner join ProposalType pt on p.ProposalTypeId = pt.Id
					inner join Lookup11 l11 on l11.Id = pcpp.Lookup11Id
				where (pc.EmbeddedSPCCertificate_YesNoId = 1 or pc.ItemTypeId = 12)
				and pc.ProgramId = @entityId
			--order by 1, 2
		) fn
		group by fn.Id, fn.ShortText, fn.ClientEntitySubTypeId;

		insert into @FootNotes (ProgramCourseId, IsSpcCert, [Text], Seq)
		select pc.Id, 0, dbo.ConcatWithSepOrdered_Agg('', '', ec.Id, isNull(ec.Title, '''')), l11.ShortText
		from ProgramSequence pc
			inner join ProgramSequenceProgramPathway pcpp on (pc.Id = pcpp.ProgramSequenceId
				and pcpp.ProgramPathwayId = @Pathway
			)
			inner join Lookup11 l11 on l11.Id = pcpp.Lookup11Id
			inner join ProgramSequenceExternalCertificate pcec on pc.Id = pcec.ProgramSequenceId
			inner join @certs ec on pcec.ExternalCertificateId = ec.CertId
		where pc.EmbeddedIndustryCertificate_YesNoId = 1 
		and pc.ProgramId = @entityId
		group by pc.Id, l11.ShortText;

		update @FootNotes
		set sortorder = sorted.rownum
		from @FootNotes fn
			inner join (
				select Id, row_number() over (order by fn1.Seq asc, fn1.IsSpcCert desc) rownum 
				from @FootNotes fn1
			) sorted on fn.Id = sorted.Id
		;

		declare @exception table (ExceptionIdent varchar(max), Exception varchar(max));

		insert into @exception (Exception, ExceptionIdent)
		select distinct OrHigherException, ExceptionIdentifier
		from ProgramSequenceDetail pd 	
			inner join ProgramSequenceProgramPathway pcpp on (pd.ProgramSequenceId = pcpp.ProgramSequenceId
				and pcpp.ProgramPathwayId = @Pathway
			)
		where OrHigherException is not null
		and len(OrHigherException) > 0;

		with ProgramCourses as (
			select CourseId
			from ProgramSequence
			where ProgramId = @entityId
		)
		, ReportUrl as (
			select  c.Id as CourseId, cr.MetaReportId, ''../../../DynamicReports/AllFieldsReportByEntity/'' + CASE WHEN c.StatusAliasId <> 1 and c2.Id IS NOT NULL THEN cast(c2.Id as nvarchar) ELSE cast(c.Id as nvarchar) END + ''?entityType=Course&reportId='' + cast(cr.MetaReportId as nvarchar) as reportUrl
			from Course c
				inner join ProgramCourses pc on pc.CourseId = c.Id
				inner join MetaTemplate mt on c.MetaTemplateId = mt.MetaTemplateId
				LEFT JOIN Course AS c2 on c.BaseCourseId = c2.BaseCourseId and c2.StatusAliasId = 1
				outer apply (
					select top 1 mr.Id as MetaReportId
					from MetaReportTemplateType mrtt
						inner join MetaReport mr on mrtt.MetaReportId = mr.Id
					where mr.Title = ''Approved Course Outline'' /*MetaReportTypeId 1 = (Course) Outline*/
					and mrtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
					order by mrtt.Id
				) cr
		)
		, hasRequisites as (
			select ru.CourseId
				, case
					when cr.Id is not null
						then ''<a href="'' + ReportUrl + ''" target="_blank">Y</a>''
					else ''<a href="'' + ReportUrl + ''" target="_blank">N</a>''
				end as HasRequisites
			from ReportUrl ru
				left join CourseRequisite cr on ru.CourseId = cr.CourseId
		)
		, Terms as (
			select cs.CourseId, dbo.ConcatWithSepOrdered_Agg('', '', cs.SortOrder, cs.Term) as Term
			from (
				select cs.CourseId
					, sem.SortOrder
					, case
						when cs.SemesterId = 1
							then ''F''
						when cs.SemesterId = 2
							then ''Sp''
						when cs.SemesterId = 3
							then ''Su''
						when cs.SemesterId = 4
							then ''OnDmd''
						else ''''
					end as Term
				from CourseSemester cs
					inner join Semester sem on cs.SemesterId = sem.Id
				where exists(
					select top 1 1
					from ProgramSequence ps
					where cs.CourseId = ps.CourseId
					and ps.ProgramId = @entityId
				)
				group by cs.CourseId, sem.SortOrder, cs.SemesterId
			) cs
			group by cs.CourseId
		)
		, CourseSequence as (
			select l11.ShortText as Seq#
				, ''<span Style="display: font-weight: bold; Color: Red;"><sup>'' + coalesce(DuplicateIdentifier, '''')  + ''</sup></span>'' as DuplicateIdentifier
				, ''<span Style="display: font-weight: bold; Color: Red;"><sup>'' + coalesce(MissedSeqIdentifier, '''')  + ''</sup></span>'' as MissedSeqIdentifier
				, sf.Title as SequenceFlag
				, case
					when pc.EmbeddedSPCCertificate_YesNoId = 1  
						then (
							select fn.[Text]
							from @FootNotes fn
							where fn.ProgramCourseid = pc.Id
							and fn.IsSpcCert = 1
							and isCA = 0
						)
					else ''''
				end as SPCCert
				,case
					when pc.ItemTypeId = 12
						then (
							select fn.[Text]
							from @FootNotes fn
							where fn.ProgramCourseid = pc.Id
							and fn.IsSpcCert = 1
							and isCA = 1
						)
					else ''''
				end as SPCCertCA
				, case
					when pc.EmbeddedIndustryCertificate_YesNoId = 1
						then (
							select top 1 fn.[Text]
							from @FootNotes fn
							where fn.ProgramCourseid = pc.Id
							and fn.isSpcCert = 0
						)
					else ''''
				end as INDCert
				, t.Term
				--, bt.Title AS BlockType
				, (CASE 
					WHEN pc.ListItemTypeId = 11
					THEN pc.ItemTitle
					ELSE concat(''<a href="'',rep.reportUrl,''" target="blank">'',coalesce(s.SubjectCode + '' '' + c.CourseNumber + '' '' + C.Title, cod.Requirement), '' '' + cod.ExceptionIdentifier,''</a>'')end) as Course
				, cast(convert(decimal(10, 0), pc.CalcMin) as nvarchar) as MinCredit
				, cast(convert(decimal(10, 0), pc.CalcMax) as nvarchar) as MaxCredit
				, null as MinOverride
				, null as MaxOverride
				, pc.CalcMin as MinCreditHr
				, pc.CalcMax as MaxCreditHr
				, ctp.Title as Coursetype
				, HasRequisites
			from ProgramSequence pc 
				inner join ProgramSequenceProgramPathway pcpp on (pc.Id = pcpp.ProgramSequenceId
					and pcpp.ProgramPathwayId = @Pathway
				)
				inner join ProgramPathway pp on pp.Id = pcpp.ProgramPathwayId
				left join #DuplicateSequence ds on (ds.ProgramPathwayId = pp.Id
					and ds.Lookup11Id = pcpp.Lookup11Id
				)
				left join #MissedSequenceNumber msn on (msn.ProgramPathwayId = pp.Id
					and msn.SequenceId# = pcpp.Lookup11Id
				)
				left join Lookup11 l11 on l11.Id = pcpp.Lookup11Id
				inner join SequenceFlag sf on sf.Id = pcpp.SequenceFlagId
				left join ProgramSequenceDetail cod on pc.Id = cod.ProgramSequenceId
				--left join CreditHourChangeType chct on chct.Id = cod.CreditHourChangeTypeId
				left join Course c on c.Id = pc.CourseId
				left join [Subject] s on c.subjectId = s.Id
				left join Terms t on t.CourseId = c.Id
				left join HasRequisites hr on hr.CourseId = c.Id
				left join CoursetypeProgram ctp on ctp.Id = cod.CoursetypeProgramId
				left join CourseDescription cd on cd.CourseId = c.Id
				left join ReportUrl rep on c.Id = rep.CourseId
				--inner join BlockType bt on (bt.Id = co.BlocktypeId)
		)
		insert into @SequenceTemp
			select 1 as [Value]
				, ''<div style="display: table; width: 100%; border-left: 1px #808080 solid;border-right: 1px #808080 solid;border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">                   
				<div Style="display: table-caption;text-align: center;font-size: 20px;font-weight: bold;">
					'' + @PathwayTitle + 
				''</div>
				<div style="display: table-row;">
					<div style="width:50px; display: table-cell;text-align: Center; font-weight: bold; border-left: 1px #808080 solid;border-right: 1px #808080 solid; border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;backGround-color: #C6C2C2; white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">
						Seq #
					</div>
					<div style="display: table-cell;text-align: Center; font-weight: bold;border-left: 1px #808080 solid;border-right: 1px #808080 solid;border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;backGround-color: #C6C2C2;width:50px; white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">
						Course <br>Options
					</div>
					<div style="width:400px;display: table-cell;text-align: Center; font-weight: bold;border-left: 1px #808080 solid;border-right: 1px #808080 solid;border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;backGround-color: #C6C2C2; white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">
						Course
					</div>
					<div style="width:50px; display: table-cell;text-align: Center; font-weight: bold; border-left: 1px #808080 solid;border-right: 1px #808080 solid; border-top: 1px #808080 solid;border-bottom: 1px #808080 solid; backGround-color: #C6C2C2; white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">
						Credits
					</div>
					<div style="width:50px; display: table-cell;text-align: Center; font-weight: bold; border-left: 1px #808080 solid;border-right: 1px #808080 solid; border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;backGround-color: #C6C2C2;width:50px; white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">
						Course <br>Type
					</div>'' +
					''<div style="width:50px; display: table-cell;text-align: Center; font-weight: bold; border-left: 1px #808080 solid;border-right: 1px #808080 solid; border-top: 1px #808080 solid;border-bottom: 1px #808080 solid; backGround-color: #C6C2C2; white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">
						Term(s)
					</div>
					<div style="width:50px; display: table-cell;text-align: Center; font-weight: bold; border-left: 1px #808080 solid;border-right: 1px #808080 solid; border-top: 1px #808080 solid;border-bottom: 1px #808080 solid; backGround-color: #C6C2C2; white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">
						Reqs
					</div>
					<div style=" width:175px; display: table-cell;text-align: Center; font-weight: bold; border-left: 1px #808080 solid;border-right: 1px #808080 solid; border-top: 1px #808080 solid;border-bottom: 1px #808080 solid; backGround-color: #C6C2C2; white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">
						Possible Earned Credit: <br>Articulations
					</div>
					<div style=" width:175px; display: table-cell;text-align: Center; font-weight: bold; border-left: 1px #808080 solid;border-right: 1px #808080 solid; border-top: 1px #808080 solid;border-bottom: 1px #808080 solid; backGround-color: #C6C2C2; white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">
						SPC Certificates
					</div>
					<div style="display: table-cell;text-align: Center; font-weight: bold; border-left: 1px #808080 solid;border-right: 1px #808080 solid; border-top: 1px #808080 solid;border-bottom: 1px #808080 solid; backGround-color: #C6C2C2;width:175px; white-space: nowrap;overflow: hidden;text-overflow: ellipsis;">
						Industry Certifications
					</div>'' + 
				''</div>'' as [Text]
				, null as Seq#
				, null as SequenceFlag
				, null as Coursetype
				, null as Course
			union
			select coalesce(Seq# + '' '', 2) as [Value]
				, ''<div style="display: table-row;'' +
				case when MissedSeqIdentifier like ''%*%'' or DuplicateIdentifier like ''%*%'' then '' color: Red '' else '' '' end + ''">''  +
				''<div style="display: table-cell;text-align: Left;
				border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;" >'' +
				coalesce(Seq# + '' '' + coalesce(cs.DuplicateIdentifier, '''') + coalesce(MissedSeqIdentifier, ''''), ''None'') +
				''</div>'' + ''<div style="display: table-cell;text-align: Left;
				border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">'' +
				coalesce(SequenceFlag + '' '', '' '') + ''</div>'' + 
				''<div style="display: table-cell;text-align: Left;
				border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">'' +
				coalesce(Course + '' '', '' '') + ''</div>'' +
				''<div style="display: table-cell;text-align: Left;
				border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">'' +
				coalesce(case when MinCredit = MaxCredit or MaxCredit is null or MinCredit is null then coalesce(MinCredit, MaxCredit) else MinCredit + ''-'' + MaxCredit end,
				'' '') + ''</div>'' + ''<div style="display: table-cell;text-align: Left;
				border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">'' +
				coalesce(Coursetype + '' '', '' '') + ''</div>'' + 
				''<div style="display: table-cell;text-align: Left;
				border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">'' +
				-- coalesce(BlockType + '' '', '' '') + ''</div>'' +
				-- ''<div style="display: table-cell;text-align: Left;
				-- border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				-- border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">'' +
				coalesce(Term + '' '', '' '') + ''</div>'' +
				''<div style="display: table-cell;text-align: Left;
				border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">'' +
				coalesce(HasRequisites + '' '', '' '') + ''</div>'' +
				''<div style="display: table-cell;text-align: Left;
				border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">'' +
				coalesce(SPCCertCa + '' '', '' '') + ''</div>'' +
				''<div style="display: table-cell;text-align: Left;
				border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">'' +
				coalesce(SPCCert + '' '', '' '') + ''</div>'' +
				''<div style="display: table-cell;text-align: Left;
				border-left: 1px #808080 solid;border-right: 1px #808080 solid;
				border-top: 1px #808080 solid;border-bottom: 1px #808080 solid;">'' +
				coalesce(cs.IndCert + '' '', '' '') + ''</div>'' +
					''</div>'' as [Text]
					, Seq#
					, SequenceFlag
					, Coursetype
					, Course
			from CourseSequence cs
		;

		delete
		from @FootNotes;

		select @ConCatSequence = coalesce(@ConCatSequence, '''') + [Text]
		from @SequenceTemp  st
		order by [Value], Seq# asc, SequenceFlag desc, Coursetype, Course;

		set @ConCatSequence = @ConCatSequence + ''</div>''

		select @ConCatSequence = concat(coalesce(@ConCatSequence, ''''), ''<div style="width:100%">'', ExceptionIdent + '' - '', Exception, ''</div>'')
		from @exception ex

		insert into @FullConcat (Sort, [Text])
		values (@sort, @ConCatSequence);

		delete from @exception;

		delete
		from #ProgramPathways
		where Id = @Pathway;

		set @Pathway = (select top 1 Id from #ProgramPathways order by SortOrder);
		set @PathwayTitle = (select ShortText from #ProgramPathways where Id = @Pathway);
		set @sort = (select Sortorder from #ProgramPathways where Id = @Pathway);
		set @ConcatSequence = '''';
		delete from @SequenceTemp;
		set @Pathway = (select top 1 Id from #ProgramPathways order by SortOrder);
		end;

		declare @Output nvarchar(max);

		select @Output = coalesce(@Output, '''') + [Text]
		from @FullConcat
		order by Sort;

		--select @Output = coalesce(@Output, '''') + ''<br />'' + concat(Id, '' '', Title)
		--from @certs;

		select 1 as [Value], concat(''<style>p{display:inline;margin:0px;}</style>'', @Output) as [Text]

		drop table #ProgramPathways;
		drop table #DuplicateSequence;
		drop table if exists #Duplicates;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @Id