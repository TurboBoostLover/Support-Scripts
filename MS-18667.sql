USE [sdccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18667';
DECLARE @Comments nvarchar(Max) = 
	'Update Catalog Presentation of PRogram Outcomes to be correct order';
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
UPDATE OutputModelClient
SET ModelQuery = '
DECLARE @entityList_internal TABLE (
	InsertOrder INT IDENTITY (1, 1) PRIMARY KEY,
	ProgramId INT
	);

INSERT INTO @entityList_internal (ProgramId)
SELECT el.Id FROM @entityList el;

DECLARE @entityRootData TABLE (
	ProgramId			INT PRIMARY KEY,
	CatalogDescription	NVARCHAR(MAX), 
	AwardNotes			NVARCHAR(MAX),
	ProgramOutcomes		NVARCHAR(MAX)
	)

DECLARE @AwardNotesQueryString NVARCHAR(MAX) = 
	(SELECT CustomSql FROM MetaForeignKeyCriteriaClient WHERE Id = 2884);

INSERT INTO @entityRootData
SELECT 
	p.Id, 
	p.Description AS Description, 
	CASE WHEN awn.SerializationSuccess = 1 AND QuerySuccess = 1
		 THEN sfr.[Text] ELSE ''(Something went wrong)''
	END AS AwardNotes,
	plo.Text
FROM Program p
	INNER JOIN @entityList_internal eli ON p.Id = eli.ProgramId
CROSS APPLY (
    SELECT STRING_AGG(CONCAT(''<li>'', po.Outcome, ''</li>''), '''')
           WITHIN GROUP (ORDER BY po.SortOrder) AS Text
    FROM ProgramOutcome po 
    WHERE po.ProgramId = p.Id
) plo
	OUTER APPLY dbo.fnBulkResolveResolutionSqlQuery(
		@AwardNotesQueryString, 
		1, 
		p.Id, 
		CONCAT(
			''['',
			dbo.fnGenerateBulkResolveQueryParameter(''@entityId'', p.Id, ''int''), 
			'']''
			)
	) awn
	OUTER APPLY OPENJSON(awn.SerializedFullRow)
	WITH (
		[Value] INT			  ''$.Value'',
		[Text]  NVARCHAR(MAX) ''$.Text''
		) sfr

SELECT eli.ProgramId AS Id, m.Model FROM @entityList_internal eli
	CROSS APPLY (
		SELECT (
			SELECT erd.CatalogDescription, erd.AwardNotes, erd.ProgramOutcomes
			FROM @entityRootData erd WHERE erd.ProgramId = eli.ProgramId
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
		) RootData
	) erd
	CROSS APPLY (
		SELECT (
			SELECT eli.InsertOrder, JSON_QUERY(erd.RootData) AS RootData
			FOR JSON PATH
			) Model
		) m
'
WHERE Id = 9