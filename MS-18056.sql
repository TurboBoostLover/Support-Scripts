USE [victorvalley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18056';
DECLARE @Comments nvarchar(Max) = 
	'Update Querys to run faster';
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
DECLARE @ClientId int = 1

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @Subject int = (SELECT SubjectId FROM ProgramCourse WHERE Id = @PkIdValue)

select c.Id as Value,
				coalesce(c.EntityTitle, s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title, s.SubjectCode + '' '' + c.CourseNumber, c.Title) + 
				case
					when sa.StatusBaseId != 1 then '' ('' + sa.Title + '')'' 
					when sa.StatusBaseID = 1 then ''''
				end as Text,
				s.Id as FilterValue,
				cd.Variable as IsVariable,
				cd.MinCreditHour as Min,
				cd.MaxCreditHour as Max
		from Course c
			inner join CourseDescription cd on c.Id = cd.CourseId
			inner join Subject s on c.SubjectId = s.Id
			inner join StatusAlias sa on c.StatusAliasId = sa.Id
		where (
			(
				c.Active = 1
				and sa.StatusBaseId in (1, 2, 4, 8)
				and c.SubjectId = @Subject
			)
			or exists (
				select 1
				from ProgramCourse pc
					inner join CourseOption co on pc.CourseOptionId = co.Id
				where co.ProgramId = @entityId
				and pc.CourseId = c.Id
			)
		)
		order by Text
'
WHERE Id = 128

UPDATE MetaForeignKeyCriteriaClient
sET CustomSql = '
DECLARE @subId int = (SELECT SubjectId FROM CourseRequisite WHERE Id = @PkIdValue)

select 
    c.Id as Value
    ,s.SubjectCode + '' '' + c.CourseNumber + '' - '' + c.Title + '' ('' + sa.Title + '')'' as Text
from Course c 
    inner join [Subject] s on s.Id = c.SubjectId 
    inner join StatusAlias sa on sa.Id = c.StatusAliasId
where c.ClientId = @clientId 
and c.Active = 1 
and c.SubjectId = @subId 
and sa.StatusBaseId = 1
order by Text
'
WHERE Id = 129

DECLARE @Sections TABLE (SECId int, TempId int)
INSERT INTO @Sections
SELECT mss.MetaSElectedSectionId, mss.MetaTemplateId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 3864

DECLARE @Temps INTEGERS
INSERT INTO @Temps
SELECT TempID FROM @Sections

DELETE FROM MetaDisplaySubscriber WHERE MetaDisplayRuleId in (
	SELECT mdr.Id FROM MetaDisplayRule AS mdr
	INNER JOIN ExpressionPart AS ep on ep.ExpressionId = mdr.ExpressionId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedFieldId = ep.Operand1_MetaSelectedFieldId
	INNER JOIN @Sections As s on msf.MetaSelectedSectionId = s.SECId
)

DELETE FROM MetaDisplayRule WHERE ExpressionId in (
	SELECT ExpressionId FROM ExpressionPart AS ep
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedFieldId = ep.Operand1_MetaSelectedFieldId
	INNER JOIN @Sections As s on msf.MetaSelectedSectionId = s.SECId
)

DELETE FROM ExpressionPart WHERE Operand1_MetaSelectedFieldId in (
	SELECT msf.MetaSelectedFieldId FROM MetaSelectedField AS msf
	INNER JOIN @Sections As s on msf.MetaSelectedSectionId = s.SECId
)

DELETE FROM MetaSelectedField WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @Sections
)

DELETE FROM MetaDisplaySubscriber WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @Sections
)

DELETE FROM MetaSelectedSectionRolePermission WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @Sections
)

DELETE FROM MetaSelectedSection WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @Sections
)

	declare @currentSettings NVARCHAR(max) = (
    select replace(replace(JSON_Query(Configurations, '$[2].settings'), '[',''),']','')   
    from Config.ClientSetting
)
set @currentSettings = @currentSettings + ',{
    "AccessLevel": "curriqunet",
    "DataType": "bool",
    "Description": "This will enable the Contributors flyout feature on Maverick",
    "Default": false,
    "Label": "Enable Maverick Co-Contributors",
    "Name": "EnableFlyoutCoContributors",
    "Value": true,
    "Active": true
}'
set @currentSettings = CONCAT('[',@currentSettings,']')
update Config.ClientSetting
set Configurations = JSON_MODIFY(Configurations, '$[2].settings',JSON_QUERY(@currentSettings))

INSERT INTO CourseContributorMetaSelectedSection
(CourseContributorId, MetaSelectedSectionId, CreatedDate)
SELECT cc.Id, mss.MetaSelectedSectionId, GETDATE() FROM CourseContributor AS cc
INNER JOIN Course AS c on cc.CourseId = c.Id
INNER JOIN MetaTemplate As mt on c.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL

INSERT INTO ProgramContributorMetaSelectedSection
(ProgramContributorId, MetaSelectedSectionId)
SELECT pc.Id, mss.MetaSelectedSectionId FROM ProgramContributor As pc
INNER JOIN Program AS p on pc.ProgramId = p.Id
INNER JOIN MetaTemplate As mt on p.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL

INSERT INTO ModuleContributorMetaSelectedSection
(ModuleContributorId, MetaSelectedSectionId, CreatedDate)
SELECT mc.Id, mss.MetaSelectedSectionId, GETDATE() FROM ModuleContributor AS mc
INNER JOIN Module AS m on mc.ModuleId = m.Id
INNER JOIN MetaTemplate As mt on m.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
WHERE mss.MetaSelectedSection_MetaSelectedSectionId IS NULL

DECLARE @CoCo TABLE (SecId int, FieldId int)
INSERT INTO @CoCo
SELECT mss.MetaSelectedSectionId, msf.MetaSelectedFieldId FROM MetaSelectedSection AS mss
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mss.MetaBaseSchemaId in (210, 326,1456)

UPDATE MetaSelectedSection
SET MetaBaseSchemaId = NULL
, MetaSectionTypeId = 1
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @CoCo
)

UPDATE MetaSelectedField
SET DisplayName = 'Open the Form Properties to select co-contributors and assign permissions.'
, MetaAvailableFieldId = NULL
, IsRequired = 0
, MaxCharacters = NULL
, DefaultDisplayType = 'StaticText'
, MetaPresentationTypeId = 35
, Width = NULL
, WidthUnit = 0
, Height = NULL
, HeightUnit = 0
, FieldTypeId = 2
, LabelStyleId = NULL
, LabelVisible = NULL
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @CoCo
)

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()