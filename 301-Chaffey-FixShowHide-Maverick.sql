USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-16692';
DECLARE @Comments nvarchar(Max) = 
	'Fix Show hide issues';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId int = 2; /*  Default 1 is Support,  
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

DECLARE @SECTIONS INTEGERS
INSERT INTO @SECTIONS
SELECT MetaSelectedSectionId
FROM MetaDisplaySubscriber
WHERE MetaSelectedSectionId IS NOT NULL
GROUP BY MetaSelectedSectionId
HAVING COUNT(*) > 1;

DECLARE @TABS INTEGERS
INSERT INTO @TABS
SELECT mss2.MetaSelectedSectionId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedSection As mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
WHERE mss.MetaSelectedSectionId in (
	SELECT Id FROM @SECTIONS
)

declare @Tabid integers
insert into @Tabid
SELECT Id FROM @TABS

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



-- Fix Showhide
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
where EPB.id is null 
	and EPB2.id is null
	and A.ExpressionId is null

delete MDS
from MetaDisplaySubscriber MDS
	inner join MetaDisplaySubscriber MDS2 on MDS.MetaDisplayRuleId = MDS2.MetaDisplayRuleId
		and MDS.MetaSelectedSectionId = MDS2.MetaSelectedSectionId
		and MDS.Id <> MDS2.Id

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
	or (MSS.MetaSectionTypeId = 32 and C.C > 0)  -- AS of the writing of this script subscriptions does not work directly on checklists in new forms  If this changes the one below should also be removed

declare @newsection3 integers

while exists(select*from @SectionFixShowhide)
begin

	insert MetaSelectedSection
	(ClientId,MetaSelectedSection_MetaSelectedSectionId,SectionName,DisplaySectionName,SectionDescription,DisplaySectionDescription,
	ColumnPosition,RowPosition,SortOrder,SectionDisplayId,MetaSectionTypeId,MetaTemplateId,DisplayFieldId,HeaderFieldId,FooterFieldId,
	OriginatorOnly,MetaBaseSchemaId,MetadataAttributeMapId,EntityListLibraryTypeId,EditMapId,AllowCopy,ReadOnly,Config)
	output inserted.MetaSelectedSectionid into @newsection3
	select
	MSS.ClientId,MSS.MetaSelectedSection_MetaSelectedSectionId,null,0,NULL,0,NULL,MSS.RowPosition,MSS.RowPosition,1,1,MSS.MetaTemplateId,NULL,NULL,NULL,0,MSS2.MetaBaseSchemaId,NULL,NULL,NULL,1,0,NULL
	from MetaSelectedSection MSS
		inner join @SectionFixShowhide S on MSS.MetaSelectedSectionId = S.Id
		inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSectionId
	
	update MSS
	set MetaSelectedSection_MetaSelectedSectionId = NS.Id,RowPosition = 0,SortOrder = 0
	from MetaSelectedSection MSS
		inner join @SectionFixShowhide S on MSS.MetaSelectedSectionId = S.Id
		inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
			and MSS.RowPosition = MSS2.RowPosition
		inner join @newsection3 NS on MSS2.MetaSelectedSectionId = NS.Id
	
	update MDS
	set MetaSelectedSectionId = MSS.MetaSelectedSection_MetaSelectedSectionId
	from MetaSelectedSection MSS
		inner join @SectionFixShowhide S on MSS.MetaSelectedSectionId = S.Id
		cross apply (
			select min(MetaDisplayRuleId) as id
			from MetaDisplaySubscriber 
			where MetaSelectedSectionId = MSS.MetaSelectedSectionId
		) A
		inner join MetaDisplaySubscriber MDS on MSS.MetaSelectedSectionId = MDS.MetaSelectedSectionId
			and A.id = MDS.MetaDisplayRuleId

	insert into @TabSections
	select*from @newsection3

	delete @SectionFixShowhide 
	where 1 = 1

	delete @newsection3
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
		or (MSS.MetaSectionTypeId = 32 and C.C > 0)

end


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


-- merge sections that are next to each other with the same MetaDisplayRuleId
declare @Mergesections integers

insert into @Mergesections
select
S.Id
from @TabSections S
	inner join MetaSelectedSection MSS on S.Id = MSS.MetaSelectedSectionId
	inner join MetaDisplaySubscriber MDS on MSS.MetaSelectedSectionId = MDS.MetaSelectedSectionId
	outer apply(
		select MSS2.MetaSelectedSectionId as id
		from MetaSelectedSection MSS2
			inner join MetaDisplaySubscriber MDS2 on MSS2.MetaSelectedSectionId = MDS2.MetaSelectedSectionId
				and MDS.MetaDisplayRuleId = MDS2.MetaDisplayRuleId
		where MSS2.RowPosition + 1 = MSS.RowPosition
			and MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
	) A
	cross apply(
		select MSS3.MetaSelectedSectionId as id
		from MetaSelectedSection MSS3
			inner join MetaDisplaySubscriber MDS3 on MSS3.MetaSelectedSectionId = MDS3.MetaSelectedSectionId
				and MDS.MetaDisplayRuleId = MDS3.MetaDisplayRuleId
		left join MetaSelectedField MSF on MSS3.MetaSelectedSectionId = MSF.MetaSelectedSectionId
		where MSS3.RowPosition - 1 = MSS.RowPosition
			and MSS.MetaSelectedSection_MetaSelectedSectionId = MSS3.MetaSelectedSection_MetaSelectedSectionId
			and MSS3.MetaSectionTypeId = MSS.MetaSectionTypeId
			and MSS3.MetaSectionTypeId = 1
			and MSF.MetaSelectedFieldId is null
			and MSS3.SectionName is null
			and MSS3.SectionDescription is null
	) B
where A.id is null
	and MSS.SectionName is null
	and MSS.SectionDescription is null

while exists(select*from @Mergesections)
begin

	update MSS3
	set MetaSelectedSection_MetaSelectedSectionId = MS.Id,RowPosition = coalesce(A.RowPosition,- MSS3.RowPosition - 1) + MSS3.RowPosition + 1,SortOrder = coalesce(A.RowPosition,- MSS3.RowPosition - 1) + MSS3.RowPosition + 1
	from @Mergesections MS
		inner join MetaSelectedSection MSS on MS.id = MSS.MetaSelectedSectionId
		cross apply (
			select max(RowPosition) as RowPosition
			from MetaSelectedSection MSS4 
			where MSS4.MetaSelectedSection_MetaSelectedSectionId = MSS.MetaSelectedSectionId
		) A
		inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
			and MSS.RowPosition + 1 = MSS2.RowPosition
		inner join MetaSelectedSection MSS3 on MSS2.MetaSelectedSectionId = MSS3.MetaSelectedSection_MetaSelectedSectionId

	delete MDS
	from @Mergesections MS
		inner join MetaSelectedSection MSS on MS.id = MSS.MetaSelectedSectionId
		inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
			and MSS.RowPosition + 1 = MSS2.RowPosition
		inner join MetaDisplaySubscriber MDS on MSS2.MetaSelectedSectionId = MDS.MetaSelectedSectionId

	delete MSS2
	from @Mergesections MS
		inner join MetaSelectedSection MSS on MS.id = MSS.MetaSelectedSectionId
		inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
			and MSS.RowPosition + 1 = MSS2.RowPosition

	update MSS2
	set RowPosition = MSS2.RowPosition - 1, SortOrder = MSS2.RowPosition - 1
	from @Mergesections MS
		inner join MetaSelectedSection MSS on MS.id = MSS.MetaSelectedSectionId
		inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
			and MSS.RowPosition < MSS2.RowPosition

	delete @Mergesections where 1 = 1

	insert into @Mergesections
	select
	S.Id
	from @TabSections S
		inner join MetaSelectedSection MSS on S.Id = MSS.MetaSelectedSectionId
		inner join MetaDisplaySubscriber MDS on MSS.MetaSelectedSectionId = MDS.MetaSelectedSectionId
		outer apply(
			select MSS2.MetaSelectedSectionId as id
			from MetaSelectedSection MSS2
				inner join MetaDisplaySubscriber MDS2 on MSS2.MetaSelectedSectionId = MDS2.MetaSelectedSectionId
					and MDS.MetaDisplayRuleId = MDS2.MetaDisplayRuleId
			where MSS2.RowPosition + 1 = MSS.RowPosition
				and MSS.MetaSelectedSection_MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
		) A
		cross apply(
			select MSS3.MetaSelectedSectionId as id
			from MetaSelectedSection MSS3
				inner join MetaDisplaySubscriber MDS3 on MSS3.MetaSelectedSectionId = MDS3.MetaSelectedSectionId
					and MDS.MetaDisplayRuleId = MDS3.MetaDisplayRuleId
			left join MetaSelectedField MSF on MSS3.MetaSelectedSectionId = MSF.MetaSelectedSectionId
			where MSS3.RowPosition - 1 = MSS.RowPosition
				and MSS.MetaSelectedSection_MetaSelectedSectionId = MSS3.MetaSelectedSection_MetaSelectedSectionId
				and MSS3.MetaSectionTypeId = MSS.MetaSectionTypeId
				and MSS3.MetaSectionTypeId = 1
				and MSF.MetaSelectedFieldId is null
				and MSS3.SectionName is null
				and MSS3.SectionDescription is null
		) B
	where A.id is null
		and MSS.SectionName is null
		and MSS.SectionDescription is null
		
end

-- fix field showhide
declare @FieldFixShowhide integers

delete @FieldFixShowhide where 1 = 1

insert into @FieldFixShowhide
select MSF.MetaSelectedFieldId
from MetaSelectedField MSF
	inner join @TabSections TS on TS.id = MSF.MetaSelectedSectionId
	cross apply (
		select count(MDS.id) as C 
		from MetaDisplaySubscriber MDS
		where MDS.MetaSelectedFieldId = MSF.MetaSelectedFieldId
	) C
	cross apply (
		select min(RowPosition) as RowP
		from MetaSelectedField MSF2 
			inner join MetaDisplaySubscriber MDS2 on MDS2.MetaSelectedFieldId = MSF2.MetaSelectedFieldId
		where MSF.MetaSelectedSectionId = MSF2.MetaSelectedSectionId
	) B
where B.RowP = MSF.RowPosition

while exists(select*from @FieldFixShowhide)
begin
	
	insert MetaSelectedSection
	(ClientId,MetaSelectedSection_MetaSelectedSectionId,SectionName,DisplaySectionName,SectionDescription,DisplaySectionDescription,
	ColumnPosition,RowPosition,SortOrder,SectionDisplayId,MetaSectionTypeId,MetaTemplateId,DisplayFieldId,HeaderFieldId,FooterFieldId,
	OriginatorOnly,MetaBaseSchemaId,MetadataAttributeMapId,EntityListLibraryTypeId,EditMapId,AllowCopy,ReadOnly,Config)
	output inserted.MetaSelectedSectionid into @newsection3
	select
	MSS.ClientId,MSS.MetaSelectedSectionId,null,0,NULL,0,NULL,0,0,1,1,MSS.MetaTemplateId,NULL,NULL,NULL,0,MSS.MetaBaseSchemaId,NULL,NULL,NULL,1,0,NULL
	from MetaSelectedSection MSS
		inner join MetaSelectedField MSF on MSS.MetaSelectedSectionId = MSF.MetaSelectedSectionId
		inner join @FieldFixShowhide F on MSF.MetaSelectedFieldId = F.Id
	
	declare @newsection34 integers
	
	insert MetaSelectedSection
	(ClientId,MetaSelectedSection_MetaSelectedSectionId,SectionName,DisplaySectionName,SectionDescription,DisplaySectionDescription,
	ColumnPosition,RowPosition,SortOrder,SectionDisplayId,MetaSectionTypeId,MetaTemplateId,DisplayFieldId,HeaderFieldId,FooterFieldId,
	OriginatorOnly,MetaBaseSchemaId,MetadataAttributeMapId,EntityListLibraryTypeId,EditMapId,AllowCopy,ReadOnly,Config)
	output inserted.MetaSelectedSectionid into @newsection3
	select
	MSS.ClientId,MSS.MetaSelectedSectionId,null,0,NULL,0,NULL,1,1,1,1,MSS.MetaTemplateId,NULL,NULL,NULL,0,MSS.MetaBaseSchemaId,NULL,NULL,NULL,1,0,NULL
	from MetaSelectedSection MSS
		inner join MetaSelectedField MSF on MSS.MetaSelectedSectionId = MSF.MetaSelectedSectionId
		inner join @FieldFixShowhide F on MSF.MetaSelectedFieldId = F.Id
		cross apply (
		select count(MSF2.MetaSelectedFieldId) as C 
		from MetaSelectedField MSF2
		where MSF.MetaSelectedSectionId = MSF2.MetaSelectedSectionId
			and MSF.RowPosition < MSF2.RowPosition
		) F2
	where F2.C > 1
	
	update MSF
	set MetaSelectedSectionId = NS.Id,RowPosition = MSF2.RowPosition - MSF.RowPosition - 1
	from MetaSelectedField MSF 
		inner join @FieldFixShowhide F on MSF.MetaSelectedFieldId = F.Id
		inner join MetaSelectedSection MSS on MSS.MetaSelectedSectionId = MSF.MetaSelectedSectionId
		inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
		inner join @newsection34 NS on MSS2.MetaSelectedSectionId = NS.Id
		inner join MetaSelectedField MSF2 on MSF.MetaSelectedSectionId = MSF2.MetaSelectedSectionId
			and MSF.RowPosition < MSF2.RowPosition
	
	update MSF
	set MetaSelectedSectionId = NS.Id,RowPosition = 0
	from MetaSelectedField MSF 
		inner join @FieldFixShowhide F on MSF.MetaSelectedFieldId = F.Id
		inner join MetaSelectedSection MSS on MSS.MetaSelectedSectionId = MSF.MetaSelectedSectionId
		inner join MetaSelectedSection MSS2 on MSS.MetaSelectedSectionId = MSS2.MetaSelectedSection_MetaSelectedSectionId
		inner join @newsection3 NS on MSS2.MetaSelectedSectionId = NS.Id

	update MDS
	set MetaSelectedFieldId = null, MetaSelectedSectionId = MSF.MetaSelectedSectionId
	from MetaDisplaySubscriber MDS
		inner join @FieldFixShowhide F on MDS.MetaSelectedFieldId = F.id
		inner join MetaSelectedField MSF on F.id = MSF.MetaSelectedFieldId
		

	insert into @TabSections
	select*from @newsection3

	delete @FieldFixShowhide where 1 = 1

	delete @newsection3 where 1 = 1

	insert into @FieldFixShowhide
	select MSF.MetaSelectedFieldId
	from MetaSelectedField MSF
		inner join @TabSections TS on TS.id = MSF.MetaSelectedSectionId
		cross apply (
			select count(MDS.id) as C 
			from MetaDisplaySubscriber MDS
			where MDS.MetaSelectedFieldId = MSF.MetaSelectedFieldId
		) C
		cross apply (
			select min(RowPosition) as RowP
			from MetaSelectedField MSF2 
				inner join MetaDisplaySubscriber MDS2 on MDS2.MetaSelectedFieldId = MSF2.MetaSelectedFieldId
			where MSF.MetaSelectedSectionId = MSF2.MetaSelectedSectionId
		) B
	where B.RowP = MSF.RowPosition

end

-- Fixing Null targeting Expresion part
update EP
set ExpressionOperatorTypeId = case 
	when ExpressionOperatorTypeId = 3 then 17 
	when ExpressionOperatorTypeId = 16 then 15 
	else ExpressionOperatorTypeId 
end
from ExpressionPart EP
	inner join MetaSelectedField MSF on Ep.Operand1_MetaSelectedFieldId = MSF.MetaSelectedFieldId
	inner join @TabSections TS on MSF.MetaSelectedSectionId = TS.Id
where ComparisonDataTypeId = 3
	and Operand2Literal = -1
-- End fix showhide
COMMIT