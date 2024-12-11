use [sdccd]

/*
   Commit
                Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15378';
DECLARE @Comments nvarchar(Max) = 'Set up Limited Live Edit';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ScriptTypeId bit = 1; /*  Default 1 is Support,  
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
Please do not alter the script above this comment except to set
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
declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0
    AND mtt.ClientId = 1

declare @positionId TABLE (id int, nme nvarchar(max))
INSERT INTO @positionId
SELECT Id, Title FROM Position WHERE Id in (
20, 31, 32, 33, 37, 38, 39
)
 
insert into EditMap DEFAULT values 

declare @mapid int = SCOPE_IDENTITY();

insert into EditMapStatus (EditMapId,PositionId,StatusAliasId)
select @mapid, p.ID, 7 from @positionId AS p 

insert into EditMapStatus (EditMapId,RoleId,StatusAliasId)
select @mapid, 1, sa.Id
from StatusAlias sa
where sa.Active = 1 
union 
select @mapid, 3, sa.Id
from StatusAlias sa
where sa.Active = 1

declare @MetaSelectedSectionIds table (Id int);

insert into @MetaSelectedSectionIds (Id)
select MetaSelectedSectionId from MetaSelectedSection 
where SectionName in ('Tech Review and Dean View') 
and ClientId = 1 
and MetaSelectedSection_MetaSelectedSectionId is null 
and MetaTemplateId in (SELECT * FROM @templateId)

insert into @MetaSelectedSectionIds (Id)
select MetaSelectedSectionId from MetaSelectedSection 
inner join @MetaSelectedSectionIds on Id = MetaSelectedSection_MetaSelectedSectionId

update MetaSelectedSection 
set EditMapId = @mapid 
where MetaSelectedSectionId IN (select Id from @MetaSelectedSectionIds)


update MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (SELECT * FROM @templateId)

--COMMIT