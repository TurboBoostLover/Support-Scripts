USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19504';
DECLARE @Comments nvarchar(Max) = 
	'Fix look up data in Min Qual since client added a lot of garbage and then clean up drop down where values display';
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
UPDATE MinimumQualification
SET Title = 'with a BA in Psychology or Sociology'
WHERE Id = 250

UPDATE CourseMinimumQualification
SET MinimumQualificationId = NULL
WHERE MinimumQualificationId in (
	SELECT Id FROM MinimumQualification WHERE Title IS NULL
)

DELETE MinimumQualification
WHERE Title IS NULL
OR LEN(TITLE) < 2

update mq 
set SortOrder = sorted.rownum 
from MinimumQualification mq
inner join ( 
select id, ROW_NUMBER() over (order by Title) rownum 
from MinimumQualification 
WHERE Title IS NOT NULL
) sorted on mq.Id = sorted.Id

DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 1;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		--Create more Variables here using Sort if needed

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
select [Id] as [Value], (Title + case when MastersRequired = 0 then '' else ' (Masters Required)' end) as [Text] 
from [MinimumQualification] 
where Active = 1 
and ([ClientId] = @clientId) 
Order By Title
"

DECLARE @RSQL NVARCHAR(MAX) = "
select (Title + case when MastersRequired = 0 then '' else ' (Masters Required)' end) as [Text] 
from [MinimumQualification]  
where [Id] = @Id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'MinimumQualification', 'Id', 'Title + case when MastersRequired = 0 then '' else '' (Masters Required)'' end', @CSQL, @RSQL, 'Order By SortOrder', 'MinimumQualification', 1)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaAvailableFieldId = 1435
and MetaForeignKeyLookupSourceId IS NULL

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @MAX