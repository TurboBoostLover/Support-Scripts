USE [peralta];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-17092';
DECLARE @Comments nvarchar(Max) = 
	'Add Hierarchy';
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
--14 Department
--15 Division

DECLARE @Div TABLE (id int, Tit NVARCHAR(MAX))

INSERT INTO OrganizationEntity
(OrganizationTierId, Title, ClientId, StartDate)
output inserted.Id, inserted.Title INTO @Div
VALUES
(15, 'Office of the President', 5, GETDATE()),
(15, 'Vice President of Instruction', 5, GETDATE()),
(15, 'Vice President of Administrative Services', 5, GETDATE()),
(15, 'Vice President of Student Services', 5, GETDATE()),
(15, 'Dean of Counseling, Student Equity, & Achievement', 5, GETDATE()),
(15, 'Dean of Enrollment Services', 5, GETDATE())

DECLARE @Dep TABLE (Id int, Tit NVARCHAR(MAX))

INSERT INTO OrganizationEntity
(OrganizationTierId, Title, ClientId, StartDate)
output inserted.Id, inserted.Title INTO @Dep
VALUES
(14, 'Vice President of Instruction', 5, GETDATE()),
(14, 'Vice President of Administrative Services', 5, GETDATE()),
(14, 'Vice President of Student Services', 5, GETDATE()),
(14, 'Planning, Research & Institutional Effectiveness', 5, GETDATE()),
(14, 'Liberal Arts & Social Sciences Division Office', 5, GETDATE()),
(14, 'Math Science and Technology Division Office', 5, GETDATE()),
(14, 'Allied Health and Public Safety Division Office', 5, GETDATE()),
(14, 'Custodial Services', 5, GETDATE()),
(14, 'Facilities', 5, GETDATE()),
(14, 'Information Technology', 5, GETDATE()),
(14, 'Mail Services', 5, GETDATE()),
(14, 'Warehouse', 5, GETDATE()),
(14, 'Dean of Enrollment Services', 5, GETDATE()),
(14, 'Student Activities & Campus Life', 5, GETDATE()),
(14, 'Career Center', 5, GETDATE()),
(14, 'Counseling', 5, GETDATE()),
(14, 'First Year Experience', 5, GETDATE()),
(14, 'Puente', 5, GETDATE()),
(14, 'Sankofa', 5, GETDATE()),
(14, 'Transfer Center', 5, GETDATE()),
(14, 'Welcome Center', 5, GETDATE()),
(14, 'Wellness Center', 5, GETDATE()),
(14, 'Admissions and Records', 5, GETDATE()),
(14, 'Athletics Services', 5, GETDATE()),
(14, 'CalWORKs', 5, GETDATE()),
(14, 'Extended Opportunity Programs and Services', 5, GETDATE()),
(14, 'Financial Aid', 5, GETDATE()),
(14, 'NextUp', 5, GETDATE()),
(14, 'Orientation', 5, GETDATE()),
(14, 'Outreach', 5, GETDATE()),
(14, 'Student Accessibility Services', 5, GETDATE()),
(14, 'Veterans Affairs', 5, GETDATE())

DECLARE @1 int = (SELECT Id FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 15 and Title = 'Office of the President')
DECLARE @2 int = (SELECT Id FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 15 and Title = 'Vice President of Instruction')
DECLARE @3 int = (SELECT Id FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 15 and Title = 'Vice President of Administrative Services')
DECLARE @4 int = (SELECT Id FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 15 and Title = 'Vice President of Student Services')
DECLARE @5 int = (SELECT Id FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 15 and Title = 'Dean of Counseling, Student Equity, & Achievement')
DECLARE @6 int = (SELECT Id FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 15 and Title = 'Dean of Enrollment Services')

INSERT INTO OrganizationLink
(Child_OrganizationEntityId, Parent_OrganizationEntityId, ClientId, StartDate)
SELECT Id, @1, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Vice President of Instruction'
UNION
SELECT Id, @1, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Vice President of Administrative Services'
UNION
SELECT Id, @1, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Vice President of Student Services'
UNION
SELECT Id, @1, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Planning, Research & Institutional Effectiveness'
UNION
SELECT Id, @2, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Liberal Arts & Social Sciences Division Office'
UNION
SELECT Id, @2, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Math Science and Technology Division Office'
UNION
SELECT Id, @2, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Allied Health and Public Safety Division Office'
UNION
SELECT Id, @3, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Custodial Services'
UNION
SELECT Id, @3, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Facilities'
UNION
SELECT Id, @3, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Information Technology'
UNION
SELECT Id, @3, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Mail Services'
UNION
SELECT Id, @3, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Warehouse'
UNION
SELECT Id, @4, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Dean of Enrollment Services'
UNION
SELECT Id, @4, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Student Activities & Campus Life'
UNION
SELECT Id, @4, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Career Center'
UNION
SELECT Id, @4, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Counseling'
UNION
SELECT Id, @4, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'First Year Experience'
UNION
SELECT Id, @4, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Puente'
UNION
SELECT Id, @4, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Sankofa'
UNION
SELECT Id, @4, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Transfer Center'
UNION
SELECT Id, @4, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Welcome Center'
UNION
SELECT Id, @4, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Wellness Center'
UNION
SELECT Id, @5, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Admissions and Records'
UNION
SELECT Id, @5, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Athletics Services'
UNION
SELECT Id, @6, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'CalWORKs'
UNION
SELECT Id, @6, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Extended Opportunity Programs and Services'
UNION
SELECT Id, @6, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Financial Aid'
UNION
SELECT Id, @6, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'NextUp'
UNION
SELECT Id, @6, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Orientation'
UNION
SELECT Id, @6, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Outreach'
UNION
SELECT Id, @6, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Student Accessibility Services'
UNION
SELECT Id, @6, 5, GETDATE() FROM OrganizationEntity WHERE ClientId = 5 and OrganizationTierId = 14 and Title = 'Veterans Affairs'