USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18434';
DECLARE @Comments nvarchar(Max) = 
	'Update Query on their 2nd Assessment';
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
UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
DECLARE @ModuleClientId INT = (SELECT ClientId FROM Module WHERE Id = @EntityId);
DECLARE @IndiSloTemplateTypeId INT;

DECLARE @MetaTemplateTypeList INTEGERS 
INSERT INTO @MetaTemplateTypeList
VALUES (15), (54);

DECLARE @OutComeId INT = (SELECT Reference_CourseOutcomeId FROM ModuleDetail WHERE ModuleId = @EntityId);

IF (@IsAdmin = 1)
BEGIN
    ;WITH MetaTemplateTypes (MetaTemplateTypeId) AS
    (
        SELECT Id FROM @MetaTemplateTypeList
    ),
    Modules (Text, Value, ClientEntitySubTypeId, OrganizationConnectionStrategyId, StatusBaseId, UserId) AS
    (
        SELECT 
            ''<b>'' +
            ''[{@{HyperLink}@, @{EntityEdit}@, @{Module}@, @{'' + CONVERT(VARCHAR(20), m.Id) + ''}@, @{''
            + COALESCE(m.Title, ''This Assessment has no title.'') + ''}@}] ''
            + ''</b>''
            + COALESCE(''<div style="float:right; color:red"> Created: '' + CONVERT(NVARCHAR(20), m.CreatedOn, 101) + '' </div>'', '''')
            + COALESCE(''<br />**'' + pt.Title + ''**'', '''')
            + COALESCE(''<div style="float:right; color:blue"> Originator: '' + u.FirstName + '' '' + u.LastName + '' </div>'', '''')
            AS Text,
            m.Id AS Value,
            cest.Id,
            COALESCE(cest.OrganizationConnectionStrategyId, cet.OrganizationConnectionStrategyId),
            sa.StatusBaseId,
            m.UserId
        FROM [Module] m
        LEFT JOIN [ProposalType] pt ON m.ProposalTypeId = pt.Id
        INNER JOIN [StatusAlias] sa ON m.StatusAliasId = sa.Id
        INNER JOIN [ClientEntityType] cet ON pt.EntityTypeId = cet.EntityTypeId AND pt.ClientId = cet.ClientId
        LEFT JOIN [ClientEntitySubType] cest ON pt.ClientEntitySubTypeId = cest.Id
        INNER JOIN [MetaTemplateTypes] mtt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
        INNER JOIN [User] u ON m.UserId = u.Id
        INNER JOIN ModuleDetail md ON m.Id = md.ModuleId AND md.Reference_CourseOutcomeId = @OutComeId
        WHERE m.ClientId = @ModuleClientId
          AND m.StatusAliasId = 1
          AND m.CreatedOn >= DATEADD(YEAR, -4, GETDATE()) -- Last 4 years
    ),
    CurrentProposal (Text, Value, ClientEntitySubTypeId, OrganizationConnectionStrategyId, StatusBaseId, UserId) AS
    (
        SELECT 
            ''<b>'' +
            ''[{@{HyperLink}@, @{EntityEdit}@, @{Module}@, @{'' + CONVERT(VARCHAR(20), m.Id) + ''}@, @{''
            + COALESCE(m.Title, ''This Assessment has no title.'') + ''}@}] ''
            + ''</b>''
            + COALESCE(''<div style="float:right; color:red"> Created: '' + CONVERT(NVARCHAR(20), m.CreatedOn, 101) + '' </div>'', '''')
            + COALESCE(''<br />**'' + pt.Title + ''**'', '''')
            + COALESCE(''<div style="float:right; color:blue"> Originator: '' + u.FirstName + '' '' + u.LastName + '' </div>'', '''')
            AS Text,
            m.Id AS Value,
            cet.Id,
            cet.OrganizationConnectionStrategyId,
            sa.StatusBaseId,
            m.UserId
        FROM ModuleRelatedModule mrm
        INNER JOIN Module m ON mrm.Reference_ModuleId = m.Id
        INNER JOIN ProposalType pt ON m.ProposalTypeId = pt.Id
        INNER JOIN [User] u ON m.UserId = u.Id
        INNER JOIN [StatusAlias] sa ON m.StatusAliasId = sa.Id
        INNER JOIN [ClientEntityType] cet ON pt.EntityTypeId = cet.EntityTypeId AND cet.ClientId = @ModuleClientId
        WHERE mrm.ModuleId = @EntityId
          AND m.CreatedOn >= DATEADD(YEAR, -4, GETDATE()) -- Last 4 years
    )
    SELECT Text, Value
    FROM Modules m
        INNER JOIN ModuleDetail md ON m.Value = md.ModuleId
    UNION
    SELECT Text, Value
    FROM CurrentProposal m
        INNER JOIN ModuleDetail md ON m.Value = md.ModuleId
    WHERE NOT EXISTS (
        SELECT 1 FROM ModuleRelatedModule mrm 
        WHERE mrm.ModuleId != @ModuleClientId 
          AND mrm.Reference_ModuleId = m.Value
    ) 
    AND (EXISTS (SELECT 1 FROM ModuleRelatedModule mrm WHERE mrm.ModuleId = @EntityId AND mrm.Reference_ModuleId = m.Value) 
         OR (m.StatusBaseId = 4 AND m.Value != @EntityId)) 
    ORDER BY m.Text;
END
ELSE
	BEGIN
		;WITH MetaTemplateTypes (MetaTemplateTypeId) AS
		(
			SELECT Id FROM @MetaTemplateTypeList
		),
		Modules (Text, Value, ClientEntitySubTypeId, OrganizationConnectionStrategyId, StatusBaseId, UserId) AS
		(
			SELECT 
				''[{@{HyperLink}@, @{EntityEdit}@, @{Module}@, @{'' + convert(varchar(20), m.Id) + ''}@, @{''
				+ coalesce(m.Title, ''This Assessment has no title.'') + ''}@}] ''
				+ coalesce(''<div style="float:right; color:red"> Created: '' + convert(nvarchar(20),m.createdOn,101) + '' </div>'','''')
				+ coalesce(''<br />**'' + pt.Title + ''**'','''') 
				+ coalesce(''<div style="float:right; color:blue"> Originator: '' + u.FirstName + '' '' + u.LastName + '' </div>'','''') 
				as Text,
				m.Id as Value,
				cest.Id,
				coalesce(cest.OrganizationConnectionStrategyId, cet.OrganizationConnectionStrategyId),
				sa.StatusBaseId,
				m.UserId
			FROM [Module] m
				LEFT JOIN [ProposalType] pt ON m.ProposalTypeId = pt.Id
				INNER JOIN [StatusAlias] sa ON m.StatusAliasId = sa.Id
				INNER JOIN ClientEntityType cet ON pt.EntityTypeId = cet.EntityTypeId
					AND pt.ClientId = cet.ClientId
				LEFT JOIN ClientEntitySubType cest on pt.ClientEntitySubTypeId = cest.Id
				INNER JOIN MetaTemplateTypes mtt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
				INNER JOIN [User] u on m.UserId = u.id
				INNER JOIN ModuleDetail md on m.id = md.ModuleId AND md.Reference_CourseOutcomeId = @OutComeId
			WHERE m.ClientId = @ModuleClientId
			AND m.StatusAliasId = 1
			AND m.CreatedOn >= DATEADD(YEAR, -4, GETDATE()) -- Last 4 years
		),
		CurrentProposal (Text, Value, ClientEntitySubTypeId, OrganizationConnectionStrategyId, StatusBaseId, UserId) AS
		(
			select 
				''<b>'' +
				''[{@{HyperLink}@, @{EntityEdit}@, @{Module}@, @{'' + convert(varchar(20), m.Id) + ''}@, @{''
				+ coalesce(m.Title, ''This Assessment has no title.'') + ''}@}] ''
				+ ''</b>''
				+ coalesce(''<div style="float:right; color:red"> Created: '' + convert(nvarchar(20),m.createdOn,101) + '' </div>'','''')
				+ coalesce(''<br />**'' + pt.Title + ''**'','''')
				+ coalesce(''<div style="float:right; color:blue"> Originator: '' + u.FirstName + '' '' + u.LastName + '' </div>'','''')
				as Text,
				m.Id as Value,
				cet.Id,
				cet.OrganizationConnectionStrategyId,
				sa.StatusBaseId,
				m.UserId
			 from ModulerelatedModule mrm
			 Inner Join Module m on mrm.Reference_ModuleId = m.Id
			 Inner join ProposalType pt ON m.ProposalTypeId = pt.Id 
			 INNER JOIN [User] u on m.UserId = u.id
			 INNER JOIN [StatusAlias] sa ON m.StatusAliasId = sa.Id
			 INNER JOIN [ClientEntityType] cet ON pt.EntityTypeId = cet.EntityTypeId and cet.ClientId = @ModuleClientId
			 where mrm.ModuleId = @EntityId
				AND m.CreatedOn >= DATEADD(YEAR, -4, GETDATE()) -- Last 4 years
			 )
		SELECT Text, Value
		FROM Modules m
			INNER JOIN ModuleDetail md ON m.Value = md.ModuleId
		UNION 
		SELECT Text, Value
		FROM CurrentProposal m
			INNER JOIN ModuleDetail md ON m.Value = md.ModuleId
		WHERE NOT EXISTS (
			SELECT 1 FROM moduleRelatedModule mrm 
			WHERE mrm.ModuleId != @entityId 
			AND mrm.Reference_ModuleId = m.Value
			) 
		AND (EXISTS (SELECT 1 FROM ModuleRelatedModule mrm WHERE mrm.ModuleId = @entityId AND mrm.Reference_ModuleId = m.Value) 
		OR (m.StatusBaseId = 4 AND m.Value != @entityId)) 
		AND ((m.OrganizationConnectionStrategyId = 1 AND EXISTS (SELECT 1
																FROM [UserOriginationSubjectPermission] uosp
																WHERE uosp.SubjectId = md.SubjectId
																AND uosp.UserId = @userId))
		OR (m.OrganizationConnectionStrategyId = 2 AND EXISTS (SELECT 1
																FROM [UserOriginationOrganizationEntityPermission] uooep
																WHERE uooep.OrganizationEntityId = coalesce(md.Tier3_OrganizationEntityId, md.Tier2_OrganizationEntityId, md.Tier1_OrganizationEntityId)
																AND uooep.UserId = @userId)))
		ORDER BY m.Text;
END
'
WHERE Id = 209

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedFieldId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 209