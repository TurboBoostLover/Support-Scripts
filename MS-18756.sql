USE [palomar];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18756';
DECLARE @Comments nvarchar(Max) = 
	'Update Query text';
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
DECLARE @Id int = 266

DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @description VARCHAR(Max) = (Select Description from course where id = @entityid); 
DECLARE @descriptionPart2 VARCHAR(Max) = (Select TextMax01 from GenericMaxText where courseid = @entityid);
select 
	0 as Value,
	case 
		when @descriptionPart2 is null or c.ProposalTypeId <> 68 then
			@description
		else 
			Concat(
				''<b>Part 1: </b>'', @descriptionPart2, ''<br><b>Part 2:</b>'', @description
			)
	End as Text
	FROM Course AS c WHERE c.Id = @EntityId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

SET @SQL = '
DECLARE @ObjectivePart1 VARCHAR(Max) = (Select TextMax10 from GenericMaxText where courseid = @entityid) ;
declare @text nvarchar(max) = ''''

select @text = concat(@text,''<ul>'',dbo.ConcatOrdered_Agg(SortOrder,concat(''<li>'',Text,''</li>''),1),''</ul>'') 
from (select Text, row_number() over (partition by CourseId order by SortOrder, Id) as SortOrder from CourseObjective where CourseId = @EntityId) s

select 
	top 1 0 as Value,
	case 
		when @ObjectivePart1 is null or c.ProposalTypeId <> 68 then
			@text 
		Else 
			Concat(
				''<b> Part 1: </b>'', @ObjectivePart1, ''<br><b> Part 2: </b>'', @text 
			)
End as Text
FROM Course AS c WHERE c.Id = @EntityId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 267

SET @SQL = '
DECLARE @content VARCHAR(Max) = (Select LectureOutline from course where id = @entityid); 
DECLARE @contentPart2 VARCHAR(Max) = (Select TextMax08 from GenericMaxText where courseid = @entityid);
select 
	0 as Value,
	case 
		when @contentPart2 is null or c.ProposalTypeId <> 68 then
			@content
		else 
			Concat(
				''<b>Part 1: </b>'', @contentPart2, ''<br><b>Part 2:</b>'', @content
			)
	End as Text
	FROM Course AS c
	WHERE c.Id = @EntityId
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 265

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (@Id, 267, 265)