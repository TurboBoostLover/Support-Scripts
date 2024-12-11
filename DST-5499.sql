/*======================================================================
-- Procedure to analyze all requirements-based on show/hide logic.
-- Original Author: Thomas P Metcalf
-- Created: 01/26/2015
-- Created for JIRA ticket: UST-638
-- Updated on 07/09/2018 by Lara Dougan for DST-2686
======================================================================*/

alter procedure dbo.upUpdateEntitySectionSummary
	@entityId int = null
	,@entityTypeId int
	,@templateId int = null
	,@debug bit = 0 -- enable debug output
as

set ansi_defaults on;
set ansi_warnings off;
set concat_null_yields_null on;
set nocount on;
set quoted_identifier on;
set implicit_transactions off;
set xact_abort on;

--======================================================================
-- Debug or testing values
--======================================================================

--declare
--	@entityId int = null
--	,@entityTypeId int = 1
--	,@templateId int = 829
--;


--declare
--	@entityId int = 1200
--	,@entityTypeId int = 1
--	,@templateId int = null
--	,@debug bit = 1
--;

------------------------------------------------------------------------

declare
	@thisProcedureName sysname = N'upUpdateEntitySectionSummary'
	,@procStartTime datetime2 = sysdatetime()
	,@startTransactionCount int = @@trancount
	,@lastErrorNum int = null
	,@errorMessage nvarchar(2000) = null
	,@empty nvarchar(max) = N''
	,@indent nvarchar(max) = nchar(9) -- tab (\t)
	,@newline nvarchar(max) = nchar(10) -- newline (\n)
	,@paramDelim nvarchar(5) = ', '
	,@sql nvarchar(max) = null
	,@sqlParams nvarchar(max) = null
	,@intResult int = null
	,@curId int = null
	,@maxId int = null
	,@curEntityId int = null
	,@baseTable sysname = null
	,@entityTemplateTable sysname = null
	,@programPlanId int = null
	,@selectedSectionId int = null
	,@schemaName sysname = null
	,@tableName sysname = null
	,@columnName sysname = null
	,@metadataAttributeMapId int = null
	,@minElem int = null
	,@metaControlAttributeId int = null
	,@targetValue int = null
;

if @entityId < 1
	set @entityId = null
;

if @templateId < 1
	set @templateId = null
;

if @debug is null
	set @debug = 0
;

if @debug = 1
begin
	set ansi_warnings on;

	print concat(@empty, @thisProcedureName
		,': Starting...'
		,' (start time: ', @procStartTime
		,', transaction count: ', @@trancount
		,')'
	);
end

begin try
	if (@entityId is null and @templateId is null)
	begin
		set @errorMessage = concat(@empty, @thisProcedureName, ': '
			,'A specific "@entityId" or a specific "@templateId" must be provided.'
		);
		throw 50001, @errorMessage, 1;

	end;

	--Gets the Entity Type (ex. Course, Program, Module)
	set @baseTable = (select ReferenceTable from dbo.EntityType where Id = @entityTypeId);

	if (@entityTypeId is null or @baseTable is null or len(@baseTable) < 1)
	begin
		set @errorMessage = concat(@empty, @thisProcedureName, ': '
			,'The value of "@entityTypeId" is empty or unsuppored. A valid "@entityTypeId" is required.'
		);
		throw 50001, @errorMessage, 1;

	end

	set @entityTemplateTable = (case when @entityTypeId = 4 then 'ProgramPlan' else @baseTable end);

	-- check that entity has the correct template if both are defined
	if (@entityId is not null and @templateId is not null)
	begin
		set @sqlParams = (N'
			@entityId int
			,@templateId int
			,@intResult int output
		');
		set @sql = concat(N'
set @intResult = (case when exists (
	select 1
	from dbo.', quotename(@entityTemplateTable), N' as e
	where
		(e.MetaTemplateId = @templateId)
		and (', (case when @entityTypeId = 4
			then ('e.ProgramId = @entityId')
			else ('e.Id = @entityId')
			end), N')
)
then 1
else 0
end);');
		exec sys.sp_executesql @sql, @sqlParams
			,@entityId
			,@templateId
			,@intResult output
		;
		if isnull(@intResult, 0) = 0
		begin
			set @errorMessage = concat(@empty, @thisProcedureName, ': '
				,'The cannot find an entity with "@entityId" and "@templateId".'
				,' Verify that the entity is using the correct template, or let "@templateId" = null.'
			);
			throw 50001, @errorMessage, 1;
		end
	end

	if @entityId is not null and @entityTypeId = 4
	begin
		set @programPlanId = (select pp.Id from ProgramPlan as pp where pp.ProgramId = @entityId);
	end

	-- Determine Target Entities
	create table #TargetEntities (
		Id int not null primary key
		,MetaTemplateId int null
	);

	set @sqlParams = (N'
		@entityId int
		,@templateId int
	');
	set @sql = concat(N'
select e.Id, e.MetaTemplateId
from dbo.', quotename(@entityTemplateTable), N' as e
where
	(@templateId is null or e.MetaTemplateId = @templateId)
	and (@entityId is null or ', (
		case when @entityTypeId = 4
		then ('e.ProgramId = @entityId')
		else ('e.Id = @entityId')
		end), N')
;');

	insert into #TargetEntities (Id, MetaTemplateId)
	exec sys.sp_executesql @sql, @sqlParams
		,@entityId
		,@templateId
	;

	if ((select count(*) from #TargetEntities) > 0)
	begin
		if @debug = 1
		begin
			print concat(@empty, @thisProcedureName
				,': Beginning Badge Update ...'
				,' (elapsed: ', datediff(ms, @procStartTime, sysdatetime()), ' ms'
				,', transaction count: ', @@trancount
				,', @entityTypeId: ', (case when (@entityTypeId is not null) then cast(@entityTypeId as nvarchar(max)) else 'null' end)
				,', @entityId: ', (case when (@entityId is not null) then cast(@entityId as nvarchar(max)) else 'null' end)
				,', @templateId: ', (case when (@templateId is not null) then cast(@templateId as nvarchar(max)) else 'null' end)
				,')'
			);
		end

		if (@templateId is null)
		begin
			set @sqlParams = (N'
				@entityId int
				,@templateId int output
			');
			set @sql = concat(N'
set @templateId = (
	select e.MetaTemplateId
	from dbo.', quotename(@entityTemplateTable), N' as e
	where (', (case when @entityTypeId = 4
		then 'e.ProgramId = @entityId'
		else 'e.Id = @entityId'
		end), N')
);');
			exec sys.sp_executesql @sql, @sqlParams
				,@entityId
				,@templateId output
			;
			if @templateId is null
			begin
				set @errorMessage = concat(@empty, @thisProcedureName, ': '
					,'The cannot find a MetaTemplateId value for entity with "@entityId".'
				);
				throw 50001, @errorMessage, 1;
			end
		end;

		declare @ReadOnlyCrossListing table (Id int, MetaSelectedFieldId int, MetaSelectedSectionId int);

		if(@entityTypeId = 1 AND exists(select top 1 1 from Course c join #TargetEntities te on c.Id = te.Id where c.IsCrossListed = 1))
		begin
			insert into @ReadOnlyCrossListing (Id, MetaSelectedFieldId)
			select c.Id, msf.MetaSelectedFieldId from Course c
			join #TargetEntities te on c.Id = te.Id 
			join CrossListingCourse clc on clc.CourseId = c.Id
			join MetaSelectedSection mss on mss.MetaTemplateId = c.MetaTemplateId
			join MetaSelectedField msf on mss.MetaSelectedSectionId = msf.MetaSelectedSectionId
			join CrossListingFieldSyncBlackList bl on bl.ClientId = c.ClientId AND bl.MetaAvailableFieldId = msf.MetaAvailableFieldId
			where c.IsCrossListed = 1 AND clc.IsSource = 0


			insert into @ReadOnlyCrossListing (Id, MetaSelectedSectionId)
			select c.Id, mss.MetaSelectedSectionId from Course c
			join #TargetEntities te on c.Id = te.Id 
			join CrossListingCourse clc on clc.CourseId = c.Id
			join MetaSelectedSection mss on mss.MetaTemplateId = c.MetaTemplateId
			join CrossListingSchemaSyncBlackList bl on bl.ClientId = c.ClientId AND bl.MetaBaseSchemaId = mss.MetaBaseSchemaId
			where c.IsCrossListed = 1 AND clc.IsSource = 0
		end



		create table #TargetFields (
			RowId int not null identity
			,MetaSelectedSectionId int not null
			,TableName sysname not null
			,ColumnName sysname not null
			,MetadataAttributeMapId int null
			,DataGrabSql nvarchar(max) null
		);

		create table #FieldValues (
			EntityId int not null
			,MetaSelectedSectionId int not null
			,TableName sysname not null
			,ColumnName sysname not null
			,[Value] nvarchar(max) null
			,StateRequirement int null
		);
		create nonclustered index IX_FieldValues_SectionColumns
			on #FieldValues (MetaSelectedSectionId, TableName, ColumnName)
		;

		with TargetTables as (
			select
				mss.MetaSelectedSectionId
				,maf.TableName
				,maf.ColumnName
				,isnull(mda.MetadataAttributeMapId, 0) as MetadataAttributeMapId
			from dbo.Expression as e
			inner join dbo.ExpressionPart as ep on e.Id = ep.ExpressionId
			inner join dbo.MetaSelectedField as msf on ep.Operand1_MetaSelectedFieldId = msf.MetaSelectedFieldId
			inner join dbo.MetaAvailableField as maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
			inner join dbo.MetaSelectedSection as mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
			inner join dbo.MetaSectionType as mst
				on mss.MetaSectionTypeId = mst.Id
				and mst.IsOneToMany = 0
			inner join dbo.MetaSelectedSection as mss2
				on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
				and mss2.MetaSelectedSection_MetaSelectedSectionId is null
			left join (
				MetadataAttribute as mda
				inner join MetadataAttributeType as mdat
					on mda.MetadataAttributeTypeId = mdat.Id
					and mdat.Id = 17
			) on msf.MetadataAttributeMapId = mda.MetadataAttributeMapId
			where mss.MetaTemplateId = @templateId

			union select
				mss.MetaSelectedSectionId
				,maf.TableName
				,maf.ColumnName
				,isnull(mda.MetadataAttributeMapId, 0) as MetadataAttributeMapId
			from dbo.MetaSelectedField as msf
			inner join dbo.MetaSelectedSection as mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
			inner join dbo.MetaSectionType as mst
				on mss.MetaSectionTypeId = mst.Id
				and mst.IsOneToMany = 0
			inner join dbo.MetaSelectedSection as mss2
				on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
				and mss2.MetaSelectedSection_MetaSelectedSectionId is null
			inner join dbo.MetaAvailableField as maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
			left join INFORMATION_SCHEMA.COLUMNS as nn
				on (nn.TABLE_SCHEMA collate SQL_Latin1_General_CP1_CI_AS) = 'dbo'
				and (nn.TABLE_NAME collate SQL_Latin1_General_CP1_CI_AS) = maf.TableName -- case insensitive
				and (nn.COLUMN_NAME collate SQL_Latin1_General_CP1_CI_AS) = maf.ColumnName -- case insensitive
				and nn.IS_NULLABLE = 'NO'
				and nn.COLUMN_DEFAULT is null
				and msf.[ReadOnly] = 0
			left join (
				dbo.MetadataAttribute as mda
				inner join dbo.MetadataAttributeType as mdat
					on mda.MetadataAttributeTypeId = mdat.Id
					and mdat.Id = 17
			) on msf.MetadataAttributeMapId = mda.MetadataAttributeMapId
			where
				mss.MetaTemplateId = @templateId
				and (
					nn.TABLE_NAME is not null
					or (
						msf.IsRequired = 1 
						and msf.[ReadOnly] = 0
					)
				)
		)
		insert into #TargetFields (MetaSelectedSectionId, TableName, ColumnName, MetadataAttributeMapId, DataGrabSql)
		select
			tt.MetaSelectedSectionId
			,tt.TableName
			,tt.ColumnName
			,tt.MetadataAttributeMapId
			,concat(N'
select
	t.', quotename(
		case when tt.TableName = @baseTable
		then 'Id'
		else (@baseTable + 'Id')
		end)
		,' as EntityId
	,@selectedSectionId as MetaSelectedSectionId
	,@tableName as TableName
	,@columnName as ColumnName
	,', quotename(tt.ColumnName), ' as [Value]
	,isnull(@metadataAttributeMapId, 0) as StateRequirement
from ', quotename(tt.TableName), ' as t
inner join #TargetEntities as te on te.Id = t.', (
	case when tt.TableName = @baseTable
	then 'Id'
	else @baseTable + 'Id'
	end), '
;'
			) as DataGrabSql
		from TargetTables as tt
		;

		-- Required fields or show/hide based fields
		select
			@curId = (select min(RowId) from #TargetFields)
			,@maxId = (select max(RowId) from #TargetFields)
			,@sqlParams = (N'
				@selectedSectionId int
				,@tableName sysname
				,@columnName sysname
				,@metadataAttributeMapId int
			')
		;
		while (@curId <= @maxId)
		begin
			select
				@selectedSectionId = tf.MetaSelectedSectionId
				,@tableName = tf.TableName
				,@columnName = tf.ColumnName
				,@metadataAttributeMapId = tf.MetadataAttributeMapId
				,@sql = tf.DataGrabSql
			from #TargetFields as tf
			where tf.RowId = @curId
			;

			insert into #FieldValues (EntityId, MetaSelectedSectionId, TableName, ColumnName, [Value], StateRequirement)
			exec sys.sp_executesql @sql, @sqlParams
				,@selectedSectionId
				,@tableName
				,@columnName
				,@metadataAttributeMapId
			;

			set @curId += 1;
		end;

		-- 12 seconds for full template type
		-- Evaluate Show/Hide Logic
		declare @ValueConversions table (
			ComparisonDataTypeId int null
			,[Value] nvarchar(max) null
			,TranslatedValue nvarchar(max) null
		);

		insert into @ValueConversions (ComparisonDataTypeId, [Value], TranslatedValue)
		values
			(3, null, '-1')
			,(4, '1', 'true')
			,(4, null, 'false')
			,(4, '0', 'false')
		;

		create table #FieldEvaluations (
			EntityId int null
			,ExpressionId int null
			,ExpressionPartId int null
			,Parent_ExpressionPartId int null
			,ComparisonDataTypeId int null
			,TableName sysname null
			,ColumnName sysname null
			,[Value] nvarchar(max) null
			,ExpressionOperatorTypeId int null
			,Evaluation int null
		);
		create nonclustered index IX_FieldEvaluations_Evaluations
			on #FieldEvaluations (Evaluation)
			include (EntityId, Parent_ExpressionPartId)
		;

		create table #ShowHideEvaluations (
			EntityId int null
			,ExpressionId int null
			,Evaluation bit null
		);

		with TargetExpressions as (
			select
				fv.EntityId
				,e.Id as ExpressionId
				,ep.Id as ExpressionPartId
				,ep.Parent_ExpressionPartId
				,ep.ComparisonDataTypeId
				,maf.TableName
				,maf.ColumnName
				,ep.ExpressionOperatorTypeId
				,fv.[Value]
				,(case ep.ExpressionOperatorTypeId
					when 3 then (
						case
							--Due to time constraints, i.e. not having time to verify and analyze the impacts
							--of correcting the comparisons for the other other operators or data types, only correcting
							--the behavior of the equals comparison to compare decimals as decimals
							when ep.ComparisonDataTypeId = 1 and (numv.NumericValue is null or numv.NumericValue = numv.NumericOperand2Literal) then 1
							when ep.ComparisonDataTypeId <> 1 and (isnull(vc.TranslatedValue, fv.[Value]) = ep.Operand2Literal) then 1
							else 0
						end
					)
					when 5 then (
						case
							when (isnull(fv.[Value], vc.TranslatedValue) < ep.Operand2Literal or fv.[Value] is null) then 1
							else 0
						end
					)
					when 6 then (
						case
							when (isnull(fv.[Value], vc.TranslatedValue) > ep.Operand2Literal) then 1
							else 0
						end
					)
					when 7 then (
						case
							when (isnull(fv.[Value], vc.TranslatedValue) <= ep.Operand2Literal or fv.[Value] is null) then 1
							else 0
						end
					)
					when 8 then (
						case
							when (isnull(fv.[Value], vc.TranslatedValue) >= ep.Operand2Literal) then 1
							else 0
						end
					)
					when 9 then (
						case
							when (isnull(fv.[Value], vc.TranslatedValue) between ep.Operand2Literal and ep.Operand3Literal) then 1
							else 0
						end
					)
					when 10 then (case when (isnull(fv.[Value], vc.TranslatedValue) like concat(N'%', ep.Operand2Literal, N'%'))
						then 1 else 0 end)
					when 11 then (case when (isnull(fv.[Value], vc.TranslatedValue) like concat(ep.Operand2Literal, N'%'))
						then 1 else 0 end)
					when 12 then (case when (isnull(fv.[Value], vc.TranslatedValue) like concat(N'%', ep.Operand2Literal))
						then 1 else 0 end)
					when 13 then (case when (isnull(fv.[Value], vc.TranslatedValue) like concat(ep.Operand2Literal, N'%', ep.Operand3Literal))
						then 1 else 0 end)
					when 14 then (case when (isnull(fv.[Value], vc.TranslatedValue) is not null)
						then 1 else 0 end)
					when 16 then (
						case 
							when (isnull(fv.[Value], vc.TranslatedValue) is null or isnull(fv.[Value], vc.TranslatedValue) <> ep.Operand2Literal) then 1
							else 0 
						end
					)
				end) as Evaluation
			from dbo.Expression as e
			inner join dbo.ExpressionPart as ep on e.Id = ep.ExpressionId
			inner join dbo.MetaSelectedField as msf on ep.Operand1_MetaSelectedFieldId = msf.MetaSelectedFieldId
			inner join dbo.MetaSelectedSection as mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
			inner join dbo.MetaSectionType mst on mss.MetaSectionTypeId = mst.Id
			inner join dbo.MetaSelectedSection as mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
			inner join dbo.MetaAvailableField as maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
			inner join #FieldValues as fv on maf.TableName = fv.TableName
				and maf.ColumnName = fv.ColumnName
			left join @ValueConversions as vc
				on (
					fv.[Value] = vc.[Value]
					or (fv.[Value] is null and vc.[Value] is null)
				)
				and ep.ComparisonDataTypeId = vc.ComparisonDataTypeId
			cross apply (
				select
					--When doing a decimal comparison/operation (ComparisonDataTypeId 1), try to cast values to decimal for proper comparison
					--Direct comparison doesn't work as, e.g., '0.00' does not equal '0' in a string comparison
					--We are using case statements to avoid potentially costly cast attempts when not doing numeric (decimal) comparisons
					--We are using decimal (16, 4) because that was the most decimal digits I found in a quick glance at the CourseDescription table,
					--and even though most are (16, 3), we don't want to lose precision and cause incorrect matches as a result
					case
						when ep.ComparisonDataTypeId = 1 then try_cast(isnull(vc.TranslatedValue, fv.[Value]) as decimal(16, 4))
						else null
					end as NumericValue,
					case
						when ep.ComparisonDataTypeId = 1 then try_cast(ep.Operand2Literal as decimal(16, 4))
						else null
					end as NumericOperand2Literal,
					case
						when ep.ComparisonDataTypeId = 1 then try_cast(ep.Operand3Literal as decimal(16, 4))
						else null
					end as NumericOperand3Literal
			) numv
			where
				mst.IsOneToMany = 0
				and mss2.MetaSelectedSection_MetaSelectedSectionId is null
				and mss2.MetaTemplateId = @templateId
		), TargetEvaluations as (
			select
				te.EntityId
				,te.Expressionid
				,te.ExpressionPartId
				,te.Parent_ExpressionPartId
				,te.ComparisonDataTypeId
				,te.TableName
				,te.ColumnName
				,te.ExpressionOperatorTypeId
				,te.[Value]
				,te.Evaluation
			from TargetExpressions as te

			union select
				te.EntityId
				,e.Id as ExpressionId
				,ep.Id as ExpressionPartId
				,ep.Parent_ExpressionPartId
				,ep.ComparisonDataTypeId
				,null as TableName
				,null as ColumnName
				,ep.ExpressionOperatorTypeId
				,null as [Value]
				,null as Evaluation
			from dbo.Expression as e
			inner join dbo.ExpressionPart as ep on e.Id = ep.ExpressionId
			inner join TargetExpressions as te on e.Id = te.Expressionid
			where ep.Operand1_MetaSelectedFieldId is null
		)
		insert into #FieldEvaluations (
			EntityId
			,ExpressionId
			,ExpressionPartId
			,Parent_ExpressionPartId
			,ComparisonDataTypeId
			,TableName
			,ColumnName
			,ExpressionOperatorTypeId
			,[Value]
			,Evaluation
		)
		select
			te.EntityId
			,te.Expressionid
			,te.ExpressionPartId
			,te.Parent_ExpressionPartId
			,te.ComparisonDataTypeId
			,te.TableName
			,te.ColumnName
			,te.ExpressionOperatorTypeId
			,te.[Value]
			,te.Evaluation
		from TargetEvaluations as te
		;

		--select '#FieldEvaluations' as "#FieldEvaluations", fe.* from #FieldEvaluations as fe;

		-- 16 seconds for full Template Analysis
		-- Recursively go up the tree and evaluate the and, or, and not conditions
		with ParentExpression as (
			select
				eval.EntityId
				,ep.ExpressionId
				,ep.ExpressionOperatorTypeId
				,ep.Parent_ExpressionPartId
				,(case
					when (ep.ExpressionOperatorTypeId = 1 and EvaluationSum = EvaluationCount)
						then 1
					when (ep.ExpressionOperatorTypeId = 2 and EvaluationSum > 0)
						then 1
					when (ep.ExpressionOperatorTypeId = 4 and eval.Evaluation = 0)
						then 1
					else 0
				end) as Evaluation
				,EvaluationSum as sumEval
				,EvaluationCount as evalCount
			from dbo.ExpressionPart as ep
			inner join #FieldEvaluations as eval on ep.Id = eval.Parent_ExpressionPartId
			outer apply (select
				sum(eval.Evaluation) over (
					partition by
						eval.EntityId
						,ep.ExpressionId
						,ep.ExpressionOperatorTypeId
						,ep.Parent_ExpressionPartId
				) as EvaluationSum
			) as es
			outer apply (select
				count(eval.Evaluation) over (
					partition by
						eval.EntityId
						,ep.ExpressionId
						,ep.ExpressionOperatorTypeId
						,ep.Parent_ExpressionPartId
				) as EvaluationCount
			) as ec
			where eval.Evaluation is not null

			union all select
				eval.EntityId
				,ep.ExpressionId
				,ep.ExpressionOperatorTypeId
				,ep.Parent_ExpressionPartId
				,(case
					when (ep.ExpressionOperatorTypeId = 1 and EvaluationSum = EvaluationCount)
						then 1
					when (ep.ExpressionOperatorTypeId = 2 and EvaluationSum > 0)
						then 1
					when (ep.ExpressionOperatorTypeId = 4 and eval.Evaluation = 0)
						then 1
					else 0
				end) as Evaluation
				,EvaluationSum as sumEval
				,EvaluationCount as evalCount
			from dbo.ExpressionPart as ep
			inner join ParentExpression as eval on ep.Id = eval.Parent_ExpressionPartId
			outer apply (select
				sum(eval.Evaluation) over (
					partition by
						eval.EntityId
						,ep.ExpressionId
						,ep.ExpressionOperatorTypeId
						,ep.Parent_ExpressionPartId
				) as EvaluationSum
			) as es
			outer apply (select
				count(eval.Evaluation) over (
					partition by
						eval.EntityId
						,ep.ExpressionId
						,ep.ExpressionOperatorTypeId
						,ep.Parent_ExpressionPartId
				) as EvaluationCount
			) as ec
			where eval.Evaluation is not null
		)
		insert into #ShowHideEvaluations (EntityId, ExpressionId, Evaluation)
		--output inserted.*
		select pe.EntityId, pe.ExpressionId, pe.Evaluation
		from ParentExpression as pe
		where pe.Parent_ExpressionPartId is null
		;

		create table #MetaSelected (
			MetaSelectedSectionId int null
			,MetaSelectedFieldId int null
			,EntityId int null
		);
		create nonclustered index IX_MetaSelected_Fields
			on #MetaSelected (EntityId, MetaSelectedFieldId)
		;
		create nonclustered index IX_MetaSelected_Sections
			on #MetaSelected (EntityId, MetaSelectedSectionId)
		;

		insert into #MetaSelected (MetaSelectedSectionId, MetaSelectedFieldId, EntityId)
		--output inserted.*
		select distinct mds.MetaSelectedSectionId, mds.MetaSelectedFieldId, she.EntityId
		from dbo.MetaDisplayRule as mdr
		inner join #ShowHideEvaluations as she on mdr.ExpressionId = she.ExpressionId
		inner join dbo.MetaDisplaySubscriber as mds on mdr.Id = mds.MetaDisplayRuleId
		where she.Evaluation = 1
		;
		
		-- Reuben Ellis modified this section on 2017-06-15 for the state requirements addition to META.
		-- 22 Seconds
		create table #BadgeStatus (
			EntityId int null
			,MetaSelectedSectionId int null
			,ValidCount int null
			,RequiredCount int null
			,ValidStateCount int null
			,TotalStateCount int null
			,Notes nvarchar(max)
		);

		with HasDataQuery as (
			select
				fv.EntityId
				,mss.MetaSelectedSectionId
				,(case when fv.[Value] is not null then 1 else 0 end) as HasData
				,(1) as RequiredField
				,(case when fv.[Value] is not null and fv.StateRequirement <> 0 then 1 else 0 end) as HasStateData
				,(case when fv.StateRequirement <> 0 then 1 else 0 end) as HasMetaAttributeMapId
			from dbo.MetaSelectedSection as mss
			inner join dbo.MetaSelectedSection as mss2 on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
			inner join dbo.MetaSectionType as mst
				on mss2.MetaSectionTypeId = mst.Id
				and mst.IsOneToMany = 0 -- Only want extension tables
			inner join dbo.MetaSelectedField as msf
				on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
				and msf.MetaPresentationTypeId <> 5 -- Checkboxes can't be set as required at present
				and msf.[ReadOnly] = 0
			inner join dbo.MetaAvailableField as maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
			inner join #FieldValues as fv
				on maf.TableName = fv.TableName
				and maf.ColumnName = fv.ColumnName
				and msf.MetaSelectedSectionId = fv.MetaSelectedSectionId
			left join INFORMATION_SCHEMA.COLUMNS as nn
				on (nn.TABLE_SCHEMA collate SQL_Latin1_General_CP1_CI_AS) = 'dbo'
				and (nn.TABLE_NAME collate SQL_Latin1_General_CP1_CI_AS) = maf.TableName -- case insensitive
				and (nn.COLUMN_NAME collate SQL_Latin1_General_CP1_CI_AS) = maf.ColumnName -- case insensitive
				and nn.IS_NULLABLE = 'NO'
				and nn.COLUMN_DEFAULT is null
			left join #MetaSelected as ms
				on fv.EntityId = ms.EntityId
				and (
					mss2.MetaSelectedSectionId = ms.MetaSelectedSectionId 
					or msf.MetaSelectedFieldId = ms.MetaSelectedFieldId
				)
			where
				(
					msf.IsRequired = 1
					or nn.TABLE_NAME is not null
				)
				and mss.MetaSelectedSection_MetaSelectedSectionId is null
				and mss.MetaTemplateId = @templateId
				and ms.EntityId is null
				--this is used to prevent validation errors for fields that are read only due to cross-listing sync
				and 
				(
					not exists(select top 1 1 from @ReadOnlyCrossListing where Id = fv.EntityId)
					or exists(select top 1 1 from @ReadOnlyCrossListing where MetaSelectedFieldId = msf.MetaSelectedFieldId)
				)
		)
		insert into #BadgeStatus (EntityId, MetaSelectedSectionid, ValidCount, RequiredCount, ValidStateCount, TotalStateCount, Notes)
		--output inserted.*
		select
			EntityId
			,MetaSelectedSectionId
			,sum(HasData)
			,sum(RequiredField)
			,sum(HasStateData)
			,sum(HasMetaAttributeMapId)
			,'First-level fields'
		from HasDataQuery as hdq
		group by EntityId, MetaSelectedSectionId
		;

		--no further validation is needed for cross-listed courses.
		--delete te from #TargetEntities te where exists(select top 1 1 from @ReadOnlyCrossListing r where r.Id = te.Id);

		-- Evaluation OpenList Sections

		declare @OpenListSections table (
			Id int not null identity
			,EntityId int null
			,MetaSelectedSectionId int null
			,MinElem int null
			,MetaBaseSchemaId int null
			,PrimaryTable nvarchar(max) null
			,ForeignTable nvarchar(max) null
			,SqlText nvarchar(max) null
		);

		insert into @OpenListSections (MetaSelectedSectionId, EntityId, MinElem, MetaBaseSchemaId, PrimaryTable, ForeignTable, SqlText)
		--output inserted.*
		select
			mss2.MetaSelectedSectionId
			,te.Id
			,msss.MinElem
			,mss.MetaBaseSchemaId
			,mbs.PrimaryTable
			,mbs.ForeignTable
			,concat(N'
select
	te.Id as EntityId
	,@selectedSectionId as MetaSelectedSectionId
	,@minElem as RequiredCount
	,count(ft.Id) as TotalCount
	,0 as ValidStateCount
	,0 as TotalStateCount
	,''Min Count'' as Notes
from #TargetEntities as te
left join ', quotename(mbs.ForeignTable), ' as ft on te.Id = ft.', quotename(mbs.ForeignKey), '
where te.Id = @entityId
group by te.Id;'
			) as SqlText
		from MetaSelectedSectionSetting as msss
		inner join MetaSelectedSection as mss on msss.MetaSelectedSectionId = mss.MetaSelectedSectionId
		inner join MetaSelectedSection as mss2
			on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
			and mss2.MetaSelectedSection_MetaSelectedSectionId is null
		inner join MetaBaseSchema as mbs on mss.MetaBaseSchemaId = mbs.Id
		inner join #TargetEntities as te
			on not exists (
				select 1
				from #MetaSelected as ms
				where
					te.Id = ms.EntityId
					and mss.MetaSelectedSectionId = ms.MetaSelectedSectionId
			)
			--this is used to prevent validation errors for fields that are read only due to cross-listing sync
			AND 
			(
				not exists(select top 1 1 from @ReadOnlyCrossListing where Id = te.Id)
				or exists(select top 1 1 from @ReadOnlyCrossListing where  msss.MetaSelectedSectionId = MetaSelectedSectionId)
			)
		where
			mss.MetaTemplateId = @templateId
			and msss.MinElem is not null
		;

		select
			@curId = (select min(Id) from @OpenListSections)
			,@maxId = (select max(Id) from @OpenListSections)
			,@sqlParams = (N'
				@entityId int
				,@selectedSectionId int
				,@minElem int
			')
		;
		while (@curId <= @maxId)
		begin
			select
				@curEntityId = ols.EntityId
				,@selectedSectionId = ols.MetaSelectedSectionId
				,@minElem = ols.MinElem
				,@sql = SqlText
			from @OpenListSections as ols
			where Id = @curId
			;

			insert into #BadgeStatus (EntityId, MetaSelectedSectionid, RequiredCount, ValidCount, ValidStateCount, TotalStateCount, Notes)
			exec sys.sp_executesql @sql, @sqlParams
				,@curEntityId
				,@selectedSectionId
				,@minElem
			;

			set @curId += 1;
		end

		insert into #BadgeStatus (EntityId, MetaSelectedSectionId, RequiredCount, ValidCount, ValidStateCount, TotalStateCount, Notes)
		--output inserted.*
		select te.Id, mss.MetaSelectedSectionId, 0, 0, 0, 0, 'Empty placeholders'
		from #TargetEntities as te
		inner join MetaSelectedSection as mss on te.MetaTemplateId = mss.MetaTemplateId
		where
			mss.MetaSelectedSection_MetaSelectedSectionId is null
			and not exists (
				select 1
				from #BadgeStatus as bs
				where
					bs.EntityId = te.Id
					and bs.MetaSelectedSectionId = mss.MetaSelectedSectionId
			);

		declare @AggregateQueries table (
			Id int not null identity
			,MetaControlAttributeId int null
			,TargetValue int null
			,SqlText nvarchar(max) null
		);

		declare @ComparisonOperator table (
			MetaAttributeComparisonTypeId int null
			,Operator nvarchar(10) null
		);

		insert into @ComparisonOperator (MetaAttributeComparisonTypeId, Operator)
		values
			(1, ' = ')
			,(2, ' != ')
			,(3, ' < ')
			,(4, ' > ')
			,(5, ' <= ')
			,(6, ' >= ')
		;

		declare @AggregateValidation table (
			EntityId int null
			,AggregateRuleId int null
			,AggregateCount int null
			,AggregateSum int null
		);

		insert into @AggregateQueries (MetaControlAttributeId, TargetValue, SqlText)
		--output inserted.*
		select
			mca.Id as MetaControlAttributeId
			,mca.TargetValue
			,concat(N'
select
	te.Id as EntityId
	,@metaControlAttributeId as AggregateRuleId
	,sum(case when (', 
			'ft.', quotename(maf.ColumnName)
			,co.Operator
			,'@targetValue'
		,') then 1 else 0 end) as AggregateCount
	,sum(cast(ft.', quotename(maf.ColumnName), ' as int)) as AggregateSum
from #TargetEntities te
left outer join ', quotename(mbs.ForeignTable), ' ft on te.Id = ft.', quotename(mbs.ForeignKey), '
group by te.Id;'
			) as SqlText
		from MetaControlAttribute as mca
		inner join MetaSelectedSection as mss on mca.MetaSelectedSectionId = mss.MetaSelectedSectionId
		inner join MetaSelectedField as msf on mca.MetaSelectedFieldId = msf.MetaSelectedFieldId
		inner join MetaAvailableField as maf on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
		inner join MetaBaseSchema as mbs on mss.MetaBaseSchemaId = mbs.Id
		inner join @ComparisonOperator as co on mca.MetaAttributeComparisonTypeId = co.MetaAttributeComparisonTypeId
		where mss.MetaTemplateId = @TemplateId
		and mca.MetaControlAttributeTypeId in (4, 5) -- 4 = ListSumValidation, 5 = ListCountValidation
		;

		if (@debug = 1)
		begin;
			select
				'@AggregateQueries' as [__@AggregateQueries], aq.*
			from @AggregateQueries aq;
		end;

		select
			@curId = (select min(Id) from @AggregateQueries)
			,@maxId = (select max(Id) from @AggregateQueries)
			,@sqlParams = (N'
				@metaControlAttributeId int
				,@targetValue int
			')
		;
		while (@curId <= @maxId)
		begin
			select
				@metaControlAttributeId = MetaControlAttributeId
				,@targetValue = TargetValue
				,@sql = SqlText
			from @AggregateQueries
			where Id = @curId
			;

			insert into @AggregateValidation (EntityId, AggregateRuleId, AggregateCount, AggregateSum)
			exec sys.sp_executesql @sql, @sqlParams
				,@metaControlAttributeId
				,@targetValue
			;

			set @curId += 1;
		end;

		if (@debug = 1)
		begin;
			select
				'@AggregateValidation' as [__@AggregateValidation], av.*
			from @AggregateValidation av;
		end;

		with AggregateEvaluation as (
			select
				av.EntityId
				,av.AggregateRuleId
				,(case mca.MetaControlAttributeTypeId
					when 4 then -- sum
						(case mca.MetaAttributeComparisonTypeId
							when 1 then (case when av.AggregateSum = mca.TargetValue then 1 else 0 end)
							when 2 then (case when av.AggregateSum <> mca.TargetValue then 1 else 0 end)
							when 3 then (case when av.AggregateSum < mca.TargetValue then 1 else 0 end)
							when 4 then (case when av.AggregateSum > mca.TargetValue then 1 else 0 end)
							when 5 then (case when av.AggregateSum <= mca.TargetValue then 1 else 0 end)
							when 6 then (case when av.AggregateSum >= mca.TargetValue then 1 else 0 end)
							else 0
						end)
					when 5 then
						(case mca.MetaAttributeComparisonTypeId
							when 1 then (case when av.AggregateCount = mca.TotalCount then 1 else 0 end)
							when 2 then (case when av.AggregateCount <> mca.TotalCount then 1 else 0 end)
							when 3 then (case when av.AggregateCount < mca.TotalCount then 1 else 0 end)
							when 4 then (case when av.AggregateCount > mca.TotalCount then 1 else 0 end)
							when 5 then (case when av.AggregateCount <= mca.TotalCount then 1 else 0 end)
							when 6 then (case when av.AggregateCount >= mca.TotalCount then 1 else 0 end)
							else 0
						end)
				end) as Evaluation
			from @AggregateValidation as av
			inner join MetaControlAttribute as mca on av.AggregateRuleId = mca.ID
		), PageAggregation as (
			select
				ae.EntityId
				,mss2.MetaSelectedSectionId
				,sum(ae.Evaluation) as ValidCount
			from AggregateEvaluation as ae
			inner join MetaControlAttribute as mca on ae.AggregateRuleId = mca.Id
			inner join MetaSelectedSection as mss on mca.MetaSelectedSectionId = mss.MetaSelectedSectionId
			inner join MetaSelectedSection as mss2
				on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
				and mss2.MetaSelectedSection_MetaSelectedSectionId is null
			--this is used to prevent validation errors for fields that are read only due to cross-listing sync
			where 
				(
					not exists(select top 1 1 from @ReadOnlyCrossListing where Id = ae.EntityId)
					or exists(select top 1 1 from @ReadOnlyCrossListing where  mca.MetaSelectedSectionId = MetaSelectedSectionId)
				)
			group by ae.EntityId, mss2.MetaSelectedSectionId
		), EntityCount as (
			select
				mss.MetaSelectedSectionId
				,count(mca.Id) as RequiredCount
			from MetaTemplate as mt
			inner join MetaSelectedSection as mss
				on mt.MetaTemplateId = mss.MetaTemplateId
				and mss.MetaSelectedSection_MetaSelectedSectionId is null
			inner join MetaSelectedSection as mss2 on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
			inner join MetaControlAttribute as mca on mss2.MetaSelectedSectionId = mca.MetaSelectedSectionId
			where mca.MetaControlAttributeTypeId in (4, 5) -- 4 = ListSumValidation, 5 = ListCountValidation
			group by mss.MetaSelectedSectionId
		)
		insert into #BadgeStatus (EntityId, MetaSelectedSectionId, ValidCount, RequiredCount, ValidStateCount, TotalStateCount, Notes)
		select
			pa.EntityId, pa.MetaSelectedSectionId,
			isnull(pa.ValidCount, 0) as ValidCount, isnull(ec.RequiredCount, 0) as RequiredCount,
			0 as ValidStateCount, 0 as TotalStateCount,
			'Aggregate validation' as Notes
		from PageAggregation pa
		inner join EntityCount as ec on pa.MetaSelectedSectionId = ec.MetaSelectedSectionId
		;

		--#region custom sql validation
		drop table if exists #customValidationResults;

		create table #customValidationResults (
			EntityId int,
			SectionId int,
			IsValid bit
		);

		declare @customValidationParameters nvarchar(max) = (
			select
				te.Id as [id], json_query(params.Parameters) as [parameters]
			from #TargetEntities te
			cross apply (
				select concat(
					'[',
						dbo.fnGenerateBulkResolveQueryParameter('@entityId', te.Id, 'int'), @paramDelim,
						dbo.fnGenerateBulkResolveQueryParameter('@entityTypeId', @entityTypeId, 'int'), @paramDelim,
						dbo.fnGenerateBulkResolveQueryParameter('@resultTable', '#customValidationResults', 'string'), @paramDelim,
						dbo.fnGenerateBulkResolveQueryParameter('@debug', @debug, 'bool'),
					']'
				) as Parameters
			) params
			for json path
		);

		declare @customValidationQuery nvarchar(max) =
		'exec upEvaluateCustomSqlValidations @entityId = @entityId, @entityTypeId = @entityTypeId, @resultTable = @resultTable, @debug = @debug;';

		declare @customValidationResults nvarchar(max);

		exec upBulkResolveQuery
			@queryString = @customValidationQuery, @serializedParameters = @customValidationParameters,
			@serializedResults = @customValidationResults output;

		if (@debug = 1)
		begin;
			select
				@customValidationParameters as [@customValidationParameters],
				@customValidationResults as [@customValidationResults];

			select
				'#customValidationResults' as [#customValidationResults],
				cvr.*
			from #customValidationResults cvr;
		end;

		--Assuming all sections we are validating have a root tab as their parent section
		--So we are aggregating up to the tab-level on a per-entity basis
		with ResultsWithParentSections as (
			select
				cvr.*, mss.MetaSelectedSection_MetaSelectedSectionId as ParentSectionId
			from #customValidationResults cvr
			inner join MetaSelectedSection mss on cvr.SectionId = mss.MetaSelectedSectionId
		--this is used to prevent validation errors for fields that are read only due to cross-listing sync
		where 
		(
			not exists(select top 1 1 from @ReadOnlyCrossListing where Id = cvr.EntityId)
			or exists(select top 1 1 from @ReadOnlyCrossListing where  cvr.SectionId = MetaSelectedSectionId)
		)
		),
		ValidCounts as (
			select rps.EntityId, rps.ParentSectionId, count(*) as ValidCount
			from ResultsWithParentSections rps
			where rps.IsValid = 1
			group by rps.EntityId, rps.ParentSectionId
		),
		RequiredCounts as (
			select rps.EntityId, rps.ParentSectionId, count(*) as RequiredCount
			from ResultsWithParentSections rps
			group by rps.EntityId, rps.ParentSectionId
		)
		insert into #BadgeStatus (EntityId, MetaSelectedSectionId, ValidCount, RequiredCount, ValidStateCount, TotalStateCount, Notes)
		select
			rc.EntityId, rc.ParentSectionId,
			isnull(vc.ValidCount, 0) as ValidCount, rc.RequiredCount,
			0 as ValidStateCount, 0 as TotalStateCount,
			'Custom SQL Validation' as Notes
		from RequiredCounts rc
		left outer join ValidCounts vc on (rc.EntityId = vc.EntityId and rc.ParentSectionId = vc.ParentSectionId)
		WHERE rc.ParentSectionId IS NOT NULL;

		drop table if exists #customValidationResults;

		--#endregion custom sql validation

		update #BadgeStatus
		set ValidCount = RequiredCount
		--output inserted.*
		where ValidCount > RequiredCount
		;

		if (@debug = 1)
		begin;
			select '#BadgeStatus'as [__#BadgeStatus], bs.*, mss.SectionName
			from #BadgeStatus bs
			inner join MetaSelectedSection mss on bs.MetaSelectedSectionId = mss.MetaSelectedSectionId;
		end;

		begin transaction; -- Transaction_UpdateSectionSummary

		declare @sectionSumaryOutput table (
			[Action] nvarchar(255),
			EntityId int,
			EntityTypeId int,
			MetaSelectedSectionId int,
			ValidCount int,
			TotalCount int,
			ValidStateCount int,
			TotalStateCount int
		);

		if (@entityTypeId = 1)
		begin
			update t set ValidCount = 0, TotalCount = 0, ValidStateCount = 0, TotalStateCount = 0
			from CourseSectionSummary t 
			join #TargetEntities s 
			on t.CourseId = s.Id;

			merge into CourseSectionSummary as css
			using (
				select
					bs.EntityId
					,MetaSelectedSectionId
					,sum(ValidCount) as ValidCount
					,sum(RequiredCount) as RequiredCount
					,isnull(sum(ValidStateCount), 0) as ValidStateCount
					,isnull(sum(TotalStateCount), 0) as TotalStateCount
				from #BadgeStatus as bs
				group by EntityId, MetaSelectedSectionId
			) as bs
				on css.MetaSelectedSectionId = bs.MetaSelectedSectionId
				and css.CourseId = bs.EntityId
			when not matched by target then
				insert (CourseId, MetaSelectedSectionid, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
				values (bs.EntityId, bs.MetaSelectedSectionId, bs.ValidCount, bs.RequiredCount, bs.ValidStateCount, bs.TotalStateCount)
			when matched then update set 
				css.ValidCount = bs.ValidCount
				,css.TotalCount = bs.RequiredCount
				,css.ValidStateCount = bs.ValidStateCount
				,css.TotalStateCount = bs.TotalStateCount
			output
				$action as [Action], inserted.CourseId as EntityId, @entityTypeId as EntityTypeId, inserted.MetaSelectedSectionId,
				inserted.ValidCount, inserted.TotalCount, inserted.ValidStateCount, inserted.TotalStateCount
				into @sectionSumaryOutput
				([Action], EntityId, EntityTypeId, MetaSelectedSectionId, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
			--output 'CourseSectionSummary' as "CourseSectionSummary", $action, inserted.*
			;
		end;
		else if (@entityTypeId = 2)
		begin
			update t set ValidCount = 0, TotalCount = 0, ValidStateCount = 0, TotalStateCount = 0
			from ProgramSectionSummary t 
			join #TargetEntities s 
			on t.ProgramId = s.Id;

			merge into ProgramSectionSummary as css
			using (
				select
					bs.EntityId
					,MetaSelectedSectionId
					,sum(ValidCount) as ValidCount
					,sum(RequiredCount) as RequiredCount
					,isnull(sum(ValidStateCount), 0) as ValidStateCount
					,isnull(sum(TotalStateCount), 0) as TotalStateCount
				from #BadgeStatus as bs
				group by bs.EntityId, MetaSelectedSectionId
			) as bs
				on css.MetaSelectedSectionId = bs.MetaSelectedSectionId
				and css.ProgramId = bs.EntityId
			when not matched by target then
				insert (ProgramId, MetaSelectedSectionid, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
				values (bs.EntityId, bs.MetaSelectedSectionId, bs.ValidCount, bs.RequiredCount, bs.ValidStateCount, bs.TotalStateCount)
			when matched and (
				css.ValidCount <> bs.ValidCount 
				or css.TotalCount <> bs.RequiredCount 
				or bs.ValidStateCount <> css.ValidStateCount 
				or bs.TotalStateCount <> css.TotalStateCount
			) then update set
				css.ValidCount = bs.ValidCount
				,css.TotalCount = bs.RequiredCount
				,css.ValidStateCount = bs.ValidStateCount
				,css.TotalStateCount = bs.TotalStateCount
			output
				$action as [Action], inserted.ProgramId as EntityId, @entityTypeId as EntityTypeId, inserted.MetaSelectedSectionId,
				inserted.ValidCount, inserted.TotalCount, inserted.ValidStateCount, inserted.TotalStateCount
				into @sectionSumaryOutput
				([Action], EntityId, EntityTypeId, MetaSelectedSectionId, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
			--output 'ProgramSectionSummary' as "ProgramSectionSummary", $action, inserted.*
			;
		end;
		else if (@entityTypeId = 3)
		begin
			update t set ValidCount = 0, TotalCount = 0, ValidStateCount = 0, TotalStateCount = 0
			from PackageSectionSummary t 
			join #TargetEntities s 
			on t.PackageId = s.Id;

			merge into PackageSectionSummary as css
			using (
				select
					EntityId
					,MetaSelectedSectionId
					,sum(ValidCount) as ValidCount
					,sum(RequiredCount) as RequiredCount
					,isnull(sum(ValidStateCount), 0) as ValidStateCount
					,isnull(sum(TotalStateCount), 0) as TotalStateCount
				from #BadgeStatus
				group by EntityId, MetaSelectedSectionId
			) as bs
				on css.MetaSelectedSectionId = bs.MetaSelectedSectionId
				and css.PackageId = bs.EntityId
			when not matched by target then
				insert (PackageId, MetaSelectedSectionid, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
				values (bs.EntityId, bs.MetaSelectedSectionId, bs.ValidCount, bs.RequiredCount, bs.ValidStateCount, bs.TotalStateCount)
			when matched and (
				css.ValidCount <> bs.ValidCount
				or css.TotalCount <> bs.RequiredCount
				or bs.ValidStateCount <> css.ValidStateCount
				or bs.TotalStateCount <> css.TotalStateCount
			) then update set
				css.ValidCount = bs.ValidCount
				,css.TotalCount = bs.RequiredCount
				,css.ValidStateCount = bs.ValidStateCount
				,css.TotalStateCount = bs.TotalStateCount
			output
				$action as [Action], inserted.PackageId as EntityId, @entityTypeId as EntityTypeId, inserted.MetaSelectedSectionId,
				inserted.ValidCount, inserted.TotalCount, inserted.ValidStateCount, inserted.TotalStateCount
				into @sectionSumaryOutput
				([Action], EntityId, EntityTypeId, MetaSelectedSectionId, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
			--output 'PackageSectionSummary' as "PackageSectionSummary", $action, inserted.*
			;
		end;
		else if (@entityTypeId = 4)
		begin
			merge into ProgramPlanSectionSummary as css
			using (
				select
					EntityId
					,MetaSelectedSectionId
					,sum(ValidCount) as ValidCount
					,sum(RequiredCount) as RequiredCount
					,isnull(sum(ValidStateCount), 0) as ValidStateCount
					,isnull(sum(TotalStateCount), 0) as TotalStateCount
				from #BadgeStatus
				group by EntityId, MetaSelectedSectionId
			) as bs
				on css.MetaSelectedSectionId = bs.MetaSelectedSectionId
				and css.ProgramPlanId = bs.EntityId
			when not matched by target then
				insert (ProgramPlanId, MetaSelectedSectionid, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
				values (bs.EntityId, bs.MetaSelectedSectionId, bs.ValidCount, bs.RequiredCount, bs.ValidStateCount, bs.TotalStateCount)
			when matched and (
				css.ValidCount <> bs.ValidCount
				or css.TotalCount <> bs.RequiredCount
				or bs.ValidStateCount <> css.ValidStateCount
				or bs.TotalStateCount <> css.TotalStateCount
			) then update set
				css.ValidCount = bs.ValidCount
				,css.TotalCount = bs.RequiredCount
				,css.ValidStateCount = bs.ValidStateCount
				,css.TotalStateCount = bs.TotalStateCount
			output
				$action as [Action], inserted.ProgramPlanId as EntityId, @entityTypeId as EntityTypeId, inserted.MetaSelectedSectionId,
				inserted.ValidCount, inserted.TotalCount, inserted.ValidStateCount, inserted.TotalStateCount
				into @sectionSumaryOutput
				([Action], EntityId, EntityTypeId, MetaSelectedSectionId, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
			--output 'ProgramPlanSectionSummary' as "ProgramPlanSectionSummary", $action, inserted.*
			;
		end;
		else if (@entityTypeId = 5)
		begin
			merge into OrganizationSectionSummary as css
			using (
				select
					EntityId
					,MetaSelectedSectionId
					,sum(ValidCount) as ValidCount
					,sum(RequiredCount) as RequiredCount
					,isnull(sum(ValidStateCount), 0) as ValidStateCount
					,isnull(sum(TotalStateCount), 0) as TotalStateCount
				from #BadgeStatus
				group by EntityId, MetaSelectedSectionId
			) as bs
				on css.MetaSelectedSectionId = bs.MetaSelectedSectionId
				and css.OrganizationId = bs.EntityId
			when not matched by target then
				insert (OrganizationId, MetaSelectedSectionid, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
				values (bs.EntityId, bs.MetaSelectedSectionId, bs.ValidCount, bs.RequiredCount, bs.ValidStateCount, bs.TotalStateCount)
			when matched and (
				css.ValidCount <> bs.ValidCount
				or css.TotalCount <> bs.RequiredCount
				or bs.ValidStateCount <> css.ValidStateCount
				or bs.TotalStateCount <> css.TotalStateCount
			) then update set
				css.ValidCount = bs.ValidCount
				,css.TotalCount = bs.RequiredCount
				,css.ValidStateCount = bs.ValidStateCount
				,css.TotalStateCount = bs.TotalStateCount
			output
				$action as [Action], inserted.OrganizationId as EntityId, @entityTypeId as EntityTypeId, inserted.MetaSelectedSectionId,
				inserted.ValidCount, inserted.TotalCount, inserted.ValidStateCount, inserted.TotalStateCount
				into @sectionSumaryOutput
				([Action], EntityId, EntityTypeId, MetaSelectedSectionId, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
			--output 'OrganizationSectionSummary' as "OrganizationSectionSummary", $action, inserted.*
			;
		end;
		else if (@entityTypeId = 6)
		begin			
			update t set ValidCount = 0, TotalCount = 0, ValidStateCount = 0, TotalStateCount = 0
			from ModuleSectionSummary t 
			join #TargetEntities s 
			on t.ModuleId = s.Id;

			merge into ModuleSectionSummary as css
			using (
				select
					EntityId
					,MetaSelectedSectionId
					,sum(ValidCount) as ValidCount
					,sum(RequiredCount) as RequiredCount
					,isnull(sum(ValidStateCount), 0) as ValidStateCount
					,isnull(sum(TotalStateCount), 0) as TotalStateCount
				from #BadgeStatus
				group by EntityId, MetaSelectedSectionId
			) as bs
				on css.MetaSelectedSectionId = bs.MetaSelectedSectionId
				and css.ModuleId = bs.EntityId
			when not matched by target then
				insert (ModuleId, MetaSelectedSectionid, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
				values (bs.EntityId, bs.MetaSelectedSectionId, bs.ValidCount, bs.RequiredCount, bs.ValidStateCount, bs.TotalStateCount)
			when matched and (
				css.ValidCount <> bs.ValidCount
				or css.TotalCount <> bs.RequiredCount
				or bs.ValidStateCount <> css.ValidStateCount
				or bs.TotalStateCount <> css.TotalStateCount
			) then update set
				css.ValidCount = bs.ValidCount
				,css.TotalCount = bs.RequiredCount
				,css.ValidStateCount = bs.ValidStateCount
				,css.TotalStateCount = bs.TotalStateCount
			output
				$action as [Action], inserted.ModuleId as EntityId, @entityTypeId as EntityTypeId, inserted.MetaSelectedSectionId,
				inserted.ValidCount, inserted.TotalCount, inserted.ValidStateCount, inserted.TotalStateCount
				into @sectionSumaryOutput
				([Action], EntityId, EntityTypeId, MetaSelectedSectionId, ValidCount, TotalCount, ValidStateCount, TotalStateCount)
			--output 'ModuleSectionSummary' as "ModuleSectionSummary", $action, inserted.*
			;
		end;

		commit transaction; -- Transaction_UpdateSectionSummary

		if @debug = 1
		begin
			select
				concat(et.ReferenceTable, 'SectionSummary output') as __SectionSummaryOutput,
				sso.*, mss.SectionName
			from @sectionSumaryOutput sso
			inner join MetaSelectedSection mss on sso.MetaSelectedSectionId = mss.MetaSelectedSectionId
			inner join EntityType et on et.Id = @entityTypeId;

			print concat(@empty, @thisProcedureName
				,': Badge update complete.'
				,' (elapsed: ', datediff(ms, @procStartTime, sysdatetime()), ' ms'
				,', transaction count: ', @@trancount
				,')'
			);
		end
	end;

	-- Clean up temp tables
	drop table if exists #TargetEntities;
	drop table if exists #TargetFields;
	drop table if exists #FieldValues;
	drop table if exists #FieldEvaluations;
	drop table if exists #BadgeStatus;
	drop table if exists #ShowHideEvaluations;
	drop table if exists #MetaSelected;
end try
begin catch
	set @lastErrorNum = error_number();

	if @debug = 1
	begin
		print concat(@empty, @thisProcedureName
			,': error: ', @lastErrorNum
			,' (current time: ', sysdatetime()
			,', elapsed: ', datediff(ms, @procStartTime, sysdatetime()), ' ms'
			,', transaction count: ', @@trancount
			,')'
		);
	end

	while @@trancount > @startTransactionCount and xact_state() in (-1, 1)
	begin
		rollback transaction;
	end;

	-- Clean up temp tables
	drop table if exists #TargetEntities;
	drop table if exists #TargetFields;
	drop table if exists #FieldValues;
	drop table if exists #FieldEvaluations;
	drop table if exists #BadgeStatus;
	drop table if exists #ShowHideEvaluations;
	drop table if exists #MetaSelected;

	throw;
end catch

if @debug = 1
begin
	print concat(@empty, @thisProcedureName
		,': Operation complete.'
		,' (current time: ', sysdatetime()
		,', elapsed: ', datediff(ms, @procStartTime, sysdatetime()), ' ms'
		,', transaction count: ', @@trancount
		,', last error number: ', (case when @lastErrorNum is not null
			then cast(@lastErrorNum as nvarchar(max))
			else N'null'
			end)
		,')'
	);
end

