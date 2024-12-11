USE [palomar];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-13975';
DECLARE @Comments nvarchar(Max) = 
	'Update Proposal Names and create new ones';
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
DECLARE @Table Table (id int, title nvarchar(max))

UPDATE ProposalType
SET Title = 'Course Deactivation-Noncredit'
WHERE Id = 42

UPDATE ProposalType
SET Title = 'Course Change-Noncredit'
WHERE Id = 41

UPDATE ProposalType
SET Title = 'Course Review-Credit'
WHERE Id = 5

UPDATE ProposalType
SET Title = 'Course Change-Credit'
WHERE Id = 4

UPDATE ProposalType
SET Title = 'Course Deactivation-Credit'
WHERE Id = 10

UPDATE ProposalType
SET Title = 'Course New-Credit'
WHERE Id = 1

UPDATE ProposalType
SET Title = 'Course Reactivation-Credit'
WHERE Id = 43

UPDATE ProposalType
SET Title = 'Technical Update-Credit ''for Instructional Services Use'''
WHERE Id = 15

UPDATE ProposalType
SET Title = 'Technical Deactivation - Credit ''for Instructional Services Use'''
WHERE Id = 47

UPDATE ProposalType
SET Title = 'Course Change-Noncredit'
WHERE Id = 44

UPDATE ProposalType
SET Title = 'Course New-Noncredit'
WHERE Id = 40
-------------------------------------------------------------
DECLARE @UserId int = (
SELECT Id FROM [User]
WHERE FirstName = 'Curriqunet'							--get user id
AND Username = 'SupportAdmin@CurriQunet.com'
)

EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 25, @Templatename = 'Course Review-Noncredit' --copy 

DECLARE @Templateid2 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new template
DECLARE @Templatetypeid int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of new template

EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Templateid2 , @metaTemplateTypeId = @Templatetypeid -- activates the new template
---------------------------------------------------------------------------------------------------------------------------------------------------
EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 25, @Templatename = 'Course Reactivation-Noncredit' --copy 

DECLARE @Templateid3 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new template
DECLARE @Templatetypeid2 int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of new template

EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Templateid3 , @metaTemplateTypeId = @Templatetypeid2 -- activates the new template
---------------------------------------------------------------------------------------------------------------------------------------------------
EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 25, @Templatename = 'Technical Course Deactivation-Noncredit ''for Instructional Services Use''' --copy 

DECLARE @Templateid4 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new template
DECLARE @Templatetypeid3 int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of new template

EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Templateid4 , @metaTemplateTypeId = @Templatetypeid3 -- activates the new template
---------------------------------------------------------------------------------------------------------------------------------------------------
EXEC spBuilderTemplateTypeCopy @clientId = 1, @userId = @UserId, @metaTemplateTypeId = 25, @Templatename = 'Technical Update-Noncredit ''for Instructional Services Use''' --copy 

DECLARE @Templateid5 int = (SELECT max(metaTemplateId) FROM MetaTemplate) --gets template id of new template
DECLARE @Templatetypeid4 int = (SELECT max(MetaTemplateTypeId) FROM MetaTemplateType) --gets temple type of new template

EXEC spBuilderTemplateActivate @clientId = 1, @metaTemplateId = @Templateid5 , @metaTemplateTypeId = @Templatetypeid4 -- activates the new template
---------------------------------------------------------------------------------------------------------------------------------------------------
INSERT INTO ProposalType
(ClientId, Title, EntityTypeId, ClientEntitySubTypeId, ProcessActionTypeId, MetaTemplateTypeId, Active, AvailableForLookup, AllowReactivation, AllowMultipleApproved, ReactivationRequired, OriginatorOnly, ClientEntityTypeId, CloneRequired, AllowDistrictClone, AllowCloning, HideProposalRequirementFields)
output inserted.Id, inserted.Title into @Table (id, title)
VALUES
(1, 'Course Review-Noncredit', 1, 3, 2, @Templatetypeid, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0),
(1, 'Course Reactivation-Noncredit', 1, 3, 2, @Templatetypeid2, 1, 0, 1, 0, 1, 0, 1, 0, 0, 0, 0),
(1, 'Technical Course Deactivation-Noncredit ''for Instructional Services Use''', 1, 3, 2, @Templatetypeid3, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0),
(1, 'Technical Update-Noncredit ''for Instructional Services Use''', 1, 3, 2, @Templatetypeid4, 1, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0)

INSERT INTO ProcessProposalType
(ProposalTypeId, ProcessId)
SELECT id, 8 FROM @Table WHERE title = 'Course Review-Noncredit'
UNION
SELECT id, 8 FROM @Table WHERE title = 'Course Reactivation-Noncredit'
UNION
SELECT id, 8 FROM @Table WHERE title ='Technical Course Deactivation-Noncredit ''for Instructional Services Use'''
UNION
SELECT id, 8 FROM @Table WHERE title = 'Technical Update-Noncredit ''for Instructional Services Use'''

---------------------------------------------------------------------------------------------------------------------------------------------------
DECLARE @Table2 Table (msf int) 
INSERT INTO @Table2
SELECT msf.MetaSelectedFieldId
FROM MetaSelectedField msf
    INNER JOIN MetaSelectedSection mss ON mss.MetaSelectedSectionId = msf.MetaSelectedSectionId				--gets the field id from the new template
	WHERE msf.MetaAvailableFieldId in (
	292,
	450,
	451,
	453,
	454,
	455,
	456,
	458,
	459,
	461,
	462,
	888,
	7503,
	1601,
	2038,
	3426,
	2623,
	301,
	3446,
	617,
	872,
	873,
	878,
	880,
	2678,
	1001,
	1731,
	2613,
	2614,
	180,
	171,
	184,
	175,
	3392,
	3393,
	193,
	6440
	)
    AND mss.MetaTemplateId in (@Templateid2)

INSERT INTO @Table2
SELECT msf.MetaSelectedFieldId
FROM MetaSelectedField msf
    INNER JOIN MetaSelectedSection mss ON mss.MetaSelectedSectionId = msf.MetaSelectedSectionId				--gets the field id from the new template
	WHERE msf.MetaAvailableFieldId in (
	3446,
	3438
	)
    AND mss.MetaTemplateId in (@Templateid3)

INSERT INTO MetaSelectedFieldRolePermission
(MetaSelectedFieldId, RoleId, AccessRestrictionType)
SELECT msf, 4, 1 FROM @Table2
UNION
SELECT msf, 1, 2 FROM @Table2

DECLARE @Table3 Table (mss int)
INSERT INTO @Table3
SELECT mss.MetaSelectedSectionId
FROM MetaSelectedField msf
    INNER JOIN MetaSelectedSection mss ON mss.MetaSelectedSectionId = msf.MetaSelectedSectionId				--gets the field id from the new template
	WHERE msf.MetaAvailableFieldId in (
	292,
	1601,
	301,
	180,
	171,
	184,
	175,
	3392,
	3393,
	193,
	6440
	)
    AND mss.MetaTemplateId in (@Templateid2)

INSERT INTO MetaSelectedSectionRolePermission
(MetaSelectedSectionId, RoleId, AccessRestrictionType)
SELECT mss, 4, 1 FROM @Table3
UNION
SELECT mss, 1, 2 FROM @Table3

--commit