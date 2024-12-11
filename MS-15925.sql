USE [chabot];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15925';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text on SLO aggregate assessmnent';
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
DECLARE @SQL NVARCHAR(MAX) = '
Declare @CourseId int = (select Reference_CourseId from ModuleDetail where moduleId = @EntityId);
if (@isAdmin = 1)   BEGIN    
  ;WITH Modules (Text, Value, StatusBaseId, UserId) AS     
  (
         SELECT
						CONCAT(m.EntityTitle, '' - '', mcrn.Int01) as Text,      
						 m.Id as Value,      
						 sa.StatusBaseId,      
						 m.UserId     
		FROM [Module] m      
		LEFT JOIN ProposalType pt ON m.ProposalTypeId = pt.Id  
		LEFT JOIN ModuleCRN As mcrn on mcrn.ModuleId = m.Id
		INNER JOIN StatusAlias sa ON m.StatusAliasId = sa.Id      
		INNER JOIN MetaTemplateType mtt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId and mtt.TemplateName = ''SLO Assessment''      
		INNER JOIN [User] u on m.UserId = u.id      
		INNER JOIN ModuleDetail md on m.id = md.ModuleId AND md.Reference_CourseId = @CourseId  
        where m.StatusAliasId = 1
		--INNER JOIN StatusAlias sa2 on m.StatusAliasId = sa2.Id and sa2.StatusBaseId = 4     AND m.Active = 1    
		)    
		SELECT Text, Value    
		FROM Modules m     
		INNER JOIN ModuleDetail md ON m.Value = md.ModuleId    
		WHERE (EXISTS (SELECT 1 FROM ModuleRelatedModule mrm WHERE mrm.ModuleId = @entityId AND mrm.Reference_ModuleId = m.Value)     
		OR  m.Value != @entityId)     
		ORDER BY m.Text;   
		END  ELSE  BEGIN    
		;WITH Modules (Text, Value, StatusBaseId, OrganizationConnectionStrategyId, UserId) AS     
		(       
			SELECT          
						CONCAT(m.EntityTitle, '' - '', mcrn.Int01) as Text,      
					  m.Id as Value,      
					  coalesce(cest.OrganizationConnectionStrategyId, cet.OrganizationConnectionStrategyId),      
					  sa.StatusBaseId,     
					  m.UserId     
			FROM [Module] m      
			LEFT JOIN ProposalType pt ON m.ProposalTypeId = pt.Id  
			LEFT JOIN ModuleCRN As mcrn on mcrn.ModuleId = m.Id
			INNER JOIN StatusAlias sa ON m.StatusAliasId = sa.Id      
			INNER JOIN MetaTemplateType mtt ON pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId and mtt.TemplateName = ''SLO Assessment''      
			INNER JOIN [ClientEntityType] cet ON pt.EntityTypeId = cet.EntityTypeId       AND pt.ClientId = cet.ClientId      
			LEFT JOIN [ClientEntitySubType] cest on pt.ClientEntitySubTypeId = cest.Id      
			INNER JOIN [User] u on m.UserId = u.id      
			INNER JOIN ModuleDetail md on m.id = md.ModuleId
            where m.StatusAliasId = 1
            
			--INNER JOIN StatusAlias sa2 on m.StatusAliasId = sa2.Id and sa2.StatusBaseId = 4     AND m.Active = 1    
			)    
			SELECT Text, Value    
			FROM Modules m     
			INNER JOIN ModuleDetail md ON m.Value = md.ModuleId    
			WHERE (
				EXISTS (
					SELECT 1 FROM ModuleRelatedModule mrm WHERE mrm.ModuleId = @entityId AND mrm.Reference_ModuleId = m.Value
					)     
				OR (m.StatusBaseId = 4 AND m.Value != @entityId))     
				AND ((m.OrganizationConnectionStrategyId = 1 
					AND EXISTS (
						SELECT 1                  
						FROM [UserOriginationSubjectPermission] uosp                  
						WHERE uosp.SubjectId = md.SubjectId                  
						AND uosp.UserId = @userId))    
				OR (m.OrganizationConnectionStrategyId = 2 
					AND EXISTS (
						SELECT 1                  
						FROM [UserOriginationOrganizationEntityPermission] uooep                  
						WHERE uooep.OrganizationEntityId = coalesce(md.Tier3_OrganizationEntityId, md.Tier2_OrganizationEntityId, md.Tier1_OrganizationEntityId)
					AND uooep.UserId = 1)))    ORDER BY m.Text;   END
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 56173709

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField As msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 56173709
)