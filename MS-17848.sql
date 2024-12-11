USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17848';
DECLARE @Comments nvarchar(Max) = 
	'Fix Course Form Issues';
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
DECLARE @SQL NVARCHAR(MAX) = '
DECLARE @text NVARCHAR(MAX) = 
''<table border ="2" style="margin: auto; width: 100%;">
<tr style="background:lightgray;">
	<th>Programme</th>
	<th>Curriculum</th>
	<th>Major(s)</th>
	<th>Specialisation(s)</th>
	<th>Course Type</th>
	<th>Course Code</th>
	<th>Semester, Year to be offered</th>
</tr>''

DECLARE @semesters NVARCHAR(MAX) = 
(SELECT dbo.ConcatWithSepOrdered_Agg(''<br>'',sortorder,Title)
from (select s.Title,ROW_NUMBER() over (Order by CS.sortorder) as sortorder
FROM CourseSemester cs
	inner JOIN Semester s ON s.Id = cs.SemesterId
WHERE cs.CourseId = @entityId) A)

DECLARE @majors NVARCHAR(MAX) =
(SELECT dbo.ConcatWithSep_Agg('', '',Title) 
FROM GenericOrderedList01 gol
	INNER JOIN lookup14 l14 ON gol.Lookup14Id = l14.Id 
WHERE gol.CourseId = @entityId)

DECLARE @Specialization NVARCHAR(MAX) = 
(SELECT dbo.ConcatWithSep_Agg(''<br>'',l14.Title) 
FROM GenericOrderedList01Lookup14 gol14
	INNER JOIN lookup14 l14 ON gol14.Lookup14Id = l14.Id
	INNER JOIN GenericOrderedList01 gol ON gol14.GenericOrderedList01Id = gol.Id
WHERE gol.CourseId = @entityId)

SET @text += (
SELECT dbo.ConcatWithSep_Agg(''<br>'',Concat(''<tr>'',''<td>'', ec.Title, ''</td><td>'', dt.Code, ''</td><td>'', @majors, ''</td><td>'', @Specialization, ''</td><td>'',ct.Title, ''</td><td>'', c.CourseNumber, ''</td><td>'', @semesters, ''</td></tr>''))
FROM Course c
	INNER JOIN CourseEligibility ce ON c.Id = ce.CourseId
	LEFT JOIN EligibilityCriteria ec ON ce.EligibilityCriteriaId = ec.Id
	LEFT JOIN DisciplineType dt ON c.DisciplineTypeId = dt.Id
	INNER JOIN CourseProposal cp ON cp.CourseId = c.Id
	Left JOIN CreditType ct ON cp.CreditTypeId = ct.Id
WHERE c.Id = @entityId)

SET @text += ''</table>''

SELECT @text AS Text, 0 AS Value
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 252

DECLARE @SQL2 NVARCHAR(MAX) = '
declare @MajorTranslationTable table
(SchoolCode nvarchar(10),ProgrammeCode nvarchar(10),Major nvarchar(500))
insert into @MajorTranslationTable
(SchoolCode,ProgrammeCode ,Major )
values
-- Chinese Opera and CO
(''CO'',''A'',''Performance''),
(''CO'',''A'',''Music''),
(''CO'',''B'',''ALL''),
(''CO'',''D'',''ALL''),
(''CO'',''P'',''Performance''),
(''CO'',''P'',''Music''),
(''CO'',''X'',''ALL''),

-- Compliementary Studies 
(''LA'',''B'',''ALL''),
(''LG'',''B'',''ALL''),
(''LA'',''X'',''ALL''),
(''LG'',''X'',''ALL''),

-- Dance
(''DR'',''A'',''Ballet''),
(''DR'',''A'',''Chinese Dance''),
(''DR'',''A'',''Contemporary Dance''),
(''DA'',''B'',''ALL''),
(''DR'',''C'',''Dance Performance''),
(''DR'',''C'',''Choreography''),
(''DA'',''D'',''ALL''),
(''DR'',''P'',''Dance Performance''),
(''DA'',''X'',''ALL''),

-- Drama
(''DR'',''2'',''Directing''),
(''DR'',''2'',''Playwriting''),
(''DR'',''2'',''Drama and Theatre Education''),
(''DR'',''2'',''Dramaturgy''),
(''DR'',''B'',''ALL''),
(''DR'',''C'',''Acting for Drama''),
(''DR'',''C'',''Acting for Musical Theatre''),
(''DR'',''C'',''Directing''),
(''DR'',''C'',''Dramaturgy''),
(''DR'',''C'',''Applied Theatre''),
(''DR'',''D'',''ALL''),
(''DR'',''X'',''ALL''),

-- Film and Television
(''FT'',''B'',''ALL''),
(''FT'',''C'',''Creative Producing''),
(''FT'',''C'',''Directing''),
(''FT'',''C'',''Cinematography''),
(''FT'',''C'',''Editing''),
(''FT'',''C'',''Sound Recording and Design''),
(''FT'',''C'',''Screenwriting''),
(''FT'',''C'',''Digital Screen Design''),
(''FT'',''X'',''ALL''),

-- Genearl Education and Research
(''PG'',''2'',''ALL''),
(''PG'',''C'',''ALL''),
(''PG'',''E'',''ALL''),
(''PG'',''I'',''ALL''),
(''PG'',''H'',''ALL''),

-- Music
(''MU'',''2'',''Performance''),
(''MU'',''2'',''Conducting''),
(''MU'',''2'',''Composition''),
(''MU'',''A'',''Chinese Music: Gaohu, Banhu, Erhu, Zhonghu, Gehu (Cello), Bass Gehu (Double Bass), Yangqin, Liuqin, Pipa, Ruan, Sanxian, Guzheng, Guqin, Dizi, Suona, Guan, Sheng, Chinese Percussion''),
(''MU'',''A'',''Western Music: Piano, Organ, Violin, Viola, Cello, Double Bass, Harp, Classical Guitar, Flute, Oboe, Clarinet, Bassoon, Saxophone, Horn, Trumpet, Trombone, Bass Trombone, Euphonium, Tuba, Timpani and Orchestral Percussion''),
(''MU'',''A'',''Voice''),
(''MU'',''A'',''Composition and Electronic Music''),
(''MU'',''B'',''ALL''),
(''MU'',''D'',''ALL''),
(''MU'',''X'',''ALL''),
(''MU'',''C'',''Performance''),
(''MU'',''C'',''Composition and Electronic Music''),

-- Theatre and Entertainment Arts
(''TE'',''2'',''Contemporary Design and Technologies''),
(''TE'',''2'',''Arts and Event Management''),
(''TE'',''B'',''ALL''),
(''TE'',''D'',''ALL''),
(''TE'',''V'',''Lighting Technology''),
(''TE'',''V'',''Sound Technology''),
(''TE'',''V'',''Technical Theatre and Stage Management''),
(''TE'',''V'',''Costume Making''),
(''TE'',''V'',''Property Making and Scenic Painting''),
(''TE'',''X'',''ALL''),
(''TE'',''C'',''Media Design and Technology''),
(''TE'',''C'',''Technical Production and Management''),
(''TE'',''C'',''Theatre Design'')

select
    LU14.Id as Value
    ,LU14.Title as Text
	,1 as FilterValue 
from CourseSchool CS
	inner join School S on CS.SchoolId = S.id
		and S.Active = 1
	inner join ItemType IT on CS.ItemTypeId = IT.id
		and IT.Active = 1
		AND IT.ItemTableName = ''CourseSchool''
	inner join @MajorTranslationTable MTT on S.Code = MTT.SchoolCode
		and IT.Code = MTT.ProgrammeCode
	inner join Lookup14 LU14 on (MTT.Major = LU14.title or MTT.Major = ''ALL'')
		and LU14.Description = ''Major''
	inner join CourseSchoolMajor CSM on CSM.id = @pkIdValue
		and CSM.CourseSchoolid = CS.id
order by LU14.Title
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL2
WHERE Id = 102

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = 'SELECT 1 AS Value, ''1'' AS Text'
, ResolutionSql = 'SELECT 1 AS Value, ''1'' AS Text'
WHERE Id = 275

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId in (252, 102, 275)
)