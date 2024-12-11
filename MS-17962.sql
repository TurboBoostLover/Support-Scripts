USE [chabot];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17962';
DECLARE @Comments nvarchar(Max) = 
	'Update Admin Reports';
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
DELETE FROM AdminReportFilter WHERE AdminReportId = 29
DELETE FROM AdminReportClient WHERE AdminReportId = 29
DELETE FROM AdminReport WHERE Id = 29

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId INT;
DECLARE @sql NVARCHAR(MAX) =
"
DECLARE @SQL NVARCHAR(MAX) = (SELECT CustomSQL FROM MetaForeignKeyCriteriaClient WHERE Id = 42412)

SELECT DISTINCT
s.Title AS [Subject],
c.CourseNumber As [Course Number],
c.Title AS [Course Title],
co.OutcomeText AS [SLOs],
CASE WHEN mco.CourseOutcomeId IS NOT NULL THEN 'Yes'
ELSE NULL
END AS [Assessed],
d.Text AS [Next Assessment],
sa.Title As [Course Status],
sa2.Title As [Proposal status],
CONCAT(s.SubjectCode,  ' ', c.CourseNumber, ' - ', c.Title, ' (', convert(varchar(10),p.ImplementDate,101), ' - ', CASE WHEN c.StatusAliasId <> 1 THEN convert(varchar(10),p2.ImplementDate,101) ELSE  'Current' END, ')') as [Course Version],
lo1.ShortText AS [How well does the current learning outcome reflect what students need to learn],
dbo.Format_RemoveAccents(dbo.stripHtml(crn.TextMax02)) As [What course-level strengths has this assessment revealed? What about areas for improvement?],
dbo.Format_RemoveAccents(dbo.stripHtml(crn.TextMax03)) AS [Based on the assessment data results, what recommendations do you have for this course],
dbo.Format_RemoveAccents(dbo.stripHtml(crn.TextMax04)) AS [Describe any reflections or discussions that have taken place in your discipline based on the assessment data results]
FROM Module AS m
INNER JOIN StatusAlias as sa2 on sa2.Id = m.StatusAliasId
INNER JOIN ModuleDetail AS md on md.ModuleId = m.Id
INNER JOIN Course AS c on md.Reference_CourseId = c.Id
INNER JOIN BaseCourse AS bc on c.BaseCourseId = bc.Id
LEFT JOIN Course AS c2 on c2.BaseCourseId = bc.Id and c2.Id <> c.Id and c2.CreatedOn > c.CreatedOn
LEFT JOIN PRoposal As p2 on c2.ProposalId = p2.Id
INNER JOIN Proposal As p on c.ProposalId = p.Id
INNER JOIN StatusAlias AS sa on c.StatusAliasId = sa.Id
INNER JOIN Subject AS s on c.SubjectId = s.Id
INNER JOIN CourseOutcome AS co on co.CourseId = c.Id
INNER JOIN ModuleCRN AS crn on crn.ModuleId = m.Id
LEFT JOIN ModuleCourseOutcome AS mco on mco.ModuleId = m.Id
LEFT JOIN Lookup01 AS lo1 on md.Lookup01Id_01 = lo1.Id
cross apply dbo.fnBulkResolveCustomSqlQuery(@SQL,0,m.Id,1,786,0,null)d
WHERE M.Active = 1
and m.ProposalTypeId = 30
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Student Learning Outcomes Report', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 1)

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId2 INT;
DECLARE @sql2 NVARCHAR(MAX) =
"
DECLARE @SQL NVARCHAR(MAX) = (SELECT CustomSQL FROM MetaForeignKeyCriteriaClient WHERE Id = 42412)

SELECT DISTINCT
oe.Title AS [Discipline],
p.Title As [Program],
po.Outcome AS [Program Learning Outcome],
CASE WHEN mpo.ProgramOutcomeId IS NOT NULL THEN 'Yes'
ELSE NULL
END AS [Assessed],
d.Text AS [Next Assessment],
sa2.Title As [Status],
CONCAT(p.Title, ' - ', at.Title, ' (',convert(varchar(10),p5.ImplementDate,101), ' - ', CASE WHEN p.StatusAliasId <> 1 THEN convert(varchar(10),p3.ImplementDate,101) ELSE  'Current' END, ')') as [Version],
dbo.Format_RemoveAccents(dbo.stripHtml(crn.TextMax01)) AS [Past Assessment: What changes or improvements have you made in the past based on outcomes assessment?],
dbo.ConcatWithSep_Agg('; ', lo2.LongText) AS [Past Assessment: The assessment data that was gathered led to changes/improvements in...],
dbo.Format_RemoveAccents(dbo.stripHtml(crn.TextMax02)) AS [What are you planning to start doing, stop doing, or change in order to continuously improve your program?]
FROM Module AS m
INNER JOIN StatusAlias as sa2 on sa2.Id = m.StatusAliasId
INNER JOIN ModuleDetail AS md on md.ModuleId = m.Id
INNER JOIN OrganizationEntity As oe on md.Tier2_OrganizationEntityId = oe.Id
INNER JOIN Program as p on md.Active_ProgramId = p.Id
INNER JOIN Proposal AS p5 on p.ProposalId = p5.Id
INNER JOIN AwardType As at on p.AwardTypeId = at.Id
INNER JOIN ProgramOutcome As po on po.ProgramId = p.Id
LEFT JOIN ModuleProgramOutcome As mpo on mpo.ModuleId = m.Id
INNER JOIN BaseProgram AS bp on p.BaseProgramId = bp.Id
LEFT JOIN Program AS p2 on p2.BaseProgramId = bp.Id and p2.Id <> p.Id and p2.CreatedOn > p.CreatedOn
LEFT JOIN PRoposal As p3 on p2.ProposalId = p3.Id
INNER JOIN ModuleCRN AS crn on crn.ModuleId = m.Id
LEFT JOIN ModuleLookup03 AS ml3 on ml3.ModuleId = m.Id
LEFT JOIN Lookup03 AS lo2 on ml3.Lookup03Id = lo2.Id and lo2.Active = 1
cross apply dbo.fnBulkResolveCustomSqlQuery(@SQL,0,m.Id,1,786,0,null)d
WHERE M.Active = 1
and m.ProposalTypeId = 34
group by oe.Title, p.Title, po.Outcome, mpo.ProgramOutcomeId, d.Text, sa2.Title, at.Title, p5.ImplementDate, p.StatusAliasId, p3.ImplementDate, crn.TextMax01, crn.TextMax02
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Program Learning Outcome Report', @sql2, 1, 0)
SET @adminReportId2 = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId2, 1)

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId3 INT;
DECLARE @sql3 NVARCHAR(MAX) =
"
SELECT DISTINCT
oe.Title AS [Office],
oe2.Title AS [Department],
oe3.Title AS [Unit],
COALESCE(oeo.Outcome, oeo2.Outcome) AS [Service Area Outcomes],
yn.Title AS [Assessed],
convert(varchar(10),moee.Date01,101) AS [Next Assessment],
moee.MaxText01 AS [What is your program/area doing well regarding carrying out this SAO?],
moee.MaxText02 AS [Where does your program/area have room for growth in terms of carrying out this SAO?],
moee.MaxText03 AS [Moving forward, what will your program/area keep doing, stop doing, or change]
FROM Module AS m
INNER JOIN StatusAlias as sa on sa.Id = m.StatusAliasId
INNER JOIN ModuleDetail AS md on md.ModuleId = m.Id
INNER JOIN OrganizationEntity AS oe on md.Tier1_OrganizationEntityId = oe.Id
INNER JOIN OrganizationEntity As oe2 on md.Tier2_OrganizationEntityId = oe2.Id
LEFT JOIN OrganizationEntity AS oe3 on md.Tier3_OrganizationEntityId = oe3.Id
LEFT JOIN OrganizationEntityOutcome AS oeo on oeo.OrganizationEntityId = oe3.Id
LEFT JOIN OrganizationEntityOutcome AS oeo2 on oeo2.OrganizationEntityId = oe2.Id
LEFT JOIN ModuleOrganizationEntityOutcome AS moee on moee.ModuleId = m.Id
LEFT JOIN YesNo AS yn on moee.YesNoId_01 = yn.Id
WHERE M.Active = 1
and m.ProposalTypeId = 35
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Service Area Outcome Report ', @sql3, 1, 0)
SET @adminReportId3 = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId3, 1)