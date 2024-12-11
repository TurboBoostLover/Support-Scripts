USE [gavilan];

/*
   Commit
                    Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13773';
DECLARE @Comments nvarchar(Max) = 'Removed "Goals and Resource Report" reports and added proposal type to "Program Review Goals" report';
DECLARE @Developer nvarchar(50) = 'Brenton Trebilcock/Nathan Westergard';
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

INSERT INTO History.ScriptsRunOnDatabase
(TicketNumber,Developer,Comments,ScriptTypeId)
VALUES
(@JiraTicketNumber, @Developer, @Comments, @ScriptTypeId); 

-----------------Script details go below this line------------------

-- Removing from admin report client, so the reports still exist if needed in the future
DELETE FROM AdminReportClient
WHERE AdminReportId IN (4, 5)

SET QUOTED_IDENTIFIER OFF;

-- add proposal type to the Program Review Goals report
DECLARE @reportSql NVARCHAR(max) = "
DECLARE @Table Table (id int, Connects nvarchar(max), fund nvarchar(max))
insert into @Table
SELECT ModuleId,
CAST(dbo.stripHtml (dbo.regex_replace(ConnectionToMissionStatement, N'['+nchar(8203)+N']', N'')) AS NVARCHAR(MAX)),
CAST(dbo.stripHtml (dbo.regex_replace(FundAmountRequested, N'['+nchar(8203)+N']', N'')) AS NVARCHAR(MAX))
FROM ModuleGoal
WHERE Active = 1

UPDATE @TABLE SET Connects = replace(Connects, '&rsquo;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&#39;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&nbsp;' collate Latin1_General_CS_AS, ' '  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&amp;' collate Latin1_General_CS_AS, '&'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&quot;' collate Latin1_General_CS_AS, '""'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&euro;' collate Latin1_General_CS_AS, '€'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&lt;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&gt;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&oelig;' collate Latin1_General_CS_AS, 'oe'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&copy;' collate Latin1_General_CS_AS, '©'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&laquo;' collate Latin1_General_CS_AS, '«'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&reg;' collate Latin1_General_CS_AS, '®'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&plusmn;' collate Latin1_General_CS_AS, '±'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&sup2;' collate Latin1_General_CS_AS, '²'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&sup3;' collate Latin1_General_CS_AS, '³'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&micro;' collate Latin1_General_CS_AS, 'µ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&middot;' collate Latin1_General_CS_AS, '·'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&ordm;' collate Latin1_General_CS_AS, 'º'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&raquo;' collate Latin1_General_CS_AS, '»'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&frac14;' collate Latin1_General_CS_AS, '¼'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&frac12;' collate Latin1_General_CS_AS, '½'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&frac34;' collate Latin1_General_CS_AS, '¾'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&Aelig' collate Latin1_General_CS_AS, 'Æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&Ccedil;' collate Latin1_General_CS_AS, 'Ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&Egrave;' collate Latin1_General_CS_AS, 'È'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&Eacute;' collate Latin1_General_CS_AS, 'É'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&Ecirc;' collate Latin1_General_CS_AS, 'Ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&Ouml;' collate Latin1_General_CS_AS, 'Ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&agrave;' collate Latin1_General_CS_AS, 'à'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&acirc;' collate Latin1_General_CS_AS, 'â'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&auml;' collate Latin1_General_CS_AS, 'ä'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&aelig;' collate Latin1_General_CS_AS, 'æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&ccedil;' collate Latin1_General_CS_AS, 'ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&egrave;' collate Latin1_General_CS_AS, 'è'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&eacute;' collate Latin1_General_CS_AS, 'é'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&ecirc;' collate Latin1_General_CS_AS, 'ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&euml;' collate Latin1_General_CS_AS, 'ë'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&icirc;' collate Latin1_General_CS_AS, 'î'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&ocirc;' collate Latin1_General_CS_AS, 'ô'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&ouml;' collate Latin1_General_CS_AS, 'ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&divide;' collate Latin1_General_CS_AS, '÷'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&oslash;' collate Latin1_General_CS_AS, 'ø'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&ugrave;' collate Latin1_General_CS_AS, 'ù'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&uacute;' collate Latin1_General_CS_AS, 'ú'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&ucirc;' collate Latin1_General_CS_AS, 'û'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&uuml;' collate Latin1_General_CS_AS, 'ü'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&lsaquo;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET Connects = replace(Connects, '&rsaquo;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)
------------------------------------------------------------------------------------------------------------------------------------------
UPDATE @TABLE SET fund = replace(fund, '&rsquo;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&#39;' collate Latin1_General_CS_AS, ''''  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&nbsp;' collate Latin1_General_CS_AS, ' '  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&amp;' collate Latin1_General_CS_AS, '&'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&quot;' collate Latin1_General_CS_AS, '""'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&euro;' collate Latin1_General_CS_AS, '€'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&lt;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&gt;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&oelig;' collate Latin1_General_CS_AS, 'oe'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&copy;' collate Latin1_General_CS_AS, '©'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&laquo;' collate Latin1_General_CS_AS, '«'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&reg;' collate Latin1_General_CS_AS, '®'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&plusmn;' collate Latin1_General_CS_AS, '±'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&sup2;' collate Latin1_General_CS_AS, '²'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&sup3;' collate Latin1_General_CS_AS, '³'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&micro;' collate Latin1_General_CS_AS, 'µ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&middot;' collate Latin1_General_CS_AS, '·'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&ordm;' collate Latin1_General_CS_AS, 'º'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&raquo;' collate Latin1_General_CS_AS, '»'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&frac14;' collate Latin1_General_CS_AS, '¼'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&frac12;' collate Latin1_General_CS_AS, '½'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&frac34;' collate Latin1_General_CS_AS, '¾'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&Aelig' collate Latin1_General_CS_AS, 'Æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&Ccedil;' collate Latin1_General_CS_AS, 'Ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&Egrave;' collate Latin1_General_CS_AS, 'È'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&Eacute;' collate Latin1_General_CS_AS, 'É'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&Ecirc;' collate Latin1_General_CS_AS, 'Ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&Ouml;' collate Latin1_General_CS_AS, 'Ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&agrave;' collate Latin1_General_CS_AS, 'à'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&acirc;' collate Latin1_General_CS_AS, 'â'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&auml;' collate Latin1_General_CS_AS, 'ä'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&aelig;' collate Latin1_General_CS_AS, 'æ'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&ccedil;' collate Latin1_General_CS_AS, 'ç'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&egrave;' collate Latin1_General_CS_AS, 'è'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&eacute;' collate Latin1_General_CS_AS, 'é'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&ecirc;' collate Latin1_General_CS_AS, 'ê'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&euml;' collate Latin1_General_CS_AS, 'ë'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&icirc;' collate Latin1_General_CS_AS, 'î'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&ocirc;' collate Latin1_General_CS_AS, 'ô'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&ouml;' collate Latin1_General_CS_AS, 'ö'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&divide;' collate Latin1_General_CS_AS, '÷'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&oslash;' collate Latin1_General_CS_AS, 'ø'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&ugrave;' collate Latin1_General_CS_AS, 'ù'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&uacute;' collate Latin1_General_CS_AS, 'ú'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&ucirc;' collate Latin1_General_CS_AS, 'û'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&uuml;' collate Latin1_General_CS_AS, 'ü'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&lsaquo;' collate Latin1_General_CS_AS, '<'  collate Latin1_General_CS_AS)
UPDATE @TABLE SET fund = replace(fund, '&rsaquo;' collate Latin1_General_CS_AS, '>'  collate Latin1_General_CS_AS)

SELECT
	  m.Title AS [Title]
    , pt.Title AS [Proposal Type]
	, sa.Title AS [Status]
	, s.Title AS [Semester]
	, mg.Goal AS [Goal]
	, t.Connects AS [Connection of Goal to Mission Statement]
	, mg.PlanToAchieveGoal AS [Plan to Achieve Goal]
	, mg.ResponsibleParty AS [Responsible Party]
	, t.fund AS [Fund Amount Requested]
	, mg.ResourceAllocation AS [Total Resource Allocation Request]
	, mg.Timeline AS [Timeline to Completion]
	, mg.EvaluationPlan AS [Evaluation Method]

FROM Module AS m
    INNER JOIN ProposalType pt ON pt.Id = m.ProposalTypeId
	INNER JOIN Modulegoal AS mg ON mg.ModuleId = m.Id
	INNER JOIN StatusAlias AS sa ON m.StatusAliasId = sa.Id
	INNER JOIN ModuleDetail AS md ON md.ModuleId = m.Id
	INNER JOIN Semester AS s on s.Id = md.AcademicYear_SemesterId
	INNER JOIN @Table AS t ON t.id = m.Id
WHERE m.Active = 1
ORDER BY m.Id
"

SET QUOTED_IDENTIFIER ON;

UPDATE AdminReport
    SET ReportSQL = @reportSql
WHERE Id = 6