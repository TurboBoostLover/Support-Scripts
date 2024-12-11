USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17007';
DECLARE @Comments nvarchar(Max) = 
	'Update bad query
	note: his all stems from when it was requested we turn off auto update on the "Articulation Programs" tab so that historical ones no longer update to the new versions.
	This query on this checklist was developed to pull in active Programs in black and historical in red but when it auto updated it never would show the red since there where no longer historical programs selected on that tab,
	it never updated this checklist with auto update it would of shown nothing being selected on the new version. 
	Now that auto update is off there are still historical programs selected on the "Articulation Programs" Tab that are not visible since that query is written to only show active Programs. 
	So now with leaving auto update on that tab off (requested in #40027) this is to make it behave like it would have before
	';
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
sET CustomSql = '		
select p.Id as [Value],
				concat(
					isnull(p.Title, '''')
					, '' - ''
					, coalesce(p.Associations, '''')
					, ''<br />''
				) as [Text]
		from Program p
			inner join OrganizationEntity oe on p.Tier2_OrganizationEntityId = oe.Id
			inner join StatusAlias sa on p.StatusAliasId = sa.Id
			inner join ProposalType pt on p.ProposalTypeId = pt.Id
			inner join AwardType awt on awt.Id = p.AwardTypeId
		where p.ClientId = 1
		and p.Active = 1
		and p.StatusAliasId <> 5
		and (sa.Title = ''Active''
			or exists (
				select 1
				from ProgramSequenceProgram psp
				where p.Id = psp.Related_ProgramId
			)
		)
		and awt.Code in (''CERTF'', ''CERTN'', ''ATCF'', ''ATCN'', ''ATDF'', ''ATDN'')
		and p.Tier2_OrganizationEntityId = (
			select Tier2_OrganizationEntityId
			from Program
			where Id = @entityId
		)
		order by oe.Title, p.Title, pt.Title;
		'
WHERE Id = 65

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 65
)