USE [sbcc];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-19648';
DECLARE @Comments nvarchar(Max) = 
	'Update General Education Items';
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
UPDATE GeneralEducation
SET EndDate = GETDATE()
WHERE Id in (
	1, --SBCC GENERAL EDUCATION (Areas A-D)
	2, --SBCC INSTITUTIONAL REQUIREMENTS (Area E)
	16	--SBCC INFORMATION COMPETENCY (Area F)
)

UPDATE GeneralEducationElement
SET EndDate = GETDATE()
WHERE GeneralEducationId in (
	1, --SBCC GENERAL EDUCATION (Areas A-D)
	2, --SBCC INSTITUTIONAL REQUIREMENTS (Area E)
	16	--SBCC INFORMATION COMPETENCY (Area F)
)

INSERT INTO GeneralEducation
(Title, SortOrder, ClientId, StartDate)
VALUES
('SBCC GENERAL EDUCATION REQUIREMENTS', 24, 1, GETDATE())

DECLARE @NewGe int = SCOPE_IDENTITY()

INSERT INTO GeneralEducationElement
(GeneralEducationId, Title, SortOrder ,StartDate, ClientId)
VALUES
(@NewGe, 'SBCC AREA 1A: English Composition', 0, GETDATE(), 1),
(@NewGe, 'SBCC AREA 1B: Oral Communication/Critical Thinking', 1, GETDATE(), 1),
(@NewGe, 'SBCC AREA 2: Mathematical Concepts and Quantitative Reasoning', 2, GETDATE(), 1),
(@NewGe, 'SBCC AREA 3: Arts and Humanities', 3, GETDATE(), 1),
(@NewGe, 'SBCC AREA 4: Social and Behavioral Sciences', 4, GETDATE(), 1),
(@NewGe, 'SBCC AREA 5: Natural Sciences', 5, GETDATE(), 1),
(@NewGe, 'SBCC AREA 6: Ethnic Studies', 6, GETDATE(), 1),
(@NewGe, 'SBCC AREA 7: Applied Living Skills', 7, GETDATE(), 1)

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
select [Id] as [Value], 
(Title) as [Text],
SortOrder
from [GeneralEducation] 
where Active = 1
	and Id != 5
UNION
select [Id] as [Value], 
CONCAT(''<span class="text-danger">'', Title, ''</span>'') as [Text],
SortOrder
from [GeneralEducation] 
WHERE Id in (
	SELECT GeneralEducationId FROM GeneralEducationElement WHERE Id in (
		SELECT GeneralEducationElementId FROM CourseGeneralEducation WHERE CourseId = @EntityId
	)
)
and Active = 0
Order By SortOrder
'
, LookupLoadTimingType = 2
WHERE Id = 43

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
select gee.Id as Value, 
	gee.Title as Text, 
	ge.Id as filterValue, 
	IsNull(gee.SortOrder, gee.Id) as SortOrder,
	IsNull(ge.SortOrder, ge.Id) as FilterSortOrder 
from  [GeneralEducation] ge 
	inner join [GeneralEducationElement] gee on gee.GeneralEducationId = ge.Id 
where gee.Active = 1
and ge.Id <> 5
	UNION
	SELECT
	 gee.Id as Value, 
	CONCAT(''<span class="text-danger">'', gee.Title, ''</span>'') as Text, 
	ge.Id as filterValue, 
	IsNull(gee.SortOrder, gee.Id) as SortOrder,
	IsNull(ge.SortOrder, ge.Id) as FilterSortOrder 
from  [GeneralEducation] ge 
	inner join [GeneralEducationElement] gee on gee.GeneralEducationId = ge.Id 
where gee.Id in (
	SELECT GeneralEducationElementId FROM CourseGeneralEducation WHERE CourseId = @EntityId
)
and gee.Active = 0
and ge.Id <> 5
Order By FilterSortOrder, SortOrder
'
, LookupLoadTimingType = 2
WHERE Id = 44

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId in (
43, 44
)