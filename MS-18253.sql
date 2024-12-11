USE [socccd];

/*
   Commit
									Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18253';
DECLARE @Comments nvarchar(Max) = 
	'Update question marks to correct symbols';
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

--Forms already been versioned and correct so these template ids are historical and can't change
UPDATE msf
SET DisplayName = CASE
WHEN msf.MetaAvailableFieldId = 1221 and mss.MEtaTemplateId = 76 THEN 'B. How does the unit''s mission support the mission of the college?'
WHEN msf.MetaAvailableFieldId = 4212 and mss.MEtaTemplateId = 76 THEN 'G. Review the provided equity gap data on course success rates by ethnicity for your instructional school/division or for the college. Research has shown that equity gaps result from a lack of equity-minded practices and policies at the institutional and programmatic levels. Rather than attributing equity gaps to student deficits, equity-mindedness involves interpreting inequitable outcomes as a signal that the college''s practices and policies are not working as intended. What is your unit doing to institute equity-minded policies and/or practices within the unit?'
WHEN msf.MetaAvailableFieldId = 4214 and mss.MEtaTemplateId = 76 THEN 'A2. How does the staffing structure impact the unit''s ability to fulfill its mission/objectives?'
WHEN msf.MetaAvailableFieldId = 4215 and mss.MEtaTemplateId = 76 THEN 'B1. What professional development opportunities are available to the unit''s management and staff?'
WHEN msf.MetaAvailableFieldId = 4217 and mss.MEtaTemplateId = 76 THEN 'C. What are the unit''s current personnel needs, if any?'
WHEN msf.MetaAvailableFieldId = 4218 and mss.MEtaTemplateId = 76 THEN 'D. Discuss the unit''s facilities, equipment, and technological infrastructure.'
WHEN msf.MetaAvailableFieldId = 1228 and mss.MEtaTemplateId = 76 THEN 'E. What are the unit''s current facilities needs, if any?'
WHEN msf.MetaAvailableFieldId = 1229 and mss.MEtaTemplateId = 76 THEN 'F. What are the unit''s current equipment needs, if any?'
WHEN msf.MetaAvailableFieldId = 1236 and mss.MEtaTemplateId = 76 THEN 'G. What are the unit''s current technology needs, if any?'
WHEN msf.MetaAvailableFieldId = 1237 and mss.MEtaTemplateId = 76 THEN 'H1. Describe the unit''s service, outreach, marketing, and/or economic development activities.'
WHEN msf.MetaAvailableFieldId = 4087 and mss.MEtaTemplateId = 76 THEN 'I. What are the unit''s current marketing needs, if any?'
ELSE DisplayName
END
FROM MetaSelectedField AS msf
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.MetaTemplateId in (76)
	and msf.MetaAvailableFieldId in (1221, 4212, 4214, 4215, 4217, 4218, 1228, 1229, 1236, 1237, 4087)

UPDATE msfa
SET Value = CASE
	WHEN msf.MetaAvailableFieldId = 1223 and mss.MetaTemplateId = 76 THEN 'The college''s strategic plan goals can be found under "Planning" at: <a target="blank" href="https://www.saddleback.edu/administration/office-planning-research-and-accreditation-opra">https://www.saddleback.edu/administration/office-planning-research-and-accreditation-opra</a>.'
	WHEN msf.MetaAvailableFieldId = 4091 and mss.MetaTemplateId = 77 THEN 'The college''s strategic plan goals can be found under "Planning" at: <a target="blank" href="https://www.saddleback.edu/administration/office-planning-research-and-accreditation-opra">https://www.saddleback.edu/administration/office-planning-research-and-accreditation-opra</a>.'
	ELSE Value
END
FROM MetaSelectedFieldAttribute AS msfa
INNER JOIN MetaSelectedField AS msf on msf.MetaSelectedFieldId = msfa.MetaSelectedFieldId
INNER JOIN MetaSelectedSection AS mss on msf.MetaSelectedSectionId = mss.MetaSelectedSectionId
	WHERE mss.MetaTemplateId in (76, 77)
	and msf.MetaAvailableFieldId in (1223,4091)
	and msfa.Name in ('helptext', 'SubText')

UPDATE MetaTemplate
SET LastUpdatedDate = GETDATE()
WHERE MetaTemplateId in (76, 77)