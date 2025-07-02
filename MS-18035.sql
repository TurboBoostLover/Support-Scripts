USE [gavilan];

/*
   Commit
					Rollback
*/

DECLARE @JiraTicketNumber nvarchar(20) = 'MS-18035';
DECLARE @Comments nvarchar(Max) = 
	'Update Program Review';
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
Declare @clientId int =57, -- SELECT Id, Title FROM Client 
	@Entitytypeid int =6; -- SELECT * FROM EntityType (1 = course, 2 = program, 6 = module)

declare @templateId integers

INSERT INTO @templateId
SELECT mt.MetaTemplateId
FROM MetaTemplateType mtt
    INNER JOIN MetaTemplate mt ON mtt.MetaTemplateTypeId = mt.MetaTemplateTypeId
WHERE mt.Active = 1 
    AND mtt.EntityTypeId = @entityTypeId
    AND mt.IsDraft = 0
    AND mt.EndDate IS NULL
    AND mtt.Active = 1
    AND mtt.IsPresentationView = 0	--comment out if doing reports and forms
    AND mtt.ClientId = @clientId
		AND mtt.MetaTemplateTypeId in (535)		--comment back in if just doing some of the mtt's

declare @FieldCriteria table (
	TabName nvarchar(255) index ixRecalcFieldCriteria_TabName,
	TableName sysname index ixRecalcFieldCriteria_TableName,
	ColumnName sysname index ixRecalcFieldCriteria_ColumnName,
	Action nvarchar(max)
);
/************************* Put fields Here ***********************
*************************Only Edit Values************************/
insert into @FieldCriteria (TabName, TableName, ColumnName,Action)
values
('Click Add Item to Enter a Resource Request', 'ModuleResourceRequestLookup', 'Lookup01Id','1'),
('Click Add Item to Enter a Resource Request', 'ModuleResourceRequest', 'MaxText01','2')

declare @Fields table (
	FieldId int primary key,
	SectionId int,
	Action nvarchar(max),
	TabId int,
	TemplateId int,
	sortorder int,
	mtt int,
	nam NVARCHAR(MAX)
);

insert into @Fields (FieldId,SectionId,Action,TabId,TemplateId,sortorder, mtt, nam)
select msf.metaselectedfieldid,msf.MetaSelectedSectionId,rfc.Action,mss.MetaSelectedSectionId,mss.MetaTemplateId ,msf.RowPosition, mt.MetaTemplateTypeId, mss2.SectionName
from MetaTemplate mt
inner join MetaSelectedSection mss
	on mt.MetaTemplateId = mss.MetaTemplateId
inner join MetaSelectedSection mss2
	on mss.MetaSelectedSectionId = mss2.MetaSelectedSection_MetaSelectedSectionId
inner join MetaSelectedField msf
	on mss2.MetaSelectedSectionId = msf.MetaSelectedSectionId
inner join MetaAvailableField maf
	on msf.MetaAvailableFieldId = maf.MetaAvailableFieldId
inner join @FieldCriteria rfc
	on ( maf.TableName = rfc.TableName and maf.ColumnName = rfc.ColumnName and rfc.TabName = mss.SectionName)		--uncomment tab name if tempalate have different tab name (likely in reports)
where mt.MetaTemplateId  in (select * from @templateId)

/********************** Changes go HERE **************************************************/
UPDATE MetaSelectedSection
SET SectionName = '6. Category of Request'
, SectionDescription = 'Select all that apply'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '1' and nam like 'Category of Request%'
)

UPDATE MetaSelectedSection
SET SectionName = '7. The committe will separate goals with resouce requests. Requests will be categorized into two groups: those to be ranked and those not ranked.'
, SectionDescription = 'The requests not ranked include Safety, Compliance, Personnel, and Position.'
, DisplaySectionDescription = 1
WHERE MetaSelectedSectionId in (
	SELECT SectionId FROM @Fields WHERE Action = '1' and nam like 'Which of the following%'
)

UPDATE MetaSelectedField
SET DisplayName = '8. Provide a complete description, justification, or rationale for the requested amount. Describe how it aligns to the selected goal(s) and your responses to the above questions.'
WHERE MetaSelectedFieldId in (
	SELECT FieldId FROM @Fields WHERE Action = '2'
)

INSERT INTO MetaSelectedFieldAttribute
(Name, Value, MetaSelectedFieldId)
SELECT 'helptext', '300 words', FieldId FROM @Fields WHERE Action = '2'

UPDATE Lookup01
SET LongText = 'Safety: Requests that ensure a safe learning and working environment for students and employees, such as emergency preparedness, campus security, health and wellness, and risk management.'
WHERE Id = 34

UPDATE Lookup01
SET LongText = 'Compliance: Requests that meet necessary regulatory and legal standards, such as Section 508, FERPA, and OSHA. These requests may or may not be related to safety or security issues, but they are required by law or regulation.'
WHERE Id = 35

UPDATE Lookup01
SET LongText = 'Personnel and Position: Requests that involve hiring, staffing, or reclassifying full-time or part-time faculty or staff. These requests are reviewed and approved through a separate process by the Faculty Staffing Committee or the Executive and Leadership Council.'
WHERE Id = 36

DELETE FROM Lookup01 WHERE ID = 37
/****************************** update templates ******************************************/
update MetaTemplate
set LastUpdatedDate = getdate()
where MetaTemplateId in (select Distinct templateId FROM @Fields)

--exec EntityExpand @clientId =3 , @entityTypeId =2

--exec upUpdateEntitySectionSummary @entityTypeId = 1, @templateId = EnterMetaTemplateIdHere, @entityId = null; --badge update

--commit
--rollback