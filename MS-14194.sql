USE [peralta];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14194';
DECLARE @Comments nvarchar(Max) = 
	'Update CustomSQL';
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
DECLARE @SQL NVARCHAR(MAX) = '
declare @config stringpair;
declare @IsNonCredit bit = (SELECT CASE WHEN p.AwardTypeId in (SELECT Id FROM AwardType WHERE Title like ''%Certificate of Competency%'' or Title like ''%Certificate of Completion%'' or Title like ''%Certificate of Accomplishmen%'')
			THEN 1 ELSE 0 END FROM Program AS p WHERE p.Id = @EntityId);

insert into @config
(String1,String2)
values
(''BlockItemTable'',''ProgramSequence'');

create table #renderedInjections (
    TableName sysname,
    Id int,
    InjectionType nvarchar(255),
    RenderedText nvarchar(max),
    primary key (TableName, Id, InjectionType)
);

INSERT INTO #renderedInjections
(TableName, Id, InjectionType, RenderedText)
    SELECT
        ''ProgramSequence'' AS TableName
       ,ps.Id
       ,''CourseEntryRightColumnReplacement''
       ,CASE WHEN @IsNonCredit = 1
					THEN 
					CONCAT(
					FORMAT(cd.MinLectureHour * 17.5, ''##0.###''),
						CASE 
							WHEN cd.Variable = 1
                then CONCAT(''-'',FORMAT(cd.MaxLectureHour * 17.5, ''##0.###''))
							ELSE ''''
						END)
					ELSE
						CONCAT(
						FORMAT(cd.MinCreditHour, ''##0.###''),
					CASE
						WHEN cd.Variable = 1
							THEN CONCAT(''-'', FORMAT(cd.MaxCreditHour, ''##0.###''))
							ELSE ''''
						END)
        END
        AS RenderedText
    FROM ProgramSequence ps
    left join CourseDescription cd on cd.CourseId = ps.CourseId
    WHERE (
    ps.ProgramId = @entityId
    );



declare @CourseUnitsOveride nvarchar(max) =
''select
    Id as [Value], RenderedText as [Text]
from #renderedInjections ri
where ri.TableName = ''''ProgramSequence'''' and ri.Id = @id and ri.InjectionType = ''''CourseEntryRightColumnReplacement'''';'';


declare @extraDetailsDisplay StringPair;

INSERT INTO @extraDetailsDisplay
(String1, String2)
VALUES
(''CourseEntryRightColumnReplacement'', @CourseUnitsOveride );

declare @classOverrides stringtriple;

INSERT INTO @classOverrides
(String1, String2, String3)
VALUES
(''CourseCrossListingList'', ''Wrapper'', ''hidden d-none'');   

EXEC upGenerateGroupConditionsCourseBlockDisplay 
    @entityId ,
		@extraDetailsDisplay = @extraDetailsDisplay,
    @elementClassOverrides = @classOverrides, 
    @config = @config, 
    @outputTotal = 0,
		@hoursScale = 2;

DROP TABLE IF EXISTS #renderedInjections;
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 995

UPDATE MetaTemplate
Set LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = 2
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 1
    AND mtt.ClientId = 1
		AND mtt.MetaTemplateTypeId = 63
)