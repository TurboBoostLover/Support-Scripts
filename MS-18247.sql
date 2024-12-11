USE [uaeu];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18247';
DECLARE @Comments nvarchar(Max) = 
	'Update the way attachments may work';
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
declare @currentSettings NVARCHAR(max) = (
    select replace(replace(JSON_Query(Configurations, '$[2].settings'), '[',''),']','')   
    from Config.ClientSetting
)
set @currentSettings = @currentSettings + ',{
    "AccessLevel": "curriqunet",
    "DataType": "int",
    "Description": "This sqlstatementid holds the logic for deciding who can view/edit workflow attachments.  If this has an id, then the clientsetting property EnableOpenAttachmentsWorkflow is considered to be enabled.",
    "Default": false,
    "Label": "Workflow Attachment MetaSqlStatmentId",
    "Name": "OpenAttachmentsWorkflowSqlId",
    "Value": 1,
    "Active": true
}'
set @currentSettings = CONCAT('[',@currentSettings,']')
update Config.ClientSetting
set Configurations = JSON_MODIFY(Configurations, '$[2].settings',JSON_QUERY(@currentSettings))

INSERT INTO MetaSqlStatement
(SqlStatement, SqlStatementTypeId)
VALUES
('
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
DECLARE @Users TABLE (UserID int)

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

		INSERT INTO @Users
		SELECT psah.UserId FROM Course AS c
		INNER JOIN Proposal AS p on c.ProposalId = p.Id
		INNER JOIN ProcessLevelActionHistory AS plah on plah.ProposalId = p.Id
		INNER JOIN ProcessStepActionHistory AS psah on psah.ProcessLevelActionHistoryId = plah.Id
		WHERE p.Id = @proposalId
		and StepActionResultTypeId = 1

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


		INSERT INTO @Users
		SELECT psah.UserId FROM Program AS pp
		INNER JOIN Proposal AS p on pp.ProposalId = p.Id
		INNER JOIN ProcessLevelActionHistory AS plah on plah.ProposalId = p.Id
		INNER JOIN ProcessStepActionHistory AS psah on psah.ProcessLevelActionHistoryId = plah.Id
		WHERE p.Id = @proposalId
		and StepActionResultTypeId = 1

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

		INSERT INTO @Users
		SELECT psah.UserId FROM Module AS m
		INNER JOIN Proposal AS p on m.ProposalId = p.Id
		INNER JOIN ProcessLevelActionHistory AS plah on plah.ProposalId = p.Id
		INNER JOIN ProcessStepActionHistory AS psah on psah.ProcessLevelActionHistoryId = plah.Id
		WHERE p.Id = @proposalId
		and StepActionResultTypeId = 1

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
    from @Users
    where userId = @userId
)
BEGIN
    select cast(2 as int)
end

else if exists (
    select top 1 1
    from #userIds
    where userId = @userId
)
BEGIN
    select cast(1 as int)
end
else
begin
    select cast(0 as int)
end
', 3)

DECLARE @Id int = SCOPE_IDENTITY()

exec upGetUpdateClientSetting @setting = 'OpenAttachmentsWorkflowSqlId', @newValue = @ID, @clientId = 11, @valuedatatype = 'int', @section = 'Curriqunet'