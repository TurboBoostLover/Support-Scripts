USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-15248';
DECLARE @Comments nvarchar(Max) = 
	'Fix Group Checklist issue';
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
UPDATE ClientLearningOutcome
SET ClientId = 2
WHERE ParentId = 44

UPDATE ClientLearningOutcome
SET ClientId = 3
WHERE ParentId = 43

UPDATE ClientLearningOutcome
SET ClientId = 4
WHERE ParentId = 45

UPDATE ClientLearningOutcome
SET ClientId = 5
WHERE ParentId = 46


UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
declare @clientId2 int = (SELECT ClientId fROM Course WHERE Id = @EntityID)
DECLARE @Real int = (SELECT 
	CASE 
		When @clientId2 = 2
			THEN 44
		WHEN @clientId2 = 3
			THEN 43
		WHEN @clientId2 = 4
			THEN 45
		WHEN @clientId2 = 5
			THEN 46
		ELSE 0
	END)

declare @now datetime = getDate();
select clo.Id as [Value]
, ''<b>'' + 
	coalesce(clo.Title, '''') + 
	''</b> '' + 
	case
		when clo.Active = 0 then ''<span style="color: red;">'' + coalesce(clo.[Description], '''') + ''</span>''
		else coalesce(clo.[Description], '''')
	end +
	''<br />''
as [Text]
, clo.ParentId as filterValue
, isNull(clo.SortOrder, clo.Id) as sortOrder
, isNull(clop.SortOrder, clop.Id) as filterSortOrder
from ClientLearningOutcome clop
inner Join ClientLearningOutcome clo on clo.ParentId = clop.Id
where (@now between clo.StartDate and isNull(clo.EndDate, @now)
or exists (
	select 1
	from CourseOutcomeClientLearningOutcome coclo
		inner join CourseOutcome co on coclo.CourseOutcomeId = co.Id
	where clo.Id = coclo.ClientLearningOutcomeId
	and co.CourseId = @entityId
)
)
and clo.ParentId is not null
and clo.ParentId = @Real
order by filterValue, sortOrder;
'
WHERE Id = 441

UPDATE MetaSElectedField
SET MetaForeignKeyLookupSourceId = 441
WHERE MetaAvailableFieldId = 3766

SELECT * FROM GeneralEducationElement Where active = 1 and id not in (
52, 54, 55, 27, 28, 29, 30, 31, 32, 84, 43, 44, 85, 47, 87, 7, 8, 9, 10, 11, 12,13, 14, 15, 86, 26, 79, 65, 66, 67, 71, 72, 73, 74, 75, 77, 78
)Order BY GeneralEducationId, Title

UPDATE GeneralEducationElement
SET SortOrder = 1
WHERE Id = 52

UPDATE GeneralEducationElement
SET SortOrder = 2
WHERE Id = 54

UPDATE GeneralEducationElement
SET SortOrder = 3
WHERE Id = 55

UPDATE GeneralEducationElement
SET SortOrder = 4
WHERE Id = 27

UPDATE GeneralEducationElement
SET SortOrder = 5
WHERE Id = 28

UPDATE GeneralEducationElement
SET SortOrder = 6
WHERE Id = 29

UPDATE GeneralEducationElement
SET SortOrder = 7
WHERE Id = 30

UPDATE GeneralEducationElement
SET SortOrder = 8
WHERE Id = 31

UPDATE GeneralEducationElement
SET SortOrder = 9
WHERE Id = 32

UPDATE GeneralEducationElement
SET SortOrder = 10
WHERE Id = 84

UPDATE GeneralEducationElement
SET SortOrder = 11
WHERE Id = 43

UPDATE GeneralEducationElement
SET SortOrder = 12
WHERE Id = 44

UPDATE GeneralEducationElement
SET SortOrder = 13
WHERE Id = 85

UPDATE GeneralEducationElement
SET SortOrder = 14
WHERE Id = 47

UPDATE GeneralEducationElement
SET SortOrder = 15
WHERE Id = 87

UPDATE GeneralEducationElement
SET SortOrder = 16
WHERE Id = 7

UPDATE GeneralEducationElement
SET SortOrder = 17
WHERE Id = 8

UPDATE GeneralEducationElement
SET SortOrder = 18
WHERE Id = 9

UPDATE GeneralEducationElement
SET SortOrder = 19
WHERE Id = 10

UPDATE GeneralEducationElement
SET SortOrder = 20
WHERE Id = 11

UPDATE GeneralEducationElement
SET SortOrder = 21
WHERE Id = 12

UPDATE GeneralEducationElement
SET SortOrder = 22
WHERE Id = 13

UPDATE GeneralEducationElement
SET SortOrder = 23
WHERE Id = 14

UPDATE GeneralEducationElement
SET SortOrder = 24
WHERE Id = 15

UPDATE GeneralEducationElement
SET SortOrder = 25
WHERE Id = 86

UPDATE GeneralEducationElement
SET SortOrder = 26
WHERE Id = 26

UPDATE GeneralEducationElement
SET SortOrder = 27
WHERE Id = 79

UPDATE GeneralEducationElement
SET SortOrder = 28
WHERE Id = 65

UPDATE GeneralEducationElement
SET SortOrder = 29
WHERE Id = 66

UPDATE GeneralEducationElement
SET SortOrder = 30
WHERE Id = 67

UPDATE GeneralEducationElement
SET SortOrder = 31
WHERE Id = 71

UPDATE GeneralEducationElement
SET SortOrder = 32
WHERE Id = 72

UPDATE GeneralEducationElement
SET SortOrder = 33
WHERE Id = 73

UPDATE GeneralEducationElement
SET SortOrder = 34
WHERE Id = 74

UPDATE GeneralEducationElement
SET SortOrder = 35
WHERE Id = 75

UPDATE GeneralEducationElement
SET SortOrder = 36
WHERE Id = 77

UPDATE GeneralEducationElement
SET SortOrder = 37
WHERE Id = 78

UPDATE GeneralEducationElement
SET EndDate = GETDATE()
WHERE GeneralEducationId in (
	SELECT Id FROM GeneralEducation WHERE Active = 0
)

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0		--comment out if doing reports and forms
)