USE [chabot];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-14336';
DECLARE @Comments nvarchar(Max) = 
	'upating the printer friendly report';
DECLARE @Developer nvarchar(50) = 'Nathan W';
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
Declare @sql nvarchar(max)=
'declare @headerText nvarchar(max) = ''
		<style>
		.instruction{
			font-weight: normal;
		}
		p.top-sectionTitle {
            font-weight: bold;
		}
        p.top-sectionTitle span {
            font-weight: normal;
		}
		</style>'',
		@instructionalText nvarchar(max) =
		''<div>
                <p>
                    This program map from the 2023-2024 catalog year represents one possible pathway to complete this program. Your pathway may vary depending on your transfer plans and also previous college credit, including AP Test scores, concurrent enrollment courses and high school articulated courses.
                </p>
                <p>
                    I''''m ready to get started. What do I do next?
                </p>
                <ol>
                    <li>Review this program map to get an overview of the required courses</li>
                    <li>Meet with a counselor to develop your customized student education plan <a href="http://www.chabotcollege.edu/counseling">www.chabotcollege.edu/counseling</a></li>
                    <li>Use DegreeWorks, an online student education planning tool, to track your progress toward graduation <a href="http://www.chabotcollege.edu/admissions/degreeworks">www.chabotcollege.edu/admissions/degreeworks</a></li>
                </ol>
            </div>'',
		@ApprenticeshipText nvarchar(max) =
            ''<div>
                <p>This apprenticeship program map for the 2023-2024 catalog year provides an overview of the required courses. You must be accepted into the apprenticeship by the Program Sponsor.</p>
                <p>Apprenticeship Programs at Chabot College are an excellent way to earn a certificate and/or an associate degree while also gaining real-world, paid work experience in the occupation. The requirements and expectations vary depending on the apprenticeship program. Classes also vary by program, with some offered in person, online or off-campus.</p>
                <p>I''''m ready to get started. What do I do next?</p>
                <ol>
                    <li>Apply to be an apprentice for the program you are interested in <a href="http://www.chabotcollege.edu/academics/apprenticeship">www.chabotcollege.edu/academics/apprenticeship</a></li>
                    <li>Meet with a Chabot College counselor to review and plan general education courses (for associate degree programs only) <a href="http://www.chabotcollege.edu/counseling">www.chabotcollege.edu/counseling</a></li>
                </ol>
            </div>'',
		@NoncreditText nvarchar(max) =
            ''<div>
                <p>This noncredit program map from the 2023-2024 catalog year represents one possible pathway to complete this program and is intended for students who do not need credit for transfer, but who wish to obtain knowledge and skills needed for entry level positions in the workforce or obtain short-term vocational skills needed for immediate employment.</p>
                <p>Noncredit Programs at Chabot College are an excellent low-cost way to earn a certificate since noncredit courses are tuition FREE. Courses focus on skill development and growth, preparing students for employment and future academic coursework. Plus, you can repeat a noncredit course as many times as you want!</p>
                <p>I''''m ready to get started. What do I do next?</p>
				<ol>
                    <li>Review this program map to get an overview of the required courses</li>
                    <li>Meet with a counselor to develop your customized student education plan <a href="http://www.chabotcollege.edu/counseling">www.chabotcollege.edu/counseling</a></li>
                    <li>Use DegreeWorks, an online student education planning tool, to track your progress toward graduation <a href="http://www.chabotcollege.edu/admissions/degreeworks">www.chabotcollege.edu/admissions/degreeworks</a></li>
                </ol>
            </div>''

SELECT 0 AS [Value], 
	CASE
		when p.Tier2_OrganizationEntityId = 27 --Apprenticeship
			then concat(@headerText, @ApprenticeshipText)
		When p.AwardTypeId in (7,8) --Certificates
				and p.Tier2_OrganizationEntityId != 27
			then concat(@headerText, @NoncreditText)
		Else concat(@headerText, @instructionalText)
	END AS [Text]
From program p
where p.id = @entityId'

update MetaForeignKeyCriteriaClient
set CustomSql = @sql,
	ResolutionSql = @sql
WHERE id = 56173722

update MetaTemplate
set LastUpdatedDate = GETDATE()
From MetaTemplate mt
	inner join MetaSelectedSection mss on mt.MetaTemplateId = mss.MetaTemplateId
	Inner join MetaSelectedField msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
		and msf.MetaForeignKeyLookupSourceId = 56173722