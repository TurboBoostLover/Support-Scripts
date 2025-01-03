USE master;

-- COMMIT
-- ROLLBACK

SET XACT_ABORT ON 
--SELECT @@servername AS 'Server Name' ,DB_NAME() AS 'Database Name'

BEGIN TRAN
BEGIN TRY

DECLARE @base TABLE (dbName NVARCHAR(MAX), query NVARCHAR(MAX));
INSERT INTO @base 
SELECT [name], 
'
' AS sqlText
FROM master.dbo.sysdatabases 
WHERE 
	name NOT IN ('master','model','msdb','tempdb','ELMAH','GlobalConfig','CUIQSSOLIVETEST') 
	and version != 0 
AND [name] not  LIKE '%_Old'
ORDER BY name

-- read file
CREATE TABLE #fileContent (content NVARCHAR(MAX))
-- BULK INSERT #fileContent
-- FROM 'C:\Users\AndrewEmrick\Desktop\Scripts\searchTemplate.sql'
-- WITH ( 
-- 	CODEPAGE= 65001, -- UTF-8 encoding
-- 	ROWTERMINATOR = ''
-- ); 



UPDATE @base
--for running this from a query
SET query = ( '
Print (DB_NAME())
DECLARE @JiraTicketNumber nvarchar(20) = ''MS-14971'';
DECLARE @Comments nvarchar(Max) = 
	''Update Bad look up timing types'';
DECLARE @Developer nvarchar(50) = ''Nathan Westergard'';
DECLARE @ScriptTypeId int = 1;


SELECT
 @@servername AS ''Server Name'' 
,DB_NAME() AS ''Database Name''
,@JiraTicketNumber as ''Jira Ticket Number'';

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
DROP TABLE IF EXISTS #Nate;

SELECT
    pt.Title AS [Proposal Type],
    mss.SectionName AS [Section Name],
    msf.DisplayName AS [Field Name],
    mfkcc.Id AS [Look up Id]
INTO #Nate
FROM ProposalType AS pt
INNER JOIN MetaTemplateType AS mtt on pt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
INNER JOIN MetaTemplate AS mt on mt.MetaTemplateTypeId= mtt.MetaTemplateTypeId
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
LEFT JOIN MetaSelectedSection AS mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
INNER JOIN MetaSelectedFieldAttribute AS msfa on msfa.MetaSelectedFieldId = msf.MetaSelectedFieldId
INNER JOIN MetaForeignKeyCriteriaClient AS mfkcc on msf.MetaForeignKeyLookupSourceId = mfkcc.Id
WHERE mfkcc.LookupLoadTimingType = 3
AND mss.MetaSelectedSectionId in (
    SELECT DISTINCT MetaSelectedSectionId FROM MetaSelectedSectionAttribute WHERE Name = ''FilterSubscriptionTable''
);

UPDATE MetaForeignKeyCriteriaClient
SeT LookupLoadTimingType = 2
WHERE Id in (
	SELECT DISTINCT Id FROM #Nate
)

DROP TABLE #Nate;

COMMIT') --if not reading from a file

--for running this from a file
--SET query = (SELECT TOP 1 Content FROM #fileContent)

DROP TABLE #fileContent

-- ====================
-- interface implementation
-- ====================
-- interface dbName, query
DECLARE @container TABLE (Id INT IDENTITY(1, 1), dbName NVARCHAR(MAX), query NVARCHAR(MAX), queryRdyForExec NVARCHAR(MAX));
INSERT INTO @container (dbName, query)
SELECT b.dbName, b.query
FROM @base b

UPDATE b
SET queryRdyForExec = 'use [' + b.dbName + '];' + b.query
FROM @container b

DECLARE @currId INT = (SELECT MIN(Id) FROM @container)
DECLARE @dbName NVARCHAR(MAX) = '';
DECLARE @sql NVARCHAR(MAX) = '';

WHILE (@currId <= (SELECT MAX(Id) FROM @container))
BEGIN
	SET @dbName = (SELECT dbName FROM @container WHERE Id = @currId);
	SET @sql = (SELECT queryRdyForExec FROM @container WHERE Id = @currId);
	DECLARE @procBody NVARCHAR(MAX) = (SELECT query FROM @container WHERE Id = @currId);
	EXEC sp_executesql  @sql;
	--PRINT '============================= [ START ] ======================================';
	--PRINT @sql;

	SET @currId = @currId + 1;
END

COMMIT		-- disable this for support
END TRY
BEGIN CATCH
	--PRINT '============================= [ Rolling back ] ======================================';
	--PRINT 'Database: [' + @dbName + ']'; 
	--PRINT 'Query :';
	--PRINT  @sql;
	ROLLBACK; -- disable this for support
	THROW; -- will stop execution
END CATCH

