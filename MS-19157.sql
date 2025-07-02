USE [sbccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19157';
DECLARE @Comments nvarchar(Max) = 
	'Update Resource Request Admin report';
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
UPDATE AdminReport
SET ReportSQL = '
DECLARE @lu12a NVARCHAR(MAX);
DECLARE @lu12t NVARCHAR(MAX);

SELECT @lu12a = dbo.ConcatWithSepOrdered_Agg('','', Id, concat(''['', Title, '']''))
FROM Lookup12
WHERE ClientId = 3
AND Lookup12ParentId = 1
AND Active = 1
AND Title NOT IN (''Faculty'', ''Classified'');

SELECT @lu12t = dbo.ConcatWithSepOrdered_Agg('','', Id, concat(''['', Title, '']''))
FROM Lookup12
WHERE ClientId = 3
AND Lookup12ParentId = 1
AND Active = 1
AND Title IN (''Faculty'', ''Classified'');

DECLARE @sql NVARCHAR(MAX) = ''
DECLARE @lu12Ta TABLE (Id INT, columnName SYSNAME)
DECLARE @lu12Tt TABLE (Id INT, columnName SYSNAME)
DECLARE @separator NVARCHAR(50) = '''' || ''''

DECLARE @mtIds INTEGERS;

INSERT INTO @mtIds(Id)
SELECT mt.MetaTemplateId
FROM MetaTemplate mt
	INNER JOIN MetaTemplateType mtt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mtt.ClientEntityTypeId = 18
AND mtt.IsPresentationView = 0
AND mt.ClientId = 3
AND mt.Title LIKE ''''%Year%'''';

INSERT INTO @lu12Ta
SELECT Id, Title
FROM Lookup12
WHERE ClientId = 3
AND Lookup12ParentId = 1
AND Active = 1
AND Title NOT IN (''''Faculty'''', ''''Classified'''');

INSERT INTO @lu12Tt
SELECT Id, Title
FROM Lookup12
WHERE ClientId = 3
AND Lookup12ParentId = 1
AND Active = 1
AND Title IN (''''Faculty'''', ''''Classified'''');


SELECT
	pvt.Id,
	pvt.Title [Program Review Title],
    pvt.Division,
    pvt.Department,
    pvt.Area,
    pvt.Semester AS [Semester Assessed],
	pvt.Description AS [Area Description],
	pvt.Mission AS [Mission, Vision and Values],
	pvt.Strenghts,
	pvt.Weaknesses,
	pvt.Opportunities,
	pvt.Threats,
	pvt.Goals,
	pvt.Planning,
	pvt.TOASTS,
    pvt.YesNo AS [Do you want to request resources?],
	pvt.how AS [How does the department and the request(s) align with the Mission, Vision, and Values of the College?],
    '' + @lu12a + ''
INTO #temp1
FROM
(SELECT
    m.Id,
    m.Title AS Title,
    l12a.columnName AS Lookup12a,
    s.Title AS [Semester],
    div.Title AS [Division],
    dep.Title AS [Department],
    area.Title AS [Area],
    yn.Title AS [YesNo],
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax01)) AS [Description],
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax02)) AS [Mission],
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax03)) AS [Strenghts],
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax04)) AS [Weaknesses], 
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax05)) AS [Opportunities], 
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax06)) AS [Threats], 
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax07)) AS [Goals], 
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax08)) AS [Planning],
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax09)) AS [TOASTS],
	dbo.Format_RemoveAccents(dbo.stripHtml(me.TextMax01)) AS [how],
    CONCAT(COALESCE(FORMAT(ml12.Decimal01, ''''##0.##''''), ''''''''), COALESCE(@separator + ml12.MaxText01, '''''''')) AS [Requests]
FROM Module m
    INNER JOIN ModuleDetail md ON m.Id = md.ModuleId
	INNER JOIN ModuleCRN mc ON mc.ModuleId = m.Id
	INNER JOIN ModuleExtension01 me ON me.ModuleId = m.Id
    LEFT JOIN OrganizationEntity div ON md.Tier1_OrganizationEntityId = div.Id
    LEFT JOIN OrganizationEntity dep ON md.Tier2_OrganizationEntityId = dep.Id
    LEFT JOIN OrganizationEntity area ON md.Tier3_OrganizationEntityId = area.Id
    INNER JOIN ModuleYesNo myn ON myn.ModuleId = m.Id
    LEFT JOIN YesNo yn ON yn.Id = myn.YesNo05Id
    LEFT JOIN ModuleLookup12 ml12 
	OUTER APPLY (SELECT * FROM @lu12Ta l12a WHERE ml12.Lookup12Id = l12a.Id) l12a
    ON m.Id = ml12.ModuleId
    LEFT JOIN Semester s ON s.Id = m.SemesterId
	INNER JOIN StatusAlias sa ON sa.Id = m.StatusAliasId
WHERE m.MetaTemplateId IN (SELECT Id FROM @mtIds)
AND sa.StatusBaseId = 6
AND m.Active = 1) p
PIVOT --This will display the repeater items in their own columns
(
MAX([Requests])
FOR p.Lookup12a IN (''+ @lu12a +'')
) AS pvt

SELECT
	pvt2.Id,
	pvt2.Title [Program Review Title],
    pvt2.Division,
    pvt2.Department,
    pvt2.Area,
    pvt2.Semester AS [Semester Assessed],
	pvt2.Description AS [Area Description],
	pvt2.Mission AS [Mission, Vision and Values],
	pvt2.Strenghts,
	pvt2.Weaknesses,
	pvt2.Opportunities,
	pvt2.Threats,
	pvt2.Goals,
	pvt2.Planning,
	pvt2.TOASTS,
    pvt2.YesNo AS [Do you want to request resources?],
	pvt2.how AS [How does the department and the request(s) align with the Mission, Vision, and Values of the College?],
    '' + @lu12t + ''
INTO #temp2
FROM
(SELECT
    m.Id,
    m.Title AS Title,
    l12t.columnName AS Lookup12t,
    s.Title AS [Semester],
    div.Title AS [Division],
    dep.Title AS [Department],
    area.Title AS [Area],
    yn.Title AS [YesNo],
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax01)) AS [Description],
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax02)) AS [Mission],
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax03)) AS [Strenghts],
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax04)) AS [Weaknesses], 
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax05)) AS [Opportunities], 
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax06)) AS [Threats], 
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax07)) AS [Goals], 
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax08)) AS [Planning],
	dbo.Format_RemoveAccents(dbo.stripHtml(mc.TextMax09)) AS [TOASTS],
	dbo.Format_RemoveAccents(dbo.stripHtml(me.TextMax01)) AS [how],
	CONCAT(COALESCE(FORMAT(ml12.Decimal02, ''''##0.##''''), ''''''''), COALESCE(@separator + FORMAT(ml12.Decimal03, ''''##0.##''''), '''''''')) AS [Other]
FROM Module m
    INNER JOIN ModuleDetail md ON m.Id = md.ModuleId
	INNER JOIN ModuleCRN mc ON mc.ModuleId = m.Id
	INNER JOIN ModuleExtension01 me ON me.ModuleId = m.Id
    LEFT JOIN OrganizationEntity div ON md.Tier1_OrganizationEntityId = div.Id
    LEFT JOIN OrganizationEntity dep ON md.Tier2_OrganizationEntityId = dep.Id
    LEFT JOIN OrganizationEntity area ON md.Tier3_OrganizationEntityId = area.Id
    INNER JOIN ModuleYesNo myn ON myn.ModuleId = m.Id
    LEFT JOIN YesNo yn ON yn.Id = myn.YesNo05Id
    LEFT JOIN ModuleLookup12 ml12 
	OUTER APPLY (SELECT * FROM @lu12Tt l12t WHERE ml12.Lookup12Id = l12t.Id) l12t
    ON m.Id = ml12.ModuleId
    LEFT JOIN Semester s ON s.Id = m.SemesterId
	INNER JOIN StatusAlias sa ON sa.Id = m.StatusAliasId
WHERE m.MetaTemplateId IN (SELECT Id FROM @mtIds)
AND sa.StatusBaseId = 6
AND m.Active = 1) p
PIVOT --This will display the repeater items in their own columns
(
MAX([Other])
FOR p.Lookup12t IN (''+ @lu12t +'')
) AS pvt2;

SELECT t1.*, ''+ @lu12t +'' FROM #temp1 t1 JOIN #temp2 t2 ON t1.Id = t2.Id''

EXECUTE sp_executesql @sql;'
WHERE Id = 11