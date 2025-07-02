USE [hkapa];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18962';
DECLARE @Comments nvarchar(Max) = 
	'Update Query on PSD report and student intakes';
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
DELETE FROM MetaSelectedFieldAttribute
WHERE MetaSelectedFieldId in (
	SELECT MetaSelectedFieldId FROM MetaSelectedField WHERE MetaAvailableFieldId = 2244
)

UPDATE MetaSelectedField
SET MetaPresentationTypeId = 25
, DefaultDisplayType = 'CKEditor'
, MetaAvailableFieldId = 2251
WHERE MetaAvailableFieldId = 2244

DECLARE @Id int = 224

DECLARE @SQL NVARCHAR(MAX) = '
declare @title NVARCHAR(max)
declare @title2 NVARCHAR(MAX)
declare @awardGrantingBody NVARCHAR(max)
declare @primaryAreaStudy NVARCHAR(max)
declare @subAreaStudy NVARCHAR(max)
declare @otherAreaStudy NVARCHAR(max)
declare @programmeLength NVARCHAR(max)
declare @academyCredit NVARCHAR(max)
declare @QFCredit NVARCHAR(max)
declare @QFLevel NVARCHAR(max)
declare @launchYear NVARCHAR(max)
declare @launchMonth NVARCHAR(max)
declare @targetStudents NVARCHAR(max)
declare @studentIntakesPerYear NVARCHAR(max)
declare @studentsPerIntake NVARCHAR(max)
declare @QualificationTitle NVARCHAR(MAX)

select @title = Title from Program
where Id = @entityId

select @title2 = TitleAlias from Program
where Id = @entityId

SELECT @QualificationTitle = dbo.ConcatWithSepOrdered_Agg(''<br>'', awt.SortOrder, awt.Title) FROM AwardTypeAlias AS awt
INNER JOIN ProgramAwardType AS pa on awt.Id = pa.AwardTypeAliasId WHERE pa.ProgramId = @EntityId

select @awardGrantingBody = lr.Text	
	from ProgramDetail pd 
		inner join LettersOfRecommendationRequirement lr on pd.LettersOfRecommendationRequirementId = lr.Id
	where pd.ProgramId = @entityId

select @primaryAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.First_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @subAreaStudy = ar.Title 
from Program p
	inner join AdmissionRequirement ar on p.Second_AdmissionRequirementId = ar.Id
where p.Id = @entityId

select @otherAreaStudy = CareerOption 
from Program
where Id = @entityId

select @programmeLength = cc.Title
from Program p
	inner join CategoryCode cc on p.CategoryCodeId = cc.Id
where p.Id = @entityId

select @academyCredit = Int05 
from GenericInt
where ProgramId = @entityId

select @QFCredit = ICCBCreditHours 
from Program
where Id = @entityId

select @QFLevel = qfl.Title
from Program p
	inner join QFLevel qfl on p.QFLevelId = qfl.Id
where p.Id = @entityId

select @launchYear = StartYear 
from ProgramProposal
where ProgramId = @entityId

select  @launchMonth = m.MonthName
from Program p
	inner join Months m on m.Id = p.StartMonth
where p.Id = @entityId

select @targetStudents = EntranceRequirementsText 
from program
where Id = @entityId

select @studentIntakesPerYear = DeactivateReson
from Program
where Id = @entityId

select @studentsPerIntake = AdmissionProcedures
from Program
where Id = @entityId

declare @modesOfDeliveryFT nvarchar(max) = (
	select 
		case
			when ft.RenderedText is not null
				then 
				concat (
					''<b>Full Time</b><br />''
					, ft.RenderedText
					, ''<br />''
				)
			else ''''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('''', dm.Id, concat(''<li style ="list-style-type: none;">'', dm.Title, ''</li>'')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 1--Full Time
	) ft
)

declare @modesOfDeliverPT nvarchar(max) = (
	select
		case
			when pt.RenderedText is not null
				then
				concat(
					''<b>Part-Time</b>''
					, pt.RenderedText
					, ''<br />''
				)
			else ''''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('''', dm.Id, concat(''<li style ="list-style-type: none;">'', dm.Title, ''</li>'')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 4--Part-Time
	) pt
)

declare @modesOfDeliverFTPT nvarchar(max) = (
	select
		case
			when ftpt.RenderedText is not null
				then
				concat(
					''<b>Full-Time and Part-time</b>''
					, ftpt.RenderedText
					, ''<br />''
				)
			else ''''
		end
	from (
		select dbo.ConcatWithSepOrdered_Agg('''', dm.Id, concat(''<li style ="list-style-type: none;">'', dm.Title, ''</li>'')) as RenderedText
		from ProgramDeliveryMethod pdm
			inner join DeliveryMethod dm on dm.Id = pdm.DeliveryMethodId
		where ProgramId = @entityId
		and dm.ParentId = 5--Full-Time and Part-time
	) ftpt
)

declare @modesOfDelivery nvarchar(max) = (
	select 
	concat(
		@modesOfDeliveryFT
		, @modesOfDeliverPT
		, @modesOfDeliverFTPT
	)
)

DECLARE @tbody NVARCHAR(MAX) = (CONCAT(
''<table style="border-collapse: collapse; width: 100%; font-family: Arial, sans-serif; font-size: 14px;">'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Programme Title (English)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@title, ''&nbsp;''), ''</td>'',
    ''</tr>'',
		''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Programme Title (Chinese)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@title2, ''&nbsp;''), ''</td>'',
    ''</tr>'',
		''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left; width: 30%;">Qualification Title</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QualificationTitle, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Award Granting Body</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@awardGrantingBody, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Mode of Delivery</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@modesOfDelivery, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Primary Area of Study / Training</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@primaryAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Sub Area of Study / Training</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@subAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Other Area of Study / Training (if any)</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@otherAreaStudy, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Programme Length</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@programmeLength, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Academy Credit</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@academyCredit, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    --''<tr>'',
    --    ''<th style="border: 1px solid black; padding: 8px; text-align: left;">QF Credits</th>'',
    --    ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QFCredit, ''&nbsp;''), ''</td>'',
    --''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">QF Level</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@QFLevel, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Planned Programme Launch Date</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@launchMonth, ''&nbsp;''), '', '', ISNULL(@launchYear, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Target Students</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@targetStudents, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Number of Student Intakes Per Year</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@studentIntakesPerYear, ''&nbsp;''), ''</td>'',
    ''</tr>'',
    ''<tr>'',
        ''<th style="border: 1px solid black; padding: 8px; text-align: left;">Number of Students Per Intake</th>'',
        ''<td style="border: 1px solid black; padding: 8px;">'', ISNULL(@studentsPerIntake, ''&nbsp;''), ''</td>'',
    ''</tr>'',
''</table>''
))

SELECT 0 AS [Value], CONCAT(@tbody, ''<br>'') AS [Text]
'

UPDATE MetaForeignKeyCriteriaClient
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id= @Id

UPDATE mt
SET LastUpdatedDate = GETDATE()
FROM MetaTemplate AS mt
INNER JOIN MetaSelectedSection AS mss on mss.MetaTemplateId = mt.MetaTemplateId
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE (msf.MetaForeignKeyLookupSourceId = @Id
OR
msf.MetaAvailableFieldId = 2251)