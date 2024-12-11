USE riohondo;

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16715';
DECLARE @Comments nvarchar(Max) = 'Changed Courses Condition of Enrollment tab to new forms';
DECLARE @Developer nvarchar(50) = 'Nate W.';
DECLARE @ScriptTypeId int = 1; 
/*  
Default for @ScriptTypeId on this script 
is 1 for  Support,  
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

/*
--------------------------------------------------------------------
Please do not alter the script above this comment except to set
the Use statement and the variables. 

Notes:  
	1.   In comments put a brief description of what the script does.
         You can also use this to document if we are doing something 
		 that is against meta best practices, but the client is 
		 insisting on, and that the client has been made aware of 
		 the potential consequences
	2.   ScriptTypeId
		 Note:  For Pre and Post Deploy we should follow the following 
		 script naming convention Release Number/Ticket Number/either the 
		 word Predeploy or PostDeploy
		 Example: Release3.103.0_DST-4645_PostDeploy.sql
-----------------Script details go below this line------------------
*/

declare @Templateid integers
insert into @Templateid
select MT.MetaTemplateId
from MetaTemplateType MTT
	inner join MetaTemplate MT on MT.MetaTemplateTypeId = MTT.MetaTemplateTypeId
where MTT.EntityTypeid = 1   -- select*from EntityType


declare @Tabid integers
insert into @Tabid
select MSS.MetaSelectedSectionId
from MetaSelectedSection MSS
inner join MetaSelectedSection MSSchild on MSS.MetaSelectedSectionId = MSSchild.MetaSelectedSection_MetaSelectedSectionId
	and MSSchild.MetaSectionTypeId in (500)
where MSS.MetaTemplateId in (select*from @Templateid)
	and MSS.MetaSelectedSection_MetaSelectedSectionId is null
	and MSS.MetaSectionTypeId = 15
	and MSSchild.MetaBaseSchemaId = 109



-- Convert Tabs
update MetaSelectedSection
set MetaSectionTypeId = 30
where MetaSelectedSectionid in (select*from @Tabid)
--End Convert Tabs


-- Clean Up Tabs
declare @TabSections integers

;with Sections
as (select*from @Tabid
	union ALL
	select MSS.MetaSelectedSectionId 
	from Sections S
		inner join MetaSelectedSection MSS on S.Id = MSS.MetaSelectedSection_MetaSelectedSectionId
)
insert into @TabSections
select *
from Sections

delete from MetaSelectedFieldRolePermission
WHERE MetaSelectedFieldId in (
	SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaSelectedSectionId in (
		SELECT * FROM @TabSections
	)
	AND MetaAvailableFieldId = 290
)

delete MetaSelectedField 
where MetaSelectedSectionid in (select*from @TabSections)
	and MetaAvailableFieldId = 290

declare @EmptySections integers

insert into @EmptySections
select MSS.MetaSelectedSectionid
from MetaSelectedSection MSS
	inner join @TabSections TS on MSS.MetaSelectedSectionId = TS.id
	left join MetaSelectedField MSF on MSS.MetaSelectedSectionId = MSF.MetaSelectedSectionId
	left join MetaSelectedSection MSS2 on MSS.MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
where MSF.MetaSelectedFieldId is null
	and MSS2.MetaSelectedSectionId is null

while exists(select*from @EmptySections)
begin

	delete MetaDisplaySubscriber
	where MetaSelectedSectionid in (select*from @EmptySections)
	
	delete MetaSelectedSectionAttribute
	where MetaSelectedSectionid in (select*from @EmptySections)
	
	delete MetaSelectedSectionRolePermission
	where MetaSelectedSectionid in (select*from @EmptySections)
	
	delete MetaSelectedSection
	where MetaSelectedSectionid in (select*from @EmptySections)
	
	delete @EmptySections where 1 = 1 
	
	insert into @EmptySections
	select MSS.MetaSelectedSectionid
	from MetaSelectedSection MSS
		inner join @TabSections TS on MSS.MetaSelectedSectionId = TS.id
		left join MetaSelectedField MSF on MSS.MetaSelectedSectionId = MSF.MetaSelectedSectionId
		left join MetaSelectedSection MSS2 on MSS.MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
	where MSF.MetaSelectedFieldId is null
		and MSS2.MetaSelectedSectionId is null
	
end

update MSS
set RowPosition = A.ROWNUM - 1, SortOrder = A.ROWNUM - 1
from MetaSelectedSection MSS
	inner join (
		select MetaSelectedSectionId,ROW_NUMBER() OVER (Partition by T.id ORDER BY RowPosition,MetaSelectedSectionId) as ROWNUM
		from MetaSelectedSection MSS
			inner join @TabSections T on MSS.MetaSelectedSection_MetaSelectedSectionId = T.id
	) A on MSS.MetaSelectedSectionId = A.MetaSelectedSectionId

update MSF
set RowPosition = A.ROWNUM - 1
from MetaSelectedField MSF
	inner join (
		select MetaSelectedFieldId,ROW_NUMBER() OVER (Partition by T.id ORDER BY RowPosition,MetaSelectedSectionId) as ROWNUM
		from MetaSelectedField MSF
			inner join @TabSections T on MSF.MetaSelectedSectionId = T.id
	) A on MSF.MetaSelectedFieldId = A.MetaSelectedFieldId
-- End Clean Up Tabs



--fix showhide
update MDS
set MetaDisplayRuleId = MDR.Id
from ExpressionPart EP
	inner join ExpressionPart EP2 on EP.Operand2Literal = EP2.Operand2Literal
		and EP.Operand1_MetaSelectedFieldId = EP2.Operand1_MetaSelectedFieldId
		and EP.ExpressionOperatorTypeId = EP2.ExpressionOperatorTypeId
		and EP.ExpressionId < EP2.ExpressionId
	inner join ExpressionPart EPP on EP.Parent_ExpressionPartId = EPP.Id
		and EPP.Parent_ExpressionPartId is null
	inner join ExpressionPart EPP2 on EP2.Parent_ExpressionPartId = EPP2.Id
		and EPP2.Parent_ExpressionPartId is null
	left join ExpressionPart EPB on EP.ExpressionId = EPB.ExpressionId
		and EP.id <> EPB.id
		and EPP.id <> EPB.id
	left join ExpressionPart EPB2 on EP2.ExpressionId = EPB2.ExpressionId
		and EP2.id <> EPB2.id
		and EPP2.id <> EPB2.id
	outer Apply (
		select TEP.ExpressionId as ExpressionId
		from ExpressionPart tEP
		inner join ExpressionPart tEP2 on tEP.Operand2Literal = tEP2.Operand2Literal
			and tEP.Operand1_MetaSelectedFieldId = tEP2.Operand1_MetaSelectedFieldId
			and tEP.ExpressionOperatorTypeId = tEP2.ExpressionOperatorTypeId
			and tEP.ExpressionId > tEP2.ExpressionId
		inner join ExpressionPart tEPP on tEP.Parent_ExpressionPartId = tEPP.Id
			and tEPP.Parent_ExpressionPartId is null
		inner join ExpressionPart TEPP2 on TEP2.Parent_ExpressionPartId = TEPP2.Id
			and TEPP2.Parent_ExpressionPartId is null
		left join ExpressionPart TEPB on TEP.ExpressionId = TEPB.ExpressionId
			and TEP.id <> TEPB.id
			and TEPP.id <> TEPB.id
		left join ExpressionPart TEPB2 on TEP2.ExpressionId = TEPB2.ExpressionId
			and TEP2.id <> TEPB2.id
			and TEPP2.id <> TEPB2.id
		where TEPB.id is null 
			and TEPB2.id is null
			and TEP.ExpressionId = EP.ExpressionId
	) A
	inner join MetaDisplayRule MDR on MDR.ExpressionId = EP.ExpressionId
	inner join MetaDisplayRule MDR2 on MDR2.ExpressionId = EP2.ExpressionId
	inner join MetaDisplaySubscriber MDS on MDS.MetaDisplayRuleId = MDR2.Id
	inner join MetaSelectedField MSF on MSF.MetaSelectedFieldId = EP.Operand1_MetaSelectedFieldId
	inner join @TabSections TS on MSF.MetaSelectedSectionId = TS.Id
where EPB.id is null 
	and EPB2.id is null
	and A.ExpressionId is null

update EP
set ExpressionOperatorTypeid = 17
from ExpressionPart EP
	inner join MetaSelectedField MSF on MSF.MetaSelectedFieldId = EP.Operand1_MetaSelectedFieldId
	inner join @TabSections TS on MSF.MetaSelectedSectionId = TS.Id
where EP.ExpressionOperatorTypeid = 3 and EP.Operand2Literal = '-1'

delete MDS
from MetaDisplaySubscriber MDS
	inner join MetaDisplaySubscriber MDS2 on MDS.MetaDisplayRuleId = MDS2.MetaDisplayRuleId
		and MDS.MetaSelectedSectionId = MDS2.MetaSelectedSectionId
		and MDS.Id < MDS2.Id
	inner join @TabSections TS on MDS.MetaSelectedSectionId = TS.Id

declare @expresionid integers

insert into @expresionid
select MDR.ExpressionId
from MetaDisplayRule MDR
	left join MetaDisplaySubscriber MDS on MDS.MetaDisplayRuleId = MDR.id
where MDS.Id is null

delete MetaDisplayRule
where ExpressionId in (select*from @expresionid)

delete ExpressionPart
where ExpressionId in (select*from @expresionid)


declare @SectionFixShowhide integers

insert into @SectionFixShowhide
select MSS.MetaSelectedSectionId
from MetaSelectedSection MSS
	inner join @TabSections TS on TS.id = MSS.MetaSelectedSectionId
	cross apply (
		select count(MDS.id) as C 
		from MetaDisplaySubscriber MDS
		where MDS.MetaSelectedSectionId = MSS.MetaSelectedSectionId
	) C
where C.C > 1

declare @newsection integers

while exists(select*from @SectionFixShowhide)
begin

	insert MetaSelectedSection
	(ClientId,MetaSelectedSection_MetaSelectedSectionId,SectionName,DisplaySectionName,SectionDescription,DisplaySectionDescription,
	ColumnPosition,RowPosition,SortOrder,SectionDisplayId,MetaSectionTypeId,MetaTemplateId,DisplayFieldId,HeaderFieldId,FooterFieldId,
	OriginatorOnly,MetaBaseSchemaId,MetadataAttributeMapId,EntityListLibraryTypeId,EditMapId,AllowCopy,ReadOnly,Config)
	output inserted.MetaSelectedSectionid into @newsection
	select
	MSS.ClientId,MSS.MetaSelectedSection_MetaSelectedSectionId,null,0,NULL,0,NULL,MSS.RowPosition,MSS.RowPosition,1,1,MSS.MetaTemplateId,NULL,NULL,NULL,0,MSS.MetaBaseSchemaId,NULL,NULL,NULL,1,0,NULL
	from MetaSelectedSection MSS
		inner join @SectionFixShowhide S on MSS.MetaSelectedSectionId = S.Id
	
	update MSS
	set MetaSelectedSection_MetaSelectedSectionId = NS.Id,RowPosition = 0,SortOrder = 0
	from MetaSelectedSection MSS
		inner join @SectionFixShowhide S on MSS.MetaSelectedSectionId = S.Id
		inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
			and MSS.RowPosition = MSS2.RowPosition
		inner join @newsection NS on MSS2.MetaSelectedSectionId = NS.Id
	
	update MDS
	set MetaSelectedSectionId = MSS.MetaSelectedSection_MetaSelectedSectionId
	from MetaSelectedSection MSS
		inner join @SectionFixShowhide S on MSS.MetaSelectedSectionId = S.Id
		cross apply (
			select max(id) as id
			from MetaDisplaySubscriber 
			where MetaSelectedSectionId = MSS.MetaSelectedSectionId
		) A
		inner join MetaDisplaySubscriber MDS on MSS.MetaSelectedSectionId = MDS.MetaSelectedSectionId
			and A.id = MDS.Id

	insert into @TabSections
	select*from @newsection

	delete @SectionFixShowhide 
	where 1 = 1

	delete @newsection
	where 1 = 1

	insert into @SectionFixShowhide
	select MSS.MetaSelectedSectionId
	from MetaSelectedSection MSS
		inner join @TabSections TS on TS.id = MSS.MetaSelectedSectionId
		cross apply (
			select count(MDS.id) as C 
			from MetaDisplaySubscriber MDS
			where MDS.MetaSelectedSectionId = MSS.MetaSelectedSectionId
		) C
	where C.C > 1

end
-- End fix showhide


-- Convert StaticText
declare @StaticTextid integers
insert into @StaticTextid
select MSF.MetaSelectedFieldId 
from MetaSelectedField MSF
	inner join @TabSections TS on TS.id = MSF.MetaSelectedSectionId
where MSF.MetaPresentationTypeId = 35

if exists(select top 1 1 from @StaticTextid)
begin

	update MSS
	set DisplaySectionDescription = 1,SectionDescription = isnull(MSS.SectionDescription + '<br>','') + MSF.DisplayName
	from MetaSelectedSection MSS
	inner join MetaSelectedField MSF on mSS.MetaSelectedSectionId = MSF.MetaSelectedSectionId
	inner join @StaticTextid ST on ST.id = MSF.MetaSelectedFieldId
	where MSF.RowPosition = 0

end
-- End Convert StaticText



-- Convert TelerikChainedCombo 
declare @FKEY integers;

declare @TelerikChainedComboid integers 
insert into @TelerikChainedComboid
select MSS.MetaSelectedSectionId 
from MetaSelectedSection MSS
	inner join @TabSections TS on TS.id = MSS.MetaSelectedSectionId
where MSS.MetaSectionTypeId = 22

update MSS
set MetaSectionTypeId = 1,MetaBaseSchemaId = MSSP.MetaBaseSchemaId
from MetaSelectedSection MSS
	inner join MetaSelectedSection MSSP on MSS.MetaSelectedSection_MetaSelectedSectionId = MSSP.MetaSelectedSectionId
	inner join @TelerikChainedComboid TCC on MSS.MetaSelectedSectionId = TCC.Id


declare @TelerikChainedComboChildrenWithoutFkey integers
insert into @TelerikChainedComboChildrenWithoutFkey
select MSF.MetaSelectedFieldId
from MetaSelectedField MSF 
inner join MetaAvailableField MAF on MSF.MetaAvailableFieldId = MAF.MetaAvailableFieldId
where MSF.MetaSelectedSectionid in (select*from @TelerikChainedComboid)
	and MSF.MetaForeignKeyLookupSourceId is null

insert into @FKEY 
select top (
	select count(*) from (
	select MSF.MetaAvailableFieldId
	from @TelerikChainedComboChildrenWithoutFkey Field
	inner join MetaSelectedField MSF on Field.id = MSF.MetaSelectedFieldId
	group by MSF.MetaAvailableFieldId) A
) Id
from (
	select ROW_NUMBER() over (order by id) as Id
	from MetaForeignKeyCriteriaClient
	union 
	select MAX(id) + 1 as Id from MetaForeignKeyCriteriaClient
	) A
where Id not in (select id from MetaForeignKeyCriteriaClient)
order by Id

insert into MetaForeignKeyCriteriaClient
(Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,Title,LookupLoadTimingType)
select
FKEY.id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,Title,3
from (
	select
	FKEYBASE.TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,
	isnull(ResolutionSql,concat('select ',DefaultDisplayColumn,' from ',FKEYBASE.TableName,' where ',DefaultValueColumn,' = @id') ) as ResolutionSql,
	DefaultSortColumn,Title,LookupLoadTimingType,ROW_NUMBER() over (Order by MSF.MetaSelectedFieldid) as ROWNUM
	from MetaSelectedField MSF 
		inner join MetaAvailableField MAF on MSF.MetaAvailableFieldId = MAF.MetaAvailableFieldId
		inner join MetaForeignKeyCriteriaBase FKEYBASE on MAF.MetaForeignKeyLookupSourceId = FKEYBASE.id
	where MSF.MetaSelectedFieldId in (select*from @TelerikChainedComboChildrenWithoutFkey)
) A
inner join (select id,ROW_NUMBER() over (Order by id) as ROWNUM from @FKEY) FKEY on A.ROWNUM = FKEY.ROWNUM


update MSF
set MetaForeignKeyLookupSourceId = FKEY.Id
from (
	select MSF.MetaAvailableFieldId,ROW_NUMBER() over (Order by MSF.MetaAvailableFieldId) as ROWNUM
	from @TelerikChainedComboChildrenWithoutFkey Field
	inner join MetaSelectedField MSF on Field.id = MSF.MetaSelectedFieldId
	group by MSF.MetaAvailableFieldId
) A
inner join (select id,ROW_NUMBER() over (Order by id) as ROWNUM from @FKEY) FKEY on A.ROWNUM = FKEY.ROWNUM
inner join MetaSelectedField MSF on A.MetaAvailableFieldId = MSF.MetaAvailableFieldId
inner join @TelerikChainedComboChildrenWithoutFkey Field on MSF.MetaSelectedFieldId = Field.id


declare @ChildFieldId integers
insert into @ChildFieldId
select MetaSelectedFieldid 
from MetaSelectedField MSF  
	inner join MetaForeignKeyCriteriaClient FKEY on MSF.MetaForeignKeyLookupSourceId = FKEY.Id
	inner join MetaAvailableField MAF on MSF.MetaAvailableFieldId = MAF.MetaAvailableFieldId
	left join MetaSelectedSectionAttribute MSSA on MSF.MetaSelectedSectionId = MSSA.MetaSelectedSectionId 
		and MSSA.Name = 'Tier0ForeignKeyField' 
		and MSSA.Value = MAF.ColumnName
	left join MetaSelectedSectionAttribute MSSA2 on MSF.MetaSelectedSectionId = MSSA2.MetaSelectedSectionId 
		and MSSA2.Name = 'Tier0Table' 
		and MSSA2.Value = MAF.TableName
where MSF.MetaSelectedSectionid in (select*from @TelerikChainedComboid)
	and (MSSA.Id is null OR MSSA2.Id is null)


-- Update the children 
update FKEY
set CustomSql = 'declare @curentcourseids integers
insert into @curentcourseids
select Requisite_CourseId from CourseRequisite where courseid = @entityid

select c.Id as Value, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title + '' ('' + sa.Title + '')'' as Text , c.SubjectId as FilterValue
from Course c 
	inner join [Subject] s on s.Id = c.SubjectId 
	inner join StatusAlias sa on sa.Id = c.StatusAliasId 
where c.ClientId = @Clientid
	and c.Active = 1 
	and c.SubjectId is not null 
	and sa.StatusBaseId in(1, 2, 4, 6)
union
select c.Id as Value, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title + '' ('' + sa.Title + '')'' as Text , c.SubjectId as FilterValue
from Course c 
	inner join [Subject] s on s.Id = c.SubjectId 
	inner join StatusAlias sa on sa.Id = c.StatusAliasId 
	inner join @curentcourseids CC on C.id = CC.Id
order by Text'
from MetaSelectedField MSF 
	inner join MetaForeignKeyCriteriaClient FKEY on MSF.MetaForeignKeyLookupSourceId = FKEY.Id
	inner join @ChildFieldId CF on MSF.MetaSelectedFieldId = CF.id



delete MetaSelectedFieldAttribute
from MetaSelectedFieldAttribute MSFA
	inner join @ChildFieldId CF on MSFA.MetaSelectedFieldId = CF.id

insert into MetaSelectedFieldAttribute
(Name,[Value],MetaSelectedFieldId)
select 'FilterSubscriptionTable',MSSA4.Value,MSF.MetaSelectedFieldId
from MetaSelectedField MSF 
	inner join @ChildFieldId CF on MSF.MetaSelectedFieldId = CF.id
	inner join MetaAvailableField MAF on MSF.MetaAvailableFieldId = MAF.MetaAvailableFieldId
	inner join MetaSelectedSectionAttribute MSSA on MSF.MetaSelectedSectionId = MSSA.MetaSelectedSectionId 
		and MSSA.Value = MAF.TableName
	inner join MetaSelectedSectionAttribute MSSA2 on MSF.MetaSelectedSectionId = MSSA2.MetaSelectedSectionId 
		and MSSA2.Value = MAF.ColumnName
		and replace(MSSA.Name,'Table','') = replace(MSSA2.Name,'ForeignKeyField','') 
	inner join MetaSelectedSectionAttribute MSSA3 on MSF.MetaSelectedSectionId = MSSA3.MetaSelectedSectionId 
		and MSSA3.Name like '%FilterColumn'
		and replace(MSSA3.Name,'FilterColumn','') = replace(MSSA2.Name,'ForeignKeyField','') 
	inner join MetaSelectedSectionAttribute MSSA4 on MSF.MetaSelectedSectionId = MSSA4.MetaSelectedSectionId 
		and MSSA4.Name like '%Table' 
		and convert(int,replace(replace(MSSA4.Name,'Tier',''),'Table','')) = convert(int,replace(replace(MSSA.Name,'Tier',''),'Table','') ) - 1
	inner join MetaSelectedSectionAttribute MSSA5 on MSF.MetaSelectedSectionId = MSSA5.MetaSelectedSectionId 
		and MSSA5.Name like '%ForeignKeyField'
		and convert(int,replace(replace(MSSA5.Name,'Tier',''),'ForeignKeyField','')) = convert(int,replace(replace(MSSA2.Name,'Tier',''),'ForeignKeyField','') ) - 1
union
select
'FilterSubscriptionColumn',MSSA5.Value,MSF.MetaSelectedFieldId
from MetaSelectedField MSF 
	inner join @ChildFieldId CF on MSF.MetaSelectedFieldId = CF.id
	inner join MetaAvailableField MAF on MSF.MetaAvailableFieldId = MAF.MetaAvailableFieldId
	inner join MetaSelectedSectionAttribute MSSA on MSF.MetaSelectedSectionId = MSSA.MetaSelectedSectionId 
		and MSSA.Value = MAF.TableName
	inner join MetaSelectedSectionAttribute MSSA2 on MSF.MetaSelectedSectionId = MSSA2.MetaSelectedSectionId 
		and MSSA2.Value = MAF.ColumnName
		and replace(MSSA.Name,'Table','') = replace(MSSA2.Name,'ForeignKeyField','') 
	inner join MetaSelectedSectionAttribute MSSA3 on MSF.MetaSelectedSectionId = MSSA3.MetaSelectedSectionId 
		and MSSA3.Name like '%FilterColumn'
		and replace(MSSA3.Name,'FilterColumn','') = replace(MSSA2.Name,'ForeignKeyField','') 
	inner join MetaSelectedSectionAttribute MSSA4 on MSF.MetaSelectedSectionId = MSSA4.MetaSelectedSectionId 
		and MSSA4.Name like '%Table' 
		and convert(int,replace(replace(MSSA4.Name,'Tier',''),'Table','')) = convert(int,replace(replace(MSSA.Name,'Tier',''),'Table','') ) - 1
	inner join MetaSelectedSectionAttribute MSSA5 on MSF.MetaSelectedSectionId = MSSA5.MetaSelectedSectionId 
		and MSSA5.Name like '%ForeignKeyField'
		and convert(int,replace(replace(MSSA5.Name,'Tier',''),'ForeignKeyField','')) = convert(int,replace(replace(MSSA2.Name,'Tier',''),'ForeignKeyField','') )  - 1
union
select
'FilterTargetTable',MSSA.Value,MSF.MetaSelectedFieldId
from MetaSelectedField MSF 
	inner join @ChildFieldId CF on MSF.MetaSelectedFieldId = CF.id
	inner join MetaAvailableField MAF on MSF.MetaAvailableFieldId = MAF.MetaAvailableFieldId
	inner join MetaSelectedSectionAttribute MSSA on MSF.MetaSelectedSectionId = MSSA.MetaSelectedSectionId 
		and MSSA.Value = MAF.TableName
	inner join MetaSelectedSectionAttribute MSSA2 on MSF.MetaSelectedSectionId = MSSA2.MetaSelectedSectionId 
		and MSSA2.Value = MAF.ColumnName
		and replace(MSSA.Name,'Table','') = replace(MSSA2.Name,'ForeignKeyField','') 
	inner join MetaSelectedSectionAttribute MSSA3 on MSF.MetaSelectedSectionId = MSSA3.MetaSelectedSectionId 
		and MSSA3.Name like '%FilterColumn'
		and replace(MSSA3.Name,'FilterColumn','') = replace(MSSA2.Name,'ForeignKeyField','') 
	inner join MetaSelectedSectionAttribute MSSA4 on MSF.MetaSelectedSectionId = MSSA4.MetaSelectedSectionId 
		and MSSA4.Name like '%Table' 
		and convert(int,replace(replace(MSSA4.Name,'Tier',''),'Table','')) = convert(int,replace(replace(MSSA.Name,'Tier',''),'Table','') ) - 1
	inner join MetaSelectedSectionAttribute MSSA5 on MSF.MetaSelectedSectionId = MSSA5.MetaSelectedSectionId 
		and MSSA5.Name like '%ForeignKeyField'
		and convert(int,replace(replace(MSSA5.Name,'Tier',''),'ForeignKeyField','')) = convert(int,replace(replace(MSSA2.Name,'Tier',''),'ForeignKeyField','') ) - 1
union
select
'FilterTargetColumn',MSSA2.Value,MSF.MetaSelectedFieldId
from MetaSelectedField MSF 
	inner join @ChildFieldId CF on MSF.MetaSelectedFieldId = CF.id
	inner join MetaAvailableField MAF on MSF.MetaAvailableFieldId = MAF.MetaAvailableFieldId
	inner join MetaSelectedSectionAttribute MSSA on MSF.MetaSelectedSectionId = MSSA.MetaSelectedSectionId 
		and MSSA.Value = MAF.TableName
	inner join MetaSelectedSectionAttribute MSSA2 on MSF.MetaSelectedSectionId = MSSA2.MetaSelectedSectionId 
		and MSSA2.Value = MAF.ColumnName
		and replace(MSSA.Name,'Table','') = replace(MSSA2.Name,'ForeignKeyField','') 
	inner join MetaSelectedSectionAttribute MSSA3 on MSF.MetaSelectedSectionId = MSSA3.MetaSelectedSectionId 
		and MSSA3.Name like '%FilterColumn'
		and replace(MSSA3.Name,'FilterColumn','') = replace(MSSA2.Name,'ForeignKeyField','') 
	inner join MetaSelectedSectionAttribute MSSA4 on MSF.MetaSelectedSectionId = MSSA4.MetaSelectedSectionId 
		and MSSA4.Name like '%Table' 
		and convert(int,replace(replace(MSSA4.Name,'Tier',''),'Table','')) = convert(int,replace(replace(MSSA.Name,'Tier',''),'Table','') ) - 1
	inner join MetaSelectedSectionAttribute MSSA5 on MSF.MetaSelectedSectionId = MSSA5.MetaSelectedSectionId 
		and MSSA5.Name like '%ForeignKeyField'
		and convert(int,replace(replace(MSSA5.Name,'Tier',''),'ForeignKeyField','')) = convert(int,replace(replace(MSSA2.Name,'Tier',''),'ForeignKeyField','') ) - 1

delete MetaSelectedSectionAttribute
where MetaSelectedSectionid in (select*from @TelerikChainedComboid)
-- End Convert TelerikChainedCombo


-- Convert OrderedList
declare @OrderedList table
(ID int,tablename NVARCHAR(max),columnname NVARCHAR(max),Title NVARCHAR(max), MetaSqlStatement NVARCHAR(max),MetaSqlStatementid int,clientid int)
insert into @OrderedList(ID)
select OL.MetaSelectedSectionid
from MetaSelectedSection OL
	inner join MetaSelectedSection TAB on OL.MetaSelectedSection_MetaSelectedSectionId = TAB.MetaSelectedSectionId
		and TAB.MetaSelectedSectionId in (select*from @TabSections)
where OL.MetaSectionTypeId in (2,500)

update @OrderedList
set tablename = MSSA.value,columnname = MSSA2.value
from @OrderedList OL
	inner join MetaSelectedSectionAttribute MSSA on MSSA.MetaSelectedSectionid = OL.id
		and MSSA.name = 'TitleTable'
	inner join MetaSelectedSectionAttribute MSSA2 on MSSA2.MetaSelectedSectionid = OL.id
		and MSSA2.name = 'TitleColumn'
	inner join MetaSelectedSection MSS on MSSA.MetaSelectedSectionId = MSS.MetaSelectedSectionId
	and MSS.MetaSectionTypeId = 500


update @OrderedList
set tablename = MBS.ForeignTable,
columnname = case 
				when MAF.ColumnName is not null then 'Title'
				when MAF2.ColumnName is not null then 'TextOther'
				else ''
			end
from @OrderedList OL
	inner join MetaSelectedSection MSS on OL.id = MSS.MetaSelectedSectionId
	and MSS.MetaSectionTypeId = 2
	inner join MetaBaseSchema MBS on MSS.MetaBaseSchemaId = MBS.id
	left join MetaSelectedField MSF on MSF.MetaSelectedSectionId = MSS.MetaSelectedSectionId
	left join MetaAvailableField MAF on MSF.MetaAvailableFieldId = MAF.MetaAvailableFieldId
		and MAF.ColumnName = 'Title'
	left join MetaSelectedField MSF2 on MSF2.MetaSelectedSectionId = MSS.MetaSelectedSectionId
	left join MetaAvailableField MAF2 on MSF2.MetaAvailableFieldId = MAF2.MetaAvailableFieldId
		and MAF2.ColumnName = 'TextOther'


update @OrderedList
set Title = SectionName, clientid = 57
from @OrderedList OL
inner join MetaSelectedSection MSS on MSS.MetaSelectedSectionid = OL.id
inner join MetaTemplate MT on MSS.MetaTemplateId = MT.MetaTemplateId
where 1 = 1

MERGE ListItemType LIT
	USING ( 
		select OL.Title,1,OL.tablename,OL.columnname,1,1,GETDATE(),OL.Clientid
	from @OrderedList OL
		left join @OrderedList OL2 on OL.tablename = OL2.tablename 
			and OL.columnname = OL2.columnname
			and OL.id <> OL2.id
			and OL2.id < OL.id
		where OL2.id is null
		union 
		select 'Group',2,'CourseRequisite','RequisiteContent',1,2,getdate(),1) AS OL (Title,ListItemTypeOrdinal,ListItemTableName,ListItemTitleColumn,active,SortOrder,StartDate,ClientId)
ON (LIT.ListItemTableName = OL.ListItemTableName and LIT.ListItemTitleColumn = OL.ListItemTitleColumn) or
	(LIT.ListItemTableName = OL.ListItemTableName and LIT.ListItemTypeOrdinal = OL.ListItemTypeOrdinal) or
	(LIT.ListItemTableName = OL.ListItemTableName and LIT.SortOrder = OL.SortOrder)
WHEN NOT MATCHED THEN 
INSERT (Title,ListItemTypeOrdinal,ListItemTableName,ListItemTitleColumn,active,SortOrder,StartDate,ClientId)
VALUES (OL.Title,OL.ListItemTypeOrdinal,OL.ListItemTableName,OL.ListItemTitleColumn,OL.active,OL.SortOrder,OL.StartDate,57);

delete MetaSelectedSectionAttribute
where MetaSelectedSectionid in (select id from @OrderedList)

-- order list requiremnets
declare @CourseListItemTypeid int = (select id from ListItemType where ListItemTypeOrdinal = 1 and ListItemTableName = 'CourseRequisite')


declare @Fieldsectionsshowhide table (FieldId int, SectionId int)
;with FieldsSections
as (select MSF.MetaSelectedFieldId as fieldid,MSF.MetaSelectedSectionId as Sectionid
	from MetaSelectedField MSF
		inner join @TabSections TS on MSF.MetaSelectedSectionId = TS.Id
		inner join MetaDisplaySubscriber MDS on MDS.MetaSelectedSectionId = Ts.Id
	where MSF.IsRequired = 1
	union ALL
	select FS.fieldid,MSS2.MetaSelectedSectionId as Sectionid
	from FieldsSections FS
		inner join MetaSelectedSection MSS on FS.SectionId = MSS.MetaSelectedSectionId
		inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSectionId
		inner join MetaDisplaySubscriber MDS on MDS.MetaSelectedSectionId = MSS2.MetaSelectedSectionId
)
insert into @Fieldsectionsshowhide
(FieldId, SectionId)
select FieldId, SectionId
from FieldsSections

update OL
set MetaSqlStatement = case when CN.ColumnName is null then null else
concat('declare @validCount int = 0;
declare @totalCount int = 0;

set @totalCount = (select count(' + MBS.PrimaryKey + ')
from ' + MBS.ForeignTable + '
where ' + MBS.Foreignkey + ' = @entityid
	and ListItemTypeId = ',@CourseListItemTypeid,'
)

set @validCount = (select count(' + MBS.PrimaryKey + ')
from ' + MBS.ForeignTable + '
where ' + MBS.Foreignkey + ' = @entityid
	'+ CN.ColumnName + '
	and ListItemTypeId = ',@CourseListItemTypeid,'
)

select case
	when @totalCount = @validCount
	then 1
	else 0
end;') end
from @OrderedList OL
	inner join MetaSelectedSection MSS on OL.id = MSS.MetaSelectedSectionId
	inner join MetaBaseSchema MBS on MSS.MetaBaseSchemaId = MBS.id
	Cross apply
	(select dbo.ConcatWithSep_Agg(concat(char(10),char(9)),concat('and (', MAF.ColumnName, ' is not null',
		case
			when EP.ExpressionOperatorTypeId = 8 and EP.Operand2Literal = '{@thisyear}' then ' or ' + MAF2.ColumnName + ' > year(GETDATE()) - 5'
			when EP.ExpressionOperatorTypeId = 3 and EP.ComparisonDataTypeId = 3 then ' or ' + MAF2.ColumnName + ' = ' + EP.Operand2Literal
			when EP.ExpressionOperatorTypeId = 16 and EP.ComparisonDataTypeId = 3 then ' or ' + MAF2.ColumnName + ' <> ' + EP.Operand2Literal
			when EP.ExpressionOperatorTypeId = 3 and EP.ComparisonDataTypeId = 4 then ' or ' + MAF2.ColumnName + ' = ''' + EP.Operand2Literal + ''''
			when EP.ExpressionOperatorTypeId = 16 and EP.ComparisonDataTypeId = 4 then ' or ' + MAF2.ColumnName + ' <> ''' + EP.Operand2Literal + ''''
			else ''
		end
		, CN2.text
		,')' ) ) as ColumnName
	from MetaSelectedField MSF 
		inner join MetaAvailableField MAF on MSF.MetaAvailableFieldId = MAF.MetaAvailableFieldId
		inner join MetaSelectedSection MSS2 on MSS.MetaTemplateId = MSS2.MetaTemplateId
		inner join @TabSections TS on MSS2.MetaSelectedSectionId = TS.Id
		left join MetaDisplaySubscriber MDS on MDS.MetaSelectedFieldId = MSF.MetaSelectedFieldId
		left join MetaDisplayRule MDR on MDS.MetaDisplayRuleId = MDR.id
		left join ExpressionPart EP on MDR.ExpressionId = EP.ExpressionId
			and Parent_ExpressionPartId is not null
		left join MetaSelectedField MSF2 on EP.Operand1_MetaSelectedFieldId = MSF2.MetaSelectedFieldId
		left join MetaAvailableField MAF2 on MSF2.MetaAvailableFieldId = MAF2.MetaAvailableFieldId
		outer apply (
			select dbo.ConcatWithSep_Agg('',
			case
				when EP2.ExpressionOperatorTypeId = 3 and EP2.ComparisonDataTypeId = 3 then ' or ' + MAF3.ColumnName + ' = ' + EP2.Operand2Literal
				when EP2.ExpressionOperatorTypeId = 16 and EP2.ComparisonDataTypeId = 3 then ' or ' + MAF3.ColumnName + ' <> ' + EP2.Operand2Literal
				when EP2.ExpressionOperatorTypeId = 3 and EP2.ComparisonDataTypeId = 4 then ' or ' + MAF3.ColumnName + ' = ''' + EP2.Operand2Literal + ''''
				when EP2.ExpressionOperatorTypeId = 16 and EP2.ComparisonDataTypeId = 4 then ' or ' + MAF3.ColumnName + ' <> ''' + EP2.Operand2Literal + ''''
				else ''
			end) as text
			from @Fieldsectionsshowhide FSSH 
			left join MetaDisplaySubscriber MDS2 on MDS2.MetaSelectedSectionId = FSSH.SectionId
			left join MetaDisplayRule MDR2 on MDS2.MetaDisplayRuleId = MDR2.id
			left join ExpressionPart EP2 on MDR2.ExpressionId = EP2.ExpressionId
				and EP2.Parent_ExpressionPartId is not null
			left join MetaSelectedField MSF3 on EP2.Operand1_MetaSelectedFieldId = MSF3.MetaSelectedFieldId
			left join MetaAvailableField MAF3 on MSF3.MetaAvailableFieldId = MAF3.MetaAvailableFieldId
			where FSSH.FieldId = MSF.MetaSelectedFieldId) CN2
	where MSF.MetaSelectedSectionId = MSS2.MetaSelectedSectionId
		and MSF.IsRequired = 1
	) CN


merge MetaSqlStatement USING (
	select distinct MetaSqlStatement,1
	from @OrderedList
	where MetaSqlStatement is not null
) AS MSqlS (SqlStatement,SqlStatementTypeId)
on 1 = 0
WHEN NOT MATCHED THEN 
INSERT (SqlStatement,SqlStatementTypeId)
values (MSqlS.SqlStatement,MSqlS.SqlStatementTypeId);

update OL
set MetaSqlStatementid = MSS.id
from @OrderedList OL
	inner join MetaSqlStatement MSS on MSS.SqlStatement = OL.MetaSqlStatement
where 1 = 1

insert into MetaControlAttribute
(MetaSelectedSectionId,Description,MetaControlAttributeTypeId,CustomMessage,MetaSqlStatementId)
select Id,'Require the required fields',6,'Launch Requirement: All required fields must be filled out.',MetaSqlStatementid
from @OrderedList
where MetaSqlStatementid is not null

update MetaSelectedSection
set MetaSectionTypeId = 31
where MetaSelectedSectionid in (select id from @OrderedList)


Declare @queryString nvarchar(MAX) =
(
	select DBO.Concat_Agg(text)
	from (select distinct concat('update ', OL.tablename, ' set ListItemTypeId = ',LIT.Id,' Where 1 = 1
	') as text
	from @OrderedList OL
	inner join ListItemType LIT on OL.tablename = LIT.ListItemTableName and OL.columnname = LIT.ListItemTitleColumn) A
)

exec sp_executesql @queryString

declare @Fieldid integers

;with Sections
as (select OL.id from @OrderedList OL
	union ALL
	select MSS.MetaSelectedSectionId 
	from Sections S
		inner join MetaSelectedSection MSS on S.Id = MSS.MetaSelectedSection_MetaSelectedSectionId
)
insert into @Fieldid
select distinct MSF.MetaSelectedFieldId
from Sections S
	inner join MetaSelectedField MSF on MSF.MetaSelectedSectionId = S.id


insert into MetaSelectedFieldAttribute
(Name,Value,MetaSelectedFieldId)
select 'listitemtype',1,id
from @Fieldid

declare @NewFieldid integers

declare @Row int = (select max(RowPosition) from @OrderedList OL inner join MetaSelectedField MSF on OL.id = MSF.MetaSelectedSectionId)

insert into MetaSelectedField
(DisplayName,MetaAvailableFieldId,MetaSelectedSectionId,IsRequired,MinCharacters,MaxCharacters,RowPosition,ColPosition,ColSpan,
DefaultDisplayType,MetaPresentationTypeId,Width,WidthUnit,Height,HeightUnit,AllowLabelWrap,LabelHAlign,LabelVAlign,LabelStyleId,
LabelVisible,FieldStyle,EditDisplayOnly,GroupName,GroupNameDisplay,FieldTypeId,ValidationRuleId,LiteralValue,ReadOnly,AllowCopy,
Precision,MetaForeignKeyLookupSourceId,MetadataAttributeMapId,EditMapId,NumericDataLength,Config)
output inserted.MetaSelectedFieldId into @NewFieldid
select
'Group Title',2095,OL.ID,0,NULL,NULL,@Row + 1,0,2,'Textarea',17,100,2,100,1,1,0,1,1,1,0,NULL,NULL,NULL,1,NULL,NULL,0,1,NULL,NULL,NULL,NULL,NULL,NULL
from @OrderedList OL

insert into MetaSelectedFieldAttribute
(Name,Value,MetaSelectedFieldId)
select 'listitemtype',2,id
from @NewFieldid

insert into MetaSelectedSectionAttribute 
(Name,Value,MetaSelectedSectionId)
select
'AllowConditions','TRUE',id
from @OrderedList
-- End Convert OrderedList



-- Deal With Condition
update CR
set SortOrder = CR2.rownum
from CourseRequisite CR
inner join (select ROW_NUMBER() over (Partition by courseid order by RT.SortOrder,CR2.SortOrder,CR2.id) as rownum,CR2.id from CourseRequisite CR2 inner join RequisiteType RT on CR2.RequisiteTypeid = RT.id) CR2 on CR.id = CR2.id
where 1 = 1

--select ROW_NUMBER() over (Partition by courseid order by SortOrder) as rownum,C.EntityTitle,CR.*
--from CourseRequisite CR
--left join Course C on CR.Requisite_CourseId = C.id
--where courseid = 6355 
--order by SortOrder

update CourseRequisite
set ConditionId = NULL
where ConditionId = 3

declare @CourseRequisiteTable table
(id int,Groupstart int)

insert into @CourseRequisiteTable 
(id,Groupstart)
select CR.id,1
from (select ROW_NUMBER() over (Partition by courseid order by SortOrder) as rownum,CourseId,id,ConditionId from CourseRequisite) CR
left join (select ROW_NUMBER() over (Partition by courseid order by SortOrder) + 1 as rownum,CourseId,id,ConditionId from CourseRequisite) CR2 on CR.rownum = CR2.rownum 
	and CR.CourseId = CR2.CourseId 
where CR.ConditionId = 2 and (CR2.ConditionId = 1 or CR2.ConditionId is null)


merge @CourseRequisiteTable CRT
USING ( 
	select id,0
	from CourseRequisite) AS CR (id,Groupstart)
on CRT.id = CR.id
WHEN NOT MATCHED THEN 
INSERT (id,Groupstart)
values (CR.id,CR.Groupstart);

--select CRT.Groupstart,*
--from @CourseRequisiteTable CRT
--inner join CourseRequisite CR on CR.Id = CRT.id
--where courseid = 6355
--order by SortOrder

update CR2
set CR2.SortOrder = CR2.SortOrder + Groupstart
from (select ROW_NUMBER() over (Partition by courseid order by SortOrder) as rownum,CourseId,id from CourseRequisite) CR
cross apply (
	select courseid,sum(CRT.Groupstart) as Groupstart,max(CR2.rownum) as NUMSUM from @CourseRequisiteTable CRT
	inner join (select ROW_NUMBER() over (order by SortOrder) as rownum,id from CourseRequisite where CR.CourseId = courseid) CR2 on CRT.id = CR2.Id and CR2.rownum <= CR.rownum
) A
inner join CourseRequisite CR2 on CR.id = CR2.id

declare @GroupListItemTypeId integer = (select id from ListItemType where ListItemTypeOrdinal = 2 and ListItemTableName = 'CourseRequisite')


--select CRT.Groupstart,Cr.*
--from @CourseRequisiteTable CRT
--right join CourseRequisite CR on CR.Id = CRT.id
--where courseid = 6384
--order by SortOrder

insert into CourseRequisite
(courseid,SortOrder,CreatedDate,ListItemTypeId,GroupConditionId,ConditionId)
select CR.CourseId,Cr.SortOrder - 1,GETDATE(),@GroupListItemTypeId,CR.ConditionId,CR2.ConditionId
from @CourseRequisiteTable CRT
inner join CourseRequisite CR on CRT.id = CR.id
outer apply (select case when CR3.id is null then CR.ConditionId else CR3.ConditionId end as ConditionId from (select MIN(SortOrder) as SortOrder from CourseRequisite CR2 where CR.CourseId = CR2.CourseId and CR.SortOrder < Cr2.SortOrder and (ConditionId <> CR.ConditionId or ConditionId is null) ) CR2
	left join CourseRequisite CR3 on CR2.SortOrder = CR3.SortOrder and CR.CourseId = CR3.CourseId
	) CR2
where CRT.Groupstart = 1

update CR
set Parent_Id = CR2.id,ConditionId = case when CR.SortOrder = CR5.SortOrder then CR.ConditionId else NULL end
from CourseRequisite CR
cross apply
(
	select MAX(Sortorder) as SortOrder
	from CourseRequisite CR2 
	where CR.Courseid = CR2.CourseId and CR2.ListItemTypeId = @GroupListItemTypeId and CR2.SortOrder < CR.SortOrder --Group
) A
inner join CourseRequisite CR2 on CR.Courseid = CR2.CourseId and CR2.ListItemTypeId = @GroupListItemTypeId and CR2.SortOrder = A.SortOrder
inner join (select ROW_NUMBER() over (Partition by courseid order by SortOrder) as rownum,id from CourseRequisite) CR3 on CR.id = CR3.id
left join (select ROW_NUMBER() over (Partition by courseid order by SortOrder) + 1 as rownum,CourseId,SortOrder,ConditionId,id from CourseRequisite) CR4 on CR.CourseId = CR4.CourseId and CR3.rownum = Cr4.rownum
cross Apply (select MAX(SORTORDER) as SortOrder from CourseRequisite CR5 where CR.CourseId = CR5.CourseId) CR5
where CR.ListItemTypeId <> @GroupListItemTypeId 
	and (CR.ConditionId = 2 or CR4.ConditionId = 2)

--select CRT.Groupstart,*
--from @CourseRequisiteTable CRT
--right join CourseRequisite CR on CR.Id = CRT.id
--where courseid = 6384
--order by SortOrder

delete @CourseRequisiteTable where 1 = 1

insert into @CourseRequisiteTable 
(id,Groupstart)
select CR.id,1
from (select ROW_NUMBER() over (Partition by courseid order by SortOrder) as rownum,CourseId,id,ConditionId from CourseRequisite where Parent_Id is null) CR
left join (select ROW_NUMBER() over (Partition by courseid order by SortOrder) + 1 as rownum,CourseId,id,ConditionId from CourseRequisite where Parent_Id is null) CR2 on CR.rownum = CR2.rownum 
	and CR.CourseId = CR2.CourseId 
where CR.ConditionId = 1 and CR2.ConditionId is null


merge @CourseRequisiteTable CRT
USING ( 
	select id,0
	from CourseRequisite where Parent_Id is null) AS CR (id,Groupstart)
on CRT.id = CR.id
WHEN NOT MATCHED THEN 
INSERT (id,Groupstart)
values (CR.id,CR.Groupstart);

--select CRT.Groupstart,*
--from @CourseRequisiteTable CRT
--right join CourseRequisite CR on CR.Id = CRT.id
--where courseid = 6384
--order by SortOrder

update CR2
set CR2.SortOrder = CR2.SortOrder + Groupstart
from (select ROW_NUMBER() over (Partition by courseid order by SortOrder) as rownum,CourseId,id from CourseRequisite) CR
cross apply (
	select courseid,sum(CRT.Groupstart) as Groupstart,max(CR2.rownum) as NUMSUM from @CourseRequisiteTable CRT
	inner join (select ROW_NUMBER() over (order by SortOrder) as rownum,id from CourseRequisite where CR.CourseId = courseid) CR2 on CRT.id = CR2.Id and CR2.rownum <= CR.rownum
) A
inner join CourseRequisite CR2 on CR.id = CR2.id

insert into CourseRequisite
(courseid,SortOrder,CreatedDate,ListItemTypeId,GroupConditionId)
select CR.CourseId,Cr.SortOrder - 1,GETDATE(),@GroupListItemTypeId,CR.ConditionId
from @CourseRequisiteTable CRT
inner join (select ROW_NUMBER() over (Partition by courseid order by SortOrder) as rownum,CourseId,SortOrder,ConditionId,id from CourseRequisite) CR on CRT.id = CR.id
where CRT.Groupstart = 1

update CR
set Parent_Id = CR2.id
from CourseRequisite CR
cross apply
(
	select MAX(Sortorder) as SortOrder
	from CourseRequisite CRT 
	where CR.Courseid = CRT.CourseId and CRT.ListItemTypeId = @GroupListItemTypeId and CRT.SortOrder < CR.SortOrder and CRT.GroupConditionId = 1 --AND Group
) A
inner join CourseRequisite CR2 on CR.Courseid = CR2.CourseId and CR2.ListItemTypeId = @GroupListItemTypeId and CR2.SortOrder = A.SortOrder
inner join (select ROW_NUMBER() over (Partition by courseid order by SortOrder) as rownum,id from CourseRequisite where Parent_Id is null) CR3 on CR.id = CR3.id
left join (select ROW_NUMBER() over (Partition by courseid order by SortOrder) + 1 as rownum,CourseId,SortOrder,ConditionId,id from CourseRequisite where Parent_Id is null) CR4 on CR.CourseId = CR4.CourseId and CR3.rownum = Cr4.rownum
where (CR.ConditionId = 1 or CR4.ConditionId = 1)

--select ROW_NUMBER() over (Partition by courseid order by SortOrder) as rownum,C.EntityTitle,CR.*
--from CourseRequisite CR
--left join Course C on CR.Requisite_CourseId = C.id
--where courseid = 6355 
--order by SortOrder

delete MSF
from @OrderedList OL
inner join MetaSelectedSection MSS on OL.id = MSS.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField MSF on MSS.MetaSelectedSectionId = MSF.MetaSelectedSectionId
where MSF.MetaAvailableFieldId = 290

update CR
set ConditionId = NULL
from CourseRequisite CR
cross Apply (select MAX(SORTORDER) as SortOrder from CourseRequisite CR2 where CR.CourseId = CR2.CourseId) CR2
where CR.SortOrder <> CR2.SortOrder
-- End Deal With Condition