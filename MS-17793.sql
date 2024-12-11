USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17793';
DECLARE @Comments nvarchar(Max) = 
	'Update Custom SQL';
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
sET CustomSql = 'declare @SchoolCurriculumTranslationTable table (SchoolCode nvarchar(10),CurriculumCode nvarchar(10))
insert into @SchoolCurriculumTranslationTable
values
(''CO'',''3'')
,(''CO'',''A'')
,(''CO'',''B'')
,(''CO'',''C'')
,(''CO'',''D'')
,(''DA'',''2'')
,(''DA'',''3'')
,(''DA'',''A'')
,(''DA'',''B'')
,(''DA'',''C'')
,(''DA'',''D'')
,(''DA'',''P'')
,(''DR'',''2'')
,(''DR'',''3'')
,(''DR'',''B'')
,(''DR'',''C'')
,(''DR'',''D'')
,(''FT'',''2'')
,(''FT'',''3'')
,(''FT'',''B'')
,(''FT'',''C'')
,(''LA'',''B'')
,(''LA'',''C'')
,(''LA'',''D'')
,(''LG'',''D'')
,(''LG'',''E'')
,(''LG'',''H'')
,(''LG'',''I'')
,(''MU'',''2'')
,(''MU'',''3'')
,(''MU'',''A'')
,(''MU'',''C'')
,(''MU'',''D'')
,(''MU'',''G'')
,(''MU'',''X'')
,(''PG'',''2'')
,(''PG'',''3'')
,(''TE'',''2'')
,(''TE'',''3'')
,(''TE'',''B'')
,(''TE'',''C'')
,(''TE'',''D'')
,(''TE'',''V'')


select DT.id as Value,concat(DT.code,'' - '',DT.Title) as Text, SortOrder AS SortOrder
from CourseDetail CD
	inner join OrganizationEntity OE on CD.Tier1_OrganizationEntityId = OE.id
		and OE.Active = 1
	inner join @SchoolCurriculumTranslationTable SCTT on OE.Code = SCTT.SchoolCode
	inner join DisciplineType DT on DT.Code = SCTT.CurriculumCode
		and DT.Active = 1
where CD.courseid = @entityid
UNION
SELECT -1 AS Value, ''No Selection'' AS Text, 100 as SortOrder
order by SortOrder'
, ResolutionSql = '
select  CASE WHEN ID <> -1 THEN CONCAT(Code, '' - '', Title) ELSE ''No Selection'' END as [Text]
from DisciplineType
where Id = @Id
'
WHERE Id = 118

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'select 
    sdc.Id as Value
    ,sdc.Title as Text 
		, sdc.SortOrder AS SortOrder
From SubDivisionCategory sdc
	left join Course C on C.id = @entityid
	left join CourseDetail CD on CD.CourseId = C.id
    inner join OrganizationEntitySubDivisionCategory oes on oes.SubDivisionCategoryId = sdc.Id
Where sdc.Active = 1
	and ((CD.Tier1_OrganizationEntityId = oes.OrganizationEntityId
	and C.DisciplineTypeId = OES.DisciplineTypeId) or C.id is null)
	UNION
	SELECT -1 AS Value, ''No Selection'' AS Text, 100 AS SortOrder
ORDER by sdc.SortOrder'
, ResolutionSql = 'Select  CASE WHEN Id <> -1 THEN Code ELSE ''No Selection'' END as Text 
From SubDivisionCategory 
Where Id = @id'
WHERE Id = 205

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = '
declare @type int = 
(SELECT dt.Id AS Id FROM Course c
	INNER JOIN CourseDetail cd ON c.Id = cd.CourseId
	INNER JOIN DisciplineType dt on c.DisciplineTypeId = dt.Id
WHERE c.Id = @entityId)

declare @subDivision INT = (
    select 
	(CASE 
			WHEN sdc.Id IN (58,146,154,99,159,143,126,151,86,148,66,67,64,60,144)
				THEN 11 --Contextual Studies
			WHEN sdc.Id IN (3,2,127,133,132,135,137,138,131,136,152,93,92,91,89,88,87,85,150,73,70,65,156,145,
							63,62,140,130,124,125,123,121,114,111,112,95,82,79,83,77,75,76,72,128,155,160,142,139,118,122,157)
				THEN 16 --Major Studies
			WHEN sdc.Id IN (71,59,149,90,153,134,119,129,115,81,78,71,69,68)
				THEN 21 --School Electives
			WHEN sdc.Id IN (158,120,117,61,141,110,98,84,74)
				THEN 9 --Academy Electives
			WHEN sdc.Id = 100
				THEN 14 --Liberal Arts Studies
			WHEN sdc.Id IN (103, 104, 105,106,107, 108,109,101,102)
				THEN 13 --Language
			WHEN sdc.Id IN (147,80,96,113)
				THEN 20 --School Core
			WHEN sdc.Id = 116
				THEN 8 --Academy Core
			END) 
    from CourseDetail cd
        inner join SubDivisionCategory sdc on sdc.Id = cd.SubDivisionCategoryId
    where cd.CourseId = @entityId
)

declare @final table (Id INT)

if (@type = 11) --MFA/MMus
begin
    if (@subDivision = 16)
    begin
        insert into @final
        (Id)
        VALUES
        (16), --MajorStudies,
        (22), --Specialisation,
        (18), --Professional Practice,
        (23) --Thesis Project
    end

    if (@subDivision = 20) --School Core
    BEGIN
        insert into @final
        (Id)
        VALUES
        (20) --School Core
    end

    if (@subDivision = 8) --Academy Core
    BEGIN
        insert into @final
        (Id)
        VALUES
        (8) --Academy Core
    end

    if (@subDivision = 21) --School Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (21) --School Electives
    end

    if (@subDivision = 9) --Academy Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (9) --Academy Electives
    end
end

if (@type = 5 or @type = 3) --BFA/MUS Curriculum B and C
BEGIN
    if (@subDivision = 16) --MajorStudies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (16) --MajorStudies
    end

    if (@subDivision = 11) --Contextual Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (11) --Contextual Studies
    end

    if (@subDivision = 13) --Language
    BEGIN
        insert into @final
        (Id)
        VALUES
        (13) --Language
    end

    if (@subDivision = 14) --Liberal Arts Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (14) --Liberal Arts Studies
    end

    if (@subDivision = 21) --School Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (21) --School Electives
    end

    if (@subDivision = 9) --Academy Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (9) --Academy Electives
    end
end

if (@type = 8 or @type = 9 or @type = 10) --diploma
BEGIN
    if (@subDivision = 16) --Major Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (16) --Major Studies
    end

    if (@subDivision = 11) --Contextual Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (11) --Contextual Studies
    end

    if (@subDivision = 13) --Language
    BEGIN
        insert into @final
        (Id)
        VALUES
        (13) --Language
    end

    if (@subDivision = 14) --Liberal Arts Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (14) --Liberal Arts Studies
    end
end

if (@type = 1) --	Advanced Diploma
begin
    if (@subDivision = 16) --Major Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (16) --Major Studies
    end

    if (@subDivision = 11) --Contextual Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (11) --Contextual Studies
    end

    if (@subDivision = 13) --Language
    BEGIN
        insert into @final
        (Id)
        VALUES
        (13) --Language
    end

    if (@subDivision = 21) --School Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (21) --School Electives
    end

    if (@subDivision = 9) --Academy Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (9) --Academy Electives
    end
    
    if (@subDivision = 14) --Liberal Arts Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (14) --Liberal Arts Studies
    end
end

if (@type = 2) -- diploma in foundations
BEGIN
    if (@subDivision = 16) --Major Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (16) --Major Studies
    end

    if (@subDivision = 11) --Contextual Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (11) --Contextual Studies
    end

    if (@subDivision = 13) --Language
    BEGIN
        insert into @final
        (Id)
        VALUES
        (13) --Language
    end
end

if (@type = 14) --	Professional Diploma
BEGIN
    if (@subDivision = 16) --Major Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (16) --Major Studies
    end

    if (@subDivision = 11) --Contextual Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (11) --Contextual Studies
    end

    if (@subDivision = 21) --School Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (21) --School Electives
    end

    if (@subDivision = 13) --Language
    BEGIN
        insert into @final
        (Id)
        VALUES
        (13) --Language
    end
end

if (@type = 7) 	--Certificate
BEGIN
    if (@subDivision = 16) --Major Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (15), --Major Courses
        (17) --Production Practice Courses
    end

    if (@subDivision = 11) --Contextual Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (11) --Contextual Studies
    end

    if (@subDivision = 21) --School Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (21) --School Electives
    end
end

if (@type = 12)	--MA
BEGIN
    if (@subDivision = 20) --School Core
    BEGIN
        insert into @final
        (Id)
        VALUES
        (19) --Required Courses
    end

    if (@subDivision = 16) --Major Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (19) --Required Courses
    end

    if (@subDivision = 9) --Academy Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (12) --Electives
    end

    if (@subDivision = 21) --School Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (12) --Electives
    end
end

if (@type = 13)	--PostGraduate Diploma
BEGIN
    if (@subDivision = 20) --School Core
    BEGIN
        insert into @final
        (Id)
        VALUES
        (20) --School Core
    end

    if (@subDivision = 16) --Major Studies
    BEGIN
        insert into @final
        (Id)
        VALUES
        (16) --Major Studies
    end

    if (@subDivision = 9) --Academy Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (9) --Academy Electives
    end

    if (@subDivision = 21) --School Electives
    BEGIN
        insert into @final
        (Id)
        VALUES
        (21) --School Electives
    end
end

SELECT Id as Value, Title as Text, SortOrder AS SortOrder
from CreditType 
where Active = 1
and Id in (select * from @final)
UNION
SELECT -1 AS Value, ''No Selection'' AS Text, 100 AS SortOrder
order by SortOrder
'
, ResolutionSql = 'Select Id as Value, CASE WHEN Id <> -1 THEN Title ELSE ''No Selection'' END as Text
FROM CreditType
WHERE Id = @Id'
WHERE Id = 213

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (
		118, 205, 213
	)
)