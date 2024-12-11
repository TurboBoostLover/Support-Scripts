USE [imperial];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-16898';
DECLARE @Comments nvarchar(Max) = 
	'Updated the links to be links for the catalog';
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
declare @atCode nvarchar(100) = (
	select aType.Code
	from Program p
		inner join AwardType aType on aType.Id = p.AwardTypeId
	where p.Id = @entityId
);

if (@atCode in (''A.A.'', ''A.S.'', ''A.A.-T'', ''A.S.-T''))
begin
	select 0 as [Value]
		, ''<b style="font-size: 16px;">Transfer Preparation</b><br /><p>Courses that fulfill major requirements for an associate degree at Imperial Valley College may not be the same as those required for completing the major at a transfer institution offering a bachelor''''s degree. Students who plan to transfer to a four-year college or university should schedule an appointment with an IVC Counselor to develop a student education plan (SEP) before
         beginning their program.</p><p>Transfer Resources:<br />
		<a href="https://www.ASSIST.org" target="_blank"><b>www.ASSIST.org – CSU and UC Articulation Agreements and Majors Search Engine</b></a><br />
		<a href="https://www.CSUMentor.edu" target="_blank"><b>www.CSUMentor.edu – CSU System Information</b></a><br />
		<a href="https://www.universityofcalifornia.edu/admissions/index.html" target="_blank"><b>www.universityofcalifornia.edu/admissions/index.html - UC System Information</b></a><br />
		<a href="https://www.aiccu.edu" target="_blank"><b>www.aiccu.edu – California Independent Colleges and Universities, Association of</b></a><br />
		<a href="https://www.wiche.edu/tuition-savings/wue" target="_blank"><b>www.wiche.edu/tuition-savings/wue - Western Undergraduate Exchange Programs</b></a></p>'' as [Text]
	;
end;
'

UPDATE MetaForeignKeyCriteriaClient 
SET CustomSql = @SQL
, ResolutionSql = @SQL
WHERE Id = 23

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT mss.MetaTemplateId FROM MetaSelectedSection AS mss
	INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE msf.MetaForeignKeyLookupSourceId = 23
)