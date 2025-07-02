USE [chabot];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18314';
DECLARE @Comments nvarchar(Max) = 
	'Fix CB Validation';
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
SET CustomSql = '
declare @cb22 nvarchar(5) = (
	SELECT
		cb.Code
	FROM CourseCBCode ccc
		INNER JOIN CB22 cb ON ccc.CB22Id = cb.Id
	WHERE ccc.CourseId = @entityId
)
, @topCodVocational BIT = (
	SELECT
		cb.Vocational
	FROM CourseCBCode ccc
		INNER JOIN CB03 cb ON ccc.CB03Id = cb.Id
	WHERE ccc.CourseId = @entityId
);
    declare @conditionSql nvarchar(max),    @finalSql nvarchar(max);
SET @conditionSql = (
	SELECT
		CASE
			WHEN @cb22 IS NOT NULL AND
				@cb22 = ''I'' THEN ''cb.Code in (''''A'''', ''''B'''', ''''C'''', ''''D'''')''
			WHEN @topCodVocational = 1 THEN ''cb.Code in (''''A'''', ''''B'''', ''''C'''', ''''D'''')''
			WHEN @topCodVocational = 0 THEN ''cb.Code in (''''E'''', ''''D'''')''
			ELSE ''1 = 1''
		END
);
SET @finalSql = ''select cb.Id as Value, cb.Code + '''' - '''' + cb.Description as Text  from CB09 cb  where cb.Active = 1  and '' + @conditionSql + ''  order by cb.SortOrder;'';
EXEC sys.sp_executesql @finalSql
					  ,N''@conditionSql nvarchar(max)''
					  ,@conditionSql;
'
WHERE Id = 290

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 290