USE [palomar];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15146';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin report sql';
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
UPDATE AdminReport
SET ReportSQL = '
declare @status int = (select StatusBaseId from Module m join StatusAlias sa on sa.Id = m.StatusAliasId where m.Id = @catalogid);

declare @urls table (URL nvarchar(max), SectionId int);
declare @temp table ([Page Title] nvarchar(max), [Parent Menu] nvarchar(max), URL nvarchar(max), [Position] nvarchar(max),[Draft Edit] nvarchar(max),[Review Edit] nvarchar(max),[Workflow Level] nvarchar(max),[User] nvarchar(max),[User Email Address] nvarchar(max));

;with rcte as (
	select cs.Id as RootId,cs.Id, cs.ParentId, cs.CatalogSectionTypeId, cs.[Title], cs.UrlAlias
	from CatalogSection cs
	union all
	select r.RootId, cs.Id, cs.ParentId, cs.CatalogSectionTypeId , cs.[Title],cs.UrlAlias
	from rcte r 
	join CatalogSection cs on cs.Id = r.ParentId
	where r.ParentId is not null
)
insert into @urls (URL,SectionId)
select case 
	when @status = 1 then concat(''palomar.curriqunet.com/catalog/iq/'',dbo.ConcatWithSepOrdered_Agg(''/'',r.Id,isnull(r.UrlAlias,r.Id))) 
	when @status = 5 then concat(''palomar.curriqunet.com/catalog/archive/'' + cast(@catalogid as nvarchar) + ''/iq/'',dbo.ConcatWithSepOrdered_Agg(''/'',r.Id,isnull(r.UrlAlias,r.Id)))
	else null end
, RootId
from rcte r 
group by RootId


;with sectionParent as 
(
	select Id as SectionId, ParentId, Title as ParentTitle, 0 as IsTop 
	from CatalogSection
	UNION ALL
	select SectionId, cs.ParentId, cs2.Title as ParentTitle, case when cs2.ParentId is null then 1 else 0 end as IsTop 
	from sectionParent sp
	join CatalogSection cs on cs.Id = sp.ParentId
	join CatalogSection cs2 on cs2.Id = cs.ParentId
	where cs.ParentId is not null
),
ReportData as
(
	select case when sa1.Title is not null then 1 else 0 end as EditInReview, 
		case when sa2.Title is not null then 1 else 0 end as EditInDraft, 
		cs.Title as SectionTitle, sp.ParentTitle as TabTitle, u.FirstName, u.LastName, u.Email, p.Title as Position, p.Id as PositionId,
		cs.Id as SectionId
	from CatalogSection cs 
	inner join sectionParent sp on sp.SectionId = cs.Id and IsTop = 1
	left join CatalogSectionPositionAssignment pa 
		left join CatalogSectionPositionAssignmentStatusAlias pas
			left join StatusAlias sa1 on sa1.Id = pas.StatusAliasId and sa1.Title = ''In Review''
			left join StatusAlias sa2 on sa2.Id = pas.StatusAliasId and sa2.Title = ''Draft''
				on pas.CatalogSectionPositionAssignmentId = pa.Id
		inner join [Position] p on p.Id = pa.PositionId and p.Active = 1
		inner join UserPosition up on up.PositionId = p.Id and up.Active = 1
		inner join [user] u on u.Id = up.UserId and u.Active = 1
		on cs.Id = pa.CatalogSectionId
	where ModuleId = @catalogId
	and cs.CatalogSectionTypeId in (1,2,3,5,6)
	and cs.CatalogBlockPanelTypeId in (2)
	--and URLAlias not in (''Courses'',''Requirements'',''Summary'')
),
WorkflowLevel as
(
	select s.PositionId, Min(sl.SortOrder) as WorkflowLevel
	from StepLevel sl 
	join Step s on s.StepLevelId = sl.Id
	join Process p on p.ProcessVersionId_Active = sl.ProcessVersionId 
	join [Module] m on m.ProcessId = p.Id and m.Id = @catalogId
	group by PositionId
)
insert into @temp
select 
		SectionTitle as [Page Title],
		TabTitle as [Parent Menu],
		URL,
		[Position],
		case when max(EditInDraft) = 1 then ''Yes'' else ''No'' end as [Draft Edit],
		case when max(EditInReview) = 1 then ''Yes'' else ''No'' end as [Review Edit],
		case when wl.WorkflowLevel is null then ''Not Assigned'' else cast(WorkflowLevel as nvarchar) end as [Workflow Level],
		case when LastName is null then ''Not Assigned'' else concat(FirstName, '' '', LastName) end as [User],
		Email as [User Email Address]
from ReportData rd
left join @urls u on u.SectionId = rd.SectionId
left join WorkflowLevel wl on wl.PositionId = rd.PositionId
where rd.SectionTitle is not null or rd.LastName is not null
group by SectionTitle,TabTitle,FirstName,LastName,Email,[Position], URL, WorkflowLevel
order by SectionTitle, TabTitle, LastName, FirstName, Position

if(@status = 1 OR @status = 5)
	select * from @temp
else
	select [Page Title],[Parent Menu],[Position],[Draft Edit],[Review Edit],[Workflow Level],[User],[User Email Address] from @temp
'
WHERE Id = 1006