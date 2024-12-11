USE [nu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17081';
DECLARE @Comments nvarchar(Max) = 
	'Limited Live edit';
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
declare @templateId integers
INSERT INTO @templateId
	select mt.MetaTemplateId
	from MetaTemplate mt
		inner join MetaTemplateType mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	where mtt.Active = 1
	and mtt.IsPresentationView = 0
	and mtt.EntityTypeId = 2--1 = Course, 2 = Program, 6 = Module
	and mt.Active = 1
	and mt.EndDate is null
	and mt.IsDraft = 0;


declare @positionId TABLE (id int, nme nvarchar(max))
INSERT INTO @positionId
SELECT Id, Title FROM Position WHERE Id in (
841, 829
)

insert into EditMap DEFAULT values 
declare @mapid int = SCOPE_IDENTITY();

insert into EditMapStatus (EditMapId,PositionId,StatusAliasId)
select @mapid, p.ID, 633 from @positionId AS p 
UNION
select @mapid, p.ID, 629 from @positionId AS p
UNION
select @mapid, p.ID, 628 from @positionId AS p 
UNION
select @mapid, p.ID, 632 from @positionId AS p 

insert into EditMapStatus (EditMapId,RoleId,StatusAliasId)
select @mapid, 1, sa.Id
from StatusAlias sa
where sa.Active = 1 
union 
select @mapid, 3, sa.Id
from StatusAlias sa
where sa.Active = 1
union 
select @mapid,4, sa.Id
from StatusAlias sa
where sa.Active = 1
and id in (631)

declare @Msf table (Id int);
INSERT INTO @Msf
SELECT MetaSelectedFieldID FROM MetaSelectedField WHERE MetaAvailableFieldId = 867

update MetaSelectedField 
set EditMapId = @mapid 
where MetaSelectedFieldId IN (select Id from @Msf)

update MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (SELECT * FROM @templateId)