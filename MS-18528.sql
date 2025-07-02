USE [stpetersburg];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18528';
DECLARE @Comments nvarchar(Max) = 
	'Update Help text on report';
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
DECLARE @Id int = 113

DECLARE @SQL NVARCHAR(MAX) = '
select 0 as Value,
	''<style>@media print {a[href
	]:after {content: none !important;
	}
}</style>
    <div style="background-color: #EBF1DE!important;width: 40%;border: 1px solid black;font-size: 12px;float:left;padding:5px;"><b>Program Pathway</b> is a tool for students:
        <ul>
            <li>The course sequence is the recommended order in which to take program courses</li>
            <li>If a course indicates an SPC Certificate, all courses to complete that Certificate are noted</li>
            <li>If a course indicates an Industry Certification, only the last course to become eligible to sit for the certification exam is noted – contact <a target="_blank" href="mailto:GetCertified@spcollege.edu">GetCertified@spcollege.edu</a> for more information</li>
						<li>For additional program and course information, see the Program of Study and/or contact your Academic Advisor</li>
						<li>Course and sequence are subject to change – check the current version for your requirement term here <a href="https://www.spcollege.edu/future-students/degrees-training" target="_blank">www.spcollege.edu/future-students/degrees-training</a> and/or contact your Academic Advisor</li>
        </ul>
    </div>
	<div style="background-color: #EBF1DE!important;width: 55%;border: 1px solid black;font-size: 12px;float:right;padding:5px;"><h4 style="margin-block-start: auto;margin-block-end: auto;">COURSE TYPE KEY</h4>'' +
	dbo.ConcatWithSepOrdered_Agg(null,SortOrder,''<strong>'' + Title + '':</strong>  '' + [Description] + ''<br />'') + ''</div>'' as Text 
	from (select ProgramId, ROW_NUMBER() over(order by SortOrder) as SortOrder, Title,[Description] from CourseTypeProgram) a 
	where ProgramId IS NULL OR ProgramId = @entityId
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
WHERE msf.MetaForeignKeyLookupSourceId = @Id