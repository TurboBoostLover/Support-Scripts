use nocccd

INSERT INTO MetaSelectedFieldAttribute
(Name ,Value, MetaSelectedFieldId)
SELECT 'listitemtype', 1, MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId in (4046, 5555, 1594)
union
SELECT 'listitemtype', 2, MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId in (6458)
union
SELECT 'listitemtype', 3, MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId in (6459)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
declare @results table (Value int, Text varchar(max), FilterValue int);    
declare @courseid int = (SELECT CourseId FROM ProgramSequence WHERE Id = @pkidValue)    
	declare @requisiteTable table( SortOrder int, Title nvarchar(max));
	declare @igetcTable table( SortOrder int, Title nvarchar(max));
	declare @csugeTable table( SortOrder int, Title nvarchar(max));
	declare @smcgeTable table( SortOrder int, Title nvarchar(max));
	
	insert 
		into @requisiteTable (SortOrder, Title)
		select
			row_number() over (order by cr.SortOrder, cr.Id) as SortOrder,
			isnull(''<li class="list-group-item-compact"><strong>'' + rt.Title + '':</strong> '' + s.SubjectCode + '' '' + rc.CourseNumber + ''</li>'',''<li class="list-group-item-compact"><strong>'' + rt.Title + '':</strong> '' + cr.CourseRequisiteComment + ''</li>'') + isnull('' '' + con.Title,'''') as Title
		from
			Course c
			inner join CourseRequisite cr
			left join Condition con on con.Id = cr.ConditionId on cr.CourseId = c.Id
			left join Course rc on cr.Requisite_CourseId = rc.Id
			left join Subject s on rc.SubjectId = s.Id
			inner join RequisiteType rt on cr.RequisiteTypeId = rt.Id
		where
			c.Id = @courseid
		order by 
			cr.SortOrder
			
		insert into 
			@igetcTable (SortOrder, Title)
			select
				row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,
				''<li class="list-group-item-compact">'' + gee.Title + ''</li>'' as Title
			from
				CourseGeneralEducation cge
				inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
				inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id
				inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id
			where
				CourseId = @courseid
				and geg.Id = 1
				and geg.Active = 1
				and ge.Active = 1
				and gee.Active = 1;
				
			insert into 
				@csugeTable (SortOrder, Title)
			select
				row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,
				''<li class="list-group-item-compact">'' + gee.Title + ''</li>'' as Title
			from
				CourseGeneralEducation cge
				inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
				inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id
				inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id
			where
				CourseId = @courseid  and geg.Id = 2  and geg.Active = 1  and ge.Active = 1  and gee.Active = 1;
			
			insert into 
				@smcgeTable (SortOrder, Title)
			select
				row_number() over (order by geg.Id, ge.Title, gee.Title) as SortOrder,
				''<li class="list-group-item-compact">'' + gee.Title + ''</li>'' as Title
			from
				CourseGeneralEducation cge
				inner join GeneralEducationElement gee on cge.GeneralEducationElementId = gee.Id
				inner join GeneralEducation ge on gee.GeneralEducationId = ge.Id
				inner join GeneralEducationGroup geg on ge.GeneralEducationGroupId = geg.Id
			where
				CourseId = @courseid
				and geg.Id = 3
				and geg.Active = 1
				and ge.Active = 1
				and gee.Active = 1;
			
			declare @requisites nvarchar(max) = 
				(select 
					dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedRequisites+dbo.fnHtmlCloseTag(''ol'') as Text
				from 
					(select
						dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedRequisites
					from 
						@requisiteTable rt) cli);
						
			declare @igetc nvarchar(max) = 
				(select dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold font-italic py-1''))+''IGETC''+dbo.fnHtmlCloseTag(''label'')+dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedIGETC+dbo.fnHtmlCloseTag(''ol'') as Text
				from (
					select
						dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedIGETC
					from
						@igetcTable rt) cli);
						
			declare @csuge nvarchar(max) = 
				(select 
					dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold font-italic py-1''))+''CSU GE''+dbo.fnHtmlCloseTag(''label'')+dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedCSUGE+dbo.fnHtmlCloseTag(''ol'') as Text
				from (
					select
						dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedCSUGE
					from
						@csugeTable rt) cli);
						
			declare @smcge nvarchar(max) = 
				(select
					dbo.fnHtmlOpenTag(''label'', dbo.fnHtmlAttribute(''class'', ''font-weight-bold font-italic py-1''))+''SMC GE''+dbo.fnHtmlCloseTag(''label'')+dbo.fnHtmlOpenTag(''ol'', dbo.fnHtmlAttribute(''class'', ''list-group px-2''))+cli.CombinedSMCGE+dbo.fnHtmlCloseTag(''ol'') as Text
				from (
					select
						dbo.ConcatWithSepOrdered_Agg(null, SortOrder, Title) as CombinedSMCGE
					from 
						@smcgeTable rt) cli);
						
			declare @gc nvarchar(max) = 
				(select 
					''<li class="list-group-item-compact py-2"><strong><i class="fa fa-globe pr-1"></i>Satisfies Global Citizenship</strong></li>''
				from 
					CourseGlobalCitizenship cgc 
				where 
					IsApproved = 1 and CourseId = @courseid);
					
			declare @de nvarchar(max) = 
				(select 
					''<li class="list-group-item-compact py-2"><strong><i class="pr-1"></i>Transfers to ''+ 
					case 
						when ComparableCsuUc = 1 AND ISCSUTransfer = 1 
						then ''UC/CSU'' 
						when ComparableCsuUc = 1 
						then ''CSU'' 
						when ISCSUTransfer = 1 
						then ''UC'' 
					else null 
					end +''</strong></li>'' 
				from 
					Course 
				where 
					(ComparableCsuUc = 1 OR ISCSUTransfer = 1) and Id = @courseid);  
					
					----------------------------------------------------  
					
					insert into @results (Value,Text,FilterValue)
					
					select 
						0 as Value, 
						concat( dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''pl-2 pr-2 pb-2 pt-0'')) + @requisites + dbo.fnHtmlCloseTag(''div''), dbo.fnHtmlOpenTag(''div'', dbo.fnHtmlAttribute(''class'', ''px-2''))+concat(@igetc, @csuge, @smcge)+dbo.fnHtmlCloseTag(''div''),dbo.fnHtmlOpenTag(''div'','''')+concat(@gc,@de)+dbo.fnHtmlCloseTag(''div'')) as Text, 
						@courseid as FilterValue
						
					delete from 
						@requisiteTable;  
						
					delete from 
						@igetcTable;  
						
					delete from 
						@csugeTable;  
						
					delete from 
						@smcgeTable;
		
			
			select * from @results
			WHERE FilterValue = (			
			SELECT CourseId FROM ProgramSequence WHERE Id = @pkidValue
			);
'
WHERE Id = 495

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()