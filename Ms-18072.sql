USE [nukz];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18072';
DECLARE @Comments nvarchar(Max) = 
	'Fix the SQL for Attachments in review';
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
UPDATE MetaSqlStatement
SET SqlStatement = '

--testing vars
 --declare @positionId int = null
 --declare @userId int = 32
 --declare @entityId int = 72
 --declare @entityType int = 2
 --declare @proposalId int = 8
--0 is not visible to the user
--1 is visible but not editable
--2 is editable
------------------------------------
declare @positions integers
drop table if exists #userIds
create table #userIds (entityId int, entityTypeId int, positionId int, userId int);
declare @entities integerpairs
declare @entityIsImplemented bit = (select IsImplemented from Proposal where id = @proposalId)
if (@entityType = 1)
BEGIN
    insert into @entities
    values
    (@entityId, 1)
    insert into @positions
    select distinct s.PositionId
    from course c
        inner join proposal p on p.id = c.ProposalId
        inner join ProcessVersion pv on pv.id = p.ProcessVersionId
        inner join StepLevel sl on sl.ProcessVersionId = pv.Id
        inner join Step s on s.StepLevelId = sl.Id
    where c.id = @entityId
    exec upGetUsersByEntityAndPosition @entities = @entities, @positionIds = @positions, @resultTable = #userIds

		INSERT INTO #userIds
		(entityId, entityTypeId, positionId, userId)
		SELECT c.Id, 1, 1, c.UserId FROM Proposal AS p
		INNER JOIN Course AS c on c.ProposalId = p.Id
		WHERE p.Id = @proposalId

end

if (@entityType = 2)
BEGIN
    insert into @entities
    values
    (@entityId, 2)
    insert into @positions
    select distinct s.PositionId
    from Program c
        inner join proposal p on p.id = c.ProposalId
        inner join ProcessVersion pv on pv.id = p.ProcessVersionId
        inner join StepLevel sl on sl.ProcessVersionId = pv.Id
        inner join Step s on s.StepLevelId = sl.Id
    where c.id = @entityId
    exec upGetUsersByEntityAndPosition @entities = @entities, @positionIds = @positions, @resultTable = #userIds

		INSERT INTO #userIds
		(entityId, entityTypeId, positionId, userId)
		SELECT c.Id, 1, 1, c.UserId FROM Proposal AS p
		INNER JOIN Program AS c on c.ProposalId = p.Id
		WHERE p.Id = @proposalId

end

if (@entityType = 6)
BEGIN
    insert into @entities
    values
    (@entityId, 6)
    insert into @positions
    select distinct s.PositionId
    from Module c
        inner join proposal p on p.id = c.ProposalId
        inner join ProcessVersion pv on pv.id = p.ProcessVersionId
        inner join StepLevel sl on sl.ProcessVersionId = pv.Id
        inner join Step s on s.StepLevelId = sl.Id
    where c.id = @entityId
    exec upGetUsersByEntityAndPosition @entities = @entities, @positionIds = @positions, @resultTable = #userIds

		INSERT INTO #userIds
		(entityId, entityTypeId, positionId, userId)
		SELECT c.Id, 1, 1, c.UserId FROM Proposal AS p
		INNER JOIN Module AS c on c.ProposalId = p.Id
		WHERE p.Id = @proposalId

end

--if user is admin, return 2
if exists(
    select top 1 1
    from UserRole
    where Active = 1
    and UserId = @userId
    and RoleId = 1
)
BEGIN
    select cast(2 as int)
end
else if (@entityIsImplemented = 1)
BEGIN
    select cast(1 as int)
END
else if exists (
    select top 1 1
    from #userIds
    where userId = @userId
)
BEGIN
    select cast(2 as int)
end
else
begin
    select cast(0 as int)
end
'
WHERE Id = 12