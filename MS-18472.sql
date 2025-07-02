USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18472';
DECLARE @Comments nvarchar(Max) = 
	'Update Mapping for Course Coding';
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
INSERT INTO EligibilityCriteria
(Title, Code, SortOrder, ClientId, StartDate)
VALUES
('All MFA/MMus Students except those students from School of Dance', 29, 0, 1, GETDATE()),
('All MFA/MMus Students except those students from School of Drama', 29, 0, 1, GETDATE()),
('All MFA/MMus Students except those students from School of Film and TV', 29, 0, 1, GETDATE()),
('All MFA/MMus Students except those students from School of Theatre and Entertainment Arts', 29, 0, 1, GETDATE())

INSERT INTO SubDivisionCategory
(Code, Title, ClientId, StartDate)
VALUES
('ME', 'PGME-Elective', 1, GETDATE())

DECLARE @Sub int = SCOPE_IDENTITY()

INSERT INTO  OrganizationEntitySubDivisionCategory
(OrganizationEntityId, SubDivisionCategoryId, ClientId, StartDate, DisciplineTypeId)
VALUES
(80, @Sub, 1, GETDATE(), 12)

INSERT INTO OrganizationEntityDisciplineTypeSubDivisionCategoryEligibilityCriteriaMap
(OrganizationEntityId, DisciplineTypeId, SubDivisionCategoryId, EligibilityCriteriaId, ClientId, StartDate)
VALUES
(47, 7, 139, 45, 1, GETDATE()),
(47, 7, 142, 45, 1, GETDATE()),
(47, 7, 134, 45, 1, GETDATE()),
(47, 7, 143, 45, 1, GETDATE()),
(80, 12, @Sub, 118, 1, GETDATE()),
(1, 3, 158, 6, 1, GETDATE()),
(1, 3, 158, 27, 1, GETDATE()),
(1, 3, 158, 28, 1, GETDATE()),
(1, 3, 158, 11, 1, GETDATE()),
(1, 3, 158, 29, 1, GETDATE()),
(1, 3, 158, 13, 1, GETDATE()),

(1, 5, 158, 6, 1, GETDATE()),
(1, 5, 158, 27, 1, GETDATE()),
(1, 5, 158, 28, 1, GETDATE()),
(1, 5, 158, 11, 1, GETDATE()),
(1, 5, 158, 29, 1, GETDATE()),
(1, 5, 158, 13, 1, GETDATE()),

(7, 3, 74, 6, 1, GETDATE()),
(7, 3, 74, 27, 1, GETDATE()),
(7, 3, 74, 28, 1, GETDATE()),
(7, 3, 74, 11, 1, GETDATE()),
(7, 3, 74, 29, 1, GETDATE()),
(7, 3, 74, 13, 1, GETDATE()),

(8, 3, 84, 6, 1, GETDATE()),
(8, 3, 84, 27, 1, GETDATE()),
(8, 3, 84, 28, 1, GETDATE()),
(8, 3, 84, 11, 1, GETDATE()),
(8, 3, 84, 29, 1, GETDATE()),
(8, 3, 84, 13, 1, GETDATE()),

(8, 5, 84, 6, 1, GETDATE()),
(8, 5, 84, 27, 1, GETDATE()),
(8, 5, 84, 28, 1, GETDATE()),
(8, 5, 84, 11, 1, GETDATE()),
(8, 5, 84, 29, 1, GETDATE()),
(8, 5, 84, 13, 1, GETDATE()),

(48, 3, 98, 6, 1, GETDATE()),
(48, 3, 98, 27, 1, GETDATE()),
(48, 3, 98, 28, 1, GETDATE()),
(48, 3, 98, 11, 1, GETDATE()),
(48, 3, 98, 29, 1, GETDATE()),
(48, 3, 98, 13, 1, GETDATE()),

(46, 4, 110, 6, 1, GETDATE()),
(46, 4, 110, 27, 1, GETDATE()),
(46, 4, 110, 28, 1, GETDATE()),
(46, 4, 110, 11, 1, GETDATE()),
(46, 4, 110, 29, 1, GETDATE()),
(46, 4, 110, 13, 1, GETDATE()),

(46, 5, 110, 6, 1, GETDATE()),
(46, 5, 110, 27, 1, GETDATE()),
(46, 5, 110, 28, 1, GETDATE()),
(46, 5, 110, 11, 1, GETDATE()),
(46, 5, 110, 29, 1, GETDATE()),
(46, 5, 110, 13, 1, GETDATE()),

(47, 3, 141, 6, 1, GETDATE()),
(47, 3, 141, 27, 1, GETDATE()),
(47, 3, 141, 28, 1, GETDATE()),
(47, 3, 141, 11, 1, GETDATE()),
(47, 3, 141, 29, 1, GETDATE()),
(47, 3, 141, 13, 1, GETDATE()),

(47, 5, 141, 6, 1, GETDATE()),
(47, 5, 141, 27, 1, GETDATE()),
(47, 5, 141, 28, 1, GETDATE()),
(47, 5, 141, 11, 1, GETDATE()),
(47, 5, 141, 29, 1, GETDATE()),
(47, 5, 141, 13, 1, GETDATE()),

(2, 11, 61, 41, 1, GETDATE()),
(2, 11, 61, 42, 1, GETDATE()),
(2, 11, 61, 123, 1, GETDATE()),
(2, 11, 61, 124, 1, GETDATE()),
(2, 11, 61, 125, 1, GETDATE()),
(2, 11, 61, 126, 1, GETDATE()),

(7, 11, 74, 41, 1, GETDATE()),
(7, 11, 74, 42, 1, GETDATE()),
(7, 11, 74, 123, 1, GETDATE()),
(7, 11, 74, 124, 1, GETDATE()),
(7, 11, 74, 125, 1, GETDATE()),
(7, 11, 74, 126, 1, GETDATE()),

(8, 11, 84, 41, 1, GETDATE()),
(8, 11, 84, 42, 1, GETDATE()),
(8, 11, 84, 123, 1, GETDATE()),
(8, 11, 84, 124, 1, GETDATE()),
(8, 11, 84, 125, 1, GETDATE()),
(8, 11, 84, 126, 1, GETDATE()),

(46, 11, 110, 41, 1, GETDATE()),
(46, 11, 110, 42, 1, GETDATE()),
(46, 11, 110, 123, 1, GETDATE()),
(46, 11, 110, 124, 1, GETDATE()),
(46, 11, 110, 125, 1, GETDATE()),
(46, 11, 110, 126, 1, GETDATE()),

(47, 11, 120, 41, 1, GETDATE()),
(47, 11, 120, 42, 1, GETDATE()),
(47, 11, 120, 123, 1, GETDATE()),
(47, 11, 120, 124, 1, GETDATE()),
(47, 11, 120, 125, 1, GETDATE()),
(47, 11, 120, 126, 1, GETDATE())


DELETE FROM OrganizationEntityDisciplineTypeSubDivisionCategoryEligibilityCriteriaMap
WHERE Id in (777, 778, 1248, 2965, 2966, 3996, 3997, 4312, 8031, 5278, 5435, 6251, 6252, 6567, 2252, 3672, 4469, 5592, 6703)

UPDATE EligibilityCriteria
SET Title = 'All BFA/BMus Students except those students from School of Drama'
WHERE Id = 11

INSERT INTO DisciplineTypeSubDivisionCategoryCreditTypeMap
(DisciplineTypeId, SubDivisionCategoryId, CreditTypeId, ClientId, StartDate)
VALUES
(12, @Sub, 12, 1, GETDATE())

;WITH CTE_Duplicates AS (
    SELECT 
        OrganizationEntityId,
        DisciplineTypeId,
        id,
        ROW_NUMBER() OVER (PARTITION BY OrganizationEntityId, DisciplineTypeId ORDER BY id) AS RowNum
    FROM OrganizationEntityDisciplineTypeMap
)
DELETE FROM OrganizationEntityDisciplineTypeMap
WHERE id IN (
    SELECT id
    FROM CTE_Duplicates
    WHERE RowNum > 1
);

UPDATE MetaForeignKeyCriteriaClient
sET CustomSql = '
select
    LU14.Id as Value
    ,LU14.Title as Text
from Course C
	inner join Coursedetail CD on C.id = CD.CourseId
	inner join OrganizationEntityDisciplineTypeLookup14Map map on CD.Tier1_OrganizationEntityId = map.OrganizationEntityID
		and C.DisciplineTypeId = map.DisciplineTypeId
	inner join Lookup14 LU14 on LU14.Id = map.lookUp14id
where C.id = @entityid
and LU14.Description like ''%Major%''
order by LU14.Title
'
WHERE Id = 165

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()