USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15396';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Narrative Report';
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
SET CustomSql = 'DECLARE @Colleges TABLE (txt nvarchar(max), programId INT)
INSERT INTO @Colleges
SELECT CONCAT(''<li>'', MaxText01, '' - '', MaxText02, '' - '', MaxText03, '' - '', MaxText04), ProgramId FROM GenericOrderedList01 AS gl
WHERE gl.ProgramId = @EntityId

SELECT 
    0 AS Value,
    CONCAT(
        ''<b>Mission Statement: </b>'', COALESCE(pd.MasterPlanning, ''''),
        ''<br>'', ''<b>Completer Projections: </b>'', COALESCE(CAST(p.EleQuart AS VARCHAR), ''''),
        ''<br>'', ''<b>Annual Enrollment: </b>'', COALESCE(p.Accreditation, ''''),
        ''<br>'', ''<b>Sufficient Number of Students: </b>'', COALESCE(p.PlaceProgram, ''''),
        ''<br>'', ''<b>Place of program in curriculum/similar programs at college: </b>'', COALESCE(mt.TextMax12, ''''),
        ''<br>'', ''<b>Similar programs at other colleges in service area: </b>'', COALESCE(
            CONCAT(''<ul>'', 
                dbo.ConcatWithSep_Agg(''<br>'', c.txt) ,
            ''</ul>''), 
        '''')
    ) AS Text
FROM 
    Program AS p
    INNER JOIN ProgramDetail AS pd ON pd.ProgramId = p.Id
    LEFT JOIN GenericMaxText AS mt ON mt.ProgramId = p.Id
    LEFT JOIN @Colleges AS c ON c.ProgramId = p.Id
WHERE 
    p.Id = @EntityId
group by pd.MasterPlanning, p.EleQuart, p.Accreditation, p.PlaceProgram, mt.TextMax12'
, ResolutionSql = 'DECLARE @Colleges TABLE (txt nvarchar(max), programId INT)
INSERT INTO @Colleges
SELECT CONCAT(''<li>'', MaxText01, '' - '', MaxText02, '' - '', MaxText03, '' - '', MaxText04), ProgramId FROM GenericOrderedList01 AS gl
WHERE gl.ProgramId = @EntityId

SELECT 
    0 AS Value,
    CONCAT(
        ''<b>Mission Statement: </b>'', COALESCE(pd.MasterPlanning, ''''),
        ''<br>'', ''<b>Completer Projections: </b>'', COALESCE(CAST(p.EleQuart AS VARCHAR), ''''),
        ''<br>'', ''<b>Annual Enrollment: </b>'', COALESCE(p.Accreditation, ''''),
        ''<br>'', ''<b>Sufficient Number of Students: </b>'', COALESCE(p.PlaceProgram, ''''),
        ''<br>'', ''<b>Place of program in curriculum/similar programs at college: </b>'', COALESCE(mt.TextMax12, ''''),
        ''<br>'', ''<b>Similar programs at other colleges in service area: </b>'', COALESCE(
            CONCAT(''<ul>'', 
                dbo.ConcatWithSep_Agg(''<br>'', c.txt) ,
            ''</ul>''), 
        '''')
    ) AS Text
FROM 
    Program AS p
    INNER JOIN ProgramDetail AS pd ON pd.ProgramId = p.Id
    LEFT JOIN GenericMaxText AS mt ON mt.ProgramId = p.Id
    LEFT JOIN @Colleges AS c ON c.ProgramId = p.Id
WHERE 
    p.Id = @EntityId
group by pd.MasterPlanning, p.EleQuart, p.Accreditation, p.PlaceProgram, mt.TextMax12'
WHERE Id = 2852

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mt.MetaTemplateId FROM MetaTemplate As mt
	INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 2852
)