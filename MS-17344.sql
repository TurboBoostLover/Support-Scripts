USE [victorvalley];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17529';
DECLARE @Comments nvarchar(Max) = 
	'Fix some help text';
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
DECLARE @BadSections TABLE (SecId int, Secnam NVARCHAR(MAX), TempId int)
INSERT INTO @BadSections
SELECT MetaSelectedSectionId, SectionName, MetaTemplateId FROM MetaSelectedSection WHERE SectionDescription like '%green%' order by SectionName

UPDATE MetaSelectedSection
SET SectionDescription = '<p style="color:green;"><i><b>DEIA Opportunity:</b></p><p> Incorporate <b>diverse contributions to the discipline</b>, use <b>inclusive language</b> and/or identify opportunities for students to <b>connect content to their sociocultural backgrounds</b>.</i></p>'
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @BadSections WHERE Secnam = 'Course Content'
)

UPDATE MetaSelectedSection
SET SectionDescription = '<p style="color:green;"><i><b>DEIA Opportunity:</b></p><p> Use resources that students can access with <b>free</b>, at <b>low cost, culturally responsive</b> textbooks, and or books whose authors represent the diversity of our student population.</i><br /><br />Textbooks such as the following are appropriate:</p>'
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @BadSections WHERE Secnam = 'Course Materials'
)

UPDATE MetaSelectedSection
SET SectionDescription = '<p style="color:green;"><i><b>DEIA Opportunity:</b></p><p> Offer courses in <b>different distance education modalities</b> to maximize flexibility for students.</i><br /><br /><p><span style="font-size:1em"> Distance Education is instruction in which the instructor and student are separated by distance and interact through the assistance of communication technology (§ 55200)</span></p></p>'
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @BadSections WHERE Secnam = 'Distance Education'
)

UPDATE MetaSelectedSection
SET SectionDescription = '<p style="color:green;"><i><b>DEIA Opportunity:</b></p><p> Provide sample assignments that reflect culturally responsive strategies (e.g. assignments that address <b>real-world issues</b>, incorporate <b>multiple perspectives</b>, connect content to students’ <b>cultural context</b>, and encourage <b>collaboration</b>).</i></p>'
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @BadSections WHERE Secnam = 'Example Assignments'
)

UPDATE MetaSelectedSection
SET SectionDescription = '<p style="color:green;"><i><b>DEIA Opportunity:</b></p><p> Incorporate <b>diverse contributions to the discipline</b>, use <b>inclusive language</b> and/or identify opportunities for students to <b>connect content to their sociocultural backgrounds</b>.</i></p>'
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @BadSections WHERE Secnam = 'Lab Content'
)

UPDATE MetaSelectedSection
SET SectionDescription = '<p style="color:green;"><i><b>DEIA Opportunity:</b></p><p> Utilize a <b>variety of assessment</b> strategies as evidence of student learning and proficiency.</i><br /><br />Multiple measures may include, but are not limited to, the following:</p>'
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @BadSections WHERE Secnam = 'Methods of Evaluation'
)

UPDATE MetaSelectedSection
SET SectionDescription = '<p style="color:green;"><i><b>DEIA Opportunity:</b></p><p> Incorporate <b>equity-minded instruction, active-learning</b>, and <b>personalized learning strategies</b> into the course.</i></p>'
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @BadSections WHERE Secnam = 'Methods of Instruction'
)

UPDATE MetaSelectedSection
SET SectionDescription = '<p style="color:green;"><b>DEIA Opportunity:</b></p><p> Incorporate <b>equity-minded instruction, active-learning,</b> and <b>personalized learning strategies</b> into the course.</p>'
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @BadSections WHERE Secnam = 'Objectives'
)

UPDATE MetaSelectedSection
SET SectionDescription = '<p style="color:green;"><b>DEIA Opportunity:</b></p><p> Incorporate <b>equity-minded instruction, active-learning,</b> and <b>personalized learning strategies</b> into the course.</p>'
WHERE MetaSelectedSectionId in (
	SELECT SecId FROM @BadSections WHERE Secnam = 'Student Learning Outcomes'
)

UPDATE MetaTemplate
sET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (
	SELECT TempId FROM @BadSections
)