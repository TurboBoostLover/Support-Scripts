USE [hancockcollege];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19649';
DECLARE @Comments nvarchar(Max) = 
	'Update Look up Value for Lab type';
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
DECLARE @NewIds TABLE (Sort INT, MissingValue INT);
INSERT INTO @NewIds  
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 2;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		--Create more Variables here using Sort if needed
DECLARE @MAX2 int = (SELECT MissingValue FROM @NewIds WHERE Sort = 2)

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
declare @now datetime = getdate(); 

select [Id] as Value,
Title as Text
from [GordonImplementType] 
where @now between StartDate
and IsNull(EndDate, @now) 
AND ClientId = @clientId

Order By SortOrder
"

DECLARE @RSQL NVARCHAR(MAX) = "
select Title as Text from [GordonImplementType] where Id = @Id
"

DECLARE @CSQL2 NVARCHAR(MAX) = "
declare @now datetime = getdate();
select [Id] as Value,
Title as Text
from [GordonImplementType]
where @now between StartDate 
and IsNull(EndDate, @now) 
AND ClientId = @clientId
AND Title not in ('NC')
Order By SortOrder
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'GordonImplementType', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Lab Type', 1),
(@MAX2, 'GordonImplementType', 'Id', 'Title', @CSQL2, @RSQL, 'Order By SortOrder', 'Lab Type', 1)

INSERT INTO GordonImplementType
(Title, SortOrder, ClientId, StartDate)
VALUES
('NC', 5, 1, GETDATE())

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaSelectedFieldId in (
	SELECT msf.MEtaSElectedfieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId in (
		8, 9 ,39		--noncredit
	)
	and msf.MetaAvailableFieldId = 1397
)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX2
WHERE MetaSelectedFieldId in (
	SELECT msf.MEtaSElectedfieldId FROM MetaSelectedField AS msf
	INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	INNER JOIN MetaTemplate AS mt on mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaTemplateType AS mtt on mt.MetaTemplateTypeId = mtt.MetaTemplateTypeId
	WHERE mtt.MetaTemplateTypeId in (
		35, 7, 4, 1		--credit
	)
	and msf.MetaAvailableFieldId = 1397
)

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaAvailableFieldId = 1397
and mt.MetaTemplateTypeId in (
	1, 4, 7, 8, 9, 35, 39
)