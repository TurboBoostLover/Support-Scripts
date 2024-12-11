USE [clovis];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'IMP-15913';
DECLARE @Comments nvarchar(Max) = 
	'Add look up and look up data';
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
INSERT INTO LookupTypeGroup
(GroupName, GroupKey)
VALUES
('SUO', 'SUO')

DECLARE @ID INT = SCOPE_IDENTITY()

INSERT INTO LookupType
(Title, TableName, SortOrder, LookupTypeGroupId)
VALUES
('SUO''s', 'OrganizationEntityOutcome', 3, @ID)

DECLARE @ID2 INT = SCOPE_IDENTITY()

INSERT INTO ClientLookupType
(ClientId, LookupTypeId, CustomTitle, DontManage)
VALUES
(1, @ID2, 'SUO''s', 1)

INSERT INTO OrganizationEntityOutcome
(OrganizationEntityId, Outcome, StartDate, ClientId)
VALUES
('1', 'Students will be aware of transfer course/credit equivalencies in a timely manner.', GETDATE(), 1),		--Admissions and Records
('1', 'Students will be aware of how Advanced Placement (AP) credit is awarded for CCC.', GETDATE(), 1),
('1', 'Students and staff will be provided a more efficient process to pay fees.', GETDATE(), 1),
('2', 'Students will gain the knowledge to be able to demonstrate the proper way to run a formal meeting and governance processes.', GETDATE(), 1),		--ASG
('2', 'Students will participate in two (2) leadership retreats per academic year.', GETDATE(), 1),
('2', 'Enhance awareness and empower students to advocate for community college education at the local, state, and federal levels.', GETDATE(), 1),
('3', 'Students will learn to complete their FAFSA applications earlier for their second year with CCC.', GETDATE(), 1),		--Financial Aid
('3', 'Students will know the availability of financial aid resources and application cycle.', GETDATE(), 1),
('3', 'Students will become aware of the scholarships that are available through CCC and will complete a scholarship application.', GETDATE(), 1),
('4', 'Students will report benefit(s) from their nursing consultation visits.', GETDATE(), 1),		--Health Services
('4', 'Students will report intent to adopt at least one recommended activity/change to improve their health and wellness after receiving instruction from the nurse.', GETDATE(), 1),
('5', 'The library provides a welcoming physical and virtual space that meets the needs of our College.', GETDATE(), 1),	--Library
('5', 'The library provides a physical and digital collection that meets students, staff, and faculty academic, professional development, and lifelong learning needs. (ACRL Principle 5)', GETDATE(), 1),
('5', 'The library provides high quality information literacy instruction to Clovis Community College students.', GETDATE(), 1),
('5', 'The library provides research and reference assistance to students, staff, and faculty on demand.', GETDATE(), 1),
('6', 'Matriculation – Students will complete steps to successfully matriculate to CCC/SCCCD (RTG)  ', GETDATE(), 1),		--Outreach
('6', 'Connecting Support Programs/Services – Students will connect with appropriate support programs/services. (Crush Days)', GETDATE(), 1),
('6', 'Community Events – Students will be more informed about available services and programs. (Comm Event Count)', GETDATE(), 1),
('7', 'Student Activities will increase sense of belonging among Black, African American, and Latinx students by hosting culturally relevant and inclusive programming. ', GETDATE(), 1),		--Student Activities
('7', 'Student activities will collaborate with community organizations to bring essential resources to campus. ', GETDATE(), 1),
('7', 'Promote student activities and inform students of the resources available in the student center.  ', GETDATE(), 1),
('8', 'New students will be able to identify at least two basic needs resources1 after participating in a classroom or campus presentation. [ex. Crush Days or completing the online orientation].', GETDATE(), 1),		--Basic Needs & Retention Services
('8', 'Low-income students who utilize at least one basic needs service  will be more likely to be retained  compared to low-income students who do not utilize any basic needs services. ', GETDATE(), 1),
('8', 'Low-income students who utilize at least one basic needs service will be more likely to be persistence  compared to low-income students who do not utilize any basic needs services.', GETDATE(), 1),
('9', 'Students who utilize the equity book voucher program are more likely to complete their courses that term. ', GETDATE(), 1),		--Equity Book Voucher Program
('9', '70% of students who utilize the Equity Book Voucher Program will have a satisfactory experience with the book voucher process. ', GETDATE(), 1),
('10', '70% of students who participate in AASI will “Agree or Strongly Agree” to having an increased sense of belonging after participating in the Welcome Black event. ', GETDATE(), 1),		--African American Sucess Initiative
('10', 'Students who participate in AASI will increase their self-efficiency in their ability to attain their educational goals. ', GETDATE(), 1),
('11', '70% of students who participant in the Men of Color Initiative (MoCI) will “Agree or Strongly Agree” to having an increased sense of belonging.', GETDATE(), 1),		--Men of Color Initative
('11', 'At least 5% of male students of color on campus will engage in co-curricular programming with MoCI.     ', GETDATE(), 1),
('12', 'Latinx, low-income STEM students will be able to identify at least two success strategies after meeting with PODER staff.  ', GETDATE(), 1),		--Providing Opportunities Designed to Educate and Recognize
('12', 'Latinx, STEM students who meet with PODER staff will have a 3% increase in the Fall-to-Fall persistence rate compared to those Latinx, STEM students who do not meet with PODER staff.', GETDATE(), 1),
('13', 'Students will be able to identify learning strategies to help them succeed.', GETDATE(), 1),		--Tutorial Services
('13', 'Students will receive the opportunity to practice academic skills with peer guidance. ', GETDATE(), 1)


SELECT * FROM Lookup01
SELECT * FROM Lookup14
SELECT * FROM OrganizationEntityOutcome