USE [frc];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber NVARCHAR(20) = 'MS-13104';
DECLARE @Comments NVARCHAR(Max) = 
	'Batch Update Courses';
DECLARE @Developer NVARCHAR(50) = 'Nathan Westergard';
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
DECLARE @Music int = (SELECT Id FROM Subject WHERE Title = 'Music')
DECLARE @MusicCourseQuality NVARCHAR(MAX) = '
The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @MusicStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @MusicAccommodatingStudentswithDisabilities NVARCHAR(MAX) = '
This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @Geology int = (SELECT Id FROM Subject WHERE Title = 'Geology')
DECLARE @GeologyCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @GeologyStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @GeologyAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @Sociology int = (SELECT Id FROM Subject WHERE Title = 'Sociology')
DECLARE @SociologyCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @SociologyStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @SociologyAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @History int = (SELECT Id FROM Subject WHERE Title = 'History')
DECLARE @HistoryCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @HistoryStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @HistoryAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @PoliticalScience int = (SELECT Id FROM Subject WHERE Title = 'Political Science')
DECLARE @PoliticalScienceCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @PoliticalScienceStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @PoliticalScienceAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @Biology int = (SELECT Id FROM Subject WHERE Title = 'Biology')
DECLARE @BiologyCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @BiologyStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @BiologyAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @English int = (SELECT Id FROM Subject WHERE Title = 'English')
DECLARE @EnglishCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @EnglishStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @EnglishAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @CulinaryArts int = (SELECT Id FROM Subject WHERE Title = 'Nutrition, Food and Culinary Arts')
DECLARE @CulinaryArtsCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @CulinaryArtsStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @CulinaryArtsAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @Anthro int = (SELECT Id FROM Subject WHERE Title = 'Anthropology')
DECLARE @AnthroCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @AnthroStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @AnthroAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @Chemistry int = (SELECT Id FROM Subject WHERE Title = 'Chemistry')
DECLARE @ChemistryCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @ChemistryStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @ChemistryAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @Nursing int = (SELECT Id FROM Subject WHERE Title = 'Nursing')
DECLARE @NursingCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @NursingStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @NursingAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @ADJM int = (SELECT Id FROM Subject WHERE Title = 'Administration of Justice')
DECLARE @ADJMCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @ADJMStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @ADJMAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
--DECLARE @Languages int = (SELECT Id FROM Subject WHERE Title = 'Languages')---------
DECLARE @Psychology int = (SELECT Id FROM Subject WHERE Title = 'Psychology')
DECLARE @PsychologyCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @PsychologyStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @PsychologyAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @Bus int = (SELECT Id FROM Subject WHERE Title = 'Business')
DECLARE @BusCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @BusStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @BusAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @Geography int = (SELECT Id FROM Subject WHERE Title = 'Geography')
DECLARE @GeographyCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @GeographyStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @GeographyAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @Humanities int = (SELECT Id FROM Subject WHERE Title = 'Humanities')
DECLARE @HumanitiesCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @HumanitiesStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @HumanitiesAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @PhysicalScience int = (SELECT Id FROM Subject WHERE Title = 'Physical Science')
DECLARE @PhysicalScienceCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @PhysicalScienceStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @PhysicalScienceAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @ENVR1 int = (SELECT Id FROM Subject WHERE Title = 'Environmental Studies')
DECLARE @ENVR2 int = (SELECT Id FROM Subject WHERE Title = 'FORS')
DECLARE @ENVRNEED NVARCHAR(MAX) = 'While FRC had historically authorized and scheduled numerous classes through distance education and correspondence education modalities, the public health pandemic associated with COVID-19 necessitated pushing significantly more classes into remote modalities in the name of public health.  As such, this document represents the Curriculum Committee’s approach to establishing DE addendums at the departmental level.  The option of online/hybrid course delivery will benefit student scheduling, particularly in cases of scheduling conflicts, and allow flexibility with instructor staffing. The College is working toward increasing online course offerings, which may contribute to increased interest and enrollment.'
DECLARE @ENVRFost NVARCHAR(MAX) = 'For courses offered completely online, students will engage in the class on a weekly basis. In hybrid courses, activities may vary in methods of supporting in-person course-work. Examples include weekly quizzes, films, readings, discussions, and/or exams. Readings, lectures, and links to external sources will be available online. The instructor will communicate with the students through written feedback on their assignments, emails, course announcements, and interaction through asynchronous discussions and forums. The campus-wide early alert system (within the first six weeks of the semester) allows instructors to identify students struggling in such courses, and identify additional academic resources, including tutoring.
In online courses, instructors will maintain regular and effective interaction among students. Instructions on activities will be provided to students enrolled in hybrid courses. Student–to–student interaction can be accomplished through: messaging via the LMS, discussion forums, and asynchronous/synchronous group communications using the WorldWideWhiteboard or conferencing tools, collaborative projects, or group blogs. The instructor will establish guidelines for frequency and parameters of the contact.
'
DECLARE @ENVRAdd NVARCHAR(MAX) = 'The ISP Office coordinates with prison sites and educational staff, students, and FRC instructors to supply material and resources as needed.  '
DECLARE @ENVRCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline. Assignments will align with the defined student learning outcomes. Materials used each semester align with those in the approved COR, and assignments for each mode of delivery are created to assess student learning related to the course SLOs. This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
For ISP, course materials are periodically reviewed by lead-faculty in the program and the ISP administrative staff. The ISP curriculum review faculty also systematically reviews courses and works with instructors on course revisions. 
•	All ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. 
•	In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course. 
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @ENVRStudentIdentityVerification NVARCHAR(MAX) = 'There are a number of ways student identity may be verified. Online students may take a syllabus quiz the first week of class, will be asked to attest to their identity, and pledge that the person logging into the course and submitting the work will be the student enrolled in the class. Weekly assignments also ensure user authenticity as do discussions, the use of plagiarizing detection software (e.g., TurnItIn), and the instructor checking in with the student via email, SMS (texting), and/or social media. User login data and IP address data will also be monitored. The instructor may use video-conferencing tools throughout the semester.
For ISP, students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.  
'
DECLARE @ENVRAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.

Distance education courses must also be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with prison educational staff, FRC’s Disability Support Program for Students offers support, when resources are available, to students with temporary or permanent disabilities.  
'
--DECLARE @StudioArts int = (SELECT Id FROM Subject WHERE Title = 'Studio Arts')--------
DECLARE @Math int = (SELECT Id FROM Subject WHERE Title = 'Mathematics')
DECLARE @MathCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @MathStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @MathAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @COLL int = (SELECT Id FROM Subject WHERE Title = 'College')
DECLARE @COLLCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @COLLStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
ISP
Students complete and sign a Registration Application in front of a California Department of Corrections and Rehabilitation education coordinator who sends the application to FRC''s ISP Office for processing and delivery to the Admissions and Records Office. Course assignments and exams are updated every semester to minimize the potential for plagiarism, and midterm and final exams are proctored.
'
DECLARE @COLLAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @Equine int = (SELECT Id FROM Subject WHERE Title = 'Equine')
DECLARE @EquineCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @EquineStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @EquineAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @Agriculture1 int = (SELECT Id FROM Subject WHERE Title = 'Agriculture, General')
DECLARE @Agriculture2 int = (SELECT Id FROM Subject WHERE Title = 'Agriculture, Agriculture Business')
DECLARE @Agriculture3 int = (SELECT Id FROM Subject WHERE Title = 'Agriculture, Animal Science')
DECLARE @Agriculture4 int = (SELECT Id FROM Subject WHERE Title = 'Agriculture, Equine Studies')
DECLARE @Agriculture5 int = (SELECT Id FROM Subject WHERE Title = 'Agriculture, Mechanized Agriculture')
DECLARE @Agriculture6 int = (SELECT Id FROM Subject WHERE Title = 'Agriculture, Plant Science')
DECLARE @AgricultureCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @AgricultureStudentIdentityVerification NVARCHAR(MAX) = 'Student Identity Verification
Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @AgricultureAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @Theatre int = (SELECT Id FROM Subject WHERE Title = 'Theatre')
DECLARE @TheatreCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @TheatreStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @TheatreAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @Physics int = (SELECT Id FROM Subject WHERE Title = 'Physics')
DECLARE @PhysicsCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @PhysicsStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @PhysicsAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @EMT int = (SELECT Id FROM Subject WHERE Title = 'Emergency Medical Technician')
DECLARE @EMTCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @EMTStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @EMTAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @Philosophy int = (SELECT Id FROM Subject WHERE Title = 'Philosophy')
DECLARE @PhilosophyCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @PhilosophyStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @PhilosophyAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @ORL int = (SELECT Id FROM Subject WHERE Title = 'Outdoor Recreation Leadership')
DECLARE @ORLCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @ORLStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @ORLAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @ECE1 int = (SELECT Id FROM Subject WHERE Title = 'Early Childhood Education')
DECLARE @ECE2 int = (SELECT Id FROM Subject WHERE Title = 'CWEE')
DECLARE @ECECourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
ISP course materials are regularly reviewed by program faculty and the ISP administrative staff.
ISP courses are formatted into seven learning modules. Assignments are typically due every two weeks. In addition to readings from a course textbook, modules include course and lecture notes meant to replicate content provided in a face-to-face section of the course.
The ISP Office works with instructors to provide supplemental course material to students as needed or requested.
'
DECLARE @ECEStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @ECEAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
In coordination with staff at corrections facilities, accommodations will be made for with students with temporary or permanent disabilities, when possible.
'
DECLARE @EnvironmentalStudies int = (SELECT Id FROM Subject WHERE Title = 'Environmental Studies')
DECLARE @EnvironmentalStudiesCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @EnvironmentalStudiesStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @EnvironmentalStudiesAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @Education int = (SELECT Id FROM Subject WHERE Title = 'Education')
DECLARE @EducationCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @EducationStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @EducationAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'
DECLARE @ASL int = (SELECT Id FROM Subject WHERE Title = 'American Sign Language')
DECLARE @ASLCourseQuality NVARCHAR(MAX) = 'The course will uphold and maintain the rigor required for study in the discipline and align with the approved course outline of record.
•	Assignments will align with the student learning outcomes in the approved COR.
•	Course materials will reflect those in the approved COR
This consistency ensures the maintenance of college-level standards. All course materials are reviewed by faculty in the field and the peer review team assembled during instructor evaluation cycle.
'
DECLARE @ASLStudentIdentityVerification NVARCHAR(MAX) = 'Online
•	Students may take a syllabus quiz (or other form of a course agreement) the first week of class asking them to attest to their identity, and agree that only they, as the student enrolled in the class, will be the person logging into the course and submitting work.
•	Weekly assignments ensure user authenticity.
•	Instructors may use plagiarizing detection software (e.g., TurnItIn).
•	Instructor may check in with the student via email, text, and/or social media.
•	User login data and IP address data may be monitored.
•	The instructor may use video-conferencing tools throughout the semester.
'
DECLARE @ASLAccommodatingStudentswithDisabilities NVARCHAR(MAX) = 'This is required by the Americans with Disabilities Act (42 U.S.C. § 12100 et seq.) Section 508 of the Rehabilitation Act of 1973, CA Gov Code 11135, and the CCC Distance Education Access Guidelines.
Students with disabilities documented with the Disability Support Program for Students (DSPS) office will be accommodated by receiving extra time on exams, or using other accommodations identified, suggested, and made available by the DSPS Office.
Distance education courses will be accessible to students with disabilities. These requirements also apply to any outside websites, which will be used, including publisher content. See the DE Handbook for more information.
'

UPDATE cde
SET cde.EnsureStudent = CASE		--coursequality
	WHEN c.SubjectId = @Music then CAST( @MusicCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Geology then CAST( @GeologyCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Sociology then CAST( @SociologyCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @History then CAST( @HistoryCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @PoliticalScience then CAST( @PoliticalScienceCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Biology then CAST( @BiologyCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @English then CAST( @EnglishCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @CulinaryArts then CAST( @CulinaryArtsCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Anthro then CAST( @AnthroCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Chemistry then CAST( @ChemistryCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Nursing then CAST( @NursingCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ADJM then CAST( @ADJMCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Psychology then CAST( @PsychologyCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Bus then CAST( @BusCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Geography then CAST( @GeographyCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Humanities then CAST( @Humanities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @PhysicalScience then CAST( @PhysicalScienceCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId in (@ENVR1, @ENVR2) then CAST( @ENVRCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Math then CAST( @MathCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @COLL then CAST( @COLLCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Equine then CAST( @EquineCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId in (@Agriculture1, @Agriculture2, @Agriculture3, @Agriculture4, @Agriculture5, @Agriculture6) then CAST( @AgricultureCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Theatre then CAST( @TheatreCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Physics then CAST( @PhysicsCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @EMT then CAST( @EMTCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Philosophy then CAST( @PhilosophyCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ORL	then CAST( @ORLCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ECE1 then CAST( @ECECourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ECE2 then CAST( @ECECourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @EnvironmentalStudies then CAST( @EnvironmentalStudiesCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Education then CAST( @EducationCourseQuality AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ASL then CAST( @ASLCourseQuality AS NVARCHAR(MAX))
	ELSE COALESCE(cde.EnsureStudent, '')
	END
, cde.SpoDiffer = CASE			--StudentId
	WHEN c.SubjectId = @Music then CAST( @MusicStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Geology then CAST( @GeologyStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Sociology then CAST( @SociologyStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @History then CAST( @HistoryStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @PoliticalScience then CAST( @PoliticalScienceStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Biology then CAST( @BiologyStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @English then CAST( @EnglishStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @CulinaryArts then CAST( @CulinaryArtsStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Anthro then CAST( @AnthroStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Chemistry then CAST( @ChemistryStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Nursing then CAST( @NursingStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ADJM then CAST( @ADJMStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Psychology then CAST( @PsychologyStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Bus then CAST( @BusStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Geography then CAST( @GeographyStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Humanities then CAST( @Humanities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @PhysicalScience then CAST( @PhysicalScienceStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId in (@ENVR1, @ENVR2) then CAST( @ENVRStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Math then CAST( @MathStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @COLL then CAST( @COLLStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Equine then CAST( @EquineStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId in (@Agriculture1, @Agriculture2, @Agriculture3, @Agriculture4, @Agriculture5, @Agriculture6) then CAST( @AgricultureStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Theatre then CAST( @TheatreStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Physics then CAST( @PhysicsStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @EMT then CAST( @EMTStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Philosophy then CAST( @PhilosophyStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ORL	then CAST( @ORLStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ECE1 then CAST( @ECEStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ECE2 then CAST( @ECEStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @EnvironmentalStudies then CAST( @EnvironmentalStudiesStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Education then CAST( @EducationStudentIdentityVerification AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ASL then CAST( @ASLStudentIdentityVerification AS NVARCHAR(MAX))
	ELSE COALESCE(cde.SpoDiffer, '')
	END
, cde.Disabilities = CASE				--Disabilites
	WHEN c.SubjectId = @Music then CAST( @MusicAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Geology then CAST( @GeologyAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Sociology then CAST( @SociologyAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @History then CAST( @HistoryAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @PoliticalScience then CAST( @PoliticalScienceAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Biology then CAST( @BiologyAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @English then CAST( @EnglishAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @CulinaryArts then CAST( @CulinaryArtsAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Anthro then CAST( @AnthroAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Chemistry then CAST( @ChemistryAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Nursing then CAST( @NursingAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ADJM then CAST( @ADJMAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Psychology then CAST( @PsychologyAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Bus then CAST( @BusAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Geography then CAST( @GeographyAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Humanities then CAST( @Humanities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @PhysicalScience then CAST( @PhysicalScienceAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId in (@ENVR1, @ENVR2) then CAST( @ENVRAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Math then CAST( @MathAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @COLL then CAST( @COLLAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Equine then CAST( @EquineAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId in (@Agriculture1, @Agriculture2, @Agriculture3, @Agriculture4, @Agriculture5, @Agriculture6)then CAST( @AgricultureAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Theatre then CAST( @TheatreAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Physics then CAST( @PhysicsAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @EMT then CAST( @EMTAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Philosophy then CAST( @PhilosophyAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ORL	then CAST( @ORLAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ECE1 then CAST( @ECEAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ECE2 then CAST( @ECEAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @EnvironmentalStudies then CAST( @EnvironmentalStudiesAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @Education then CAST( @EducationAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	WHEN c.SubjectId = @ASL then CAST( @ASLAccommodatingStudentswithDisabilities AS NVARCHAR(MAX))
	ELSE COALESCE(cde.Disabilities, '')
	END
	,cde.Justification = CASE 
	WHEN c.SubjectId in (@ENVR1, @ENVR2) then CAST( @ENVRNEED AS NVARCHAR(MAX))
	ELSE COALESCE(cde.Justification, '')
	END
	,cde.StudentDisExplain = CASE
	WHEN c.SubjectId in (@ENVR1, @ENVR2) then CAST( @ENVRFost AS NVARCHAR(MAX))
	ELSE COALESCE(cde.StudentDisExplain, '')
	END
	,cde.AdditionalResource = CASE
	WHEN c.SubjectId in (@ENVR1, @ENVR2) then CAST( @ENVRAdd AS NVARCHAR(MAX))
	ELSE COALESCE(cde.AdditionalResource, '')
	END
FROM CourseDistanceEducation AS cde
INNER JOIN Course AS c on cde.CourseId = c.Id
WHERE c.StatusAliasId in (655, 656, 660) --Active, Approved, In Review
AND c.Active = 1