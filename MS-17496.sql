USE [laspositas];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17496';
DECLARE @Comments nvarchar(Max) = 
	'Fix Bad Query for Course Content on reports';
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
Declare @NoUnitLab int = (SELECT Bit29 FROM GenericBit WHERE CourseId = @EntityId);

DECLARE @CreditLec int = (SELECT IsTBALecture FROM CourseDescription WHERE CourseId = @EntityId);
DECLARE @CreditLab int = (SELECT IsTBALab FROM CourseDescription WHERE CourseId = @EntityId);
DECLARE @CreditWork int = (SELECT TList FROM Course WHERE Id = @EntityId);

DECLARE @NonCreditLec int = (SELECT Bit24 FROM GenericBit WHERE CourseId = @EntityId);
DECLARE @NonCreditLab int = (SELECT Bit25 FROM GenericBit WHERE CourseId = @EntityId);
DECLARE @NonCreditWork int = (SELECT Bit26 FROM GenericBit WHERE CourseId = @EntityId);

DECLARE @CreditCount int = ISNULL(@CreditLec, 0) + 
	case
		when @CreditLab = 1 or @NoUnitLab = 1 then 1
		Else 0
	End + 
	ISNULL(@CreditWork, 0);
DECLARE @NonCreditCount int = ISNULL(@NonCreditLec, 0) +
	case
			when @NonCreditLab = 1 or @NoUnitLab = 1 then 1
		Else 0
	End + 
	ISNULL(@NonCreditWork, 0);

DECLARE @LecContent NVARCHAR(MAX) = (SELECT LectureOutline FROM Course WHERE Id = @EntityId);
DECLARE @LabContent NVARCHAR(MAX) = (SELECT LabContent FROM CourseAssist WHERE CourseId = @EntityId);
DECLARE @WorkContent NVARCHAR(MAX) = (SELECT TextMax10 FROM GenericMaxText WHERE CourseId = @EntityId);

DECLARE @CredNonCred int = (SELECT CB04Id FROM CourseCBCode WHERE CourseId = @EntityId)

DECLARE @STRING NVARCHAR(MAX) = '''';

IF (@CreditCount = 1 and @CredNonCred in (1, 2))
BEGIN
    SELECT 0 AS Value, COALESCE(@LecContent, @LabContent, @WorkContent) AS Text;
END
ELSE IF (@CreditCount > 1 and @CredNonCred in (1, 2))
BEGIN
    IF @CreditLab = 1 or @NoUnitLab = 1
        SET @STRING = CONCAT(@STRING, ''<b>Lab:</b><br>'', @LabContent);
    IF @CreditLec = 1
        SET @STRING = CONCAT(@STRING, ''<b>Lecture:</b><br>'', @LecContent);
    IF @CreditWork = 1
        SET @STRING = CONCAT(@STRING, ''<b>Work Experience:</b><br>'', @WorkContent);

    SELECT 0 AS Value, @STRING AS Text;
END

IF (@NonCreditCount = 1 and @CredNonCred = 3)
BEGIN
    SELECT 0 AS Value, COALESCE(@LecContent, @LabContent, @WorkContent) AS Text;
END
ELSE IF (@NonCreditCount > 1 and @CredNonCred = 3)
BEGIN 
    IF @CreditLab = 1 or @NoUnitLab = 1
        SET @STRING = CONCAT(@STRING, ''<b>Lab:</b><br>'', @LabContent);
    IF @CreditLec = 1
        SET @STRING = CONCAT(@STRING, ''<b>Lecture:</b><br>'', @LecContent);
    IF @CreditWork = 1
        SET @STRING = CONCAT(@STRING, ''<b>Work Experience:</b><br>'', @WorkContent);

    SELECT 0 AS Value, @STRING AS Text;
END
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 156

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 156
)