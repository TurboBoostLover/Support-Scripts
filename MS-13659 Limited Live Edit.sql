use [peralta]

/*
   Commit
                Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13659';
DECLARE @Comments nvarchar(Max) = 'Set up Limited Live Edit for BCC - Articulation Officer';
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
	AND mtt.MetaTemplateTypeId <> 7

declare @positionId int = (select Id from Position where Title = 'BCC - Articulation Officer');
 
--set up the edit map that will be applied to all Sub-Sections of the the tabs.  These tabs should be editable by BCC - Articulation Officer position, Admin role and LiveEdit role.
insert into EditMap DEFAULT values 

declare @mapid int = SCOPE_IDENTITY();

insert into EditMapStatus (EditMapId,PositionId,StatusAliasId)
select @mapid, @positionId, s.Id from StatusAlias s where Active = 1 

insert into EditMapStatus (EditMapId,RoleId,StatusAliasId)
select @mapid, 1, sa.Id
from StatusAlias sa
where sa.Active = 1 
union 
select @mapid, 3, sa.Id
from StatusAlias sa
where sa.Active = 1

--This seems like the easiest way to set the Limited Live Edit on Sections and all sub-sections.
declare @MetaSelectedSectionIds table (Id int);

insert into @MetaSelectedSectionIds (Id)
select MetaSelectedSectionId from MetaSelectedSection 
where SectionName in ('Cover','General Education','Codes/Dates') 
and ClientId = 1 
and MetaSelectedSection_MetaSelectedSectionId is null 
and MetaTemplateId in (SELECT * FROM @templateId)

insert into @MetaSelectedSectionIds (Id)
select MetaSelectedSectionId from MetaSelectedSection 
inner join @MetaSelectedSectionIds on Id = MetaSelectedSection_MetaSelectedSectionId

update MetaSelectedSection 
set EditMapId = @mapid 
where MetaSelectedSectionId IN (select Id from @MetaSelectedSectionIds)

--currently the Codes/Dates tab is only visible to admins, so I needed to make it editable for the position as well.
insert into MetaSelectedSectionPositionPermission (PositionId,MetaSelectedSectionId,AccessRestrictionType)
select @positionId,MetaSelectedSectionId,2 
from MetaSelectedSection 
where SectionName = 'Codes/Dates' 
and ClientId = 1 
and MetaSelectedSection_MetaSelectedSectionId is null
and MetaTemplateId in (SELECT * FROM @templateId)

--re-cache all program templates.
update MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (SELECT * FROM @templateId)

--Edit User Roles
DECLARE @UserId int = (
SELECT UserId 
FROM UserPosition 
WHERE PositionId = 8 --Bcc Articulation Officer
AND Active = 1
)

--Just make them a user with limited live edit
Delete FROM UserRole
WHERE UserId = @UserId
AND RoleId <> 4
AND ClientId = 2