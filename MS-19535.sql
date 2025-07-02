USE [nukz];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19535';
DECLARE @Comments nvarchar(Max) = 
	'Enable Cloning';
DECLARE @Developer nvarchar(50) = 'Nathan Westergard';
DECLARE @ReqTicket nvarchar(20) = 'MS-'
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

IF NOT EXISTS(select top 1 Id from History.ScriptsRunOnDatabase where TicketNumber = @ReqTicket) AND LEN(@ReqTicket) > 5
    RAISERROR('This script has a dependency on ticket %s which needs to be run first.', 16, 1, @ReqTicket);

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
exec upGetUpdateClientSetting @setting = 'AllowCloning', @newValue = 1, @clientId = 1, @valuedatatype = 'bit', @section = 'Curriqunet'

INSERT INTO ProposalType
(ClientId, Title, EntityTypeId, ProcessActionTypeId, MetaTemplateTypeId, Active, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, CloneRequired, AllowDistrictClone, AllowCloning, HideProposalRequirementFields, AllowNonAdminReactivation)
VALUES
(1, 'Clone New Course', 1, 1, 1, 1, 0, 0, 0, 0, 0, 1, 1, 0, 1, 0, 0)

DECLARE @Proposal int = SCOPE_IDENTITY()

INSERT INTO ProcessProposalType
(ProposalTypeId, ProcessId)
VALUES
(@Proposal, 17)

INSERT INTO ProposalTypeCloneSource
(SourceProposalTypeId, ProposalTypeId)
SELECT Id, @Proposal FROM ProposalType WHERE Active = 1 and EntityTypeId = 1 and ProcessActionTypeId <> 3

INSERT INTO ProposalTypeCloneSourceStatusAlias
(ProposalTypeCloneSourceId, StatusAliasId)
SELECT Id, 1 FROM ProposalTypeCloneSource

DECLARE @FieldsToBlackList TABLE (FieldId int, Id int Identity)
INSERT INTO @FieldsToBlackList
SELECT MetaSelectedFieldId
FROM MetaSelectedField
WHERE MetaAvailableFieldId in (
	871,
	1776,
	292,
	285,
	298,
	1601,
	301,
	13554,
	13502,
	13501,
	7390,
	180,
	189,
	185,
	2625,
	2624,
	1431,
	2623,
	586,
	1392,
	895,
	873,
	888,
	872,
	2956,
	2958,
	7378,
	3447,
	2459
)

DECLARE @SectionsToBlacklist TABLE (SecId int, Id int Identity)
INSERT INTO @SectionsToBlacklist
SELECT MetaSelectedSectionId
FROM MetaSelectedSection
WHERE MetaBaseSchemaId in (
	1203,
	81,
	94,
	8501,
	8512,
	109
)

DECLARE @Counting TABLE (Id int, FieldId int, Counting int Identity)
INSERT INTO @Counting
SELECT Id, FieldId FROM @FieldsToBlackList
--UNION
--SELECT Id FROM @SectionsToBlacklist

while exists(select top 1 Id from @Counting)
begin
    declare @TID int = (select top 1 Id from @Counting)
		declare @Field int = (SELECT FieldId FROM @Counting WHERE Id = @TID)
    
		INSERT INTO MetadataAttributeMap
		DEFAULT VALUES

		DECLARE @Id int = SCOPE_IDENTITY()

		INSERT INTO MetadataAttribute
		(Description, ValueText, MetadataAttributeTypeId, MetadataAttributeMapId, DataType)
		VALUES
		('Clone Blacklist', 'BlacklistDoNotClone', 20, @Id, 'Text')

		UPDATE MetaSelectedField
		SET MetadataAttributeMapId = @Id
		WHERE MetaSelectedFieldId = @Field

    delete @Counting
    where id = @TID
end


INSERT INTO @Counting
SELECT Id, SecId FROM @SectionsToBlacklist

while exists(select top 1 Id from @Counting)
begin
    declare @TID2 int = (select top 1 Id from @Counting)
		declare @Section int = (SELECT FieldId FROM @Counting WHERE Id = @TID2)
    
		INSERT INTO MetadataAttributeMap
		DEFAULT VALUES

		DECLARE @Id2 int = SCOPE_IDENTITY()

		INSERT INTO MetadataAttribute
		(Description, ValueText, MetadataAttributeTypeId, MetadataAttributeMapId, DataType)
		VALUES
		('Clone Blacklist', 'BlacklistDoNotClone', 20, @Id2, 'Text')

		UPDATE MetaSelectedSection
		SET MetadataAttributeMapId = @Id2
		WHERE MetaSelectedSectionId = @Section

    delete @Counting
    where id = @TID2
end