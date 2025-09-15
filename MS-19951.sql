USE [rccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19951';
DECLARE @Comments nvarchar(Max) = 
	'Update Course Req dop down to not null out selected option';
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
EXEC spGetMissingOrMaxIdentityValues 'MetaForeignKeyCriteriaClient', 'Id', 1;		--This 10 here is the amount of Id's it grabs

DECLARE @MAX int = (SELECT MissingValue FROM @NewIds WHERE Sort = 1)		--Create more Variables here using Sort if needed

SET QUOTED_IDENTIFIER OFF

DECLARE @CSQL NVARCHAR(MAX) = "
select c.Id as Value,
s.SubjectCode + ' ' + c.CourseNumber + ' - ' + c.Title + ' (' + sa.Title + ')' as Text 
from Course c inner join [Subject] s on s.Id = c.SubjectId
inner join StatusAlias sa on sa.Id = c.StatusAliasId
where c.ClientId = @clientId
and c.Active = 1 
and c.SubjectId = @subjectId 
and sa.StatusBaseId in(1, 2, 4, 6) 
UNION
select c.Id as Value,
s.SubjectCode + ' ' + c.CourseNumber + ' - ' + c.Title + ' (' + sa.Title + ')' as Text 
from Course c inner join [Subject] s on s.Id = c.SubjectId
inner join StatusAlias sa on sa.Id = c.StatusAliasId
where c.ClientId = @clientId
and c.Active = 1 
and c.Id in (
	SELECT Requisite_CourseId FROM CourseRequisite WHERE CourseId = @Entityid
)
order by Text
"

DECLARE @RSQL NVARCHAR(MAX) = "
select s.SubjectCode + ' ' + c.CourseNumber + ' - ' + c.Title + ' (' + sa.Title + ')' as Text
from Course c
inner join [Subject] s on s.Id = c.SubjectId 
inner join StatusAlias sa on sa.Id = c.StatusAliasId
where c.Id = @id
"

SET QUOTED_IDENTIFIER ON

INSERT INTO MetaForeignKeyCriteriaClient
(Id, TableName, DefaultValueColumn, DefaultDisplayColumn, CustomSql, ResolutionSql, DefaultSortColumn, Title, LookupLoadTimingType)
VALUES
(@MAX, 'Course', 'Id', 'Title', @CSQL, @RSQL, 'Order By SortOrder', 'Active, Pending, Approved, In Review Courses and selected', 3)

UPDATE MetaSelectedField
SET MetaForeignKeyLookupSourceId = @MAX
WHERE MetaAvailableFieldId = 298
and MetaForeignKeyLookupSourceId IS NULL

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = @MAX

UPDATE CourseRequisite
SET Requisite_CourseId = 14602
WHERE Id = 8264