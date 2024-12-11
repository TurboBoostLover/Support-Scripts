USE [chaffey];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13581';
DECLARE @Comments nvarchar(Max) = 
	'Change working on DE Report';
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
DECLARE @TABLE table (mss int, msf int, mt int)
INSERT INTO @TABLE
SELECT DISTINCT mss.MetaSelectedSectionId, msf.MetaSelectedFieldId, mt.MetaTemplateId
FROM MetaTemplateType mtt
	INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
	INNER JOIN MetaSelectedSection mss ON mss.MetaTemplateId = mt.MetaTemplateId
	INNER JOIN MetaSelectedSection mss2 on mss.MetaSelectedSection_MetaSelectedSectionId = mss2.MetaSelectedSectionId
	INNER JOIN MetaSelectedField msf on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
WHERE mt.Active = 1 
	AND mtt.EntityTypeId = 1
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
	AND mtt.IsPresentationView = 1
	AND mss.SectionName = '<br>Regular and Effective Contact'
	AND mss2.SectionName = 'NewDEPage'							--string compare to compare section with only static text in it to the tab name 

DECLARE @mss int = (SELECT mss FROM @TABLE)
DECLARE @msf int = (SELECT msf FROM @TABLE)
DECLARE @MT int = (SELECT mt FROM @TABLE)

-- Variable: Replacement static text
DECLARE @NewText nvarchar(MAX) =
'<div style = "Color: Purple">
	This section outlines a variety of "best practice" instructional pedagogies for developing and maintaining regular and substantive interaction. 
	<b> NOTE: </b>
	There are many ways to demonstrate regular and substantive interaction, so not every element recommended by the department must be present in every section of the course.
</div>
<br>

Regular interaction refers to frequent, predictable, instructor-initiated opportunities for instructor-student interaction and monitoring of student engagement. Substantive refers to interaction that is academic in nature. Regular and substantive interaction can be accomplished in a number of ways, including through feedback on assignments, participation in discussion forums, and conferencing and other synchronous activities via Zoom. 
	<a href ="https://www.chaffey.edu/policiesandprocedures/docs/aps/4105-ap.pdf" target = "_blank"> AP 4105 </a>
	defines two elements that are central to regular and substantive interaction:

<ul>
	<li>
		<b> Instructor-to-student interaction </b> 
		is a key feature of distance education courses, and it is one factor that distinguishes it from correspondence courses. In course sections in which the instructional time is conducted in part or in whole through distance education, ensuring regular effective instructor/student contact guarantees the student receives the benefit of the instructor’s presence in the learning environment both as a provider of instructional information and as a facilitator of student learning. In a face-to-face instructional format, instructors are present at each course section meeting and interact via announcements, lectures, activities, and discussions that take a variety of forms. In course sections in which the instructional time is conducted in part or in whole through distance education, instructors provide similar experiences.
	</li>
	<li>
		<b> Student-to-student interaction </b> 
		is also a key feature of distance education, and it is another factor that distinguishes it from correspondence courses. These forms of contact are also required by federal regulatory requirements, state education codes, and the Accrediting Commission for Community and Junior Colleges (ACCJC), and are recommended by the Statewide Academic Senate for Community Colleges.
	</li>

</ul>

Regular and substantive interaction is a California Title V educational requirement that requires instructors to incorporate instructor-initiated, regular, substantive interaction into online and any online portion of hybrid course design and delivery. This means that it is the 
<b> responsibility of the instructor </b>
to initiate interaction with students, provide contact information to students, make announcements, question and involve them in discussions, reach out to them when they are absent or missing work, provide meaningful feedback on assignments, and monitor their overall progress. It is also the responsibility of the instructor to design opportunities for students to interact with other students in the course via discussion boards, group collaboration, peer review, and other student-to-student engaged activities. 
<br>
<br>

This form outlines requirements for “Start of the Course” and creating opportunities for “Faculty-Initiated” and “Student-to-Student” interaction. It may also serve as an optional supplement to a hybrid or online course evaluation. 
<br>
<br>

Please note there are many ways to demonstrate regular and substantive interaction, so not all of these elements will be present in every course. For additional information and guidance, please utilize the
	<a href = "https://canvas.chaffey.edu/courses/2503/pages/regular-and-substantive-interaction" target = "_blank"> Regular and Substantive Interaction resources. </a>'; 


UPDATE MetaSelectedSection
SET SectionName = '<br>Regular and Substantive Interaction'
WHERE MetaSelectedSectionId = @mss

UPDATE MetaSelectedField
SET DisplayName = @NewText
WHERE MetaSelectedFieldId = @msf

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId = @MT