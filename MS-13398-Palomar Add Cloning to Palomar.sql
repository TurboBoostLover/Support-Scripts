USE [palomar];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13398';
DECLARE @Comments nvarchar(Max) = 
	'Adding Cloing to Programs for Palomar';
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
/*Config*/
update Config.ClientSetting
set AllowCloning = 1

/*create AS Degreee PT*/
declare @mtt int = (
    select MetaTemplateTypeId
    from MetaTemplateType
    where EntityTypeId = 2
    and Active = 1
    and TemplateName = 'New Program'
)

declare @client int = (
    select Id
    from Client
)

declare @ptTitle nvarchar(500) = 'AS Degree - 18 units or more'
declare @orgBinding integerPairs
declare @Process int = (
    select Id 
    from Process 
    where Title = 'New Program'
    and ProcessActionTypeId = 1
    and Active = 1 
)
declare @cet int = (
    select Id
    from ClientEntityType
    where EntityTypeId = 2
)
declare @roleIds integers

declare @EntityType int = 2

exec spProposalTypesInsert @client, @ptTitle, @EntityType,null,null,1,@mtt,@orgBinding,null,@process,@cet,@roleIds

declare @newASPT int = (select max(id) from ProposalType)

/*create CA cert PT*/
set @ptTitle= 'CA Certificates'

exec spProposalTypesInsert @client, @ptTitle, @EntityType,null,null,1,@mtt,@orgBinding,null,@process,@cet,@roleIds

declare @newCAPT int = (select max(id) from ProposalType)

/*set every PT to not clone but the two new ones*/
update ProposalType
set AllowCloning = 0
where id not in (@newASPT,@newCAPT)

update ProposalType
set AllowCloning = 1,
CloneRequired = 1
where id in (@newASPT,@newCAPT)

/*custom sql to go on the award type dropdown*/
declare @templateId integers

insert into @templateId
select mt.MetaTemplateId
from MetaTemplateType mtt
inner join MetaTemplate mt
	on mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
where mtt.EntityTypeId = 2
and mt.Active = 1
and mt.IsDraft = 0
and mt.EndDate is NULL
and mtt.active = 1
and mtt.IsPresentationView = 0

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);

insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('Units/Hours', 'Program', 'AwardTypeId','find')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on (maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName)
where mt.MetaTemplateId  in (select * from @templateId)

/*new custom sql*/
declare @customSQL varchar(max) = 'declare @PTTItle NVARCHAR(500) = (
    select pt.Title
    from Program p
        inner join ProposalType pt on pt.Id = p.ProposalTypeId
    where p.Id = @entityId
)

if (@PTTItle = ''AS Degree - 18 units or more'')
BEGIN
    select
        Id as Value
        ,Title as Text
    from AwardType
    where Active = 1
    and Title like ''%A.S.%''
    order by SortOrder

end
else if (@PTTItle = ''CA Certificates'')
BEGIN
    select
        Id as Value
        ,Title as Text
    from AwardType
    where Active = 1
    and Title like ''%Certificate of Achievement%''
    order by SortOrder
end
ELSE
begin
    select
        Id as Value
        ,Title as Text
    from AwardType
    where Active = 1
    order by SortOrder
end'

declare @resoSQL varchar(max) = 'select Title as Text from AwardType where Id = @id'

declare @maxId int = (select max(id) + 1 from MetaForeignKeyCriteriaClient)

insert into MetaForeignKeyCriteriaClient
(Id,TableName,DefaultValueColumn,DefaultDisplayColumn,CustomSql,ResolutionSql,DefaultSortColumn,LookupLoadTimingType,Title)
VALUES
(@maxId,'AwardType','Id','Title',@customSQL,@resoSQL,'Order by SortOrder',2,'awardtype override')

update MetaSelectedField
set MetaForeignKeyLookupSourceId = @maxId
where MetaSelectedFieldId in (select fieldid from @Fields where action = 'find')

update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select * from @templateId)

--commit
--rollback