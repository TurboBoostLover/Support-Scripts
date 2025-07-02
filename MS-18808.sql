USE [Hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18808';
DECLARE @Comments nvarchar(Max) = 
	'Update PSD report table 4.4';
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
declare @sql nvarchar(max);

set @sql = 
'
DECLARE @type bit = (SELECT CASE WHEN  p.AwardTypeId = 28 THEN 1 ELSE 0 END FROM Program AS p WHERE p.Id = @EntityId)

DECLARE @style NVARCHAR(MAX) = ''
<style type="text/css">
.tg  {border-collapse:collapse;border-spacing:0;}
.tg td{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
  overflow:hidden;padding:10px 5px;word-break:normal;}
.tg th{border-color:black;border-style:solid;border-width:1px;font-family:Arial, sans-serif;font-size:14px;
  font-weight:normal;overflow:hidden;padding:10px 5px;word-break:normal;}
.tg .tg-0pky{border-color:inherit;text-align:left;vertical-align:top}
</style>
''


DECLARE @infoText NVARCHAR(MAX) = ''<br><p>4.4 The weighting of courses at various QF Levels is summarised in Tables 4.4. The mapping of courses 
	against the Generic Level Descriptors (GLD) is in Appendix 4.2.<p>''
DECLARE @tbody NVARCHAR(MAX) = concat(''<br><b style="font-size:16px">Table 4.4: Course Weighting by QF Levels </b>'', @infoText)

DECLARE @CoursesByMajorSpecialisation TABLE (
	Id INT IDENTITY(1,1), 
	MajorId INT, 
	MajorTitle NVARCHAR(MAX), 
	SpecialisationId INT, 
	SpecialisationTitle NVARCHAR(MAX), 
	CourseId INT,
	CourseTitle NVARCHAR(MAX), 
	QFCredit DECIMAL(10,2), 
	QFLevelId INT, 
	QFLevelTitle NVARCHAR(MAX), 
	CourseDurationId INT,
	CatalogYear NVARCHAR(MAX),
    Parent_Id int
)

DECLARE @totalNumCourse INT = 0;
DECLARE @totalNumCredit DECIMAL(10,2) = 0;

INSERT INTO @CoursesByMajorSpecialisation
SELECT 
	NULL AS MajorId,
	NULL AS MajorTitle,
	NULL AS SpecialisationId,
	NULL AS SpecialisationTitle,
	C.Id AS CourseId,
	C.Title AS CourseTitle,
	PS.CalcMin AS QFCredit,
	QFL.Id AS QFLevelId,
	QFL.Title AS QFLevelTitle,
	CA.DesignationId AS CourseDurationId,
	NULL AS CatalogYear,
    Parent_Id = Parent_Id
FROM ProgramSequence PS
	INNER JOIN Course C
		ON C.Id = PS.CourseId
	INNER JOIN CourseDescription CD
		ON CD.CourseId = C.Id
	INNER JOIN CourseAttribute CA
		ON CA.CourseId = C.Id
	LEFT JOIN QFLevel QFL
		ON QFL.Id = CA.QFLevelId
WHERE PS.ProgramId = @entityId


while (exists (select top 1 1 from @CoursesByMajorSpecialisation where Parent_Id is not null))
BEGIN
    update t set 
        Parent_Id = ps.Parent_Id,
        MajorId = ps.Id,
        MajorTitle = GroupTitle
    from @CoursesByMajorSpecialisation t 
    join ProgramSequence ps on ps.Id = t.Parent_Id 
END
/*
SELECT * FROM Designation
1 Semester, 2 Year long
*/

DECLARE @totalCourses INT = (SELECT COUNT(*) FROM @CoursesByMajorSpecialisation)

UPDATE @CoursesByMajorSpecialisation
SET QFCredit = QFCredit/2 
WHERE CourseDurationId = 2

UPDATE @CoursesByMajorSpecialisation
SET SpecialisationId = -1, SpecialisationTitle = ''No Specialisation''
WHERE SpecialisationId IS NULL

UPDATE @CoursesByMajorSpecialisation
SET MajorId = -1, MajorTitle = ''No Major''
WHERE MajorId IS NULL

UPDATE @CoursesByMajorSpecialisation
SET QFLevelId = -1, QFLevelTitle = ''No QFLevel selected''
WHERE QFLevelId IS NULL

DECLARE @TotalQFCredit DECIMAL(10,2) 

DECLARE @TotalMajors INT = (SELECT COUNT(DISTINCT MajorId) FROM @CoursesByMajorSpecialisation)
DECLARE @counter INT = 0
DECLARE @counter2 INT = 0
DECLARE @TotalSpecialisations INT
DECLARE @CurrentCoursesCalculations TABLE (RowOrder INT IDENTITY (1,1), QFL NVARCHAR(MAX), TotalCourses INT, TotalCredits DECIMAL(10,2))
DECLARE @currentMajorId INT
DECLARE @currentSpecialisationId INT
DECLARE @calculationRows NVARCHAR(MAX)
DECLARE @totalTablePercentage DECIMAL(10,2)

WHILE (@counter < @TotalMajors)
	BEGIN
		SELECT DISTINCT @currentMajorId = MajorId 
		FROM @CoursesByMajorSpecialisation
		ORDER BY MajorId
		offset @counter ROW
		FETCH NEXT 1 ROWS only

		SET @tbody += ''Course Weighting by QF Levels<br/>''
	

		SELECT DISTINCT @TotalSpecialisations = COUNT(*) 
		FROM (SELECT DISTINCT MajorId, SpecialisationId
		FROM @CoursesByMajorSpecialisation 
		WHERE MajorId = @currentMajorId) AS Subquery

		SET @counter += 1
		SET @counter2 = 0

        set @TotalQFCredit = (SELECT SUM(QFCredit) FROM @CoursesByMajorSpecialisation where MajorId = @currentMajorId)
        SELECT @TotalQFCredit = Nullif(@TotalQFCredit, 0) 

		WHILE(@counter2 < @TotalSpecialisations)
			BEGIN
				SELECT DISTINCT @currentSpecialisationId = SpecialisationId 
				FROM @CoursesByMajorSpecialisation
				WHERE MajorId = @currentMajorId
				ORDER BY SpecialisationId
				offset @counter2 ROW
				FETCH NEXT 1 ROWS only

                SET @tbody += (SELECT DISTINCT MajorTitle
                    FROM @CoursesByMajorSpecialisation
                    WHERE MajorId = @currentMajorId)


				IF (@currentSpecialisationId IS NULL)
				BEGIN
					-- SET @tbody += (SELECT DISTINCT CONCAT(''<br>Specialisations(s): '', COALESCE(SpecialisationTitle, '''')) 
					-- 	FROM @CoursesByMajorSpecialisation
					-- 	WHERE SpecialisationId IS NULL AND MajorId = @currentMajorId)

						INSERT INTO @CurrentCoursesCalculations
						SELECT QFLevelTitle, COUNT(CourseId), SUM(QFCredit)
						FROM @CoursesByMajorSpecialisation
						WHERE SpecialisationId IS NULL AND MajorId = @currentMajorId
						GROUP BY QFLevelTitle

				END
				ELSE
				BEGIN
					-- SET @tbody += (SELECT DISTINCT CONCAT(''<br>Specialisations(s): '', COALESCE(SpecialisationTitle, '''')) 
					-- 		FROM @CoursesByMajorSpecialisation
					-- 		WHERE SpecialisationId = @currentSpecialisationId AND MajorId = @currentMajorId)

					INSERT INTO @CurrentCoursesCalculations
					SELECT QFLevelTitle, COUNT(CourseId), SUM(QFCredit)
					FROM @CoursesByMajorSpecialisation
					WHERE SpecialisationId = @currentSpecialisationId AND MajorId = @currentMajorId
					GROUP BY QFLevelTitle
				END
				

				SELECT @totalTablePercentage = case when @TotalQFCredit is null then 100 else SUM(Coalesce(TotalCredits,0)/@TotalQFCredit) * 100 end FROM @CurrentCoursesCalculations

				SELECT @totalNumCourse = SUM(TotalCourses) FROM @CurrentCoursesCalculations;
				SELECT @totalNumCredit = SUM(TotalCredits) FROM @CurrentCoursesCalculations;

				SELECT @calculationRows = dbo.ConcatWithSepOrdered_Agg('''', RowOrder, CONCAT(''<tr><td class="tg-0lax textblue">'', QFL, ''</td><td class="tg-0lax">'',TotalCourses, 
					''</td><td class="tg-0lax">'',FORMAT(coalesce(TotalCredits,0),''0.##''),''</td><td class="tg-0lax">'', case when @TotalQFCredit is null then ''100'' else FORMAT(CAST((Coalesce(TotalCredits,0)/@TotalQFCredit * 100)  AS DECIMAL(10,2)),''0.##'') end, ''% </td></tr>''))
				FROM @CurrentCoursesCalculations

				SET @calculationRows += CONCAT(''<tr><td class="tg-0lax">Total</td><td class="tg-0lax">'',@totalNumCourse,''</td><td class="tg-0lax">'',FORMAT(@totalNumCredit,''0.##''),''</td><td class="tg-0lax">100% </td></tr>'')

				declare @Warningmessage NVARCHAR(max) = ''''

				if (@Warningmessage = '''')
				select @Warningmessage = case when CAST((Coalesce(TotalCredits,0)/@TotalQFCredit * 100) AS DECIMAL(10,2)) < .5 and @TotalQFCredit is not null and @type = 1
					then ''<span style="color:Red;font-weight: bold;">QFLevel 5 is less than 50%</span><br/>''
					else '''' end
				from @CurrentCoursesCalculations
				where QFL = ''QFLevel 5''



				SET @tbody += CONCAT(''<br><table class="tg"><tbody><tr>
					<td class="tg-0lax blue">QF Level</td>
					<td class="tg-0lax blue">Total No. of Courses</td>
					<td class="tg-0lax blue">Total No. of Credit</td>
					<td class="tg-0lax blue">Percentage (%)</td>
					</tr>'', @calculationRows, ''</tbody></table>'',
					@Warningmessage)

				DELETE FROM @CurrentCoursesCalculations
				SET @calculationRows = ''''
				SET @counter2 += 1
			END
	END

SELECT 0 AS Value, CONCAT(@style,@tbody) AS Text'


update MetaForeignKeyCriteriaClient set CustomSql = @sql, ResolutionSql = @sql where Id = 237

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE msf.MetaForeignKeyLookupSourceId = 237