USE [chaffey];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16152';
DECLARE @Comments nvarchar(Max) = 
	'Add reports to all PSR proposals';
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
INSERT INTO MetaReportTemplateType
(MetaReportId, MetaTemplateTypeId, StartDate)
VALUES
(57, 37, GETDATE())

UPDATE AdminReport
SET ReportSQL = 'DECLARE @checked NVARCHAR(MAX) = ''Yes'';
DECLARE @unchecked NVARCHAR(MAX) = ''No'';
DECLARE @separator NVARCHAR(MAX) = ''========================'' + CHAR(10);

DECLARE @coContributors TABLE (Id INT Identity, moduleId INT, [Text] NVARCHAR(MAX))

INSERT INTO @coContributors (moduleId, [Text])
SELECT ModuleId, CONCAT(U.LastName, '', '', U.FirstName)
FROM Module M
	INNER JOIN ModuleContributor MC ON MC.ModuleId = M.Id
	INNER JOIN [User] U ON U.Id = MC.UserId

DECLARE @ACESSkill TABLE (Id INT Identity, moduleId INT, [Text] NVARCHAR(MAX))

INSERT INTO @ACESSkill(moduleId, [Text])
SELECT MSG.ModuleId, SG.Title
FROM Module M
	INNER JOIN ModuleStrategicGoal MSG ON MSG.ModuleId = M.Id
	INNER JOIN StrategicGoal SG ON SG.Id = MSG.StrategicGoalId


SELECT 
	concat(M.Title,'' ('',SA.Title,'')'') AS Title
	, CONCAT(U.LastName, '', '', U.FirstName) AS Originator
	, OES.Title AS School
	, OED.Title AS [Department/Area Name]
	, ME01.TextMax05 AS [Progarm Budget Code]
	, YN.Title AS [CTE Program]
	, CC.CoContributors AS [Co-Contributors]
	, QFL.Title AS [Type of PSR]
	, YN30.Title AS [ACES-ILOs Assessment Completed]
	, [AS].Skills AS [ACES-ILOs Skills]
	, ME01.TextMax01 AS [Year 1 Objectives or actions]
	, ME01.TextMax02 AS [Year 2 Objectives or actions]
	, ME01.TextMax03 AS [Year 3 Objectives or actions]
FROM Module M
	LEFT JOIN [User] U ON U.Id = M.UserId
	INNER JOIN ModuleDetail MD ON MD.ModuleId = M.Id
	LEFT JOIN OrganizationEntity OES ON OES.Id = MD.Tier1_OrganizationEntityId
	LEFT JOIN OrganizationEntity OED ON OED.Id = MD.Tier2_OrganizationEntityId
	INNER JOIN ModuleExtension01 ME01 ON ME01.ModuleId = M.Id
	INNER JOIN ModuleYesNo MYN ON MYN.ModuleId = M.Id
	LEFT JOIN YesNo YN ON YN.Id = MYN.YesNo01Id
	LEFT JOIN YesNo YN30 ON YN30.Id = MYN.YesNo30Id
	LEFT JOIN YesNo YN29 ON YN29.Id = MYN.YesNo29Id
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('' \ '', Id, [Text]) AS CoContributors
		FROM @coContributors
		WHERE moduleId = M.Id
	) AS CC
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('' \ '', Id, [Text]) AS Skills
		FROM @ACESSkill
		WHERE moduleId = M.Id
	) AS [AS]
	LEFT JOIN QFLevel QFL ON QFL.Id = MD.QfLevelId
	INNER JOIN StatusAlias SA ON SA.Id = M.StatusAliasId
	INNER JOIN MetaTemplate MT ON MT.MetaTemplateId = M.MetaTemplateId
WHERE MT.MetaTemplateTypeId in (36, 37) -- Program Review - Learning Outcomes Instructional
	AND SA.Id IN (
		1, --Active
		2, --Approved
		3, --Draft
		14 --In Review
	)
	AND M.[Active] = 1
ORDER BY M.Title, M.Id'
WHERE id = 6
UPDATE AdminReport
SET ReportSQL = 'DECLARE @checked NVARCHAR(MAX) = ''Yes'';
DECLARE @unchecked NVARCHAR(MAX) = ''No'';
DECLARE @separator NVARCHAR(MAX) = ''========================'' + CHAR(10);

--co contributors
DECLARE @coContributors TABLE (Id INT Identity, moduleId INT, [Text] NVARCHAR(MAX))

INSERT INTO @coContributors (moduleId, [Text])
SELECT ModuleId, CONCAT(U.LastName, '', '', U.FirstName)
FROM Module M
	INNER JOIN ModuleContributor MC ON MC.ModuleId = M.Id
	INNER JOIN [User] U ON U.Id = MC.UserId

--vip goals
DECLARE @VIPGoals TABLE (Id INT Identity, moduleId INT, [Text] NVARCHAR(MAX))

INSERT INTO @VIPGoals(moduleId, [Text])
SELECT MRM.ModuleId, 
	CONCAT(''VIP Goal: '', 
	MRM.MaxText01, CHAR(10), 
	''VIP Goal Status: '', 
	IT.Title, CHAR(10), 
	''Status of VIP Goal Report: '', 
	CHAR(10), MRM.MaxText02)
FROM Module M
	INNER JOIN ModuleRelatedModule MRM ON MRM.ModuleId = M.Id
	LEFT JOIN ItemType IT ON IT.Id = MRM.ItemTypeId

--query
SELECT 
	M.Id [Id to Delete]
	, concat(M.Title,'' ('',SA.Title,'')'') AS Title
	, CONCAT(U.LastName, '', '', U.FirstName) AS Originator
	, OES.Title AS School
	, OED.Title AS [Department/Area Name]
	, ME01.TextMax05 AS [Progarm Budget Code]
	, YN.Title AS [CTE Program]
	, CC.CoContributors AS [Co-Contributors]
	, QFL.Title AS [Type of PSR]
	, G.Goals AS [VIP Goals]
	, yn05.Title AS [Unexpected Faculty Requests]
	, ME01.Int01 AS [Number of faculty requested]
	, YN29.Title AS [Unexpected Staff request]
	, YN28.Title AS [Unexpected Resource request]
FROM Module M
	LEFT JOIN [User] U ON U.Id = M.UserId
	INNER JOIN ModuleDetail MD ON MD.ModuleId = M.Id
	LEFT JOIN OrganizationEntity OES ON OES.Id = MD.Tier1_OrganizationEntityId
	LEFT JOIN OrganizationEntity OED ON OED.Id = MD.Tier2_OrganizationEntityId
	INNER JOIN ModuleExtension01 ME01 ON ME01.ModuleId = M.Id
	INNER JOIN ModuleYesNo MYN ON MYN.ModuleId = M.Id
	LEFT JOIN YesNo YN ON YN.Id = MYN.YesNo01Id
	LEFT JOIN YesNo YN30 ON YN30.Id = MYN.YesNo30Id
	LEFT JOIN YesNo YN29 ON YN29.Id = MYN.YesNo29Id
	LEFT JOIN YesNo YN05 ON YN05.Id = MYN.YesNo05Id
	LEFT JOIN YesNo YN28 ON YN28.Id = MYN.YesNo28Id
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('' \ '', Id, [Text]) AS CoContributors
		FROM @coContributors
		WHERE moduleId = M.Id
	) AS CC
	OUTER APPLY (
	SELECT dbo.ConcatWithSepOrdered_Agg(@separator, Id, [Text]) AS Goals
	FROM @VIPGoals
	WHERE moduleId = M.Id
	) AS G
	LEFT JOIN QFLevel QFL ON QFL.Id = MD.QfLevelId
	INNER JOIN StatusAlias SA ON SA.Id = M.StatusAliasId
	INNER JOIN MetaTemplate MT ON MT.MetaTemplateId = M.MetaTemplateId
WHERE MT.MetaTemplateTypeId in (36, 37) -- Program Review - Learning Outcomes Instructional
	AND SA.Id IN (
		1, --Active
		2, --Approved
		3, --Draft
		14 --In Review
	)
	AND M.[Active] = 1
ORDER BY M.Title, M.Id'
WHERE id = 7
UPDATE AdminReport
SET ReportSQL = 'DECLARE @separator NVARCHAR(MAX) = ''========================'' + CHAR(10);

DECLARE @checked NVARCHAR(MAX) = ''Yes'';
DECLARE @unchecked NVARCHAR(MAX) = ''No'';

DECLARE @coContributors TABLE (Id INT Identity, moduleId INT, [Text] NVARCHAR(MAX))

INSERT INTO @coContributors (moduleId, [Text])
SELECT ModuleId, CONCAT(U.LastName, '', '', U.FirstName)
FROM Module M
	INNER JOIN ModuleContributor MC ON MC.ModuleId = M.Id
	INNER JOIN [User] U ON U.Id = MC.UserId

--Urgent Resource Request ordered list data
DECLARE @needCriteria TABLE (Id INT Identity, MRRId INT, [Text] NVARCHAR(MAX))
DECLARE @chaffeyGoals TABLE (Id INT Identity, MRRId INT, [Text] NVARCHAR(MAX))

INSERT INTO @needCriteria(MRRId, [Text])
SELECT MRRL.ModuleResourceRequestId, CONCAT(''-'', L.ShortText + CHAR(10) ) 
FROM ModuleResourceRequestLookup MRRL
	INNER JOIN Lookup01 L ON L.Id = MRRL.Lookup01Id

INSERT INTO @chaffeyGoals (MRRId, [Text])
SELECT MRRL.ModuleResourceRequestId, CONCAT(''-'', L.[Description] + CHAR(10) )
FROM ModuleResourceRequestLookup MRRL
	INNER JOIN Lookup05 L ON L.Id = MRRL.Lookup05Id


SELECT 
	 concat(M.Title,'' ('',SA.Title,'')'') AS Title
	, SA.Title AS [Proposal Status]
	, CONCAT(U.LastName, '', '', U.FirstName) AS Originator
	, OES.Title AS School
	, OED.Title AS [Department/Area Name]
	, ME01.TextMax05 AS [Progarm Budget Code]
	, YN.Title AS [CTE Program]
	, CC.CoContributors AS [Co-Contributors]
	, QFL.Title AS [Type of PSR]
	, YN05.Title AS [Unexpected full-time faculty requests?]
	, me01.iNT01 AS [Number of faculty requested]
	, MRR.MaxText03 AS [Program this request is for]
	, CONCAT(NC.[Text], CASE MRR.Bit01
							WHEN 1 THEN ''-Unexpected retirement or loss of faculty member'' END) AS [Need Criteria]
	, L.ShortText AS [Requested Tenure Track or Temporary Full-Time]
	, CASE 
		WHEN MRR.Bit02 = 1 OR MRR.Bit03 = 1 OR MRR.Bit04 = 1 OR LEN(MRR.ShortText01) > 0 
			THEN CONCAT(CASE MRR.Bit02 WHEN 1 THEN ''Rancho'' + CHAR(10) END,
						CASE MRR.Bit03 WHEN 1 THEN ''Chino'' + CHAR(10) END,
						CASE MRR.Bit04 WHEN 1 THEN ''Fontana'' + CHAR(10) END,
						CASE WHEN LEN(MRR.ShortText01) > 0 THEN CONCAT(''Other: '', MRR.ShortText01 + CHAR(10)) END)
		ELSE NULL
		END AS [Location of the requested staff position]
	, L2.ShortText AS [Type of faculty position]
	, dbo.stripHtml(MRR.MaxText01) AS [How the program will be adversely affected without the faculty position(s)]
	, CG.[Text] AS [Chaffey''s Goals]
FROM Module M
	LEFT JOIN [User] U ON U.Id = M.UserId
	INNER JOIN ModuleDetail MD ON MD.ModuleId = M.Id
	LEFT JOIN OrganizationEntity OES ON OES.Id = MD.Tier1_OrganizationEntityId
	LEFT JOIN OrganizationEntity OED ON OED.Id = MD.Tier2_OrganizationEntityId
	INNER JOIN ModuleExtension01 ME01 ON ME01.ModuleId = M.Id
	INNER JOIN ModuleYesNo MYN ON MYN.ModuleId = M.Id
	LEFT JOIN YesNo YN ON YN.Id = MYN.YesNo01Id
	LEFT JOIN YesNo YN30 ON YN30.Id = MYN.YesNo30Id
	LEFT JOIN YesNO YN05 ON YN05.Id = MYN.YesNo05Id
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('' \ '', Id, [Text]) AS CoContributors
		FROM @coContributors
		WHERE moduleId = M.Id
	) AS CC
	LEFT JOIN QFLevel QFL ON QFL.Id = MD.QfLevelId
	INNER JOIN StatusAlias SA ON SA.Id = M.StatusAliasId
	INNER JOIN MetaTemplate MT ON MT.MetaTemplateId = M.MetaTemplateId
	LEFT JOIN ModuleResourceRequest MRR ON MRR.ModuleId = M.Id
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('''', Id, [Text]) AS [Text]
		FROM @needCriteria NC
		WHERE NC.MRRId = MRR.Id
	) AS NC
	LEFT JOIN Lookup04 L ON L.Id = MRR.Lookup04Id_01
	LEFT JOIN Lookup04 L2 ON L2.Id = MRR.Lookup04Id_02
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('''', Id, [Text]) AS [Text]
		FROM @chaffeyGoals CG
		WHERE CG.MRRId = MRR.Id
	) AS CG
WHERE MT.MetaTemplateTypeId in (36, 37) -- Program Review - Learning Outcomes Instructional
	AND SA.Id IN (
		1, --Active
		2, --Approved
		3, --Draft
		14 --In Review
	)
	AND M.[Active] = 1
ORDER BY M.Title, MRR.SortOrder, M.Id'
WHERE id = 8
UPDATE AdminReport
SET ReportSQL = 'DECLARE @separator NVARCHAR(MAX) = ''========================'' + CHAR(10);

DECLARE @checked NVARCHAR(MAX) = ''Yes'';
DECLARE @unchecked NVARCHAR(MAX) = ''No'';

DECLARE @coContributors TABLE (Id INT Identity, moduleId INT, [Text] NVARCHAR(MAX))

INSERT INTO @coContributors (moduleId, [Text])
SELECT ModuleId, CONCAT(U.LastName, '', '', U.FirstName)
FROM Module M
	INNER JOIN ModuleContributor MC ON MC.ModuleId = M.Id
	INNER JOIN [User] U ON U.Id = MC.UserId

--Resource Request ordered list data
DECLARE @needCriteria TABLE (Id INT Identity, GOLId INT, [Text] NVARCHAR(MAX))
DECLARE @chaffeyGoals TABLE (Id INT Identity, GOLId INT, [Text] NVARCHAR(MAX))

INSERT INTO @needCriteria(GOLId, [Text])
SELECT GOLL.GenericOrderedList01Id, CONCAT(''-'', L.ShortText + CHAR(10), ''Explain: '' + CAST(GOLL.Rationale AS NVARCHAR(MAX)) + CHAR(10)) 
FROM GenericOrderedList01Lookup14 GOLL
	INNER JOIN Lookup01 L ON L.Id = GOLL.Lookup14Id
		AND L.ShortText IN (''Changes in state and/or federal guidelines'', 
							''Meet unexpected program demand or growth'', 
							''Fulfill a change in institutional strategic direction (e.g., workforce partner)'', 
							''Other'')

INSERT INTO @chaffeyGoals(GOLId, [Text])
SELECT GOLL.GenericOrderedList01Id, CONCAT(''-'', L.[Description] + CHAR(10), ''Explain: '' + CAST(GOLL.Rationale AS NVARCHAR(MAX)) + CHAR(10)) 
FROM GenericOrderedList01Lookup14 GOLL
	INNER JOIN Lookup05 L ON L.Id = GOLL.Lookup14Id


SELECT 
	concat(M.Title,'' ('',SA.Title,'')'') AS Title
	, CONCAT(U.LastName, '', '', U.FirstName) AS Originator
	, OES.Title AS School
	, OED.Title AS [Department/Area Name]
	, ME01.TextMax05 AS [Progarm Budget Code]
	, YN.Title AS [CTE Program]
	, CC.CoContributors AS [Co-Contributors]
	, QFL.Title AS [Type of PSR]
	, YN29.Title AS [Unexpected Staff request]
	, IT.Title AS [Staff Resource Request - Title ]
	, L.Title AS [Position Category]
	, CONCAT(NC.[Text], CASE GOL.Bit_01 WHEN 1 THEN ''-Unexpected retirement or loss of staff member'' END) 
		AS [Unexpected Need Criteria]
	, CASE 
		WHEN GOL.Bit_02 = 1 OR GOL.Bit_03 = 1 OR GOL.Bit_04 = 1 OR LEN(GOL.MaxText01) > 0
		THEN CONCAT(CASE GOL.Bit_02 WHEN 1 THEN ''Rancho'' + CHAR(10) END,
					CASE GOL.Bit_03 WHEN 1 THEN ''Chino'' + CHAR(10) END,
					CASE GOL.Bit_04 WHEN 1 THEN ''Fontana'' + CHAR(10) END,
					CASE WHEN LEN(GOL.MaxText01) > 0 THEN CONCAT(''Other: '', GOL.MaxText01) END)
		ELSE NULL END AS [Location]
	, CASE YNGOL.Title
		WHEN ''Yes'' THEN ''Instructional''
		WHEN ''No'' THEN ''Non-Instructional''
		ELSE NULL END AS [Type Position]
	, CASE YNGOL2.Title
		WHEN ''Yes'' THEN ''Full-Time (1.0)''
		WHEN ''No'' THEN ''Part-Time (0.475)''
		ELSE NULL END AS [Full-time or part-time]
	, GOL.Int02 AS [# of hours for the year]
	, dbo.stripHtml(MaxText02) AS [How program/area will be adversely affected without the staff position(s)]
	, CG.[Text] AS [Chaffey''s Goals]
FROM Module M
	LEFT JOIN [User] U ON U.Id = M.UserId
	INNER JOIN ModuleDetail MD ON MD.ModuleId = M.Id
	LEFT JOIN OrganizationEntity OES ON OES.Id = MD.Tier1_OrganizationEntityId
	LEFT JOIN OrganizationEntity OED ON OED.Id = MD.Tier2_OrganizationEntityId
	INNER JOIN ModuleExtension01 ME01 ON ME01.ModuleId = M.Id
	INNER JOIN ModuleYesNo MYN ON MYN.ModuleId = M.Id
	LEFT JOIN YesNo YN ON YN.Id = MYN.YesNo01Id
	LEFT JOIN YesNo YN29 ON YN29.Id = MYN.YesNo29Id
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('' \ '', Id, [Text]) AS CoContributors
		FROM @coContributors
		WHERE moduleId = M.Id
	) AS CC
	LEFT JOIN QFLevel QFL ON QFL.Id = MD.QfLevelId
	INNER JOIN StatusAlias SA ON SA.Id = M.StatusAliasId
	INNER JOIN MetaTemplate MT ON MT.MetaTemplateId = M.MetaTemplateId
	LEFT JOIN GenericOrderedList01 GOL ON GOL.ModuleId = M.Id
	LEFT JOIN ItemType IT ON IT.Id = GOL.ItemTypeId
	LEFT JOIN Lookup14 L ON L.Id = GOL.Lookup14Id
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('''', Id, [Text]) AS [Text]
		FROM @needCriteria NC
		WHERE NC.GOLId = GOL.Id
	) AS NC	
	LEFT JOIN YesNo YNGOL ON YNGOL.Id = GOL.YesNo01Id
	LEFT JOIN YesNo YNGOL2 ON YNGOL2.Id = GOL.YesNo02Id
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('''', Id, [Text]) AS [Text]
		FROM @chaffeyGoals CG
		WHERE CG.GOLId = GOL.Id
	) AS CG	
WHERE MT.MetaTemplateTypeId in (36, 37) -- Program Review - Learning Outcomes Instructional
		AND SA.Id IN (
			1, --Active
			2, --Approved
			3, --Draft
			14 --In Review
		)
		AND M.[Active] = 1
ORDER BY M.Title, GOL.SortOrder, M.Id'
WHERE id = 9
UPDATE AdminReport
SET ReportSQL = 'DECLARE @checked NVARCHAR(MAX) = ''Yes'';
DECLARE @unchecked NVARCHAR(MAX) = ''No'';
DECLARE @separator NVARCHAR(MAX) = ''========================'' + CHAR(10);

DECLARE @coContributors TABLE (Id INT Identity, moduleId INT, [Text] NVARCHAR(MAX))

INSERT INTO @coContributors (moduleId, [Text])
SELECT ModuleId, CONCAT(U.LastName, '', '', U.FirstName)
FROM Module M
	INNER JOIN ModuleContributor MC ON MC.ModuleId = M.Id
	INNER JOIN [User] U ON U.Id = MC.UserId

--Resource Request ordered list data
DECLARE @needCriteria TABLE (Id INT Identity, GOLId INT, [Text] NVARCHAR(MAX))
DECLARE @chaffeyGoals TABLE (Id INT Identity, GOLId INT, [Text] NVARCHAR(MAX))

INSERT INTO @needCriteria(GOLId, [Text])
SELECT GOLL.GenericOrderedList03Id, CONCAT(''-'', L.ShortText + CHAR(10), ''Explain: '' + CAST(GOLL.Rational AS NVARCHAR(MAX)) + CHAR(10)) 
FROM GenericOrderedList03YearLookup GOLL
	INNER JOIN Lookup01 L ON L.Id = GOLL.YearLookupId - 1980
		AND L.ShortText IN (''Changes in state and/or federal guidelines'', 
							''Meet unexpected program demand or growth'', 
							''Fulfill a change in institutional strategic direction (e.g., workforce partner)'', 
							''Other'')

INSERT INTO @chaffeyGoals(GOLId, [Text])
SELECT GOLL.GenericOrderedList03Id, CONCAT(''-'', L.[Description] + CHAR(10), ''Explain: '' + CAST(GOLL.Rational AS NVARCHAR(MAX)) + CHAR(10) ) 
FROM GenericOrderedList03YearLookup GOLL
	INNER JOIN Lookup05 L ON L.Id = GOLL.YearLookupId - 2000

SELECT 
	concat(M.Title,'' ('',SA.Title,'')'') AS Title
	, CONCAT(U.LastName, '', '', U.FirstName) AS Originator
	, OES.Title AS School
	, OED.Title AS [Department/Area Name]
	, ME01.TextMax05 AS [Progarm Budget Code]
	, YN.Title AS [CTE Program]
	, CC.CoContributors AS [Co-Contributors]
	, QFL.Title AS [Type of PSR]
	, YN28.Title AS [Unexpected Resource Request]
	, GOL.MaxText01 AS [Description of the item]
	, GOL.MaxText02 AS [Estimated Cost]
	, NC.[Text] AS [Unexpected Need Criteria]
	, GOL.MaxText03 AS [How the resource will impact studet, program, or department performance]
	, CG.[Text] AS [Chaffey''s Goals]
FROM Module M
	LEFT JOIN [User] U ON U.Id = M.UserId
	INNER JOIN ModuleDetail MD ON MD.ModuleId = M.Id
	LEFT JOIN OrganizationEntity OES ON OES.Id = MD.Tier1_OrganizationEntityId
	LEFT JOIN OrganizationEntity OED ON OED.Id = MD.Tier2_OrganizationEntityId
	INNER JOIN ModuleExtension01 ME01 ON ME01.ModuleId = M.Id
	INNER JOIN ModuleYesNo MYN ON MYN.ModuleId = M.Id
	LEFT JOIN YesNo YN ON YN.Id = MYN.YesNo01Id
	LEFT JOIN YesNo YN28 ON YN28.Id = MYN.YesNo28Id
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('' \ '', cc.Id, [Text]) AS CoContributors
		FROM @coContributors cc
		WHERE cc.moduleId = M.Id
	) AS CC
	LEFT JOIN QFLevel QFL ON QFL.Id = MD.QfLevelId
	INNER JOIN StatusAlias SA ON SA.Id = M.StatusAliasId
	INNER JOIN MetaTemplate MT ON MT.MetaTemplateId = M.MetaTemplateId
	LEFT JOIN GenericOrderedList03 GOL ON GOL.ModuleId = M.Id
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('''', NC.Id, [Text]) AS [Text]
		FROM @needCriteria NC
		WHERE NC.GOLId = GOL.Id
	) AS NC
	OUTER APPLY (
		SELECT dbo.ConcatWithSepOrdered_Agg('''', CG.Id, [Text]) AS [Text]
		FROM @chaffeyGoals CG
		WHERE CG.GOLId = GOL.Id
	) AS CG	
WHERE MT.MetaTemplateTypeId in (36, 37) -- Program Review - Learning Outcomes Instructional
	AND SA.Id IN (
		1, --Active
		2, --Approved
		3, --Draft
		14 --In Review
	)
	AND M.[Active] = 1
ORDER BY M.Title, GOL.SortOrder, M.Id'
WHERE id = 10