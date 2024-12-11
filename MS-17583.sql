USE [delta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17583';
DECLARE @Comments nvarchar(Max) = 
	'Update Bad Queries from wiping out data';
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
select 
	oe.Id as Value,
	oe.Title as Text
from OrganizationTier ot
inner join OrganizationEntity oe on ot.Id = oe.OrganizationTierId
where ot.Title = ''Division''
	and ot.Active = 1
	and oe.Active = 1
and oe.Id IN (
	select distinct ol.Parent_OrganizationEntityId from StudentData sd
	inner join CRNOffering co on co.Id = sd.CRNOfferingId
	inner join CRN crn on co.CRNId = crn.Id
	inner join Semester sem on co.SemesterId = sem.Id AND sem.TermStartDate > dateadd(year,-1,getdate()) AND sem.TermStartDate > ''1/1/2022''
	inner join Module m on sd.UserId = m.UserId AND m.Id = @entityId
	inner join Subject s on crn.SubjectId = s.Id
	inner join OrganizationSubject os on os.SubjectId = s.Id
	inner join OrganizationLink ol on os.OrganizationEntityId = ol.Child_OrganizationEntityId
)
UNION
SELECT oe.Id AS Value,
oe.Title AS Text
FROM OrganizationEntity AS oe
INNER JOIN ModuleDetail AS md on md.Tier1_OrganizationEntityId = oe.Id
wHERE md.ModuleId = @EntityId
ORDER BY oe.Title
'
WHERE Id = 647

UPDATE MetaForeignKeyCriteriaClient
sET CustomSql = '
select 
	oe.Id as Value,
	oe.Title as Text
from OrganizationTier ot
inner join OrganizationEntity oe on ot.Id = oe.OrganizationTierId
where ot.Title = ''Department''
	and ot.Active = 1
	and oe.Active = 1
and oe.Id IN (
	select distinct ol.Child_OrganizationEntityId from StudentData sd
	inner join CRNOffering co on co.Id = sd.CRNOfferingId
	inner join CRN crn on co.CRNId = crn.Id
	inner join Subject s on crn.SubjectId = s.Id
	inner join OrganizationSubject os on os.SubjectId = s.Id
	inner join OrganizationLink ol on os.OrganizationEntityId = ol.Child_OrganizationEntityId and OL.Parent_OrganizationEntityId = @Tier1_OrganizationEntityId
	inner join Semester sem on co.SemesterId = sem.Id AND sem.TermStartDate > dateadd(year,-1,getdate()) AND sem.TermStartDate > ''1/1/2022''
	inner join Module m on sd.UserId = m.UserId AND m.Id = @entityId
)
UNION
SELECT oe.Id AS Value,
oe.Title AS Text
FROM OrganizationEntity AS oe
INNER JOIN ModuleDetail AS md on md.Tier2_OrganizationEntityId = oe.Id
wHERE md.ModuleId = @EntityId
ORDER BY oe.Title
'
WHERE Id = 264

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
SELECT 
	s.id AS Value,
	CONCAT (s.Title,'' ('', s.SubjectCode,'')'') As Text
FROM Subject s 
	inner join OrganizationSubject os on os.SubjectId = s.Id
WHERE s.ClientId = @clientId 
	AND s.Active = 1
	AND os.OrganizationEntityId = @Tier2_OrganizationEntityId
	and s.id IN (
	select distinct s.id from StudentData sd
	inner join CRNOffering co on co.Id = sd.CRNOfferingId
	inner join CRN crn on co.CRNId = crn.Id
	inner join Subject s on crn.SubjectId = s.Id
	inner join Semester sem on co.SemesterId = sem.Id AND sem.TermStartDate > dateadd(year,-1,getdate()) AND sem.TermStartDate > ''1/1/2022''
	inner join Module m on sd.UserId = m.UserId AND m.Id = @entityId
)
union
SELECT s.ID AS Value,
	CONCAT (s.Title,'' ('', s.SubjectCode,'')'') As Text
FROM Subject s 
INNER JOIN ModuleDetail AS md on md.Reference_SubjectId = s.Id
WHERE md.ModuleId = @EntityId
Order BY Text
'
WHERE Id = 2606

UPDATE MetaForeignKeyCriteriaClient
sET CustomSql = '
SELECT
	c.Id AS [Value]
	,concat(
		COALESCE(c.EntityTitle, concat(s.SubjectCode,space(1),c.CourseNumber,space(1),c.Title)),
		CASE
		WHEN md.Reference_CourseId IS NOT NULL AND
			c.Id = md.Reference_CourseId THEN '' *''
		ELSE ''''
		End
	) as Text
   ,s.id AS filterColumn
FROM Course c
	INNER JOIN CourseDescription cd ON cd.CourseId = c.Id
	INNER JOIN [Subject] s ON c.SubjectId = s.Id
	inner join OrganizationSubject os on os.SubjectId = s.Id
	INNER JOIN StatusAlias sa ON c.StatusAliasId = sa.Id
	LEFT OUTER JOIN ModuleDetail md ON md.ModuleId = @entityId
WHERE c.ClientId = @clientId
AND c.Active = 1
AND s.id = @Reference_SubjectId
AND sa.StatusBaseId = 1
AND cd.HasComputerizedCatalog = 1
AND EXISTS (
	SELECT
		1
	FROM CourseOutcome co
		INNER JOIN Course c_inner
		INNER JOIN StatusAlias sa_inner ON c_inner.StatusAliasId = sa_inner.Id ON co.CourseId = c_inner.Id
	WHERE c.BaseCourseId = c_inner.BaseCourseId
	AND sa_inner.StatusBaseId IN (1)
)
AND c.Id IN (
	select distinct c.Id as CourseId from StudentData sd
	inner join CRNOffering co on co.Id = sd.CRNOfferingId
	inner join CRN crn on co.CRNId = crn.Id
	inner join Semester sem on co.SemesterId = sem.Id AND sem.TermStartDate > dateadd(year,-1,getdate()) AND sem.TermStartDate > ''1/1/2022''
	inner join Module m on sd.UserId = m.UserId AND m.Id = @entityId	
	where exists (select top 1 1 from Course c where (crn.ClientId = c.ClientId and crn.SubjectId = c.SubjectId and dbo.RegEx_Replace(crn.CourseNumber,''\d+'','''') = dbo.RegEx_Replace(c.CourseNumber,''\d+'','''') 
				AND (Cast(dbo.RegEx_Replace(crn.CourseNumber,''\D+'','''') as int) = CAST(dbo.RegEx_Replace(c.CourseNumber,''\D+'','''') as int))))
)
UNION
SELECT 
c.Id AS [Value]
	,concat(
		COALESCE(c.EntityTitle, concat(s.SubjectCode,space(1),c.CourseNumber,space(1),c.Title)),
		CASE
		WHEN md.Reference_CourseId IS NOT NULL AND
			c.Id = md.Reference_CourseId THEN '' *''
		ELSE ''''
		End
	) as Text
   ,s.id AS filterColumn
FROM Course c
	INNER JOIN CourseDescription cd ON cd.CourseId = c.Id
	INNER JOIN [Subject] s ON c.SubjectId = s.Id
	INNER JOIN ModuleDetail AS md on md.Reference_CourseId = c.Id
	WHERE md.ModuleId = @EntityId
ORDER BY Text
'
WHERE Id = 253

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (
		253, 2606, 264, 647
	)
)