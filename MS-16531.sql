USE [socccd];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16531';
DECLARE @Comments nvarchar(Max) = 
	'Custom Admin Report';
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
SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId INT;
DECLARE @sql NVARCHAR(MAX) =
"
DECLARE @Contributer TABLE (ModuleId int, txt NVARCHAR(MAX))
INSERT INTO @Contributer
SELECT m.ID, dbo.ConcatWithSep_Agg('; ', CONCAT(u.Firstname, ' ', u.LastName))
FROM Module As m
INNER JOIN ModuleContributor AS mc on mc.ModuleId = m.Id
INNER JOIN [User] AS u on mc.UserId = u.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 64
group by m.Id

DECLARE @Checklist TABLE (ModuleId int, txt NVARCHAR(MAX))
INSERT INTO @Checklist
SELECT m.Id, dbo.ConcatWithSep_Agg('; ', lo2.LongText)
FROM Module AS m
INNER JOIN  ModuleLookup01 AS ml01 on ml01.ModuleId = m.Id
INNER JOIN Lookup02 AS lo2 on ml01.Lookup02Id = lo2.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 64
group by m.Id

DECLARE @Programs TABLE (ModuleId int, txt nvarchar(max))
INSERT INTO @Programs
SELECT m.Id, dbo.ConcatWithSep_Agg('; ', p.EntityTitle)
FROM Module AS m
INNER JOIN ModuleRelatedModule AS mrm on mrm.ModuleId = m.Id
INNER JOIN Program AS p on mrm.Reference_ProgramId = p.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 64
group by m.Id

DECLARE @Objective TABLE (ModuleId int, txt nvarchar(max))
INSERT INTO @Objective
SELECT m.ID, dbo.ConcatWithSep_Agg('; ', CONCAT(msg.MaxText01, ' - ', sg.Title, ' - ', it.Title))
FROM Module AS m
INNER JOIN ModuleStrategicGoal AS msg on msg.ModuleId = m.Id
INNER JOIN StrategicGoal AS sg on msg.StrategicGoalId = sg.Id
INNER JOIN ItemType AS it on msg.ItemTypeId = it.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 64
group by m.Id

DECLARE @Action TABLE (ModuleId int, txt nvarchar(max))
INSERT INTO @Action
SELECT m.Id, dbo.ConcatWithSep_Agg('; ', CONCAT(msgoal.MaxText01, ' - ', mmo.MaxText01, ' - ', mmo.MaxText02))
FROM Module AS m
INNER JOIN ModuleModuleObjective AS mmo on mmo.ModuleId = m.Id
INNER JOIN ModuleStrategicGoal AS msgoal on mmo.ModuleStrategicGoalId = msgoal.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 64
group by m.Id


SELECT 
yl.Title AS [Program Review Year],
CONCAT(u.FirstName, ' ', u.LastName) AS [Program Review Team Chair],
oe.Title AS [School/Division],
oe.Title AS [Department],
s.Title AS [Prefix],
c.txt AS [Program Review Team Members],
CASE
	WHEN myn.YesNo01Id = 1 THEN 'Yes'
	WHEN myn.YesNo01Id = 2 THEN 'No'
	ELSE ''
END AS [Would you like to make a presentation of this report to Consultation Council],
checkl.txt as [Program Review Checklist],
prog.txt AS [Programs],
obj.txt AS [Program Objectives],
action.txt AS [Action Steps],
dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.TextMax01)) AS [What are the most important contributions of the program to the college?],
dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.TextMax02)) As [Since the last PR, how have SLO results been used to make changes to the program and whats the impact?],
dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.TextMax03)) AS [How does the department determine if students who complete a degree or certificate are successful in achieving the stated PSLOs?],
dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.TextMax04)) AS [Did the program achieve its objectives from the last PR and what has been the impact of those achievements on the program?],
dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.TextMax07)) AS [A. What is the mission statement of the program?],
dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.TextMax08)) AS [B. How does the program's mission support the mission of the college?],
dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.TextMax09)) AS [C. How does the program align itself with the current strategic plan of the college, if applicable?],
dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.TextMax10)) AS [D. Describe any significant trends in the student demographics of the program.],
dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.TextMax06)) AS [E1. What are the program's average success and retention rates over the past five years?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax01)) AS [E2. How do these rates compare with collegewide averages?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax02)) AS [E3. Discuss the trends in these rates and how they are being addressed by the program.],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax03)) AS [F1. How does the program's five-year average success rate compare with the ISS success rate?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax04)) AS [F2. If the program's average falls below the ISS, what is being done to increase it?],
dbo.Format_RemoveAccents(dbo.stripHtml(mcrn.ShortText02)) AS [G. What percentage of the program's courses are offered online?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax05)) AS [H1. How do the online success and retention rates compare to the face-to-face rates?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax06)) AS [H2. If there is a discrepancy, what is being done to bring them into alignment?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax07)) AS [I. Describe the program's trends in section counts, enrollments, and FTES over the past five years?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax08)) AS [J1. Describe the program's trends in productivity and course fill rates over the past five years?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax09)) AS [J2. How does the program's productivity and course fill rates compare with collegewide trends?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax10)) AS [K. Describe the program's trends in award completions over the past five years?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax11)) AS [L1. For CTE programs, address the trends in labor market data (from EMSI) related to the program.],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax12)) AS [L2. How is the program responding to those trends?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax13)) AS [M. What are the unique challenges and opportunities of the program?],
Case
	WHEN myn.YesNo02Id = 1 THEN 'Yes'
	WHEN myn.YesNo02Id = 2 THEN 'No'
	ELSE ''
END AS [N. Did the program receive any funding for requested resources since the last PR?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax14)) AS [O. If funding was received, how did these resources result in program improvement?],
dbo.Format_RemoveAccents(dbo.stripHtml(me1.TextMax15)) AS [P. What is your department doing to institute equity-minded practices in your courses and/or program(s)?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax01)) AS [A1. Discuss the staffing structure of the program.],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax02)) AS [A2. How does the staffing structure impact the program's ability to fulfill its mission/objectives?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax03)) AS [B1. What professional development opportunities are available to the program's faculty and staff?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax04)) AS [B2. Are the professional development opportunities sufficient to meet the needs of the program?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax05)) AS [C. What are the program's current personnel needs, if any?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax06)) AS [D1. What curricular changes have been made in the program since the last PR?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax07)) AS [D2. What are the outcomes of those curricular changes?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax08)) AS [E. What are the program's current curricular/instructional needs, if any?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax09)) AS [F. Discuss the program's facilities, equipment, and technological infrastructure.],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax10)) AS [G. What are the program's current facilities needs, if any?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax11)) AS [H. What are the program's current equipment needs, if any?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax12)) AS [I. What are the program's current technology needs, if any?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax13)) AS [J1. Describe the program's service, outreach, marketing, and/or economic development activities?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax14)) AS [J2. What changes in these areas would make the program more effective, if any?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax15)) AS [K. What are the program's current marketing needs, if any?]
FROM Module AS m
INNER JOIN ModuleDetail AS md on md.ModuleId = m.Id
INNER JOIN [User] as u on m.UserId = u.Id
LEFT JOIN @Contributer AS c on c.ModuleId = m.Id
LEFT JOIN @Checklist AS checkl on checkl.ModuleId = m.Id
LEFT JOIN @Programs AS prog on prog.ModuleId = m.Id
LEFT JOIN @Objective AS obj on obj.ModuleId = m.Id
LEFT JOIN @Action AS action on action.ModuleId = m.Id
LEFT JOIN ModuleYesNo AS myn on myn.ModuleId = m.Id
LEFT JOIN YesNo AS yn on myn.YesNo01Id = yn.Id
LEFT JOIN ModuleCRN As mcrn on mcrn.ModuleId = m.Id
LEFT JOIN ModuleExtension01 AS me1 on me1.ModuleId = m.Id
LEFT JOIN ModuleExtension02 AS me2 on me2.ModuleId = m.Id
LEFT JOIN YearLookup AS yl on md.YearLookupId = yl.Id
LEFT JOIN OrganizationEntity AS oe on md.Tier1_OrganizationEntityId = oe.Id
LEFT JOIN OrganizationEntity AS oe2 on md.Tier2_OrganizationEntityId = oe2.Id
LEFT JOIN Subject AS s on md.SubjectId = s.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 64
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Program Review All Fields', @sql, 1, 0)
SET @adminReportId = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId, 2)

SET QUOTED_IDENTIFIER OFF 
 
DECLARE @adminReportId2 INT;
DECLARE @sql2 NVARCHAR(MAX) =
"
DECLARE @Contributer TABLE (ModuleId int, txt NVARCHAR(MAX))
INSERT INTO @Contributer
SELECT m.ID, dbo.ConcatWithSep_Agg('; ', CONCAT(u.Firstname, ' ', u.LastName))
FROM Module As m
INNER JOIN ModuleContributor AS mc on mc.ModuleId = m.Id
INNER JOIN [User] AS u on mc.UserId = u.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 65
group by m.Id

DECLARE @Checklist TABLE (ModuleId int, txt NVARCHAR(MAX))
INSERT INTO @Checklist
SELECT m.Id, dbo.ConcatWithSep_Agg('; ', lo2.LongText)
FROM Module AS m
INNER JOIN  ModuleLookup01 AS ml01 on ml01.ModuleId = m.Id
INNER JOIN Lookup02 AS lo2 on ml01.Lookup02Id = lo2.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 65
group by m.Id

DECLARE @Units TABLE (ModuleId int, txt nvarchar(max))
INSERT INTO @Units
SELECT m.Id, dbo.ConcatWithSep_Agg('; ', oe.Title)
FROM Module AS m
INNER JOIN ModuleEvaluationMethod AS mem on mem.ModuleId = m.Id
INNER JOIN OrganizationEntity AS oe on mem.ProgramId = oe.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 65
group by m.Id

DECLARE @Objective TABLE (ModuleId int, txt nvarchar(max))
INSERT INTO @Objective
SELECT m.ID, dbo.ConcatWithSep_Agg('; ', CONCAT(msg.MaxText01, ' - ', sg.Title, ' - ', it.Title))
FROM Module AS m
INNER JOIN ModuleStrategicGoal AS msg on msg.ModuleId = m.Id
INNER JOIN StrategicGoal AS sg on msg.StrategicGoalId = sg.Id
INNER JOIN ItemType AS it on msg.ItemTypeId = it.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 65
group by m.Id

DECLARE @Action TABLE (ModuleId int, txt nvarchar(max))
INSERT INTO @Action
SELECT m.Id, dbo.ConcatWithSep_Agg('; ', CONCAT(msgoal.MaxText01, ' - ', mmo.MaxText01, ' - ', mmo.MaxText02))
FROM Module AS m
INNER JOIN ModuleModuleObjective AS mmo on mmo.ModuleId = m.Id
INNER JOIN ModuleStrategicGoal AS msgoal on mmo.ModuleStrategicGoalId = msgoal.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 65
group by m.Id

SELECT 
yl.Title AS [Administrative Unit Review Year],
CONCAT(u.FirstName, ' ', u.LastName) AS [Administrative Unit Review Team Chair],
oe.Title AS [Department],
c.txt AS [Administrative Unit Review Team Members],
CASE
	WHEN myn.YesNO01Id = 1 THEN 'Yes'
	WHEN myn.YesNo01Id = 2 THEN 'No'
	ELSE ''
END AS [Would you like to make a presentation of this report to Consultation Council?],
clist.txt AS [Administrative Unit Review Checklist],
unit.txt AS [Units],
obj.txt AS [Unit Objectives],
act.txt AS [Action Steps],
dbo.Format_RemoveAccents(dbo.stripHtml(crn.TextMax01)) AS [A. What are the most important contributions of the unit to the college?],
dbo.Format_RemoveAccents(dbo.stripHtml(crn.TextMax02)) AS [B. How have AUO results been used to make changes to the unit and what has been the impact of those changes on the unit?],
dbo.Format_RemoveAccents(dbo.stripHtml(crn.TextMax04)) AS [C. Did the unit achieve its objectives from the last AUR and what has been the impact of those achievements on the unit?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax05)) AS [A1. Discuss the staffing structure of the unit.],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax06)) AS [A2. How does the staffing structure impact the unit’s ability to fulfill its mission/objectives?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax07)) AS [B1. What professional development opportunities are available to the unit’s management and staff?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax08)) AS [B2. Are the professional development opportunities sufficient to meet the needs of the unit?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax09)) AS [C. What are the unit’s current personnel needs, if any?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax10)) AS [D. Discuss the unit’s facilities, equipment, and technological infrastructure.],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax11)) AS [E. What are the unit’s current facilities needs, if any?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax12)) AS [F. What are the unit’s current equipment needs, if any?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax13)) AS [G. What are the unit’s current technology needs, if any?],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax14)) AS [H1. Describe the unit’s service, outreach, marketing, and/or economic development activities.],
dbo.Format_RemoveAccents(dbo.stripHtml(me2.TextMax15)) AS [H2. What changes in these areas would make the unit more effective?],
dbo.Format_RemoveAccents(dbo.stripHtml(crn.TextMax05)) AS [I. What are the unit’s current marketing needs, if any?]
FROM Module AS m
INNER JOIN ModuleDetail AS md on m.Id = md.ModuleId
INNER JOIN [User] AS u on m.UserId = u.Id
LEFT JOIN YearLookup AS yl on md.YearLookupId = yl.Id
LEFT JOIN OrganizationEntity AS oe on md.Tier2_OrganizationEntityId = oe.Id
LEFT JOIN @Contributer AS c on c.ModuleId = m.Id
LEFT JOIN ModuleYesNo AS myn on myn.ModuleId = m.Id
LEFT JOIN @Checklist AS clist on clist.ModuleId = m.Id
LEFT JOIN @Units AS unit on unit.ModuleId = m.Id
LEFT JOIN @Objective AS obj on obj.ModuleId = m.Id
LEFT JOIN @Action AS act on act.ModuleId = m.Id
LEFT JOIN ModuleCRN AS crn on crn.ModuleId = m.Id
LEFT JOIN ModuleExtension02 AS me2 on me2.ModuleId = m.Id
WHERE m.ClientId = 2
and m.Active = 1
and m.ProposalTypeId = 65
";

SET QUOTED_IDENTIFIER ON 

INSERT INTO AdminReport (ReportName, ReportSQL, OutputFormatId, ShowOnMenu)
VALUES ('Admin Unit Program Review All Fields', @sql2, 1, 0)
SET @adminReportId2 = SCOPE_IDENTITY ()

INSERT INTO AdminReportClient (AdminReportId, ClientId)
VALUES (@adminReportId2, 2)